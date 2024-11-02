import Testing
import ArgParser

struct ParamTests {
    
    @Test func testFlagParam() throws {
        let fa = FlagParam(names: [], help: "")
        #expect(!fa.value, "unset flag should be false")
        try fa.process(param: "")
        #expect(fa.value, "Set flag is true")
    }
    
    @Test func testIntParam() throws {
        let ia = BasicParam(names: [], initial: 2, help: "how many procs?")
        #expect(ia.value == 2, "unset flag should be the initial value")
        try ia.process(param: "abc", arg: "10")
        #expect(ia.value == 10, "set flag for '10' should be 10")
        try ia.process(param: "abc", arg: "-10")
        #expect(ia.value == -10, "set flag for '-10' should be -10")
        #expect(throws: (any Error).self, "non-integer arg should throw") {
            try ia.process(param: "v", arg: "mm")
        }
    }
    
    @Test func testUIntParam() throws {
        let uia = BasicParam<UInt8>(names: [], initial: 2, help: "how many procs?")
        #expect(uia.value == 2, "unset flag should be the initial value")
        try uia.process(param: "abc", arg: "10")
        #expect(uia.value == 10, "set flag for '10' should be 10")
        #expect(throws: (any Error).self, "out of range arg should throw") {
            try uia.process(param: "v", arg: "300")
        }
        #expect(throws: (any Error).self, "out of range arg should throw") {
            try uia.process(param: "v", arg: "-3")
        }
        #expect(throws: (any Error).self, "non-integer arg should throw") {
            try uia.process(param: "v", arg: "mm")
        }
    }
    
    @Test func testStringParam() throws {
        let sa = BasicParam(names: [], initial: "unset", help: "a string arg")
        #expect(sa.value == "unset", "unset value should equal the initial value")
        try sa.process(param: "abc", arg: "string value")
        #expect(sa.value == "string value", "set flag should equal what we set")
    }
    
    @Test func testRangedIntParams() throws {
        let ri = RangeLimitedParam(names: ["procs","p"], initial: 1, min: 0, max: 8, help: "how many processes to use")
        #expect(ri.value == 1, "unset flag should be the initial value")
        try ri.process(param: "abc", arg: "8")
        #expect(ri.value == 8, "set flag for '8' should be 8")
        #expect(throws: (any Error).self, "out of range arg should throw") {
            try ri.process(param: "v", arg: "9")
        }
        #expect(throws: (any Error).self, "non-integer value should throw") {
            try ri.process(param: "v", arg: "xxx")
        }
    }
    
    @Test func testRangedStringParams() throws {
        let rs = RangeLimitedParam(names: ["name","n"], initial: "care", min: "b", max: "d", help: "how many processes to use")
        #expect(rs.value == "care", "unset flag should be the initial value")
        try rs.process(param: "n", arg: "ballast")
        #expect(rs.value == "ballast", "set flag for 'ballast' should be 'ballast'")
        #expect(throws: (any Error).self, "out of range arg should throw") {
            try rs.process(param: "v", arg: "azz")
        }
        #expect(throws: (any Error).self, "out of range arg should throw") {
            try rs.process(param: "v", arg: "daa")
        }
    }
    
    @Test func testClamptedIntParams() throws {
        let ri = ClampedRangeParam(names: ["procs","p"], initial: 1, min: 0, max: 8, help: "how many processes to use")
        #expect(ri.value == 1, "unset flag should be the initial value")
        try ri.process(param: "abc", arg: "5")
        #expect(ri.value == 5, "set flag for '5' should be 5")
        try ri.process(param: "abc", arg: "100")
        #expect(ri.value == 8, "set flag for '100' should be clampted to 8")
        try ri.process(param: "abc", arg: "-2")
        #expect(ri.value == 0, "set flag for '-2' should be clampted to 0")
    }

    @Test func testAccumulatingParams() throws {
        let ap = AccumulatingParam(names: ["name"], initial: 0, help: "well hello there")
        #expect(ap.value == 0, "unset param should be zero")
        try ap.process(param: "name")
        #expect(ap.value == 1, "should increment")
        try ap.process(param: "name")
        #expect(ap.value == 2, "should increment")
    }
}

struct ArgParserTests {
    @Test func testParse1() throws {
        let p = BasicParam(names: ["p"], initial: 0, help: "number of processes")
        let ap = ArgParser(p)
        let extras = try ap.parseArgs(["-p","20"])
        #expect(p.value == 20, "given -p 20 should set it to 20")
        #expect(extras.isEmpty, "no extra arguments were given in -p 20 case")
    }

    @Test func testParse2() throws {
        let p = BasicParam(names: ["parse"], initial: "cee", help: "language to parse")
        let ap = ArgParser(p)
        var extras = try ap.parseArgs(["--parse=awk"])
        #expect(p.value == "awk", "given --parse=awk should set it to awk")
        #expect(extras.isEmpty, "no extra arguments were given in --parse=awk case")
        extras = try ap.parseArgs(["--parse","bash"])
        #expect(p.value == "bash", "given --parse bash should set it to bash")
        #expect(extras.isEmpty, "no extra arguments were given in --parse=awk case")
    }

    @Test func testParse3() throws {
        let p = BasicParam(names: ["procs", "p"], initial: 0, help: "number of processes")
        let v = FlagParam(names: ["verbose", "v"], help: "verbose mode")
        let ap = ArgParser(p,v)
        let extras = try ap.parseArgs(["-vp","20"])
        #expect(p.value == 20, "given -p 20 should set it to 20")
        #expect(v.value, "given -v should set it to true")
        #expect(extras.isEmpty, "no extra arguments were given in -vp 20 case")
    }

    @Test func testParse4() throws {
        let p = BasicParam(names: ["procs", "p"], initial: 0, help: "number of processes")
        let v = FlagParam(names: ["verbose", "v"], help: "verbose mode")
        let ap = ArgParser(p,v)
        let extras = try ap.parseArgs(["-vp", "--", "620", "--procs"])
        #expect(p.value == 620, "given -p 620 should set it to 620")
        #expect(v.value, "given -v should set it to true")
        #expect(extras == ["--procs"], "extra arguments were given in -vp -- 620 --procs case")
    }

    @Test func testParse5() throws {
        let p = BasicParam(names: ["procs", "p"], initial: 0, help: "number of processes")
        let v = FlagParam(names: ["verbose", "v"], help: "verbose mode")
        let ap = ArgParser(p,v)
        let args = ["cmdname", "--", "-vp", "--", "620", "--procs"]
        let extras = try ap.parseArgs(args.dropFirst())
        #expect(p.value == 0, "-p should still have default")
        #expect(!v.value, "-v should till have default")
        #expect(extras == Array(args.dropFirst(2)), "all args were verbatim")
    }

    @Test func testParse6() throws {
        let p = BasicParam(names: ["procs", "p"], initial: 0, help: "number of processes")
        let v = FlagParam(names: ["verbose", "v"], help: "verbose mode")
        let ap = ArgParser(p,v)
        let extras = try ap.parseArgs(["-v", "-"])
        #expect(p.value == 0, "-p should still be default")
        #expect(v.value, "given -v should set it to true")
        #expect(extras == ["-"], "extra arguments '-' should be there")
    }

}
