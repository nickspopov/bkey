import Foundation

struct Lesson: Identifiable, Sendable {
    let id: Int
    let title: String
    let tier: Int
    let newKeys: [Character]
    let allowedKeys: Set<Character>
    let gateWPM: Int
    let gateAccuracy: Double // 0-100

    enum CompletionStatus: Sendable, Equatable {
        case locked
        case available
        case completed(stars: Int) // 1-3
    }

    /// Calculate star rating for performance
    func starRating(wpm: Double, accuracy: Double) -> Int {
        guard wpm >= Double(gateWPM) && accuracy >= gateAccuracy else { return 0 }

        if wpm >= Double(gateWPM + 20) && accuracy >= 98 {
            return 3
        } else if wpm >= Double(gateWPM + 10) || accuracy >= 95 {
            return 2
        }
        return 1
    }
}
