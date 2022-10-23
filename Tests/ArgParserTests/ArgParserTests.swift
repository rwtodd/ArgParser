import XCTest
@testable import ArgParser

final class ArgParserTests: XCTestCase {
    func testFlagParam() throws {
        let fa = FlagParam(names: [], help: "")
        XCTAssertFalse(fa.value, "unset flag should be false")
        try fa.process(param: "")
        XCTAssert(fa.value, "Set flag is true")
    }
    
    func testIntParam() throws {
        let ia = IntParam(names: [], initial: 2, help: "how many procs?")
        XCTAssertEqual(ia.value, 2, "unset flag should be the initial value")
        try ia.process(param: "abc", arg: "10")
        XCTAssertEqual(ia.value, 10, "set flag for '10' should be 10")
    }
    
    func testStringParam() throws {
        let sa = StringParam(names: [], initial: "unset", help: "a string arg")
        XCTAssertEqual(sa.value, "unset", "unset value should equal the initial value")
        try sa.process(param: "abc", arg: "string value")
        XCTAssertEqual(sa.value, "string value", "set flag should equal what we set")
    }
}
