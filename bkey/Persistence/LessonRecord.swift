import Foundation
import SwiftData

@Model
class LessonRecord {
    var lessonId: Int = 0
    var bestWPM: Double = 0
    var bestAccuracy: Double = 0
    var stars: Int = 0
    var completedAt: Date?
    var attempts: Int = 0
    var skipped: Bool = false

    init(lessonId: Int) {
        self.lessonId = lessonId
    }
}
