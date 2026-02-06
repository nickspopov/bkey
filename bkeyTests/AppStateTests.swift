import Testing
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
        #expect(!appState.session.targetText.isEmpty)
        #expect(appState.session.state == .ready)
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
}
