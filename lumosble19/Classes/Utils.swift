//
// Created by yaoyu on 2019-02-12.
// Copyright (c) 2019 fishare. All rights reserved.
//

import Foundation
public let REFRESH_ALL = "de.fishare.refresh"
public let CONNECTION  = "de.fishare.connection"

func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound )
    }

    func toHex4Human() -> String {
        return map { String(format: "%02hhx ", $0) }.joined()
    }

    func toHexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

    func toJson() -> [String:Any]?{
        do {
            return try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
}