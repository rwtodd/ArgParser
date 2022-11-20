//
//  StringConvertibles.swift
//
//  BasicParam<T> works with LosslessStringConvertibles, so I plan to add any
//  generally-useful wrappers here to package with the Arg Parser.
//
//  Created by Richard Todd on 11/19/22.
//

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
    
    // provide a default constructor that's empty
    public init() {
        seq = [].joined()
    }
    
    public var description: String {
        seq.map { $0.description }.joined(separator: ",")
    }
}
