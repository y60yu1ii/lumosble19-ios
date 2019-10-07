//
// Created by yaoyu on 2019-02-11.
//

import Foundation
import CoreBluetooth

public enum UpdateKind{ case write, update }
protocol ControllerDelegate {
    func didDiscoverServices()
    func onRSSIUpdated(rssi: Int)
    func onUpdated(_ uuidStr: String, value: Data, kind: UpdateKind)
}


class GattController:NSObject, CBPeripheralDelegate{
    var delegate:ControllerDelegate?
    //dict of characteristic
    var charaDict:[String:CBCharacteristic] = Dictionary()
    var verifyMap:[String: Data] = Dictionary()
    var cbPeripheral:CBPeripheral

    var queue:OperationQueue = OperationQueue()
    var debug = false

    var len = 0
    var now = 0

    var isConnected:Bool{
        get { return self.cbPeripheral.state == .connected }
    }

    init(_ peri:CBPeripheral){
        cbPeripheral = peri
        queue.maxConcurrentOperationCount = 1
    }

    deinit{
        cbPeripheral.delegate = nil
    }

    func startDiscoverServices(){
        cbPeripheral.delegate = self
        cbPeripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach{ peripheral.discoverCharacteristics(nil, for: $0) }
        len = peripheral.services?.count ?? len
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach{ charaDict[$0.uuid.uuidString] = $0 }
        now += 1
//        print("\(now) / \(len) ")
        if(now >= len ){ delegate?.didDiscoverServices() }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        delegate?.onRSSIUpdated(rssi: RSSI.intValue)
        self.cbPeripheral.readRSSI()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        let uuidStr = characteristic.uuid.uuidString
        let value   = characteristic.value ?? Data()
        delegate?.onUpdated(uuidStr, value: value, kind: .update)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        let uuidStr = characteristic.uuid.uuidString
        let value   = characteristic.value ?? Data()
        delegate?.onUpdated(uuidStr, value: value, kind: .write)
    }

    func writeTo(_ uuid:String, data:Data, resp:Bool){
        guard let ch = charaDict[uuid] else { return }
        writeTo(ch, data: data, resp: resp)
    }

    func readFrom(_ uuid:String){
        guard let ch = charaDict[uuid] else { return }
        readFrom(ch)
    }

    func subscribeTo(_ uuid:String){
        guard let ch = charaDict[uuid] else { return }
        self.cbPeripheral.setNotifyValue(true, for: ch)
    }

    func writeTo(_ ch:CBCharacteristic, data:Data, resp:Bool){
        if isConnected {
            let t:CBCharacteristicWriteType = (resp) ? .withResponse : .withoutResponse
            let op = BlockOperation(block:{ self.cbPeripheral.writeValue(data, for: ch, type: t) })
            queue.addOperation(op)
        }
    }

    func readFrom(_ ch:CBCharacteristic){
        if isConnected {
            let op = BlockOperation(block:{ self.cbPeripheral.readValue(for: ch) })
            queue.addOperation(op)
        }
    }

}
