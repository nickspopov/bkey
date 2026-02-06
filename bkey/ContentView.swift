import SwiftUI

struct ContentView: View {
    @State private var session = TypingSession()
    @State private var inputManager = KeyboardInputManager()

    private var expectedKeyCodes: Set<UInt16> {
        guard let char = session.expectedCharacter else { return [] }
        return KeyDefinition.keyCodes(for: char)
    }

    var body: some View {
        VStack(spacing: 0) {
            StatsBarView(session: session)

            Divider()
                .background(Color.white.opacity(0.1))

            TextDisplayView(session: session)

            Divider()
                .background(Color.white.opacity(0.1))

            KeyboardView(
                pressedKeyCodes: inputManager.pressedKeyCodes,
                expectedKeyCodes: expectedKeyCodes
            )
        }
        .background(Theme.background)
        .onAppear {
            inputManager.onCharacterTyped = { char in
                session.typeCharacter(char)
            }
            inputManager.startMonitoring()
        }
        .onDisappear {
            inputManager.stopMonitoring()
        }
    }
}

#Preview {
    ContentView()
}
