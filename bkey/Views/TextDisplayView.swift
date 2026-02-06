import SwiftUI

struct TextDisplayView: View {
    let session: TypingSession
    let fontSize: CGFloat
    let caretStyle: CaretStyle

    @State private var caretVisible = true
    @State private var isTyping = false
    @State private var blinkTimer: Timer?

    private let font: Font = .system(size: 22, design: .monospaced)

    var body: some View {
        let displayFont = Font.system(size: fontSize, design: .monospaced)

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    // Build attributed text
                    textContent(font: displayFont)

                    // Caret overlay
                    caretOverlay(font: displayFont)
                        .id("caret")
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: session.currentIndex) {
                // Scroll to keep caret visible
                withAnimation(.easeOut(duration: 0.08)) {
                    proxy.scrollTo("caret", anchor: .center)
                }
                resetBlinkTimer()
            }
        }
        .frame(height: fontSize * 2.5)
        .onAppear { startBlinkTimer() }
        .onDisappear { blinkTimer?.invalidate() }
    }

    @ViewBuilder
    private func textContent(font: Font) -> some View {
        let text = session.targetText
        if text.isEmpty {
            Text("").font(font)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                    Text(String(char))
                        .font(font)
                        .foregroundStyle(colorForState(session.characterStates[safe: index] ?? .pending))
                }
            }
        }
    }

    @ViewBuilder
    private func caretOverlay(font: Font) -> some View {
        let charWidth = fontSize * 0.6 // approximate monospace char width
        let xOffset = CGFloat(session.currentIndex) * charWidth + 20 // +20 for padding

        switch caretStyle {
        case .line:
            Rectangle()
                .fill(Color(red: 99/255, green: 179/255, blue: 237/255)) // #63B3ED
                .frame(width: 2, height: fontSize * 1.4)
                .offset(x: xOffset - 1, y: 0)
                .opacity(caretVisible ? 1 : 0)
        case .block:
            Rectangle()
                .fill(Color(red: 99/255, green: 179/255, blue: 237/255).opacity(0.3))
                .frame(width: charWidth, height: fontSize * 1.4)
                .offset(x: xOffset, y: 0)
                .opacity(caretVisible ? 1 : 0)
        case .underline:
            Rectangle()
                .fill(Color(red: 99/255, green: 179/255, blue: 237/255))
                .frame(width: charWidth, height: 2)
                .offset(x: xOffset, y: fontSize * 0.6)
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
