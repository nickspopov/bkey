import Testing
@testable import bkey

struct TypingSessionTests {
    @Test func sessionStartsInReadyState() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hello", "world"]))
        session.start()
        #expect(session.state == .ready)
        #expect(session.currentIndex == 0)
        #expect(session.targetText.contains("hello"))
    }

    @Test func firstKeystrokeActivatesSession() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["ab"]))
        session.start()
        session.processCharacter("a")
        #expect(session.state == .active)
        #expect(session.startTime != nil)
    }

    @Test func correctCharacterAdvancesIndex() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        // targetText is at least "hi" (possibly followed by more words)
        session.processCharacter("h")
        #expect(session.characterStates[0] == .correct)
        #expect(session.currentIndex == 1)
        #expect(session.correctChars == 1)
    }

    @Test func incorrectCharacterMarksError() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("x") // wrong
        #expect(session.characterStates[0] == .incorrect)
        #expect(session.errors == 1)
        #expect(session.currentIndex == 1)
    }

    @Test func backspaceRetreatsIndex() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("h")
        session.processCharacter("x") // wrong
        session.processBackspace()
        #expect(session.currentIndex == 1)
        #expect(session.characterStates[1] == .pending)
    }

    @Test func backspaceDoesNotCrossWordBoundary() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["a", "b"]))
        session.start()
        // targetText = "a b ..." — type "a", then space to move to next word
        session.processCharacter("a")
        session.processCharacter(" ")
        // Now at start of word "b", backspace should not go back to "a"
        session.processBackspace()
        #expect(session.currentIndex == 2) // stays at "b"
    }

    @Test func sessionCompletesWhenAllCharsTyped() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["a"]))
        session.start()
        // Type all characters in the target
        for char in session.targetText {
            session.processCharacter(char)
        }
        #expect(session.state == .complete)
    }
}

struct SessionMetricsTests {
    @Test func grossWPMCalculation() {
        // 50 correct chars in 60 seconds = (50/5)/1 = 10 WPM
        let wpm = SessionMetrics.grossWPM(correctChars: 50, elapsedSeconds: 60)
        #expect(wpm == 10.0)
    }

    @Test func accuracyCalculation() {
        let acc = SessionMetrics.accuracy(correctChars: 90, totalKeystrokes: 100)
        #expect(acc == 90.0)
    }

    @Test func accuracyWith100Percent() {
        let acc = SessionMetrics.accuracy(correctChars: 50, totalKeystrokes: 50)
        #expect(acc == 100.0)
    }

    @Test func netWPMWithErrors() {
        // gross = (50/5)/1 = 10, penalty = 5/1 = 5, net = 5
        let net = SessionMetrics.netWPM(correctChars: 50, errors: 5, elapsedSeconds: 60)
        #expect(net == 5.0)
    }

    @Test func formattedTime() {
        #expect(SessionMetrics.formattedTime(65) == "1:05")
        #expect(SessionMetrics.formattedTime(0) == "0:00")
        #expect(SessionMetrics.formattedTime(3600) == "60:00")
    }
}
