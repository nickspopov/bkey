import SwiftUI
import Charts
import SwiftData

struct ProgressDashboardView: View {
    @Query(sort: \SessionRecord.date) private var sessions: [SessionRecord]
    @Query private var proficiencies: [KeyProficiencyRecord]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Progress")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                // WPM Over Time
                if !validSessions.isEmpty {
                    Section {
                        wpmChart
                    } header: {
                        Text("WPM Over Time")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }

                // Stats summary
                statsGrid

                // Key Heatmap
                Section {
                    KeyHeatmapView(proficiencies: proficiencies)
                } header: {
                    Text("Key Proficiency")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .padding()
        }
        .background(Color(red: 13/255, green: 17/255, blue: 23/255))
        .frame(width: 600, height: 700)
    }

    @ViewBuilder
    private var wpmChart: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(validSessions, id: \.date) { session in
                    LineMark(
                        x: .value("Date", session.date),
                        y: .value("Gross WPM", session.wpm)
                    )
                    .foregroundStyle(Color(red: 99/255, green: 179/255, blue: 237/255))
                    .symbol(Circle())

                    LineMark(
                        x: .value("Date", session.date),
                        y: .value("Net WPM", session.netWpm)
                    )
                    .foregroundStyle(Color(red: 104/255, green: 211/255, blue: 145/255))
                    .symbol(Diamond())
                }

                // 7-day rolling average
                ForEach(rollingAverages, id: \.date) { avg in
                    LineMark(
                        x: .value("Date", avg.date),
                        y: .value("7-Day Avg", avg.avgWPM)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            .frame(height: 200)

            // Chart legend
            HStack(spacing: 16) {
                legendItem(color: Color(red: 99/255, green: 179/255, blue: 237/255), label: "Gross WPM")
                legendItem(color: Color(red: 104/255, green: 211/255, blue: 145/255), label: "Net WPM")
                legendItem(color: .orange, label: "7-Day Avg", dashed: true)
            }
            .font(.caption2)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func legendItem(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 4) {
            if dashed {
                Rectangle()
                    .fill(color)
                    .frame(width: 12, height: 2)
                    .overlay(
                        HStack(spacing: 2) {
                            Rectangle().fill(color).frame(width: 4, height: 2)
                            Rectangle().fill(color).frame(width: 4, height: 2)
                        }
                    )
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            Text(label)
                .foregroundStyle(.gray)
        }
    }

    /// 7-day rolling average WPM for each session date
    private var rollingAverages: [(date: Date, avgWPM: Double)] {
        let sorted = validSessions
        guard sorted.count >= 2 else { return [] }

        let sevenDays: TimeInterval = 7 * 24 * 60 * 60
        return sorted.map { session in
            let windowStart = session.date.addingTimeInterval(-sevenDays)
            let inWindow = sorted.filter { $0.date >= windowStart && $0.date <= session.date }
            let avg = inWindow.reduce(0.0) { $0 + $1.wpm } / Double(inWindow.count)
            return (date: session.date, avgWPM: avg)
        }
    }

    /// Sessions with plausible stats (filters out accidental/corrupt data)
    private var validSessions: [SessionRecord] {
        sessions.filter { $0.duration >= 5 && $0.wpm <= 300 }
    }

    private var statsGrid: some View {
        let totalSessions = validSessions.count
        let totalTime = validSessions.reduce(0.0) { $0 + $1.duration }
        let avgWPM = validSessions.isEmpty ? 0 : validSessions.reduce(0.0) { $0 + $1.wpm } / Double(validSessions.count)
        let bestWPM = validSessions.map(\.wpm).max() ?? 0

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(label: "Sessions", value: "\(totalSessions)")
            statCard(label: "Total Time", value: SessionMetrics.formattedTime(totalTime))
            statCard(label: "Avg WPM", value: "\(Int(avgWPM))")
            statCard(label: "Best WPM", value: "\(Int(bestWPM))")
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct Diamond: ChartSymbolShape {
    nonisolated var perceptualUnitRect: CGRect { CGRect(x: 0, y: 0, width: 1, height: 1) }
    nonisolated func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
        }
    }
}
