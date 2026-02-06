import SwiftUI

struct KeyHeatmapView: View {
    let proficiencies: [KeyProficiencyRecord]

    var body: some View {
        VStack(spacing: 2) {
            // Show just the letter rows (rows 1-3 of layout)
            ForEach(1...3, id: \.self) { rowIndex in
                let row = LayoutDefinition.qwertyUS[rowIndex]
                HStack(spacing: 2) {
                    ForEach(Array(row.keys.enumerated()), id: \.offset) { _, key in
                        if key.label.count == 1 {
                            heatmapKey(key)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func heatmapKey(_ key: KeyDefinition) -> some View {
        let char = key.label.lowercased()
        let record = proficiencies.first { $0.character == char }
        let confidence = record?.confidence ?? 0

        return VStack(spacing: 2) {
            Text(key.label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
            if let record = record, record.totalAttempts > 0 {
                Text("\(Int(record.confidence * 100))%")
                    .font(.system(size: 7))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(width: 36, height: 36)
        .background(confidenceColor(confidence))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence < 0.33 {
            return Color.red.opacity(0.3 + confidence * 0.5)
        } else if confidence < 0.66 {
            return Color.yellow.opacity(0.3 + confidence * 0.3)
        } else {
            return Color.green.opacity(0.3 + confidence * 0.3)
        }
    }
}
