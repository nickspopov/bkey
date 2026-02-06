struct LessonCurriculum {
    static let allLessons: [Lesson] = {
        var lessons: [Lesson] = []
        var allLearnedKeys: Set<Character> = []

        // Helper to add lesson and accumulate keys
        func addLesson(id: Int, title: String, tier: Int, newKeys: [Character], gateWPM: Int, gateAccuracy: Double) {
            allLearnedKeys.formUnion(newKeys)
            lessons.append(Lesson(
                id: id, title: title, tier: tier,
                newKeys: newKeys,
                allowedKeys: allLearnedKeys,
                gateWPM: gateWPM, gateAccuracy: gateAccuracy
            ))
        }

        // Tier 1 — Home Row
        addLesson(id: 1, title: "F and J", tier: 1, newKeys: ["f", "j"], gateWPM: 5, gateAccuracy: 80)
        addLesson(id: 2, title: "D and K", tier: 1, newKeys: ["d", "k"], gateWPM: 8, gateAccuracy: 80)
        addLesson(id: 3, title: "S and L", tier: 1, newKeys: ["s", "l"], gateWPM: 10, gateAccuracy: 85)
        addLesson(id: 4, title: "A and ;", tier: 1, newKeys: ["a", ";"], gateWPM: 10, gateAccuracy: 85)
        addLesson(id: 5, title: "G and H", tier: 1, newKeys: ["g", "h"], gateWPM: 12, gateAccuracy: 85)
        addLesson(id: 6, title: "Space", tier: 1, newKeys: [" "], gateWPM: 12, gateAccuracy: 85)
        addLesson(id: 7, title: "Home Row Review", tier: 1, newKeys: [], gateWPM: 15, gateAccuracy: 88)
        addLesson(id: 8, title: "Home Row Speed", tier: 1, newKeys: [], gateWPM: 15, gateAccuracy: 90)

        // Tier 2 — Top Row
        addLesson(id: 9, title: "E and I", tier: 2, newKeys: ["e", "i"], gateWPM: 15, gateAccuracy: 85)
        addLesson(id: 10, title: "R and U", tier: 2, newKeys: ["r", "u"], gateWPM: 15, gateAccuracy: 85)
        addLesson(id: 11, title: "T and Y", tier: 2, newKeys: ["t", "y"], gateWPM: 16, gateAccuracy: 85)
        addLesson(id: 12, title: "W and O", tier: 2, newKeys: ["w", "o"], gateWPM: 17, gateAccuracy: 85)
        addLesson(id: 13, title: "Q and P", tier: 2, newKeys: ["q", "p"], gateWPM: 17, gateAccuracy: 85)
        addLesson(id: 14, title: "Top Row Review 1", tier: 2, newKeys: [], gateWPM: 18, gateAccuracy: 88)
        addLesson(id: 15, title: "Top Row Review 2", tier: 2, newKeys: [], gateWPM: 18, gateAccuracy: 88)
        addLesson(id: 16, title: "Speed Drill 1", tier: 2, newKeys: [], gateWPM: 20, gateAccuracy: 90)
        addLesson(id: 17, title: "Speed Drill 2", tier: 2, newKeys: [], gateWPM: 20, gateAccuracy: 90)
        addLesson(id: 18, title: "Speed Drill 3", tier: 2, newKeys: [], gateWPM: 20, gateAccuracy: 90)

        // Tier 3 — Bottom Row
        addLesson(id: 19, title: "V and M", tier: 3, newKeys: ["v", "m"], gateWPM: 18, gateAccuracy: 85)
        addLesson(id: 20, title: "C and ,", tier: 3, newKeys: ["c", ","], gateWPM: 18, gateAccuracy: 85)
        addLesson(id: 21, title: "X and .", tier: 3, newKeys: ["x", "."], gateWPM: 18, gateAccuracy: 85)
        addLesson(id: 22, title: "Z and /", tier: 3, newKeys: ["z", "/"], gateWPM: 18, gateAccuracy: 85)
        addLesson(id: 23, title: "B and N", tier: 3, newKeys: ["b", "n"], gateWPM: 20, gateAccuracy: 88)
        addLesson(id: 24, title: "Full Alphabet Review 1", tier: 3, newKeys: [], gateWPM: 22, gateAccuracy: 88)
        addLesson(id: 25, title: "Full Alphabet Review 2", tier: 3, newKeys: [], gateWPM: 22, gateAccuracy: 90)
        addLesson(id: 26, title: "Full Alphabet Review 3", tier: 3, newKeys: [], gateWPM: 23, gateAccuracy: 90)
        addLesson(id: 27, title: "Speed Drill", tier: 3, newKeys: [], gateWPM: 25, gateAccuracy: 92)
        addLesson(id: 28, title: "Bottom Row Mastery", tier: 3, newKeys: [], gateWPM: 25, gateAccuracy: 92)

        // Tier 4 — Shift & Capitals
        addLesson(id: 29, title: "Left Shift + Right Keys", tier: 4, newKeys: [], gateWPM: 20, gateAccuracy: 88)
        addLesson(id: 30, title: "Right Shift + Left Keys", tier: 4, newKeys: [], gateWPM: 20, gateAccuracy: 88)
        addLesson(id: 31, title: "Capital Letters", tier: 4, newKeys: [], gateWPM: 22, gateAccuracy: 90)
        addLesson(id: 32, title: "Proper Nouns", tier: 4, newKeys: [], gateWPM: 22, gateAccuracy: 90)
        addLesson(id: 33, title: "Capitalization Review", tier: 4, newKeys: [], gateWPM: 25, gateAccuracy: 92)
        addLesson(id: 34, title: "Capitalization Speed", tier: 4, newKeys: [], gateWPM: 25, gateAccuracy: 92)

        // Tier 5 — Punctuation & Numbers
        addLesson(id: 35, title: "Period and Comma", tier: 5, newKeys: [], gateWPM: 20, gateAccuracy: 85)
        addLesson(id: 36, title: "Apostrophe", tier: 5, newKeys: ["'"], gateWPM: 20, gateAccuracy: 85)
        addLesson(id: 37, title: "Question Mark", tier: 5, newKeys: ["?"], gateWPM: 20, gateAccuracy: 85)
        addLesson(id: 38, title: "Exclamation", tier: 5, newKeys: ["!"], gateWPM: 20, gateAccuracy: 85)
        addLesson(id: 39, title: "Numbers 1-5", tier: 5, newKeys: ["1","2","3","4","5"], gateWPM: 15, gateAccuracy: 85)
        addLesson(id: 40, title: "Numbers 6-0", tier: 5, newKeys: ["6","7","8","9","0"], gateWPM: 15, gateAccuracy: 85)
        addLesson(id: 41, title: "Symbols @#$", tier: 5, newKeys: ["@","#","$"], gateWPM: 12, gateAccuracy: 85)
        addLesson(id: 42, title: "Mixed Practice 1", tier: 5, newKeys: [], gateWPM: 22, gateAccuracy: 88)
        addLesson(id: 43, title: "Mixed Practice 2", tier: 5, newKeys: [], gateWPM: 23, gateAccuracy: 88)
        addLesson(id: 44, title: "Mixed Practice 3", tier: 5, newKeys: [], gateWPM: 24, gateAccuracy: 90)
        addLesson(id: 45, title: "Final Challenge", tier: 5, newKeys: [], gateWPM: 25, gateAccuracy: 90)

        return lessons
    }()

    static func lesson(byId id: Int) -> Lesson? {
        allLessons.first { $0.id == id }
    }
}
