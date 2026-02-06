import Testing
import Foundation
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

    @Test func restartResetsSession() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hello", "world"]))
        session.start()
        session.processCharacter("h")
        session.processCharacter("e")
        #expect(session.currentIndex == 2)
        session.restart()
        #expect(session.state == .ready)
        #expect(session.currentIndex == 0)
        #expect(session.keystrokes == 0)
        #expect(session.errors == 0)
        #expect(session.correctChars == 0)
        #expect(session.startTime == nil)
    }

    @Test func processCharacterIgnoredWhenComplete() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["a"]))
        session.start()
        for char in session.targetText {
            session.processCharacter(char)
        }
        #expect(session.state == .complete)
        let indexAfterComplete = session.currentIndex
        session.processCharacter("x")
        #expect(session.currentIndex == indexAfterComplete)
    }

    @Test func processBackspaceIgnoredWhenNotActive() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        #expect(session.state == .ready)
        session.processBackspace()
        #expect(session.currentIndex == 0)
    }

    @Test func processBackspaceIgnoredAtStartOfText() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("h") // activate
        // Backspace to 0
        session.processBackspace()
        #expect(session.currentIndex == 0)
        // Try again at 0 — should not go negative
        session.processBackspace()
        #expect(session.currentIndex == 0)
    }

    @Test func currentCharacterReturnsNilAtEnd() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["a"]))
        session.start()
        for char in session.targetText {
            session.processCharacter(char)
        }
        #expect(session.currentCharacter == nil)
    }

    @Test func currentWordIndexTracksProgress() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["ab", "cd"]))
        session.start()
        // At start, word index is 0
        #expect(session.currentWordIndex == 0)
        // Type "ab" + space
        session.processCharacter("a")
        session.processCharacter("b")
        #expect(session.currentWordIndex == 0) // still in word 0 at the space
        session.processCharacter(" ")
        #expect(session.currentWordIndex == 1) // now in word 1
    }

    @Test func timestampedKeystrokesRecorded() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("h")
        session.processCharacter("x") // wrong
        #expect(session.timestampedKeystrokes.count == 2)
        #expect(session.timestampedKeystrokes[0].correct == true)
        #expect(session.timestampedKeystrokes[1].correct == false)
    }

    @Test func forceCorrectModeDoesNotAdvanceOnError() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]), errorMode: .forceCorrect)
        session.start()
        session.processCharacter("x") // wrong — should NOT advance
        #expect(session.currentIndex == 0)
        #expect(session.errors == 1)
        #expect(session.keystrokes == 1)
        // Pressing wrong again increments errors but stays put
        session.processCharacter("z")
        #expect(session.currentIndex == 0)
        #expect(session.errors == 2)
        #expect(session.keystrokes == 2)
        // Correct key advances
        session.processCharacter("h")
        #expect(session.currentIndex == 1)
    }

    @Test func stopOnWordModeDoesNotAdvanceOnError() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]), errorMode: .stopOnWord)
        session.start()
        session.processCharacter("x") // wrong — should NOT advance
        #expect(session.currentIndex == 0)
        #expect(session.errors == 1)
        // Correct key advances
        session.processCharacter("h")
        #expect(session.currentIndex == 1)
    }

    @Test func continueOnErrorModeAdvancesOnError() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]), errorMode: .continueOnError)
        session.start()
        session.processCharacter("x") // wrong — SHOULD advance
        #expect(session.currentIndex == 1)
        #expect(session.errors == 1)
    }

    @Test func characterKeystrokesRecorded() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("h") // correct
        session.processCharacter("x") // wrong — expected 'i'
        #expect(session.characterKeystrokes.count == 2)
        #expect(session.characterKeystrokes[0].character == "h")
        #expect(session.characterKeystrokes[0].correct == true)
        #expect(session.characterKeystrokes[1].character == "i") // expected char, not typed char
        #expect(session.characterKeystrokes[1].correct == false)
    }

    @Test func characterKeystrokesClearedOnRestart() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("h")
        #expect(session.characterKeystrokes.count == 1)
        session.restart()
        #expect(session.characterKeystrokes.isEmpty)
    }

    @Test func endSessionFromNonActiveStateDoesNothing() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        #expect(session.state == .ready)
        session.endSession()
        #expect(session.state == .ready) // unchanged
        #expect(session.endTime == nil)
    }

    @Test func forceCorrectModeCompletesSessionWhenAllCorrect() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["a"]), errorMode: .forceCorrect)
        session.start()
        // Type all chars correctly
        for char in session.targetText {
            session.processCharacter(char)
        }
        #expect(session.state == .complete)
        #expect(session.errors == 0)
    }

    @Test func forceCorrectModeRecordsCharacterKeystrokesOnError() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["ab"]), errorMode: .forceCorrect)
        session.start()
        session.processCharacter("x") // wrong for 'a'
        session.processCharacter("a") // correct
        #expect(session.characterKeystrokes.count == 2)
        // Both refer to expected char 'a' since we didn't advance
        #expect(session.characterKeystrokes[0].character == "a")
        #expect(session.characterKeystrokes[0].correct == false)
        #expect(session.characterKeystrokes[1].character == "a")
        #expect(session.characterKeystrokes[1].correct == true)
    }

    @Test func defaultErrorModeIsContinueOnError() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        #expect(session.errorMode == .continueOnError)
    }

    @Test func endSessionSetsEndTime() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("h") // activate
        session.endSession()
        #expect(session.endTime != nil)
        #expect(session.state == .complete)
    }

    @Test func endSessionCalledTwiceDoesNotChangeEndTime() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("h")
        session.endSession()
        let firstEndTime = session.endTime
        session.endSession() // second call — state is .complete, not .active
        #expect(session.endTime == firstEndTime)
    }

    @Test func multipleWordsJoinedWithSpaces() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["cat", "dog"]))
        session.start()
        // targetText contains spaces between words
        #expect(session.targetText.contains(" "))
        // Each word should be either "cat" or "dog"
        let words = session.targetText.split(separator: " ")
        #expect(words.allSatisfy { $0 == "cat" || $0 == "dog" })
    }

    @Test func wordBoundariesComputedCorrectly() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["ab", "cd"]))
        session.start()
        // word boundaries: 0 (start of "ab"), 3 (start of "cd"), ...
        #expect(session.wordBoundaries[0] == 0)
        #expect(session.wordBoundaries[1] == 3) // "ab" (2) + " " (1) = 3
    }

    @Test func backspaceWorksWithinSameWord() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["abc"]))
        session.start()
        session.processCharacter("a") // index 1
        session.processCharacter("x") // wrong, index 2 (continueOnError)
        session.processBackspace()     // back to 1
        session.processBackspace()     // back to 0
        #expect(session.currentIndex == 0)
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

    @Test func grossWPMZeroSecondsReturnsZero() {
        let wpm = SessionMetrics.grossWPM(correctChars: 50, elapsedSeconds: 0)
        #expect(wpm == 0)
    }

    @Test func netWPMFloorsAtZero() {
        // More errors than gross WPM should floor at 0
        let net = SessionMetrics.netWPM(correctChars: 10, errors: 100, elapsedSeconds: 60)
        #expect(net == 0)
    }

    @Test func netWPMZeroSecondsReturnsZero() {
        let net = SessionMetrics.netWPM(correctChars: 50, errors: 5, elapsedSeconds: 0)
        #expect(net == 0)
    }

    @Test func bestWPMEmptyArrayReturnsZero() {
        let best = SessionMetrics.bestWPM(keystrokes: [])
        #expect(best == 0)
    }

    @Test func bestWPMSingleKeystrokeReturnsZero() {
        let best = SessionMetrics.bestWPM(keystrokes: [(time: Date(), correct: true)])
        #expect(best == 0)
    }

    @Test func accuracyWithZeroKeystrokesReturns100() {
        let acc = SessionMetrics.accuracy(correctChars: 0, totalKeystrokes: 0)
        #expect(acc == 100.0)
    }

    @Test func bestWPMWithMultipleKeystrokes() {
        let start = Date()
        // Simulate 10 correct keystrokes over 10 seconds
        var keystrokes: [(time: Date, correct: Bool)] = []
        for i in 0..<10 {
            keystrokes.append((time: start.addingTimeInterval(Double(i)), correct: true))
        }
        let best = SessionMetrics.bestWPM(keystrokes: keystrokes)
        // 10 correct chars in 10-second window => (10/5) / (10/60) = 12 WPM
        #expect(best == 12.0)
    }

    @Test func bestWPMIgnoresIncorrectKeystrokes() {
        let start = Date()
        var keystrokes: [(time: Date, correct: Bool)] = []
        for i in 0..<5 {
            keystrokes.append((time: start.addingTimeInterval(Double(i)), correct: true))
        }
        for i in 5..<10 {
            keystrokes.append((time: start.addingTimeInterval(Double(i)), correct: false))
        }
        let best = SessionMetrics.bestWPM(keystrokes: keystrokes)
        // Best window will include 5 correct out of 10-second window
        // (5/5) / (10/60) = 6 WPM
        #expect(best == 6.0)
    }

    @Test func grossWPMWith30Seconds() {
        // 25 correct chars in 30 seconds = (25/5) / 0.5 = 10 WPM
        let wpm = SessionMetrics.grossWPM(correctChars: 25, elapsedSeconds: 30)
        #expect(wpm == 10.0)
    }

    @Test func formattedTimeWithLargeValue() {
        #expect(SessionMetrics.formattedTime(125) == "2:05")
        #expect(SessionMetrics.formattedTime(59) == "0:59")
    }
}
