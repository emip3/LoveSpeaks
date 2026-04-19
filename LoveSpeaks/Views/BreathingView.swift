//
//  BreathingView.swift
//  LoveSpeaks
//

import SwiftUI

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BreathingViewModel()

    var body: some View {
        ZStack {
            Color.lsSky.ignoresSafeArea()

            if viewModel.finished {
                BreathingFinishView { dismiss() }
            } else {
                activeBreathingContent
            }
        }
        .onAppear { viewModel.startCycles() }
    }

    // MARK: - Active Breathing Content

    private var activeBreathingContent: some View {
        VStack(spacing: 0) {
            dismissButton
            Spacer()
            breathCircle
            subtextLabel
            progressDots
            Spacer()
        }
    }

    private var dismissButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
    }

    private var breathCircle: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 200, height: 200)
                .scaleEffect(viewModel.scale * 1.05)

            Circle()
                .fill(Color.white.opacity(0.20))
                .frame(width: 155, height: 155)
                .scaleEffect(viewModel.scale)

            Circle()
                .fill(Color.white.opacity(0.60))
                .frame(width: 105, height: 105)
                .overlay(
                    Text(viewModel.phase.rawValue)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.29, green: 0.48, blue: 0.50))
                )
                .scaleEffect(viewModel.scale)
        }
        .animation(.easeInOut(duration: viewModel.phaseDuration), value: viewModel.scale)
    }

    private var subtextLabel: some View {
        Text(viewModel.subText)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(Color.white.opacity(0.78))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.top, 28)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.totalCycles, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(i < viewModel.cycleCount ? 1.0 : 0.35))
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.top, 30)
    }
}

// MARK: - Finish Screen

struct BreathingFinishView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.lsMenta.opacity(0.35), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.lsSlate)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                }

                Spacer()

                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
                        .overlay(
                            Image(systemName: "lungs.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color.lsSky)
                        )
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.white)
                        )
                        .offset(x: 4, y: -4)
                }
                .padding(.bottom, 18)

                Text("Estás más relajado")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.primary)
                    .multilineTextAlignment(.center)

                Text("Lucas sigue tranquilo. Tomaste un momento para ti y lo lograste.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color.lsSlate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)
                    .padding(.bottom, 28)

                VStack(spacing: 10) {
                    Button { onDismiss() } label: {
                        Text("Volver al perfil")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.lsSalmon)
                            .clipShape(Capsule())
                    }
                    Button { onDismiss() } label: {
                        Text("Repetir ejercicio")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color.lsSlate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black.opacity(0.05))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

#Preview { BreathingView() }
