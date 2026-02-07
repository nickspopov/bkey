import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var eventMonitor: Any?

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
        .frame(minWidth: 900, minHeight: 600)
    }

    @ViewBuilder
    private var typingView: some View {
        VStack(spacing: 0) {
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
                    showFingerLabels: appState.showFingerLabels,
                    keystrokeCount: appState.keystrokeCount
                )
                .frame(height: 220)
                .padding(.bottom, 10)
            }
        }
    }

    @ViewBuilder
    private var sessionSummaryOverlay: some View {
        if let lesson = appState.currentLesson {
            // Lesson mode: show lesson result
            LessonResultView(
                lesson: lesson,
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
                onTryAgain: {
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
