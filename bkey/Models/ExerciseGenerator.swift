import Foundation

struct ExerciseGenerator {
    /// Build 3-5 exercises for a lesson
    static func exercises(for lesson: Lesson) -> [LessonExercise] {
        var result: [LessonExercise] = []
        var nextId = 0

        let hasNewKeys = !lesson.newKeys.isEmpty
        let hasSpace = lesson.allowedKeys.contains(" ")

        // 1. Introduction (only if lesson introduces new keys)
        if hasNewKeys {
            let mappings = lesson.newKeys.compactMap { char -> (character: Character, finger: FingerZone)? in
                guard let finger = KeyMapping.fingerZone(for: char) else { return nil }
                return (character: char, finger: finger)
            }
            result.append(LessonExercise(
                id: nextId,
                type: .introduction,
                title: "New Keys: \(lesson.newKeys.map { String($0) }.joined(separator: " & "))",
                instruction: "Learn the position of your new keys. Press Space to continue.",
                newKeys: lesson.newKeys,
                fingerMappings: mappings
            ))
            nextId += 1
        }

        // 2. Letter drill
        let drillWords = generateLetterDrill(lesson: lesson, hasSpace: hasSpace)
        result.append(LessonExercise(
            id: nextId,
            type: .letterDrill,
            title: "Letter Drill",
            instruction: hasNewKeys
                ? "Practice the new keys with repeats and patterns"
                : "Warm up with character patterns",
            targetWords: drillWords
        ))
        nextId += 1

        // 3. Word practice
        let practiceWords = generateWordPractice(lesson: lesson)
        result.append(LessonExercise(
            id: nextId,
            type: .wordPractice,
            title: "Word Practice",
            instruction: "Type real words using the keys you know",
            targetWords: practiceWords
        ))
        nextId += 1

        // 4. Sentence practice (Tier 2+ only, needs space)
        if lesson.tier >= 2 && hasSpace {
            let sentences = generateSentencePractice(lesson: lesson)
            result.append(LessonExercise(
                id: nextId,
                type: .sentencePractice,
                title: "Sentence Practice",
                instruction: "Type short phrases to build fluency",
                targetWords: sentences
            ))
            nextId += 1
        }

        // 5. Speed challenge (always last)
        let challengeWords = generateSpeedChallenge(lesson: lesson)
        result.append(LessonExercise(
            id: nextId,
            type: .speedChallenge,
            title: "Speed Challenge",
            instruction: "Type as fast and accurately as you can to pass the lesson",
            targetWords: challengeWords
        ))

        return result
    }

    /// Generate character repeats, alternating pairs, and bigrams
    static func generateLetterDrill(lesson: Lesson, hasSpace: Bool) -> [String] {
        let chars: [Character]
        if !lesson.newKeys.isEmpty {
            chars = lesson.newKeys.filter { $0 != " " }
        } else {
            // Review lesson: use all allowed letter chars
            chars = Array(lesson.allowedKeys).filter { $0 != " " && $0.isLetter }.shuffled().prefix(6).map { $0 }
        }

        guard !chars.isEmpty else { return ["test"] }

        var items: [String] = []

        // Single character repeats (e.g., "fff", "jjj")
        for char in chars {
            items.append(String(repeating: char, count: 3))
            items.append(String(repeating: char, count: 4))
        }

        // Alternating pairs (e.g., "fjfj", "dkdk")
        if chars.count >= 2 {
            for i in 0..<chars.count {
                for j in (i+1)..<chars.count {
                    let pair = String([chars[i], chars[j], chars[i], chars[j]])
                    items.append(pair)
                    let reversed = String([chars[j], chars[i], chars[j], chars[i]])
                    items.append(reversed)
                }
            }
        }

        // Bigrams with other allowed keys
        let otherChars = Array(lesson.allowedKeys).filter { $0 != " " && !chars.contains($0) && $0.isLetter }.shuffled().prefix(4)
        for char in chars {
            for other in otherChars {
                items.append(String([char, other]))
                items.append(String([other, char]))
            }
        }

        items.shuffle()
        let selected = Array(items.prefix(20))

        // Pre-space lessons: join without spaces
        if !hasSpace {
            return [selected.joined()]
        }

        return selected
    }

    /// Generate real words filtered to allowed keys
    static func generateWordPractice(lesson: Lesson) -> [String] {
        let allowed = lesson.allowedKeys
        let gen = WordGenerator()
        let allWords = gen.generateBatch(count: 300)
        let filtered = allWords.filter { word in
            word.allSatisfy { allowed.contains($0) }
        }

        if filtered.count >= 10 {
            return Array(filtered.prefix(30))
        }

        // Fallback: generate character combinations
        let chars = Array(allowed).filter { $0 != " " }
        guard !chars.isEmpty else { return ["test"] }
        var words: [String] = []
        for _ in 0..<30 {
            let len = Int.random(in: 2...5)
            let word = String((0..<len).map { _ in chars.randomElement()! })
            words.append(word)
        }
        return words
    }

    /// Generate 3-6 word groups for sentence-like practice
    static func generateSentencePractice(lesson: Lesson) -> [String] {
        let allowed = lesson.allowedKeys
        let gen = WordGenerator()
        let allWords = gen.generateBatch(count: 300)
        let filtered = allWords.filter { word in
            word.allSatisfy { allowed.contains($0) }
        }

        guard filtered.count >= 5 else { return generateWordPractice(lesson: lesson) }

        var sentences: [String] = []
        var pool = filtered.shuffled()
        var poolIndex = 0

        for _ in 0..<8 {
            let length = Int.random(in: 3...6)
            var words: [String] = []
            for _ in 0..<length {
                if poolIndex >= pool.count {
                    pool = filtered.shuffled()
                    poolIndex = 0
                }
                words.append(pool[poolIndex])
                poolIndex += 1
            }
            sentences.append(words.joined(separator: " "))
        }

        return sentences
    }

    /// Generate 50 words for the gate exercise
    static func generateSpeedChallenge(lesson: Lesson) -> [String] {
        let allowed = lesson.allowedKeys
        let gen = WordGenerator()
        let allWords = gen.generateBatch(count: 300)
        let filtered = allWords.filter { word in
            word.allSatisfy { allowed.contains($0) }
        }

        if filtered.count >= 20 {
            return Array(filtered.shuffled().prefix(50))
        }

        // Fallback
        let chars = Array(allowed).filter { $0 != " " }
        guard !chars.isEmpty else { return ["test"] }
        var words: [String] = []
        for _ in 0..<50 {
            let len = Int.random(in: 2...5)
            let word = String((0..<len).map { _ in chars.randomElement()! })
            words.append(word)
        }
        return words
    }
}
