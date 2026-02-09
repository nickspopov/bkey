import SwiftUI

struct SessionSummaryView: View {
    let session: TypingSession
    let practiceMode: PracticeMode
    let onRestart: () -> Void
    let onClose: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            theme.scrimColor
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Session Complete")
                        .font(.title2.bold())
                        .foregroundStyle(theme.textPrimary)
                    Text(practiceMode.displayName)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    summaryItem(label: "WPM", value: "\(finalWPM)")
                    summaryItem(label: "Net WPM", value: "\(finalNetWPM)")
                    summaryItem(label: "Best WPM", value: "\(finalBestWPM)")
                    summaryItem(label: "Accuracy", value: "\(finalAccuracy)%")
                    summaryItem(label: "Typos", value: "\(session.errors)")
                    summaryItem(label: "Characters", value: "\(session.keystrokes)")
                    summaryItem(label: "Time", value: formattedTime)
                }

                HStack(spacing: 16) {
                    Button("Restart") {
                        onRestart()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)

                    Button("Close") {
                        onClose()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(32)
            .frame(width: 400)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceBackground)
                    .shadow(radius: 20)
            )
        }
    }

    private func summaryItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var elapsedSeconds: TimeInterval {
        guard let start = session.startTime else { return 0 }
        let end = session.endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    private var finalWPM: Int {
        Int(SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsedSeconds))
    }

    private var finalNetWPM: Int {
        Int(SessionMetrics.netWPM(correctChars: session.correctChars, errors: session.errors, elapsedSeconds: elapsedSeconds))
    }

    private var finalBestWPM: Int {
        Int(SessionMetrics.bestWPM(keystrokes: session.timestampedKeystrokes))
    }

    private var finalAccuracy: Int {
        Int(SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes))
    }

    private var formattedTime: String {
        SessionMetrics.formattedTime(elapsedSeconds)
    }
}
