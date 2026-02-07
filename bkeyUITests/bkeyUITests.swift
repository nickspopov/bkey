import XCTest

final class bkeyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Reads the target text from the TextDisplayView accessibility value.
    /// Returns the full target string the user is expected to type.
    private func readTargetText(app: XCUIApplication, timeout: TimeInterval = 5) -> String {
        let textDisplay = app.scrollViews["typingTextDisplay"]
        XCTAssertTrue(textDisplay.waitForExistence(timeout: timeout), "TextDisplayView not found")
        let value = textDisplay.value as? String ?? ""
        XCTAssertFalse(value.isEmpty, "Target text is empty")
        return value
    }

    /// Types each character of the given text into the app, one at a time.
    /// Handles uppercase by using shift modifier.
    private func typeText(_ text: String, into app: XCUIApplication) {
        for char in text {
            let str = String(char)
            if char.isUppercase {
                app.typeKey(str.lowercased(), modifierFlags: .shift)
            } else if char == " " {
                app.typeKey(" ", modifierFlags: [])
            } else {
                app.typeKey(str, modifierFlags: [])
            }
        }
    }

    /// Types the first `count` characters of the target text.
    private func typePartialText(count: Int, app: XCUIApplication) {
        let target = readTargetText(app: app)
        let partial = String(target.prefix(count))
        typeText(partial, into: app)
    }

    /// Navigates to a tab by clicking its label text.
    private func navigateToTab(_ tabName: String, app: XCUIApplication) {
        let tab = app.staticTexts[tabName]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab '\(tabName)' not found")
        tab.click()
    }

    // MARK: - Test 1: Free Run Complete → Summary → Try Again

    @MainActor
    func testFreeRunCompleteSessionAndTryAgain() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for app to be ready
        XCTAssertTrue(app.staticTexts["words/min"].waitForExistence(timeout: 5))

        // Read target text and type it all
        let targetText = readTargetText(app: app)
        typeText(targetText, into: app)

        // Session summary should appear
        XCTAssertTrue(app.staticTexts["Session Complete"].waitForExistence(timeout: 5))

        // Verify summary stats labels exist
        XCTAssertTrue(app.staticTexts["WPM"].exists)
        XCTAssertTrue(app.staticTexts["Accuracy"].exists)
        XCTAssertTrue(app.staticTexts["Typos"].exists)
        XCTAssertTrue(app.staticTexts["Time"].exists)

        // Click Try Again
        XCTAssertTrue(app.buttons["Try Again"].exists)
        app.buttons["Try Again"].click()

        // Summary should disappear
        XCTAssertFalse(app.staticTexts["Session Complete"].waitForExistence(timeout: 2))

        // New session should have target text (possibly different)
        let newTargetText = readTargetText(app: app)
        XCTAssertFalse(newTargetText.isEmpty)
    }
}
