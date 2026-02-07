import SwiftUI

struct KeyboardView: View {
    let activeKeyCode: UInt16?
    let lastPressedKeyCode: UInt16?
    let lastPressCorrect: Bool
    let showFingerLabels: Bool
    let keystrokeCount: Int

    @State private var flashingKeyCode: UInt16? = nil

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width - 40 // padding
            // Calculate unit width from the widest row (number row has ~14.5 units)
            let widthBased = totalWidth / 14.5
            // Also constrain by available height: 5 rows * 0.95 height + 4 * 2pt spacing
            let heightBased = (geometry.size.height - 8) / (5 * 0.95)
            let unitWidth = min(widthBased, heightBased)

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
        .onChange(of: keystrokeCount) {
            flashingKeyCode = lastPressedKeyCode
            let duration: Double = lastPressCorrect ? 0.15 : 0.2
            Task {
                try? await Task.sleep(for: .seconds(duration))
                flashingKeyCode = nil
            }
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
