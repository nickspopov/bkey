# TouchType (bkey) — Phase 1 + Phase 2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a complete macOS touch typing tutor with free-run mode, structured lessons, adaptive engine, and persistent progress tracking.

**Architecture:** SwiftUI app with `@Observable` state management. Models are pure Swift (testable without UI). Views observe models via SwiftUI bindings. Key events captured via `NSEvent.addLocalMonitorForEvents`. Phase 2 persistence uses SwiftData. The project uses `PBXFileSystemSynchronizedRootGroup` so new files placed in `bkey/` are automatically included in the Xcode build — no `.pbxproj` edits needed.

**Tech Stack:** Swift 5.0, SwiftUI, AppKit (NSEvent), SwiftData, Swift Charts. macOS 26.0 deployment target. Zero third-party dependencies.

**Important build notes:**
- The project has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types are implicitly `@MainActor`. Use `nonisolated` explicitly where needed.
- Use `import Testing` with `@Test` macros for unit tests (not XCTest).
- Build: `xcodebuild -project bkey.xcodeproj -scheme bkey build`
- Test: `xcodebuild -project bkey.xcodeproj -scheme bkey test`
- Audio is **skipped** — settings toggles exist but no playback.
- Hand overlays are **skipped** — just color-coded keys.

---

## File Structure (Final)

```
bkey/
├── App/
│   ├── bkeyApp.swift                  // @main (modify existing)
│   └── AppState.swift                 // Global observable state
├── Models/
│   ├── TypingSession.swift            // Session state machine
│   ├── WordGenerator.swift            // Random word selection
│   ├── KeyMapping.swift               // Physical key → finger zone
│   ├── LayoutDefinition.swift         // QWERTY row/key data
│   ├── SessionMetrics.swift           // WPM/accuracy math
│   ├── Lesson.swift                   // Lesson definitions (Phase 2)
│   ├── LessonCurriculum.swift         // All 45 lessons (Phase 2)
│   └── KeyProficiency.swift           // Per-key confidence (Phase 2)
├── Views/
│   ├── ContentView.swift              // Root view (modify existing)
│   ├── TextDisplayView.swift          // Typing area with caret
│   ├── KeyboardView.swift             // On-screen keyboard
│   ├── KeyView.swift                  // Individual key
│   ├── StatsBarView.swift             // WPM, accuracy, typos
│   ├── SessionSummaryView.swift       // End overlay
│   ├── SettingsView.swift             // Settings sheet
│   ├── LessonPickerView.swift         // Lesson list (Phase 2)
│   ├── LessonView.swift               // Lesson exercise UI (Phase 2)
│   ├── ProgressView.swift             // Charts & heatmap (Phase 2)
│   └── KeyHeatmapView.swift           // Per-key heatmap (Phase 2)
├── Services/
│   ├── KeyEventHandler.swift          // NSEvent monitor
│   └── PersistenceManager.swift       // SwiftData container (Phase 2)
├── Persistence/
│   ├── UserProfile.swift              // SwiftData model (Phase 2)
│   ├── LessonRecord.swift             // SwiftData model (Phase 2)
│   ├── SessionRecord.swift            // SwiftData model (Phase 2)
│   └── KeyProficiencyRecord.swift     // SwiftData model (Phase 2)
├── Resources/
│   └── Words/
│       └── en_common_1000.json        // Word list
├── Extensions/
│   └── Color+FingerZones.swift        // Zone colors
└── Assets.xcassets/                   // Already exists
```

---

## Task 1: Word List Resource

**Files:**
- Create: `bkey/Resources/Words/en_common_1000.json`

**Step 1: Create the word list**

Create a JSON file with 200 common English words (the doc says 1000 but we start with 200 for manageable file size — extend later). Words should be lowercase, no punctuation, no duplicates, sorted alphabetically.

```json
["a","about","after","again","all","also","an","and","another","any","are","as","at","back","be","because","been","before","being","between","both","but","by","came","can","come","could","day","did","do","down","each","end","even","every","few","find","first","for","from","get","give","go","going","good","got","great","had","has","have","he","her","here","him","his","how","i","if","in","into","is","it","its","just","know","large","last","left","let","life","like","line","little","long","look","made","make","man","many","may","me","men","might","more","most","much","must","my","name","never","new","next","no","not","now","number","of","off","old","on","one","only","or","other","our","out","over","own","part","people","place","point","put","read","right","run","said","same","say","see","she","should","show","small","so","some","something","still","such","take","tell","than","that","the","their","them","then","there","these","they","thing","think","this","those","three","through","time","to","too","two","under","up","us","use","very","want","was","water","way","we","well","were","what","when","where","which","while","who","will","with","word","work","world","would","write","year","you","your"]
```

**Step 2: Commit**
```bash
git add bkey/Resources/Words/en_common_1000.json
git commit -m "feat: add common English word list resource"
```

---

## Task 2: Finger Zone Colors & Key Mapping

**Files:**
- Create: `bkey/Extensions/Color+FingerZones.swift`
- Create: `bkey/Models/KeyMapping.swift`
- Create: `bkey/Models/LayoutDefinition.swift`
- Test: `bkeyTests/KeyMappingTests.swift`

**Step 1: Write the FingerZone enum and colors**

`Color+FingerZones.swift`:
```swift
import SwiftUI

enum FingerZone: String, CaseIterable, Sendable {
    case leftPinky, leftRing, leftMiddle, leftIndex
    case rightIndex, rightMiddle, rightRing, rightPinky
    case thumb

    var color: Color {
        switch self {
        case .leftPinky:  Color(red: 246/255, green: 135/255, blue: 179/255) // #F687B3
        case .leftRing:   Color(red: 237/255, green: 137/255, blue: 54/255)  // #ED8936
        case .leftMiddle: Color(red: 236/255, green: 201/255, blue: 75/255)  // #ECC94B
        case .leftIndex:  Color(red: 104/255, green: 211/255, blue: 145/255) // #68D391
        case .rightIndex: Color(red: 79/255, green: 209/255, blue: 197/255)  // #4FD1C5
        case .rightMiddle:Color(red: 99/255, green: 179/255, blue: 237/255)  // #63B3ED
        case .rightRing:  Color(red: 127/255, green: 156/255, blue: 245/255) // #7F9CF5
        case .rightPinky: Color(red: 183/255, green: 148/255, blue: 244/255) // #B794F4
        case .thumb:      Color(red: 113/255, green: 128/255, blue: 150/255) // #718096
        }
    }

    var label: String {
        switch self {
        case .leftPinky:  "L4"
        case .leftRing:   "L3"
        case .leftMiddle: "L2"
        case .leftIndex:  "L1"
        case .rightIndex: "R1"
        case .rightMiddle:"R2"
        case .rightRing:  "R3"
        case .rightPinky: "R4"
        case .thumb:      "Th"
        }
    }
}
```

**Step 2: Write KeyDefinition and LayoutDefinition**

