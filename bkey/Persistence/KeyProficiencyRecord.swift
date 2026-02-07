import Foundation
import SwiftData

@Model
class KeyProficiencyRecord {
    @Attribute(.unique) var character: String = ""
    var totalAttempts: Int = 0
    var correctAttempts: Int = 0
    var averageSpeedMs: Double = 500
    var confidence: Double = 0
    var lastPracticed: Date = Date()

    // Store last 20 transition times as JSON-encoded array
    var recentSpeedsData: Data = Data()

    init(character: String) {
        self.character = character
    }

    var recentSpeeds: [Double] {
        get {
            (try? JSONDecoder().decode([Double].self, from: recentSpeedsData)) ?? []
        }
        set {
            recentSpeedsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    func addTransitionTime(_ ms: Double) {
        var speeds = recentSpeeds
        speeds.append(ms)
        if speeds.count > 20 { speeds.removeFirst() }
        recentSpeeds = speeds
        averageSpeedMs = speeds.reduce(0, +) / Double(speeds.count)
        recalculateConfidence()
    }

    func recordAttempt(correct: Bool) {
        totalAttempts += 1
        if correct { correctAttempts += 1 }
        lastPracticed = Date()
        recalculateConfidence()
    }

    private func recalculateConfidence() {
        let speedFactor: Double
        if averageSpeedMs <= 170 {
            speedFactor = 1.0
        } else if averageSpeedMs >= 500 {
            speedFactor = 0.0
        } else {
            speedFactor = (500 - averageSpeedMs) / (500 - 170)
        }

        let accuracyRatio = totalAttempts > 0 ? Double(correctAttempts) / Double(totalAttempts) : 0
        let accuracyFactor = accuracyRatio * accuracyRatio

        confidence = speedFactor * accuracyFactor
    }
}
