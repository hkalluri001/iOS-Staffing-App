//
//  AgencyMapView.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI
import MapKit

struct AgencyMapView: View {
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of USA
        span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 40)
    ))
    
    @State private var agencies: [StaffingAgencyDetail] = []
    @State private var selectedAgency: StaffingAgencyDetail?
    @State private var filterSpecialty: String?
    @State private var showFilters = false
    
    var filteredAgencies: [StaffingAgencyDetail] {
        if let specialty = filterSpecialty {
            return agencies.filter {
                $0.specialties.contains(where: {
                    $0.localizedCaseInsensitiveContains(specialty)
                })
            }
        }
        return agencies
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    ForEach(filteredAgencies) { agency in
                        ForEach(agency.locations) { location in
                            Annotation(agency.name, coordinate: location.coordinate) {
                                AgencyMapMarker(
                                    agency: agency,
                                    isSelected: selectedAgency?.id == agency.id
                                )
                                .onTapGesture {
                                    selectedAgency = agency
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                
                // Filter overlay
                VStack {
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterPill(
                                    title: "All",
                                    isSelected: filterSpecialty == nil,
                                    action: { filterSpecialty = nil }
                                )
                                
                                ForEach(allSpecialties, id: \.self) { specialty in
                                    FilterPill(
                                        title: specialty,
                                        isSelected: filterSpecialty == specialty,
                                        action: { filterSpecialty = specialty }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button(action: { showFilters.toggle() }) {
                            Image(systemName: "slider.horizontal.3")
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Selected agency card
                    if let agency = selectedAgency {
                        AgencyPreviewCard(agency: agency) {
                            // Navigate to detail
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationTitle("Agency Locations")
            .sheet(isPresented: $showFilters) {
                MapFilterSheet(
                    selectedSpecialty: $filterSpecialty,
                    agencies: agencies
                )
            }
            .task {
                await loadAgencies()
            }
        }
    }
    
    private var allSpecialties: [String] {
        Array(Set(agencies.flatMap { $0.specialties })).sorted()
    }
    
    private func loadAgencies() async {
        do {
            agencies = try await JobAPIService.shared.getStaffingAgencies()
        } catch {
            print("Failed to load agencies: \(error)")
        }
    }
}

struct AgencyMapMarker: View {
    let agency: StaffingAgencyDetail
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(agency.isVerified ? Color.blue : Color.orange)
                .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                .shadow(radius: 4)
            
            VStack(spacing: 2) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: isSelected ? 20 : 16))
                Text("\(agency.openJobsCount)")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.white)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AgencyPreviewCard: View {
    let agency: StaffingAgencyDetail
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Logo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
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
                    
                    Text("\(agency.openJobsCount) open jobs • \(agency.locations.count) locations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(agency.specialties.prefix(3), id: \.self) { specialty in
                            Text(specialty)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 8)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MapFilterSheet: View {
    @Binding var selectedSpecialty: String?
    let agencies: [StaffingAgencyDetail]
    @Environment(\.dismiss) private var dismiss
    
    var allSpecialties: [String] {
        Array(Set(agencies.flatMap { $0.specialties })).sorted()
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Filter by Specialty") {
                    Button("Show All") {
                        selectedSpecialty = nil
                        dismiss()
                    }
                    .foregroundColor(selectedSpecialty == nil ? .blue : .primary)
                    
                    ForEach(allSpecialties, id: \.self) { specialty in
                        Button(action: {
                            selectedSpecialty = specialty
                            dismiss()
                        }) {
                            HStack {
                                Text(specialty)
                                Spacer()
                                if selectedSpecialty == specialty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("Statistics") {
                    StatRow(title: "Total Agencies", value: "\(agencies.count)")
                    StatRow(title: "Total Locations", value: "\(agencies.flatMap { $0.locations }.count)")
                    StatRow(title: "Open Jobs", value: "\(agencies.reduce(0) { $0 + $1.openJobsCount })")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}