`LayoutDefinition.swift` — defines every key's position, size, label, and finger zone:
```swift
struct KeyDefinition: Sendable {
    let keyCode: UInt16
    let label: String
    let shiftLabel: String?
    let finger: FingerZone
    let width: CGFloat  // relative to standard key (1.0)
}

struct KeyRow: Sendable {
    let keys: [KeyDefinition]
}

struct LayoutDefinition {
    static let qwertyUS: [KeyRow] = [
        // Row 0: number row
        KeyRow(keys: [
            KeyDefinition(keyCode: 50, label: "`", shiftLabel: "~", finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 18, label: "1", shiftLabel: "!", finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 19, label: "2", shiftLabel: "@", finger: .leftRing, width: 1.0),
            KeyDefinition(keyCode: 20, label: "3", shiftLabel: "#", finger: .leftMiddle, width: 1.0),
            KeyDefinition(keyCode: 21, label: "4", shiftLabel: "$", finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 23, label: "5", shiftLabel: "%", finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 22, label: "6", shiftLabel: "^", finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 26, label: "7", shiftLabel: "&", finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 28, label: "8", shiftLabel: "*", finger: .rightMiddle, width: 1.0),
            KeyDefinition(keyCode: 25, label: "9", shiftLabel: "(", finger: .rightRing, width: 1.0),
            KeyDefinition(keyCode: 29, label: "0", shiftLabel: ")", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 27, label: "-", shiftLabel: "_", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 24, label: "=", shiftLabel: "+", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 51, label: "delete", shiftLabel: nil, finger: .rightPinky, width: 1.5),
        ]),
        // Row 1: QWERTY
        KeyRow(keys: [
            KeyDefinition(keyCode: 48, label: "tab", shiftLabel: nil, finger: .leftPinky, width: 1.5),
            KeyDefinition(keyCode: 12, label: "Q", shiftLabel: nil, finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 13, label: "W", shiftLabel: nil, finger: .leftRing, width: 1.0),
            KeyDefinition(keyCode: 14, label: "E", shiftLabel: nil, finger: .leftMiddle, width: 1.0),
            KeyDefinition(keyCode: 15, label: "R", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 17, label: "T", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 16, label: "Y", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 32, label: "U", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 34, label: "I", shiftLabel: nil, finger: .rightMiddle, width: 1.0),
            KeyDefinition(keyCode: 31, label: "O", shiftLabel: nil, finger: .rightRing, width: 1.0),
            KeyDefinition(keyCode: 35, label: "P", shiftLabel: nil, finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 33, label: "[", shiftLabel: "{", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 30, label: "]", shiftLabel: "}", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 42, label: "\\", shiftLabel: "|", finger: .rightPinky, width: 1.0),
        ]),
        // Row 2: home row
        KeyRow(keys: [
            KeyDefinition(keyCode: 57, label: "caps lock", shiftLabel: nil, finger: .leftPinky, width: 1.8),
            KeyDefinition(keyCode: 0, label: "A", shiftLabel: nil, finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 1, label: "S", shiftLabel: nil, finger: .leftRing, width: 1.0),
            KeyDefinition(keyCode: 2, label: "D", shiftLabel: nil, finger: .leftMiddle, width: 1.0),
            KeyDefinition(keyCode: 3, label: "F", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 5, label: "G", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 4, label: "H", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 38, label: "J", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 40, label: "K", shiftLabel: nil, finger: .rightMiddle, width: 1.0),
            KeyDefinition(keyCode: 37, label: "L", shiftLabel: nil, finger: .rightRing, width: 1.0),
            KeyDefinition(keyCode: 41, label: ";", shiftLabel: ":", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 39, label: "'", shiftLabel: "\"", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 36, label: "enter", shiftLabel: nil, finger: .rightPinky, width: 1.8),
        ]),
        // Row 3: bottom row
        KeyRow(keys: [
            KeyDefinition(keyCode: 56, label: "shift", shiftLabel: nil, finger: .leftPinky, width: 2.4),
            KeyDefinition(keyCode: 6, label: "Z", shiftLabel: nil, finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 7, label: "X", shiftLabel: nil, finger: .leftRing, width: 1.0),
            KeyDefinition(keyCode: 8, label: "C", shiftLabel: nil, finger: .leftMiddle, width: 1.0),
            KeyDefinition(keyCode: 9, label: "V", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 11, label: "B", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 45, label: "N", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 46, label: "M", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 43, label: ",", shiftLabel: "<", finger: .rightMiddle, width: 1.0),
            KeyDefinition(keyCode: 47, label: ".", shiftLabel: ">", finger: .rightRing, width: 1.0),
            KeyDefinition(keyCode: 44, label: "/", shiftLabel: "?", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 60, label: "shift", shiftLabel: nil, finger: .rightPinky, width: 2.4),
        ]),
        // Row 4: modifier row
        KeyRow(keys: [
            KeyDefinition(keyCode: 179, label: "fn", shiftLabel: nil, finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 59, label: "control", shiftLabel: nil, finger: .leftPinky, width: 1.3),
            KeyDefinition(keyCode: 58, label: "option", shiftLabel: nil, finger: .leftPinky, width: 1.3),
            KeyDefinition(keyCode: 55, label: "command", shiftLabel: nil, finger: .leftPinky, width: 1.5),
            KeyDefinition(keyCode: 49, label: "", shiftLabel: nil, finger: .thumb, width: 6.0),
            KeyDefinition(keyCode: 54, label: "command", shiftLabel: nil, finger: .rightPinky, width: 1.5),
            KeyDefinition(keyCode: 61, label: "option", shiftLabel: nil, finger: .rightPinky, width: 1.3),
            // Arrow keys cluster
            KeyDefinition(keyCode: 123, label: "◀", shiftLabel: nil, finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 126, label: "▲", shiftLabel: nil, finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 124, label: "▶", shiftLabel: nil, finger: .rightPinky, width: 1.0),
        ]),
    ]
}
```

**Step 3: Write KeyMapping**

`KeyMapping.swift` — maps keyCodes to finger zones and characters to keyCodes:
```swift
struct KeyMapping {
    /// Map from keyCode to FingerZone, built from layout definition
    static let keyCodeToFinger: [UInt16: FingerZone] = {
        var map: [UInt16: FingerZone] = [:]
        for row in LayoutDefinition.qwertyUS {
            for key in row.keys {
                map[key.keyCode] = key.finger
            }
        }
        return map
    }()

    /// Map from lowercase character to its keyCode
    static let characterToKeyCode: [Character: UInt16] = {
        var map: [Character: UInt16] = [:]
        for row in LayoutDefinition.qwertyUS {
            for key in row.keys {
                if key.label.count == 1 {
                    map[Character(key.label.lowercased())] = key.keyCode
                }
            }
        }
        map[" "] = 49 // space
        return map
    }()

    /// Get the finger zone for a character
    static func fingerZone(for character: Character) -> FingerZone? {
        guard let keyCode = characterToKeyCode[character] else { return nil }
        return keyCodeToFinger[keyCode]
    }

    /// Get the keyCode for a character
    static func keyCode(for character: Character) -> UInt16? {
        characterToKeyCode[character]
    }
}
```

**Step 4: Write failing tests**

`bkeyTests/KeyMappingTests.swift`:
```swift
import Testing
@testable import bkey

struct KeyMappingTests {
    @Test func fingerZoneForHomeRowKeys() {
        #expect(KeyMapping.fingerZone(for: "a") == .leftPinky)
        #expect(KeyMapping.fingerZone(for: "s") == .leftRing)
        #expect(KeyMapping.fingerZone(for: "d") == .leftMiddle)
        #expect(KeyMapping.fingerZone(for: "f") == .leftIndex)
        #expect(KeyMapping.fingerZone(for: "j") == .rightIndex)
        #expect(KeyMapping.fingerZone(for: "k") == .rightMiddle)
        #expect(KeyMapping.fingerZone(for: "l") == .rightRing)
        #expect(KeyMapping.fingerZone(for: ";") == .rightPinky)
    }

    @Test func fingerZoneForSpace() {
        #expect(KeyMapping.fingerZone(for: " ") == .thumb)
    }

    @Test func keyCodeMappingRoundTrip() {
        let code = KeyMapping.keyCode(for: "f")
        #expect(code == 3)
        #expect(KeyMapping.keyCodeToFinger[3] == .leftIndex)
    }

    @Test func allLettersHaveMapping() {
        for char in "abcdefghijklmnopqrstuvwxyz" {
            #expect(KeyMapping.fingerZone(for: char) != nil, "Missing mapping for '\(char)'")
        }
    }

    @Test func layoutHasFiveRows() {
        #expect(LayoutDefinition.qwertyUS.count == 5)
    }
}
```

**Step 5: Run tests**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey test
```
Expected: All 5 tests pass.

**Step 6: Commit**
```bash
git add bkey/Extensions/Color+FingerZones.swift bkey/Models/KeyMapping.swift bkey/Models/LayoutDefinition.swift bkeyTests/KeyMappingTests.swift
git commit -m "feat: add finger zone colors, key mapping, and QWERTY layout definition"
```

---

## Task 3: Word Generator

**Files:**
- Create: `bkey/Models/WordGenerator.swift`
- Test: `bkeyTests/WordGeneratorTests.swift`

**Step 1: Write WordGenerator**

```swift
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
}
```

**Step 2: Write tests**

```swift
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
```

**Step 3: Run tests, commit**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey test
git add bkey/Models/WordGenerator.swift bkeyTests/WordGeneratorTests.swift
git commit -m "feat: add word generator with no-repeat batch generation"
```

---

## Task 4: Typing Session Model (State Machine)

**Files:**
- Create: `bkey/Models/TypingSession.swift`
- Create: `bkey/Models/SessionMetrics.swift`
- Test: `bkeyTests/TypingSessionTests.swift`

**Step 1: Write CharacterState and TypingSession**

`TypingSession.swift`:
```swift
import Foundation
import Observation

enum CharacterState: Sendable {
    case pending
    case correct
    case incorrect
    case corrected
}

@Observable
class TypingSession {
    enum State: Sendable {
        case ready, active, paused, complete
    }

    var state: State = .ready
    var targetText: String = ""
    var characterStates: [CharacterState] = []
    var currentIndex: Int = 0
    var keystrokes: Int = 0
    var errors: Int = 0
    var correctChars: Int = 0
    var startTime: Date?
    var endTime: Date?
    var words: [String] = []
    var wordBoundaries: [Int] = [] // indices where each word starts

