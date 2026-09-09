# bkey — Touch Typing Tutor for macOS
## Technical Documentation & Product Requirements

**Version:** 1.0 Draft  
**Date:** February 6, 2026  
**Platform:** macOS (Swift / SwiftUI)  
**Minimum OS:** macOS 14.0 (Sonoma)  

---

## 1. Product Vision

bkey is a native macOS touch typing tutor that teaches and reinforces proper finger placement through adaptive practice sessions, finger-zone color-coded keyboard visualization, and real-time performance metrics. The app combines the modern "MonkeyType-style" text display with a structured learning progression, wrapped in a polished dark-themed macOS interface.

### 1.1 Design Reference

The visual design follows a dark-theme aesthetic (see reference screenshot) with three primary zones stacked vertically:

1. **Stats Bar** (top) — WPM, Accuracy %, and Typo count displayed with iconography
2. **Text Display Area** (middle) — single-line scrolling text with a blinking caret, typed characters in light color, untyped characters in subdued gray
3. **On-Screen Keyboard** (bottom 40%) — full keyboard visualization with finger-zone color mapping using a cool-toned gradient (teals, blues, purples) and semi-transparent hand overlay guides

The window includes a settings gear icon (top-right) and standard macOS traffic-light controls.

---

## 2. Phased Delivery Plan

### Phase 1 — MVP (Free-Run Mode Only)
Core typing experience with no structured lessons.

### Phase 2 — Structured Lessons & Adaptive Engine
Progressive lesson system with per-key proficiency tracking.

### Phase 3 — Multi-Layout, Multi-Language & Advanced Modes
Additional keyboard layouts, languages, and practice modes.

### Phase 4 — Gamification & Social
Streaks, achievements, leaderboards, and engagement loops.

---

## 3. Phase 1 — MVP

### 3.1 Overview

The MVP delivers a single "Free Run" mode: the user opens the app, sees random common English words, and types. The app tracks WPM, accuracy, and typos in real time, highlights the correct finger for each key on the on-screen keyboard, and shows a session summary at the end. No accounts, no lessons, no progression — just a clean, satisfying typing experience.

### 3.2 Feature Specification

#### 3.2.1 Application Shell

