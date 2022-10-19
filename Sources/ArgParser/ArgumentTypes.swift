public enum ArgumentErrors : Error {
  case invalidArgument(desc: String)
}

public protocol Argument {
    var name: String { get }
    var shortName: Character? { get }

    func process(_ :String) throws
    func helpText() -> String
}

public class BaseArgument<T> : Argument {
    public let name: String
    public let shortName: Character?
    public var value: T
    let helpStr: String
    var needsArg : Bool { true }

    public init(name n: String, shortName sn: Character?, initial i: T, help hs: String) {
        name = n
        shortName = sn
        value = i
        helpStr = hs
    }

    public convenience init(name n: String, initial i: T, help hs: String) {
        self.init(name: n, shortName: nil, initial: i, help: hs)
    }

    public func helpText() -> String {
       var ostr = "--\(name)"
       if let ch = shortName {
         ostr.append("|-\(ch)")
       }
       if needsArg {
         ostr.append("  <value>")
       }
       ostr.append("\n    \(helpStr)\n")
       return ostr
    }

    // TODO: make it not public eventually
    // TODO: make it throw an exception when it doesn't work
    public func process(_ s: String) throws { 
        assert(needsArg || (s == ""), "process() got an arg even though none wanted!") 
        guard let converted = convertArgument(s) else {
            throw ArgumentErrors.invalidArgument(desc: "Argument to \(name) is of the wrong type!")
        }
        guard let filtered = filterArgument(converted) else {
            throw ArgumentErrors.invalidArgument(desc: "Argument to \(name): bad value or out of range!")
        }
        value = filtered
    }
    func filterArgument(_ arg: T) -> T? { arg }
    func convertArgument(_ s: String) -> T? { fatalError("convertArgument() not implemented!") }
}

public class FlagArg: BaseArgument<Bool> {
    override var needsArg: Bool { false }
    override func convertArgument(_ s: String) -> Bool? { true }
    public init(name n: String, shortName sn: Character?, help hs: String) { 
        super.init(name: n, shortName: sn, initial: false, help: hs)
    }
    public convenience init(name n: String, help hs: String) { 
        self.init(name: n, shortName: nil, help: hs)
    }
}

public class StringArg : BaseArgument<String> {
    override func convertArgument(_ s: String) -> String?  { s }
}

public class IntArg : BaseArgument<Int> {
    override func convertArgument(_ s: String) -> Int?  { Int(s) }
}

public class RangedIntArg : IntArg {
    private let min, max: Int
    public init(name n: String, shortName sn: Character?, initial i: Int, min: Int, max: Int, help hs: String) {
        self.min = min 
        self.max = max 
        super.init(name: n, shortName: sn, initial: i, help: "\(hs) (range: \(min) to \(max))")
    }

    public convenience init(name n: String, initial i: Int, min: Int, max: Int, help hs: String) {
        self.init(name: n, shortName: nil, initial: i, min: min, max: max, help: hs)
    }

    override func filterArgument(_ arg: Int) -> Int? {
        (arg >= min && arg <= max) ? arg : nil 
    }
}

public class ClampedIntArg : IntArg {
    private let min, max: Int
    public init(name n: String, shortName sn: Character?, initial i: Int, min: Int, max: Int, help hs: String) {
        self.min = min 
        self.max = max 
        super.init(name: n, shortName: sn, initial: i, help: "\(hs) (range clamped to: \(min) to \(max))")
    }

    public convenience init(name n: String, initial i: Int, min: Int, max: Int, help hs: String) {
        self.init(name: n, shortName: nil, initial: i, min: min, max: max, help: hs)
    }

    override func filterArgument(_ arg: Int) -> Int? {
        if arg < min { return min }
        else if arg > max { return max }
        else { return arg }
    }
}
