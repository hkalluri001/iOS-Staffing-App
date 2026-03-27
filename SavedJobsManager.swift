//
//  SavedJobsManager.swift
//  StaffingAgencyApp
//

import Combine
import SwiftData
import SwiftUI

@Model
final class SavedJobEntry {
    var jobID: String
    var agencyID: String
    var agencyName: String
    var title: String
    var city: String
    var state: String
    var salaryMin: Int
    var salaryMax: Int
    var salaryPeriodRaw: String
    var jobTypeRaw: String
    var remoteOptionRaw: String
    var postedDate: Date
    var expiresDate: Date?
    var applicationURL: String?
    var savedDate: Date

    init(from job: Job) {
        jobID = job.id
        agencyID = job.agencyId
        agencyName = job.agencyName
        title = job.title
        city = job.location.city
        state = job.location.state
        salaryMin = job.salaryMin
        salaryMax = job.salaryMax
        salaryPeriodRaw = job.salaryPeriod.rawValue
        jobTypeRaw = job.type.rawValue
        remoteOptionRaw = job.remoteOption.rawValue
        postedDate = job.postedDate
        expiresDate = job.expiresDate
        applicationURL = job.applicationURL
        savedDate = Date()
    }

    var formattedSalary: String {
        let salaryPeriod = SalaryPeriod(rawValue: salaryPeriodRaw) ?? .yearly

        if salaryPeriod == .hourly {
            return "$\(salaryMin)-$\(salaryMax)/hr"
        }

        return "$\(salaryMin / 1000)k-$\(salaryMax / 1000)k/yr"
    }

    var locationDisplay: String {
        "\(city), \(state)"
    }

    var remoteOption: RemoteOption {
        RemoteOption(rawValue: remoteOptionRaw) ?? .onsite
    }

    var jobType: JobType {
        JobType(rawValue: jobTypeRaw) ?? .fullTime
    }
}

@MainActor
final class SavedJobsManager: ObservableObject {
    private let modelContext: ModelContext
    @Published private(set) var savedEntries: [SavedJobEntry] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetch()
    }

    func fetch() {
        let descriptor = FetchDescriptor<SavedJobEntry>(
            sortBy: [SortDescriptor(\.savedDate, order: .reverse)]
        )
        savedEntries = (try? modelContext.fetch(descriptor)) ?? []
    }

    func save(_ job: Job) {
        guard !isSaved(job.id) else { return }

        modelContext.insert(SavedJobEntry(from: job))
        try? modelContext.save()
        fetch()
    }

    func remove(jobID: String) {
        guard let entry = savedEntries.first(where: { $0.jobID == jobID }) else { return }

        modelContext.delete(entry)
        try? modelContext.save()
        fetch()
    }

    func toggle(_ job: Job) {
        if isSaved(job.id) {
            remove(jobID: job.id)
        } else {
            save(job)
        }
    }

    func isSaved(_ jobID: String) -> Bool {
        savedEntries.contains(where: { $0.jobID == jobID })
    }
}

struct SaveJobButton: View {
    let job: Job
    @EnvironmentObject private var savedJobsManager: SavedJobsManager

    private var isSaved: Bool {
        savedJobsManager.isSaved(job.id)
    }

    var body: some View {
        Button {
            savedJobsManager.toggle(job)
        } label: {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .foregroundStyle(isSaved ? .blue : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Remove saved job" : "Save job")
    }
}

struct SavedJobsView: View {
    @EnvironmentObject private var savedJobsManager: SavedJobsManager

    var body: some View {
        NavigationStack {
            Group {
                if savedJobsManager.savedEntries.isEmpty {
                    ContentUnavailableView(
                        "No Saved Jobs",
                        systemImage: "bookmark",
                        description: Text("Tap the bookmark on any job to save it here.")
                    )
                } else {
                    List {
                        ForEach(savedJobsManager.savedEntries) { entry in
                            SavedJobRow(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Saved Jobs")
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for offset in offsets {
            savedJobsManager.remove(jobID: savedJobsManager.savedEntries[offset].jobID)
        }
    }
}

private struct SavedJobRow: View {
    let entry: SavedJobEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title)
                .font(.headline)

            Text(entry.agencyName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                Label(entry.locationDisplay, systemImage: "mappin")
                Label(entry.formattedSalary, systemImage: "dollarsign.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Badge(text: entry.jobType.rawValue, color: .blue)

                if entry.remoteOption == .remote {
                    Badge(text: "Remote", color: .green, style: .outlined)
                } else if entry.remoteOption == .hybrid {
                    Badge(text: "Hybrid", color: .orange, style: .outlined)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
