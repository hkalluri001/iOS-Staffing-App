import Foundation
import Testing
@testable import StaffingAgencyApp

struct JobModelTests {
    @Test func formattedSalaryShowsHourlyRangeWithHrSuffix() {
        let job = makeJob(salaryMin: 70, salaryMax: 90, salaryPeriod: .hourly)

        #expect(job.formattedSalary.contains("/hr"))
        #expect(job.formattedSalary.contains("70"))
        #expect(job.formattedSalary.contains("90"))
    }

    @Test func formattedSalaryYearlyUsesKSuffix() {
        let job = makeJob(salaryMin: 120_000, salaryMax: 160_000, salaryPeriod: .yearly)

        #expect(job.formattedSalary.contains("120k"))
        #expect(job.formattedSalary.contains("160k"))
        #expect(job.formattedSalary.contains("/yr"))
    }

    @Test func isOpenReturnsTrueWhenExpiresDateIsNil() {
        let job = makeJob(expiresDate: nil)

        #expect(job.isOpen)
    }

    @Test func isOpenReturnsTrueWhenExpiresDateIsInFuture() {
        let job = makeJob(expiresDate: Date().addingTimeInterval(86_400))

        #expect(job.isOpen)
    }

    @Test func isOpenReturnsFalseWhenExpiresDateIsInPast() {
        let job = makeJob(expiresDate: Date().addingTimeInterval(-1))

        #expect(job.isOpen == false)
    }

    @Test func timeAgoIsNonEmptyForRecentDates() {
        let job = makeJob(postedDate: Date().addingTimeInterval(-3_600))

        #expect(job.timeAgo.isEmpty == false)
    }

    @Test func postedDateDisplayIsNonEmpty() {
        let job = makeJob()

        #expect(job.postedDateDisplay.isEmpty == false)
    }

    @Test func remoteOptionRawValuesMatchExpectedStrings() {
        #expect(RemoteOption.remote.rawValue == "Remote")
        #expect(RemoteOption.hybrid.rawValue == "Hybrid")
        #expect(RemoteOption.onsite.rawValue == "On-site")
    }

    @Test func jobTypeRawValuesMatchExpectedStrings() {
        #expect(JobType.fullTime.rawValue == "Full-time")
        #expect(JobType.partTime.rawValue == "Part-time")
        #expect(JobType.contract.rawValue == "Contract")
        #expect(JobType.tempToHire.rawValue == "Temp-to-hire")
    }

    private func makeJob(
        salaryMin: Int = 100_000,
        salaryMax: Int = 130_000,
        salaryPeriod: SalaryPeriod = .yearly,
        postedDate: Date = Date(),
        expiresDate: Date? = Date().addingTimeInterval(86_400 * 30)
    ) -> Job {
        Job(
            id: "test-job",
            agencyId: "1",
            agencyName: "Test Agency",
            title: "Test Role",
            description: "Test description",
            location: AgencyLocation(
                address: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94105",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            type: .fullTime,
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            salaryPeriod: salaryPeriod,
            experienceLevel: "3+ years",
            requirements: ["Requirement 1"],
            benefits: ["Benefit 1"],
            postedDate: postedDate,
            expiresDate: expiresDate,
            remoteOption: .hybrid,
            applicationURL: nil
        )
    }
}

struct MockDataTests {
    @Test func sharedAgenciesAreNonEmpty() {
        #expect(MockData.shared.agencies.isEmpty == false)
    }

    @Test func sharedJobsAreNonEmpty() {
        #expect(MockData.shared.jobs.isEmpty == false)
    }

    @Test func jobsForAgencyIDReturnsOnlyMatchingJobs() {
        let jobs = MockData.shared.jobs(forAgencyId: "1")

        #expect(jobs.allSatisfy { $0.agencyId == "1" })
    }

    @Test func jobsForUnknownAgencyIDReturnsEmptyArray() {
        let jobs = MockData.shared.jobs(forAgencyId: "missing")

        #expect(jobs.isEmpty)
    }

    @Test func agencyByIDReturnsCorrectAgency() {
        let agency = MockData.shared.agency(byId: "1")

        #expect(agency?.id == "1")
    }

    @Test func agencyByIDReturnsNilForUnknownID() {
        let agency = MockData.shared.agency(byId: "missing")

        #expect(agency == nil)
    }

    @Test func allMockJobsHaveNonEmptyTitles() {
        for job in MockData.shared.jobs {
            #expect(job.title.isEmpty == false)
        }
    }

    @Test func allMockAgenciesHaveAtLeastOneLocation() {
        for agency in MockData.shared.agencies {
            #expect(agency.locations.isEmpty == false)
        }
    }

    @Test func allMockAgenciesHaveValidRatings() {
        for agency in MockData.shared.agencies {
            #expect(agency.rating >= 0)
            #expect(agency.rating <= 5)
        }
    }
}

struct JobAPIServiceTests {
    @Test func searchOpenJobsWithEmptyQueryReturnsAllOpenJobs() async {
        let allOpenJobs = await JobAPIService.shared.getOpenJobs()
        let searchedJobs = await JobAPIService.shared.searchOpenJobs(query: "")

        #expect(searchedJobs.count == allOpenJobs.count)
    }