    // Rolling window for best WPM
    private(set) var timestampedKeystrokes: [(time: Date, correct: Bool)] = []

    private let wordGenerator: WordGenerator

    init(wordGenerator: WordGenerator = WordGenerator()) {
        self.wordGenerator = wordGenerator
    }

    func start() {
        let batch = wordGenerator.generateBatch(count: 50)
        words = batch
        targetText = batch.joined(separator: " ")
        characterStates = Array(repeating: .pending, count: targetText.count)
        currentIndex = 0
        keystrokes = 0
        errors = 0
        correctChars = 0
        startTime = nil
        endTime = nil
        state = .ready
        timestampedKeystrokes = []
        computeWordBoundaries()
    }

    func restart() {
        start()
    }

    private func computeWordBoundaries() {
        wordBoundaries = [0]
        var pos = 0
        for word in words {
            pos += word.count + 1 // +1 for space
            wordBoundaries.append(pos)
        }
    }

    func processCharacter(_ character: Character) {
        guard state == .ready || state == .active else { return }

        if state == .ready {
            state = .active
            startTime = Date()
        }

        guard currentIndex < targetText.count else { return }

        keystrokes += 1
        let expected = targetText[targetText.index(targetText.startIndex, offsetBy: currentIndex)]

        if character == expected {
            characterStates[currentIndex] = .correct
            correctChars += 1
            timestampedKeystrokes.append((time: Date(), correct: true))
            currentIndex += 1
        } else {
            characterStates[currentIndex] = .incorrect
            errors += 1
            timestampedKeystrokes.append((time: Date(), correct: false))
            currentIndex += 1
        }

        // Check if session is complete
        if currentIndex >= targetText.count {
            endSession()
        }
    }

    func processBackspace() {
        guard state == .active else { return }
        guard currentIndex > 0 else { return }

        // Find the start of the current word
        let wordStart = wordBoundaries.last(where: { $0 <= currentIndex - 1 }) ?? 0

        // Don't backspace past word boundary (can't go to previous word)
        let prevIndex = currentIndex - 1
        guard prevIndex >= wordStart else { return }

        currentIndex = prevIndex
        // If it was incorrect, mark as corrected when retyped correctly later
        characterStates[currentIndex] = .pending
    }

    func endSession() {
        guard state == .active else { return }
        state = .complete
        endTime = Date()
    }

    // Current expected character
    var currentCharacter: Character? {
        guard currentIndex < targetText.count else { return nil }
        return targetText[targetText.index(targetText.startIndex, offsetBy: currentIndex)]
    }

    // Current word index (which word the user is on)
    var currentWordIndex: Int {
        for i in (0..<wordBoundaries.count).reversed() {
            if currentIndex >= wordBoundaries[i] {
                return i
            }
        }
        return 0
    }
}
```

`SessionMetrics.swift`:
```swift
import Foundation

struct SessionMetrics {
    /// Gross WPM = (chars / 5) / minutes
    static func grossWPM(correctChars: Int, elapsedSeconds: TimeInterval) -> Double {
        guard elapsedSeconds > 0 else { return 0 }
        let minutes = elapsedSeconds / 60.0
        return (Double(correctChars) / 5.0) / minutes
    }

    /// Accuracy = correct / total × 100
    static func accuracy(correctChars: Int, totalKeystrokes: Int) -> Double {
        guard totalKeystrokes > 0 else { return 100 }
        return (Double(correctChars) / Double(totalKeystrokes)) * 100.0
    }

    /// Net WPM = gross - (errors / minutes)
    static func netWPM(correctChars: Int, errors: Int, elapsedSeconds: TimeInterval) -> Double {
        guard elapsedSeconds > 0 else { return 0 }
        let minutes = elapsedSeconds / 60.0
        let gross = (Double(correctChars) / 5.0) / minutes
        let penalty = Double(errors) / minutes
        return max(0, gross - penalty)
    }

    /// Best WPM from rolling 10-second windows
    static func bestWPM(keystrokes: [(time: Date, correct: Bool)]) -> Double {
        guard keystrokes.count > 1 else { return 0 }
        var best: Double = 0
        let windowDuration: TimeInterval = 10.0

        for i in 0..<keystrokes.count {
            let windowStart = keystrokes[i].time
            let windowEnd = windowStart.addingTimeInterval(windowDuration)
            let inWindow = keystrokes[i...].prefix(while: { $0.time <= windowEnd })
            let correctInWindow = inWindow.filter(\.correct).count
            let wpm = (Double(correctInWindow) / 5.0) / (windowDuration / 60.0)
            best = max(best, wpm)
        }
        return best
    }

    /// Elapsed time formatted as m:ss
    static func formattedTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
```

**Step 2: Write tests**

`bkeyTests/TypingSessionTests.swift`:
```swift
import Testing
@testable import bkey

struct TypingSessionTests {
    @Test func sessionStartsInReadyState() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hello", "world"]))
        session.start()
        #expect(session.state == .ready)
        #expect(session.currentIndex == 0)
        #expect(session.targetText.contains("hello"))
    }

    @Test func firstKeystrokeActivatesSession() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["ab"]))
        session.start()
        session.processCharacter("a")
        #expect(session.state == .active)
        #expect(session.startTime != nil)
    }

    @Test func correctCharacterAdvancesIndex() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        // targetText is at least "hi" (possibly followed by more words)
        session.processCharacter("h")
        #expect(session.characterStates[0] == .correct)
        #expect(session.currentIndex == 1)
        #expect(session.correctChars == 1)
    }

    @Test func incorrectCharacterMarksError() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("x") // wrong
        #expect(session.characterStates[0] == .incorrect)
        #expect(session.errors == 1)
        #expect(session.currentIndex == 1)
    }

    @Test func backspaceRetreatsIndex() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["hi"]))
        session.start()
        session.processCharacter("h")
        session.processCharacter("x") // wrong
        session.processBackspace()
        #expect(session.currentIndex == 1)
        #expect(session.characterStates[1] == .pending)
    }

    @Test func backspaceDoesNotCrosWordBoundary() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["a", "b"]))
        session.start()
        // targetText = "a b ..." — type "a", then space to move to next word
        session.processCharacter("a")
        session.processCharacter(" ")
        // Now at start of word "b", backspace should not go back to "a"
        session.processBackspace()
        #expect(session.currentIndex == 2) // stays at "b"
    }

    @Test func sessionCompletesWhenAllCharsTyped() {
        let session = TypingSession(wordGenerator: WordGenerator(words: ["a"]))
        session.start()
        // Type all characters in the target
        for char in session.targetText {
            session.processCharacter(char)
        }
        #expect(session.state == .complete)
    }
}

struct SessionMetricsTests {
    @Test func grossWPMCalculation() {
        // 50 correct chars in 60 seconds = (50/5)/1 = 10 WPM
        let wpm = SessionMetrics.grossWPM(correctChars: 50, elapsedSeconds: 60)
        #expect(wpm == 10.0)
    }

    @Test func accuracyCalculation() {
        let acc = SessionMetrics.accuracy(correctChars: 90, totalKeystrokes: 100)
        #expect(acc == 90.0)
    }

    @Test func accuracyWith100Percent() {
        let acc = SessionMetrics.accuracy(correctChars: 50, totalKeystrokes: 50)
        #expect(acc == 100.0)
    }

    @Test func netWPMWithErrors() {
        // gross = (50/5)/1 = 10, penalty = 5/1 = 5, net = 5
        let net = SessionMetrics.netWPM(correctChars: 50, errors: 5, elapsedSeconds: 60)
        #expect(net == 5.0)
    }

    @Test func formattedTime() {
        #expect(SessionMetrics.formattedTime(65) == "1:05")
        #expect(SessionMetrics.formattedTime(0) == "0:00")
        #expect(SessionMetrics.formattedTime(3600) == "60:00")
    }
}
```

**Step 3: Run tests, commit**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey test
git add bkey/Models/TypingSession.swift bkey/Models/SessionMetrics.swift bkeyTests/TypingSessionTests.swift
git commit -m "feat: add typing session state machine and metrics calculation"
```

---

## Task 5: App State & Key Event Handler

**Files:**
- Create: `bkey/App/AppState.swift`
- Create: `bkey/Services/KeyEventHandler.swift`

**Step 1: Write AppState**

