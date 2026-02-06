import SwiftData
import Foundation

struct PersistenceManager {
    static let shared: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            LessonRecord.self,
            SessionRecord.self,
            KeyProficiencyRecord.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @MainActor
    static func saveSession(from session: TypingSession, mode: String) {
        guard let start = session.startTime else { return }
        let end = session.endTime ?? Date()
        let elapsed = end.timeIntervalSince(start)

        // Skip trivially short sessions to avoid saving inflated stats
        guard elapsed >= 5, session.keystrokes >= 10 else { return }

        let wpm = SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsed)
        let net = SessionMetrics.netWPM(correctChars: session.correctChars, errors: session.errors, elapsedSeconds: elapsed)
        let acc = SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes)

        let record = SessionRecord(
            mode: mode,
            duration: elapsed,
            wpm: wpm,
            netWpm: net,
            accuracy: acc,
            errors: session.errors,
            characterCount: session.keystrokes
        )

        let context = shared.mainContext
        context.insert(record)

        // Update user profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(profileDescriptor)) ?? []
        let profile = profiles.first ?? UserProfile()
        if profiles.isEmpty { context.insert(profile) }
        profile.totalPracticeTime += elapsed
        profile.totalWordsTyped += session.correctChars / 5

        try? context.save()
    }
}
