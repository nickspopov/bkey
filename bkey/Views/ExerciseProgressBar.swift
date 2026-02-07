import SwiftUI

struct ExerciseProgressBar: View {
    let exercises: [LessonExercise]
    let currentIndex: Int
    let completedCount: Int

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
                                .foregroundStyle(.white)
                        } else if exercise.id == currentIndex {
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Exercise title
                    Text(exercise.title)
                        .font(.system(size: 9))
                        .foregroundStyle(exercise.id == currentIndex ? .white : .gray)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func fillColor(for id: Int) -> Color {
        if id < completedCount {
            return Color.green.opacity(0.7)
        } else if id == currentIndex {
            return Color(red: 99/255, green: 179/255, blue: 237/255) // #63B3ED
        } else {
            return Color.white.opacity(0.15)
        }
    }
}
