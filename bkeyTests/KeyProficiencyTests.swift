import Testing
@testable import bkey

struct KeyProficiencyTests {
    @Test func initialConfidenceIsZero() {
        let tracker = KeyProficiencyTracker()
        #expect(tracker.proficiencies["a"] == nil)
    }

    @Test func recordingAttemptsUpdatesData() {
        let tracker = KeyProficiencyTracker()
        tracker.recordAttempt(character: "a", correct: true, transitionTimeMs: 200)
        tracker.recordAttempt(character: "a", correct: true, transitionTimeMs: 180)
        tracker.recordAttempt(character: "a", correct: false, transitionTimeMs: 300)

        let data = tracker.proficiencies["a"]!
        #expect(data.totalAttempts == 3)
        #expect(data.correctAttempts == 2)
        #expect(data.recentSpeeds.count == 3)
    }

    @Test func confidenceCalculation() {
        let tracker = KeyProficiencyTracker()
        // Fast and accurate -> high confidence
        for _ in 0..<20 {
            tracker.recordAttempt(character: "f", correct: true, transitionTimeMs: 150)
        }
        let fastConf = tracker.proficiencies["f"]!.confidence
        #expect(fastConf > 0.9)

        // Slow and inaccurate -> low confidence
        for _ in 0..<20 {
            tracker.recordAttempt(character: "z", correct: false, transitionTimeMs: 450)
        }
        let slowConf = tracker.proficiencies["z"]!.confidence
        #expect(slowConf < 0.1)
    }

    @Test func weakestCharactersReturnsLowestConfidence() {
        let tracker = KeyProficiencyTracker()
        tracker.recordAttempt(character: "a", correct: true, transitionTimeMs: 150)
        tracker.recordAttempt(character: "b", correct: false, transitionTimeMs: 450)
        tracker.recordAttempt(character: "c", correct: true, transitionTimeMs: 300)

        let weak = tracker.weakestCharacters(count: 2)
        #expect(weak.first == "b")
    }

    @Test func adaptiveWordSelectorReturnsCorrectCount() {
        let words = ["hello", "world", "test", "swift", "code", "apple", "banana"]
        let result = AdaptiveWordSelector.selectWords(
            count: 5,
            allWords: words,
            weakChars: ["e", "t"],
            proficiencies: [:]
        )
        #expect(result.count <= 5)
        #expect(!result.isEmpty)
    }

    @Test func averageSpeedDefaultsTo500WhenEmpty() {
        let data = KeyProficiencyTracker.ProficiencyData()
        #expect(data.averageSpeed == 500)
    }

    @Test func accuracyIsZeroWithNoAttempts() {
        let data = KeyProficiencyTracker.ProficiencyData()
        #expect(data.accuracy == 0)
    }

    @Test func recentSpeedsCappedAt20() {
        let tracker = KeyProficiencyTracker()
        for i in 0..<25 {
            tracker.recordAttempt(character: "x", correct: true, transitionTimeMs: Double(i * 10 + 100))
        }
        #expect(tracker.proficiencies["x"]!.recentSpeeds.count == 20)
    }

    @Test func weakestCharactersWithFilterReturnsOnlyAllowed() {
        let tracker = KeyProficiencyTracker()
        tracker.recordAttempt(character: "a", correct: true, transitionTimeMs: 150)
        tracker.recordAttempt(character: "b", correct: false, transitionTimeMs: 450)
        tracker.recordAttempt(character: "c", correct: true, transitionTimeMs: 300)

        let allowed: Set<Character> = ["a", "c"]
        let weak = tracker.weakestCharacters(count: 5, from: allowed)
        #expect(!weak.contains("b"))
        #expect(weak.allSatisfy { allowed.contains($0) })
    }

    @Test func adaptiveWordSelectorEmptyWeakCharsStillWorks() {
        let words = ["hello", "world", "test"]
        let result = AdaptiveWordSelector.selectWords(
            count: 3,
            allWords: words,
            weakChars: [],
            proficiencies: [:]
        )
        #expect(!result.isEmpty)
    }

    @Test func adaptiveWordSelectorEmptyWordsReturnsEmpty() {
        let result = AdaptiveWordSelector.selectWords(
            count: 5,
            allWords: [],
            weakChars: ["e"],
            proficiencies: [:]
        )
        #expect(result.isEmpty)
    }
}
