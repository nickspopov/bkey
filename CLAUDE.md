# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

bkey is a macOS desktop application built with Swift and SwiftUI. It targets macOS 26.0 and uses Xcode 26.0 as its build system.

## Build & Test Commands

```bash
# Build the project
xcodebuild -project bkey.xcodeproj -scheme bkey build

# Run all unit tests
xcodebuild -project bkey.xcodeproj -scheme bkey test

# Run UI tests specifically
xcodebuild -project bkey.xcodeproj -scheme bkey -only-testing:bkeyUITests test
```

## Architecture

- **bkey target** — Main app. Entry point is `bkey/bkeyApp.swift` (@main SwiftUI App struct). UI starts in `bkey/ContentView.swift`.
- **bkeyTests target** — Unit tests using the Swift Testing framework (`@Test` macro, `import Testing`).
- **bkeyUITests target** — UI tests using XCTest (`XCTestCase` subclasses).

## Key Build Settings

- Swift 5.0 with `SWIFT_APPROACHABLE_CONCURRENCY` and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- App Sandbox and Hardened Runtime enabled
- Bundle identifier: `orgnick.bkey`
- No external dependencies
