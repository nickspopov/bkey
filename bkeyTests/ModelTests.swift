import Testing
import Foundation
@testable import bkey

struct SessionRecordTests {
    @Test func initSetsAllFields() {
        let record = SessionRecord(
            mode: "freeRun",
            duration: 60,
            wpm: 45.0,
            netWpm: 40.0,
            accuracy: 95.0,
            errors: 3,
            characterCount: 200
        )
        #expect(record.mode == "freeRun")
        #expect(record.duration == 60)
        #expect(record.wpm == 45.0)
        #expect(record.netWpm == 40.0)
        #expect(record.accuracy == 95.0)
        #expect(record.errors == 3)
        #expect(record.characterCount == 200)
    }

    @Test func dateIsSetOnInit() {
        let before = Date()
        let record = SessionRecord(
            mode: "freeRun", duration: 10, wpm: 20,
            netWpm: 18, accuracy: 90, errors: 1, characterCount: 50
        )
        let after = Date()
        #expect(record.date >= before)
        #expect(record.date <= after)
    }

    @Test func lessonModeString() {
        let record = SessionRecord(
            mode: "lesson-5", duration: 30, wpm: 25,
            netWpm: 22, accuracy: 88, errors: 5, characterCount: 100
        )
        #expect(record.mode == "lesson-5")
    }
}

struct LessonRecordTests {
    @Test func initSetsLessonId() {
        let record = LessonRecord(lessonId: 7)
        #expect(record.lessonId == 7)
        #expect(record.bestWPM == 0)
        #expect(record.bestAccuracy == 0)
        #expect(record.stars == 0)
        #expect(record.completedAt == nil)
        #expect(record.attempts == 0)
    }

    @Test func fieldsAreMutable() {
        let record = LessonRecord(lessonId: 1)
        record.bestWPM = 50.0
        record.bestAccuracy = 95.0
        record.stars = 3
        record.attempts = 5
        record.completedAt = Date()
        #expect(record.bestWPM == 50.0)
        #expect(record.bestAccuracy == 95.0)
        #expect(record.stars == 3)
        #expect(record.attempts == 5)
        #expect(record.completedAt != nil)
    }
}

struct UserProfileTests {
    @Test func initDefaultValues() {
        let profile = UserProfile()
        #expect(profile.totalPracticeTime == 0)
        #expect(profile.totalWordsTyped == 0)
        #expect(profile.currentLesson == 1)
    }

    @Test func fieldsAreMutable() {
        let profile = UserProfile()
        profile.totalPracticeTime = 3600
        profile.totalWordsTyped = 500
        profile.currentLesson = 10
        #expect(profile.totalPracticeTime == 3600)
        #expect(profile.totalWordsTyped == 500)
        #expect(profile.currentLesson == 10)
    }

    @Test func createdAtIsSetOnInit() {
        let before = Date()
        let profile = UserProfile()
        let after = Date()
        #expect(profile.createdAt >= before)
        #expect(profile.createdAt <= after)
    }
}

struct AudioManagerTests {
    @Test func playKeystrokeDoesNotCrash() {
        // Verifies the static method is callable without crash
        AudioManager.playKeystroke()
    }

    @Test func playErrorDoesNotCrash() {
        AudioManager.playError()
    }
}
