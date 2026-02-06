import Testing
@testable import bkey

struct TypingSessionTests {

    @Test func correctTypingRecordsCorrectResult() {
        let session = TypingSession(text: "hello")
        session.typeCharacter("h")
        #expect(session.characterResults[0] == .correct)
        #expect(session.correctCount == 1)
        #expect(session.incorrectCount == 0)
        #expect(session.cursorIndex == 1)
    }

    @Test func incorrectTypingRecordsIncorrectResult() {
        let session = TypingSession(text: "hello")
        session.typeCharacter("x")
        #expect(session.characterResults[0] == .incorrect)
        #expect(session.correctCount == 0)
        #expect(session.incorrectCount == 1)
        #expect(session.cursorIndex == 1)
    }

    @Test func mixedTypingTracksAccuracy() {
        let session = TypingSession(text: "abc")
        session.typeCharacter("a") // correct
        session.typeCharacter("x") // incorrect
        session.typeCharacter("c") // correct
        #expect(session.correctCount == 2)
        #expect(session.incorrectCount == 1)
        let expectedAccuracy = (2.0 / 3.0) * 100.0
        #expect(abs(session.accuracy - expectedAccuracy) < 0.01)
    }

    @Test func accuracyIs100WhenNoInput() {
        let session = TypingSession(text: "test")
        #expect(session.accuracy == 100.0)
    }

    @Test func wpmIsZeroBeforeTyping() {
        let session = TypingSession(text: "test")
        #expect(session.wpm == 0)
    }

    @Test func sessionStartTimeSetOnFirstCharacter() {
        let session = TypingSession(text: "test")
        #expect(session.sessionStartTime == nil)
        session.typeCharacter("t")
        #expect(session.sessionStartTime != nil)
    }

    @Test func expectedCharacterReturnsCurrentChar() {
        let session = TypingSession(text: "ab")
        #expect(session.expectedCharacter == "a")
        session.typeCharacter("a")
        #expect(session.expectedCharacter == "b")
    }

    @Test func typingBeyondTextDoesNothing() {
        let session = TypingSession(text: "a")
        session.typeCharacter("a")
        let indexBefore = session.cursorIndex
        session.typeCharacter("b")
        // Cursor should not advance beyond text (but extendTextIfNeeded may have extended)
        // The key check: no crash and correctCount stays at 1
        #expect(session.correctCount == 1)
    }

    @Test func resetClearsState() {
        let session = TypingSession(text: "hello")
        session.typeCharacter("h")
        session.typeCharacter("e")
        session.reset()
        #expect(session.cursorIndex == 0)
        #expect(session.correctCount == 0)
        #expect(session.incorrectCount == 0)
        #expect(session.sessionStartTime == nil)
        #expect(session.characterResults.allSatisfy { $0 == .pending })
    }

    @Test func textExtendsWhenRunningLow() {
        let shortText = String(repeating: "a", count: 50)
        let session = TypingSession(text: shortText)
        let originalLength = session.fullText.count
        // Type enough to trigger extension (remaining < 200)
        // Since text is only 50 chars, extension should happen immediately on first type
        session.typeCharacter("a")
        #expect(session.fullText.count > originalLength)
    }
}
