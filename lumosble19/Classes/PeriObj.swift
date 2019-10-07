//
// Created by yaoyu on 2019-02-11.
//

import Foundation
import CoreBluetooth
public protocol PeriObjDelegate{
    func onRSSIChanged(rssi: Int, periObj:PeriObj)
    func onUpdated(label: String, value:Any, periObj:PeriObj)
}

open class PeriObj :NSObject{
    public var cbPeripheral:CBPeripheral? = nil
    public var key:String  = "key"
    public var name:String = "name"
    public var uuid:String = "uuid"
    public var markDelete = false
    public var blocked = false
    public var connectingLock = false
    public var delegate: PeriObjDelegate? = nil
    var controller: GattController? = nil
    public var rssi:Int = 0

    public init(_ uuid :String){
        self.uuid = uuid
    }

    deinit {
        delegate = nil
        controller = nil
    }

    func preConnect(_ avl:AvailObj){
        self.cbPeripheral = avl.cbPeripheral
        self.key  = avl.key
        self.rssi = avl.rssi
        self.uuid = avl.uuid
        self.name = avl.name
    }

    func postConnect(peri:CBPeripheral){
        connectingLock = true
        self.cbPeripheral = peri
        name = cbPeripheral?.name ?? name
        controller = GattController(peri)
        controller?.delegate = self
        DispatchQueue.main.async{
            self.controller?.startDiscoverServices()
        }
    }

    func clear(){
        cbPeripheral?.delegate = nil
        controller?.delegate = nil
    }

    open func setUp(){
        controller?.cbPeripheral.readRSSI()
    }

    open func connectionDropped(_ completion:@escaping (_:Bool)->()){}
    open func disconnect(_ completion:@escaping (_:Bool)->()){}
    open func onRSSIChange(_ rssi:Int){}
    open func onUpdate(_ uuidStr: String, _ value: Data, _ kind: UpdateKind) {}

    public func writeTo(_ uuidStr:String, data:Data){
        controller?.writeTo(uuidStr, data: data, resp: true)
    }
    public func writeToNoResp(_ uuidStr:String, data:Data){
        controller?.writeTo(uuidStr, data: data, resp: false)
    }

    public func readFrom(_ uuidStr:String){
        controller?.readFrom(uuidStr)
    }

    public func subscribe(_ uuidStr:String){
        controller?.subscribeTo(uuidStr)
    }
}

extension PeriObj :ControllerDelegate{
    func didDiscoverServices() {
        setUp()
    }

    func onRSSIUpdated(rssi: Int) {
        self.rssi = rssi
        onRSSIChange(rssi)
    }

    func onUpdated(_ uuidStr: String, value: Data, kind: UpdateKind) {
        onUpdate(uuidStr, value, kind)
    }
}

