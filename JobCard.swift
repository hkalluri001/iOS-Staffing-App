//
//  JobCard.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI

struct JobCard: View {
    let job: Job
    var compact: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                
                if !compact {
                    HStack(spacing: 16) {
                        DetailItem(icon: "mappin", text: "\(job.location.city), \(job.location.state)")
                        DetailItem(icon: "dollarsign.circle", text: job.formattedSalary)
                        DetailItem(icon: "briefcase", text: job.experienceLevel)
                    }
                }
                
                HStack {
                    Badge(text: job.type.rawValue, color: .blue)
                    
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
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .overlay(
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 4),
                        alignment: .leading
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DetailItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