`AppState.swift`:
```swift
import SwiftUI
import Observation

enum AppMode: Sendable {
    case freeRun
    case lesson(lessonId: Int)
}

@Observable
class AppState {
    var mode: AppMode = .freeRun
    var session: TypingSession = TypingSession()
    var showSettings: Bool = false
    var showSessionSummary: Bool = false

    // Settings (stored via @AppStorage in views, mirrored here for model access)
    var showKeyboard: Bool = true
    var showFingerLabels: Bool = false
    var fontSize: Int = 22
    var soundOnKeystroke: Bool = false
    var soundOnError: Bool = true
    var errorMode: ErrorMode = .continueOnError

    // Phase 2 settings
    var caretStyle: CaretStyle = .line
    var showLiveStats: Bool = true

    // Target key highlighting
    var activeKeyCode: UInt16? = nil
    var lastPressedKeyCode: UInt16? = nil
    var lastPressCorrect: Bool = true

    func startFreeRun() {
        mode = .freeRun
        session = TypingSession()
        session.start()
        showSessionSummary = false
        updateActiveKeyCode()
    }

    func handleCharacter(_ character: Character, keyCode: UInt16) {
        guard session.state == .ready || session.state == .active else { return }

        lastPressedKeyCode = keyCode
        let expectedChar = session.currentCharacter
        session.processCharacter(character)
        lastPressCorrect = (character == expectedChar)

        if session.state == .complete {
            showSessionSummary = true
        }

        updateActiveKeyCode()
    }

    func handleBackspace() {
        session.processBackspace()
        updateActiveKeyCode()
    }

    func handleEscape() {
        if session.state == .active {
            session.endSession()
            showSessionSummary = true
        }
    }

    func updateActiveKeyCode() {
        if let char = session.currentCharacter {
            activeKeyCode = KeyMapping.keyCode(for: char)
        } else {
            activeKeyCode = nil
        }
    }
}

enum ErrorMode: String, CaseIterable, Sendable {
    case continueOnError = "Continue"
    case forceCorrect = "Force Correct"
    case stopOnWord = "Stop on Word"
}

enum CaretStyle: String, CaseIterable, Sendable {
    case line = "Line"
    case block = "Block"
    case underline = "Underline"
}
```

**Step 2: Write KeyEventHandler**

`KeyEventHandler.swift`:
```swift
import AppKit

struct KeyEventHandler {
    static func setupMonitor(appState: AppState) -> Any? {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Ignore auto-repeat
            guard !event.isARepeat else { return nil }

            // Ignore modifier-only or command/control combos
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.command) || flags.contains(.control) {
                return event // pass through system shortcuts
            }

            let keyCode = event.keyCode

            // Backspace
            if keyCode == 51 {
                appState.handleBackspace()
                return nil
            }

            // Escape — end session
            if keyCode == 53 {
                appState.handleEscape()
                return nil
            }

            // Enter — if Cmd+Enter, end session (Cmd already filtered above, so just Enter)
            // Regular Enter is not used in typing; ignore
            if keyCode == 36 {
                return nil
            }

            // Tab — ignore
            if keyCode == 48 {
                return nil
            }

            // Get the typed character
            guard let characters = event.characters, let char = characters.first else {
                return nil
            }

            appState.handleCharacter(char, keyCode: keyCode)
            return nil // suppress system beep
        }
    }

    static func removeMonitor(_ monitor: Any?) {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
```

**Step 3: Commit**
```bash
git add bkey/App/AppState.swift bkey/Services/KeyEventHandler.swift
git commit -m "feat: add app state management and key event handler"
```

---

## Task 6: Stats Bar View

**Files:**
- Create: `bkey/Views/StatsBarView.swift`

**Step 1: Write StatsBarView**

```swift
import SwiftUI

struct StatsBarView: View {
    let session: TypingSession

    var body: some View {
        HStack(spacing: 40) {
            statItem(
                icon: "text.word.spacing",
                value: "\(currentWPM)",
                label: "words/min"
            )
            statItem(
                icon: "scope",
                value: "\(currentAccuracy)",
                label: "accuracy",
                suffix: "%"
            )
            statItem(
                icon: "exclamationmark.circle",
                value: "\(session.errors)",
                label: "typos"
            )
        }
        .padding(.vertical, 20)
    }

    private func statItem(icon: String, value: String, label: String, suffix: String = "") -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.gray)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if !suffix.isEmpty {
                        Text(suffix)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }

    private var currentWPM: Int {
        guard let start = session.startTime, session.state == .active else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        return Int(SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsed))
    }

    private var currentAccuracy: Int {
        Int(SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes))
    }
}
```

**Step 2: Commit**
```bash
git add bkey/Views/StatsBarView.swift
git commit -m "feat: add stats bar view with WPM, accuracy, and typos"
```

---

## Task 7: Text Display View

**Files:**
- Create: `bkey/Views/TextDisplayView.swift`

**Step 1: Write TextDisplayView**

This is the core typing area — monospace text with colored characters and an animated caret.

```swift
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
```

**Step 2: Commit**
```bash
git add bkey/Views/TextDisplayView.swift
git commit -m "feat: add text display view with caret animation and character coloring"
```

---

## Task 8: On-Screen Keyboard View

**Files:**
- Create: `bkey/Views/KeyView.swift`
- Create: `bkey/Views/KeyboardView.swift`

**Step 1: Write KeyView**

```swift
import SwiftUI

enum KeyState {
    case idle
    case target
    case pressedCorrect
    case pressedIncorrect
}

struct KeyView: View {
    let definition: KeyDefinition
    let state: KeyState
    let showFingerLabel: Bool
    let unitWidth: CGFloat

    var body: some View {
        let width = definition.width * unitWidth
        let height = unitWidth * 0.95

        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: glowColor, radius: state == .target ? 8 : 0)

            VStack(spacing: 1) {
                Text(displayLabel)
                    .font(.system(size: labelFontSize, weight: .medium, design: .default))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if showFingerLabel {
                    Text(definition.finger.label)
                        .font(.system(size: 7, weight: .regular))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .frame(width: width, height: height)
        .scaleEffect(state == .target ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.15), value: state)
    }

    private var displayLabel: String {
        definition.label
    }

    private var labelFontSize: CGFloat {
        if definition.label.count > 3 {
            return 9
        } else if definition.label.count > 1 {
            return 10
        }
        return 13
    }

    private var backgroundFill: Color {
        switch state {
        case .idle:
            definition.finger.color.opacity(0.2)
        case .target:
            definition.finger.color.opacity(0.8)
        case .pressedCorrect:
            Color.white.opacity(0.6)
        case .pressedIncorrect:
            Color.red.opacity(0.7)
        }
    }

    private var glowColor: Color {
        state == .target ? definition.finger.color.opacity(0.5) : .clear
    }
}
```

**Step 2: Write KeyboardView**

```swift
import SwiftUI

struct KeyboardView: View {
    let activeKeyCode: UInt16?
    let lastPressedKeyCode: UInt16?
    let lastPressCorrect: Bool
    let showFingerLabels: Bool

    @State private var flashingKeyCode: UInt16? = nil

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width - 40 // padding
            // Calculate unit width from the widest row (number row has ~14.5 units)
            let unitWidth = totalWidth / 14.5

            VStack(spacing: 2) {
                ForEach(Array(LayoutDefinition.qwertyUS.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 2) {
                        ForEach(Array(row.keys.enumerated()), id: \.offset) { _, key in
                            KeyView(
                                definition: key,
                                state: keyState(for: key.keyCode),
                                showFingerLabel: showFingerLabels,
                                unitWidth: unitWidth
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func keyState(for keyCode: UInt16) -> KeyState {
        if keyCode == flashingKeyCode {
            return lastPressCorrect ? .pressedCorrect : .pressedIncorrect
        }
        if keyCode == activeKeyCode {
            return .target
        }
        return .idle
    }
}
```

**Step 3: Commit**
```bash
git add bkey/Views/KeyView.swift bkey/Views/KeyboardView.swift
git commit -m "feat: add on-screen keyboard with finger-zone coloring and key states"
```

---

## Task 9: Session Summary View

**Files:**
- Create: `bkey/Views/SessionSummaryView.swift`

**Step 1: Write SessionSummaryView**

```swift
import SwiftUI

struct SessionSummaryView: View {
    let session: TypingSession
    let onTryAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Session Complete")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    summaryItem(label: "WPM", value: "\(finalWPM)")
                    summaryItem(label: "Net WPM", value: "\(finalNetWPM)")
                    summaryItem(label: "Accuracy", value: "\(finalAccuracy)%")
                    summaryItem(label: "Typos", value: "\(session.errors)")
                    summaryItem(label: "Characters", value: "\(session.keystrokes)")
                    summaryItem(label: "Time", value: formattedTime)
                }

                HStack(spacing: 16) {
                    Button("Try Again") {
                        onTryAgain()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 99/255, green: 179/255, blue: 237/255))

                    Button("Close") {
                        onClose()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(32)
            .frame(width: 400)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 22/255, green: 27/255, blue: 34/255))
                    .shadow(radius: 20)
            )
        }
    }

    private func summaryItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var elapsedSeconds: TimeInterval {
        guard let start = session.startTime else { return 0 }
        let end = session.endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    private var finalWPM: Int {
        Int(SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsedSeconds))
    }

    private var finalNetWPM: Int {
        Int(SessionMetrics.netWPM(correctChars: session.correctChars, errors: session.errors, elapsedSeconds: elapsedSeconds))
    }

    private var finalAccuracy: Int {
        Int(SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes))
    }

    private var formattedTime: String {
        SessionMetrics.formattedTime(elapsedSeconds)
    }
}
```

