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

    static func normalizeCustomText(_ text: String) -> String {
        let replaced = text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        // Collapse multiple spaces
        let components = replaced.split(separator: " ")
        let collapsed = components.joined(separator: " ")
        // Truncate to 10000 chars
        if collapsed.count > 10000 {
            return String(collapsed.prefix(10000))
        }
        return collapsed
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