    @Test func searchOpenJobsFiltersBySearchText() async {
        let results = await JobAPIService.shared.searchOpenJobs(query: "iOS Developer")

        for job in results {
            let matches = await MainActor.run {
                job.title.localizedCaseInsensitiveContains("iOS Developer") ||
                    job.agencyName.localizedCaseInsensitiveContains("iOS Developer") ||
                    job.description.localizedCaseInsensitiveContains("iOS Developer")
            }

            #expect(matches)
        }
    }

    @Test func searchOpenJobsWithRemoteOnlyReturnsRemoteOrHybridJobs() async {
        let results = await JobAPIService.shared.searchOpenJobs(query: "", remoteOnly: true)

        for job in results {
            let isRemoteOrHybrid = await MainActor.run {
                job.remoteOption == .remote || job.remoteOption == .hybrid
            }

            #expect(isRemoteOrHybrid)
        }
    }

    @Test func searchOpenJobsWithMinSalaryFiltersOutLowerSalaryJobs() async {
        let minSalary: Double = 100
        let results = await JobAPIService.shared.searchOpenJobs(query: "", minSalary: minSalary)

        for job in results {
            let salaryMax = await MainActor.run { job.salaryMax }
            #expect(Double(salaryMax) >= minSalary * 1_000)
        }
    }

    @Test func getOpenJobsReturnsOnlyOpenJobs() async {
        let jobs = await JobAPIService.shared.getOpenJobs()

        let areAllOpen = await MainActor.run {
            jobs.allSatisfy(\.isOpen)
        }

        #expect(areAllOpen)
    }

    @Test func getOpenJobsAreSortedMostRecentFirst() async {
        let jobs = await JobAPIService.shared.getOpenJobs()
        let dates = await MainActor.run {
            jobs.map { $0.postedDate }
        }

        #expect(zip(dates, dates.dropFirst()).allSatisfy { $0 >= $1 })
    }

    @Test func getAgenciesHiringWithEmptyRoleReturnsAllAgencies() async {
        let agencies = await JobAPIService.shared.getAgenciesHiring(role: "")

        #expect(agencies.count == MockData.shared.agencies.count)
    }

    @Test func getOpenJobListingsMapsJobsToUnifiedListings() async {
        let listings = await JobAPIService.shared.getOpenJobListings()
        let openJobs = await JobAPIService.shared.getOpenJobs()

        #expect(listings.count == openJobs.count)
    }
}

struct UnifiedJobListingTests {
    @Test func initFromJobPreservesID() {
        let job = makeSampleJob()
        let listing = UnifiedJobListing(from: job)

        #expect(listing.id == job.id)
    }

    @Test func initFromJobPreservesTitle() {
        let job = makeSampleJob()
        let listing = UnifiedJobListing(from: job)

        #expect(listing.title == job.title)
    }

    @Test func initFromJobPreservesCompanyName() {
        let job = makeSampleJob()
        let listing = UnifiedJobListing(from: job)

        #expect(listing.company == job.agencyName)
    }

    @Test func initFromJobFormatsLocationAsCityAndState() {
        let job = makeSampleJob()
        let listing = UnifiedJobListing(from: job)

        #expect(listing.location.contains(job.location.city))
        #expect(listing.location.contains(job.location.state))
    }

    @Test func initFromJobSetsRemoteCorrectly() {
        #expect(UnifiedJobListing(from: makeSampleJob(remoteOption: .remote)).remote)
        #expect(UnifiedJobListing(from: makeSampleJob(remoteOption: .hybrid)).remote)
        #expect(UnifiedJobListing(from: makeSampleJob(remoteOption: .onsite)).remote == false)
    }

    @Test func formattedSalaryIsNonNilWhenMinAndMaxExist() {
        let listing = UnifiedJobListing(from: makeSampleJob())

        #expect(listing.formattedSalary != nil)
    }

    private func makeSampleJob(remoteOption: RemoteOption = .hybrid) -> Job {
        Job(
            id: "listing-test",
            agencyId: "1",
            agencyName: "Sample Agency",
            title: "Backend Engineer",
            description: "Build APIs.",
            location: AgencyLocation(
                address: "1 Market St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94105",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            type: .fullTime,
            salaryMin: 120_000,
            salaryMax: 160_000,
            salaryPeriod: .yearly,
            experienceLevel: "3+ years",
            requirements: [],
            benefits: [],
            postedDate: Date(),
            expiresDate: Date().addingTimeInterval(86_400 * 30),
            remoteOption: remoteOption,
            applicationURL: nil
        )
    }
}

struct LocationManagerTests {
    @Test func distanceReturnsNilWhenUserLocationIsUnknown() {
        let locationManager = LocationManager()
        let location = AgencyLocation(
            address: "123 Main",
            city: "Austin",
            state: "TX",
            zipCode: "78701",
            latitude: 30.2672,
            longitude: -97.7431
        )

        #expect(locationManager.distance(to: location) == nil)
    }
}
