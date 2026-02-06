import SwiftUI

struct KeyboardView: View {
    let pressedKeyCodes: Set<UInt16>
    let expectedKeyCodes: Set<UInt16>

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.keySpacing) {
            ForEach(0..<KeyDefinition.fullLayout.count, id: \.self) { rowIndex in
                HStack(spacing: Theme.keySpacing) {
                    ForEach(KeyDefinition.fullLayout[rowIndex]) { key in
                        KeyCapView(
                            key: key,
                            isPressed: pressedKeyCodes.contains(key.keyCode),
                            isExpected: expectedKeyCodes.contains(key.keyCode)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
