import SwiftUI

struct TextDisplayView: View {
    let session: TypingSession
    let fontSize: CGFloat
    let caretStyle: CaretStyle

    @State private var caretVisible = true
    @State private var isTyping = false
    @State private var blinkTimer: Timer?

    private let font: Font = .system(size: 22, design: .monospaced)

    private let caretColor = Color(red: 99/255, green: 179/255, blue: 237/255) // #63B3ED

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
        .onAppear { startBlinkTimer() }
        .onDisappear { blinkTimer?.invalidate() }
    }

    @ViewBuilder
    private var caretView: some View {
        switch caretStyle {
        case .line:
            Rectangle()
                .fill(caretColor)
                .frame(width: 2, height: fontSize * 1.4)
                .opacity(caretVisible ? 1 : 0)
        case .block:
            Rectangle()
                .fill(caretColor.opacity(0.3))
                .frame(height: fontSize * 1.4)
                .opacity(caretVisible ? 1 : 0)
        case .underline:
            VStack {
                Spacer()
                Rectangle()
                    .fill(caretColor)
                    .frame(height: 2)
            }
            .frame(height: fontSize * 1.4)
            .opacity(caretVisible ? 1 : 0)
        }
    }

    private func colorForState(_ state: CharacterState) -> Color {
        switch state {
        case .pending:   Color(red: 74/255, green: 85/255, blue: 104/255)   // #4A5568
        case .correct:   Color(red: 226/255, green: 232/255, blue: 240/255) // #E2E8F0
        case .incorrect: Color(red: 245/255, green: 101/255, blue: 101/255) // #F56565
        case .corrected: Color(red: 226/255, green: 232/255, blue: 240/255) // #E2E8F0 (same as correct)
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
