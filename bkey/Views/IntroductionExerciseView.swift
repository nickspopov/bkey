import SwiftUI

struct IntroductionExerciseView: View {
    let exercise: LessonExercise
    let appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            Text("New Keys")
                .font(.title2.bold())
                .foregroundStyle(.white)

            // Key cards showing new keys and their finger assignments
            HStack(spacing: 20) {
                ForEach(exercise.fingerMappings, id: \.character) { mapping in
                    VStack(spacing: 12) {
                        // Key label
                        Text(String(mapping.character).uppercased())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(mapping.finger.color.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(mapping.finger.color, lineWidth: 2)
                            )

                        // Finger zone label
                        Text(mapping.finger.label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(mapping.finger.color)

                        Text(fingerName(mapping.finger))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }

            Spacer().frame(height: 8)

            // Keyboard with highlighted keys
            if appState.showKeyboard {
                KeyboardView(
                    activeKeyCode: nil,
                    lastPressedKeyCode: nil,
                    lastPressCorrect: true,
                    showFingerLabels: appState.showFingerLabels,
                    keystrokeCount: 0,
                    highlightedKeys: highlightedKeyCodes
                )
                .frame(height: 180)
            }

            Text("Press Space to continue")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
    }

    private var highlightedKeyCodes: Set<UInt16> {
        var codes = Set<UInt16>()
        for char in exercise.newKeys {
            if let code = KeyMapping.keyCode(for: char) {
                codes.insert(code)
            }
        }
        return codes
    }

    private func fingerName(_ finger: FingerZone) -> String {
        switch finger {
        case .leftPinky: "Left Pinky"
        case .leftRing: "Left Ring"
        case .leftMiddle: "Left Middle"
        case .leftIndex: "Left Index"
        case .rightIndex: "Right Index"
        case .rightMiddle: "Right Middle"
        case .rightRing: "Right Ring"
        case .rightPinky: "Right Pinky"
        case .thumb: "Thumb"
        }
    }
}
