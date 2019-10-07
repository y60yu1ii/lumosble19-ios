//
// Created by yaoyu on 2019/10/07.
// Copyright (c) 2019 P.Q.D. Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

public class CentralManager: NSObject{
        //singleton pattern
    private static let sharedInstance = CentralManager()
    static private var shInstance : CentralManager { return sharedInstance }
    @objc public static func instance() -> CentralManager { return shInstance }

    let CONNECT_FILTER:Int = -75
    let REGX_ALL = ".*?"
    let RECONNECT_TIMES = 1

    public var serviceUUIDs = [String]()
    public var setting : Setting? = nil
    public var event : EventListener? = nil
    public var avails = [AvailObj]()
    var periMap = [String:PeriObj]()
    public var peris : [PeriObj] { get{ return periMap.map{$0.1} } }

    var centralMgr: CBCentralManager!

    private override init(){
        super.init()
        centralMgr = CBCentralManager(delegate: self,
                queue: DispatchQueue.global(qos: .background),
                options: [CBCentralManagerOptionShowPowerAlertKey:true])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension CentralManager{

    @objc public func startAPP(){
        //prevent from doing nothing when initiated
        print("Open central manager \u{24}")
    }

    @objc public func connect(_ key:String){
        let avl = avails.first{ $0.key == key }
        if(avl != nil){ connect(avl!) }
    }

    @objc public func disconnect(_ key:String){
        let periObj = peris.first{ $0.key == key }
        if(periObj != nil){
           disconnect(periObj!, isRemove: false)
        }
    }

    @objc public func remove(_ key:String){
        let periObj = peris.first{ $0.key == key }
        if(periObj != nil){
            disconnect(periObj!, isRemove: true)
        }
    }

    @objc public func loadHistory(){
        getHistory().forEach{
            let name:String = loadProfile($0, "name")
            periMap[$0] = (setting?.getCustomObj($0, name) ?? PeriObj($0))
        }
    }
}

extension CentralManager : CBCentralManagerDelegate{
    /**
     *  on Scanned results
     *
     **/
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
//        print("Scan name is \(peripheral.name ?? "")")
        let rssi = RSSI.intValue
        guard rssi != 127 else { return }
        guard peripheral.name != nil else { return }
        if !isValidName(name: peripheral.name) { return }
        let data = advertisementData["kCBAdvDataManufacturerData"] as? Data ?? Data()
        let uuid = peripheral.identifier.uuidString
        let periObj = periMap[uuid]
        if(periObj != nil){
            if(!periObj!.blocked){
                print("[FOUND LOST] \(periObj!.name) is my lost device, reconnect")
                connect(makeAvail(peripheral, rawData: data))
            }
            return
        }

        let avl = avails.first{ $0.uuid == uuid }
        if(avl != nil){
//            print("[UPDATE] avail count is \(avails.count) key is \(avl!.key) name is \(avl!.name)")
            avl!.rssi = rssi
            avl!.rawData = data
        }else if(rssi > CONNECT_FILTER){
            let a = makeAvail(peripheral, rawData: data)
            avails.append(a)
            event?.didDiscover(a)
            print("[ADD to AVAIL] \(a.name) key is \(a.key) " +
                    "count is \(avails.count) " +
                    "peris count is \(peris.count)"
            )
        }
    }

    func isValidName(name:String?) -> Bool{
        guard let n = name else{ return false }
        let matched = matches(for: setting?.getNameRule() ?? REGX_ALL, in: n)
        return !matched.isEmpty
    }

    func makeAvail(_ peri:CBPeripheral, rawData:Data) -> AvailObj{
        let avl:AvailObj = setting?.getCustomAvl(peri) ?? AvailObj(peri)
        avl.rawData = rawData
        avl.setUp()
        return avl
    }

    //did connect callback
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        print("[CONNECTED] \(peripheral.name ?? "") is connected")
        let uuid = peripheral.identifier.uuidString
        let periObj = peris.first{ $0.uuid == uuid }
        if(periObj != nil){
            print("[CONNECTED] \(periObj!.name) with \(periObj!.uuid) key is \(periObj!.key)")
            DispatchQueue.main.async {
                periObj!.postConnect(peri: peripheral)
            }
            NotificationCenter.default.post(name: Notification.Name(CONNECTION),
                    object: nil, userInfo: ["key" : periObj!.key, "connected": true])
            event?.didConnectionChange(periObj!.key, isConnected: true)
        }
    }

