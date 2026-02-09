import Foundation

enum PracticeMode: Equatable, Sendable {
    case endless
    case timed(duration: TimedDuration)
    case wordCount(count: WordCountOption)
    case custom(text: String)

    var displayName: String {
        switch self {
        case .endless: "Endless"
        case .timed(let d): "Timed — \(d.displayLabel)"
        case .wordCount(let c): "Words — \(c.displayLabel)"
        case .custom: "Custom Text"
        }
    }
}

enum TimedDuration: Int, CaseIterable, Sendable {
    case fifteen = 15, thirty = 30, sixty = 60, onetwenty = 120

    var displayLabel: String {
        switch self {
        case .fifteen: "15s"
        case .thirty: "30s"
        case .sixty: "60s"
        case .onetwenty: "2m"
        }
    }
}

enum WordCountOption: Int, CaseIterable, Sendable {
    case ten = 10, twentyFive = 25, fifty = 50, hundred = 100

    var displayLabel: String {
        "\(rawValue)"
    }
}
