import XCTest
@testable import ArgParser

/**
 Tessts of BasicParam with IntegerSequenceArg
 */
final class IntSeqArgTests : XCTestCase {
    var isa : BasicParam<IntegerSequenceArg>?
    
    override func setUp() {
        super.setUp()
        isa = BasicParam<IntegerSequenceArg>(names: ["isa"], initial: IntegerSequenceArg(), help: "")
    }
    
    func testDefaultEmpty() throws {
        XCTAssertEqual(Array(isa!.value.seq), [])
    }
    
    func testSingleVal() throws {
        try isa!.process(param: "isa", arg: "1")
        XCTAssertEqual(Array(isa!.value.seq),[1])
    }

    func testSingleVal2() throws {
        try isa!.process(param: "isa", arg: "-14")
        XCTAssertEqual(Array(isa!.value.seq),[-14])
    }

    func testSingleRange() throws {
        try isa!.process(param: "isa", arg: "-2..2")
        XCTAssertEqual(Array(isa!.value.seq),[-2,-1,0,1,2])
    }

    func testSingleRange2() throws {
        try isa!.process(param: "isa", arg: "10..12")
        XCTAssertEqual(Array(isa!.value.seq),[10,11,12])
    }

    // right now, we don't support backwards ranges... maybe in the future find
    // a way to allow it
    func testBackwardRange() throws {
        XCTAssertThrowsError(try isa!.process(param: "isa", arg: "14..12"))
    }
    
    func testNonNumber() throws {
        XCTAssertThrowsError(try isa!.process(param: "isa", arg: "14a"))
    }

    func testMultipleNums() throws {
        try isa!.process(param: "isa", arg: "1,2,3")
        XCTAssertEqual(Array(isa!.value.seq), [1,2,3])
    }
    
    func testMultipleNums2() throws {
        try isa!.process(param: "isa", arg: "1,-5,3")
        XCTAssertEqual(Array(isa!.value.seq), [1,-5,3])
    }

    func testMultipleNums3() throws {
        try isa!.process(param: "isa", arg: "1,10..12,3")
        XCTAssertEqual(Array(isa!.value.seq), [1,10,11,12,3])
    }

    func testEmptyArg() throws {
        try isa!.process(param: "isa", arg: "")
        XCTAssertEqual(Array(isa!.value.seq), [])
    }
    
    func testStringConversion() throws {
        try isa!.process(param: "isa", arg: "-10,14..16,18..20")
        XCTAssertEqual(isa!.value.description, "-10,14,15,16,18,19,20")
    }
    
    func testStringConversionWhenEmpty() throws {
        try isa!.process(param: "isa", arg: "")
        XCTAssertEqual(isa!.value.description, "")
    }

}
