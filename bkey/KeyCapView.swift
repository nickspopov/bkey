import SwiftUI

struct KeyCapView: View {
    let key: KeyDefinition
    let isPressed: Bool
    let isExpected: Bool

    private var zoneColor: Color { key.finger.color }

    private var backgroundOpacity: Double {
        if isPressed { return 0.70 }
        if isExpected { return 0.40 }
        return 0.15
    }

    private var textColor: Color {
        if isPressed || isExpected { return Theme.keyTextHighlight }
        return Theme.keyText
    }

    var body: some View {
        Text(key.label)
            .font(Theme.keyFont)
            .foregroundStyle(textColor)
            .frame(
                width: Theme.keyUnit * key.widthMultiplier + Theme.keySpacing * (key.widthMultiplier - 1),
                height: Theme.keyUnit
            )
            .background(
                RoundedRectangle(cornerRadius: Theme.keyCornerRadius)
                    .fill(zoneColor.opacity(backgroundOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.keyCornerRadius)
                    .stroke(isExpected ? zoneColor : Color.clear, lineWidth: 2)
            )
    }
}
