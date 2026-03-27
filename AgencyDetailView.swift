//
//  AgencyDetailView.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI
import MapKit

struct AgencyDetailView: View {
    let agency: Agency
    @State private var selectedTab = 0
    @State private var selectedJob: Job?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                
                Picker("", selection: $selectedTab) {
                    Text("Jobs (\(MockData.shared.jobs(forAgencyId: agency.id).count))").tag(0)
                    Text("About").tag(1)
                    Text("Locations").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Group {
                    switch selectedTab {
                    case 0:
                        jobsTab
                    case 1:
                        aboutTab
                    case 2:
                        locationsTab
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedJob) { job in
            JobDetailView(job: job)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "building.2.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 8) {
                Text(agency.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if agency.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            
            VStack(spacing: 4) {
                StarRating(rating: agency.rating, size: 24)
                Text("\(agency.reviewCount) reviews")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                ActionButton(icon: "phone.fill", title: "Call") {
                    callPhone()
                }
                ActionButton(icon: "envelope.fill", title: "Email") {
                    sendEmail()
                }
                ActionButton(icon: "safari.fill", title: "Website") {
                    openWebsite()
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var jobsTab: some View {
        LazyVStack(spacing: 12) {
            ForEach(MockData.shared.jobs(forAgencyId: agency.id)) { job in
                JobCard(job: job) {
                    selectedJob = job
                }
            }
        }
        .padding(.vertical)
    }
    
    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            InfoSection(title: "Overview") {
                Text(agency.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            InfoSection(title: "Details") {
                VStack(spacing: 12) {
                    DetailRow(icon: "briefcase.fill", title: "Specialties", value: agency.specialties.joined(separator: ", "))
                    DetailRow(icon: "person.2.fill", title: "Company Size", value: agency.employeeCount)
                    DetailRow(icon: "calendar", title: "Founded", value: String(agency.foundedYear))
                }
            }
            
            InfoSection(title: "Contact") {
                VStack(spacing: 12) {
                    DetailRow(icon: "phone.fill", title: "Phone", value: agency.phone)
                    DetailRow(icon: "envelope.fill", title: "Email", value: agency.email)
                    DetailRow(icon: "globe", title: "Website", value: agency.website)
                }
            }
        }
        .padding(.vertical)
    }
    
    private var locationsTab: some View {
        VStack(spacing: 16) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: agency.locations.first?.coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))) {
                ForEach(agency.locations) { location in
                    Marker(location.city, coordinate: location.coordinate)
                }
            }
            .frame(height: 300)
            .cornerRadius(16)
            
            VStack(spacing: 12) {
                ForEach(agency.locations) { location in
                    LocationRow(location: location)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func callPhone() {
        guard let url = URL(string: "tel:\(agency.phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression))") else { return }
        UIApplication.shared.open(url)
    }
    
    private func sendEmail() {
        guard let url = URL(string: "mailto:\(agency.email)") else { return }
        UIApplication.shared.open(url)
    }
    
    private func openWebsite() {
        guard let url = URL(string: agency.website) else { return }
        UIApplication.shared.open(url)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .frame(width: 70)
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

struct LocationRow: View {
    let location: AgencyLocation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(location.city)
                    .font(.headline)
                Text(location.fullAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
