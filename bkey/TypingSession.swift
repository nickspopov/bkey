import Foundation
import Observation

enum CharacterResult {
    case pending
    case correct
    case incorrect
}

@Observable
final class TypingSession {
    private(set) var fullText: String
    private(set) var cursorIndex: Int = 0
    private(set) var characterResults: [CharacterResult] = []
    private(set) var correctCount: Int = 0
    private(set) var incorrectCount: Int = 0
    private(set) var sessionStartTime: Date?

    var wpm: Double {
        guard let start = sessionStartTime else { return 0 }
        let elapsedMinutes = Date().timeIntervalSince(start) / 60.0
        guard elapsedMinutes > 0 else { return 0 }
        return (Double(cursorIndex) / 5.0) / elapsedMinutes
    }

    var accuracy: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 100.0 }
        return (Double(correctCount) / Double(total)) * 100.0
    }

    var expectedCharacter: Character? {
        guard cursorIndex < fullText.count else { return nil }
        let idx = fullText.index(fullText.startIndex, offsetBy: cursorIndex)
        return fullText[idx]
    }

    var isComplete: Bool {
        cursorIndex >= fullText.count
    }

    init(text: String? = nil) {
        let t = text ?? SentenceBank.generateText()
        self.fullText = t
        self.characterResults = Array(repeating: .pending, count: t.count)
    }

    func typeCharacter(_ char: Character) {
        guard cursorIndex < fullText.count else { return }

        if sessionStartTime == nil {
            sessionStartTime = Date()
        }

        let idx = fullText.index(fullText.startIndex, offsetBy: cursorIndex)
        if char == fullText[idx] {
            characterResults[cursorIndex] = .correct
            correctCount += 1
        } else {
            characterResults[cursorIndex] = .incorrect
            incorrectCount += 1
        }

        cursorIndex += 1
        extendTextIfNeeded()
    }

    func extendTextIfNeeded() {
        let remaining = fullText.count - cursorIndex
        if remaining < 200 {
            let moreText = " " + SentenceBank.generateText()
            fullText += moreText
            characterResults += Array(repeating: .pending, count: moreText.count)
        }
    }

    func reset() {
        let newText = SentenceBank.generateText()
        fullText = newText
        cursorIndex = 0
        characterResults = Array(repeating: .pending, count: newText.count)
        correctCount = 0
        incorrectCount = 0
        sessionStartTime = nil
    }
}
