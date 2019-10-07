//
// Created by yaoyu on 2019-02-12.
// Copyright (c) 2019 fishare. All rights reserved.
//

import Foundation
let ud = UserDefaults.standard
let NULL = "string.null"

func getHistory() -> Array<String> {
    return ud.array(forKey: "history") as? Array<String> ?? []
}

func setHistory(list:Array<String>){
    ud.set(list, forKey: "history")
    ud.synchronize()
}

func addToHistory(_ key:String){
    if var ls = ud.array(forKey: "history") as? [String] {
        if !ls.contains(key) {
            ls.append(key)
            setHistory(list: ls)
        }
    }else {
        setHistory(list: [key])
    }
}

func removeFromHistory(_ key:String){
    if var ls =  ud.array(forKey: "history") as? [String]{
        ls = ls.filter{$0 != key}
        ud.set(ls, forKey: "history")
        ud.synchronize()
    }
}

func loadProfile(_ key:String, _ para:String) -> String{
    let profile = getProfileDict(key)
    return profile[key] as? String ?? NULL
}

func loadProfile(_ key:String, _ para:String) -> Int{
    let profile = getProfileDict(key)
    return profile[key] as? Int ?? 0
}

func saveProfile(_ key:String, _ para:String, _ value:Any){
    var profile = getProfileDict(key)
    profile[key] = value
    ud.set(profile, forKey: key)
    ud.synchronize()
}

func getProfileDict(_ key:String) -> [String:Any]{
    if let profile = ud.dictionary(forKey: key) {
        return profile
    } else {
        let prf: [String:Any] = [
            "name": "name",
            "mac" :"mac",
            "uuid" :"uuid",
        ]
        ud.set(prf, forKey: key)
        ud.synchronize()
        return prf
    }
}

