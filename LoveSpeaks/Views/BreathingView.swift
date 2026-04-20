//
//  BreathingView.swift
//  LoveSpeaks
//

import SwiftUI

// MARK: - BreathingView
struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    // Forma explícita requerida cuando el ViewModel es @MainActor final class
    @StateObject private var viewModel: BreathingViewModel = BreathingViewModel()

    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: viewModel.phase)

            if viewModel.finished {
                BreathingFinishView(
                    onDismiss: { dismiss() },
                    onRepeat:  { viewModel.restart() }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else {
                activeBreathingContent
            }
        }
        .onAppear { viewModel.startCycles() }
    }

    // MARK: Color de fondo por fase
    private var bgColor: Color {
        switch viewModel.phase {
        case .inhale: return Color(red: 0.682, green: 0.851, blue: 0.878)
        case .hold:   return Color(red: 0.620, green: 0.800, blue: 0.820)
        case .exhale: return Color(red: 0.700, green: 0.870, blue: 0.890)
        }
    }

    // MARK: Contenido activo
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
            .padding(.top, 18)
            .padding(.trailing, 22)
        }
    }

    private var breathCircle: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.13))
                .frame(width: 210, height: 210)
                .scaleEffect(viewModel.scale * 1.04)

            Circle()
                .fill(Color.white.opacity(0.20))
                .frame(width: 160, height: 160)
                .scaleEffect(viewModel.scale)

            Circle()
                .fill(Color.white.opacity(0.62))
                .frame(width: 108, height: 108)
                .scaleEffect(viewModel.scale)
                .overlay(
                    Text(viewModel.phase.rawValue)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.29, green: 0.48, blue: 0.50))
                        .scaleEffect(1.0 / max(viewModel.scale, 0.01))
                )
        }
        .animation(.easeInOut(duration: viewModel.phaseDuration), value: viewModel.scale)
    }

    private var subtextLabel: some View {
        Text(viewModel.subText)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(Color.white.opacity(0.78))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.top, 30)
    }

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<viewModel.totalCycles, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(i < viewModel.cycleCount ? 1.0 : 0.30))
                    .frame(width: 7, height: 7)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.cycleCount)
            }
        }
        .padding(.top, 28)
    }
}

// MARK: - BreathingFinishView
struct BreathingFinishView: View {
    let onDismiss: () -> Void
    let onRepeat:  () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.lsMint.opacity(0.35), Color.white],
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
                    .padding(.top, 18)
                    .padding(.trailing, 22)
                }

                Spacer()

                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 68, height: 68)
                        .overlay(Circle().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 28))
                                .foregroundColor(Color.lsSalmon.opacity(0.75))
                        )
                    Circle()
                        .fill(Color(red: 0.20, green: 0.78, blue: 0.35))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.white)
                        )
                        .offset(x: 4, y: -4)
                }
                .padding(.bottom, 20)

                Text("¡Te has nivelado!")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.primary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)

                Text("Estás más relajado y en equilibrio.\n¿Deseas terminar las respiraciones?")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color.lsSlate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 30)

                VStack(spacing: 10) {
                    Button { onDismiss() } label: {
                        Text("Terminar")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.lsSalmon)
                            .clipShape(Capsule())
                    }
                    Button { onRepeat() } label: {
                        Text("Seguir respirando")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color.lsSlate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black.opacity(0.05))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 26)

                Spacer()
            }
        }
    }
}

#Preview { BreathingView() }
#Preview("Finish") { BreathingFinishView(onDismiss: {}, onRepeat: {}) }
