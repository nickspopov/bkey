import Testing
import Foundation
@testable import bkey

struct LessonFlowStateTests {
    // MARK: - Initialization

    @Test func initCreatesExercises() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let flow = LessonFlowState(lesson: lesson)
        #expect(!flow.exercises.isEmpty)
        #expect(flow.currentExerciseIndex == 0)
        #expect(flow.exerciseResults.isEmpty)
    }

    @Test func initWithCustomExercises() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let exercises = [
            LessonExercise(id: 0, type: .letterDrill, title: "Drill", instruction: "Practice"),
            LessonExercise(id: 1, type: .speedChallenge, title: "Speed", instruction: "Go fast"),
        ]
        let flow = LessonFlowState(lesson: lesson, exercises: exercises)
        #expect(flow.exercises.count == 2)
    }

    // MARK: - Exercise progression

    @Test func currentExerciseReturnsFirst() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let flow = LessonFlowState(lesson: lesson)
        #expect(flow.currentExercise?.id == 0)
    }

    @Test func advanceMovesToNextExercise() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let exercises = [
            LessonExercise(id: 0, type: .letterDrill, title: "Drill", instruction: "Practice"),
            LessonExercise(id: 1, type: .speedChallenge, title: "Speed", instruction: "Go fast"),
        ]
        let flow = LessonFlowState(lesson: lesson, exercises: exercises)
        let hasNext = flow.advanceToNextExercise()
        #expect(hasNext == true)
        #expect(flow.currentExerciseIndex == 1)
        #expect(flow.currentExercise?.id == 1)
    }

    @Test func advanceReturnsFalseOnLastExercise() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let exercises = [
            LessonExercise(id: 0, type: .speedChallenge, title: "Speed", instruction: "Go fast"),
        ]
        let flow = LessonFlowState(lesson: lesson, exercises: exercises)
        let hasNext = flow.advanceToNextExercise()
        #expect(hasNext == false)
        #expect(flow.currentExerciseIndex == 0)
    }

    @Test func isOnLastExercise() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let exercises = [
            LessonExercise(id: 0, type: .letterDrill, title: "Drill", instruction: "Practice"),
            LessonExercise(id: 1, type: .speedChallenge, title: "Speed", instruction: "Go fast"),
        ]
        let flow = LessonFlowState(lesson: lesson, exercises: exercises)
        #expect(flow.isOnLastExercise == false)
        _ = flow.advanceToNextExercise()
        #expect(flow.isOnLastExercise == true)
    }

    // MARK: - Result recording

    @Test func recordResultAddsToResults() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let exercises = [
            LessonExercise(id: 0, type: .letterDrill, title: "Drill", instruction: "Practice", targetWords: ["ff", "jj"]),
            LessonExercise(id: 1, type: .speedChallenge, title: "Speed", instruction: "Go fast", targetWords: ["test"]),
        ]
        let flow = LessonFlowState(lesson: lesson, exercises: exercises)

        // Create a mock session
        let session = TypingSession(wordGenerator: WordGenerator(words: ["ff", "jj"]))
        session.start()
        for char in session.targetText {
            session.processCharacter(char)
        }

        flow.recordResult(from: session)
        #expect(flow.exerciseResults.count == 1)
        #expect(flow.exerciseResults[0].exerciseType == .letterDrill)
    }

    // MARK: - Speed challenge result extraction

    @Test func speedChallengeResultIsNilBeforeRecording() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let flow = LessonFlowState(lesson: lesson)
        #expect(flow.speedChallengeResult == nil)
    }

    @Test func speedChallengeResultExtracted() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let exercises = [
            LessonExercise(id: 0, type: .letterDrill, title: "Drill", instruction: "Practice", targetWords: ["ff"]),
            LessonExercise(id: 1, type: .speedChallenge, title: "Speed", instruction: "Go fast", targetWords: ["jj"]),
        ]
        let flow = LessonFlowState(lesson: lesson, exercises: exercises)

        // Record drill result
        let drillSession = TypingSession(wordGenerator: WordGenerator(words: ["ff"]))
        drillSession.start()
        for char in drillSession.targetText { drillSession.processCharacter(char) }
        flow.recordResult(from: drillSession)

        // Advance to speed challenge
        _ = flow.advanceToNextExercise()

        // Record speed challenge result
        let speedSession = TypingSession(wordGenerator: WordGenerator(words: ["jj"]))
        speedSession.start()
        for char in speedSession.targetText { speedSession.processCharacter(char) }
        flow.recordResult(from: speedSession)

        #expect(flow.speedChallengeResult != nil)
        #expect(flow.speedChallengeResult?.exerciseType == .speedChallenge)
    }

    // MARK: - Current exercise nil at end

    @Test func currentExerciseNilWhenPastEnd() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        let exercises = [
            LessonExercise(id: 0, type: .speedChallenge, title: "Speed", instruction: "Go fast"),
        ]
        let flow = LessonFlowState(lesson: lesson, exercises: exercises)
        // Manually set index past end
        flow.currentExerciseIndex = 1
        #expect(flow.currentExercise == nil)
    }
}
