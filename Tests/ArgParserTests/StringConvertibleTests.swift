import Foundation
import Testing
import ArgParser

/**
 Tessts of BasicParam with IntegerSequenceArg
 */
struct IntSeqArgTests {
    var isa : BasicParam<IntegerSequenceArg>?
    
    init() {
        isa = BasicParam<IntegerSequenceArg>(names: ["isa"], initial: IntegerSequenceArg(), help: "")
    }
    
    @Test func testDefaultEmpty() throws {
        #expect(Array(isa!.value.seq) == [])
    }
    
    @Test func testSingleVal() throws {
        try isa!.process(param: "isa", arg: "1")
        #expect(Array(isa!.value.seq) == [1])
    }

    @Test func testSingleVal2() throws {
        try isa!.process(param: "isa", arg: "-14")
        #expect(Array(isa!.value.seq) == [-14])
    }

    @Test func testSingleRange() throws {
        try isa!.process(param: "isa", arg: "-2..2")
        #expect(Array(isa!.value.seq) == [-2,-1,0,1,2])
    }

    @Test func testSingleRange2() throws {
        try isa!.process(param: "isa", arg: "10..12")
        #expect(Array(isa!.value.seq) == [10,11,12])
    }

    // right now, we don't support backwards ranges... maybe in the future find
    // a way to allow it
    @Test func testBackwardRange() throws {
        #expect(throws: (any Error).self) { try isa!.process(param: "isa", arg: "14..12") }
    }
    
    @Test func testNonNumber() throws {
        #expect(throws: (any Error).self) { try isa!.process(param: "isa", arg: "14a") }
    }

    @Test func testMultipleNums() throws {
        try isa!.process(param: "isa", arg: "1,2,3")
        #expect(Array(isa!.value.seq) == [1,2,3])
    }
    
    @Test func testMultipleNums2() throws {
        try isa!.process(param: "isa", arg: "1,-5,3")
        #expect(Array(isa!.value.seq) == [1,-5,3])
    }

    @Test func testMultipleNums3() throws {
        try isa!.process(param: "isa", arg: "1,10..12,3")
        #expect(Array(isa!.value.seq) == [1,10,11,12,3])
    }

    @Test func testEmptyArg() throws {
        try isa!.process(param: "isa", arg: "")
        #expect(Array(isa!.value.seq) == [])
    }
    
    @Test func testStringConversion() throws {
        try isa!.process(param: "isa", arg: "-10,14..16,18..20")
        #expect(isa!.value.description == "-10,14,15,16,18,19,20")
    }
    
    @Test func testStringConversionWhenEmpty() throws {
        try isa!.process(param: "isa", arg: "")
        #expect(isa!.value.description == "")
    }
    
    @Test func testArgConstructor() throws {
        let arg = IntegerSequenceArg([1...3,6...6])
        #expect(arg.description == "1,2,3,6")
    }

}

/**
 Tessts of DateArg
 */
struct YMDArgTests  {
    var da : BasicParam<YMDArg>?
    
    init() {
        da = BasicParam<YMDArg>(names: ["da"], initial: YMDArg(), help: "")
    }
    
    @Test func testDefaultSetting() throws {
        let today = Calendar.current.startOfDay(for: Date())
        #expect(da!.value.date == today)
    }
    
    @Test func testTPlusTMinusDates() throws {
        var dc = Calendar.current.dateComponents([.year,.month,.day], from: Date())
        try da!.process(param: "da", arg: "t")
        #expect(da!.value == YMDArg(year: dc.year!, month: dc.month!, day: dc.day!))

        try da!.process(param: "da", arg: "t+0")
        #expect(da!.value == YMDArg(year: dc.year!, month: dc.month!, day: dc.day!))

        try da!.process(param: "da", arg: "t-0")
        #expect(da!.value == YMDArg(year: dc.year!, month: dc.month!, day: dc.day!))
        
        dc = Calendar.current.dateComponents([.year,.month,.day], from: Calendar.current.date(byAdding: .day, value: 5, to: Date())!)
        try da!.process(param: "da", arg: "t+5")
        #expect(da!.value == YMDArg(year: dc.year!, month: dc.month!, day: dc.day!))

        dc = Calendar.current.dateComponents([.year,.month,.day], from: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
        try da!.process(param: "da", arg: "t-5")
        #expect(da!.value == YMDArg(year: dc.year!, month: dc.month!, day: dc.day!))
    }
    
    @Test func testSimpleDates() throws {
        try da!.process(param: "da", arg: "2011-01-01")
        #expect(da!.value == YMDArg(year: 2011, month: 1, day: 1)!)
        try da!.process(param: "da", arg: "1977-06-02")
        #expect(da!.value == YMDArg(year: 1977, month: 6, day: 2)!)
    }
    
    @Test func testAbbreviatedDates() throws {
        let dc = Calendar.current.dateComponents([.year,.month], from: Date())
        try da!.process(param: "da", arg: "11-14")
        #expect(da!.value.description == "\(dc.year!)-11-14")
        
        try da!.process(param: "da", arg: "14")
        #expect(da!.value.description == "\(dc.year!)-\(dc.month!)-14")
    }
    
    @Test func testSpecialArgs() throws {
        let today = Calendar.current.startOfDay(for: Date())
        try da!.process(param: "da", arg: "Today")
        #expect(da!.value.date == today)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        try da!.process(param: "da", arg: "yesterDAY")
        #expect(da!.value == YMDArg(yesterday))
        
        let tomorrow =  Calendar.current.date(byAdding: .day, value: 1, to: today)!
        try da!.process(param: "da", arg: "TOmorroW")
        #expect(da!.value == YMDArg(tomorrow))
    }
    
    @Test func testBadDates() throws {
        #expect(YMDArg("2011-21-blah") == nil)
        #expect(YMDArg("") == nil)
        #expect(YMDArg("1-2-2011") == nil)
        #expect(YMDArg("12-32") == nil)
        #expect(YMDArg("0-0-0") == nil)
        #expect(YMDArg("2018-0-14") == nil)
    }
    
    @Test func testClampableDates() throws {
        let cda = ClampedRangeParam(
            names: ["date"],
            initial: YMDArg(year:2022,month:12,day:1)!,
            min: YMDArg(year:2022,month:11,day:15)!,
            max: YMDArg(year:2022,month:12,day:15)!,
            help: "between nov 15 and dec 15 in year 2022")
        #expect(cda.value == YMDArg(year:2022,month:12,day:1))
        try cda.process(param: "date", arg: "2022-11-14")
        #expect(cda.value == YMDArg(year:2022,month:11,day:15))
        try cda.process(param: "date", arg: "2012-1-1")
        #expect(cda.value == YMDArg(year:2022,month:11,day:15))
        try cda.process(param: "date", arg: "2000-12-3")
        #expect(cda.value == YMDArg(year:2022,month:11,day:15))
        try cda.process(param: "date", arg: "2023-12-1")
        #expect(cda.value == YMDArg(year:2022,month:12,day:15))
        try cda.process(param: "date", arg: "2022-12-16")
        #expect(cda.value == YMDArg(year:2022,month:12,day:15))
    }
}
