public class ArgParser {
    
    /**
     A helper struct to track the verbatim state of arguments as they are iterated.
     
     It follows the `IteratorProtocol` but doesn't declare such because it is only used inside this class.
     */
    private struct ArgIterator<T: IteratorProtocol<String>> {
        private var iterator : T
        private(set) var verbatim : Bool
        
        init(iterator: T) {
            self.iterator = iterator
            self.verbatim = false
        }
        
        mutating func next() -> String? {
            let str = iterator.next()
            if !verbatim && str == "--" {
                verbatim = true
                return iterator.next()
            }
            return str
        }
    }
    
    private let params : [Parameter]
    private let paramDict : [String: Parameter]
    
    public init(_ spec: Parameter...) {
        var pd : [String: Parameter] = [:]
        for param in spec {
            param.addToDict(&pd)
        }
        params = spec
        paramDict = pd
    }
    
    /**
     Get parameter help text for the entire help spec.
     
     - returns: a help string suitable for output
     */
    public func argumentHelpText() -> String {
        params.map { $0.helpText() }.joined()
    }
    
    /** identify double-dash commands */
    private static func doubleDashCmd(_ s: String) -> Substring? {
        if s.hasPrefix("--") {
            return s.dropFirst(2)
        }
        return nil
    }
    
    private static func singleDashCmd(_ s: String) -> [Character]? {
        if s.hasPrefix("-") && s.count > 1 {
            return Array(s.dropFirst(1))
        }
        return nil
    }
    
    private func processParam(_ paramStr: String) throws {
        guard let param = paramDict[paramStr] else {
            throw ArgumentErrors.invalidArgument(desc: "parameter <\(paramStr)> not found!")
        }
        switch param {
        case let zeroArg as NoArgParameter:
            try zeroArg.process(param: paramStr)
        case is OneArgParameter:
            throw ArgumentErrors.invalidArgument(desc: "parameter <\(paramStr)> wasn't given arguments!")
        default:
            assertionFailure("parameter \(paramStr) processed but was not NoArg or OneArg!")
        }
    }
    
    private func processParam<T>(_ paramStr: String, withIterator: inout ArgIterator<T>) throws {
        guard let param = paramDict[paramStr] else {
            throw ArgumentErrors.invalidArgument(desc: "parameter <\(paramStr)> not found!")
        }
        switch param {
        case let zeroArg as NoArgParameter:
            try zeroArg.process(param: paramStr)
        case let oneArg as OneArgParameter:
            guard let arg = withIterator.next() else {
                throw ArgumentErrors.invalidArgument(desc: "no argument provided to <\(paramStr)>!")
            }
            try oneArg.process(param: paramStr, arg: arg)
        default:
            assertionFailure("parameter \(paramStr) processed but was not NoArg or OneArg!")
        }
    }
    
    private func processParam(_ paramStr: String, withArg: String) throws {
        guard let param = paramDict[paramStr] else {
            throw ArgumentErrors.invalidArgument(desc: "parameter <\(paramStr)> not found!")
        }
        switch param {
        case is NoArgParameter:
            throw ArgumentErrors.invalidArgument(desc: "parameter <\(paramStr)> doesn't take arguments!")
        case let oneArg as OneArgParameter:
            try oneArg.process(param: paramStr, arg: withArg)
        default:
            assertionFailure("parameter \(paramStr) processed but was not NoArg or OneArg!")
        }
    }
    
    /**
     Parse the given `args`, setting any parameters and returning the
     list of extra arguments not associated with parameters.
     */
    public func parseArgs(_ args: some Sequence<String>) throws -> [String] {
        var extras : [String] = []
        var argIterator = ArgIterator(iterator: args.makeIterator())
        while let arg = argIterator.next() {
            if argIterator.verbatim {
                // verbatim arguments can't be parsed, just extras
                extras.append(arg)
            } else if let dd = Self.doubleDashCmd(arg) {
                // we need to separate --param=value into (param,value), if given that way
                if let eqSign = dd.firstIndex(of: "=") {
                    let cmd = String(dd.prefix(upTo: eqSign))
                    let cmdArg = String(dd.suffix(from: dd.index(after: eqSign)))
                    try processParam(cmd, withArg: cmdArg)
                } else {
                    try processParam(String(dd), withIterator: &argIterator)
                }
            } else if let sd = Self.singleDashCmd(arg) {
                // all the elements except the first must be NoArg...
                for cmd in sd.dropLast() {
                    try processParam(String(cmd))
                }
                try processParam(String(sd.last!), withIterator: &argIterator)
            } else {
                extras.append(arg)
            }
        }
        return extras
    }
}

