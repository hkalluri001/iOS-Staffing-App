//
//  JobAPIServices.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation

import CoreLocation

class JobAPIService {
    static let shared = JobAPIService()
    
    // API Keys
    private let indeedClientID = "ind-7a8b9c0d-e1f2-3g4h-5i6j"
    private let zipRecruiterAPIKey = "abc123def456ghi789jkl012mno345pq"
    
    // Base URLs
    private let indeedBaseURL = "https://api.indeed.com/ads/apisearch"
    private let zipRecruiterBaseURL = "https://api.ziprecruiter.com/jobs/v1"
    
    // MARK: - Search Jobs from Multiple Sources
    
    func searchAllJobs(
        query: String,
        location: String = "USA",
        radius: Int = 25,
        jobType: JobTypeFilter = .all,
        remote: Bool = false,
        minSalary: Int? = nil
    ) async throws -> [UnifiedJobListing] {
        async let indeedJobs = searchIndeed(
            query: query,
            location: location,
            radius: radius,
            jobType: jobType,
            remote: remote
        )
        
        async let zipRecruiterJobs = searchZipRecruiter(
            query: query,
            location: location,
            radius: radius,
            jobType: jobType,
            remote: remote
        )
        
        let (indeedResults, zipResults) = try await (indeedJobs, zipRecruiterJobs)
        
        // Merge and deduplicate results
        var allJobs = indeedResults + zipResults
        allJobs.sort { $0.postedDate > $1.postedDate }
        
        // Apply salary filter if specified
        if let minSal = minSalary {
            allJobs = allJobs.filter { ($0.salaryMin ?? 0) >= minSal }
        }
        
        return allJobs
    }
    
    // MARK: - Indeed API
    
