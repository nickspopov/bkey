import SwiftUI
import Observation

enum AppMode: Sendable, Equatable {
    case freeRun
    case lesson(lessonId: Int)
}

enum AppTab: String, CaseIterable {
    case freeRun = "Free Run"
    case lessons = "Lessons"
    case progress = "Progress"
}

@Observable
class AppState {
    var mode: AppMode = .freeRun
    var session: TypingSession = TypingSession()
    var showSettings: Bool = false
    var showSessionSummary: Bool = false
    var showLessonPicker: Bool = false
    var showProgress: Bool = false
    var selectedTab: AppTab = .freeRun

    // Settings
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

    // Current lesson (if in lesson mode)
    var currentLesson: Lesson? {
        if case .lesson(let id) = mode {
            return LessonCurriculum.lesson(byId: id)
        }
        return nil
    }

    func startFreeRun() {
        mode = .freeRun
        session = TypingSession()
        session.start()
        showSessionSummary = false
        selectedTab = .freeRun
        updateActiveKeyCode()
    }

    func startLesson(id: Int) {
        guard let lesson = LessonCurriculum.lesson(byId: id) else { return }
        mode = .lesson(lessonId: id)
        let words = wordsForLesson(lesson)
        session = TypingSession(wordGenerator: WordGenerator(words: words))
        session.start()
        showSessionSummary = false
        selectedTab = .freeRun
        updateActiveKeyCode()
    }

    func startNextLesson() {
        if case .lesson(let id) = mode {
            let nextId = id + 1
            if LessonCurriculum.lesson(byId: nextId) != nil {
                startLesson(id: nextId)
            }
        }
    }

    func handleCharacter(_ character: Character, keyCode: UInt16) {
        guard session.state == .ready || session.state == .active else { return }

        lastPressedKeyCode = keyCode
        let expectedChar = session.currentCharacter
        session.processCharacter(character)
        lastPressCorrect = (character == expectedChar)

        if session.state == .complete {
            handleSessionComplete()
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
            handleSessionComplete()
        }
    }

    func updateActiveKeyCode() {
        if let char = session.currentCharacter {
            activeKeyCode = KeyMapping.keyCode(for: char)
        } else {
            activeKeyCode = nil
        }
    }

    private func handleSessionComplete() {
        showSessionSummary = true
        // Save session to persistence
        let modeString: String
        switch mode {
        case .freeRun: modeString = "freeRun"
        case .lesson(let id): modeString = "lesson-\(id)"
        }
        PersistenceManager.saveSession(from: session, mode: modeString)
    }

    private func wordsForLesson(_ lesson: Lesson) -> [String] {
        let allowed = lesson.allowedKeys
        let gen = WordGenerator()
        let allWords = gen.generateBatch(count: 200)
        let filtered = allWords.filter { word in
            word.allSatisfy { allowed.contains($0) }
        }
        if filtered.count >= 10 {
            return filtered
        }
        // Fallback: generate character combinations
        let chars = Array(allowed).filter { $0 != " " }
        guard !chars.isEmpty else { return ["test"] }
        var words: [String] = []
        for _ in 0..<50 {
            let len = Int.random(in: 2...5)
            let word = String((0..<len).map { _ in chars.randomElement()! })
            words.append(word)
        }
        return words
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
