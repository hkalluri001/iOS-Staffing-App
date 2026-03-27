//
//  MockData.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
class MockData {
    static let shared = MockData()
    
    let agencies: [Agency] = [
        Agency(
            id: "1",
            name: "Key Business Solutions, inc",
            logoURL: nil,
            rating: 4.5,
            reviewCount: 128,
            specialties: ["IT", "Engineering", "Design", "Product"],
            description: "Leading technology staffing agency with 20 years of experience placing top talent at Fortune 500 companies and innovative startups alike.",
            website: "https://techstaffpro.com",
            phone: "(555) 123-4567",
            email: "jobs@techstaffpro.com",
            foundedYear: 2004,
            employeeCount: "500-1000",
            isVerified: true,
            locations: [
                AgencyLocation(
                    address: "123 Market Street",
                    city: "San Francisco",
                    state: "CA",
                    zipCode: "94105",
                    latitude: 37.7749,
                    longitude: -122.4194
                ),
                AgencyLocation(
                    address: "456 Congress Ave",
                    city: "Austin",
                    state: "TX",
                    zipCode: "78701",
                    latitude: 30.2672,
                    longitude: -97.7431
                )
            ]
        ),
        Agency(
            id: "2",
            name: "MedStaff Solutions",
            logoURL: nil,
            rating: 4.8,
            reviewCount: 256,
            specialties: ["Healthcare", "Nursing", "Medical", "Pharmacy"],
            description: "Premier healthcare staffing serving hospitals nationwide. Specializing in travel nursing and permanent placements.",
            website: "https://medstaff.com",
            phone: "(555) 987-6543",
            email: "care@medstaff.com",
            foundedYear: 1998,
            employeeCount: "1000+",
            isVerified: true,
            locations: [
                AgencyLocation(
                    address: "789 Broadway",
                    city: "New York",
                    state: "NY",
                    zipCode: "10003",
                    latitude: 40.7128,
                    longitude: -74.0060
                )
            ]
        ),
        Agency(
            id: "3",
            name: "Finance First Recruiting",
            logoURL: nil,
            rating: 4.2,
            reviewCount: 89,
            specialties: ["Finance", "Accounting", "Banking"],
            description: "Connecting top financial talent with leading institutions. From entry-level analysts to C-suite executives.",
            website: "https://financefirst.com",
            phone: "(555) 456-7890",
            email: "talent@financefirst.com",
            foundedYear: 2010,
            employeeCount: "100-500",
            isVerified: false,
            locations: [
                AgencyLocation(
                    address: "321 Wall Street",
                    city: "New York",
                    state: "NY",
                    zipCode: "10005",
                    latitude: 40.7074,
                    longitude: -74.0113
                ),
                AgencyLocation(
                    address: "555 LaSalle Street",
                    city: "Chicago",
                    state: "IL",
                    zipCode: "60602",
                    latitude: 41.8781,
                    longitude: -87.6298
                )
            ]
        )
    ]
    
    let jobs: [Job] = [
        Job(
            id: "101",
            agencyId: "1",
            agencyName: "Key Business Solutions, Inc.",
            title: "Senior iOS Developer",
            description: "We are seeking an experienced iOS developer to lead mobile development for our client's fintech application. You'll work with SwiftUI, Combine, and modern iOS architecture patterns.",
            location: AgencyLocation(
                address: "123 Market Street",
                city: "San Francisco",
                state: "CA",
                zipCode: "94105",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            type: .fullTime,
            salaryMin: 150000,
            salaryMax: 200000,
            salaryPeriod: .yearly,
            experienceLevel: "5+ years",
            requirements: [
                "5+ years iOS development experience",
                "Strong Swift and SwiftUI skills",
                "Experience with Combine and async/await",
                "Published apps on App Store",
                "BS in Computer Science or equivalent"
            ],
            benefits: [
                "Comprehensive health insurance",
                "401(k) matching",
                "Unlimited PTO",
                "Remote work options",
                "Annual conference budget"
            ],
            postedDate: Date().addingTimeInterval(-86400 * 2),
            expiresDate: Date().addingTimeInterval(86400 * 28),
            remoteOption: .hybrid,
            applicationURL: "https://techstaffpro.com/apply/101"
        ),
        Job(
            id: "102",
            agencyId: "1",
            agencyName: "TechStaff Pro",
            title: "UX/UI Designer",
            description: "Design beautiful, intuitive interfaces for mobile and web applications. Collaborate with product and engineering teams to deliver exceptional user experiences.",
            location: AgencyLocation(
                address: "456 Congress Ave",
                city: "Austin",
                state: "TX",
                zipCode: "78701",
                latitude: 30.2672,
                longitude: -97.7431
            ),
            type: .contract,
            salaryMin: 70,
            salaryMax: 90,
            salaryPeriod: .hourly,
            experienceLevel: "3-5 years",
            requirements: [
                "Portfolio demonstrating strong visual design",
                "Proficiency in Figma and design systems",
                "Experience with prototyping tools",
                "Understanding of iOS and Android design guidelines"
            ],
            benefits: [
                "Flexible schedule",
                "Equipment provided",
                "Potential for conversion to full-time"
            ],
            postedDate: Date().addingTimeInterval(-86400 * 5),
            expiresDate: Date().addingTimeInterval(86400 * 25),
            remoteOption: .remote,
            applicationURL: nil
        ),
        Job(
            id: "201",
            agencyId: "2",
            agencyName: "MedStaff Solutions",
            title: "ICU Registered Nurse",
            description: "Full-time ICU RN position at Level I Trauma Center. 12-hour shifts, 3 days per week. Competitive pay and comprehensive benefits package.",
            location: AgencyLocation(
                address: "789 Broadway",
                city: "New York",
                state: "NY",
                zipCode: "10003",
                latitude: 40.7128,
                longitude: -74.0060
            ),
            type: .fullTime,
            salaryMin: 95000,
            salaryMax: 130000,
            salaryPeriod: .yearly,
            experienceLevel: "2+ years ICU",
            requirements: [
                "Active NY RN license",
                "BLS and ACLS certification",
                "2+ years ICU experience",
                "BSN preferred",
                "COVID-19 vaccination"
            ],
            benefits: [
                "Sign-on bonus up to $20,000",
                "Student loan repayment",
                "Relocation assistance",
                "Health, dental, vision",
                "Tuition reimbursement"
            ],
            postedDate: Date().addingTimeInterval(-86400),
            expiresDate: Date().addingTimeInterval(86400 * 30),
            remoteOption: .onsite,
            applicationURL: "https://medstaff.com/jobs/201"
        )
    ]
    
    func jobs(forAgencyId agencyId: String) -> [Job] {
        jobs.filter { $0.agencyId == agencyId }
    }
    
    func agency(byId id: String) -> Agency? {
        agencies.first { $0.id == id }
    }
}
