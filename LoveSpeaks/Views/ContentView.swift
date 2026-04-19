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
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(AppTab.home)
                SummaryView()
                    .tag(AppTab.summary)
                ProfileView()
                    .tag(AppTab.profile)
                ConfigView()
                    .tag(AppTab.config)
            }
            .onAppear {
                UITabBar.appearance().isHidden = true
            }

            FakeTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar

struct FakeTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(
                                selected == tab ? Color.lsSalmon : Color.lsSlate.opacity(0.5)
                            )
                        Text(tab.label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(
                                selected == tab ? Color.lsSalmon : Color.lsSlate.opacity(0.5)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(UIColor.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.black.opacity(0.07), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    ContentView()
}