**Step 2: Commit**
```bash
git add bkey/Views/SessionSummaryView.swift
git commit -m "feat: add session summary overlay with metrics display"
```

---

## Task 10: Settings View

**Files:**
- Create: `bkey/Views/SettingsView.swift`

**Step 1: Write SettingsView**

```swift
import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Show Keyboard", isOn: $appState.showKeyboard)
                Toggle("Show Finger Labels", isOn: $appState.showFingerLabels)
                Stepper("Font Size: \(appState.fontSize)", value: $appState.fontSize, in: 16...32, step: 2)
                Picker("Caret Style", selection: $appState.caretStyle) {
                    ForEach(CaretStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                Toggle("Show Live Stats", isOn: $appState.showLiveStats)
            }

            Section("Sound") {
                Toggle("Sound on Keystroke", isOn: $appState.soundOnKeystroke)
                Toggle("Sound on Error", isOn: $appState.soundOnError)
            }

            Section("Typing") {
                Picker("Error Mode", selection: $appState.errorMode) {
                    ForEach(ErrorMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 400)
    }
}
```

**Step 2: Commit**
```bash
git add bkey/Views/SettingsView.swift
git commit -m "feat: add settings view with display, sound, and typing options"
```

---

## Task 11: Main View & App Assembly

**Files:**
- Modify: `bkey/ContentView.swift`
- Modify: `bkey/bkeyApp.swift` → move to `bkey/App/bkeyApp.swift`

Note: Since the project uses `PBXFileSystemSynchronizedRootGroup`, we need to keep `bkeyApp.swift` where Xcode expects it. Actually, the sync root is `bkey/` so any `.swift` file inside `bkey/` (including subdirectories) will be automatically included. We can move `bkeyApp.swift` to `bkey/App/bkeyApp.swift` and delete the old one.

**Step 1: Rewrite ContentView as the main layout**

`bkey/ContentView.swift` — replace entire contents:
```swift
import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var eventMonitor: Any?
    @State private var statsTimer: Timer?

    var body: some View {
        ZStack {
            // Background
            Color(red: 13/255, green: 17/255, blue: 23/255) // #0D1117
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Settings gear
                HStack {
                    Spacer()
                    Button {
                        appState.showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }

                // Stats bar
                if appState.showLiveStats {
                    StatsBarView(session: appState.session)
                        .id(appState.session.keystrokes) // force refresh
                }

                Spacer()

                // Text display
                TextDisplayView(
                    session: appState.session,
                    fontSize: CGFloat(appState.fontSize),
                    caretStyle: appState.caretStyle
                )

                Spacer()

                // On-screen keyboard
                if appState.showKeyboard {
                    KeyboardView(
                        activeKeyCode: appState.activeKeyCode,
                        lastPressedKeyCode: appState.lastPressedKeyCode,
                        lastPressCorrect: appState.lastPressCorrect,
                        showFingerLabels: appState.showFingerLabels
                    )
                    .frame(height: 220)
                    .padding(.bottom, 10)
                }
            }

            // Session summary overlay
            if appState.showSessionSummary {
                SessionSummaryView(
                    session: appState.session,
                    onTryAgain: {
                        appState.startFreeRun()
                    },
                    onClose: {
                        appState.showSessionSummary = false
                    }
                )
            }
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView(appState: appState)
        }
        .onAppear {
            appState.startFreeRun()
            eventMonitor = KeyEventHandler.setupMonitor(appState: appState)
        }
        .onDisappear {
            KeyEventHandler.removeMonitor(eventMonitor)
            statsTimer?.invalidate()
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
```

**Step 2: Update bkeyApp.swift**

`bkey/bkeyApp.swift` — replace contents:
```swift
import SwiftUI

@main
struct bkeyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentMinSize)
    }
}
```

**Step 3: Build and verify**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey build
```
Expected: BUILD SUCCEEDED

**Step 4: Run tests**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey test
```
Expected: All tests pass.

**Step 5: Commit**
```bash
git add bkey/ContentView.swift bkey/bkeyApp.swift
git commit -m "feat: assemble main view with stats, text display, keyboard, and settings"
```

---

## Task 12: SwiftData Persistence Models (Phase 2)

**Files:**
- Create: `bkey/Persistence/UserProfile.swift`
- Create: `bkey/Persistence/LessonRecord.swift`
- Create: `bkey/Persistence/SessionRecord.swift`
- Create: `bkey/Persistence/KeyProficiencyRecord.swift`
- Create: `bkey/Services/PersistenceManager.swift`

**Step 1: Write SwiftData models**

`UserProfile.swift`:
```swift
import Foundation
import SwiftData

@Model
class UserProfile {
    var createdAt: Date = Date()
    var totalPracticeTime: TimeInterval = 0
    var totalWordsTyped: Int = 0
    var currentLesson: Int = 1

    init() {}
}
```

`LessonRecord.swift`:
```swift
import Foundation
import SwiftData

@Model
class LessonRecord {
    var lessonId: Int = 0
    var bestWPM: Double = 0
    var bestAccuracy: Double = 0
    var stars: Int = 0
    var completedAt: Date?
    var attempts: Int = 0

    init(lessonId: Int) {
        self.lessonId = lessonId
    }
}
```

`SessionRecord.swift`:
```swift
import Foundation
import SwiftData

@Model
class SessionRecord {
    var date: Date = Date()
    var mode: String = "freeRun"
    var duration: TimeInterval = 0
    var wpm: Double = 0
    var netWpm: Double = 0
    var accuracy: Double = 0
    var errors: Int = 0
    var characterCount: Int = 0

    init(mode: String, duration: TimeInterval, wpm: Double, netWpm: Double, accuracy: Double, errors: Int, characterCount: Int) {
        self.date = Date()
        self.mode = mode
        self.duration = duration
        self.wpm = wpm
        self.netWpm = netWpm
        self.accuracy = accuracy
        self.errors = errors
        self.characterCount = characterCount
    }
}
```

`KeyProficiencyRecord.swift`:
```swift
import Foundation
import SwiftData

@Model
class KeyProficiencyRecord {
    @Attribute(.unique) var character: String = ""
    var totalAttempts: Int = 0
    var correctAttempts: Int = 0
    var averageSpeedMs: Double = 500
    var confidence: Double = 0
    var lastPracticed: Date = Date()

    // Store last 20 transition times as JSON-encoded array
    var recentSpeedsData: Data = Data()

    init(character: String) {
        self.character = character
    }

    var recentSpeeds: [Double] {
        get {
            (try? JSONDecoder().decode([Double].self, from: recentSpeedsData)) ?? []
        }
        set {
            recentSpeedsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    func addTransitionTime(_ ms: Double) {
        var speeds = recentSpeeds
        speeds.append(ms)
        if speeds.count > 20 { speeds.removeFirst() }
        recentSpeeds = speeds
        averageSpeedMs = speeds.reduce(0, +) / Double(speeds.count)
        recalculateConfidence()
    }

    func recordAttempt(correct: Bool) {
        totalAttempts += 1
        if correct { correctAttempts += 1 }
        lastPracticed = Date()
        recalculateConfidence()
    }

    private func recalculateConfidence() {
        let speedFactor: Double
        if averageSpeedMs <= 170 {
            speedFactor = 1.0
        } else if averageSpeedMs >= 500 {
            speedFactor = 0.0
        } else {
            speedFactor = (500 - averageSpeedMs) / (500 - 170)
        }

        let accuracyRatio = totalAttempts > 0 ? Double(correctAttempts) / Double(totalAttempts) : 0
        let accuracyFactor = accuracyRatio * accuracyRatio

        confidence = speedFactor * accuracyFactor
    }
}
```

**Step 2: Write PersistenceManager**

