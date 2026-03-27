//
//  HomeView.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @State private var searchMode: SearchMode = .agencies
    @State private var searchText = ""
    @State private var agencies: [StaffingAgencyDetail] = []
    @State private var jobs: [UnifiedJobListing] = []
    @State private var isLoading = false
    @State private var selectedAgency: StaffingAgencyDetail?
    
    enum SearchMode {
        case agencies, jobs
    }
    
    var filteredAgencies: [StaffingAgencyDetail] {
        if searchText.isEmpty { return agencies }
        return agencies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.specialties.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerSection
                
                // Search Mode Toggle
                Picker("Search Mode", selection: $searchMode) {
                    Text("Agencies").tag(SearchMode.agencies)
                    Text("Jobs").tag(SearchMode.jobs)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Search Bar
                searchBarSection
                
                // Quick Filters
                if searchMode == .agencies {
                    specialtyFilters
                } else {
                    jobRoleFilters
                }
                
                // Results
                resultsSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Staffing Search")
        .task {
            await loadInitialData()
        }
        .onChange(of: searchMode) { _, mode in
            Task {
                await reloadResults(for: mode)
            }
        }
        .sheet(item: $selectedAgency) { agency in
            AgencyDetailSheet(agency: agency)
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Find Your Next Opportunity")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Search \(agencies.count) staffing agencies across the USA")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var searchBarSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(
                    searchMode == .agencies
                        ? "Search agencies by name or specialty..."
                        : "Search job titles (e.g. 'Nurse', 'Developer')...",
                    text: $searchText
                )
                .font(.body)
                .submitLabel(.search)
                .onSubmit(performSearch)
                
                if !searchText.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
            
            // Location bar
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text("USA (Nationwide)")
                    .font(.subheadline)
                Spacer()
                Button("Change") {}
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.horizontal)
        }
    }
    
    private var specialtyFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Specialty")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(["IT", "Healthcare", "Finance", "Engineering", "Design", "Marketing"], id: \.self) { specialty in
                        Button(action: {
                            searchText = specialty
                            performSearch()
                        }) {
                            Text(specialty)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var jobRoleFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Roles")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(["iOS Developer", "RN Nurse", "CPA", "UX Designer", "Project Manager"], id: \.self) { role in
                        Button(action: {
                            searchText = role
                            performSearch()
                        }) {
                            Text(role)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if searchMode == .agencies {
                Text("\(filteredAgencies.count) Agencies Found")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 12) {
                    ForEach(filteredAgencies) { agency in
                        EnhancedAgencyCard(agency: agency) {
                            selectedAgency = agency
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                Text("\(jobs.count) Jobs Found")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 12) {
                    ForEach(jobs) { job in
                        JobResultCard(job: job)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func loadInitialData() async {
        isLoading = true
        do {
            async let fetchedAgencies = JobAPIService.shared.getStaffingAgencies()
            async let fetchedJobs = JobAPIService.shared.getOpenJobListings()
            agencies = try await fetchedAgencies
            jobs = await fetchedJobs
        } catch {
            print("Failed to load: \(error)")
        }
        isLoading = false
    }

    private func reloadResults(for mode: SearchMode) async {
        if mode == .jobs {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                jobs = await JobAPIService.shared.getOpenJobListings()
            } else {
                jobs = await JobAPIService.shared.searchOpenJobListings(query: searchText)
            }
        }
    }

    private func clearSearch() {
        searchText = ""

        if searchMode == .jobs {
            Task {
                jobs = await JobAPIService.shared.getOpenJobListings()
            }
        }
    }
    
    private func performSearch() {
        isLoading = true
        
        Task {
            if searchMode == .jobs {
                let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let results: [UnifiedJobListing]

                if trimmedSearch.isEmpty {
                    results = await JobAPIService.shared.getOpenJobListings()
                } else {
                    results = await JobAPIService.shared.searchOpenJobListings(query: trimmedSearch)
                }

                await MainActor.run {
                    jobs = results
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct JobResultCard: View {
    let job: UnifiedJobListing

    private var postedTimeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: job.postedDate, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)

                    Text(job.company)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if job.remote {
                    Badge(text: "Remote", color: .green, style: .outlined)
                }
            }

            HStack(spacing: 12) {
                Label(job.location, systemImage: "mappin")
                Label(job.jobType.rawValue, systemImage: "briefcase")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Text(job.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                if let salary = job.formattedSalary {
                    Badge(text: salary, color: .blue)
                }

                Spacer()

                Text(postedTimeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Enhanced Agency Card

struct EnhancedAgencyCard: View {
    let agency: StaffingAgencyDetail
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(agency.name)
                                .font(.headline)
                            
                            if agency.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        
                        StarRating(rating: agency.rating, size: 14)
                        
                        HStack(spacing: 12) {
                            Label("\(agency.openJobsCount) jobs", systemImage: "briefcase")
                            Label("\(agency.locations.count) locations", systemImage: "mappin")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                FlowLayout(spacing: 8) {
                    ForEach(agency.specialties.prefix(4), id: \.self) { specialty in
                        Badge(text: specialty, color: .blue)
                    }
                }
                
                // Location preview
                HStack {
                    Image(systemName: "map")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(agency.locations.map { "\($0.city), \($0.state)" }.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Agency Detail Sheet

struct AgencyDetailSheet: View {
    let agency: StaffingAgencyDetail
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        
                        Text(agency.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        StarRating(rating: agency.rating, size: 24)
                        
                        HStack(spacing: 20) {
                            StatBox(value: "\(agency.openJobsCount)", label: "Open Jobs")
                            StatBox(value: "\(agency.locations.count)", label: "Locations")
                            StatBox(value: "\(agency.reviewCount)", label: "Reviews")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    // Contact Buttons
                    HStack(spacing: 16) {
                        ContactButton(icon: "phone.fill", title: "Call", color: .green) {
                            if let url = URL(string: "tel:\(agency.phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression))") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        ContactButton(icon: "envelope.fill", title: "Email", color: .blue) {
                            if let url = URL(string: "mailto:\(agency.email)") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        ContactButton(icon: "safari.fill", title: "Website", color: .orange) {
                            if let url = URL(string: agency.website) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Locations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Locations")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(agency.locations) { location in
                            LocationDetailCard(location: location)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Specialties
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Specialties")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(agency.specialties, id: \.self) { specialty in
                                Badge(text: specialty, color: .purple)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Agency Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 70)
    }
}

struct ContactButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct LocationDetailCard: View {
    let location: AgencyLocationDetail
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(location.city), \(location.state)")
                    .font(.headline)
                Text(location.fullAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(location.phone)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