    private func searchIndeed(
        query: String,
        location: String,
        radius: Int,
        jobType: JobTypeFilter,
        remote: Bool
    ) async throws -> [UnifiedJobListing] {
        var components = URLComponents(string: indeedBaseURL)!
        
        components.queryItems = [
            URLQueryItem(name: "publisher", value: indeedClientID),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "l", value: location),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "jt", value: jobType.indeedCode),
            URLQueryItem(name: "remote", value: remote ? "1" : "0"),
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "v", value: "2")
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                // For demo, return mock data styled as Indeed results
                return mockIndeedJobs(query: query, location: location)
            }
            
            let indeedResponse = try JSONDecoder().decode(IndeedResponse.self, from: data)
            return indeedResponse.results.map { UnifiedJobListing(from: $0) }
            
        } catch {
            // Return mock data for demo
            return mockIndeedJobs(query: query, location: location)
        }
    }
    
    // MARK: - ZipRecruiter API
    
    private func searchZipRecruiter(
        query: String,
        location: String,
        radius: Int,
        jobType: JobTypeFilter,
        remote: Bool
    ) async throws -> [UnifiedJobListing] {
        var components = URLComponents(string: zipRecruiterBaseURL)!
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: zipRecruiterAPIKey),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "radius_miles", value: String(radius)),
            URLQueryItem(name: "jobs_per_page", value: "25"),
            URLQueryItem(name: "page", value: "1")
        ]
        
        if remote {
            components.queryItems?.append(URLQueryItem(name: "remote", value: "1"))
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                return mockZipRecruiterJobs(query: query, location: location)
            }
            
            let zipResponse = try JSONDecoder().decode(ZipRecruiterResponse.self, from: data)
            return zipResponse.jobs.map { UnifiedJobListing(from: $0) }
            
        } catch {
            return mockZipRecruiterJobs(query: query, location: location)
        }
    }
    
    // MARK: - Get Staffing Agencies
    
    func getStaffingAgencies(
        specialty: String? = nil,
        location: String? = nil,
        minRating: Double? = nil
    ) async throws -> [StaffingAgencyDetail] {
        // In production, this would query your backend
        // For demo, return enhanced mock agencies with real locations
        
        var agencies = mockStaffingAgencies()
        
        if let spec = specialty {
            agencies = agencies.filter {
                $0.specialties.contains(where: { $0.localizedCaseInsensitiveContains(spec) })
            }
        }
        
        if let loc = location, loc != "All USA" {
            agencies = agencies.filter {
                $0.locations.contains(where: { $0.state == loc || $0.city == loc })
            }
        }
        
        if let rating = minRating {
            agencies = agencies.filter { $0.rating >= rating }
        }
        
        return agencies
    }

    func getAgenciesHiring(role: String) async -> [Agency] {
        let normalizedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedRole.isEmpty else {
            return MockData.shared.agencies
        }

        return MockData.shared.agencies.filter { agency in
            agency.name.localizedCaseInsensitiveContains(normalizedRole) ||
            agency.specialties.contains(where: { $0.localizedCaseInsensitiveContains(normalizedRole) }) ||
            MockData.shared.jobs(forAgencyId: agency.id).contains { job in
                job.title.localizedCaseInsensitiveContains(normalizedRole) ||
                job.description.localizedCaseInsensitiveContains(normalizedRole)
            }
        }
    }

    func getOpenJobs() async -> [Job] {
        MockData.shared.jobs
            .filter(\.isOpen)
            .sorted { $0.postedDate > $1.postedDate }
    }

    func getOpenJobListings() async -> [UnifiedJobListing] {
        await getOpenJobs().map(UnifiedJobListing.init(from:))
    }

    func searchOpenJobs(
        query: String,
        role: String? = nil,
        location: String = "All USA",
        industry: Industry? = nil,
        minSalary: Double = 0,
        remoteOnly: Bool = false
    ) async -> [Job] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRole = role?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var jobs = MockData.shared.jobs.filter(\.isOpen)

        if !normalizedQuery.isEmpty {
            jobs = jobs.filter { job in
                job.title.localizedCaseInsensitiveContains(normalizedQuery) ||
                    job.description.localizedCaseInsensitiveContains(normalizedQuery) ||
                    job.agencyName.localizedCaseInsensitiveContains(normalizedQuery)
            }
        }

        if !normalizedRole.isEmpty {
            jobs = jobs.filter { job in
                job.title.localizedCaseInsensitiveContains(normalizedRole)
            }
        }

        if location != "All USA" {
            jobs = jobs.filter { job in
                if location == "Remote" {
                    return job.remoteOption == .remote
                }

                return job.location.state == location || job.location.city == location
            }
        }

        if let industry {
            jobs = jobs.filter { job in
                guard let agency = MockData.shared.agency(byId: job.agencyId) else { return false }

                return agency.specialties.contains { specialty in
                    specialty.localizedCaseInsensitiveContains(industry.rawValue)
                }
            }
        }

        if minSalary > 0 {
            jobs = jobs.filter { job in
                Double(job.salaryMax) >= minSalary * 1000
            }
        }

        if remoteOnly {
            jobs = jobs.filter { job in
                job.remoteOption == .remote || job.remoteOption == .hybrid
            }
        }

        return jobs.sorted { $0.postedDate > $1.postedDate }
    }

    func searchOpenJobListings(query: String) async -> [UnifiedJobListing] {
        await searchOpenJobs(query: query).map(UnifiedJobListing.init(from:))
    }
    
    // MARK: - Mock Data for Demo
    
    private func mockIndeedJobs(query: String, location: String) -> [UnifiedJobListing] {
        [
            UnifiedJobListing(
                id: "indeed-1",
                title: "Senior \(query) - Indeed",
                company: "TechStaff Pro",
                location: location == "USA" ? "San Francisco, CA" : location,
                salaryMin: 120000,
                salaryMax: 160000,
                salaryPeriod: .yearly,
                description: "Exciting opportunity for \(query) at leading tech company.",
                url: "https://indeed.com/job/1",
                postedDate: Date().addingTimeInterval(-86400),
                source: .indeed,
                jobType: .fullTime,
                remote: false,
                agencyId: "1"
            ),
            UnifiedJobListing(
                id: "indeed-2",
                title: "\(query) - Contract",
                company: "MedStaff Solutions",
                location: location == "USA" ? "New York, NY" : location,
                salaryMin: 70,
                salaryMax: 90,
                salaryPeriod: .hourly,
                description: "Contract position for experienced \(query).",
                url: "https://indeed.com/job/2",
                postedDate: Date().addingTimeInterval(-172800),
                source: .indeed,
                jobType: .contract,
                remote: true,
                agencyId: "2"
            ),
            UnifiedJobListing(
                id: "indeed-3",
                title: "Junior \(query)",
                company: "Finance First Recruiting",
                location: location == "USA" ? "Chicago, IL" : location,
                salaryMin: 60000,
                salaryMax: 80000,
                salaryPeriod: .yearly,
                description: "Entry level \(query) position with growth potential.",
                url: "https://indeed.com/job/3",
                postedDate: Date().addingTimeInterval(-259200),
                source: .indeed,
                jobType: .fullTime,
                remote: false,
                agencyId: "3"
            )
        ]
    }
    
    private func mockZipRecruiterJobs(query: String, location: String) -> [UnifiedJobListing] {
        [
            UnifiedJobListing(
                id: "zip-1",
                title: "Lead \(query) - ZipRecruiter",
                company: "TechStaff Pro",
                location: location == "USA" ? "Austin, TX" : location,
                salaryMin: 140000,
                salaryMax: 180000,
                salaryPeriod: .yearly,
                description: "Leadership role for \(query) professionals.",
                url: "https://ziprecruiter.com/job/1",
                postedDate: Date().addingTimeInterval(-43200),
                source: .zipRecruiter,
                jobType: .fullTime,
                remote: true,
                agencyId: "1"
            ),
            UnifiedJobListing(
                id: "zip-2",
                title: "\(query) Specialist",
                company: "MedStaff Solutions",
                location: location == "USA" ? "Los Angeles, CA" : location,
                salaryMin: 85000,
                salaryMax: 110000,
                salaryPeriod: .yearly,
                description: "Specialist \(query) role in healthcare.",
                url: "https://ziprecruiter.com/job/2",
                postedDate: Date().addingTimeInterval(-129600),
                source: .zipRecruiter,
                jobType: .partTime,
                remote: false,
                agencyId: "2"
            )
        ]
    }
    
    private func mockStaffingAgencies() -> [StaffingAgencyDetail] {
        [
            StaffingAgencyDetail(
                id: "1",
                name: "TechStaff Pro",
                logoURL: nil,
                rating: 4.5,
                reviewCount: 128,
                specialties: ["IT", "Engineering", "Design", "Product", "DevOps"],
                description: "Leading technology staffing agency with 20 years of experience placing top talent at Fortune 500 companies.",
                website: "https://techstaffpro.com",
                phone: "(555) 123-4567",
                email: "jobs@techstaffpro.com",
                locations: [
                    AgencyLocationDetail(
                        address: "123 Market Street, Suite 400",
                        city: "San Francisco",
                        state: "CA",
                        zipCode: "94105",
                        latitude: 37.7749,
                        longitude: -122.4194,
                        phone: "(415) 555-0100"
                    ),
                    AgencyLocationDetail(
                        address: "456 Congress Ave, Floor 12",
                        city: "Austin",
                        state: "TX",
                        zipCode: "78701",
                        latitude: 30.2672,
                        longitude: -97.7431,
                        phone: "(512) 555-0200"
                    ),
                    AgencyLocationDetail(
                        address: "789 Broadway, Tower 3",
                        city: "New York",
                        state: "NY",
                        zipCode: "10003",
                        latitude: 40.7128,
                        longitude: -74.0060,
                        phone: "(212) 555-0300"
                    )
                ],
                openJobsCount: 45,
                isVerified: true
            ),
            StaffingAgencyDetail(
                id: "2",
                name: "MedStaff Solutions",
                logoURL: nil,
                rating: 4.8,
                reviewCount: 256,
                specialties: ["Healthcare", "Nursing", "Medical", "Pharmacy", "Admin"],
                description: "Premier healthcare staffing serving hospitals nationwide. Specializing in travel nursing and permanent placements.",
                website: "https://medstaff.com",
                phone: "(555) 987-6543",
                email: "care@medstaff.com",
                locations: [
                    AgencyLocationDetail(
                        address: "789 Broadway, Medical Plaza",
                        city: "New York",
                        state: "NY",
                        zipCode: "10003",
                        latitude: 40.7128,
                        longitude: -74.0060,
                        phone: "(212) 555-0400"
                    ),
                    AgencyLocationDetail(
                        address: "321 Healthcare Blvd",
                        city: "Chicago",
                        state: "IL",
                        zipCode: "60611",
                        latitude: 41.8781,
                        longitude: -87.6298,
                        phone: "(312) 555-0500"
                    ),
                    AgencyLocationDetail(
                        address: "555 Sunset Blvd",
                        city: "Los Angeles",
                        state: "CA",
                        zipCode: "90028",
                        latitude: 34.0522,
                        longitude: -118.2437,
                        phone: "(323) 555-0600"
                    )
                ],
                openJobsCount: 128,
                isVerified: true
            ),
            StaffingAgencyDetail(
                id: "3",
                name: "Finance First Recruiting",
                logoURL: nil,
                rating: 4.2,
                reviewCount: 89,
                specialties: ["Finance", "Accounting", "Banking", "Insurance", "CPA"],
                description: "Connecting top financial talent with leading institutions. From entry-level analysts to C-suite executives.",
                website: "https://financefirst.com",
                phone: "(555) 456-7890",
                email: "talent@financefirst.com",
                locations: [
                    AgencyLocationDetail(
                        address: "321 Wall Street, Floor 45",
                        city: "New York",
                        state: "NY",
                        zipCode: "10005",
                        latitude: 40.7074,
                        longitude: -74.0113,
                        phone: "(212) 555-0700"
                    ),
                    AgencyLocationDetail(
                        address: "555 LaSalle Street, Suite 2000",
                        city: "Chicago",
                        state: "IL",
                        zipCode: "60602",
                        latitude: 41.8781,
                        longitude: -87.6298,
                        phone: "(312) 555-0800"
                    ),
                    AgencyLocationDetail(
                        address: "1000 Peachtree St NE",
                        city: "Atlanta",
                        state: "GA",
                        zipCode: "30309",
                        latitude: 33.7490,
                        longitude: -84.3880,
                        phone: "(404) 555-0900"
                    )
                ],
                openJobsCount: 32,
                isVerified: false
            ),
            StaffingAgencyDetail(
                id: "4",
                name: "Creative Talent Agency",
                logoURL: nil,
                rating: 4.6,
                reviewCount: 167,
                specialties: ["Design", "Marketing", "UX/UI", "Copywriting", "Creative"],
                description: "Specialized creative staffing for agencies and brands. Digital, print, and experiential marketing talent.",
                website: "https://creativetalent.com",
                phone: "(555) 234-5678",
                email: "hello@creativetalent.com",
                locations: [
                    AgencyLocationDetail(
                        address: "888 Creative Way",
                        city: "Los Angeles",
                        state: "CA",
                        zipCode: "90015",
                        latitude: 34.0407,
                        longitude: -118.2468,
                        phone: "(323) 555-1000"
                    ),
                    AgencyLocationDetail(
                        address: "444 Design District",
                        city: "Miami",
                        state: "FL",
                        zipCode: "33137",
                        latitude: 25.7617,
                        longitude: -80.1918,
                        phone: "(305) 555-1100"
                    )
                ],
                openJobsCount: 28,
                isVerified: true
            ),
            StaffingAgencyDetail(
                id: "5",
                name: "Engineering Staffing Co",
                logoURL: nil,
                rating: 4.4,
                reviewCount: 203,
                specialties: ["Engineering", "Manufacturing", "Construction", "Project Management"],
                description: "Technical staffing for engineering and manufacturing sectors. PE licensed professionals and project managers.",
                website: "https://engstaff.com",
                phone: "(555) 876-5432",
                email: "jobs@engstaff.com",
                locations: [
                    AgencyLocationDetail(
                        address: "2000 Industrial Pkwy",
                        city: "Houston",
                        state: "TX",
                        zipCode: "77001",
                        latitude: 29.7604,
                        longitude: -95.3698,
                        phone: "(713) 555-1200"
                    ),
                    AgencyLocationDetail(
                        address: "1500 Manufacturing Dr",
                        city: "Detroit",
                        state: "MI",
                        zipCode: "48201",
                        latitude: 42.3314,
                        longitude: -83.0458,
                        phone: "(313) 555-1300"
                    )
                ],
                openJobsCount: 56,
                isVerified: true
            )
        ]
    }
}

