import SwiftUI

struct ExerciseTransitionView: View {
    let completedExercise: LessonExercise
    let nextExercise: LessonExercise?
    let lastResult: ExerciseResult?
    let onContinue: () -> Void

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
                        .foregroundStyle(.white)

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
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 40)

                // Next exercise info
                if let next = nextExercise {
                    VStack(spacing: 6) {
                        Text("Next:")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(next.title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text(next.instruction)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                }

                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 99/255, green: 179/255, blue: 237/255))
                .padding(.top, 8)
            }
            .padding(32)
            .frame(width: 360)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 22/255, green: 27/255, blue: 34/255))
                    .shadow(radius: 20)
            )
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}
