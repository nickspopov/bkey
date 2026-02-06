import SwiftUI
import Observation

enum AppMode: Sendable {
    case freeRun
    case lesson(lessonId: Int)
}

@Observable
class AppState {
    var mode: AppMode = .freeRun
    var session: TypingSession = TypingSession()
    var showSettings: Bool = false
    var showSessionSummary: Bool = false

    // Settings (stored via @AppStorage in views, mirrored here for model access)
    var showKeyboard: Bool = true
    var showFingerLabels: Bool = false
    var fontSize: Int = 22
    var soundOnKeystroke: Bool = false
    var soundOnError: Bool = true
    var errorMode: ErrorMode = .continueOnError

    // Phase 2 settings
    var caretStyle: CaretStyle = .line
    var showLiveStats: Bool = true

    // Target key highlighting
    var activeKeyCode: UInt16? = nil
    var lastPressedKeyCode: UInt16? = nil
    var lastPressCorrect: Bool = true

    func startFreeRun() {
        mode = .freeRun
        session = TypingSession()
        session.start()
        showSessionSummary = false
        updateActiveKeyCode()
    }

    func handleCharacter(_ character: Character, keyCode: UInt16) {
        guard session.state == .ready || session.state == .active else { return }

        lastPressedKeyCode = keyCode
        let expectedChar = session.currentCharacter
        session.processCharacter(character)
        lastPressCorrect = (character == expectedChar)

        if session.state == .complete {
            showSessionSummary = true
        }

        updateActiveKeyCode()
    }

    func handleBackspace() {
        session.processBackspace()
        updateActiveKeyCode()
    }

    func handleEscape() {
        if session.state == .active {
            session.endSession()
            showSessionSummary = true
        }
    }

    func updateActiveKeyCode() {
        if let char = session.currentCharacter {
            activeKeyCode = KeyMapping.keyCode(for: char)
        } else {
            activeKeyCode = nil
        }
    }
}

enum ErrorMode: String, CaseIterable, Sendable {
    case continueOnError = "Continue"
    case forceCorrect = "Force Correct"
    case stopOnWord = "Stop on Word"
}

enum CaretStyle: String, CaseIterable, Sendable {
    case line = "Line"
    case block = "Block"
    case underline = "Underline"
}
