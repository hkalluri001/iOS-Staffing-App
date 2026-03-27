//
//  AdvancedSearchView.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI

struct AdvancedSearchView: View {
    @State private var searchText = ""
    @State private var selectedRole: JobRole?
    @State private var selectedLocation: String = "All USA"
    @State private var selectedIndustry: Industry?
    @State private var minSalary: Double = 0
    @State private var remoteOnly = false

    @State private var searchResults: [Job] = []
    @State private var isSearching = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                searchHeader
                roleSelector
                filterSection
                searchButton
                resultsSection
            }
            .padding()
        }
        .navigationTitle("Find Jobs")
        .background(Color(.systemGroupedBackground))
        .task {
            await loadOpenJobs()
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: 12) {
            Text("Search open jobs")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("e.g. iOS Developer, Nurse, Accountant", text: $searchText)
                    .font(.body)

                if !searchText.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }

    // MARK: - Role Selector

    private var roleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Roles")
                .font(.headline)

            FlowLayout(spacing: 10) {
                ForEach(JobRole.allCases) { role in
                    RoleChip(
                        role: role,
                        isSelected: selectedRole == role,
                        action: {
                            selectedRole = selectedRole == role ? nil : role
                            performSearch()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filters")
                .font(.headline)

            HStack {
                Image(systemName: "mappin")
                    .foregroundColor(.blue)
                Picker("Location", selection: $selectedLocation) {
                    ForEach(["All USA", "California", "New York", "Texas", "Florida", "Remote"], id: \.self) { location in
                        Text(location).tag(location)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedLocation) { _, _ in
                    performSearch()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)

            HStack {
                Image(systemName: "briefcase")
                    .foregroundColor(.blue)
                Picker("Industry", selection: $selectedIndustry) {
                    Text("All Industries").tag(nil as Industry?)
                    ForEach(Industry.allCases) { industry in
                        Text(industry.rawValue).tag(industry as Industry?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedIndustry) { _, _ in
                    performSearch()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)

            Toggle(isOn: $remoteOnly) {
                HStack {
                    Image(systemName: "house")
                        .foregroundColor(.green)
                    Text("Remote Only")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .onChange(of: remoteOnly) { _, _ in
                performSearch()
            }

            VStack(alignment: .leading) {
                Text("Minimum Salary: $\(Int(minSalary))k")
                    .font(.subheadline)
                Slider(value: $minSalary, in: 0...200, step: 10) { _ in
                    performSearch()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }

    // MARK: - Search Button

    private var searchButton: some View {
        Button(action: performSearch) {
            HStack {
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "magnifyingglass")
                }
                Text(isSearching ? "Searching..." : "Search Jobs")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(searchResults.count) Open Jobs")
                .font(.headline)
                .padding(.top)

            if searchResults.isEmpty {
                EmptySearchView(query: effectiveQuery)
            } else {
                ForEach(searchResults) { job in
                    NavigationLink {
                        JobDetailView(job: job)
                    } label: {
                        SearchJobCard(job: job)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var effectiveQuery: String {
        let roleQuery = selectedRole?.rawValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let textQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return textQuery.isEmpty ? roleQuery : textQuery
    }

    // MARK: - Search Logic

    private func clearSearch() {
        searchText = ""
        selectedRole = nil
        performSearch()
    }

    private func loadOpenJobs() async {
        isSearching = true
        let jobs = await JobAPIService.shared.getOpenJobs()
        await MainActor.run {
            searchResults = jobs
            isSearching = false
        }
    }

    private func performSearch() {
        isSearching = true

        Task {
            let jobs = await JobAPIService.shared.searchOpenJobs(
                query: searchText,
                role: selectedRole?.rawValue,
                location: selectedLocation,
                industry: selectedIndustry,
                minSalary: minSalary,
                remoteOnly: remoteOnly
            )

            await MainActor.run {
                searchResults = jobs
                isSearching = false
            }
        }
    }
}

// MARK: - Supporting Types

enum JobRole: String, CaseIterable, Identifiable {
    case iOSDeveloper = "iOS Developer"
    case nurse = "Registered Nurse"
    case accountant = "Accountant"
    case softwareEngineer = "Software Engineer"
    case uxDesigner = "UX Designer"
    case dataAnalyst = "Data Analyst"
    case projectManager = "Project Manager"
    case salesRep = "Sales Representative"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .iOSDeveloper, .softwareEngineer: return "laptopcomputer"
        case .nurse: return "cross.fill"
        case .accountant: return "dollarsign.circle"
        case .uxDesigner: return "paintbrush"
        case .dataAnalyst: return "chart.bar"
        case .projectManager: return "person.2"
        case .salesRep: return "phone.fill"
        }
    }
}

enum Industry: String, CaseIterable, Identifiable {
    case technology = "Technology"
    case healthcare = "Healthcare"
    case finance = "Finance"
    case education = "Education"
    case manufacturing = "Manufacturing"
    case retail = "Retail"

    var id: String { rawValue }
}

struct RoleChip: View {
    let role: JobRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: role.icon)
                Text(role.rawValue)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchJobCard: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(job.agencyName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if job.remoteOption == .remote {
                    Badge(text: "Remote", color: .green, style: .outlined)
                } else if job.remoteOption == .hybrid {
                    Badge(text: "Hybrid", color: .orange, style: .outlined)
                }
            }

            HStack(spacing: 16) {
                DetailItem(icon: "mappin", text: "\(job.location.city), \(job.location.state)")
                DetailItem(icon: "dollarsign.circle", text: job.formattedSalary)
                DetailItem(icon: "briefcase", text: job.type.rawValue)
            }

            HStack {
                Text("Posted \(job.postedDateDisplay)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(job.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct EmptySearchView: View {
    let query: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(query.isEmpty ? "No open jobs available right now" : "No jobs found for '\(query)'")
                .font(.headline)

            Text("Try a different job title, location, or filter.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
}
