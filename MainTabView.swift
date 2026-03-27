//
//  MainTabView.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "building.2.fill")
                Text("Agencies")
            }
            .tag(0)
            
            AgencyMapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(1)
            
            JobSearchView()
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("Jobs")
                }
                .tag(2)
            
            SavedJobsView()
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Saved")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

struct JobSearchView: View {
    var body: some View {
        NavigationStack {
            AdvancedSearchView()
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let user = loginViewModel.currentUser {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(user.email)
                        .foregroundColor(.secondary)
                } else {
                    Text("Profile")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Button("Log Out") {
                    loginViewModel.logout()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
        }
    }
}
