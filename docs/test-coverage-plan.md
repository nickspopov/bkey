# Test Coverage Plan — bkey

## Goal
Achieve comprehensive test coverage across the entire bkey codebase with new unit tests (Swift Testing framework) and UI end-to-end tests (XCTest).

## Current State
- **32 existing unit tests** across 6 files, all passing
- **2 UI test files** with scaffold/placeholder tests only (no real assertions)
- Covered: `KeyMapping`, `WordGenerator`, `TypingSession`, `SessionMetrics`, `KeyProficiency`, `Lesson/LessonCurriculum`
- Not covered: `AppState`, `FingerZone`, `LayoutDefinition` (beyond row count), `KeyProficiencyRecord`, `PersistenceManager`, `Array[safe:]`, all UI flows

## Coverage Gap Analysis

### Unit Tests — What's Missing

| Source File | Existing Tests | Gaps |
|---|---|---|
| **AppState** | 0 | `startFreeRun`, `startLesson`, `startNextLesson`, `handleCharacter`, `handleBackspace`, `handleEscape`, `updateActiveKeyCode`, `handleSessionComplete`, `wordsForLesson`, `currentLesson` computed property, mode/tab transitions |
| **LayoutDefinition** | 1 (row count) | Key counts per row, total key count, specific keyCode values, unique keyCodes, width values, finger zone assignments for non-letter keys |
| **KeyMapping** | 5 | Punctuation keys (`,.;'[]` etc), number keys, `fingerZone` for unmapped characters (returns nil), `keyCode` for uppercase |
| **TypingSession** | 7 | `restart()`, `endSession()` from non-active states, `processCharacter` when `state == .paused` or `state == .complete` (no-op), `processBackspace` when not active, `currentCharacter` at end of text, `currentWordIndex` mid-word, `timestampedKeystrokes` population, word boundaries for multi-word text |
| **SessionMetrics** | 5 | `grossWPM` with zero seconds, `netWPM` floors at zero (heavy errors), `bestWPM` with empty/single keystroke arrays, `bestWPM` with actual windows, `formattedTime` edge cases |
| **WordGenerator** | 4 | Default `init()` (uses bundle/fallback), `generateBatch(count: 0)` |
| **Lesson** | 5 | Star rating boundary: exactly gate+10 WPM with <95% accuracy (should be 2 via WPM path), exactly 95% accuracy with <gate+10 WPM (should be 2 via accuracy path), gate+20 WPM with 97% accuracy (should be 2, not 3) |
| **LessonCurriculum** | 0 (covered in LessonTests) | `lesson(byId:)` with invalid ID returns nil, tier distribution (8+10+10+6+11 = 45), gate WPM progression per tier |
| **KeyProficiency** | 5 | `ProficiencyData.averageSpeed` with empty speeds (returns 500), `ProficiencyData.accuracy` with zero attempts (returns 0), rolling window capping at 20 speeds, `weakestCharacters` with `allowedChars` filter, `AdaptiveWordSelector` with empty `weakChars`, consecutive duplicate removal in adaptive selector |
| **KeyProficiencyRecord** | 0 | `recentSpeeds` get/set via JSON encoding, `addTransitionTime` rolling window, `recordAttempt`, `recalculateConfidence` speed/accuracy factor formula |
| **FingerZone** | 0 | All 9 cases have unique labels (L4/L3/L2/L1/R1/R2/R3/R4/Th), all 9 have non-nil colors, `CaseIterable` has 9 cases |
| **Array[safe:]** | 0 | In-bounds returns element, out-of-bounds returns nil, negative index returns nil |

### UI E2E Tests — What's Missing

| Flow | Current Coverage | Needed |
|---|---|---|
| **App Launch** | Launch screenshot only | Verify window appears, tabs visible, keyboard visible, text display present |
| **Free Run Flow** | None | Type text -> stats update -> complete session -> summary overlay appears -> "Try Again" restarts |
| **Tab Navigation** | None | Click each tab -> correct view appears, switching tabs preserves/resets state |
| **Lesson Flow** | None | Navigate to Lessons tab -> select available lesson -> type to complete -> lesson result shows stars -> "Next Lesson" / "Retry" work |
| **Settings** | None | Open settings sheet -> toggle keyboard visibility -> verify keyboard hides, change font size, change caret style |
| **Progress Dashboard** | None | Navigate to Progress tab -> verify stats grid visible, chart visible if sessions exist |
| **Keyboard Interaction** | None | Type a key -> correct key highlights, type wrong key -> error indication |
| **Escape to End Session** | None | Start typing -> press Escape -> session summary appears |

---

## Implementation Plan

### Step 1: New Unit Tests — AppState (file: `bkeyTests/AppStateTests.swift`)
~12 tests covering the core orchestration logic:

