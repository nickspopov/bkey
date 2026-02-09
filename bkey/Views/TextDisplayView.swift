import SwiftUI

struct TextDisplayView: View {
    let session: TypingSession
    let fontSize: CGFloat
    let caretStyle: CaretStyle

    @Environment(\.appTheme) private var theme

    @State private var caretVisible = true
    @State private var isTyping = false
    @State private var blinkTimer: Timer?

    private let font: Font = .system(size: 22, design: .monospaced)

    var body: some View {
        let displayFont = Font.system(size: fontSize, design: .monospaced)

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    let text = session.targetText
                    ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                        Text(String(char))
                            .font(displayFont)
                            .foregroundStyle(colorForState(session.characterStates[safe: index] ?? .pending))
                            .background(alignment: .leading) {
                                if index == session.currentIndex {
                                    caretView
                                }
                            }
                            .id(index)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: session.currentIndex) {
                withAnimation(.easeOut(duration: 0.08)) {
                    proxy.scrollTo(session.currentIndex, anchor: .center)
                }
                resetBlinkTimer()
            }
        }
        .frame(height: fontSize * 2.5)
        .accessibilityIdentifier("typingTextDisplay")
        .accessibilityValue(session.targetText)
        .onAppear { startBlinkTimer() }
        .onDisappear { blinkTimer?.invalidate() }
    }

    @ViewBuilder
    private var caretView: some View {
        switch caretStyle {
        case .line:
            Rectangle()
                .fill(theme.accent)
                .frame(width: 2, height: fontSize * 1.4)
                .opacity(caretVisible ? 1 : 0)
        case .block:
            Rectangle()
                .fill(theme.accent.opacity(0.3))
                .frame(height: fontSize * 1.4)
                .opacity(caretVisible ? 1 : 0)
        case .underline:
            VStack {
                Spacer()
                Rectangle()
                    .fill(theme.accent)
                    .frame(height: 2)
            }
            .frame(height: fontSize * 1.4)
            .opacity(caretVisible ? 1 : 0)
        }
    }

    private func colorForState(_ state: CharacterState) -> Color {
        switch state {
        case .pending:   theme.textSecondary
        case .correct:   theme.textPrimary
        case .incorrect: theme.textError
        case .corrected: theme.textPrimary
        }
    }

    private func startBlinkTimer() {
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if !isTyping {
                caretVisible.toggle()
            }
        }
    }

    private func resetBlinkTimer() {
        caretVisible = true
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isTyping = false
        }
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
