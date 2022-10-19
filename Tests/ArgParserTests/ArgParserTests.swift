import XCTest
@testable import ArgParser

final class ArgParserTests: XCTestCase {
    func testFlagArg() throws {
        let fa = FlagArg(name: "procs" , help: "the flag")
        XCTAssertFalse(fa.value, "unset flag should be false")
        try fa.process("")
        XCTAssert(fa.value, "Set flag is true")
    }

    func testIntArg() throws {
        let ia = IntArg(name: "procs", initial: 2, help: "how many procs?") 
        XCTAssertEqual(ia.value, 2, "unset flag should be the initial value")
        try ia.process("10")
        XCTAssertEqual(ia.value, 10, "set flag for '10' should be 10")
    }

    func testStringArg() throws {
        let sa = StringArg(name: "arg", initial: "unset", help: "a string arg")
        XCTAssertEqual(sa.value, "unset", "unset value should equal the initial value")
        try sa.process("string value")
        XCTAssertEqual(sa.value, "string value", "set flag should equal what we set")
    }
}
