import SwiftUI

struct StatsBarView: View {
    let session: TypingSession
    var lesson: Lesson? = nil

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 40) {
                statItem(
                    icon: "text.word.spacing",
                    value: currentWPM.map { "\($0)" } ?? "--",
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

            // Gate criteria (lesson mode only)
            if let lesson = lesson {
                Text("Target: \(lesson.gateWPM) WPM, \(Int(lesson.gateAccuracy))% accuracy")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray.opacity(0.7))
            }
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

    private var currentWPM: Int? {
        guard let start = session.startTime, session.state == .active else { return nil }
        let elapsed = Date().timeIntervalSince(start)
        guard elapsed >= 3, session.correctChars >= 10 else { return nil }
        return Int(SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsed))
    }

    private var currentAccuracy: Int {
        Int(SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes))
    }
}
