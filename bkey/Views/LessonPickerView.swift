import SwiftUI
import SwiftData

struct LessonPickerView: View {
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Query private var lessonRecords: [LessonRecord]
    @State private var lessonToSkip: Lesson?

    private let tiers = [
        (1, "Home Row"),
        (2, "Top Row"),
        (3, "Bottom Row"),
        (4, "Shift & Capitals"),
        (5, "Punctuation & Numbers"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Free Run button
                    Button {
                        appState.startFreeRun()
                    } label: {
                        HStack {
                            Image(systemName: "keyboard")
                            Text("Free Run")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(theme.statsBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    ForEach(tiers, id: \.0) { tier, tierName in
                        Section {
                            let tierLessons = LessonCurriculum.allLessons.filter { $0.tier == tier }
                            ForEach(tierLessons) { lesson in
                                lessonRow(lesson)
                            }
                        } header: {
                            Text("Tier \(tier): \(tierName)")
                                .font(.headline)
                                .foregroundStyle(theme.textPrimary)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding()
            }
            .background(theme.background)
            .navigationTitle("Lessons")
        }
        .frame(width: 500, height: 600)
        .alert("Skip Lesson", isPresented: Binding(
            get: { lessonToSkip != nil },
            set: { if !$0 { lessonToSkip = nil } }
        )) {
            Button("Skip", role: .destructive) {
                if let lesson = lessonToSkip {
                    skipLesson(lesson)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let lesson = lessonToSkip {
                Text("Skip \"\(lesson.title)\"? You can come back to it later.")
            }
        }
    }

    private var firstAvailableLessonId: Int? {
        for lesson in LessonCurriculum.allLessons {
            let record = lessonRecords.first { $0.lessonId == lesson.id }
            let status = lessonStatus(lesson, record: record)
            if status == .available {
                return lesson.id
            }
        }
        return nil
    }

    private func lessonRow(_ lesson: Lesson) -> some View {
        let record = lessonRecords.first { $0.lessonId == lesson.id }
        let status = lessonStatus(lesson, record: record)
        let isFirstAvailable = lesson.id == firstAvailableLessonId

        return HStack {
            Button {
                appState.startLesson(id: lesson.id)
            } label: {
                HStack {
                    Text("\(lesson.id).")
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 30)
                    Text(lesson.title)
                        .foregroundStyle(status == .locked ? theme.textSecondary.opacity(0.5) : theme.textPrimary)
                    Spacer()
                    if !lesson.newKeys.isEmpty {
                        Text(lesson.newKeys.map(String.init).joined(separator: " "))
                            .font(.caption.monospaced())
                            .foregroundStyle(theme.textSecondary)
                    }
                    starsView(status)
                }
            }
            .buttonStyle(.plain)
            .disabled(status == .locked)

            if isFirstAvailable {
                Button("Skip") {
                    lessonToSkip = lesson
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(theme.statsBackground.opacity(status == .locked ? 0.4 : 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private func starsView(_ status: Lesson.CompletionStatus) -> some View {
        switch status {
        case .locked:
            Image(systemName: "lock.fill")
                .foregroundStyle(theme.textSecondary.opacity(0.3))
        case .available:
            EmptyView()
        case .skipped:
            Image(systemName: "forward.fill")
                .font(.caption)
                .foregroundStyle(.orange.opacity(0.6))
        case .completed(let stars):
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(i <= stars ? .yellow : theme.textSecondary.opacity(0.3))
                }
            }
        }
    }

    private func lessonStatus(_ lesson: Lesson, record: LessonRecord?) -> Lesson.CompletionStatus {
        if let record = record, record.stars > 0 {
            return .completed(stars: record.stars)
        }
        if let record = record, record.skipped {
            return .skipped
        }
        // Lesson 1 is always available
        if lesson.id == 1 { return .available }
        // Check if previous lesson is completed or skipped
        let prevRecord = lessonRecords.first { $0.lessonId == lesson.id - 1 }
        if let prev = prevRecord, prev.stars > 0 || prev.skipped {
            return .available
        }
        return .locked
    }

    private func skipLesson(_ lesson: Lesson) {
        let record = lessonRecords.first { $0.lessonId == lesson.id } ?? {
            let r = LessonRecord(lessonId: lesson.id)
            modelContext.insert(r)
            return r
        }()
        record.skipped = true
        try? modelContext.save()
    }

}
