import Foundation
import Testing
@testable import StaffingAgencyApp

struct AgencyTests {
    @Test func averageRatingRoundsToSingleDecimalPlace() {
        let agency = makeAgency(rating: 4.56)

        #expect(agency.averageRating == "4.6")
    }

    @Test func averageRatingPreservesTrailingZeroForWholeNumbers() {
        let agency = makeAgency(rating: 4.0)

        #expect(agency.averageRating == "4.0")
    }

    @Test func displaySpecialtiesReturnsEmptyStringWhenNoSpecialtiesExist() {
        let agency = makeAgency(specialties: [])

        #expect(agency.displaySpecialties.isEmpty)
    }

    @Test func displaySpecialtiesShowsSingleSpecialtyWithoutSeparators() {
        let agency = makeAgency(specialties: ["IT"])

        #expect(agency.displaySpecialties == "IT")
    }

    @Test func displaySpecialtiesLimitsOutputToFirstThreeItems() {
        let agency = makeAgency(specialties: ["IT", "Healthcare", "Finance", "Design"])

        #expect(agency.displaySpecialties == "IT • Healthcare • Finance")
    }

    @Test func fullAddressCombinesAllLocationFieldsInExpectedOrder() {
        let location = AgencyLocation(
            address: "123 Market Street",
            city: "San Francisco",
            state: "CA",
            zipCode: "94105",
            latitude: 37.7749,
            longitude: -122.4194
        )

        #expect(location.fullAddress == "123 Market Street, San Francisco, CA 94105")
    }

    @Test func coordinateMapsLatitudeAndLongitudeDirectly() {
        let location = AgencyLocation(
            address: "456 Congress Ave",
            city: "Austin",
            state: "TX",
            zipCode: "78701",
            latitude: 30.2672,
            longitude: -97.7431
        )

        #expect(location.coordinate.latitude == 30.2672)
        #expect(location.coordinate.longitude == -97.7431)
    }

    private func makeAgency(
        rating: Double = 4.5,
        specialties: [String] = ["IT", "Healthcare", "Finance"]
    ) -> Agency {
        Agency(
            id: "agency-1",
            name: "Test Agency",
            logoURL: nil,
            rating: rating,
            reviewCount: 10,
            specialties: specialties,
            description: "Test description",
            website: "https://example.com",
            phone: "(555) 111-2222",
            email: "test@example.com",
            foundedYear: 2020,
            employeeCount: "10-50",
            isVerified: true,
            locations: [
                AgencyLocation(
                    address: "123 Main St",
                    city: "San Jose",
                    state: "CA",
                    zipCode: "95112",
                    latitude: 37.3382,
                    longitude: -121.8863
                )
            ]
        )
    }
}
