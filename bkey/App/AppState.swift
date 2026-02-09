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

    // Multi-exercise lesson flow
    var lessonFlow: LessonFlowState? = nil
    var showExerciseTransition: Bool = false

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

    // Practice mode
    var practiceMode: PracticeMode = .endless
    var countdownRemaining: Int? = nil
    private var countdownTimer: Timer? = nil

    // Theme
    var themeMode: ThemeMode = .dark

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
        if let raw = defaults.string(forKey: "themeMode"), let mode = ThemeMode(rawValue: raw) {
            themeMode = mode
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
        defaults.set(themeMode.rawValue, forKey: "themeMode")
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
        lessonFlow = nil
        showExerciseTransition = false
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownRemaining = nil

        switch practiceMode {
        case .endless:
            let words = generateAdaptiveWords(count: 50)
            session = TypingSession(wordGenerator: WordGenerator(words: words), errorMode: errorMode)
        case .timed:
            // Timed: generate lots of words, timer will end the session
            let words = generateAdaptiveWords(count: 200)
            session = TypingSession(wordGenerator: WordGenerator(words: words), errorMode: errorMode)
        case .wordCount(let option):
            let words = generateAdaptiveWords(count: option.rawValue)
            session = TypingSession(wordGenerator: WordGenerator(words: words), errorMode: errorMode, targetWordCount: option.rawValue)
        case .custom(let text):
            let normalized = PracticeMode.normalizeCustomText(text)
            guard !normalized.isEmpty else {
                session = TypingSession()
                return
            }
            session = TypingSession(customText: normalized, errorMode: errorMode)
        }

        session.start()
        showSessionSummary = false
        selectedTab = .freeRun
        updateActiveKeyCode()
    }

    private func generateAdaptiveWords(count: Int) -> [String] {
        if !proficiencyTracker.proficiencies.isEmpty {
            let weakChars = proficiencyTracker.weakestCharacters(count: 5)
            let allWords = WordGenerator().generateBatch(count: max(count * 4, 200))
            return AdaptiveWordSelector.selectWords(
                count: count,
                allWords: allWords,
                weakChars: weakChars,
                proficiencies: proficiencyTracker.proficiencies
            )
        } else {
            return WordGenerator().generateBatch(count: count)
        }
    }

    func startLesson(id: Int) {
        guard let lesson = LessonCurriculum.lesson(byId: id) else { return }
        mode = .lesson(lessonId: id)
        lessonFlow = LessonFlowState(lesson: lesson)
        showSessionSummary = false
        showExerciseTransition = false
        selectedTab = .freeRun
        startCurrentExercise()
    }

    func startCurrentExercise() {
        guard let flow = lessonFlow, let exercise = flow.currentExercise else { return }

        if exercise.type == .introduction {
            // Placeholder session for intro (not typing)
            session = TypingSession()
            activeKeyCode = nil
        } else {
            // Typing exercise: use exercise's target words
            let words = exercise.targetWords
            session = TypingSession(wordGenerator: WordGenerator(words: words), errorMode: errorMode)
            session.start()
            updateActiveKeyCode()
        }
    }

    func advanceExercise() {
        guard let flow = lessonFlow else { return }
        showExerciseTransition = false
        if flow.advanceToNextExercise() {
            startCurrentExercise()
        } else {
            // Lesson complete — show final result
            showSessionSummary = true
        }
    }

    func completeIntroduction() {
        guard let flow = lessonFlow,
              let exercise = flow.currentExercise,
              exercise.type == .introduction else { return }
        showExerciseTransition = true
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
        // Intercept space during introduction exercises
        if let flow = lessonFlow,
           let exercise = flow.currentExercise,
           exercise.type == .introduction {
            if character == " " {
                completeIntroduction()
            }
            return
        }

        guard session.state == .ready || session.state == .active else { return }

        // Start timed countdown on first keystroke
        if case .timed(let duration) = practiceMode,
           session.state == .ready || (session.state == .active && countdownRemaining == nil) {
            startCountdown(seconds: duration.rawValue)
        }

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
            countdownTimer?.invalidate()
            countdownTimer = nil
            countdownRemaining = nil
            session.endSession()
            handleSessionComplete()
        }
    }

    private func startCountdown(seconds: Int) {
        countdownRemaining = seconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if let remaining = self.countdownRemaining, remaining > 0 {
                self.countdownRemaining = remaining - 1
            }
            if self.countdownRemaining == 0 {
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                self.session.forceComplete()
                self.handleSessionComplete()
                self.updateActiveKeyCode()
            }
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
        // Save session to persistence
        let modeString: String
        switch mode {
        case .freeRun: modeString = "freeRun"
        case .lesson(let id): modeString = "lesson-\(id)"
        }
        PersistenceManager.saveSession(from: session, mode: modeString)
        updateProficiencyFromSession()

        // Handle lesson flow
        if let flow = lessonFlow {
            flow.recordResult(from: session)
            if flow.isOnLastExercise {
                // Lesson complete — show final result
                showSessionSummary = true
            } else {
                // Show transition to next exercise
                showExerciseTransition = true
            }
        } else {
            // Free run — show summary
            showSessionSummary = true
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
