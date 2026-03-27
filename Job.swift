//
//  Job.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
enum JobType: String, Codable, CaseIterable {
    case fullTime = "Full-time"
    case partTime = "Part-time"
    case contract = "Contract"
    case tempToHire = "Temp-to-hire"
}

enum SalaryPeriod: String, Codable {
    case hourly = "hour"
    case yearly = "year"
}

enum RemoteOption: String, Codable {
    case remote = "Remote"
    case hybrid = "Hybrid"
    case onsite = "On-site"
}

struct Job: Identifiable, Codable, Hashable {
    let id: String
    let agencyId: String
    let agencyName: String
    let title: String
    let description: String
    let location: AgencyLocation
    let type: JobType
    let salaryMin: Int
    let salaryMax: Int
    let salaryPeriod: SalaryPeriod
    let experienceLevel: String
    let requirements: [String]
    let benefits: [String]
    let postedDate: Date
    let expiresDate: Date?
    let remoteOption: RemoteOption
    let applicationURL: String?
    
    var formattedSalary: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        let min = formatter.string(from: NSNumber(value: salaryMin)) ?? "$0"
        let max = formatter.string(from: NSNumber(value: salaryMax)) ?? "$0"
        
        if salaryPeriod == .hourly {
            return "\(min) - \(max)/hr"
        } else {
            let minK = salaryMin / 1000
            let maxK = salaryMax / 1000
            return "$\(minK)k - $\(maxK)k/yr"
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: postedDate, relativeTo: Date())
    }

    var postedDateDisplay: String {
        postedDate.formatted(date: .abbreviated, time: .omitted)
    }

    var isOpen: Bool {
        guard let expiresDate else { return true }
        return expiresDate >= Date()
    }
}
