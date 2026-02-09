import SwiftUI

struct ModePickerView: View {
    @Bindable var appState: AppState
    @State private var customTextInput: String = ""
    @State private var showTruncationWarning: Bool = false
    @Environment(\.appTheme) private var theme

    private enum ModeTab: String, CaseIterable {
        case endless = "Endless"
        case timed = "Timed"
        case words = "Words"
        case custom = "Custom"
    }

    @State private var selectedTab: ModeTab = .endless

    var body: some View {
        VStack(spacing: 12) {
            // Mode selector pills
            HStack(spacing: 8) {
                ForEach(ModeTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                        updatePracticeMode()
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? theme.textPrimary : theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedTab == tab
                                    ? theme.accent.opacity(0.2)
                                    : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .accessibilityIdentifier("modePicker")

            // Mode-specific config
            switch selectedTab {
            case .endless:
                EmptyView()
            case .timed:
                timedConfig
            case .words:
                wordCountConfig
            case .custom:
                customTextConfig
            }
        }
        .padding(.horizontal, 20)
        .onAppear { syncTabFromMode() }
    }

    private var timedConfig: some View {
        HStack(spacing: 8) {
            ForEach(TimedDuration.allCases, id: \.self) { duration in
                let isSelected = isTimedDuration(duration)
                Button {
                    appState.practiceMode = .timed(duration: duration)
                } label: {
                    Text(duration.displayLabel)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(isSelected ? theme.accent.opacity(0.15) : theme.statsBackground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var wordCountConfig: some View {
        HStack(spacing: 8) {
            ForEach(WordCountOption.allCases, id: \.self) { option in
                let isSelected = isWordCount(option)
                Button {
                    appState.practiceMode = .wordCount(count: option)
                } label: {
                    Text(option.displayLabel)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(isSelected ? theme.accent.opacity(0.15) : theme.statsBackground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customTextConfig: some View {
        VStack(spacing: 8) {
            TextEditor(text: $customTextInput)
                .font(.system(size: 13, design: .monospaced))
                .frame(height: 80)
                .scrollContentBackground(.hidden)
                .background(theme.statsBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.textSecondary.opacity(0.3), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if customTextInput.isEmpty {
                        Text("Paste your text here...")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(theme.textSecondary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                if showTruncationWarning {
                    Text("Text truncated to 10,000 characters")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button("Start") {
                    let normalized = PracticeMode.normalizeCustomText(customTextInput)
                    showTruncationWarning = customTextInput.count > 10000
                    appState.practiceMode = .custom(text: normalized)
                    appState.startFreeRun()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .disabled(customTextInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .frame(maxWidth: 500)
    }

    private func updatePracticeMode() {
        switch selectedTab {
        case .endless:
            appState.practiceMode = .endless
        case .timed:
            if case .timed = appState.practiceMode { return }
            appState.practiceMode = .timed(duration: .sixty)
        case .words:
            if case .wordCount = appState.practiceMode { return }
            appState.practiceMode = .wordCount(count: .twentyFive)
        case .custom:
            // Don't auto-set custom mode until user clicks Start
            break
        }
    }

    private func syncTabFromMode() {
        switch appState.practiceMode {
        case .endless: selectedTab = .endless
        case .timed: selectedTab = .timed
        case .wordCount: selectedTab = .words
        case .custom: selectedTab = .custom
        }
    }

    private func isTimedDuration(_ duration: TimedDuration) -> Bool {
        if case .timed(let d) = appState.practiceMode { return d == duration }
        return false
    }

    private func isWordCount(_ option: WordCountOption) -> Bool {
        if case .wordCount(let c) = appState.practiceMode { return c == option }
        return false
    }
}
