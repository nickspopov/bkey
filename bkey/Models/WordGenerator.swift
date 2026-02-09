import Foundation

struct WordGenerator: Sendable {
    private let words: [String]

    init() {
        if let url = Bundle.main.url(forResource: "en_common_1000", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let loaded = try? JSONDecoder().decode([String].self, from: data),
           !loaded.isEmpty {
            words = loaded
        } else {
            // Fallback hardcoded list
            words = ["the","be","to","of","and","a","in","that","have","it",
                     "for","not","on","with","he","as","you","do","at","this",
                     "but","his","by","from","they","we","say","her","she","or",
                     "an","will","my","one","all","would","there","their","what","so",
                     "up","out","if","about","who","get","which","go","me","when",
                     "make","can","like","time","no","just","him","know","take","people",
                     "into","year","your","good","some","could","them","see","other","than",
                     "then","now","look","only","come","its","over","think","also","back",
                     "after","use","two","how","our","work","first","well","way","even",
                     "new","want","because","any","these","give","day","most","us","great"]
        }
    }

    /// For testing with a known word list
    init(words: [String]) {
        self.words = words
    }

    /// Generate a batch of random words with no immediate repeats
    func generateBatch(count: Int) -> [String] {
        guard !words.isEmpty else { return [] }
        var result: [String] = []
        var lastWord = ""
        for _ in 0..<count {
            var word: String
            repeat {
                word = words.randomElement()!
            } while word == lastWord && words.count > 1
            result.append(word)
            lastWord = word
        }
        return result
    }

    /// Generate exactly N words (no extras). Same no-repeat logic.
    func generateExact(count: Int) -> [String] {
        guard !words.isEmpty else { return [] }
        var result: [String] = []
        var lastWord = ""
        for _ in 0..<count {
            var word: String
            repeat {
                word = words.randomElement()!
            } while word == lastWord && words.count > 1
            result.append(word)
            lastWord = word
        }
        return result
    }
}
