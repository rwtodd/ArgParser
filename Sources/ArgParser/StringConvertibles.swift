//
//  StringConvertibles.swift
//
//  BasicParam<T> works with LosslessStringConvertibles, so I plan to add any
//  generally-useful wrappers here to package with the Arg Parser.
//
//  Created by Richard Todd on 11/19/22.
//
import Foundation


/**
  An argument type that accepts lists and ranges of integers.
 
   At present, all ranges must be low-to-hgih... no reversed ranges available at this time.  Maybe in a future version.
 
  For example:   12,14..32,105
 */
public struct IntegerSequenceArg : LosslessStringConvertible {
    public let seq : FlattenSequence<[ClosedRange<Int>]>

    public init?(_ instr: String) {
        let ranges = instr.split(separator: ",").map { part -> ClosedRange<Int>? in
            if let match = part.firstMatch(of: #/\.\./#) {
                if let low = Int(part[..<match.startIndex]),
                   let high = Int(part[match.endIndex...]),
                   low <= high {
                    return low...high
                }
            } else {
                if let single = Int(part) { return single...single }
            }
            return nil
        }
        guard ranges.firstIndex(of: nil) == nil else { return nil }
        seq = ranges.compactMap({$0}).joined()
    }
    
    // provide a default constructor where ranges can be supplied
    public init(_ ranges: [ClosedRange<Int>] = []) {
        seq = ranges.joined()
    }
    
    public var description: String {
        seq.map { $0.description }.joined(separator: ",")
    }
}


/**
 A  wrapper for  for timeless Year-Month-Day dates that is
 `LosslessStringConvertible`  and `Comparable`.
 
  The input format is yyyy-mm-dd, where the year and month can be optionally
 elided if they match the year and month from today.  The user can also input constants
 'today', 'tomorrow', and 'yesterday' if desired.
 */
public struct YMDArg : LosslessStringConvertible, Comparable {
    public static func < (lhs: YMDArg, rhs: YMDArg) -> Bool {
        lhs.date < rhs.date
    }
    
    public let date : Date
    
    public init?(_ description: String) {
        let calendar = Calendar.current
        let now = Date()
        // Assume it's a yyyy-mm-dd format, but try special cases if it doesn't 'parse':
        let parts = description.split(separator: "-").map { Int($0) }
        guard !parts.contains(nil) else {
            let lcased = description.lowercased()
            if lcased.hasPrefix("t+") {
                if let days = Int(lcased.suffix(from: lcased.index(lcased.startIndex,offsetBy: 2))) {
                    date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: days, to: now)!)
                } else { return nil }
            } else if lcased.hasPrefix("t-") {
                if let days = Int(lcased.suffix(from: lcased.index(lcased.startIndex,offsetBy: 2))) {
                    date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -days, to: now)!)
                } else { return nil }
            } else {
                switch lcased {
                case "yesterday":
                    date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now)!)
                case "t": fallthrough
                case "today":
                    date = calendar.startOfDay(for: now)
                case "tomorrow":
                    date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
                default:
                    return nil
                }
            }
            return
        }
        
        var dc = calendar.dateComponents([.year,.month,.day], from: now)
        switch parts.count {
        case 3:
            dc.year = parts[0]
            dc.month = parts[1]
            dc.day = parts[2]
        case 2:
            dc.month = parts[0]
            dc.day = parts[1]
        case 1:
            dc.day = parts[0]
        default:
            return nil
        }
        
        // try to rule out ridiculous dates since DateComponents is extremely forgiving
        if dc.day! > 31 || dc.month! > 12 || dc.day! < 1 || dc.month! < 1 {
            return nil
        }
        guard let date = calendar.date(from: dc) else { return nil }
        self.date = date
    }

    public init(_ d: Date = Date()) {
        date = Calendar.current.startOfDay(for: d)
    }
    
    public init?(year: Int, month: Int, day: Int) {
        let dc = DateComponents(year:year,month:month,day:day)
        guard let specified = Calendar.current.date(from:dc) else { return nil }
        date = specified
    }
    
    public var description: String {
        let cal = Calendar(identifier: .gregorian)
        let dc = cal.dateComponents([.year,.month,.day], from: date)
        return "\(dc.year!)-\(dc.month!)-\(dc.day!)"
    }
}
