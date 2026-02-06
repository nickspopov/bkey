import SwiftUI

enum Theme {
    // MARK: - Colors

    static let background = Color(red: 0.10, green: 0.10, blue: 0.14)
    static let completedText = Color.white.opacity(0.35)
    static let pendingText = Color.white.opacity(0.6)
    static let cursorText = Color.white
    static let cursorBackground = Color.white.opacity(0.2)
    static let errorText = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let errorBackground = Color(red: 0.5, green: 0.1, blue: 0.1).opacity(0.4)
    static let statsLabel = Color.white.opacity(0.5)
    static let statsValue = Color.white.opacity(0.9)
    static let keyText = Color.white.opacity(0.5)
    static let keyTextHighlight = Color.white

    // MARK: - Dimensions

    static let keyUnit: CGFloat = 48
    static let keySpacing: CGFloat = 4
    static let keyCornerRadius: CGFloat = 6

    // MARK: - Fonts

    static let textFont = Font.system(size: 24, design: .monospaced)
    static let statsValueFont = Font.system(size: 28, weight: .semibold, design: .monospaced)
    static let statsLabelFont = Font.system(size: 11, weight: .medium, design: .default)
    static let keyFont = Font.system(size: 13, weight: .medium, design: .default)
}