`PersistenceManager.swift`:
```swift
import SwiftData
import Foundation

struct PersistenceManager {
    static let shared: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            LessonRecord.self,
            SessionRecord.self,
            KeyProficiencyRecord.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @MainActor
    static func saveSession(from session: TypingSession, mode: String) {
        guard let start = session.startTime else { return }
        let end = session.endTime ?? Date()
        let elapsed = end.timeIntervalSince(start)

        let wpm = SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsed)
        let net = SessionMetrics.netWPM(correctChars: session.correctChars, errors: session.errors, elapsedSeconds: elapsed)
        let acc = SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes)

        let record = SessionRecord(
            mode: mode,
            duration: elapsed,
            wpm: wpm,
            netWpm: net,
            accuracy: acc,
            errors: session.errors,
            characterCount: session.keystrokes
        )

        let context = shared.mainContext
        context.insert(record)

        // Update user profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(profileDescriptor)) ?? []
        let profile = profiles.first ?? UserProfile()
        if profiles.isEmpty { context.insert(profile) }
        profile.totalPracticeTime += elapsed
        profile.totalWordsTyped += session.correctChars / 5

        try? context.save()
    }
}
```

**Step 3: Wire up SwiftData container in the app**

Update `bkeyApp.swift` to add `.modelContainer`:
```swift
import SwiftUI
import SwiftData

@main
struct bkeyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentMinSize)
        .modelContainer(PersistenceManager.shared)
    }
}
```

**Step 4: Build, test, commit**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey build
xcodebuild -project bkey.xcodeproj -scheme bkey test
git add bkey/Persistence/ bkey/Services/PersistenceManager.swift bkey/bkeyApp.swift
git commit -m "feat: add SwiftData persistence models and container setup"
```

---

## Task 13: Key Proficiency Model & Adaptive Engine (Phase 2)

**Files:**
- Create: `bkey/Models/KeyProficiency.swift`
- Test: `bkeyTests/KeyProficiencyTests.swift`

**Step 1: Write the in-memory proficiency tracker**

`KeyProficiency.swift`:
```swift
import Foundation

@Observable
class KeyProficiencyTracker {
    var proficiencies: [Character: ProficiencyData] = [:]

    struct ProficiencyData {
        var totalAttempts: Int = 0
        var correctAttempts: Int = 0
        var recentSpeeds: [Double] = [] // last 20 transition times in ms
        var confidence: Double = 0

        var averageSpeed: Double {
            guard !recentSpeeds.isEmpty else { return 500 }
            return recentSpeeds.reduce(0, +) / Double(recentSpeeds.count)
        }

        var accuracy: Double {
            guard totalAttempts > 0 else { return 0 }
            return Double(correctAttempts) / Double(totalAttempts)
        }

        mutating func recordAttempt(correct: Bool, transitionTimeMs: Double?) {
            totalAttempts += 1
            if correct { correctAttempts += 1 }
            if let time = transitionTimeMs {
                recentSpeeds.append(time)
                if recentSpeeds.count > 20 { recentSpeeds.removeFirst() }
            }
            recalculateConfidence()
        }

        private mutating func recalculateConfidence() {
            let speedFactor: Double
            let avg = averageSpeed
            if avg <= 170 {
                speedFactor = 1.0
            } else if avg >= 500 {
                speedFactor = 0.0
            } else {
                speedFactor = (500 - avg) / (500 - 170)
            }
            let accFactor = accuracy * accuracy
            confidence = speedFactor * accFactor
        }
    }

    func recordAttempt(character: Character, correct: Bool, transitionTimeMs: Double?) {
        var data = proficiencies[character] ?? ProficiencyData()
        data.recordAttempt(correct: correct, transitionTimeMs: transitionTimeMs)
        proficiencies[character] = data
    }

    /// Returns the N characters with lowest confidence
    func weakestCharacters(count: Int, from allowedChars: Set<Character>? = nil) -> [Character] {
        let filtered: [(Character, ProficiencyData)]
        if let allowed = allowedChars {
            filtered = proficiencies.filter { allowed.contains($0.key) }
        } else {
            filtered = Array(proficiencies)
        }
        return filtered
            .sorted { $0.value.confidence < $1.value.confidence }
            .prefix(count)
            .map(\.0)
    }
}

/// Adaptive word selection using proficiency data
struct AdaptiveWordSelector {
    /// Select words weighted toward the user's weak characters
    /// 60% weakness-weighted, 40% random
    static func selectWords(
        count: Int,
        allWords: [String],
        weakChars: [Character],
        proficiencies: [Character: KeyProficiencyTracker.ProficiencyData]
    ) -> [String] {
        guard !allWords.isEmpty else { return [] }

        let weakCount = Int(Double(count) * 0.6)
        let randomCount = count - weakCount

        // Score each word by how many weak characters it contains
        let scoredWords = allWords.map { word -> (String, Double) in
            var score = 0.0
            for char in word {
                if weakChars.contains(char) {
                    let conf = proficiencies[char]?.confidence ?? 0.5
                    score += (1.0 - conf) * (1.0 - conf)
                }
            }
            return (word, score)
        }

        // Sort by score descending, pick top weakness words
        let weakWords = scoredWords
            .sorted { $0.1 > $1.1 }
            .prefix(weakCount * 3) // pool
            .map(\.0)
            .shuffled()
            .prefix(weakCount)

        // Random words
        let randomWords = allWords.shuffled().prefix(randomCount)

        var result = Array(weakWords) + Array(randomWords)
        result.shuffle()

        // Remove consecutive duplicates
        var deduplicated: [String] = []
        for word in result {
            if deduplicated.last != word {
                deduplicated.append(word)
            }
        }

        return Array(deduplicated.prefix(count))
    }
}
```

**Step 2: Write tests**

`bkeyTests/KeyProficiencyTests.swift`:
```swift
import Testing
@testable import bkey

struct KeyProficiencyTests {
    @Test func initialConfidenceIsZero() {
        let tracker = KeyProficiencyTracker()
        #expect(tracker.proficiencies["a"] == nil)
    }

    @Test func recordingAttemptsUpdatesData() {
        let tracker = KeyProficiencyTracker()
        tracker.recordAttempt(character: "a", correct: true, transitionTimeMs: 200)
        tracker.recordAttempt(character: "a", correct: true, transitionTimeMs: 180)
        tracker.recordAttempt(character: "a", correct: false, transitionTimeMs: 300)

        let data = tracker.proficiencies["a"]!
        #expect(data.totalAttempts == 3)
        #expect(data.correctAttempts == 2)
        #expect(data.recentSpeeds.count == 3)
    }

    @Test func confidenceCalculation() {
        let tracker = KeyProficiencyTracker()
        // Fast and accurate → high confidence
        for _ in 0..<20 {
            tracker.recordAttempt(character: "f", correct: true, transitionTimeMs: 150)
        }
        let fastConf = tracker.proficiencies["f"]!.confidence
        #expect(fastConf > 0.9)

        // Slow and inaccurate → low confidence
        for _ in 0..<20 {
            tracker.recordAttempt(character: "z", correct: false, transitionTimeMs: 450)
        }
        let slowConf = tracker.proficiencies["z"]!.confidence
        #expect(slowConf < 0.1)
    }

    @Test func weakestCharactersReturnsLowestConfidence() {
        let tracker = KeyProficiencyTracker()
        tracker.recordAttempt(character: "a", correct: true, transitionTimeMs: 150)
        tracker.recordAttempt(character: "b", correct: false, transitionTimeMs: 450)
        tracker.recordAttempt(character: "c", correct: true, transitionTimeMs: 300)

        let weak = tracker.weakestCharacters(count: 2)
        #expect(weak.first == "b")
    }

    @Test func adaptiveWordSelectorReturnsCorrectCount() {
        let words = ["hello", "world", "test", "swift", "code", "apple", "banana"]
        let result = AdaptiveWordSelector.selectWords(
            count: 5,
            allWords: words,
            weakChars: ["e", "t"],
            proficiencies: [:]
        )
        #expect(result.count <= 5)
        #expect(!result.isEmpty)
    }
}
```

**Step 3: Run tests, commit**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey test
git add bkey/Models/KeyProficiency.swift bkeyTests/KeyProficiencyTests.swift
git commit -m "feat: add key proficiency tracking and adaptive word selection engine"
```

---

## Task 14: Lesson System (Phase 2)

**Files:**
- Create: `bkey/Models/Lesson.swift`
- Create: `bkey/Models/LessonCurriculum.swift`
- Test: `bkeyTests/LessonTests.swift`

**Step 1: Write Lesson model**

`Lesson.swift`:
```swift
import Foundation

struct Lesson: Identifiable, Sendable {
    let id: Int
    let title: String
    let tier: Int
    let newKeys: [Character]
    let allowedKeys: Set<Character>
    let gateWPM: Int
    let gateAccuracy: Double // 0-100

    enum CompletionStatus: Sendable {
        case locked
        case available
        case completed(stars: Int) // 1-3
    }

    /// Calculate star rating for performance
    func starRating(wpm: Double, accuracy: Double) -> Int {
        guard wpm >= Double(gateWPM) && accuracy >= gateAccuracy else { return 0 }

        if wpm >= Double(gateWPM + 20) && accuracy >= 98 {
            return 3
        } else if wpm >= Double(gateWPM + 10) || accuracy >= 95 {
            return 2
        }
        return 1
    }
}
```

