import Foundation
import Observation

struct ExerciseResult: Sendable {
    let exerciseId: Int
    let exerciseType: ExerciseType
    let wpm: Double
    let accuracy: Double
    let errors: Int
    let duration: TimeInterval
}

@Observable
class LessonFlowState {
    let lesson: Lesson
    let exercises: [LessonExercise]
    var currentExerciseIndex: Int = 0
    var exerciseResults: [ExerciseResult] = []

    init(lesson: Lesson) {
        self.lesson = lesson
        self.exercises = ExerciseGenerator.exercises(for: lesson)
    }

    /// For testing with custom exercises
    init(lesson: Lesson, exercises: [LessonExercise]) {
        self.lesson = lesson
        self.exercises = exercises
    }

    var currentExercise: LessonExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var isOnLastExercise: Bool {
        currentExerciseIndex == exercises.count - 1
    }

    var speedChallengeResult: ExerciseResult? {
        exerciseResults.first { $0.exerciseType == .speedChallenge }
    }

    func recordResult(from session: TypingSession) {
        guard let exercise = currentExercise else { return }
        let duration: TimeInterval
        if let start = session.startTime, let end = session.endTime {
            duration = end.timeIntervalSince(start)
        } else {
            duration = 0
        }
        let wpm = SessionMetrics.grossWPM(
            correctChars: session.correctChars,
            elapsedSeconds: duration
        )
        let accuracy = SessionMetrics.accuracy(
            correctChars: session.correctChars,
            totalKeystrokes: session.keystrokes
        )
        let result = ExerciseResult(
            exerciseId: exercise.id,
            exerciseType: exercise.type,
            wpm: wpm,
            accuracy: accuracy,
            errors: session.errors,
            duration: duration
        )
        exerciseResults.append(result)
    }

    /// Returns true if there's a next exercise, false if lesson is complete
    func advanceToNextExercise() -> Bool {
        guard currentExerciseIndex < exercises.count - 1 else { return false }
        currentExerciseIndex += 1
        return true
    }
}
