public class ArgParser {
    private let longArgs : [String: Argument]
    private let shortArgs : [Character: Argument]

    public init(forSpec spec: Argument...) {
       var largs : [String: Argument] = [:]
       var sargs : [Character: Argument] = [:]
       for arg in spec {
          largs[arg.name] = arg
          if let ch = arg.shortName {
             sargs[ch] = arg
          }
       }
       longArgs = largs
       shortArgs = sargs
    }

    /**
    Get parameter help text.
    */
    public func argumentHelpText() -> String {
       var ostr = ""
       for k in longArgs.keys.sorted() {
          ostr.append(longArgs[k]!.helpText())
       }
       return ostr
    }

    /**
    Parse the given `args`, setting any parameters and returning the
    list of extra arguments not associated with parameters.
    */
    public func parseArgs(_ args: [String]) throws -> [String] {
        // TODO actually parse
        return args
    }
}

