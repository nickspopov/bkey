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

    @Test func lessonByIdInvalidReturnsNil() {
        #expect(LessonCurriculum.lesson(byId: 999) == nil)
    }

    @Test func lessonByIdZeroReturnsNil() {
        #expect(LessonCurriculum.lesson(byId: 0) == nil)
    }

    @Test func tierDistribution() {
        let tiers = Dictionary(grouping: LessonCurriculum.allLessons, by: \.tier)
        #expect(tiers[1]?.count == 8)
        #expect(tiers[2]?.count == 10)
        #expect(tiers[3]?.count == 10)
        #expect(tiers[4]?.count == 6)
        #expect(tiers[5]?.count == 11)
    }

    @Test func allLessonsHavePositiveGates() {
        for lesson in LessonCurriculum.allLessons {
            #expect(lesson.gateWPM > 0, "Lesson \(lesson.id) has non-positive gateWPM")
            #expect(lesson.gateAccuracy > 0, "Lesson \(lesson.id) has non-positive gateAccuracy")
            #expect(lesson.gateAccuracy <= 100, "Lesson \(lesson.id) has gateAccuracy > 100")
        }
    }

    @Test func starRatingZeroWhenBelowBothGates() {
        let lesson = Lesson(id: 1, title: "Test", tier: 1, newKeys: [], allowedKeys: [], gateWPM: 20, gateAccuracy: 90)
        #expect(lesson.starRating(wpm: 10, accuracy: 80) == 0)
    }

    @Test func starRatingOneAtExactGate() {
        let lesson = Lesson(id: 1, title: "Test", tier: 1, newKeys: [], allowedKeys: [], gateWPM: 20, gateAccuracy: 90)
        #expect(lesson.starRating(wpm: 20, accuracy: 90) == 1)
    }

    @Test func starRatingThreeRequiresBothConditions() {
        let lesson = Lesson(id: 1, title: "Test", tier: 1, newKeys: [], allowedKeys: [], gateWPM: 20, gateAccuracy: 90)
        // +20 WPM but below 98% accuracy => only 2 stars
        #expect(lesson.starRating(wpm: 40, accuracy: 95) == 2)
        // 98%+ but not +20 WPM => 2 stars (from 95%+ accuracy check)
        #expect(lesson.starRating(wpm: 25, accuracy: 98) == 2)
        // Both conditions => 3 stars
        #expect(lesson.starRating(wpm: 40, accuracy: 98) == 3)
    }

    @Test func introLessonsHaveNewKeys() {
        // Lessons that introduce new keys have non-empty newKeys
        // Review/speed drill lessons may have empty newKeys
        let introLessons = [1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 19, 20, 21, 22, 23]
        for id in introLessons {
            let lesson = LessonCurriculum.lesson(byId: id)!
            #expect(!lesson.newKeys.isEmpty, "Lesson \(lesson.id) should introduce new keys")
        }
    }

    @Test func reviewLessonsHaveEmptyNewKeys() {
        let reviewLessons = [7, 8, 14, 15, 16, 17, 18, 24, 25, 26, 27, 28]
        for id in reviewLessons {
            let lesson = LessonCurriculum.lesson(byId: id)!
            #expect(lesson.newKeys.isEmpty, "Review lesson \(lesson.id) should not introduce new keys")
        }
    }

    @Test func allLessonsHaveTitle() {
        for lesson in LessonCurriculum.allLessons {
            #expect(!lesson.title.isEmpty, "Lesson \(lesson.id) has empty title")
        }
    }

    @Test func laterLessonsHaveMoreAllowedKeys() {
        let lesson1 = LessonCurriculum.lesson(byId: 1)!
        let lesson20 = LessonCurriculum.lesson(byId: 20)!
        #expect(lesson20.allowedKeys.count > lesson1.allowedKeys.count)
    }

    @Test func allLessonsHaveAllowedKeysIncludingNewKeys() {
        for lesson in LessonCurriculum.allLessons {
            for key in lesson.newKeys {
                #expect(lesson.allowedKeys.contains(key),
                    "Lesson \(lesson.id): newKey '\(key)' not in allowedKeys")
            }
        }
    }
}