| Requirement | Detail |
|---|---|
| Window | Single resizable window, minimum 900×600, default 1100×700 |
| Theme | Dark theme only (MVP). Background: near-black (#0D1117 or similar) |
| Menu Bar | Standard macOS menus: bkey, File, Edit, Window, Help |
| Settings | Gear icon opens a settings panel (sheet or popover) |
| App Lifecycle | Remember window position/size via `@AppStorage`. Resume last state on relaunch |

#### 3.2.2 Free-Run Mode — Text Engine

**Word Source:**
- Embedded word list of the 1,000 most common English words (curated from frequency corpora)
- Words randomized per session with no immediate repeats
- Session produces a continuous stream of words separated by spaces
- No punctuation, no capitals, no numbers in MVP

**Text Display:**
- Monospace font: SF Mono or Menlo, 22px, line-height 1.6
- Single visible line of text that scrolls horizontally or wraps to 2 lines max
- Smooth animated caret (blinking vertical bar) positioned before the next expected character
- Character states:
  - **Pending:** subdued gray (#4A5568)
  - **Correct:** light white (#E2E8F0)
  - **Incorrect:** red (#F56565), character remains visible
  - **Current:** caret positioned immediately before this character
- When the user completes a word (types space after the last letter), the view advances so the current word is always visible with lookahead

**Caret Animation:**
- Vertical bar, 2px wide, primary accent color (#63B3ED or similar teal)
- Smooth horizontal translation using `withAnimation(.easeOut(duration: 0.08))` on position changes
- Blinking animation when idle (1s interval), stops blinking while actively typing

#### 3.2.3 Free-Run Mode — Input Handling

**Key Event Capture:**
- Use `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` for key capture
- Capture `event.characters` (layout-sensitive character) for input matching
- Capture `event.keyCode` for physical key identification (finger tracking / keyboard highlighting)
- Filter out modifier-only events (Cmd, Ctrl, Option alone)
- Filter `event.isARepeat` — ignore auto-repeat keystrokes
- Suppress system beep by returning `nil` from the monitor when handling a key

**Character Matching Logic:**
```
on keyDown(character):
    if character == expected[currentIndex]:
        mark currentIndex as CORRECT
        advance currentIndex
    else if character == BACKSPACE:
        if currentIndex > wordStartIndex:  // can't backspace past word boundary
            retreat currentIndex
            mark currentIndex as PENDING (reset)
    else:
        mark currentIndex as INCORRECT
        increment errorCount
        advance currentIndex  // MVP: continue on error (no forced correction)
    
    if character == SPACE and currentIndex == nextWordStart:
        advance to next word
```

**Session Lifecycle:**
1. **Ready state:** text is displayed, caret blinks, timer not started
2. **Active state:** first keystroke starts the timer. Stats update live
3. **Complete state:** triggered by either (a) typing all generated words (generate 50 words per batch, generate more as user approaches the end) or (b) user presses `Esc` or `Cmd+Enter` to end early
4. On completion, show session summary overlay

#### 3.2.4 Free-Run Mode — Metrics

**Real-Time Display (during typing):**

| Metric | Calculation | Display |
|---|---|---|
| WPM | `(correctCharacters / 5) / elapsedMinutes` | Integer, updates every 500ms |
| Accuracy | `correctCharacters / totalKeystrokes × 100` | Percentage with `%` suffix |
| Typos | Count of incorrect keystrokes | Integer |

- Stats bar is positioned at the top of the typing area
- Each metric has an SF Symbol icon to its left (see design reference):
  - WPM: `text.word.spacing` or custom
  - Accuracy: `target` or `scope`
  - Typos: `exclamationmark.circle`
- Use `performance.now()`-equivalent (`CFAbsoluteTimeGetCurrent()` or `ContinuousClock`) for timing
- WPM uses **gross WPM** formula in MVP (no net WPM penalty yet)

**Session Summary (end of session):**

| Field | Value |
|---|---|
| Final WPM | Gross WPM for the session |
| Accuracy | Overall accuracy % |
| Total Typos | Error count |
| Characters Typed | Total keystrokes |
| Time Elapsed | Duration in `m:ss` |
| Best WPM | Peak 10-second rolling window WPM |

Displayed as a centered overlay card with a "Try Again" button and a "Close" (×) button.

#### 3.2.5 On-Screen Keyboard

**Layout:**
- Visual representation of a standard US QWERTY keyboard (ANSI layout)
- 5 rows: number row, QWERTY row, home row (ASDF), bottom row (ZXCV), modifier/space row
- Key sizing proportional to real keyboard (space bar = 6× width of letter key, shift = 2.5×, etc.)
- Keys rendered as rounded rectangles with subtle border and inner shadow
- Key labels in SF Mono or system font, white/light gray, centered

**Finger-Zone Color Mapping (8-zone scheme):**

| Finger | Keys (QWERTY) | Color | Hex |
|---|---|---|---|
| Left Pinky | \`, 1, Q, A, Z, Tab, CapsLock, LShift | Rose/Pink | #F687B3 |
| Left Ring | 2, W, S, X | Orange | #ED8936 |
| Left Middle | 3, E, D, C | Yellow | #ECC94B |
| Left Index | 4, 5, R, T, F, G, V, B | Green | #68D391 |
| Right Index | 6, 7, Y, U, H, J, N, M | Teal | #4FD1C5 |
| Right Middle | 8, I, K, , (comma) | Blue | #63B3ED |
| Right Ring | 9, O, L, . (period) | Indigo | #7F9CF5 |
| Right Pinky | 0, -, =, P, [, ], \, ;, ', /, RShift, Enter, Backspace | Purple | #B794F4 |
| Thumbs | Space | Neutral Gray | #718096 |

- Colors are applied as a semi-transparent background fill (opacity ~0.3 in idle state)
- The **target key** (next expected character) is highlighted with full opacity of its zone color plus a subtle glow/pulse animation
- The **finger indicator** for the target key: the corresponding finger zone brightens slightly to indicate which hand and finger to use

**Key State Rendering:**

| State | Visual |
|---|---|
| Idle | Zone color at 20% opacity, light key label |
| Target (next to type) | Zone color at 80% opacity, subtle scale-up (1.05×), glow shadow |
| Just Pressed — Correct | Brief flash to white/green (150ms), then return to idle |
| Just Pressed — Incorrect | Brief flash to red (200ms), then return to idle |

**Accessibility (MVP baseline):**
- Each zone color has a distinct luminance value (validate with contrast checker)
- Zone colors chosen to remain distinguishable under protanopia and deuteranopia simulation
- Optional: finger labels (L4, L3, L2, L1, R1, R2, R3, R4) on keys, toggleable in settings

#### 3.2.6 Settings (MVP)

| Setting | Type | Default | Options |
|---|---|---|---|
| Show Keyboard | Toggle | On | On / Off |
| Show Finger Labels | Toggle | Off | On / Off |
| Font Size | Stepper | 22 | 16–32 in steps of 2 |
| Sound on Keystroke | Toggle | Off | On / Off |
| Sound on Error | Toggle | On | On / Off |

Settings stored in `UserDefaults` via `@AppStorage`.

#### 3.2.7 Audio Feedback (MVP)

- **Error sound:** short, low-pitched click/thud (bundled .caf file, ~50ms)
- **Keystroke sound (optional):** soft mechanical key click (bundled .caf file, ~30ms)
- Play via `NSSound` or `AVAudioPlayer` with pre-loaded buffers for zero latency
- Respect system "Play user interface sound effects" setting

### 3.3 Technical Architecture — MVP

#### 3.3.1 Project Structure

```
bkey/
├── App/
│   ├── bkeyApp.swift              // @main, WindowGroup
│   └── AppState.swift                  // Global app state (ObservableObject)
├── Models/
│   ├── TypingSession.swift             // Session state machine
│   ├── WordGenerator.swift             // Random word selection
│   ├── KeyMapping.swift                // Physical key → finger zone mapping
│   ├── LayoutDefinition.swift          // QWERTY layout data
│   └── SessionMetrics.swift            // WPM/accuracy calculation
├── Views/
│   ├── MainView.swift                  // Root view: stats + text + keyboard
│   ├── TextDisplayView.swift           // Typing area with caret
│   ├── KeyboardView.swift              // On-screen keyboard
│   ├── KeyView.swift                   // Individual key rendering
│   ├── StatsBarView.swift              // WPM, accuracy, typos display
│   ├── SessionSummaryView.swift        // End-of-session overlay
│   └── SettingsView.swift              // Settings panel
├── Services/
│   ├── KeyEventHandler.swift           // NSEvent monitor, key dispatch
│   ├── AudioManager.swift              // Sound playback
│   └── TimerService.swift              // Precision timing
├── Resources/
│   ├── Words/
│   │   └── en_common_1000.json         // Word list
│   ├── Sounds/
│   │   ├── keystroke.caf
│   │   └── error.caf
│   └── Assets.xcassets                 // Colors, images
└── Extensions/
    └── Color+FingerZones.swift         // Finger zone color definitions
```

#### 3.3.2 Core Data Models

**TypingSession (state machine):**

```swift
@Observable
class TypingSession {
    enum State { case ready, active, paused, complete }
    
    var state: State = .ready
    var words: [String] = []
    var characters: [CharacterState] = []  // flat array of all chars including spaces
    var currentIndex: Int = 0
    var startTime: ContinuousClock.Instant?
    var keystrokes: Int = 0
    var errors: Int = 0
    var correctChars: Int = 0
    
    // Rolling WPM window (last 10 seconds)
    var recentTimestamps: [(time: ContinuousClock.Instant, correct: Bool)] = []
}

enum CharacterState {
    case pending
    case correct
    case incorrect
    case corrected  // was incorrect, then backspaced and retyped
}
```

**KeyMapping:**

```swift
struct KeyMapping {
    /// Maps physical key code (UInt16) to FingerZone
    static let keyCodeToFinger: [UInt16: FingerZone] = [
        0: .leftRing,    // A → actually Left Pinky for A
        // ... complete mapping
    ]
    
    /// Maps physical key code to display label
    static let keyCodeToLabel: [UInt16: String] = [:]
    
    /// Maps physical key code to keyboard row and position (for rendering)
    static let keyCodeToPosition: [UInt16: KeyPosition] = [:]
}

enum FingerZone: String, CaseIterable {
    case leftPinky, leftRing, leftMiddle, leftIndex
    case rightIndex, rightMiddle, rightRing, rightPinky
    case thumb
    
    var color: Color { /* return zone color */ }
    var label: String { /* L4, L3, L2, L1, R1, R2, R3, R4, Th */ }
}
```

#### 3.3.3 Key Event Pipeline

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  NSEvent     │ ──► │ KeyEvent     │ ──► │ TypingSession│
│  Monitor     │     │ Handler      │     │ .processKey()│
│ (keyDown)    │     │ (filter,     │     │              │
│              │     │  decode)     │     │              │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                          ┌───────────────────────┼──────────────┐
                          ▼                       ▼              ▼
                    ┌──────────┐          ┌──────────┐   ┌──────────┐
                    │TextDisplay│         │ Keyboard │   │ StatsBar │
                    │View      │         │ View     │   │ View     │
                    │(update   │         │(highlight│   │(update   │
                    │ chars)   │         │ target)  │   │ metrics) │
                    └──────────┘         └──────────┘   └──────────┘
```

**KeyEventHandler implementation notes:**
- Register monitor in `onAppear`, remove in `onDisappear`
- Return `nil` from monitor to suppress system beep
- Map `event.keyCode` (UInt16) to `FingerZone` for keyboard highlighting
- Map `event.characters` to the actual typed character for input matching
- Handle backspace via `event.keyCode == 51`
- Handle escape via `event.keyCode == 53` (end session)
- Ignore all events where `event.modifierFlags` contains `.command` or `.control`

#### 3.3.4 Rendering Performance

- **TextDisplayView:** use `Canvas` or `Text` with `AttributedString` for character coloring. Avoid creating one `Text` view per character (performance degrades past 200 characters). Preferred: single `AttributedString` rebuilt on each keystroke, SwiftUI diffing handles efficient updates
- **KeyboardView:** static layout computed once; only key state (idle/target/pressed) changes. Use `@State` per-key or a dictionary of key states
- **Caret animation:** `withAnimation(.easeOut(duration: 0.08))` on the x-offset of the caret. Calculate position from character index × character width (monospace guarantees uniform width)
- **Stats updates:** throttle to 500ms via `Timer.publish` or `.task` with `try await Task.sleep`

#### 3.3.5 Build & Distribution

| Item | Value |
|---|---|
| Xcode | 16.0+ |
| Swift | 6.0 |
| Min deployment | macOS 14.0 (Sonoma) |
| UI Framework | SwiftUI (AppKit interop for NSEvent) |
| Architecture | Universal (Apple Silicon + Intel) |
| Sandbox | Yes (App Store distribution) |
| Signing | Developer ID + Notarization |
| Dependencies | None (zero third-party deps in MVP) |

---

## 4. Phase 2 — Structured Lessons & Adaptive Engine

### 4.1 Overview

Phase 2 transforms the free-run tool into a learning application. It adds a progressive lesson curriculum, per-key proficiency tracking, an adaptive text generation engine, and persistent progress data.

### 4.2 Lesson System

#### 4.2.1 Curriculum Structure

**Tier 1 — Home Row (Lessons 1–8)**

| Lesson | New Keys | Practice Set |
|---|---|---|
| 1 | F, J | f, j (index fingers home position) |
| 2 | D, K | f, j, d, k |
| 3 | S, L | f, j, d, k, s, l |
| 4 | A, ; | Full home row: a, s, d, f, j, k, l, ; |
| 5 | G, H | Home row + index reach: g, h |
| 6 | Space | Home row words with spaces |
| 7 | Home row review | Common words using only home row letters |
| 8 | Home row speed | Timed home row drill (gate: 15 WPM, 90% accuracy) |

**Tier 2 — Top Row (Lessons 9–18)**

| Lesson | New Keys | Cumulative Set |
|---|---|---|
| 9 | E, I | Home row + e, i |
| 10 | R, U | + r, u |
| 11 | T, Y | + t, y (index finger reach) |
| 12 | W, O | + w, o |
| 13 | Q, P | + q, p |
| 14–15 | Review & words | Common words with home + top row |
| 16–18 | Speed drills | Gate: 20 WPM, 90% accuracy |

**Tier 3 — Bottom Row (Lessons 19–28)**

| Lesson | New Keys |
|---|---|
| 19 | V, M |
| 20 | C, comma |
| 21 | X, period |
| 22 | Z, / |
| 23 | B, N |
| 24–26 | Full alphabet review |
| 27–28 | Speed drills (gate: 25 WPM, 92% accuracy) |

**Tier 4 — Shift & Capitals (Lessons 29–34)**

- Opposite-hand shift technique (left shift for right-hand letters, right shift for left-hand letters)
- Capital letters at sentence starts
- Proper nouns
- Gate: 25 WPM, 92% accuracy

**Tier 5 — Punctuation & Numbers (Lessons 35–45)**

- Common punctuation: period, comma, apostrophe, question mark, exclamation
- Number row: 1–0
- Symbols: @, #, $, etc.
- Gate: 25 WPM, 90% accuracy

#### 4.2.2 Lesson Mechanics

- Each lesson consists of 3–5 exercises of increasing difficulty:
  1. **Introduction:** visual demonstration of new key(s) with finger guide
  2. **Letter drill:** individual characters and simple bigrams
  3. **Word practice:** real words limited to the learned key set
  4. **Sentence practice:** short sentences using learned keys (Tier 2+)
  5. **Speed challenge:** timed exercise serving as the lesson gate
- Lesson completion requires meeting the gate criteria (minimum WPM + minimum accuracy)
- Star rating system: ★ (met gate), ★★ (gate + 10 WPM or 95% accuracy), ★★★ (gate + 20 WPM and 98% accuracy)
- Users can always replay completed lessons
- Free-run mode remains available with the full character set at all times

#### 4.2.3 Lesson UI

- **Lesson Picker:** sidebar or horizontal scrollable list showing all lessons, with completed/locked/current states
- **Lesson View:** same typing interface as free-run, but with:
  - Lesson title and exercise number displayed
  - Progress bar showing position within the exercise
  - Gate criteria shown subtly (e.g., "Target: 20 WPM, 90% accuracy")
  - On completion: star rating animation, "Next Lesson" / "Retry" buttons

### 4.3 Adaptive Engine

#### 4.3.1 Per-Key Proficiency Model

For each character, track:

```swift
struct KeyProficiency {
    let character: Character
    var totalAttempts: Int = 0
    var correctAttempts: Int = 0
    var recentSpeeds: RingBuffer<Double>  // last 20 transition times (ms)
    var averageSpeed: Double  // mean of recentSpeeds
    var accuracy: Double  // correctAttempts / totalAttempts
    var confidence: Double  // 0.0–1.0, computed from speed + accuracy
}
```

**Confidence scoring (adapted from Keybr):**
- Measure "transition time": time from the previous correct keystroke to this keystroke
- Characters with average transition time ≤ 170ms (~35 WPM equivalent) get confidence 1.0
- Characters with average transition time ≥ 500ms (~12 WPM equivalent) get confidence 0.0
- Linear interpolation between those bounds
- Accuracy factor: multiply confidence by `(accuracy ^ 2)` to heavily penalize error-prone keys
- Final: `confidence = speedFactor × (accuracy ^ 2)`

#### 4.3.2 Adaptive Text Generation

When generating practice text (free-run or adaptive mode):

1. Compute confidence for all learned characters
2. Identify the 3–5 lowest-confidence characters
3. Select words from the word database that contain those characters, weighted by:
   - `weight = (1.0 - confidence) ^ 2` for each weak character in the word
   - Words with multiple weak characters get additive weight
4. Mix: 60% weighted-toward-weakness words, 40% random common words (prevents monotony)
5. Never repeat the same word within the last 5 words

#### 4.3.3 Progress Data Persistence

**Storage:** SwiftData (Core Data successor) with the following schema:

```swift
@Model
class UserProfile {
    var createdAt: Date
    var totalPracticeTime: TimeInterval
    var totalWordsTyped: Int
    var currentLesson: Int
    var lessons: [LessonRecord]
    var keyProficiencies: [KeyProficiencyRecord]
    var sessions: [SessionRecord]
}

@Model
class LessonRecord {
    var lessonId: Int
    var bestWPM: Double
    var bestAccuracy: Double
    var stars: Int  // 0–3
    var completedAt: Date?
    var attempts: Int
}

@Model
class SessionRecord {
    var date: Date
    var mode: String  // "freeRun", "lesson", "adaptive"
    var duration: TimeInterval
    var wpm: Double
    var accuracy: Double
    var errors: Int
    var characterCount: Int
}

@Model
class KeyProficiencyRecord {
    var character: String
    var totalAttempts: Int
    var correctAttempts: Int
    var averageSpeedMs: Double
    var confidence: Double
    var lastPracticed: Date
}
```

### 4.4 Enhanced Metrics

#### 4.4.1 Net WPM

Introduced in Phase 2 alongside Gross WPM:

- **Gross WPM** = `(totalCharacters / 5) / minutes`
- **Net WPM** = `grossWPM - (uncorrectedErrors / minutes)`
- Display both in session summary; use Net WPM as the "official" score

#### 4.4.2 WPM-Over-Time Graph

- Line chart showing WPM across sessions (x = session date, y = WPM)
- Rendered with Swift Charts (`Charts` framework)
- Separate lines for Gross and Net WPM
- Rolling 7-day average overlay
- Accessible from a "Progress" tab/section

#### 4.4.3 Per-Key Heatmap

- Visual keyboard where each key's color intensity represents proficiency
- Color scale: red (low confidence) → yellow (medium) → green (high)
- Tap/hover on a key shows: accuracy %, average speed, total attempts
- Accessible from the "Progress" section

### 4.5 Additional MVP+ Settings

| Setting | Type | Default |
|---|---|---|
| Error Mode | Picker | Continue (MVP default) |
|  | | Force Correct (must fix before advancing) |
|  | | Stop on Word (must correct word before next) |
| Show Live Stats | Toggle | On |
| Caret Style | Picker | Line (default), Block, Underline |

---

## 5. Phase 3 — Multi-Layout, Multi-Language & Advanced Modes

### 5.1 Keyboard Layout System

#### 5.1.1 Data-Driven Layout Definition

Each layout is a JSON file mapping physical keys to characters and finger zones:

```json
{
  "id": "qwerty_us",
  "name": "QWERTY (US)",
  "language": "en",
  "rows": [
    {
      "keys": [
        {
          "code": 50,
          "label": "`",
          "shiftLabel": "~",
          "finger": "leftPinky",
          "width": 1.0
        },
        {
          "code": 18,
          "label": "1",
          "shiftLabel": "!",
          "finger": "leftPinky",
          "width": 1.0
        }
      ]
    }
  ]
}
```

#### 5.1.2 Supported Layouts

| Priority | Layout | Region |
|---|---|---|
| Launch (MVP) | QWERTY US (ANSI) | Global |
| Phase 3a | QWERTY UK (ISO) | UK, Ireland |
| Phase 3a | AZERTY | France, Belgium |
| Phase 3a | QWERTZ | Germany, Austria, Switzerland |
| Phase 3b | Dvorak | Enthusiast community |
| Phase 3b | Colemak | Enthusiast community |
| Phase 3c | Ukrainian (ЙЦУКЕН) | Ukraine |
| Phase 3c | Russian (ЙЦУКЕН) | Russia |
| Phase 3c | Spanish (QWERTY ES) | Spain, Latin America |

**Auto-detection:** read the current macOS input source via `TISCopyCurrentKeyboardInputSource()` and suggest the matching layout on first launch.

### 5.2 Multi-Language Support

#### 5.2.1 Word Databases

Each language requires:
- **Common words list:** 1,000–5,000 most frequent words
- **Sentence corpus:** 500+ real sentences for sentence practice
- **Character frequency table:** for adaptive engine weighting

| Language | Word List Source | Priority |
|---|---|---|
| English | Google 10K frequency list (curated to 1K–5K) | MVP |
| Spanish | RAE frequency corpus | Phase 3 |
| French | Lexique 3.0 | Phase 3 |
| German | DeReWo frequency list | Phase 3 |
| Ukrainian | General Regionally Annotated Corpus of Ukrainian (GRAC) | Phase 3 |
| Russian | Frequency Dictionary of Russian (Sharoff) | Phase 3 |

#### 5.2.2 Dead Keys & Composition Events

For languages requiring accented characters (French, Spanish, German):

- Listen for `NSEvent` flagged events indicating dead key composition
- Track composition state: `isComposing` flag
- On composition complete, match the final composed character (e.g., `é`, `ñ`, `ü`)
- On-screen keyboard shows dead key state: highlight the accent key, then highlight the base letter
- Timeout: if no base letter is pressed within 2 seconds of a dead key, cancel composition

#### 5.2.3 IME Considerations (Future)

CJK input method support is deferred to Phase 4+ due to complexity. Phase 3 focuses on Latin-script and Cyrillic-script languages.

### 5.3 Practice Modes

#### 5.3.1 Timed Test

- User selects duration: 15s, 30s, 60s, 120s
- Countdown timer displayed prominently
- Results compared against personal best for that duration
- Word source: configurable (common words, or custom text)

#### 5.3.2 Word Count Test

- User selects word count: 10, 25, 50, 100
- Timer runs up (measuring how long it takes)
- Results: WPM, accuracy, and time

#### 5.3.3 Quote Mode

- Curated collection of 200+ literary quotes (public domain)
- Includes punctuation and capitals for realistic typing
- Attributed to source ("— Mark Twain")

#### 5.3.4 Custom Text

- User pastes or types their own text
- App formats it for typing practice
- No word database needed — use the raw text

#### 5.3.5 Code Mode

- Practice text sourced from common programming patterns
- Includes: brackets, braces, semicolons, operators, indentation
- Language presets: Swift, Python, JavaScript, HTML/CSS
- Uses a code-appropriate font variant

### 5.4 Theme & Appearance

| Theme | Description |
|---|---|
| Dark (default) | Near-black background, cool-toned accents |
| Light | White/light gray background, same accent colors |
| OLED Dark | Pure black background for OLED displays |
| Custom | User-defined background, text, accent, and zone colors |

- Follow `@Environment(\.colorScheme)` for system-matching option
- All themes must maintain WCAG AA contrast ratios for text

### 5.5 Additional Audio

- Multiple sound profiles: Mechanical, Typewriter, Soft Click, None
- Per-profile .caf sound files bundled
- Volume slider (independent of system volume)

---

## 6. Phase 4 — Gamification & Social

### 6.1 Daily Goals & Streaks

- **Daily goal:** configurable target (default: 10 minutes of practice OR 500 words)
- **Streak counter:** consecutive days meeting the goal
- **Forgiveness:** 21-hour window (not 24) — miss a day by 3 hours and still maintain streak
- **Streak freeze:** earn one per 7-day streak; manually activated to survive one missed day
- **Visual:** flame icon with streak count in the main UI; celebration animation on goal completion

### 6.2 Achievements

**Speed Milestones:**

| Badge | Criteria |
|---|---|
| First Steps | Complete first session |
| Warming Up | Reach 20 WPM |
| Getting There | Reach 40 WPM |
| Typist | Reach 60 WPM |
| Speed Demon | Reach 80 WPM |
| Centurion | Reach 100 WPM |
| Lightning | Reach 120 WPM |

**Accuracy Streaks:**

| Badge | Criteria |
|---|---|
| Sharpshooter | 5 consecutive sessions with 95%+ accuracy |
| Perfectionist | Complete a lesson with 100% accuracy |
| Untouchable | 10 consecutive sessions with 98%+ accuracy |

**Volume:**

| Badge | Criteria |
|---|---|
| Thousand Words | Type 1,000 total words |
| Ten Thousand | Type 10,000 total words |
| Hundred Thousand | Type 100,000 total words |
| Marathon | Single session over 30 minutes |

**Completion:**

| Badge | Criteria |
|---|---|
| Home Row Hero | Complete all home row lessons with ★★★ |
| Full Deck | Complete all lessons |
| Master Typist | All lessons at ★★★ |

### 6.3 Personal Bests

- Track personal best WPM for each mode and duration combination
- Highlight when a new personal best is achieved during a session (gold animation)
- Personal best history: show date and improvement trajectory

### 6.4 Leaderboards (Future / Optional)

- Requires server infrastructure (CloudKit or custom backend)
- Segmented: global all-time, weekly, friends
- Anti-cheat: validate session data server-side, flag statistical anomalies
- **Deferred** — only pursue if user base justifies server costs

### 6.5 iCloud Sync

- Sync progress data across user's Macs via CloudKit
- SwiftData + CloudKit integration (native support)
- Conflict resolution: latest-write-wins for session records; merge for cumulative stats

---

## 7. Cross-Cutting Technical Requirements

### 7.1 Accessibility

| Requirement | Implementation |
|---|---|
| VoiceOver | Full VoiceOver support: announce current character, word, and metrics |
| Keyboard navigation | All UI navigable via Tab / Arrow keys (when not in typing mode) |
| Color independence | Finger zones distinguishable by luminance alone; optional text labels |
| Colorblind palette | Validate palette under protanopia, deuteranopia, tritanopia simulation |
| Dynamic Type | Respect system font size for non-typing UI elements |
| Reduced Motion | Disable caret glide and key pulse animations when system preference is set |
| High Contrast | Support `accessibilityHighContrastEnabled` with stronger borders and fills |

### 7.2 Performance Targets

| Metric | Target |
|---|---|
| Keystroke-to-visual latency | < 16ms (1 frame at 60fps) |
| App launch to ready | < 1 second |
| Memory usage (idle) | < 80 MB |
| Memory usage (active session) | < 120 MB |
| CPU usage (active typing) | < 10% of single core |
| Battery impact | "Low" classification in Activity Monitor |

### 7.3 Privacy & Data

- **No analytics in MVP.** No network calls whatsoever.
- All data stored locally in the app sandbox.
- Phase 4 iCloud sync: user-initiated opt-in only.
- No personal data collection beyond typing performance metrics.
- App Sandbox entitlements: none beyond default (no file access, no network in MVP).

### 7.4 Error Handling

| Scenario | Behavior |
|---|---|
| Word list fails to load | Fall back to hardcoded 100-word list; show subtle warning |
| SwiftData migration failure | Preserve old data file; create fresh database; offer manual export |
| Audio playback failure | Silently disable sound; no crash |
| Key event monitor fails | Show user-facing error: "Unable to capture keyboard input. Please check accessibility permissions." |

### 7.5 Testing Strategy

| Layer | Approach |
|---|---|
| Unit Tests | TypingSession logic, WPM/accuracy calculation, KeyMapping correctness, adaptive engine confidence scoring |
| UI Tests | XCUITest for session flow: start → type → complete → summary |
| Snapshot Tests | Keyboard rendering at each finger zone state |
| Performance Tests | `XCTMetric` for keystroke processing time |
| Manual QA | Typing feel, caret smoothness, audio sync, real-user session flow |

---

## 8. Appendix

### 8.1 US QWERTY Physical Key Code Reference (macOS)

| Key | keyCode | Finger |
|---|---|---|
| A | 0 | Left Pinky |
| S | 1 | Left Ring |
| D | 2 | Left Middle |
| F | 3 | Left Index |
| H | 4 | Right Index |
| G | 5 | Left Index |
| Z | 6 | Left Pinky |
| X | 7 | Left Ring |
| C | 8 | Left Middle |
| V | 9 | Left Index |
| B | 11 | Left Index |
| Q | 12 | Left Pinky |
| W | 13 | Left Ring |
| E | 14 | Left Middle |
| R | 15 | Left Index |
| Y | 16 | Right Index |
| T | 17 | Left Index |
| 1 | 18 | Left Pinky |
| 2 | 19 | Left Ring |
| 3 | 20 | Left Middle |
| 4 | 21 | Left Index |
| 6 | 22 | Right Index |
| 5 | 23 | Left Index |
| = | 24 | Right Pinky |
| 9 | 25 | Right Ring |
| 7 | 26 | Right Index |
| - | 27 | Right Pinky |
| 8 | 28 | Right Middle |
| 0 | 29 | Right Pinky |
| ] | 30 | Right Pinky |
| O | 31 | Right Ring |
| U | 32 | Right Index |
| [ | 33 | Right Pinky |
| I | 34 | Right Middle |
| P | 35 | Right Pinky |
| L | 37 | Right Ring |
| J | 38 | Right Index |
| ' | 39 | Right Pinky |
| K | 40 | Right Middle |
| ; | 41 | Right Pinky |
| \ | 42 | Right Pinky |
| , | 43 | Right Middle |
| / | 44 | Right Pinky |
| N | 45 | Right Index |
| M | 46 | Right Index |
| . | 47 | Right Ring |
| Space | 49 | Thumb |
| Backspace | 51 | Right Pinky |
| Enter | 36 | Right Pinky |
| Tab | 48 | Left Pinky |
| Escape | 53 | — |

### 8.2 WPM Calculation Reference

```
Gross WPM = (totalCharactersTyped / 5) / elapsedTimeInMinutes

