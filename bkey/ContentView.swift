import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var eventMonitor: Any?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background
            Color(red: 13/255, green: 17/255, blue: 23/255) // #0D1117
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: tabs + settings
                HStack(spacing: 0) {
                    // Tab picker
                    HStack(spacing: 4) {
                        ForEach(AppTab.allCases, id: \.self) { tab in
                            Button {
                                appState.selectedTab = tab
                                if tab == .freeRun && appState.mode != .freeRun {
                                    appState.startFreeRun()
                                }
                            } label: {
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: appState.selectedTab == tab ? .semibold : .regular))
                                    .foregroundStyle(appState.selectedTab == tab ? .white : .gray)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        appState.selectedTab == tab
                                            ? Color.white.opacity(0.1)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.leading, 16)

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
                }
                .padding(.top, 8)

                // Content based on selected tab
                switch appState.selectedTab {
                case .freeRun:
                    typingView
                case .lessons:
                    LessonPickerView(appState: appState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .progress:
                    ProgressDashboardView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // Exercise transition overlay
            if appState.showExerciseTransition, let flow = appState.lessonFlow {
                ExerciseTransitionView(
                    completedExercise: flow.exercises[flow.currentExerciseIndex],
                    nextExercise: flow.currentExerciseIndex + 1 < flow.exercises.count
                        ? flow.exercises[flow.currentExerciseIndex + 1]
                        : nil,
                    lastResult: flow.exerciseResults.last,
                    onContinue: {
                        appState.advanceExercise()
                    }
                )
            }

            // Session summary overlay
            if appState.showSessionSummary {
                sessionSummaryOverlay
            }
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView(appState: appState)
        }
        .onAppear {
            appState.loadProficiencyData()
            appState.startFreeRun()
            eventMonitor = KeyEventHandler.setupMonitor(appState: appState)
        }
        .onDisappear {
            KeyEventHandler.removeMonitor(eventMonitor)
        }
        .environment(\.appTheme, AppTheme.forMode(appState.themeMode, colorScheme: colorScheme))
        .frame(minWidth: 900, minHeight: 600)
    }

    @ViewBuilder
    private var typingView: some View {
        VStack(spacing: 0) {
            // Exercise progress bar (lesson mode only)
            if let flow = appState.lessonFlow {
                ExerciseProgressBar(
                    exercises: flow.exercises,
                    currentIndex: flow.currentExerciseIndex,
                    completedCount: flow.exerciseResults.count
                )
            }

            // Check if we're on an introduction exercise
            if let flow = appState.lessonFlow,
               let exercise = flow.currentExercise,
               exercise.type == .introduction {
                Spacer()
                IntroductionExerciseView(exercise: exercise, appState: appState)
                Spacer()
            } else {
                // Mode picker (free run, ready state only)
                if appState.lessonFlow == nil && appState.session.state == .ready {
                    ModePickerView(appState: appState)
                        .padding(.top, 12)
                }

                // Stats bar
                if appState.showLiveStats {
                    StatsBarView(
                        session: appState.session,
                        lesson: appState.currentLesson,
                        practiceMode: appState.practiceMode,
                        countdownRemaining: appState.countdownRemaining
                    )
                    .id(appState.session.keystrokes) // force refresh
                }

                Spacer()

                // Lesson typing progress bar
                if appState.lessonFlow != nil {
                    let total = max(appState.session.targetText.count, 1)
                    ProgressView(value: Double(appState.session.currentIndex), total: Double(total))
                        .tint(Color(red: 99/255, green: 179/255, blue: 237/255))
                        .scaleEffect(y: 1.5) // 3px height
                        .padding(.horizontal, 40)
                        .animation(.easeOut(duration: 0.1), value: appState.session.currentIndex)
                }

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
                        showFingerLabels: appState.showFingerLabels,
                        keystrokeCount: appState.keystrokeCount
                    )
                    .frame(height: 220)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    @ViewBuilder
    private var sessionSummaryOverlay: some View {
        if let lesson = appState.currentLesson, let flow = appState.lessonFlow {
            // Lesson mode: show lesson result
            LessonResultView(
                lesson: lesson,
                lessonFlow: flow,
                session: appState.session,
                onNext: {
                    appState.startNextLesson()
                },
                onRetry: {
                    appState.startLesson(id: lesson.id)
                },
                onClose: {
                    appState.showSessionSummary = false
                }
            )
        } else {
            // Free run mode: show standard summary
            SessionSummaryView(
                session: appState.session,
                practiceMode: appState.practiceMode,
                onRestart: {
                    appState.startFreeRun()
                },
                onClose: {
                    appState.showSessionSummary = false
                }
            )
        }
    }
}

#Preview {
    ContentView()
}
