import Testing
@testable import bkey

struct PracticeModeTests {
    @Test func practiceModeEndlessEquality() {
        let a: PracticeMode = .endless
        let b: PracticeMode = .endless
        #expect(a == b)
    }

    @Test func practiceModeTimedEquality() {
        let a: PracticeMode = .timed(duration: .sixty)
        let b: PracticeMode = .timed(duration: .sixty)
        #expect(a == b)
    }

    @Test func practiceModeTimedInequality() {
        let a: PracticeMode = .timed(duration: .fifteen)
        let b: PracticeMode = .timed(duration: .sixty)
        #expect(a != b)
    }

    @Test func practiceModeWordCountEquality() {
        let a: PracticeMode = .wordCount(count: .fifty)
        let b: PracticeMode = .wordCount(count: .fifty)
        #expect(a == b)
    }

    @Test func practiceModeCustomEquality() {
        let a: PracticeMode = .custom(text: "hello world")
        let b: PracticeMode = .custom(text: "hello world")
        #expect(a == b)
    }

    @Test func timedDurationAllCases() {
        let cases = TimedDuration.allCases
        #expect(cases.count == 4)
        #expect(cases.map(\.rawValue) == [15, 30, 60, 120])
    }

    @Test func timedDurationDisplayLabel() {
        #expect(TimedDuration.fifteen.displayLabel == "15s")
        #expect(TimedDuration.thirty.displayLabel == "30s")
        #expect(TimedDuration.sixty.displayLabel == "60s")
        #expect(TimedDuration.onetwenty.displayLabel == "2m")
    }

    @Test func wordCountOptionAllCases() {
        let cases = WordCountOption.allCases
        #expect(cases.count == 4)
        #expect(cases.map(\.rawValue) == [10, 25, 50, 100])
    }

    @Test func wordCountOptionDisplayLabel() {
        #expect(WordCountOption.ten.displayLabel == "10")
        #expect(WordCountOption.twentyFive.displayLabel == "25")
        #expect(WordCountOption.fifty.displayLabel == "50")
        #expect(WordCountOption.hundred.displayLabel == "100")
    }

    @Test func practiceModeDisplayName() {
        #expect(PracticeMode.endless.displayName == "Endless")
        #expect(PracticeMode.timed(duration: .sixty).displayName == "Timed — 60s")
        #expect(PracticeMode.wordCount(count: .fifty).displayName == "Words — 50")
        #expect(PracticeMode.custom(text: "abc").displayName == "Custom Text")
    }
}
