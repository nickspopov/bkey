import SwiftUI
import SwiftData

struct LessonPickerView: View {
    @Bindable var appState: AppState
    @Query private var lessonRecords: [LessonRecord]

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
                        .background(Color.white.opacity(0.05))
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
                                .foregroundStyle(.white)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding()
            }
            .background(Color(red: 13/255, green: 17/255, blue: 23/255))
            .navigationTitle("Lessons")
        }
        .frame(width: 500, height: 600)
    }

    private func lessonRow(_ lesson: Lesson) -> some View {
        let record = lessonRecords.first { $0.lessonId == lesson.id }
        let status = lessonStatus(lesson, record: record)

        return Button {
            if case .locked = status { return }
            appState.startLesson(id: lesson.id)
        } label: {
            HStack {
                Text("\(lesson.id).")
                    .foregroundStyle(.gray)
                    .frame(width: 30)
                Text(lesson.title)
                    .foregroundStyle(status == .locked ? .gray.opacity(0.5) : .white)
                Spacer()
                if !lesson.newKeys.isEmpty {
                    Text(lesson.newKeys.map(String.init).joined(separator: " "))
                        .font(.caption.monospaced())
                        .foregroundStyle(.gray)
                }
                starsView(status)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(status == .locked ? 0.02 : 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(status == .locked)
    }

    @ViewBuilder
    private func starsView(_ status: Lesson.CompletionStatus) -> some View {
        switch status {
        case .locked:
            Image(systemName: "lock.fill")
                .foregroundStyle(.gray.opacity(0.3))
        case .available:
            EmptyView()
        case .completed(let stars):
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(i <= stars ? .yellow : .gray.opacity(0.3))
                }
            }
        }
    }

    private func lessonStatus(_ lesson: Lesson, record: LessonRecord?) -> Lesson.CompletionStatus {
        if let record = record, record.stars > 0 {
            return .completed(stars: record.stars)
        }
        // Lesson 1 is always available
        if lesson.id == 1 { return .available }
        // Check if previous lesson is completed
        let prevRecord = lessonRecords.first { $0.lessonId == lesson.id - 1 }
        if let prev = prevRecord, prev.stars > 0 {
            return .available
        }
        return .locked
    }

}
