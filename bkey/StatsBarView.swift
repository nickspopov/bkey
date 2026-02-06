import SwiftUI

struct StatsBarView: View {
    let session: TypingSession

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            HStack(spacing: 40) {
                statGroup(
                    icon: "text.badge.checkmark",
                    value: String(format: "%.0f", session.wpm),
                    label: "words/min"
                )
                statGroup(
                    icon: "medal",
                    value: String(format: "%.1f%%", session.accuracy),
                    label: "accuracy"
                )
                statGroup(
                    icon: "exclamationmark.circle",
                    value: "\(session.incorrectCount)",
                    label: "typos"
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    private func statGroup(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.statsLabel)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Theme.statsValueFont)
                    .foregroundStyle(Theme.statsValue)
                Text(label)
                    .font(Theme.statsLabelFont)
                    .foregroundStyle(Theme.statsLabel)
            }
        }
    }
}