Net WPM = grossWPM - (uncorrectedErrors / elapsedTimeInMinutes)

Accuracy = correctKeystrokes / totalKeystrokes × 100

Consistency = 100 - (standardDeviation(rollingWPMSamples) / mean(rollingWPMSamples) × 100)
```

**Rolling WPM:** computed over 10-second windows, sampled every 1 second, for the WPM graph and "Best WPM" tracking.

### 8.3 Adaptive Confidence Formula

```
transitionTimeMs = time between previous correct keystroke and current keystroke

speedFactor:
    if transitionTimeMs <= 170:  confidence = 1.0
    if transitionTimeMs >= 500:  confidence = 0.0
    else: confidence = (500 - transitionTimeMs) / (500 - 170)

accuracyFactor = (correctAttempts / totalAttempts) ^ 2

finalConfidence = speedFactor × accuracyFactor
```

Confidence is recalculated after each session using the last 20 transition times per character.

### 8.4 Color Palette — Finger Zones

| Zone | Hex | RGB | Luminance (relative) |
|---|---|---|---|
| Left Pinky | #F687B3 | 246, 135, 179 | 0.45 |
| Left Ring | #ED8936 | 237, 137, 54 | 0.42 |
| Left Middle | #ECC94B | 236, 201, 75 | 0.63 |
| Left Index | #68D391 | 104, 211, 145 | 0.61 |
| Right Index | #4FD1C5 | 79, 209, 197 | 0.59 |
| Right Middle | #63B3ED | 99, 179, 237 | 0.49 |
| Right Ring | #7F9CF5 | 127, 156, 245 | 0.41 |
| Right Pinky | #B794F4 | 183, 148, 244 | 0.42 |
| Thumb | #718096 | 113, 128, 150 | 0.26 |

Luminance values are spread across the 0.26–0.63 range, ensuring differentiation even in grayscale.

### 8.5 Glossary

| Term | Definition |
|---|---|
| Gross WPM | Words per minute without error penalty. 1 word = 5 characters |
| Net WPM | Gross WPM minus penalty for uncorrected errors |
| Transition time | Milliseconds between consecutive correct keystrokes for a specific character |
| Confidence | 0–1 score combining speed and accuracy for a single character |
| Dead key | A key that produces no output until a second key is pressed (used for accents) |
| Finger zone | The group of keys assigned to a specific finger in touch typing |
| Gate | Minimum WPM and accuracy required to complete a lesson |
| Home row | The middle row of letter keys (ASDF JKL;) where fingers rest by default |

---

*End of Technical Documentation*