**Step 2: Write LessonCurriculum**

`LessonCurriculum.swift`:
```swift
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

        // Tier 4 — Shift & Capitals (simplified — uses same keys but uppercase)
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
```

**Step 3: Write tests**

`bkeyTests/LessonTests.swift`:
```swift
import Testing
@testable import bkey

struct LessonTests {
    @Test func curriculumHas45Lessons() {
        #expect(LessonCurriculum.allLessons.count == 45)
    }

    @Test func firstLessonHasFAndJ() {
        let lesson = LessonCurriculum.lesson(byId: 1)!
        #expect(lesson.newKeys == ["f", "j"])
        #expect(lesson.tier == 1)
    }

    @Test func lessonIdsAreSequential() {
        let ids = LessonCurriculum.allLessons.map(\.id)
        #expect(ids == Array(1...45))
    }

    @Test func starRatingGating() {
        let lesson = Lesson(id: 1, title: "Test", tier: 1, newKeys: [], allowedKeys: [], gateWPM: 15, gateAccuracy: 90)
        #expect(lesson.starRating(wpm: 10, accuracy: 95) == 0) // below WPM gate
        #expect(lesson.starRating(wpm: 15, accuracy: 85) == 0) // below accuracy gate
        #expect(lesson.starRating(wpm: 15, accuracy: 90) == 1) // meets gate
        #expect(lesson.starRating(wpm: 25, accuracy: 91) == 2) // gate + 10 WPM
        #expect(lesson.starRating(wpm: 15, accuracy: 96) == 2) // 95%+ accuracy
        #expect(lesson.starRating(wpm: 35, accuracy: 99) == 3) // gate + 20 & 98%+
    }

    @Test func allowedKeysAccumulateThroughLessons() {
        let lesson8 = LessonCurriculum.lesson(byId: 8)!
        // By lesson 8, should have all home row + space
        #expect(lesson8.allowedKeys.contains("f"))
        #expect(lesson8.allowedKeys.contains("j"))
        #expect(lesson8.allowedKeys.contains("a"))
        #expect(lesson8.allowedKeys.contains(" "))
    }
}
```

**Step 4: Run tests, commit**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey test
git add bkey/Models/Lesson.swift bkey/Models/LessonCurriculum.swift bkeyTests/LessonTests.swift
git commit -m "feat: add lesson system with 45-lesson curriculum and star rating"
```

---

## Task 15: Lesson Picker & Lesson View (Phase 2 UI)

**Files:**
- Create: `bkey/Views/LessonPickerView.swift`
- Create: `bkey/Views/LessonView.swift`

**Step 1: Write LessonPickerView**

```swift
import SwiftUI
import SwiftData

struct LessonPickerView: View {
    @Bindable var appState: AppState
    @Query private var lessonRecords: [LessonRecord]
    @Environment(\.dismiss) private var dismiss

    private let tiers = [
        (1, "Home Row"),
        (2, "Top Row"),
        (3, "Bottom Row"),
        (4, "Shift & Capitals"),
        (5, "Punctuation & Numbers"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Free Run button
                    Button {
                        appState.startFreeRun()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "keyboard")
                            Text("Free Run")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    ForEach(tiers, id: \.0) { tier, tierName in
                        Section {
                            let tierLessons = LessonCurriculum.allLessons.filter { $0.tier == tier }
                            ForEach(tierLessons) { lesson in
                                lessonRow(lesson)
                            }
                        } header: {
                            Text("Tier \(tier): \(tierName)")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding()
            }
            .background(Color(red: 13/255, green: 17/255, blue: 23/255))
            .navigationTitle("Lessons")
        }
        .frame(width: 500, height: 600)
    }

    private func lessonRow(_ lesson: Lesson) -> some View {
        let record = lessonRecords.first { $0.lessonId == lesson.id }
        let status = lessonStatus(lesson, record: record)

        return Button {
            if case .locked = status { return }
            appState.mode = .lesson(lessonId: lesson.id)
            appState.session = TypingSession(
                wordGenerator: WordGenerator(words: wordsForLesson(lesson))
            )
            appState.session.start()
            appState.updateActiveKeyCode()
            dismiss()
        } label: {
            HStack {
                Text("\(lesson.id).")
                    .foregroundStyle(.gray)
                    .frame(width: 30)
                Text(lesson.title)
                    .foregroundStyle(status == .locked ? .gray.opacity(0.5) : .white)
                Spacer()
                if !lesson.newKeys.isEmpty {
                    Text(lesson.newKeys.map(String.init).joined(separator: " "))
                        .font(.caption.monospaced())
                        .foregroundStyle(.gray)
                }
                starsView(status)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(status == .locked ? 0.02 : 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(status == .locked)
    }

    @ViewBuilder
    private func starsView(_ status: Lesson.CompletionStatus) -> some View {
        switch status {
        case .locked:
            Image(systemName: "lock.fill")
                .foregroundStyle(.gray.opacity(0.3))
        case .available:
            EmptyView()
        case .completed(let stars):
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(i <= stars ? .yellow : .gray.opacity(0.3))
                }
            }
        }
    }

    private func lessonStatus(_ lesson: Lesson, record: LessonRecord?) -> Lesson.CompletionStatus {
        if let record = record, record.stars > 0 {
            return .completed(stars: record.stars)
        }
        // Lesson 1 is always available
        if lesson.id == 1 { return .available }
        // Check if previous lesson is completed
        let prevRecord = lessonRecords.first { $0.lessonId == lesson.id - 1 }
        if let prev = prevRecord, prev.stars > 0 {
            return .available
        }
        return .locked
    }

    private func wordsForLesson(_ lesson: Lesson) -> [String] {
        // Generate words using only allowed keys
        let allowed = lesson.allowedKeys
        let gen = WordGenerator()
        let allWords = gen.generateBatch(count: 200)
        let filtered = allWords.filter { word in
            word.allSatisfy { allowed.contains($0) }
        }
        if filtered.count >= 10 {
            return filtered
        }
        // Fallback: generate character combinations
        let chars = Array(allowed).filter { $0 != " " }
        var words: [String] = []
        for _ in 0..<50 {
            let len = Int.random(in: 2...5)
            let word = String((0..<len).map { _ in chars.randomElement()! })
            words.append(word)
        }
        return words
    }
}
```

**Step 2: Write a minimal LessonView wrapper (reuses the typing interface)**

`LessonView.swift`:
```swift
import SwiftUI
import SwiftData

struct LessonResultView: View {
    let lesson: Lesson
    let session: TypingSession
    let onNext: () -> Void
    let onRetry: () -> Void
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Lesson \(lesson.id): \(lesson.title)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                // Star display
                let stars = lesson.starRating(wpm: finalWPM, accuracy: finalAccuracy)
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .font(.largeTitle)
                            .foregroundStyle(i <= stars ? .yellow : .gray.opacity(0.3))
                    }
                }

                // Gate info
                if stars == 0 {
                    Text("Target: \(lesson.gateWPM) WPM, \(Int(lesson.gateAccuracy))% accuracy")
                        .foregroundStyle(.orange)
                } else {
                    Text("Lesson Complete!")
                        .foregroundStyle(.green)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    summaryItem(label: "WPM", value: "\(Int(finalWPM))")
                    summaryItem(label: "Accuracy", value: "\(Int(finalAccuracy))%")
                    summaryItem(label: "Typos", value: "\(session.errors)")
                    summaryItem(label: "Time", value: formattedTime)
                }

