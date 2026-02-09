import Testing
import Foundation
@testable import bkey

struct AppStateTests {
    @Test func startFreeRunSetsCorrectState() {
        let appState = AppState()
        appState.startFreeRun()
        #expect(appState.mode == .freeRun)
        #expect(appState.selectedTab == .freeRun)
        #expect(appState.session.state == .ready)
        #expect(appState.showSessionSummary == false)
    }

    @Test func startFreeRunGeneratesTargetText() {
        let appState = AppState()
        appState.startFreeRun()
        #expect(!appState.session.targetText.isEmpty)
        #expect(appState.session.characterStates.count == appState.session.targetText.count)
    }

    @Test func startLessonSetsLessonMode() {
        let appState = AppState()
        appState.startLesson(id: 1)
        #expect(appState.mode == .lesson(lessonId: 1))
        #expect(appState.selectedTab == .freeRun)
        #expect(appState.lessonFlow != nil)
        #expect(appState.lessonFlow?.lesson.id == 1)
    }

    @Test func startLessonWithInvalidIdDoesNothing() {
        let appState = AppState()
        appState.startFreeRun()
        let originalMode = appState.mode
        appState.startLesson(id: 999)
        #expect(appState.mode == originalMode)
    }

    @Test func startNextLessonAdvancesId() {
        let appState = AppState()
        appState.startLesson(id: 1)
        appState.startNextLesson()
        #expect(appState.mode == .lesson(lessonId: 2))
    }

    @Test func startNextLessonInFreeRunDoesNothing() {
        let appState = AppState()
        appState.startFreeRun()
        appState.startNextLesson()
        #expect(appState.mode == .freeRun)
    }

    @Test func startNextLessonAtLastLessonDoesNothing() {
        let appState = AppState()
        appState.startLesson(id: 45)
        appState.startNextLesson()
        // Should still be on lesson 45 since 46 doesn't exist
        #expect(appState.mode == .lesson(lessonId: 45))
    }

    @Test func handleCharacterUpdatesKeyState() {
        let appState = AppState()
        appState.startFreeRun()
        let expectedChar = appState.session.currentCharacter!
        let keyCode = KeyMapping.keyCode(for: expectedChar) ?? 0
        appState.handleCharacter(expectedChar, keyCode: keyCode)
        #expect(appState.lastPressedKeyCode == keyCode)
        #expect(appState.lastPressCorrect == true)
    }

    @Test func handleCharacterWithWrongKeyMarksIncorrect() {
        let appState = AppState()
        appState.startFreeRun()
        let expectedChar = appState.session.currentCharacter!
        let wrongChar: Character = expectedChar == "z" ? "a" : "z"
        appState.handleCharacter(wrongChar, keyCode: 6)
        #expect(appState.lastPressCorrect == false)
    }

    @Test func handleBackspaceDelegatesToSession() {
        let appState = AppState()
        appState.startFreeRun()
        let firstChar = appState.session.currentCharacter!
        let keyCode = KeyMapping.keyCode(for: firstChar) ?? 0
        appState.handleCharacter(firstChar, keyCode: keyCode)
        let indexAfterType = appState.session.currentIndex
        appState.handleBackspace()
        #expect(appState.session.currentIndex == indexAfterType - 1)
    }

    @Test func handleEscapeEndsActiveSession() {
        let appState = AppState()
        appState.startFreeRun()
        // Type one character to make session active
        let firstChar = appState.session.currentCharacter!
        appState.handleCharacter(firstChar, keyCode: KeyMapping.keyCode(for: firstChar) ?? 0)
        #expect(appState.session.state == .active)
        appState.handleEscape()
        #expect(appState.session.state == .complete)
        #expect(appState.showSessionSummary == true)
    }

    @Test func handleEscapeDoesNothingWhenNotActive() {
        let appState = AppState()
        appState.startFreeRun()
        // Session is in .ready state, not .active
        appState.handleEscape()
        #expect(appState.session.state == .ready)
        #expect(appState.showSessionSummary == false)
    }

    @Test func updateActiveKeyCodeSetsCorrectKey() {
        let appState = AppState()
        appState.startFreeRun()
        let expectedChar = appState.session.currentCharacter!
        let expectedKeyCode = KeyMapping.keyCode(for: expectedChar)
        #expect(appState.activeKeyCode == expectedKeyCode)
    }

