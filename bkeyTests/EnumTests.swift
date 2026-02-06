import Testing
@testable import bkey

struct ErrorModeTests {
    @Test func allCasesCount() {
        #expect(ErrorMode.allCases.count == 3)
    }

    @Test func rawValueRoundTrip() {
        for mode in ErrorMode.allCases {
            #expect(ErrorMode(rawValue: mode.rawValue) == mode)
        }
    }

    @Test func rawValues() {
        #expect(ErrorMode.continueOnError.rawValue == "Continue")
        #expect(ErrorMode.forceCorrect.rawValue == "Force Correct")
        #expect(ErrorMode.stopOnWord.rawValue == "Stop on Word")
    }

    @Test func invalidRawValueReturnsNil() {
        #expect(ErrorMode(rawValue: "invalid") == nil)
    }
}

struct CaretStyleTests {
    @Test func allCasesCount() {
        #expect(CaretStyle.allCases.count == 3)
    }

    @Test func rawValueRoundTrip() {
        for style in CaretStyle.allCases {
            #expect(CaretStyle(rawValue: style.rawValue) == style)
        }
    }

    @Test func rawValues() {
        #expect(CaretStyle.line.rawValue == "Line")
        #expect(CaretStyle.block.rawValue == "Block")
        #expect(CaretStyle.underline.rawValue == "Underline")
    }

    @Test func invalidRawValueReturnsNil() {
        #expect(CaretStyle(rawValue: "invalid") == nil)
    }
}

struct AppModeTests {
    @Test func equatable() {
        #expect(AppMode.freeRun == AppMode.freeRun)
        #expect(AppMode.lesson(lessonId: 1) == AppMode.lesson(lessonId: 1))
        #expect(AppMode.lesson(lessonId: 1) != AppMode.lesson(lessonId: 2))
        #expect(AppMode.freeRun != AppMode.lesson(lessonId: 1))
    }
}

struct AppTabTests {
    @Test func allCasesCount() {
        #expect(AppTab.allCases.count == 3)
    }

    @Test func rawValues() {
        #expect(AppTab.freeRun.rawValue == "Free Run")
        #expect(AppTab.lessons.rawValue == "Lessons")
        #expect(AppTab.progress.rawValue == "Progress")
    }
}

struct CharacterStateTests {
    @Test func allStatesExist() {
        let states: [CharacterState] = [.pending, .correct, .incorrect, .corrected]
        #expect(states.count == 4)
    }
}

struct LessonCompletionStatusTests {
    @Test func equatable() {
        #expect(Lesson.CompletionStatus.locked == Lesson.CompletionStatus.locked)
        #expect(Lesson.CompletionStatus.available == Lesson.CompletionStatus.available)
        #expect(Lesson.CompletionStatus.completed(stars: 2) == Lesson.CompletionStatus.completed(stars: 2))
        #expect(Lesson.CompletionStatus.completed(stars: 1) != Lesson.CompletionStatus.completed(stars: 3))
        #expect(Lesson.CompletionStatus.locked != Lesson.CompletionStatus.available)
    }
}
