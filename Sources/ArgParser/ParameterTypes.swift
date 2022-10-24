public enum ArgumentErrors : Error {
    case invalidArgument(desc: String)
}

public protocol Parameter {
    func addToDict(_ : inout [String:Parameter])
    func helpText() -> String
}

public protocol NoArgParameter : Parameter {
    func process(param: String) throws
}

public protocol OneArgParameter : Parameter {
    func process(param: String, arg: String) throws
}

public class BasicParam<T: LosslessStringConvertible> : OneArgParameter {
    public let names: [String]
    public var value: T
    let helpStr: String
    
    public init(names ns: [String], initial i: T, help hs: String) {
        names = ns
        value = i
        helpStr = hs
    }
    
    public func addToDict(_ dict: inout [String : Parameter]) {
        for name in names {
            dict[name] = self
        }
    }
    
    public func helpText() -> String {
        var ostr = names.map { name in
            name.count == 1 ? "-\(name)" : "--\(name)"
        }.joined(separator: "|")
        ostr.append("  <\(T.self)>\n   \(helpStr)\n")
        return ostr
    }
    
    public func process(param: String, arg: String) throws {
        guard let converted = T(arg) else {
            throw ArgumentErrors.invalidArgument(desc: "Argument to param <\(param)> is not a \(T.self)!")
        }
        value = converted
    }
}

public class FlagParam: NoArgParameter {
    public var value: Bool = false
    let names: [String]
    let helpStr: String
    public init(names ns: [String],  help hs: String) {
        names = ns
        helpStr = hs
    }
    
    public func addToDict(_ dict: inout [String : Parameter]) {
        for name in names {
            dict[name] = self
        }
    }
    
    public func helpText() -> String {
        var ostr = names.map { name in
            name.count == 1 ? "-\(name)" : "--\(name)"
        }.joined(separator: "|")
        ostr.append("\n   \(helpStr)\n")
        return ostr
    }
    
    public func process(param: String) throws {
        value = true
    }
}

public class RangeLimitedParam<T: Comparable & LosslessStringConvertible> : BasicParam<T> {
    private let min, max: T
    public init(names ns: [String], initial i: T, min: T, max: T, help hs: String) {
        self.min = min
        self.max = max
        super.init(names: ns, initial: i, help: "\(hs) (range: \(min) to \(max))")
    }
    
    override public func process(param: String, arg: String) throws {
        try super.process(param: param, arg: arg)
        if (value < min || value > max) {
            throw ArgumentErrors.invalidArgument(desc: "Argument for param <\(param)> is not between \(min) and \(max)!")
        }
    }
}

public class ClampedRangeParam<T: Comparable & LosslessStringConvertible> : BasicParam<T> {
    private let min, max: T
    public init(names ns: [String], initial i: T, min: T, max: T, help hs: String) {
        self.min = min
        self.max = max
        super.init(names: ns, initial: i, help: "\(hs) (range clamped between: \(min) and \(max))")
    }
    
    override public func process(param: String, arg: String) throws {
        try super.process(param: param, arg: arg)
        if (value < min) { value = min }
        else if value > max { value = max }
    }
}
