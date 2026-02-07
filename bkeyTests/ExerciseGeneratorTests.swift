import Testing
@testable import bkey

struct ExerciseGeneratorTests {
    // MARK: - Lesson with new keys

    @Test func lessonWithNewKeysHasIntroduction() {
        let lesson = LessonCurriculum.lesson(byId: 1)! // F and J
        let exercises = ExerciseGenerator.exercises(for: lesson)
        #expect(exercises.first?.type == .introduction)
        #expect(exercises.first?.newKeys == ["f", "j"])
    }

    @Test func lessonWithNewKeysHasFingerMappings() {
        let lesson = LessonCurriculum.lesson(byId: 1)! // F and J
        let exercises = ExerciseGenerator.exercises(for: lesson)
        let intro = exercises.first!
        #expect(intro.fingerMappings.count == 2)
        #expect(intro.fingerMappings[0].character == "f")
        #expect(intro.fingerMappings[1].character == "j")
    }

    // MARK: - Review lesson

    @Test func reviewLessonHasNoIntroduction() {
        let lesson = LessonCurriculum.lesson(byId: 7)! // Home Row Review
        let exercises = ExerciseGenerator.exercises(for: lesson)
        #expect(exercises.first?.type != .introduction)
    }

    @Test func reviewLessonStartsWithDrill() {
        let lesson = LessonCurriculum.lesson(byId: 7)! // Home Row Review
        let exercises = ExerciseGenerator.exercises(for: lesson)
        #expect(exercises.first?.type == .letterDrill)
    }

    // MARK: - Speed challenge

    @Test func speedChallengeAlwaysLastExercise() {
        // Test with new-key lesson
        let lesson1 = LessonCurriculum.lesson(byId: 1)!
        let exercises1 = ExerciseGenerator.exercises(for: lesson1)
        #expect(exercises1.last?.type == .speedChallenge)

        // Test with review lesson
        let lesson7 = LessonCurriculum.lesson(byId: 7)!
        let exercises7 = ExerciseGenerator.exercises(for: lesson7)
        #expect(exercises7.last?.type == .speedChallenge)
    }

    @Test func speedChallengeHasTargetWords() {
        let lesson = LessonCurriculum.lesson(byId: 9)! // E and I (Tier 2, has space)
        let exercises = ExerciseGenerator.exercises(for: lesson)
        let challenge = exercises.last!
        #expect(!challenge.targetWords.isEmpty)
    }

    // MARK: - Pre-space lessons

    @Test func preSpaceLessonDrillHasNoSpaces() {
        let lesson = LessonCurriculum.lesson(byId: 1)! // F and J, no space
        #expect(!lesson.allowedKeys.contains(" "))
        let exercises = ExerciseGenerator.exercises(for: lesson)
        let drill = exercises.first(where: { $0.type == .letterDrill })!
        // Pre-space drills should be joined into a single string (no spaces)
        #expect(drill.targetWords.count == 1)
        #expect(!drill.targetWords[0].contains(" "))
    }

    // MARK: - Sentence practice tier gating

    @Test func sentencePracticeOnlyForTier2Plus() {
        // Tier 1 lesson — no sentence practice
        let tier1 = LessonCurriculum.lesson(byId: 7)! // Home Row Review, Tier 1
        let exercises1 = ExerciseGenerator.exercises(for: tier1)
        #expect(!exercises1.contains(where: { $0.type == .sentencePractice }))

        // Tier 2 lesson — should have sentence practice
        let tier2 = LessonCurriculum.lesson(byId: 9)! // E and I, Tier 2
        let exercises2 = ExerciseGenerator.exercises(for: tier2)
        #expect(exercises2.contains(where: { $0.type == .sentencePractice }))
    }

    // MARK: - Exercise count and structure

    @Test func newKeyLessonHas4To5Exercises() {
        // Tier 2+ lesson with new keys should have: intro, drill, word, sentence, speed = 5
        let lesson = LessonCurriculum.lesson(byId: 9)! // E and I, Tier 2
        let exercises = ExerciseGenerator.exercises(for: lesson)
        #expect(exercises.count >= 4)
        #expect(exercises.count <= 5)
    }

    @Test func reviewLessonHas3To4Exercises() {
        // Tier 1 review: drill, word, speed = 3
        let lesson = LessonCurriculum.lesson(byId: 7)! // Home Row Review
        let exercises = ExerciseGenerator.exercises(for: lesson)
        #expect(exercises.count >= 3)
        #expect(exercises.count <= 4)
    }

    @Test func exerciseIdsAreSequential() {
        let lesson = LessonCurriculum.lesson(byId: 9)!
        let exercises = ExerciseGenerator.exercises(for: lesson)
        for (i, exercise) in exercises.enumerated() {
            #expect(exercise.id == i)
        }
    }

    @Test func allExercisesHaveTitles() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let exercises = ExerciseGenerator.exercises(for: lesson)
        for exercise in exercises {
            #expect(!exercise.title.isEmpty)
            #expect(!exercise.instruction.isEmpty)
        }
    }

    // MARK: - Letter drill content

    @Test func letterDrillHasTargetWords() {
        let lesson = LessonCurriculum.lesson(byId: 9)!
        let exercises = ExerciseGenerator.exercises(for: lesson)
        let drill = exercises.first(where: { $0.type == .letterDrill })!
        #expect(!drill.targetWords.isEmpty)
    }

    // MARK: - Word practice content

    @Test func wordPracticeUsesAllowedKeysOnly() {
        let lesson = LessonCurriculum.lesson(byId: 9)! // E and I
        let exercises = ExerciseGenerator.exercises(for: lesson)
        let wordPractice = exercises.first(where: { $0.type == .wordPractice })!
        let allowed = lesson.allowedKeys
        for word in wordPractice.targetWords {
            for char in word {
                #expect(allowed.contains(char), "Character '\(char)' in word '\(word)' not in allowed keys")
            }
        }
    }
}