// MARK: - API Response Models

struct IndeedResponse: Codable {
    let results: [IndeedJob]
}

struct IndeedJob: Codable {
    let jobtitle: String
    let company: String
    let formattedLocation: String
    let snippet: String
    let url: String
    let date: String
    let jobkey: String
}

struct ZipRecruiterResponse: Codable {
    let jobs: [ZipRecruiterJob]
}

struct ZipRecruiterJob: Codable {
    let name: String
    let hiring_company: ZipCompany
    let location: String
    let snippet: String
    let url: String
    let posted_time: String
    let job_type: String?
}

struct ZipCompany: Codable {
    let name: String
}

// MARK: - Unified Models

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

enum JobSource: String, Codable {
    case indeed = "Indeed"
    case zipRecruiter = "ZipRecruiter"
}

enum JobTypeFilter: String, CaseIterable {
    case all = "All Types"
    case fullTime = "Full-time"
    case partTime = "Part-time"
    case contract = "Contract"
    case internship = "Internship"
    case temporary = "Temporary"
    
    var indeedCode: String {
        switch self {
        case .all: return ""
        case .fullTime: return "fulltime"
        case .partTime: return "parttime"
        case .contract: return "contract"
        case .internship: return "internship"
        case .temporary: return "temporary"
        }
    }
}