    //did disconnect callback
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[DISCONNECTED] \(peripheral.name ?? "") is dropped")
        let periObj = peris.first{ $0.uuid == peripheral.identifier.uuidString }
        if(periObj != nil){ didDisConnect(periObj!) }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[FAIL DISCONNECTED] \(peripheral.name ?? "") is dropped")
        let periObj = peris.first{ $0.uuid == peripheral.identifier.uuidString }
        if(periObj != nil){ didDisConnect(periObj!) }
   }

    private func didDisConnect(_ periObj:PeriObj){
        periObj.clear()
        periObj.connectionDropped(){ (completed) in
            print("[CentralManager] blocked \(periObj.blocked) and markDelete is \(periObj.markDelete)")
            if(periObj.markDelete){
                self.periMap.removeValue(forKey: periObj.uuid)
                removeFromHistory(periObj.uuid)
            }
        }
        NotificationCenter.default.post(name: Notification.Name(CONNECTION),
                    object: nil, userInfo: ["key" : periObj.key, "connected": false])
        event?.didConnectionChange(periObj.key, isConnected: false)
    }

    private func connect(_ avl:AvailObj){
        let periObj:PeriObj = periMap[avl.uuid] ?? setting?.getCustomObj(avl.uuid, avl.name) ?? PeriObj(avl.uuid)
        if(!periObj.blocked){
            periObj.preConnect(avl)
            periMap[periObj.uuid] = periObj
            DispatchQueue.main.async{
                if(periObj.cbPeripheral != nil){
                    self.centralMgr.connect(periObj.cbPeripheral!,
                            options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true])
                }
            }
            avl.delegate = nil
            avails.removeAll { $0.uuid == avl.uuid }
            addToHistory(avl.uuid)
            saveProfile(avl.uuid, "name", avl.name)
        }
    }

    private func disconnect(_ periObj :PeriObj, isRemove:Bool){
        print("Disconnecting")
        periObj.markDelete = isRemove
        periObj.disconnect(){ (completed) in
            if(completed && periObj.cbPeripheral != nil)
            {
                self.centralMgr.cancelPeripheralConnection(periObj.cbPeripheral!)
            }
        }
        if(isRemove){ removeFromHistory(periObj.uuid) }
    }

    private func doScan(){
        let services = serviceUUIDs.map{ (uuid)-> CBUUID in return CBUUID.init(string: uuid)}
        print("scan for \(services)")
        DispatchQueue.main.async {
            self.centralMgr.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }

    private func bluetoothIsOff(){
        peris.forEach{ $0.connectionDropped(){(completed)in} }
        avails.removeAll()
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            switch central.state{
            case CBManagerState.unauthorized:
                print("This app is not authorised to use Bluetooth low energy")
            case CBManagerState.poweredOff:
                print("Ble off")
                bluetoothIsOff()
            case CBManagerState.poweredOn:
                print("Ble on")
                doScan()
            default:break
            }
        } else {
            switch central.state.rawValue {
            case 3: // CBCentralManagerState.unauthorized :
                print("This app is not authorised to use Bluetooth low energy")
            case 4: // CBCentralManagerState.poweredOff:
                print("Ble off")
                bluetoothIsOff()
            case 5: //CBCentralManagerState.poweredOn:
                print("Ble on")
                doScan()

            default:break
            }
        }
    }
}
