//
//  ContentView.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            SummaryView()
                .tabItem { Label("Summary", systemImage: "book.fill") }
                .tag(1)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(2)
            
            ConfigView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .tint(.purple) // matches your app's color palette
    }
}

#Preview {
    ContentView()
}
