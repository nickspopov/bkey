import Testing
@testable import bkey

struct LessonTests {
    @Test func curriculumHas45Lessons() {
        #expect(LessonCurriculum.allLessons.count == 45)
    }

    @Test func firstLessonHasFAndJ() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        #expect(lesson.newKeys == ["f", "j"])
        #expect(lesson.tier == 1)
    }

    @Test func lessonIdsAreSequential() {
        let ids = LessonCurriculum.allLessons.map(\.id)
        #expect(ids == Array(1...45))
    }

    @Test func starRatingGating() {
        let lesson = Lesson(id: 1, title: "Test", tier: 1, newKeys: [], allowedKeys: [], gateWPM: 15, gateAccuracy: 90)
        #expect(lesson.starRating(wpm: 10, accuracy: 95) == 0) // below WPM gate
        #expect(lesson.starRating(wpm: 15, accuracy: 85) == 0) // below accuracy gate
        #expect(lesson.starRating(wpm: 15, accuracy: 90) == 1) // meets gate
        #expect(lesson.starRating(wpm: 25, accuracy: 91) == 2) // gate + 10 WPM
        #expect(lesson.starRating(wpm: 15, accuracy: 96) == 2) // 95%+ accuracy
        #expect(lesson.starRating(wpm: 35, accuracy: 99) == 3) // gate + 20 & 98%+
    }

    @Test func allowedKeysAccumulateThroughLessons() {
        let lesson8 = LessonCurriculum.lesson(byId: 8)!
        // By lesson 8, should have all home row + space
        #expect(lesson8.allowedKeys.contains("f"))
        #expect(lesson8.allowedKeys.contains("j"))
        #expect(lesson8.allowedKeys.contains("a"))
        #expect(lesson8.allowedKeys.contains(" "))
    }
}
