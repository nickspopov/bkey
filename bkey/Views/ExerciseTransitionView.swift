import SwiftUI

struct ExerciseTransitionView: View {
    let completedExercise: LessonExercise
    let nextExercise: LessonExercise?
    let lastResult: ExerciseResult?
    let onContinue: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Completed exercise
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)

                    Text(completedExercise.title)
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)

                    Text("Complete")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                // Mini stats from completed exercise
                if let result = lastResult, completedExercise.type.isTypingExercise {
                    HStack(spacing: 24) {
                        miniStat(label: "WPM", value: "\(Int(result.wpm))")
                        miniStat(label: "Accuracy", value: "\(Int(result.accuracy))%")
                    }
                }

                Divider()
                    .background(theme.textSecondary.opacity(0.2))
                    .padding(.horizontal, 40)

                // Next exercise info
                if let next = nextExercise {
                    VStack(spacing: 6) {
                        Text("Next:")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                        Text(next.title)
                            .font(.title3.bold())
                            .foregroundStyle(theme.textPrimary)
                        Text(next.instruction)
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .padding(.top, 8)
            }
            .padding(32)
            .frame(width: 360)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceBackground)
                    .shadow(radius: 20)
            )
        }
        .accessibilityIdentifier("exerciseTransition")
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(theme.textSecondary)
        }
    }
}
