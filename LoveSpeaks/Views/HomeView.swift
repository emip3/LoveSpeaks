//
//  HomeView.swift
//  LoveSpeaks
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 60)
                Spacer()
                detectionCircle
                    .padding(.horizontal, 40)
                Spacer()
                bottomSection
                    .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea()
        .alert("Something went wrong",
               isPresented: $viewModel.showingError,
               presenting: viewModel.errorMessage) { _ in
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Dismiss", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.10)
                .ignoresSafeArea()
            RadialGradient(
                colors: [
                    viewModel.currentSound.primaryColor.opacity(
                        viewModel.isListening ? 0.18 : 0.05
                    ),
                    Color.clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 420
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.2), value: viewModel.currentSound.category)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("LoveSpeaks")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Baby Sound Monitor")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
        }
    }

    // MARK: - Detection Circle

    private var detectionCircle: some View {
        ZStack {
            if viewModel.isListening {
                Circle()
                    .stroke(viewModel.currentSound.primaryColor.opacity(0.25), lineWidth: 2)
                    .scaleEffect(viewModel.isPulsing ? 1.18 : 1.0)
                    .animation(.easeInOut(duration: 1.1), value: viewModel.isPulsing)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [viewModel.currentSound.secondaryColor, Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 160
                    )
                )
                .animation(.easeInOut(duration: 0.8), value: viewModel.currentSound.category)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            viewModel.currentSound.primaryColor,
                            viewModel.currentSound.primaryColor.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1.5))
                .shadow(
                    color: viewModel.currentSound.primaryColor.opacity(0.5),
                    radius: 30, x: 0, y: 0
                )
                .padding(24)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7),
                    value: viewModel.currentSound.category
                )

            VStack(spacing: 10) {
                Text(viewModel.currentSound.displayEmoji)
                    .font(.system(size: 62))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                Text(viewModel.currentSound.displayTitle)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.currentSound.category)
        }
        .frame(width: 300, height: 300)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 24) {
            if viewModel.isListening && viewModel.currentSound.category != .quiet {
                sourceIndicator
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Text(viewModel.statusText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .animation(.easeInOut(duration: 0.3), value: viewModel.statusText)

            toggleButton
        }
    }

    private var sourceIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.currentSound.primaryColor)
                .frame(width: 7, height: 7)
            Text(viewModel.currentSound.source.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.60))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
    }

    private var toggleButton: some View {
        Button(action: { viewModel.toggleListening() }) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.buttonIcon)
                    .font(.system(size: 16, weight: .semibold))
                Text(viewModel.buttonLabel)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(width: 220, height: 54)
            .background(
                Capsule()
                    .fill(
                        viewModel.isListening
                            ? Color.white.opacity(0.12)
                            : viewModel.currentSound.primaryColor.opacity(0.85)
                    )
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            )
            .shadow(
                color: viewModel.isListening
                    ? Color.clear
                    : viewModel.currentSound.primaryColor.opacity(0.4),
                radius: 16, x: 0, y: 6
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isListening)
    }
}

#Preview { HomeView() }
