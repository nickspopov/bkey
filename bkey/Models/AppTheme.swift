import SwiftUI

enum ThemeMode: String, CaseIterable, Sendable {
    case system
    case dark
    case light
    case oledDark
}

struct AppTheme: Equatable, Sendable {
    let background: Color
    let surfaceBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let textError: Color
    let accent: Color
    let keyBackground: Color
    let keyBorder: Color
    let statsBackground: Color
    let isDark: Bool
    let scrimColor: Color

    static let dark = AppTheme(
        background: Color(red: 13/255, green: 17/255, blue: 23/255),
        surfaceBackground: Color(red: 22/255, green: 27/255, blue: 34/255),
        textPrimary: Color(red: 226/255, green: 232/255, blue: 240/255),
        textSecondary: Color(red: 74/255, green: 85/255, blue: 104/255),
        textError: Color(red: 245/255, green: 101/255, blue: 101/255),
        accent: Color(red: 99/255, green: 179/255, blue: 237/255),
        keyBackground: Color.white.opacity(0.1),
        keyBorder: Color.white.opacity(0.1),
        statsBackground: Color.white.opacity(0.03),
        isDark: true,
        scrimColor: Color.black.opacity(0.6)
    )

    static let light = AppTheme(
        background: Color.white,
        surfaceBackground: Color(red: 247/255, green: 250/255, blue: 252/255),
        textPrimary: Color(red: 26/255, green: 32/255, blue: 44/255),
        textSecondary: Color(red: 160/255, green: 174/255, blue: 192/255),
        textError: Color(red: 229/255, green: 62/255, blue: 62/255),
        accent: Color(red: 49/255, green: 130/255, blue: 206/255),
        keyBackground: Color(red: 237/255, green: 242/255, blue: 247/255),
        keyBorder: Color(red: 203/255, green: 213/255, blue: 224/255),
        statsBackground: Color(red: 237/255, green: 242/255, blue: 247/255),
        isDark: false,
        scrimColor: Color.black.opacity(0.3)
    )

    static let oledDark = AppTheme(
        background: Color.black,
        surfaceBackground: Color(red: 13/255, green: 13/255, blue: 13/255),
        textPrimary: Color(red: 226/255, green: 232/255, blue: 240/255),
        textSecondary: Color(red: 74/255, green: 85/255, blue: 104/255),
        textError: Color(red: 245/255, green: 101/255, blue: 101/255),
        accent: Color(red: 99/255, green: 179/255, blue: 237/255),
        keyBackground: Color(red: 10/255, green: 10/255, blue: 10/255),
        keyBorder: Color(red: 26/255, green: 26/255, blue: 26/255),
        statsBackground: Color(red: 5/255, green: 5/255, blue: 5/255),
        isDark: true,
        scrimColor: Color.black.opacity(0.6)
    )

    static func forMode(_ mode: ThemeMode, colorScheme: ColorScheme) -> AppTheme {
        switch mode {
        case .system: colorScheme == .dark ? .dark : .light
        case .dark: .dark
        case .light: .light
        case .oledDark: .oledDark
        }
    }
}

// MARK: - Environment Key

struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .dark
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}
