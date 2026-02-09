import Foundation
import Observation

enum CharacterState: Sendable {
    case pending
    case correct
    case incorrect
    case corrected
}

@Observable
class TypingSession {
    enum State: Sendable {
        case ready, active, paused, complete
    }

    var state: State = .ready
    var targetText: String = ""
    var characterStates: [CharacterState] = []
    var currentIndex: Int = 0
    var keystrokes: Int = 0
    var errors: Int = 0
    var correctChars: Int = 0
    var startTime: Date?
    var endTime: Date?
    var words: [String] = []
    var wordBoundaries: [Int] = [] // indices where each word starts

    // Rolling window for best WPM
    private(set) var timestampedKeystrokes: [(time: Date, correct: Bool)] = []

    // Per-key proficiency tracking
    private(set) var characterKeystrokes: [(character: Character, correct: Bool, time: Date)] = []

    private let wordGenerator: WordGenerator
    let errorMode: ErrorMode
    private let customText: String?

    init(wordGenerator: WordGenerator = WordGenerator(), errorMode: ErrorMode = .continueOnError) {
        self.wordGenerator = wordGenerator
        self.errorMode = errorMode
        self.customText = nil
    }

    init(customText: String, errorMode: ErrorMode = .continueOnError) {
        self.wordGenerator = WordGenerator(words: [])
        self.errorMode = errorMode
        self.customText = customText
    }

    func start() {
        if let custom = customText {
            words = custom.split(separator: " ").map(String.init)
            targetText = custom
        } else {
            let batch = wordGenerator.generateBatch(count: 50)
            words = batch
            targetText = batch.joined(separator: " ")
        }
        characterStates = Array(repeating: .pending, count: targetText.count)
        currentIndex = 0
        keystrokes = 0
        errors = 0
        correctChars = 0
        startTime = nil
        endTime = nil
        state = .ready
        timestampedKeystrokes = []
        characterKeystrokes = []
        computeWordBoundaries()
    }

    func restart() {
        start()
    }

    private func computeWordBoundaries() {
        wordBoundaries = [0]
        var pos = 0
        for word in words {
            pos += word.count + 1 // +1 for space
            wordBoundaries.append(pos)
        }
    }

    func processCharacter(_ character: Character) {
        guard state == .ready || state == .active else { return }

        if state == .ready {
            state = .active
            startTime = Date()
        }

        guard currentIndex < targetText.count else { return }

        keystrokes += 1
        let expected = targetText[targetText.index(targetText.startIndex, offsetBy: currentIndex)]

        let now = Date()

        if character == expected {
            characterStates[currentIndex] = .correct
            correctChars += 1
            timestampedKeystrokes.append((time: now, correct: true))
            characterKeystrokes.append((character: expected, correct: true, time: now))
            currentIndex += 1
        } else {
            characterStates[currentIndex] = .incorrect
            errors += 1
            timestampedKeystrokes.append((time: now, correct: false))
            characterKeystrokes.append((character: expected, correct: false, time: now))
            switch errorMode {
            case .continueOnError:
                currentIndex += 1
            case .forceCorrect, .stopOnWord:
                break // stay put, user must retype
            }
        }

        // Check if session is complete
        if currentIndex >= targetText.count {
            endSession()
        }
    }

    func processBackspace() {
        guard state == .active else { return }
        guard currentIndex > 0 else { return }

        // Find the start of the current word
        let wordStart = wordBoundaries.last(where: { $0 <= currentIndex }) ?? 0

        // Don't backspace past word boundary (can't go to previous word)
        let prevIndex = currentIndex - 1
        guard prevIndex >= wordStart else { return }

        currentIndex = prevIndex
        // If it was incorrect, mark as corrected when retyped correctly later
        characterStates[currentIndex] = .pending
    }

    func endSession() {
        guard state == .active else { return }
        state = .complete
        endTime = Date()
    }

    func forceComplete() {
        guard state == .active else { return }
        state = .complete
        endTime = Date()
    }

    // Current expected character
    var currentCharacter: Character? {
        guard currentIndex < targetText.count else { return nil }
        return targetText[targetText.index(targetText.startIndex, offsetBy: currentIndex)]
    }

    // Current word index (which word the user is on)
    var currentWordIndex: Int {
        for i in (0..<wordBoundaries.count).reversed() {
            if currentIndex >= wordBoundaries[i] {
                return i
            }
        }
        return 0
    }
}
