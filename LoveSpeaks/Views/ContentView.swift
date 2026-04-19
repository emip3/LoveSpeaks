//
//  ContentView.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

import SwiftUI

enum AppTab: Int, CaseIterable {
    case home, summary, profile, config

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .summary: return "doc.text.fill"
        case .profile: return "person.fill"
        case .config:  return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .home:    return "Inicio"
        case .summary: return "Resumen"
        case .profile: return "Perfil"
        case .config:  return "Config"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            
            HomeView()
                .tabItem {
                    Label(AppTab.home.label, systemImage: AppTab.home.icon)
                }
                .tag(AppTab.home)

            SummaryView()
                .tabItem {
                    Label(AppTab.summary.label, systemImage: AppTab.summary.icon)
                }
                .tag(AppTab.summary)

            ProfileView()
                .tabItem {
                    Label(AppTab.profile.label, systemImage: AppTab.profile.icon)
                }
                .tag(AppTab.profile)

            ConfigView()
                .tabItem {
                    Label(AppTab.config.label, systemImage: AppTab.config.icon)
                }
                .tag(AppTab.config)
        }
        // ESTA ES LA MAGIA: Cambia el color de acento de toda la barra
        .accentColor(Color.lsSalmon)
        .onAppear {
            // Esto asegura que la barra tenga el material translúcido estándar de Apple
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
