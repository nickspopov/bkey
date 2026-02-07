import AppKit

struct KeyEventHandler {
    static func setupMonitor(appState: AppState) -> Any? {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Ignore auto-repeat
            guard !event.isARepeat else { return nil }

            // Ignore modifier-only or command/control combos
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.command) || flags.contains(.control) {
                return event // pass through system shortcuts
            }

            let keyCode = event.keyCode

            // Backspace
            if keyCode == 51 {
                appState.handleBackspace()
                return nil
            }

            // Escape — pass through when a sheet is open so it can dismiss
            if keyCode == 53 {
                if appState.showSettings || appState.showSessionSummary {
                    return event
                }
                appState.handleEscape()
                return nil
            }

            // Enter — complete introduction exercise if on one
            if keyCode == 36 {
                if let flow = appState.lessonFlow,
                   let exercise = flow.currentExercise,
                   exercise.type == .introduction {
                    appState.completeIntroduction()
                }
                return nil
            }

            // Tab — ignore
            if keyCode == 48 {
                return nil
            }

            // Get the typed character
            guard let characters = event.characters, let char = characters.first else {
                return nil
            }

            appState.handleCharacter(char, keyCode: keyCode)
            return nil // suppress system beep
        }
    }

    static func removeMonitor(_ monitor: Any?) {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
