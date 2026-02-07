import Foundation
import Observation

@Observable
class KeyProficiencyTracker {
    var proficiencies: [Character: ProficiencyData] = [:]

    struct ProficiencyData {
        var totalAttempts: Int = 0
        var correctAttempts: Int = 0
        var recentSpeeds: [Double] = [] // last 20 transition times in ms
        var confidence: Double = 0

        var averageSpeed: Double {
            guard !recentSpeeds.isEmpty else { return 500 }
            return recentSpeeds.reduce(0, +) / Double(recentSpeeds.count)
        }

        var accuracy: Double {
            guard totalAttempts > 0 else { return 0 }
            return Double(correctAttempts) / Double(totalAttempts)
        }

        mutating func recordAttempt(correct: Bool, transitionTimeMs: Double?) {
            totalAttempts += 1
            if correct { correctAttempts += 1 }
            if let time = transitionTimeMs {
                recentSpeeds.append(time)
                if recentSpeeds.count > 20 { recentSpeeds.removeFirst() }
            }
            recalculateConfidence()
        }

        private mutating func recalculateConfidence() {
            let speedFactor: Double
            let avg = averageSpeed
            if avg <= 170 {
                speedFactor = 1.0
            } else if avg >= 500 {
                speedFactor = 0.0
            } else {
                speedFactor = (500 - avg) / (500 - 170)
            }
            let accFactor = accuracy * accuracy
            confidence = speedFactor * accFactor
        }
    }

    func recordAttempt(character: Character, correct: Bool, transitionTimeMs: Double?) {
        var data = proficiencies[character] ?? ProficiencyData()
        data.recordAttempt(correct: correct, transitionTimeMs: transitionTimeMs)
        proficiencies[character] = data
    }

    /// Returns the N characters with lowest confidence
    func weakestCharacters(count: Int, from allowedChars: Set<Character>? = nil) -> [Character] {
        let filtered: [(key: Character, value: ProficiencyData)]
        if let allowed = allowedChars {
            filtered = proficiencies.filter { allowed.contains($0.key) }
        } else {
            filtered = proficiencies.map { (key: $0.key, value: $0.value) }
        }
        return filtered
            .sorted { $0.value.confidence < $1.value.confidence }
            .prefix(count)
            .map(\.key)
    }
}

/// Adaptive word selection using proficiency data
struct AdaptiveWordSelector {
    /// Select words weighted toward the user's weak characters
    /// 60% weakness-weighted, 40% random
    static func selectWords(
        count: Int,
        allWords: [String],
        weakChars: [Character],
        proficiencies: [Character: KeyProficiencyTracker.ProficiencyData]
    ) -> [String] {
        guard !allWords.isEmpty else { return [] }

        let weakCount = Int(Double(count) * 0.6)
        let randomCount = count - weakCount

        // Score each word by how many weak characters it contains
        let scoredWords = allWords.map { word -> (String, Double) in
            var score = 0.0
            for char in word {
                if weakChars.contains(char) {
                    let conf = proficiencies[char]?.confidence ?? 0.5
                    score += (1.0 - conf) * (1.0 - conf)
                }
            }
            return (word, score)
        }

        // Sort by score descending, pick top weakness words
        let weakWords = scoredWords
            .sorted { $0.1 > $1.1 }
            .prefix(weakCount * 3) // pool
            .map(\.0)
            .shuffled()
            .prefix(weakCount)

        // Random words
        let randomWords = allWords.shuffled().prefix(randomCount)

        var result = Array(weakWords) + Array(randomWords)
        result.shuffle()

        // Remove consecutive duplicates
        var deduplicated: [String] = []
        for word in result {
            if deduplicated.last != word {
                deduplicated.append(word)
            }
        }

        return Array(deduplicated.prefix(count))
    }
}
