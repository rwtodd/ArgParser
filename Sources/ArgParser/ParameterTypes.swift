public enum ArgumentErrors : Error {
    case invalidArgument(desc: String)
}

public protocol Parameter {
    func addToDict(_ : inout [String:Parameter])
    func helpText() -> String
}

protocol NoArgParameter : Parameter {
    func process(param: String) throws
}

protocol ArgParameter : Parameter {
    func process(param: String, arg: String) throws
}

public class BaseParam<T> : ArgParameter {
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
        ostr.append("  <value>\n   \(helpStr)\n")
        return ostr
    }
    
    public func process(param: String, arg: String) throws {
        guard let converted = convertArgument(arg) else {
            throw ArgumentErrors.invalidArgument(desc: "Argument to \(param) is of the wrong type!")
        }
        guard let filtered = filterArgument(converted) else {
            throw ArgumentErrors.invalidArgument(desc: "Argument to \(param): bad value or out of range!")
        }
        value = filtered
    }
    func filterArgument(_ arg: T) -> T? { arg }
    func convertArgument(_ s: String) -> T? { fatalError("convertArgument() not implemented!") }
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

public class StringParam : BaseParam<String> {
    override func convertArgument(_ s: String) -> String?  { s }
}

public class IntParam : BaseParam<Int> {
    override func convertArgument(_ s: String) -> Int?  { Int(s) }
}

public class RangedIntParam : IntParam {
    private let min, max: Int
    public init(names ns: [String], initial i: Int, min: Int, max: Int, help hs: String) {
        self.min = min
        self.max = max
        super.init(names: ns, initial: i, help: "\(hs) (range: \(min) to \(max))")
    }
    
    override func filterArgument(_ arg: Int) -> Int? {
        (arg >= min && arg <= max) ? arg : nil
    }
}

public class ClampedIntParam : IntParam {
    private let min, max: Int
    public init(names ns: [String], initial i: Int, min: Int, max: Int, help hs: String) {
        self.min = min
        self.max = max
        super.init(names: ns, initial: i, help: "\(hs) (range clamped to: \(min) to \(max))")
    }
    
    override func filterArgument(_ arg: Int) -> Int? {
        if arg < min { return min }
        else if arg > max { return max }
        else { return arg }
    }
}
