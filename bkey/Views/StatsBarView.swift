import SwiftUI

struct StatsBarView: View {
    let session: TypingSession

    var body: some View {
        HStack(spacing: 40) {
            statItem(
                icon: "text.word.spacing",
                value: "\(currentWPM)",
                label: "words/min"
            )
            statItem(
                icon: "scope",
                value: "\(currentAccuracy)",
                label: "accuracy",
                suffix: "%"
            )
            statItem(
                icon: "exclamationmark.circle",
                value: "\(session.errors)",
                label: "typos"
            )
        }
        .padding(.vertical, 20)
    }

    private func statItem(icon: String, value: String, label: String, suffix: String = "") -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.gray)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if !suffix.isEmpty {
                        Text(suffix)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }

    private var currentWPM: Int {
        guard let start = session.startTime, session.state == .active else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        return Int(SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsed))
    }

    private var currentAccuracy: Int {
        Int(SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes))
    }
}
