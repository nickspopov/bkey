import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

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
                Picker("Theme", selection: $appState.themeMode) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        HStack {
                            Circle()
                                .fill(themePreviewColor(mode))
                                .frame(width: 12, height: 12)
                            Text(themeDisplayName(mode))
                        }
                        .tag(mode)
                    }
                }
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
        .onDisappear { appState.saveSettings() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func themeDisplayName(_ mode: ThemeMode) -> String {
        switch mode {
        case .system: "System"
        case .dark: "Dark"
        case .light: "Light"
        case .oledDark: "OLED Dark"
        }
    }

    private func themePreviewColor(_ mode: ThemeMode) -> Color {
        switch mode {
        case .system: Color.gray
        case .dark: Color(red: 13/255, green: 17/255, blue: 23/255)
        case .light: Color.white
        case .oledDark: Color.black
        }
    }
}
