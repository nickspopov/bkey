import SwiftUI

enum KeyState {
    case idle
    case target
    case pressedCorrect
    case pressedIncorrect
}

struct KeyView: View {
    let definition: KeyDefinition
    let state: KeyState
    let showFingerLabel: Bool
    let unitWidth: CGFloat

    @Environment(\.appTheme) private var theme

    var body: some View {
        let width = definition.width * unitWidth
        let height = unitWidth * 0.95

        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundFill)
                .overlay(
                    Group {
                        if !theme.isDark && state == .idle {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(definition.finger.color.opacity(0.12))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.keyBorder, lineWidth: 0.5)
                )
                .shadow(color: glowColor, radius: state == .target ? 8 : 0)

            VStack(spacing: 1) {
                Text(displayLabel)
                    .font(.system(size: labelFontSize, weight: .medium, design: .default))
                    .foregroundStyle(theme.textPrimary.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if showFingerLabel {
                    Text(definition.finger.label)
                        .font(.system(size: 7, weight: .regular))
                        .foregroundStyle(theme.textPrimary.opacity(0.4))
                }
            }
        }
        .frame(width: width, height: height)
        .scaleEffect(state == .target ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.15), value: state)
    }

    private var displayLabel: String {
        definition.label
    }

    private var labelFontSize: CGFloat {
        if definition.label.count > 3 {
            return 9
        } else if definition.label.count > 1 {
            return 10
        }
        return 13
    }

    private var backgroundFill: Color {
        switch state {
        case .idle:
            if theme.isDark {
                definition.finger.color.opacity(0.2)
            } else {
                theme.keyBackground
            }
        case .target:
            definition.finger.color.opacity(theme.isDark ? 0.8 : 0.5)
        case .pressedCorrect:
            theme.textPrimary.opacity(0.6)
        case .pressedIncorrect:
            theme.textError.opacity(0.7)
        }
    }

    private var glowColor: Color {
        state == .target ? definition.finger.color.opacity(theme.isDark ? 0.5 : 0.3) : .clear
    }
}
