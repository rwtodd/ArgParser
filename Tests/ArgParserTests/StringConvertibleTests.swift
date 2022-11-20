import Foundation
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
    
    func testArgConstructor() throws {
        let arg = IntegerSequenceArg([1...3,6...6])
        XCTAssertEqual(arg.description, "1,2,3,6")
    }

}


/**
 Tessts of DateArg
 */
final class YMDArgTests : XCTestCase {
    var da : BasicParam<YMDArg>?
    
    override func setUp() {
        super.setUp()
        da = BasicParam<YMDArg>(names: ["da"], initial: YMDArg(), help: "")
    }
    
    func testDefaultSetting() throws {
        let today = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(da!.value.date, today)
    }
    
    func testSimpleDates() throws {
        try da!.process(param: "da", arg: "2011-01-01")
        XCTAssertEqual(da!.value, YMDArg(year: 2011, month: 1, day: 1)!)
        try da!.process(param: "da", arg: "1977-06-02")
        XCTAssertEqual(da!.value, YMDArg(year: 1977, month: 6, day: 2)!)
    }
    
    func testAbbreviatedDates() throws {
        let dc = Calendar.current.dateComponents([.year,.month], from: Date())
        try da!.process(param: "da", arg: "11-14")
        XCTAssertEqual(da!.value.description, "\(dc.year!)-11-14")
        
        try da!.process(param: "da", arg: "14")
        XCTAssertEqual(da!.value.description, "\(dc.year!)-\(dc.month!)-14")
    }
    
    func testSpecialArgs() throws {
        let today = Calendar.current.startOfDay(for: Date())
        try da!.process(param: "da", arg: "Today")
        XCTAssertEqual(da!.value.date, today)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        try da!.process(param: "da", arg: "yesterDAY")
        XCTAssertEqual(da!.value, YMDArg(yesterday))
        
        let tomorrow =  Calendar.current.date(byAdding: .day, value: 1, to: today)!
        try da!.process(param: "da", arg: "TOmorroW")
        XCTAssertEqual(da!.value, YMDArg(tomorrow))
    }
    
    func testBadDates() throws {
        XCTAssertNil(YMDArg("2011-21-blah"))
        XCTAssertNil(YMDArg(""))
        XCTAssertNil(YMDArg("1-2-2011"))
        XCTAssertNil(YMDArg("12-32"))
        XCTAssertNil(YMDArg("0-0-0"))
        XCTAssertNil(YMDArg("2018-0-14"))
    }
    
    func testClampableDates() throws {
        let cda = ClampedRangeParam(
            names: ["date"],
            initial: YMDArg(year:2022,month:12,day:1)!,
            min: YMDArg(year:2022,month:11,day:15)!,
            max: YMDArg(year:2022,month:12,day:15)!,
            help: "between nov 15 and dec 15 in year 2022")
        XCTAssertEqual(cda.value, YMDArg(year:2022,month:12,day:1))
        try cda.process(param: "date", arg: "2022-11-14")
        XCTAssertEqual(cda.value, YMDArg(year:2022,month:11,day:15))
        try cda.process(param: "date", arg: "2012-1-1")
        XCTAssertEqual(cda.value, YMDArg(year:2022,month:11,day:15))
        try cda.process(param: "date", arg: "2000-12-3")
        XCTAssertEqual(cda.value, YMDArg(year:2022,month:11,day:15))
        try cda.process(param: "date", arg: "2023-12-1")
        XCTAssertEqual(cda.value, YMDArg(year:2022,month:12,day:15))
        try cda.process(param: "date", arg: "2022-12-16")
        XCTAssertEqual(cda.value, YMDArg(year:2022,month:12,day:15))
    }
}
