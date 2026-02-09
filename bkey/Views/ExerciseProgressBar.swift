import SwiftUI

struct ExerciseProgressBar: View {
    let exercises: [LessonExercise]
    let currentIndex: Int
    let completedCount: Int

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            ForEach(exercises) { exercise in
                VStack(spacing: 4) {
                    // Dot/pill indicator
                    ZStack {
                        Circle()
                            .fill(fillColor(for: exercise.id))
                            .frame(width: 24, height: 24)

                        if exercise.id < completedCount {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(theme.textPrimary)
                        } else if exercise.id == currentIndex {
                            Circle()
                                .fill(theme.textPrimary)
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Exercise title
                    Text(exercise.title)
                        .font(.system(size: 9))
                        .foregroundStyle(exercise.id == currentIndex ? theme.textPrimary : theme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("exerciseProgressBar")
    }

    private func fillColor(for id: Int) -> Color {
        if id < completedCount {
            return Color.green.opacity(0.7)
        } else if id == currentIndex {
            return theme.accent
        } else {
            return theme.textSecondary.opacity(0.15)
        }
    }
}
