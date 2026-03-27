//
//  JobDetailView.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI

struct JobDetailView: View {
    let job: Job
    @State private var isApplied = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                detailsSection
                descriptionSection
                requirementsSection
                
                if !job.benefits.isEmpty {
                    benefitsSection
                }
                
                Color.clear.frame(height: 100)
            }
        }
        .overlay(alignment: .bottom) {
            applyButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SaveJobButton(job: job)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(job.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(job.agencyName)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Badge(text: job.type.rawValue, color: .blue)
                
                if job.remoteOption == .remote {
                    Badge(text: "Remote", color: .green, style: .outlined)
                } else if job.remoteOption == .hybrid {
                    Badge(text: "Hybrid", color: .orange, style: .outlined)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            JobDetailItem(icon: "mappin.and.ellipse", title: "Location", value: "\(job.location.city), \(job.location.state)")
            JobDetailItem(icon: "dollarsign.circle", title: "Salary", value: job.formattedSalary)
            JobDetailItem(icon: "clock", title: "Experience", value: job.experienceLevel)
            JobDetailItem(icon: "calendar", title: "Posted", value: "\(job.postedDateDisplay) (\(job.timeAgo))")
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Job Description")
                .font(.headline)
            
            Text(job.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requirements")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(job.requirements, id: \.self) { requirement in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                        
                        Text(requirement)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benefits")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(job.benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.subheadline)
                        
                        Text(benefit)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var applyButton: some View {
        VStack {
            if isApplied {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Application Submitted!")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.green)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding()
            } else {
                Button(action: {
                    withAnimation {
                        isApplied = true
                    }
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Apply Now")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct JobDetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}