1. `startFreeRunSetsCorrectState` — mode=.freeRun, selectedTab=.freeRun, session ready, showSessionSummary=false
2. `startFreeRunGeneratesTargetText` — session.targetText is non-empty after startFreeRun
3. `startLessonSetsLessonMode` — mode=.lesson(id), session has target text
4. `startLessonWithInvalidIdDoesNothing` — startLesson(id: 999) doesn't change state
5. `startNextLessonAdvancesId` — from lesson 1, startNextLesson sets mode to lesson 2
6. `startNextLessonInFreeRunDoesNothing` — no-op when mode is .freeRun
7. `handleCharacterUpdatesKeyState` — lastPressedKeyCode, lastPressCorrect set correctly
8. `handleCharacterCompletesSession` — type all chars -> showSessionSummary=true
9. `handleBackspaceDelegatesToSession` — currentIndex decrements
10. `handleEscapeEndsActiveSession` — session goes complete, summary shown
11. `handleEscapeDoesNothingWhenNotActive` — no-op in ready state
12. `updateActiveKeyCodeSetsCorrectKey` — maps current character to keyCode
13. `currentLessonReturnsCorrectLesson` — in lesson mode, returns the lesson; in freeRun, nil
14. `wordsForLessonFiltersToAllowedKeys` — lesson 1 (f,j only) generates words with only f/j chars

### Step 2: New Unit Tests — LayoutDefinition & FingerZone (file: `bkeyTests/LayoutDefinitionTests.swift`)
~8 tests:

1. `allKeysHaveUniqueKeyCodes` — no duplicate keyCodes across all rows
2. `totalKeyCountMatchesExpected` — sum of all keys across 5 rows
3. `eachRowHasCorrectKeyCount` — number row=14, QWERTY=14, home=13, bottom=12, modifier=10
4. `spaceBarHasCorrectWidth` — keyCode 49 has width 6.0
5. `fingerZoneHasNineCases` — FingerZone.allCases.count == 9
6. `fingerZoneLabelsAreUnique` — all 9 labels are distinct
7. `fingerZoneLabelsMatchExpected` — L4, L3, L2, L1, R1, R2, R3, R4, Th
8. `allKeysHaveFingerZoneAssigned` — every KeyDefinition has a valid FingerZone

### Step 3: Expanded Unit Tests — TypingSession Edge Cases (add to `bkeyTests/TypingSessionTests.swift`)
~8 new tests:

1. `restartResetsSession` — restart() puts session back to .ready with same word generator
2. `processCharacterIgnoredWhenPaused` — no state change when paused
3. `processCharacterIgnoredWhenComplete` — no state change when complete
4. `processBackspaceIgnoredWhenNotActive` — no-op in .ready state
5. `processBackspaceIgnoredAtStartOfText` — can't go below index 0
6. `currentCharacterReturnsNilAtEnd` — after typing all text
7. `currentWordIndexTracksProgress` — verify index changes as you cross word boundaries
8. `timestampedKeystrokesRecorded` — each processCharacter adds an entry

### Step 4: Expanded Unit Tests — SessionMetrics Edge Cases (add to `bkeyTests/TypingSessionTests.swift`)
~5 new tests:

1. `grossWPMZeroSecondsReturnsZero` — guard clause
2. `netWPMFloorsAtZero` — more errors than correct chars
3. `netWPMZeroSecondsReturnsZero` — guard clause
4. `bestWPMEmptyArrayReturnsZero` — no keystrokes
5. `bestWPMSingleKeystrokeReturnsZero` — need >1

### Step 5: Expanded Unit Tests — KeyMapping (add to `bkeyTests/KeyMappingTests.swift`)
~4 new tests:

1. `fingerZoneForPunctuation` — comma, period, slash, semicolon
2. `fingerZoneForNumbers` — 1-0 mapped correctly
3. `fingerZoneForUnknownCharReturnsNil` — emoji or unicode char
4. `keyCodeForUppercaseReturnsNil` — characterToKeyCode only has lowercase

### Step 6: Expanded Unit Tests — KeyProficiency Edge Cases (add to `bkeyTests/KeyProficiencyTests.swift`)
~6 new tests:

1. `averageSpeedDefaultsTo500WhenEmpty` — ProficiencyData with no speeds
2. `accuracyIsZeroWithNoAttempts` — ProficiencyData default
3. `recentSpeedsCappedAt20` — add 25 entries, verify count is 20
4. `weakestCharactersWithFilterReturnsOnlyAllowed` — filters by allowedChars set
5. `adaptiveWordSelectorEmptyWeakCharsStillWorks` — returns count words
6. `adaptiveWordSelectorRemovesConsecutiveDuplicates` — verify no back-to-back same words

### Step 7: New Unit Tests — KeyProficiencyRecord (file: `bkeyTests/KeyProficiencyRecordTests.swift`)
~6 tests:

