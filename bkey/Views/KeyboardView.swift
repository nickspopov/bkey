import SwiftUI

struct KeyboardView: View {
    let activeKeyCode: UInt16?
    let lastPressedKeyCode: UInt16?
    let lastPressCorrect: Bool
    let showFingerLabels: Bool

    @State private var flashingKeyCode: UInt16? = nil

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width - 40 // padding
            // Calculate unit width from the widest row (number row has ~14.5 units)
            let unitWidth = totalWidth / 14.5

            VStack(spacing: 2) {
                ForEach(Array(LayoutDefinition.qwertyUS.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 2) {
                        ForEach(Array(row.keys.enumerated()), id: \.offset) { _, key in
                            KeyView(
                                definition: key,
                                state: keyState(for: key.keyCode),
                                showFingerLabel: showFingerLabels,
                                unitWidth: unitWidth
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func keyState(for keyCode: UInt16) -> KeyState {
        if keyCode == flashingKeyCode {
            return lastPressCorrect ? .pressedCorrect : .pressedIncorrect
        }
        if keyCode == activeKeyCode {
            return .target
        }
        return .idle
    }
}
