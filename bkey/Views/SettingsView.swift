import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Show Keyboard", isOn: $appState.showKeyboard)
                Toggle("Show Finger Labels", isOn: $appState.showFingerLabels)
                Stepper("Font Size: \(appState.fontSize)", value: $appState.fontSize, in: 16...32, step: 2)
                Picker("Caret Style", selection: $appState.caretStyle) {
                    ForEach(CaretStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                Toggle("Show Live Stats", isOn: $appState.showLiveStats)
            }

            Section("Sound") {
                Toggle("Sound on Keystroke", isOn: $appState.soundOnKeystroke)
                Toggle("Sound on Error", isOn: $appState.soundOnError)
            }

            Section("Typing") {
                Picker("Error Mode", selection: $appState.errorMode) {
                    ForEach(ErrorMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 400)
    }
}
