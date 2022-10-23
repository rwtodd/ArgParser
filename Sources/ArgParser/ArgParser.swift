public class ArgParser {
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
     Get parameter help text.
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
        if s.hasPrefix("-") {
            return Array(s.dropFirst(1))
        }
        return nil
    }
    
    private static func nextArg(from lst: inout IndexingIterator<[String]>, verbatim: inout Bool) -> String? {
        let str = lst.next()
        if !verbatim && str == "--" {
            verbatim = true
            return lst.next()
        }
        return str
    }
    
    /**
     Parse the given `args`, setting any parameters and returning the
     list of extra arguments not associated with parameters.
     */
    public func parseArgs(_ args: [String]) throws -> [String] {
        var extras : [String] = []
        var verbatim = false
        var argIterator = args.makeIterator()
        while let arg = Self.nextArg(from: &argIterator, verbatim: &verbatim) {
            if let dd = Self.doubleDashCmd(arg) {
                // we need to separate --param=value into (param,value), if given that way
                //let split(separator: "=", maxSplits: 1,omittingEmptySubsequences: false)
                if let eqSign = dd.firstIndex(of: "=") {
                    let cmd = String(dd.prefix(upTo: eqSign))
                    let cmdArg = String(dd.suffix(from: dd.index(after: eqSign)))
                    print("got cmd <--\(cmd)> with =arg <\(cmdArg)>")
                } else {
                    // just a cmd by itself
                    print("got cmd <--\(dd)>")
                }
            } else if let sd = Self.singleDashCmd(arg) {
                for cmd in sd {
                    print("got cmd <-\(cmd)>")
                }
            } else {
                // it must be an extra argument
                extras.append(arg)
            }
        }
        return extras
    }
}

