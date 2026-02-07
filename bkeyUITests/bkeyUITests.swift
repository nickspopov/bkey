import XCTest

final class bkeyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchShowsMainUI() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify main window exists
        XCTAssertTrue(app.windows.firstMatch.exists)

        // Verify tab buttons are visible
        XCTAssertTrue(app.staticTexts["Free Run"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Lessons"].exists)
        XCTAssertTrue(app.staticTexts["Progress"].exists)

        // Verify settings gear icon exists
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear'")).firstMatch.exists)
    }

    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Click Lessons tab
        let lessonsTab = app.staticTexts["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 5))
        lessonsTab.click()

        // Verify lessons content appears (lesson title should be visible)
        XCTAssertTrue(app.staticTexts["F and J"].waitForExistence(timeout: 3))

        // Click Progress tab
        let progressTab = app.staticTexts["Progress"]
        progressTab.click()

        // Verify progress content appears
        XCTAssertTrue(app.staticTexts["Progress"].waitForExistence(timeout: 3))

        // Click Free Run tab to return
        let freeRunTab = app.staticTexts["Free Run"]
        freeRunTab.click()

        // Verify we're back on the typing view (stats should be visible)
        XCTAssertTrue(app.staticTexts["words/min"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testTypingUpdatesDisplay() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for app to be ready
        XCTAssertTrue(app.staticTexts["words/min"].waitForExistence(timeout: 5))

        // Type a few characters
        app.typeKey("a", modifierFlags: [])
        app.typeKey("b", modifierFlags: [])
        app.typeKey("c", modifierFlags: [])

        // Verify typos counter is visible (we likely made errors since the text is random)
        XCTAssertTrue(app.staticTexts["typos"].exists)
        XCTAssertTrue(app.staticTexts["accuracy"].exists)
    }

    @MainActor
    func testSettingsSheetOpensAndCloses() throws {
        let app = XCUIApplication()
        app.launch()

        // Click settings gear
        let gearButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear'")).firstMatch
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5))
        gearButton.click()

        // Verify settings sheet appears with known toggles
        XCTAssertTrue(app.staticTexts["Show Keyboard"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Show Finger Labels"].exists)
        XCTAssertTrue(app.staticTexts["Sound on Error"].exists)

        // Close by pressing Escape
        app.typeKey(.escape, modifierFlags: [])

        // Verify we're back to main view
        XCTAssertTrue(app.staticTexts["words/min"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testLessonSelection() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Lessons tab
        let lessonsTab = app.staticTexts["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 5))
        lessonsTab.click()

        // Wait for lesson list
        XCTAssertTrue(app.staticTexts["F and J"].waitForExistence(timeout: 3))

        // Click first lesson
        app.staticTexts["F and J"].click()

        // Should return to typing view (Free Run tab area shows typing content)
        XCTAssertTrue(app.staticTexts["words/min"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testEscapeEndsFreeRunSession() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for app to be ready
        XCTAssertTrue(app.staticTexts["words/min"].waitForExistence(timeout: 5))

        // Type a character to start the session
        app.typeKey("a", modifierFlags: [])

        // Small delay to ensure session is active
        Thread.sleep(forTimeInterval: 0.3)

        // Press Escape to end session
        app.typeKey(.escape, modifierFlags: [])

        // Verify session summary overlay appears
        XCTAssertTrue(app.staticTexts["Session Complete"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Try Again"].exists)
        XCTAssertTrue(app.buttons["Close"].exists)
    }

    @MainActor
    func testTryAgainRestartsSession() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for app ready
        XCTAssertTrue(app.staticTexts["words/min"].waitForExistence(timeout: 5))

        // Type to start, then escape to end
        app.typeKey("a", modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.3)
        app.typeKey(.escape, modifierFlags: [])

        // Wait for summary
        XCTAssertTrue(app.staticTexts["Session Complete"].waitForExistence(timeout: 3))

        // Click Try Again
        app.buttons["Try Again"].click()

        // Session summary should disappear, back to typing view
        XCTAssertFalse(app.staticTexts["Session Complete"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["words/min"].exists)
    }

    @MainActor
    func testCloseButtonDismissesSummary() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for app ready
        XCTAssertTrue(app.staticTexts["words/min"].waitForExistence(timeout: 5))

        // Type to start, then escape
        app.typeKey("a", modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.3)
        app.typeKey(.escape, modifierFlags: [])

        // Wait for summary
        XCTAssertTrue(app.staticTexts["Session Complete"].waitForExistence(timeout: 3))

        // Click Close
        app.buttons["Close"].click()

        // Summary should disappear
        XCTAssertFalse(app.staticTexts["Session Complete"].waitForExistence(timeout: 2))
    }
}
