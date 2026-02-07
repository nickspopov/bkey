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

    @Test func confidenceAtSpeedBoundary170() {
        let record = KeyProficiencyRecord(character: "g")
        record.averageSpeedMs = 170
        for _ in 0..<20 {
            record.recordAttempt(correct: true)
        }
        // speedFactor = 1.0 at 170ms, accuracy = 1.0 => confidence = 1.0
        #expect(record.confidence == 1.0)
    }

    @Test func confidenceAtSpeedBoundary500() {
        let record = KeyProficiencyRecord(character: "h")
        record.averageSpeedMs = 500
        for _ in 0..<20 {
            record.recordAttempt(correct: true)
        }
        // speedFactor = 0.0 at 500ms => confidence = 0.0
        #expect(record.confidence == 0.0)
    }

    @Test func confidenceMidRange() {
        let record = KeyProficiencyRecord(character: "i")
        record.averageSpeedMs = 335 // midpoint between 170 and 500
        for _ in 0..<20 {
            record.recordAttempt(correct: true)
        }
        // speedFactor = (500-335)/(500-170) = 165/330 = 0.5
        // accuracy = 1.0, accFactor = 1.0
        // confidence = 0.5 * 1.0 = 0.5
        #expect(record.confidence == 0.5)
    }

    @Test func recentSpeedsEmptyByDefault() {
        let record = KeyProficiencyRecord(character: "j")
        #expect(record.recentSpeeds.isEmpty)
    }

    @Test func lastPracticedUpdatedOnRecordAttempt() {
        let record = KeyProficiencyRecord(character: "k")
        let before = Date()
        record.recordAttempt(correct: true)
        #expect(record.lastPracticed >= before)
    }

    @Test func recentSpeedsRoundTripsWithEmptyData() {
        let record = KeyProficiencyRecord(character: "l")
        record.recentSpeedsData = Data()
        #expect(record.recentSpeeds.isEmpty)
    }
}
