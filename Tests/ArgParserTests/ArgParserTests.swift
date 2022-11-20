import XCTest
@testable import ArgParser

final class ParamTests: XCTestCase {
    
    func testFlagParam() throws {
        let fa = FlagParam(names: [], help: "")
        XCTAssertFalse(fa.value, "unset flag should be false")
        try fa.process(param: "")
        XCTAssert(fa.value, "Set flag is true")
    }
    
    func testIntParam() throws {
        let ia = BasicParam(names: [], initial: 2, help: "how many procs?")
        XCTAssertEqual(ia.value, 2, "unset flag should be the initial value")
        try ia.process(param: "abc", arg: "10")
        XCTAssertEqual(ia.value, 10, "set flag for '10' should be 10")
        try ia.process(param: "abc", arg: "-10")
        XCTAssertEqual(ia.value, -10, "set flag for '-10' should be -10")
        XCTAssertThrowsError(try ia.process(param: "v", arg: "mm"), "non-integer arg should throw")
    }
    
    func testUIntParam() throws {
        let uia = BasicParam<UInt8>(names: [], initial: 2, help: "how many procs?")
        XCTAssertEqual(uia.value, 2, "unset flag should be the initial value")
        try uia.process(param: "abc", arg: "10")
        XCTAssertEqual(uia.value, 10, "set flag for '10' should be 10")
        XCTAssertThrowsError(try uia.process(param: "v", arg: "300"), "out of range arg should throw")
        XCTAssertThrowsError(try uia.process(param: "v", arg: "-3"), "out of range arg should throw")
        XCTAssertThrowsError(try uia.process(param: "v", arg: "mm"), "non-integer arg should throw")
    }
    
    func testStringParam() throws {
        let sa = BasicParam(names: [], initial: "unset", help: "a string arg")
        XCTAssertEqual(sa.value, "unset", "unset value should equal the initial value")
        try sa.process(param: "abc", arg: "string value")
        XCTAssertEqual(sa.value, "string value", "set flag should equal what we set")
    }
    
    func testRangedIntParams() throws {
        let ri = RangeLimitedParam(names: ["procs","p"], initial: 1, min: 0, max: 8, help: "how many processes to use")
        XCTAssertEqual(ri.value, 1, "unset flag should be the initial value")
        try ri.process(param: "abc", arg: "8")
        XCTAssertEqual(ri.value, 8, "set flag for '8' should be 8")
        XCTAssertThrowsError(try ri.process(param: "v", arg: "9"), "out of range arg should throw")
        XCTAssertThrowsError(try ri.process(param: "v", arg: "xxx"), "non-integer value should throw")
    }
    
    func testRangedStringParams() throws {
        let rs = RangeLimitedParam(names: ["name","n"], initial: "care", min: "b", max: "d", help: "how many processes to use")
        XCTAssertEqual(rs.value, "care", "unset flag should be the initial value")
        try rs.process(param: "n", arg: "ballast")
        XCTAssertEqual(rs.value, "ballast", "set flag for 'ballast' should be 'ballast'")
        XCTAssertThrowsError(try rs.process(param: "v", arg: "azz"), "out of range arg should throw")
        XCTAssertThrowsError(try rs.process(param: "v", arg: "daa"), "out of range arg should throw")
    }
    
    func testClamptedIntParams() throws {
        let ri = ClampedRangeParam(names: ["procs","p"], initial: 1, min: 0, max: 8, help: "how many processes to use")
        XCTAssertEqual(ri.value, 1, "unset flag should be the initial value")
        try ri.process(param: "abc", arg: "5")
        XCTAssertEqual(ri.value, 5, "set flag for '5' should be 5")
        try ri.process(param: "abc", arg: "100")
        XCTAssertEqual(ri.value, 8, "set flag for '100' should be clampted to 8")
        try ri.process(param: "abc", arg: "-2")
        XCTAssertEqual(ri.value, 0, "set flag for '-2' should be clampted to 0")
    }

    func testAccumulatingParams() throws {
        let ap = AccumulatingParam(names: ["name"], initial: 0, help: "well hello there")
        XCTAssertEqual(ap.value, 0, "unset param should be zero")
        try ap.process(param: "name")
        XCTAssertEqual(ap.value, 1, "should increment")
        try ap.process(param: "name")
        XCTAssertEqual(ap.value, 2, "should increment")
    }
}

final class ArgParserTests : XCTestCase {
    func testParse1() throws {
        let p = BasicParam(names: ["p"], initial: 0, help: "number of processes")
        let ap = ArgParser(p)
        let extras = try ap.parseArgs(["-p","20"])
        XCTAssertEqual(p.value, 20, "given -p 20 should set it to 20")
        XCTAssertTrue(extras.isEmpty, "no extra arguments were given in -p 20 case")
    }

    func testParse2() throws {
        let p = BasicParam(names: ["parse"], initial: "cee", help: "language to parse")
        let ap = ArgParser(p)
        var extras = try ap.parseArgs(["--parse=awk"])
        XCTAssertEqual(p.value, "awk", "given --parse=awk should set it to awk")
        XCTAssertTrue(extras.isEmpty, "no extra arguments were given in --parse=awk case")
        extras = try ap.parseArgs(["--parse","bash"])
        XCTAssertEqual(p.value, "bash", "given --parse bash should set it to bash")
        XCTAssertTrue(extras.isEmpty, "no extra arguments were given in --parse=awk case")
    }

    func testParse3() throws {
        let p = BasicParam(names: ["procs", "p"], initial: 0, help: "number of processes")
        let v = FlagParam(names: ["verbose", "v"], help: "verbose mode")
        let ap = ArgParser(p,v)
        let extras = try ap.parseArgs(["-vp","20"])
        XCTAssertEqual(p.value, 20, "given -p 20 should set it to 20")
        XCTAssertTrue(v.value, "given -v should set it to true")
        XCTAssertTrue(extras.isEmpty, "no extra arguments were given in -vp 20 case")
    }

    func testParse4() throws {
        let p = BasicParam(names: ["procs", "p"], initial: 0, help: "number of processes")
        let v = FlagParam(names: ["verbose", "v"], help: "verbose mode")
        let ap = ArgParser(p,v)
        let extras = try ap.parseArgs(["-vp", "--", "620", "--procs"])
        XCTAssertEqual(p.value, 620, "given -p 620 should set it to 620")
        XCTAssertTrue(v.value, "given -v should set it to true")
        XCTAssertEqual(extras, ["--procs"], "extra arguments were given in -vp -- 620 --procs case")
    }

    func testParse5() throws {
        let p = BasicParam(names: ["procs", "p"], initial: 0, help: "number of processes")
        let v = FlagParam(names: ["verbose", "v"], help: "verbose mode")
        let ap = ArgParser(p,v)
        let args = ["cmdname", "--", "-vp", "--", "620", "--procs"]
        let extras = try ap.parseArgs(args.dropFirst())
        XCTAssertEqual(p.value, 0, "-p should still have default")
        XCTAssertFalse(v.value, "-v should till have default")
        XCTAssertEqual(extras, Array(args.dropFirst(2)), "all args were verbatim")
    }

    func testParse6() throws {
        let p = BasicParam(names: ["procs", "p"], initial: 0, help: "number of processes")
        let v = FlagParam(names: ["verbose", "v"], help: "verbose mode")
        let ap = ArgParser(p,v)
        let extras = try ap.parseArgs(["-v", "-"])
        XCTAssertEqual(p.value, 0, "-p should still be default")
        XCTAssertTrue(v.value, "given -v should set it to true")
        XCTAssertEqual(extras, ["-"], "extra arguments '-' should be there")
    }

}
