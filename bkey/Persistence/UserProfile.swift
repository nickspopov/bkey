import Foundation
import SwiftData

@Model
class UserProfile {
    var createdAt: Date = Date()
    var totalPracticeTime: TimeInterval = 0
    var totalWordsTyped: Int = 0
    var currentLesson: Int = 1

    init() {}
}