    @Test func currentLessonReturnsCorrectLesson() {
        let appState = AppState()
        appState.startLesson(id: 3)
        #expect(appState.currentLesson?.id == 3)
        #expect(appState.currentLesson?.title == "S and L")
    }

    @Test func currentLessonReturnsNilInFreeRun() {
        let appState = AppState()
        appState.startFreeRun()
        #expect(appState.currentLesson == nil)
    }

    // MARK: - Error Mode Passing

    @Test func sessionInheritsErrorModeFromAppState() {
        let appState = AppState()
        appState.errorMode = .forceCorrect
        appState.startFreeRun()
        #expect(appState.session.errorMode == .forceCorrect)
    }

    @Test func lessonSessionInheritsErrorMode() {
        let appState = AppState()
        appState.errorMode = .stopOnWord
        // Use a review lesson (no intro exercise) so session is created immediately with words
        appState.startLesson(id: 7) // Home Row Review
        #expect(appState.session.errorMode == .stopOnWord)
    }

    // MARK: - Keystroke Count

    @Test func keystrokeCountIncrementsOnCharacter() {
        let appState = AppState()
        appState.startFreeRun()
        #expect(appState.keystrokeCount == 0)
        let char = appState.session.currentCharacter!
        let keyCode = KeyMapping.keyCode(for: char) ?? 0
        appState.handleCharacter(char, keyCode: keyCode)
        #expect(appState.keystrokeCount == 1)
        // Second keystroke
        if let next = appState.session.currentCharacter {
            appState.handleCharacter(next, keyCode: KeyMapping.keyCode(for: next) ?? 0)
            #expect(appState.keystrokeCount == 2)
        }
    }

    @Test func keystrokeCountIncrementsOnWrongKey() {
        let appState = AppState()
        appState.startFreeRun()
        appState.handleCharacter("~", keyCode: 999)
        #expect(appState.keystrokeCount == 1)
    }

    @Test func keystrokeCountNotIncrementedWhenSessionComplete() {
        let appState = AppState()
        appState.startFreeRun()
        // Complete the session
        while appState.session.state != .complete {
            if let char = appState.session.currentCharacter {
                appState.handleCharacter(char, keyCode: KeyMapping.keyCode(for: char) ?? 0)
            } else {
                break
            }
        }
        let countAfterComplete = appState.keystrokeCount
        appState.handleCharacter("x", keyCode: 7)
        #expect(appState.keystrokeCount == countAfterComplete) // unchanged
    }

    // MARK: - Settings Persistence

    @Test func saveAndLoadSettingsRoundTrip() {
        let settingsKeys = ["showKeyboard", "showFingerLabels", "fontSize", "soundOnKeystroke",
                            "soundOnError", "showLiveStats", "caretStyle", "errorMode", "themeMode"]
        let defaults = UserDefaults.standard

        // Clean before
        for key in settingsKeys { defaults.removeObject(forKey: key) }

        let appState = AppState()
        appState.showKeyboard = false
        appState.showFingerLabels = true
        appState.fontSize = 28
        appState.soundOnKeystroke = true
        appState.soundOnError = false
        appState.showLiveStats = false
        appState.caretStyle = .block
        appState.errorMode = .forceCorrect
        appState.saveSettings()

        // Create a new AppState which reads from UserDefaults in init
        let loaded = AppState()
        #expect(loaded.showKeyboard == false)
        #expect(loaded.showFingerLabels == true)
        #expect(loaded.fontSize == 28)
        #expect(loaded.soundOnKeystroke == true)
        #expect(loaded.soundOnError == false)
        #expect(loaded.showLiveStats == false)
        #expect(loaded.caretStyle == .block)
        #expect(loaded.errorMode == .forceCorrect)

        // Clean after
        for key in settingsKeys { defaults.removeObject(forKey: key) }
    }

    // MARK: - Proficiency Tracker

    @Test func proficiencyTrackerInitiallyEmpty() {
        let appState = AppState()
        #expect(appState.proficiencyTracker.proficiencies.isEmpty)
    }

    @Test func handleCharacterDoesNotIncrementWhenPaused() {
        let appState = AppState()
        appState.startFreeRun()
        // End the session first
        let char = appState.session.currentCharacter!
        appState.handleCharacter(char, keyCode: KeyMapping.keyCode(for: char) ?? 0)
        appState.handleEscape()
        let count = appState.keystrokeCount
        appState.handleCharacter("x", keyCode: 7) // session is complete
        #expect(appState.keystrokeCount == count)
    }

    // MARK: - Practice Mode

