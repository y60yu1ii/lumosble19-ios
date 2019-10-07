//
// Created by yaoyu on 2019-02-14.
// Copyright (c) 2019 fishare. All rights reserved.
//

import Foundation
import CoreBluetooth
import LumosBLE

class LumosSingleton :NSObject {
    //singleton pattern
    private static let sharedInstance = LumosSingleton()
    static private var shInstance: LumosSingleton { return sharedInstance }
    @objc static func instance() -> LumosSingleton { return shInstance }

    lazy var centralMgr:CentralManager = CentralManager.instance()
    let nc = NotificationCenter.default

    public func start(){
        centralMgr.serviceUUIDs = []
        centralMgr.setting = self
        centralMgr.event = self
        centralMgr.startAPP()
        centralMgr.loadHistory()
//        nc.addObserver(forName: Notification.Name(rawValue: CONNECTION), object: nil, queue: nil){
//            (notification) in
////            print("connection status \(notification.userInfo ?? [:])")
//        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


extension LumosSingleton : Setting{
    public func getCustomObj(_ key: String, _ name: String) -> PeriObj {
        return XRing(key)
    }
    public func getCustomAvl(_ peri: CBPeripheral) -> AvailObj {
        return BuddyAvail(peri)
    }

    public func getNameRule() -> String {
        return "(XRING)-[a-zA-Z0-9]{4}"
}
}

extension LumosSingleton : EventListener{
    public func didDiscover(_ availObj: AvailObj) {
        print("[app discover] \(availObj.name)")
        if(availObj.name.contains("XRING")){
            CentralManager.instance().connect(availObj.key)
        }
    }

    public func didConnectionChange(_ key: String, isConnected: Bool) {
        print("[app connection] \(key) is \(isConnected)")
    }
}

