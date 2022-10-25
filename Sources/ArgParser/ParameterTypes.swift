/**
 Failure to parse or interpret command-line arguments should result in `ArgumentErrors`.
 */
public enum ArgumentErrors : Error {
    case invalidArgument(desc: String)
}

/**
 Parameter is the base of the two main protocols, ``NoArgParameter`` and ``OneArgParameter``.
 
 All actual parameters should implement one of those two protocols.  Implementing just plain `Parameter` allows
 a class to get on the spec list of ``ArgParser``, which could control the formatting of the help text.
 */
public protocol Parameter {
    /**
     Add any names by which this parameter wants to process arguments to the given dictionary.
     
     - parameter dict:  the dictionary of parameter names
     - returns: None
     */
    func addToDict(_ dict: inout [String:Parameter])
    /**
     Return the help text for this parameter.
     
     - returns: a string of help text
     */
    func helpText() -> String
}

/** This protocol is for zero-arg parameters (like plain "flag" switches. */
public protocol NoArgParameter : Parameter {
   
    /**
     Process a parameter with no arguments.
     
     - parameter param: the string under which this parameter was called.
     - throws: ``ArgumentErrors`` if there is a problem with the argument.
     - returns: None
     */
    func process(param: String) throws
}

/** This protocol is for one-arg parameters on the command line (e.g., --procs 3) */
public protocol OneArgParameter : Parameter {
    /**
     Process a parameter with one argument.
     
     - Parameter param: the string under which this parameter was called.
     - Parameter arg: the argument given to the parameter, as a String.
     - throws: ``ArgumentErrors`` if there is a problem with the argument.
     - returns: None
     */
    func process(param: String, arg: String) throws
}

/**
 A typical parameter, with one or more names.
 */
public class BasicParam<T: LosslessStringConvertible> : OneArgParameter {
    private let names: [String]
    private let helpStr: String

    /**
     The current value of the parameter.
     */
    public internal(set) var value: T
    
    /**
     Creates a parameter.
     
     - Parameter names: an array of names by which this `BasicParam` is referenced
     - Parameter initial: the initial (default) value of the parameter.
     - Parameter help: the help description of this parameter
     */
    public init(names: [String], initial: T, help: String) {
        self.names = names
        value = initial
        helpStr = help
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

/** A typical cmdline flag (which takes no arguments). */
public class FlagParam: NoArgParameter {
    public internal(set) var value: Bool = false
    private let names: [String]
    private let helpStr: String
    
    public init(names: [String],  help: String) {
        self.names = names
        helpStr = help
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

/**
 A parameter limited by a user-defined range (inclusive).
 */
public class RangeLimitedParam<T: Comparable & LosslessStringConvertible> : BasicParam<T> {
    private let min, max: T
    public init(names ns: [String], initial i: T, min: T, max: T, help hs: String) {
        self.min = min
        self.max = max
        super.init(names: ns, initial: i, help: "\(hs) (range: \(min) to \(max))")
    }
    
    /**
     Process a parameter with one argument.
     
     - Parameter param: the string under which this parameter was called.
     - Parameter arg: the argument given to the parameter, as a String.
     - throws: ``ArgumentErrors`` if there is a problem with the argument.
     - returns: None
     */
    override public func process(param: String, arg: String) throws {
        try super.process(param: param, arg: arg)
        if (value < min || value > max) {
            throw ArgumentErrors.invalidArgument(desc: "Argument for param <\(param)> is not between \(min) and \(max)!")
        }
    }
}

/**
 A parameter clamoed to a user-defined range (inclusive).
 */
public class ClampedRangeParam<T: Comparable & LosslessStringConvertible> : BasicParam<T> {
    private let min, max: T
    public init(names ns: [String], initial i: T, min: T, max: T, help hs: String) {
        self.min = min
        self.max = max
        super.init(names: ns, initial: i, help: "\(hs) (range clamped between: \(min) and \(max))")
    }
    
    /**
     Process a parameter with one argument.
     
     - Parameter param: the string under which this parameter was called.
     - Parameter arg: the argument given to the parameter, as a String.
     - throws: ``ArgumentErrors`` if there is a problem with the argument.
     - returns: None
     */
    override public func process(param: String, arg: String) throws {
        try super.process(param: param, arg: arg)
        if (value < min) { value = min }
        else if value > max { value = max }
    }
}