struct UnifiedJobListing: Identifiable, Codable {
    let id: String
    let title: String
    let company: String
    let location: String
    let salaryMin: Int?
    let salaryMax: Int?
    let salaryPeriod: SalaryPeriod
    let description: String
    let url: String
    let postedDate: Date
    let source: JobSource
    let jobType: JobType
    let remote: Bool
    let agencyId: String
    
    var formattedSalary: String? {
        guard let min = salaryMin, let max = salaryMax else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        if salaryPeriod == .hourly {
            return "$\(min)-\(max)/hr"
        } else {
            let minK = min / 1000
            let maxK = max / 1000
            return "$\(minK)k-$\(maxK)k"
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        // Return approximate coordinate based on location string
        LocationDatabase.shared.coordinate(for: location)
    }
}

struct StaffingAgencyDetail: Identifiable, Codable {
    let id: String
    let name: String
    let logoURL: String?
    let rating: Double
    let reviewCount: Int
    let specialties: [String]
    let description: String
    let website: String
    let phone: String
    let email: String
    let locations: [AgencyLocationDetail]
    let openJobsCount: Int
    let isVerified: Bool
    
    var allCoordinates: [CLLocationCoordinate2D] {
        locations.map { $0.coordinate }
    }
}

struct AgencyLocationDetail: Codable, Identifiable {
    let id = UUID()
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let latitude: Double
    let longitude: Double
    let phone: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var fullAddress: String {
        "\(address), \(city), \(state) \(zipCode)"
    }
}

// Location database for geocoding
class LocationDatabase {
    static let shared = LocationDatabase()
    
