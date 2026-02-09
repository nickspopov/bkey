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

// MARK: - TypingSession forceComplete

struct ForceCompleteTests {
    @Test func forceCompleteTransitionsActiveToComplete() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hello"]))
        session.start()
        session.processCharacter("h") // activate
        #expect(session.state == .active)
        session.forceComplete()
        #expect(session.state == .complete)
        #expect(session.endTime != nil)
    }

    @Test func forceCompleteFromReadyDoesNothing() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hello"]))
        session.start()
        #expect(session.state == .ready)
        session.forceComplete()
        #expect(session.state == .ready)
        #expect(session.endTime == nil)
    }

    @Test func forceCompleteFromCompleteDoesNothing() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["a"]))
        session.start()
        for char in session.targetText {
            session.processCharacter(char)
        }
        #expect(session.state == .complete)
        let originalEnd = session.endTime
        session.forceComplete()
        #expect(session.endTime == originalEnd)
    }
}

// MARK: - TypingSession custom text

struct CustomTextSessionTests {
    @Test func sessionWithCustomTextUsesDirectText() {
        let session = TypingSession(customText: "hello world")
        session.start()
        #expect(session.targetText == "hello world")
        #expect(session.characterStates.count == 11)
    }

    @Test func sessionWithCustomTextCompletesNormally() {
        let session = TypingSession(customText: "ab")
        session.start()
        session.processCharacter("a")
        session.processCharacter("b")
        #expect(session.state == .complete)
    }
}

// MARK: - WordGenerator exact count

struct WordGeneratorExactCountTests {
    @Test func generateExactCountReturnsExactWords() {
        let gen = WordGenerator(words: ["alpha", "beta", "gamma", "delta"])
        let result = gen.generateExact(count: 10)
        #expect(result.count == 10)
    }

    @Test func generateExactCountNoRepeats() {
        let gen = WordGenerator(words: ["a", "b", "c"])
        let result = gen.generateExact(count: 20)
        for i in 1..<result.count {
            #expect(result[i] != result[i-1], "Repeat at index \(i)")
        }
    }

    @Test func generateExactCountSingleWordStillWorks() {
        let gen = WordGenerator(words: ["only"])
        let result = gen.generateExact(count: 5)
        #expect(result.count == 5)
        #expect(result.allSatisfy { $0 == "only" })
    }

    @Test func generateExactCountEmptyReturnsEmpty() {
        let gen = WordGenerator(words: [])
        let result = gen.generateExact(count: 5)
        #expect(result.isEmpty)
    }
}

// MARK: - Custom text normalization

struct CustomTextNormalizationTests {
    @Test func normalizeCollapseMultipleSpaces() {
        let result = PracticeMode.normalizeCustomText("hello   world")
        #expect(result == "hello world")
    }

    @Test func normalizeNewlinesToSpaces() {
        let result = PracticeMode.normalizeCustomText("hello\nworld")
        #expect(result == "hello world")
    }

    @Test func normalizeTrimWhitespace() {
        let result = PracticeMode.normalizeCustomText("  hello world  ")
        #expect(result == "hello world")
    }

    @Test func normalizeTabsToSpaces() {
        let result = PracticeMode.normalizeCustomText("hello\t\tworld")
        #expect(result == "hello world")
    }

    @Test func normalizeTruncatesAt10000Chars() {
        let longText = String(repeating: "a ", count: 6000) // 12000 chars
        let result = PracticeMode.normalizeCustomText(longText)
        #expect(result.count <= 10000)
    }

    @Test func normalizeEmptyTextReturnsEmpty() {
        let result = PracticeMode.normalizeCustomText("")
        #expect(result == "")
    }

    @Test func normalizeWhitespaceOnlyReturnsEmpty() {
        let result = PracticeMode.normalizeCustomText("   \n\t  ")
        #expect(result == "")
    }
}

// MARK: - Exact word count session

struct ExactWordCountSessionTests {
    @Test func sessionWithExactWordCountProducesCorrectCount() {
        let gen = WordGenerator(words: ["alpha", "beta", "gamma", "delta", "echo"])
        let session = TypingSession(wordGenerator: gen, errorMode: .continueOnError, targetWordCount: 10)
        session.start()
        let wordCount = session.targetText.split(separator: " ").count
        #expect(wordCount == 10)
    }

    @Test func sessionWithoutExactWordCountProduces50() {
        let gen = WordGenerator(words: ["alpha", "beta", "gamma"])
        let session = TypingSession(wordGenerator: gen)
        session.start()
        let wordCount = session.targetText.split(separator: " ").count
        #expect(wordCount == 50)
    }
}