    @Test func defaultPracticeModeIsEndless() {
        let appState = AppState()
        #expect(appState.practiceMode == .endless)
    }

    @Test func startFreeRunWithWordCountMode() {
        let appState = AppState()
        appState.practiceMode = .wordCount(count: .ten)
        appState.startFreeRun()
        let wordCount = appState.session.targetText.split(separator: " ").count
        #expect(wordCount == 10)
    }

    @Test func startFreeRunWithCustomTextMode() {
        let appState = AppState()
        appState.practiceMode = .custom(text: "hello world foo")
        appState.startFreeRun()
        #expect(appState.session.targetText == "hello world foo")
    }

    @Test func startFreeRunWithTimedMode() {
        let appState = AppState()
        appState.practiceMode = .timed(duration: .sixty)
        appState.startFreeRun()
        #expect(!appState.session.targetText.isEmpty)
        #expect(appState.session.state == .ready)
    }

    @Test func startFreeRunWithEndlessMode() {
        let appState = AppState()
        appState.practiceMode = .endless
        appState.startFreeRun()
        #expect(!appState.session.targetText.isEmpty)
    }

    @Test func restartFreeRunPreservesMode() {
        let appState = AppState()
        appState.practiceMode = .wordCount(count: .twentyFive)
        appState.startFreeRun()
        let wordCount = appState.session.targetText.split(separator: " ").count
        #expect(wordCount == 25)
        appState.startFreeRun()
        let wordCount2 = appState.session.targetText.split(separator: " ").count
        #expect(wordCount2 == 25)
    }

    @Test func timedModeCountdownStartsNil() {
        let appState = AppState()
        appState.practiceMode = .timed(duration: .thirty)
        appState.startFreeRun()
        #expect(appState.countdownRemaining == nil)
    }

    // MARK: - Theme Mode

    @Test func defaultThemeModeIsDark() {
        UserDefaults.standard.removeObject(forKey: "themeMode")
        let appState = AppState()
        #expect(appState.themeMode == .dark)
    }

    @Test func themeModePersistedToUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "themeMode")
        let appState = AppState()
        appState.themeMode = .oledDark
        appState.saveSettings()
        let loaded = AppState()
        #expect(loaded.themeMode == .oledDark)
        UserDefaults.standard.removeObject(forKey: "themeMode")
    }

    // MARK: - Session Completion

    @Test func sessionCompletionShowsSummary() {
        let appState = AppState()
        appState.startFreeRun()
        // Type all chars to complete
        while appState.session.state != .complete {
            if let char = appState.session.currentCharacter {
                appState.handleCharacter(char, keyCode: KeyMapping.keyCode(for: char) ?? 0)
            } else {
                break
            }
        }
        #expect(appState.showSessionSummary == true)
    }

    @Test func escapeShowsSessionSummary() {
        let appState = AppState()
        appState.startFreeRun()
        let char = appState.session.currentCharacter!
        appState.handleCharacter(char, keyCode: KeyMapping.keyCode(for: char) ?? 0)
        appState.handleEscape()
        #expect(appState.showSessionSummary == true)
    }

    // MARK: - Active Key Code

    @Test func activeKeyCodeNilAfterSessionComplete() {
        let appState = AppState()
        appState.startFreeRun()
        while appState.session.state != .complete {
            if let char = appState.session.currentCharacter {
                appState.handleCharacter(char, keyCode: KeyMapping.keyCode(for: char) ?? 0)
            } else {
                break
            }
        }
        #expect(appState.activeKeyCode == nil)
    }

    @Test func activeKeyCodeUpdatesAfterTypingAndBackspace() {
        let appState = AppState()
        appState.startFreeRun()
        let firstChar = appState.session.currentCharacter!
        let firstKeyCode = appState.activeKeyCode
        appState.handleCharacter(firstChar, keyCode: KeyMapping.keyCode(for: firstChar) ?? 0)
        // After typing first char, active key targets second char
        let secondCharKeyCode = appState.activeKeyCode
        #expect(secondCharKeyCode != nil)
        // Type second char
        let secondChar = appState.session.currentCharacter!
        appState.handleCharacter(secondChar, keyCode: KeyMapping.keyCode(for: secondChar) ?? 0)
        // Backspace — goes back to second char position
        appState.handleBackspace()
        // Active key should now target the second char again
        #expect(appState.activeKeyCode == secondCharKeyCode)
        _ = firstKeyCode // suppress unused warning
    }
}
