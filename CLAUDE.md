# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

bkey is a macOS touch typing tutor built with Swift and SwiftUI. It targets macOS 26.0 and uses Xcode 26.0 as its build system. Zero third-party dependencies.

## Build & Test Commands

```bash
# Build
xcodebuild -project bkey.xcodeproj -scheme bkey build

# Run all tests (unit + UI)
xcodebuild -project bkey.xcodeproj -scheme bkey test

# Unit tests only (faster)
xcodebuild -project bkey.xcodeproj -scheme bkey test -only-testing:bkeyTests

# UI tests only
xcodebuild -project bkey.xcodeproj -scheme bkey -only-testing:bkeyUITests test
```

## Key Build Settings

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types are implicitly `@MainActor`. Use `nonisolated` where needed.
- `SWIFT_APPROACHABLE_CONCURRENCY` enabled
- Unit tests use Swift Testing framework (`import Testing`, `@Test` macros), not XCTest
- UI tests use XCTest (`XCTestCase` subclasses)
- Uses `PBXFileSystemSynchronizedRootGroup` — new files added to `bkey/` are auto-included in the build, no `.pbxproj` edits needed

## Architecture

### Data Flow

`bkeyApp` → `ContentView` → `AppState` (central `@Observable` controller)

`AppState` owns all application state and orchestrates between modes:
- **Free Run mode**: generates adaptive word lists via `WordGenerator` + `AdaptiveWordSelector`, creates a `TypingSession`
- **Lesson mode**: `LessonCurriculum` → `Lesson` → `LessonFlowState` → multi-exercise flow (intro → drill → practice → speed challenge)

Keyboard input flows through `KeyEventHandler` (NSEvent local monitor) → `AppState.handleCharacter/handleBackspace/handleEscape` → `TypingSession` state mutations.

### Key Components

- **`TypingSession`** (`@Observable`): Core typing engine. Tracks character states (pending/correct/incorrect/corrected), word boundaries, keystroke timestamps for WPM calculation. Supports three error modes: `continueOnError`, `forceCorrect`, `stopOnWord`.
- **`LessonFlowState`** (`@Observable`): Manages multi-exercise lesson progression. Each lesson generates 3-5 exercises via `ExerciseGenerator` (introduction → letterDrill → wordPractice → sentencePractice → speedChallenge).
- **`LessonCurriculum`**: Static definition of 45 lessons across 5 tiers (Home Row → Top Row → Bottom Row → Shift/Capitals → Punctuation/Numbers). Lessons gate on WPM and accuracy thresholds.
- **`KeyProficiencyTracker`**: Per-character proficiency tracking with confidence scores based on speed and accuracy. Feeds into `AdaptiveWordSelector` for weakness-targeted practice.
- **`PersistenceManager`**: SwiftData `ModelContainer` with four `@Model` types: `UserProfile`, `SessionRecord`, `LessonRecord`, `KeyProficiencyRecord`. Settings use `UserDefaults`.
- **`LayoutDefinition`**: QWERTY US keyboard layout with `KeyDefinition` structs mapping keyCodes to finger zones. `KeyMapping` provides character↔keyCode↔fingerZone lookups.

### Testing Patterns

Tests instantiate models directly with controlled inputs:
```swift
let session = TypingSession(wordGenerator: WordGenerator(words: ["hello", "world"]))
session.start()
session.processCharacter("h")
#expect(session.state == .active)
```

`WordGenerator(words:)` initializer allows deterministic word lists for testing. No mocking frameworks needed.
