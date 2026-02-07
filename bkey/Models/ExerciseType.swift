import Foundation

enum ExerciseType: Sendable, Equatable {
    case introduction
    case letterDrill
    case wordPractice
    case sentencePractice
    case speedChallenge

    var title: String {
        switch self {
        case .introduction: "Introduction"
        case .letterDrill: "Letter Drill"
        case .wordPractice: "Word Practice"
        case .sentencePractice: "Sentence Practice"
        case .speedChallenge: "Speed Challenge"
        }
    }

    var description: String {
        switch self {
        case .introduction: "Learn the position of new keys"
        case .letterDrill: "Practice individual characters and bigrams"
        case .wordPractice: "Type real words using the keys you know"
        case .sentencePractice: "Type short phrases and sentences"
        case .speedChallenge: "Test your speed and accuracy to pass the lesson"
        }
    }

    var isTypingExercise: Bool {
        switch self {
        case .introduction: false
        case .letterDrill, .wordPractice, .sentencePractice, .speedChallenge: true
        }
    }
}
