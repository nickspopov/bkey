import Testing
import Foundation
@testable import bkey

struct KeyProficiencyRecordTests {
    @Test func recentSpeedsGetSetRoundTrips() {
        let record = KeyProficiencyRecord(character: "a")
        let speeds = [100.0, 200.0, 300.0]
        record.recentSpeeds = speeds
        #expect(record.recentSpeeds == speeds)
    }

    @Test func addTransitionTimeAppends() {
        let record = KeyProficiencyRecord(character: "b")
        record.addTransitionTime(150.0)
        record.addTransitionTime(250.0)
        #expect(record.recentSpeeds.count == 2)
        #expect(record.averageSpeedMs == 200.0)
    }

    @Test func addTransitionTimeCapsAt20() {
        let record = KeyProficiencyRecord(character: "c")
        for i in 0..<25 {
            record.addTransitionTime(Double(i * 10 + 100))
        }
        #expect(record.recentSpeeds.count == 20)
    }

    @Test func recordAttemptIncrementsCorrectly() {
        let record = KeyProficiencyRecord(character: "d")
        record.recordAttempt(correct: true)
        record.recordAttempt(correct: true)
        record.recordAttempt(correct: false)
        #expect(record.totalAttempts == 3)
        #expect(record.correctAttempts == 2)
    }

    @Test func confidenceHighForFastAccurate() {
        let record = KeyProficiencyRecord(character: "e")
        record.averageSpeedMs = 150
        for _ in 0..<20 {
            record.recordAttempt(correct: true)
        }
        #expect(record.confidence > 0.9)
    }

    @Test func confidenceLowForSlowInaccurate() {
        let record = KeyProficiencyRecord(character: "f")
        record.averageSpeedMs = 500
        for _ in 0..<20 {
            record.recordAttempt(correct: false)
        }
        #expect(record.confidence == 0.0)
    }
}
