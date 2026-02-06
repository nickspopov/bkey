import Testing
@testable import bkey

struct WordGeneratorTests {
    @Test func generateBatchReturnsCorrectCount() {
        let gen = WordGenerator(words: ["hello", "world", "test", "swift"])
        let batch = gen.generateBatch(count: 10)
        #expect(batch.count == 10)
    }

    @Test func noImmediateRepeats() {
        let gen = WordGenerator(words: ["a", "b", "c"])
        let batch = gen.generateBatch(count: 50)
        for i in 1..<batch.count {
            #expect(batch[i] != batch[i-1], "Repeat at index \(i): \(batch[i])")
        }
    }

    @Test func singleWordListStillWorks() {
        let gen = WordGenerator(words: ["only"])
        let batch = gen.generateBatch(count: 5)
        #expect(batch.count == 5)
        #expect(batch.allSatisfy { $0 == "only" })
    }

    @Test func emptyWordListReturnsEmpty() {
        let gen = WordGenerator(words: [])
        let batch = gen.generateBatch(count: 5)
        #expect(batch.isEmpty)
    }
}