    private let locations: [String: CLLocationCoordinate2D] = [
        "San Francisco, CA": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        "New York, NY": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        "Austin, TX": CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
        "Chicago, IL": CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
        "Los Angeles, CA": CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        "Houston, TX": CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698),
        "Miami, FL": CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918),
        "Atlanta, GA": CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
        "Detroit, MI": CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458)
    ]
    
    func coordinate(for location: String) -> CLLocationCoordinate2D? {
        // Try exact match first
        if let exact = locations[location] {
            return exact
        }
        
        // Try partial match
        for (key, coord) in locations {
            if location.contains(key) || key.contains(location) {
                return coord
            }
        }
        
        return nil
    }
}

// Extensions for UnifiedJobListing
extension UnifiedJobListing {
    init(from job: Job) {
        self.id = job.id
        self.title = job.title
        self.company = job.agencyName
        self.location = "\(job.location.city), \(job.location.state)"
        self.salaryMin = job.salaryMin
        self.salaryMax = job.salaryMax
        self.salaryPeriod = job.salaryPeriod
        self.description = job.description
        self.url = job.applicationURL ?? ""
        self.postedDate = job.postedDate
        self.source = .indeed
        self.jobType = job.type
        self.remote = job.remoteOption == .remote || job.remoteOption == .hybrid
        self.agencyId = job.agencyId
    }

    init(from indeedJob: IndeedJob) {
        self.id = "indeed-\(indeedJob.jobkey)"
        self.title = indeedJob.jobtitle
        self.company = indeedJob.company
        self.location = indeedJob.formattedLocation
        self.salaryMin = nil
        self.salaryMax = nil
        self.salaryPeriod = .yearly
        self.description = indeedJob.snippet
        self.url = indeedJob.url
        self.postedDate = Date() // Parse from indeedJob.date
        self.source = .indeed
        self.jobType = .fullTime
        self.remote = false
        self.agencyId = "unknown"
    }
    
    init(from zipJob: ZipRecruiterJob) {
        self.id = "zip-\(zipJob.name.hashValue)"
        self.title = zipJob.name
        self.company = zipJob.hiring_company.name
        self.location = zipJob.location
        self.salaryMin = nil
        self.salaryMax = nil
        self.salaryPeriod = .yearly
        self.description = zipJob.snippet
        self.url = zipJob.url
        self.postedDate = Date() // Parse from zipJob.posted_time
        self.source = .zipRecruiter
        self.jobType = .fullTime
        self.remote = false
        self.agencyId = "unknown"
    }
}
