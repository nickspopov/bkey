import SwiftUI
import SwiftData

struct LessonResultView: View {
    let lesson: Lesson
    let session: TypingSession
    let onNext: () -> Void
    let onRetry: () -> Void
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Lesson \(lesson.id): \(lesson.title)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                // Star display
                let stars = lesson.starRating(wpm: finalWPM, accuracy: finalAccuracy)
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .font(.largeTitle)
                            .foregroundStyle(i <= stars ? .yellow : .gray.opacity(0.3))
                    }
                }

                // Gate info
                if stars == 0 {
                    Text("Target: \(lesson.gateWPM) WPM, \(Int(lesson.gateAccuracy))% accuracy")
                        .foregroundStyle(.orange)
                } else {
                    Text("Lesson Complete!")
                        .foregroundStyle(.green)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    summaryItem(label: "WPM", value: "\(Int(finalWPM))")
                    summaryItem(label: "Accuracy", value: "\(Int(finalAccuracy))%")
                    summaryItem(label: "Typos", value: "\(session.errors)")
                    summaryItem(label: "Time", value: formattedTime)
                }

                HStack(spacing: 16) {
                    if stars > 0 {
                        Button("Next Lesson") { onNext() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    }
                    Button("Retry") { onRetry() }
                        .buttonStyle(.bordered)
                    Button("Close") { onClose() }
                        .buttonStyle(.bordered)
                }
            }
            .padding(32)
            .frame(width: 420)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 22/255, green: 27/255, blue: 34/255))
                    .shadow(radius: 20)
            )
            .onAppear { saveLessonResult(stars: lesson.starRating(wpm: finalWPM, accuracy: finalAccuracy)) }
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
    }

    private var elapsedSeconds: TimeInterval {
        guard let start = session.startTime else { return 0 }
        let end = session.endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    private var finalWPM: Double {
        SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsedSeconds)
    }

    private var finalAccuracy: Double {
        SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes)
    }

    private var formattedTime: String {
        SessionMetrics.formattedTime(elapsedSeconds)
    }

    private func saveLessonResult(stars: Int) {
        let lessonId = lesson.id
        let descriptor = FetchDescriptor<LessonRecord>(
            predicate: #Predicate { $0.lessonId == lessonId }
        )
        let existing = try? modelContext.fetch(descriptor)
        let record = existing?.first ?? LessonRecord(lessonId: lesson.id)
        if existing?.first == nil { modelContext.insert(record) }

        record.attempts += 1
        if finalWPM > record.bestWPM { record.bestWPM = finalWPM }
        if finalAccuracy > record.bestAccuracy { record.bestAccuracy = finalAccuracy }
        if stars > record.stars {
            record.stars = stars
            record.completedAt = Date()
        }
        try? modelContext.save()
    }
}