                HStack(spacing: 16) {
                    if stars > 0 {
                        Button("Next Lesson") { onNext() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    }
                    Button("Retry") { onRetry() }
                        .buttonStyle(.bordered)
                    Button("Close") { onClose() }
                        .buttonStyle(.bordered)
                }
            }
            .padding(32)
            .frame(width: 420)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 22/255, green: 27/255, blue: 34/255))
                    .shadow(radius: 20)
            )
            .onAppear { saveLessonResult(stars: stars) }
        }
    }

    private func summaryItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }

    private var stars: Int {
        lesson.starRating(wpm: finalWPM, accuracy: finalAccuracy)
    }

    private var elapsedSeconds: TimeInterval {
        guard let start = session.startTime else { return 0 }
        let end = session.endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    private var finalWPM: Double {
        SessionMetrics.grossWPM(correctChars: session.correctChars, elapsedSeconds: elapsedSeconds)
    }

    private var finalAccuracy: Double {
        SessionMetrics.accuracy(correctChars: session.correctChars, totalKeystrokes: session.keystrokes)
    }

    private var formattedTime: String {
        SessionMetrics.formattedTime(elapsedSeconds)
    }

    private func saveLessonResult(stars: Int) {
        let descriptor = FetchDescriptor<LessonRecord>(
            predicate: #Predicate { $0.lessonId == lesson.id }
        )
        let existing = try? modelContext.fetch(descriptor)
        let record = existing?.first ?? LessonRecord(lessonId: lesson.id)
        if existing?.first == nil { modelContext.insert(record) }

        record.attempts += 1
        if finalWPM > record.bestWPM { record.bestWPM = finalWPM }
        if finalAccuracy > record.bestAccuracy { record.bestAccuracy = finalAccuracy }
        if stars > record.stars {
            record.stars = stars
            record.completedAt = Date()
        }
        try? modelContext.save()
    }
}
```

**Step 3: Commit**
```bash
git add bkey/Views/LessonPickerView.swift bkey/Views/LessonView.swift
git commit -m "feat: add lesson picker and lesson result views"
```

---

## Task 16: Progress Views — WPM Chart & Key Heatmap (Phase 2)

**Files:**
- Create: `bkey/Views/ProgressDashboardView.swift`
- Create: `bkey/Views/KeyHeatmapView.swift`

**Step 1: Write ProgressDashboardView with Swift Charts**

`ProgressDashboardView.swift`:
```swift
import SwiftUI
import Charts
import SwiftData

struct ProgressDashboardView: View {
    @Query(sort: \SessionRecord.date) private var sessions: [SessionRecord]
    @Query private var proficiencies: [KeyProficiencyRecord]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Progress")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                // WPM Over Time
                if !sessions.isEmpty {
                    Section {
                        wpmChart
                    } header: {
                        Text("WPM Over Time")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }

                // Stats summary
                statsGrid

                // Key Heatmap
                Section {
                    KeyHeatmapView(proficiencies: proficiencies)
                } header: {
                    Text("Key Proficiency")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .padding()
        }
        .background(Color(red: 13/255, green: 17/255, blue: 23/255))
        .frame(width: 600, height: 700)
    }

    @ViewBuilder
    private var wpmChart: some View {
        Chart {
            ForEach(sessions, id: \.date) { session in
                LineMark(
                    x: .value("Date", session.date),
                    y: .value("Gross WPM", session.wpm)
                )
                .foregroundStyle(Color(red: 99/255, green: 179/255, blue: 237/255))
                .symbol(Circle())

                LineMark(
                    x: .value("Date", session.date),
                    y: .value("Net WPM", session.netWpm)
                )
                .foregroundStyle(Color(red: 104/255, green: 211/255, blue: 145/255))
                .symbol(Diamond())
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisValueLabel()
                    .foregroundStyle(.gray)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
                    .foregroundStyle(.gray)
            }
        }
        .frame(height: 200)
        .padding()
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statsGrid: some View {
        let totalSessions = sessions.count
        let totalTime = sessions.reduce(0.0) { $0 + $1.duration }
        let avgWPM = sessions.isEmpty ? 0 : sessions.reduce(0.0) { $0 + $1.wpm } / Double(sessions.count)
        let bestWPM = sessions.map(\.wpm).max() ?? 0

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(label: "Sessions", value: "\(totalSessions)")
            statCard(label: "Total Time", value: SessionMetrics.formattedTime(totalTime))
            statCard(label: "Avg WPM", value: "\(Int(avgWPM))")
            statCard(label: "Best WPM", value: "\(Int(bestWPM))")
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct Diamond: ChartSymbolShape {
    nonisolated var perceptualUnitRect: CGRect { CGRect(x: 0, y: 0, width: 1, height: 1) }
    nonisolated func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
        }
    }
}
```

**Step 2: Write KeyHeatmapView**

`KeyHeatmapView.swift`:
```swift
import SwiftUI

struct KeyHeatmapView: View {
    let proficiencies: [KeyProficiencyRecord]

    var body: some View {
        VStack(spacing: 2) {
            // Show just the letter rows (rows 1-3 of layout)
            ForEach(1...3, id: \.self) { rowIndex in
                let row = LayoutDefinition.qwertyUS[rowIndex]
                HStack(spacing: 2) {
                    ForEach(Array(row.keys.enumerated()), id: \.offset) { _, key in
                        if key.label.count == 1 {
                            heatmapKey(key)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func heatmapKey(_ key: KeyDefinition) -> some View {
        let char = key.label.lowercased()
        let record = proficiencies.first { $0.character == char }
        let confidence = record?.confidence ?? 0

        return VStack(spacing: 2) {
            Text(key.label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
            if let record = record, record.totalAttempts > 0 {
                Text("\(Int(record.confidence * 100))%")
                    .font(.system(size: 7))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(width: 36, height: 36)
        .background(confidenceColor(confidence))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence < 0.33 {
            return Color.red.opacity(0.3 + confidence * 0.5)
        } else if confidence < 0.66 {
            return Color.yellow.opacity(0.3 + confidence * 0.3)
        } else {
            return Color.green.opacity(0.3 + confidence * 0.3)
        }
    }
}
```

**Step 3: Commit**
```bash
git add bkey/Views/ProgressDashboardView.swift bkey/Views/KeyHeatmapView.swift
git commit -m "feat: add progress dashboard with WPM chart and key proficiency heatmap"
```

---

## Task 17: Wire Up Lesson Mode & Progress in ContentView

**Files:**
- Modify: `bkey/ContentView.swift`
- Modify: `bkey/App/AppState.swift`

**Step 1: Update ContentView to support lesson mode and add navigation**

Add a mode switcher (tabs or sidebar) at the top for: Free Run, Lessons, Progress. Update the session summary to show lesson results when in lesson mode. Wire up the lesson picker and progress dashboard as sheets/tabs.

Key changes to `ContentView.swift`:
- Add a `@State var selectedTab` for Free Run / Lessons / Progress
- Show `LessonPickerView` when Lessons tab is selected
- Show `ProgressDashboardView` when Progress tab is selected
- Show `LessonResultView` instead of `SessionSummaryView` when in lesson mode
- After session completes, call `PersistenceManager.saveSession()` and update proficiency records

**Step 2: Update AppState**

Add methods:
- `startLesson(id:)` — loads the lesson, generates appropriate words, starts session
- `handleSessionComplete()` — saves to persistence, shows appropriate summary

**Step 3: Build, test, commit**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey build
xcodebuild -project bkey.xcodeproj -scheme bkey test
git add bkey/ContentView.swift bkey/App/AppState.swift
git commit -m "feat: wire up lesson mode, progress dashboard, and persistence in main view"
```

---

## Task 18: Final Integration, Polish & Tests

**Step 1: Run full build**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey build
```
Fix any compilation errors.

**Step 2: Run all tests**
```bash
xcodebuild -project bkey.xcodeproj -scheme bkey test
```
Fix any test failures.

**Step 3: Manual review checklist**
- [ ] App launches, shows dark theme with stats bar + text + keyboard
- [ ] Typing works: characters light up, caret moves
- [ ] Wrong key shows red, correct shows white
- [ ] Keyboard highlights next expected key
- [ ] Stats update during typing
- [ ] Esc ends session, shows summary
- [ ] "Try Again" starts new session
- [ ] Settings gear opens settings sheet
- [ ] Lesson picker shows all 45 lessons
- [ ] Progress dashboard shows charts (after at least one session)

**Step 4: Final commit**
```bash
git add -A
git commit -m "feat: complete TouchType Phase 1 + Phase 2 implementation"
```

---

## Summary

| Task | Description | Files | Estimated Steps |
|------|-------------|-------|-----------------|
| 1 | Word list resource | 1 new | 2 |
| 2 | Finger zones, key mapping, layout | 3 new + 1 test | 6 |
| 3 | Word generator | 1 new + 1 test | 3 |
| 4 | Typing session model + metrics | 2 new + 1 test | 3 |
| 5 | App state + key event handler | 2 new | 3 |
| 6 | Stats bar view | 1 new | 2 |
| 7 | Text display view | 1 new | 2 |
| 8 | Keyboard view | 2 new | 3 |
| 9 | Session summary view | 1 new | 2 |
| 10 | Settings view | 1 new | 2 |
| 11 | Main view assembly | 2 modify | 5 |
| 12 | SwiftData persistence | 5 new + 1 modify | 4 |
| 13 | Key proficiency + adaptive engine | 1 new + 1 test | 3 |
| 14 | Lesson system | 2 new + 1 test | 4 |
| 15 | Lesson picker + lesson view | 2 new | 3 |
| 16 | Progress dashboard + heatmap | 2 new | 3 |
| 17 | Wire up lesson mode in main view | 2 modify | 3 |
| 18 | Final integration + polish | all | 4 |

**Total: ~30 new files, ~57 steps**
