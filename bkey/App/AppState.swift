import SwiftUI
import SwiftData
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
    var keystrokeCount: Int = 0

    // Proficiency tracking
    var proficiencyTracker = KeyProficiencyTracker()

    init() {
        let defaults = UserDefaults.standard
        if let v = defaults.object(forKey: "showKeyboard") as? Bool { showKeyboard = v }
        if let v = defaults.object(forKey: "showFingerLabels") as? Bool { showFingerLabels = v }
        if let v = defaults.object(forKey: "fontSize") as? Int { fontSize = v }
        if let v = defaults.object(forKey: "soundOnKeystroke") as? Bool { soundOnKeystroke = v }
        if let v = defaults.object(forKey: "soundOnError") as? Bool { soundOnError = v }
        if let v = defaults.object(forKey: "showLiveStats") as? Bool { showLiveStats = v }
        if let raw = defaults.string(forKey: "caretStyle"), let style = CaretStyle(rawValue: raw) {
            caretStyle = style
        }
        if let raw = defaults.string(forKey: "errorMode"), let mode = ErrorMode(rawValue: raw) {
            errorMode = mode
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(showKeyboard, forKey: "showKeyboard")
        defaults.set(showFingerLabels, forKey: "showFingerLabels")
        defaults.set(fontSize, forKey: "fontSize")
        defaults.set(soundOnKeystroke, forKey: "soundOnKeystroke")
        defaults.set(soundOnError, forKey: "soundOnError")
        defaults.set(showLiveStats, forKey: "showLiveStats")
        defaults.set(caretStyle.rawValue, forKey: "caretStyle")
        defaults.set(errorMode.rawValue, forKey: "errorMode")
    }

    // Current lesson (if in lesson mode)
    var currentLesson: Lesson? {
        if case .lesson(let id) = mode {
            return LessonCurriculum.lesson(byId: id)
        }
        return nil
    }

    func startFreeRun() {
        mode = .freeRun
        let words: [String]
        if !proficiencyTracker.proficiencies.isEmpty {
            let weakChars = proficiencyTracker.weakestCharacters(count: 5)
            let allWords = WordGenerator().generateBatch(count: 200)
            words = AdaptiveWordSelector.selectWords(
                count: 50,
                allWords: allWords,
                weakChars: weakChars,
                proficiencies: proficiencyTracker.proficiencies
            )
        } else {
            words = WordGenerator().generateBatch(count: 50)
        }
        session = TypingSession(wordGenerator: WordGenerator(words: words), errorMode: errorMode)
        session.start()
        showSessionSummary = false
        selectedTab = .freeRun
        updateActiveKeyCode()
    }

    func startLesson(id: Int) {
        guard let lesson = LessonCurriculum.lesson(byId: id) else { return }
        mode = .lesson(lessonId: id)
        let words = wordsForLesson(lesson)
        session = TypingSession(wordGenerator: WordGenerator(words: words), errorMode: errorMode)
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
        keystrokeCount += 1

        if !lastPressCorrect && soundOnError { AudioManager.playError() }
        if lastPressCorrect && soundOnKeystroke { AudioManager.playKeystroke() }

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

    func loadProficiencyData() {
        let context = PersistenceManager.shared.mainContext
        let descriptor = FetchDescriptor<KeyProficiencyRecord>()
        guard let records = try? context.fetch(descriptor) else { return }
        proficiencyTracker = KeyProficiencyTracker()
        for record in records {
            guard let char = record.character.first else { continue }
            var data = KeyProficiencyTracker.ProficiencyData()
            data.totalAttempts = record.totalAttempts
            data.correctAttempts = record.correctAttempts
            data.recentSpeeds = record.recentSpeeds
            data.confidence = record.confidence
            proficiencyTracker.proficiencies[char] = data
        }
    }

    private func updateProficiencyFromSession() {
        let keystrokes = session.characterKeystrokes
        for i in 0..<keystrokes.count {
            let ks = keystrokes[i]
            var transitionMs: Double? = nil
            if i > 0 {
                let delta = ks.time.timeIntervalSince(keystrokes[i - 1].time) * 1000
                if delta <= 5000 { transitionMs = delta }
            }
            proficiencyTracker.recordAttempt(character: ks.character, correct: ks.correct, transitionTimeMs: transitionMs)
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
        updateProficiencyFromSession()
    }

    private func wordsForLesson(_ lesson: Lesson) -> [String] {
        let allowed = lesson.allowedKeys
        let gen = WordGenerator()
        let allWords = gen.generateBatch(count: 200)
        let filtered = allWords.filter { word in
            word.allSatisfy { allowed.contains($0) }
        }

        let baseWords: [String]
        if filtered.count >= 10 {
            baseWords = filtered
        } else {
            // Fallback: generate character combinations
            let chars = Array(allowed).filter { $0 != " " }
            guard !chars.isEmpty else { return ["test"] }
            var words: [String] = []
            for _ in 0..<50 {
                let len = Int.random(in: 2...5)
                let word = String((0..<len).map { _ in chars.randomElement()! })
                words.append(word)
            }
            baseWords = words
        }

        // Use adaptive selection if proficiency data exists
        if !proficiencyTracker.proficiencies.isEmpty {
            let weakChars = proficiencyTracker.weakestCharacters(count: 5, from: allowed)
            return AdaptiveWordSelector.selectWords(
                count: 50,
                allWords: baseWords,
                weakChars: weakChars,
                proficiencies: proficiencyTracker.proficiencies
            )
        }

        return baseWords
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
