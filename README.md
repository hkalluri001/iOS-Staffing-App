# iOS Staffing App

`iOS Staffing App` is a SwiftUI application for discovering staffing agencies and open jobs across the USA. It includes agency search, job search, map browsing, mock authentication, and a small `Testing`-based unit test suite.

## Features

- Browse staffing agencies with ratings, specialties, and location coverage
- Search agencies by name or specialty
- Search open jobs and view agency name, location, salary, and posted date
- Switch between agency and job search from the main home screen
- Explore agencies on a map
- View agency details and job details
- Mock login, sign up, social sign-in, and profile/logout flow
- Basic unit tests for `Agency` and `AgencyLocation` formatting behavior

## Tech Stack

- `Swift`
- `SwiftUI`
- `CoreLocation`
- Apple `Testing` framework
- Xcode project with local mock data and service abstractions

## Project Structure

```text
StaffingAgencyApp/
├── StaffingAgencyApp/
│   ├── Models/
│   ├── Sevices/
│   ├── Views/
│   │   ├── Auth/
│   │   ├── Componets/
│   │   └── Screen/
│   ├── Assets.xcassets
│   └── StaffingAgencyAppApp.swift
├── StaffingAgencyAppTests/
│   └── AgencyTests.swift
└── StaffingAgencyApp.xcodeproj
```

## Main Screens

- `LoginView`: mock authentication entry point
- `HomeView`: main discovery screen for agencies and jobs
- `AdvancedSearchView`: dedicated jobs search experience
- `AgencyMapView`: map-based agency exploration
- `AgencyDetailView` / `JobDetailView`: detailed entity views
- `MainTabView`: tab-based app navigation

## Data Flow

- `MockData.swift` provides local agencies and job listings for development
- `JobAPIServices.swift` contains service methods for:
  - loading staffing agencies
  - loading open jobs
  - filtering job results
  - converting mock job models into unified listing models where needed

## Requirements

- macOS with Xcode installed
- iOS Simulator or physical iOS device
- Swift toolchain bundled with Xcode

## Getting Started

1. Open [StaffingAgencyApp.xcodeproj](/Users/harshithkalluri/Downloads/StaffingAgencyApp/StaffingAgencyApp.xcodeproj) in Xcode.
2. Select the `StaffingAgencyApp` scheme.
3. Choose an iPhone simulator.
4. Build and run the app.

## Running Tests

The project includes a `StaffingAgencyAppTests` target using the Apple `Testing` framework.

In Xcode:

1. Select the `StaffingAgencyApp` scheme.
2. Press `Cmd+U` to run tests.

Current tests cover:

- rating formatting in `Agency`
- specialty display formatting in `Agency`
- full address formatting in `AgencyLocation`
- latitude/longitude mapping in `AgencyLocation`

## Notes

- The app currently uses mock data and mock authentication flows.
- Some folder names in the project are intentionally kept as-is from the current codebase, including `Sevices` and `Componets`.
- Job and agency search behavior is currently optimized for local development data rather than a live backend.

## Future Improvements

- Replace mock authentication with a real auth provider
- Connect job and agency search to a production backend
- Add saved jobs persistence
- Expand automated test coverage for service and view-model logic
- Add UI tests for core navigation and search flows
