import Foundation

struct SessionMetrics {
    /// Gross WPM = (chars / 5) / minutes
    static func grossWPM(correctChars: Int, elapsedSeconds: TimeInterval) -> Double {
        guard elapsedSeconds > 0 else { return 0 }
        let minutes = elapsedSeconds / 60.0
        return (Double(correctChars) / 5.0) / minutes
    }

    /// Accuracy = correct / total x 100
    static func accuracy(correctChars: Int, totalKeystrokes: Int) -> Double {
        guard totalKeystrokes > 0 else { return 100 }
        return (Double(correctChars) / Double(totalKeystrokes)) * 100.0
    }

    /// Net WPM = gross - (errors / minutes)
    static func netWPM(correctChars: Int, errors: Int, elapsedSeconds: TimeInterval) -> Double {
        guard elapsedSeconds > 0 else { return 0 }
        let minutes = elapsedSeconds / 60.0
        let gross = (Double(correctChars) / 5.0) / minutes
        let penalty = Double(errors) / minutes
        return max(0, gross - penalty)
    }

    /// Best WPM from rolling 10-second windows
    static func bestWPM(keystrokes: [(time: Date, correct: Bool)]) -> Double {
        guard keystrokes.count > 1 else { return 0 }
        var best: Double = 0
        let windowDuration: TimeInterval = 10.0

        for i in 0..<keystrokes.count {
            let windowStart = keystrokes[i].time
            let windowEnd = windowStart.addingTimeInterval(windowDuration)
            let inWindow = keystrokes[i...].prefix(while: { $0.time <= windowEnd })
            let correctInWindow = inWindow.filter(\.correct).count
            let wpm = (Double(correctInWindow) / 5.0) / (windowDuration / 60.0)
            best = max(best, wpm)
        }
        return best
    }

    /// Elapsed time formatted as m:ss
    static func formattedTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
