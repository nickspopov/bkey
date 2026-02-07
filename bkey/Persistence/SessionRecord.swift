import Foundation
import SwiftData

@Model
class SessionRecord {
    var date: Date = Date()
    var mode: String = "freeRun"
    var duration: TimeInterval = 0
    var wpm: Double = 0
    var netWpm: Double = 0
    var accuracy: Double = 0
    var errors: Int = 0
    var characterCount: Int = 0

    init(mode: String, duration: TimeInterval, wpm: Double, netWpm: Double, accuracy: Double, errors: Int, characterCount: Int) {
        self.date = Date()
        self.mode = mode
        self.duration = duration
        self.wpm = wpm
        self.netWpm = netWpm
        self.accuracy = accuracy
        self.errors = errors
        self.characterCount = characterCount
    }
}
