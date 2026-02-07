import Foundation

struct LessonExercise: Identifiable, Sendable {
    let id: Int // 0-based index within lesson
    let type: ExerciseType
    let title: String
    let instruction: String
    let newKeys: [Character]
    let fingerMappings: [(character: Character, finger: FingerZone)]
    let targetWords: [String]

    init(
        id: Int,
        type: ExerciseType,
        title: String,
        instruction: String,
        newKeys: [Character] = [],
        fingerMappings: [(character: Character, finger: FingerZone)] = [],
        targetWords: [String] = []
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.instruction = instruction
        self.newKeys = newKeys
        self.fingerMappings = fingerMappings
        self.targetWords = targetWords
    }
}

extension LessonExercise: Equatable {
    static func == (lhs: LessonExercise, rhs: LessonExercise) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type && lhs.title == rhs.title
    }
}