1. `recentSpeedsGetSetRoundTrips` — set speeds, read back same values
2. `addTransitionTimeAppends` — adds to recentSpeeds, updates averageSpeedMs
3. `addTransitionTimeCapsAt20` — add 25, verify 20 stored
4. `recordAttemptIncrementsCorrectly` — totalAttempts, correctAttempts
5. `confidenceHighForFastAccurate` — speed<=170, 100% accuracy -> confidence ~1.0
6. `confidenceLowForSlowInaccurate` — speed>=500, 0% accuracy -> confidence 0.0

### Step 8: New Unit Tests — LessonCurriculum extras (add to `bkeyTests/LessonTests.swift`)
~4 new tests:

1. `lessonByIdInvalidReturnsNil` — LessonCurriculum.lesson(byId: 999) == nil
2. `lessonByIdZeroReturnsNil` — LessonCurriculum.lesson(byId: 0) == nil
3. `tierDistribution` — tiers 1-5 have 8, 10, 10, 6, 11 lessons respectively
4. `gateWPMNeverDecreases` — within each tier, gateWPM is non-decreasing (curriculum makes sense)

### Step 9: New Unit Tests — Array Safe Subscript (file: `bkeyTests/ArrayExtensionTests.swift`)
~3 tests:

1. `safeSubscriptInBoundsReturnsElement` — [1,2,3][safe: 1] == 2
2. `safeSubscriptOutOfBoundsReturnsNil` — [1,2,3][safe: 5] == nil
3. `safeSubscriptNegativeIndexReturnsNil` — [1,2,3][safe: -1] == nil

### Step 10: UI E2E Tests (file: `bkeyUITests/bkeyUITests.swift`)
Replace the scaffold tests with real E2E flows. UI tests use XCTest since Swift Testing doesn't support UI testing yet.

~8 tests:

1. `testAppLaunchShowsMainUI` — verify window exists, "Free Run" tab visible, keyboard area visible
2. `testTabNavigation` — click "Lessons" tab -> lessons content visible, click "Progress" -> progress visible, click "Free Run" -> typing view returns
3. `testTypingUpdatesDisplay` — type keys via `typeKey()` -> verify stats bar shows updated WPM/accuracy
4. `testSettingsSheetOpensAndCloses` — click gear icon -> settings sheet appears with "Show Keyboard" toggle -> close returns to main
5. `testSettingsToggleKeyboard` — open settings -> toggle "Show Keyboard" off -> keyboard area hides
6. `testLessonSelection` — navigate to Lessons -> tap first lesson ("F and J") -> returns to typing view in lesson mode
7. `testEscapeEndsFreeRunSession` — type a few characters -> press Escape -> session summary overlay appears with "Try Again" and "Close"
8. `testTryAgainRestartsSession` — complete or escape session -> click "Try Again" -> new session begins

---

## File Change Summary

| File | Action | Approx Test Count |
|---|---|---|
| `bkeyTests/AppStateTests.swift` | **Create** | 14 |
| `bkeyTests/LayoutDefinitionTests.swift` | **Create** | 8 |
| `bkeyTests/TypingSessionTests.swift` | **Edit** (add tests) | +8 session, +5 metrics = 13 |
| `bkeyTests/KeyMappingTests.swift` | **Edit** (add tests) | +4 |
| `bkeyTests/KeyProficiencyTests.swift` | **Edit** (add tests) | +6 |
| `bkeyTests/KeyProficiencyRecordTests.swift` | **Create** | 6 |
| `bkeyTests/LessonTests.swift` | **Edit** (add tests) | +4 |
| `bkeyTests/ArrayExtensionTests.swift` | **Create** | 3 |
| `bkeyUITests/bkeyUITests.swift` | **Rewrite** | 8 |

**Total new tests: ~66** (bringing total from 32 to ~98)

## Build & Verify After Each Step
```bash
# Unit tests
xcodebuild -project bkey.xcodeproj -scheme bkey test -only-testing:bkeyTests
# UI tests (after Step 10)
xcodebuild -project bkey.xcodeproj -scheme bkey -only-testing:bkeyUITests test
```

## Constraints & Notes
- Unit tests use `import Testing` + `@Test` macro (Swift Testing framework)
- UI tests use `XCTest` (`XCTestCase` subclasses) — Swift Testing doesn't support UI testing
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all test structs are implicitly @MainActor; use `nonisolated` where needed
- `AppState.handleSessionComplete` calls `PersistenceManager.saveSession` which uses `ModelContainer.mainContext` — AppState tests that trigger completion need an in-memory SwiftData container or must test around persistence (verify state changes, not DB writes)
- `KeyProficiencyRecord` tests need an in-memory `ModelContainer` since it's a `@Model` class
- `WordGenerator` default init loads from Bundle which may not be available in test target — use the `init(words:)` test constructor
- For UI tests, keys can be typed with `app.typeKey(...)` or `app.typeText(...)` — but `typeKey` simulates keyDown events more reliably for this app's NSEvent monitor
