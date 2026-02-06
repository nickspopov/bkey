import SwiftUI

struct TextDisplayView: View {
    let session: TypingSession

    private let lookBehind = 60
    private let lookAhead = 140

    var body: some View {
        Text(buildAttributedString())
            .font(Theme.textFont)
            .lineSpacing(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
    }

    private func buildAttributedString() -> AttributedString {
        let text = session.fullText
        let cursor = session.cursorIndex
        let results = session.characterResults

        let startIndex = max(0, cursor - lookBehind)
        let endIndex = min(text.count, cursor + lookAhead)

        guard startIndex < endIndex else {
            return AttributedString("")
        }

        var attributed = AttributedString()

        for i in startIndex..<endIndex {
            let charIdx = text.index(text.startIndex, offsetBy: i)
            var charStr = AttributedString(String(text[charIdx]))

            if i < cursor {
                // Already typed
                switch results[i] {
                case .correct:
                    charStr.foregroundColor = NSColor(Theme.completedText)
                case .incorrect:
                    charStr.foregroundColor = NSColor(Theme.errorText)
                    charStr.backgroundColor = NSColor(Theme.errorBackground)
                case .pending:
                    charStr.foregroundColor = NSColor(Theme.pendingText)
                }
            } else if i == cursor {
                // Cursor position
                charStr.foregroundColor = NSColor(Theme.cursorText)
                charStr.backgroundColor = NSColor(Theme.cursorBackground)
            } else {
                // Pending
                charStr.foregroundColor = NSColor(Theme.pendingText)
            }

            attributed += charStr
        }

        return attributed
    }
}
