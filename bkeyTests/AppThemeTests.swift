import Testing
import SwiftUI
@testable import bkey

struct AppThemeTests {
    @Test func darkThemeHasCorrectBackground() {
        let theme = AppTheme.dark
        #expect(theme.background == Color(red: 13/255, green: 17/255, blue: 23/255))
    }

    @Test func lightThemeHasWhiteBackground() {
        let theme = AppTheme.light
        #expect(theme.background == Color.white)
    }

    @Test func oledDarkThemeHasBlackBackground() {
        let theme = AppTheme.oledDark
        #expect(theme.background == Color.black)
    }

    @Test func allThemeModesResolvable() {
        let dark = AppTheme.forMode(.dark, colorScheme: .dark)
        let light = AppTheme.forMode(.light, colorScheme: .dark)
        let oled = AppTheme.forMode(.oledDark, colorScheme: .dark)
        #expect(dark.background != light.background)
        #expect(dark.background != oled.background)
        #expect(light.background != oled.background)
    }

    @Test func systemModeFollowsColorScheme() {
        let lightResult = AppTheme.forMode(.system, colorScheme: .light)
        #expect(lightResult.background == AppTheme.light.background)
        let darkResult = AppTheme.forMode(.system, colorScheme: .dark)
        #expect(darkResult.background == AppTheme.dark.background)
    }

    @Test func themeModeAllCases() {
        let cases = ThemeMode.allCases
        #expect(cases.count == 4)
    }

    @Test func themeModeDefaultIsDark() {
        let mode = ThemeMode(rawValue: "dark")
        #expect(mode == .dark)
    }

    @Test func darkThemeIsDark() {
        #expect(AppTheme.dark.isDark == true)
    }

    @Test func lightThemeIsNotDark() {
        #expect(AppTheme.light.isDark == false)
    }

    @Test func oledDarkThemeIsDark() {
        #expect(AppTheme.oledDark.isDark == true)
    }

    @Test func lightThemeScrimIsNotBlack() {
        #expect(AppTheme.light.scrimColor != AppTheme.dark.scrimColor)
    }
}
