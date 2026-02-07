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

        // Save per-key proficiency data
        saveProficiencyData(from: session, context: context)

        try? context.save()
    }

    @MainActor
    private static func saveProficiencyData(from session: TypingSession, context: ModelContext) {
        let keystrokes = session.characterKeystrokes
        guard !keystrokes.isEmpty else { return }

        // Group keystrokes by character
        var charAttempts: [Character: [(correct: Bool, time: Date)]] = [:]
        for ks in keystrokes {
            charAttempts[ks.character, default: []].append((correct: ks.correct, time: ks.time))
        }

        // Compute transition times: delta between consecutive keystrokes (any character)
        var transitionTimes: [Character: [Double]] = [:]
        for i in 1..<keystrokes.count {
            let delta = keystrokes[i].time.timeIntervalSince(keystrokes[i - 1].time) * 1000 // ms
            guard delta <= 5000 else { continue } // filter pauses
            transitionTimes[keystrokes[i].character, default: []].append(delta)
        }

        for (char, attempts) in charAttempts {
            let charString = String(char)
            let descriptor = FetchDescriptor<KeyProficiencyRecord>(
                predicate: #Predicate { $0.character == charString }
            )
            let existing = (try? context.fetch(descriptor))?.first
            let profRecord = existing ?? KeyProficiencyRecord(character: charString)
            if existing == nil { context.insert(profRecord) }

            for attempt in attempts {
                profRecord.recordAttempt(correct: attempt.correct)
            }

            if let times = transitionTimes[char], !times.isEmpty {
                let avgDelta = times.reduce(0, +) / Double(times.count)
                profRecord.addTransitionTime(avgDelta)
            }
        }
    }
}
