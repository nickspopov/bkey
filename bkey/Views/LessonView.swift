import SwiftUI
import SwiftData

struct LessonResultView: View {
    let lesson: Lesson
    let lessonFlow: LessonFlowState
    let session: TypingSession
    let onNext: () -> Void
    let onRetry: () -> Void
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Lesson \(lesson.id): \(lesson.title)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    // Star display (based on speed challenge result)
                    let stars = starRating
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

                    // Speed challenge stats (primary metrics)
                    if let challengeResult = lessonFlow.speedChallengeResult {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            summaryItem(label: "WPM", value: "\(Int(challengeResult.wpm))")
                            summaryItem(label: "Accuracy", value: "\(Int(challengeResult.accuracy))%")
                            summaryItem(label: "Typos", value: "\(challengeResult.errors)")
                            summaryItem(label: "Time", value: SessionMetrics.formattedTime(challengeResult.duration))
                        }
                    }

                    // Per-exercise breakdown
                    if lessonFlow.exerciseResults.count > 1 {
                        Divider().background(Color.white.opacity(0.2))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exercise Breakdown")
                                .font(.caption.bold())
                                .foregroundStyle(.gray)

                            ForEach(lessonFlow.exerciseResults, id: \.exerciseId) { result in
                                HStack {
                                    Text(result.exerciseType.title)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                    Spacer()
                                    if result.exerciseType.isTypingExercise {
                                        Text("\(Int(result.wpm)) WPM")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                        Text("\(Int(result.accuracy))%")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                            }
                        }
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
            }
            .frame(width: 420)
            .frame(maxHeight: 500)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 22/255, green: 27/255, blue: 34/255))
                    .shadow(radius: 20)
            )
            .onAppear { saveLessonResult(stars: starRating) }
        }
        .accessibilityIdentifier("lessonResult")
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

    /// Star rating derived from speed challenge result only
    private var starRating: Int {
        guard let result = lessonFlow.speedChallengeResult else {
            // Fallback to session data if no speed challenge result
            return lesson.starRating(wpm: fallbackWPM, accuracy: fallbackAccuracy)
        }
        return lesson.starRating(wpm: result.wpm, accuracy: result.accuracy)
    }

    private var fallbackWPM: Double {
        guard let start = session.startTime else { return 0 }
        let end = session.endTime ?? Date()
        return SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: end.timeIntervalSince(start))
    }

    private var fallbackAccuracy: Double {
        SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes)
    }

    private func saveLessonResult(stars: Int) {
        let wpm: Double
        let accuracy: Double
        if let result = lessonFlow.speedChallengeResult {
            wpm = result.wpm
            accuracy = result.accuracy
        } else {
            wpm = fallbackWPM
            accuracy = fallbackAccuracy
        }

        let lessonId = lesson.id
        let descriptor = FetchDescriptor<LessonRecord>(
            predicate: #Predicate { $0.lessonId == lessonId }
        )
        let existing = try? modelContext.fetch(descriptor)
        let record = existing?.first ?? LessonRecord(lessonId: lesson.id)
        if existing?.first == nil { modelContext.insert(record) }

        record.attempts += 1
        if wpm > record.bestWPM { record.bestWPM = wpm }
        if accuracy > record.bestAccuracy { record.bestAccuracy = accuracy }
        if stars > record.stars {
            record.stars = stars
            record.completedAt = Date()
        }
        try? modelContext.save()
    }
}
