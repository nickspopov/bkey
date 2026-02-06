import SwiftUI

struct SessionSummaryView: View {
    let session: TypingSession
    let onTryAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Session Complete")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    summaryItem(label: "WPM", value: "\(finalWPM)")
                    summaryItem(label: "Net WPM", value: "\(finalNetWPM)")
                    summaryItem(label: "Accuracy", value: "\(finalAccuracy)%")
                    summaryItem(label: "Typos", value: "\(session.errors)")
                    summaryItem(label: "Characters", value: "\(session.keystrokes)")
                    summaryItem(label: "Time", value: formattedTime)
                }

                HStack(spacing: 16) {
                    Button("Try Again") {
                        onTryAgain()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 99/255, green: 179/255, blue: 237/255))

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
                    .fill(Color(red: 22/255, green: 27/255, blue: 34/255))
                    .shadow(radius: 20)
            )
        }
    }

    private func summaryItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
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

    private var finalAccuracy: Int {
        Int(SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes))
    }

    private var formattedTime: String {
        SessionMetrics.formattedTime(elapsedSeconds)
    }
}
