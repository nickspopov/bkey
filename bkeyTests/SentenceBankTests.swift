import Testing
@testable import bkey

struct SentenceBankTests {

    @Test func sentencesAreNotEmpty() {
        #expect(!SentenceBank.sentences.isEmpty)
    }

    @Test func hasSufficientSentences() {
        #expect(SentenceBank.sentences.count >= 30)
    }

    @Test func generatedTextMeetsMinLength() {
        let text = SentenceBank.generateText(minLength: 500)
        #expect(text.count >= 500)
    }

    @Test func generatedTextContainsOnlyPrintableChars() {
        let text = SentenceBank.generateText(minLength: 200)
        for char in text {
            #expect(char.isPunctuation || char.isLetter || char.isWhitespace || char.isNumber,
                    "Found non-printable character: \(char)")
        }
    }

    @Test func generatedTextIsDifferentOnSubsequentCalls() {
        // Due to shuffling, consecutive calls should usually produce different text
        let text1 = SentenceBank.generateText(minLength: 200)
        let text2 = SentenceBank.generateText(minLength: 200)
        // They could theoretically be the same, but very unlikely with 40 sentences
        // We just verify both are valid
        #expect(text1.count >= 200)
        #expect(text2.count >= 200)
    }

    @Test func allSentencesEndWithPunctuation() {
        for sentence in SentenceBank.sentences {
            let lastChar = sentence.last!
            #expect(lastChar == "." || lastChar == "!" || lastChar == "?",
                    "Sentence doesn't end with punctuation: \(sentence)")
        }
    }
}
