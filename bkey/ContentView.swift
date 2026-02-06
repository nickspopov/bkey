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
