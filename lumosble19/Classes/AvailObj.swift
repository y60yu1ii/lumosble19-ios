//
// Created by yaoyu on 2019-02-11.
//

import Foundation
import CoreBluetooth

open class AvailObj :NSObject{
    public var cbPeripheral:CBPeripheral
    public var key:String  = "key"
    public var name:String = "name"
    public var uuid:String
    public var lastUpdateTime:Int = 0
    public var rawData:Data = Data(){ didSet{ onRawUpdate(rawData) }}
    open func onRawUpdate(_ data: Data){}
    var rssi:Int = 0{
        didSet{
            if(rssi<0){
                delegate?.onRSSIChanged(rssi: rssi, availObj: self)
                lastUpdateTime = Int(Date().timeIntervalSince1970)
            }
        }
    }

    var delegate:AvailObjDelegate? = nil
    public init(_ peri: CBPeripheral){
        cbPeripheral = peri
        uuid = peri.identifier.uuidString
        name = peri.name ?? "name"
    }
    deinit {
        delegate = nil
    }

    open func setUp(){}

}

protocol AvailObjDelegate{
    func onRSSIChanged(rssi: Int, availObj:AvailObj)
    func onUpdated(label: String, value:Any, availObj:AvailObj)
}