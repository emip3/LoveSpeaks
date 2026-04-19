import SwiftUI
import Combine

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                DynamicIslandBar()
                Spacer()
            }

            FluctuatingBlob()
                .frame(width: 220, height: 220)
                .offset(y: -40)

            VStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("Escuchando...")
                        .font(Font.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.primary)
                    Text("LoveSpeaks is tuning in")
                        .font(Font.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                }
                .padding(.bottom, 110)
            }
        }
    }
}

// MARK: - Dynamic Island Bar
struct DynamicIslandBar: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(red: 0.10, green: 0.19, blue: 0.25))
                .frame(width: 8, height: 8)
            Circle()
                .fill(Color.lsMint)
                .frame(width: 8, height: 8)
                .opacity(pulse ? 0.5 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: pulse
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 7)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .clipShape(Capsule())
        .padding(.top, 12)
        .onAppear { pulse = true }
    }
}

// MARK: - Fluctuating Blob (Timer driven, no Combine autoconnect issue)
struct FluctuatingBlob: View {
    @State private var phase: Double = 0
    @State private var timer: AnyCancellable? = nil

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let baseR = min(size.width, size.height) * 0.42

            // Aura layers
            let auras: [(Double, Color, Double)] = [
                (1.30, .lsSky,  0.18),
                (1.18, .lsMint, 0.22),
                (1.08, .lsSky,  0.28),
            ]
            for (scale, color, alpha) in auras {
                let r = baseR * scale
                let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(color.opacity(alpha + sin(phase * 0.8) * 0.05))
                )
            }

            // Salmon accent
            let sr = baseR * 1.1
            let sRect = CGRect(
                x: cx + baseR * 0.3 - sr,
                y: cy - sr * 0.9,
                width: sr * 1.8,
                height: sr * 1.6
            )
            context.fill(
                Path(ellipseIn: sRect),
                with: .color(Color.lsSalmon.opacity(0.12 + sin(phase * 0.5) * 0.04))
            )

            // Blob shape
            var blobPath = Path()
            let pts = 80
            for i in 0...pts {
                let angle = (Double(i) / Double(pts)) * .pi * 2
                let noise =
                    sin(angle * 2 + phase * 0.7) * 0.12 +
                    sin(angle * 3 - phase * 0.5) * 0.08 +
                    sin(angle * 5 + phase * 0.9) * 0.05
                let r = baseR * (1 + noise)
                let x = cx + cos(angle) * r
                let y = cy + sin(angle) * r
                if i == 0 { blobPath.move(to: CGPoint(x: x, y: y)) }
                else { blobPath.addLine(to: CGPoint(x: x, y: y)) }
            }
            blobPath.closeSubpath()

            context.fill(blobPath, with: .color(Color.lsSky.opacity(0.65)))
            context.fill(blobPath, with: .color(Color.lsMint.opacity(0.55)))
            context.fill(blobPath, with: .color(Color.white.opacity(0.28)))

            // Specular highlight
            let hr = baseR * 0.28
            let hRect = CGRect(
                x: cx - baseR * 0.22 - hr,
                y: cy - baseR * 0.30 - hr * 0.45,
                width: hr * 2,
                height: hr * 0.9
            )
            context.fill(Path(ellipseIn: hRect), with: .color(Color.white.opacity(0.36)))
        }
        .onAppear {
            timer = Timer.publish(every: 0.016, on: .main, in: .common)
                .autoconnect()
                .sink { _ in phase += 0.018 }
        }
        .onDisappear {
            timer?.cancel()
        }
    }
}

#Preview { HomeView() }

import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────────────
            backgroundGradient

            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 60)

                Spacer()

                // ── Main Detection Circle ─────────────────────────────────
                detectionCircle
                    .padding(.horizontal, 40)

                Spacer()

                // ── Status + Button ───────────────────────────────────────
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
            // Base dark background
            Color(red: 0.07, green: 0.07, blue: 0.10)
                .ignoresSafeArea()

            // Ambient glow that responds to the detected sound
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
            // Outer pulse ring (only while listening)
            if viewModel.isListening {
                Circle()
                    .stroke(viewModel.currentSound.primaryColor.opacity(0.25), lineWidth: 2)
                    .scaleEffect(viewModel.isPulsing ? 1.18 : 1.0)
                    .animation(.easeInOut(duration: 1.1), value: viewModel.isPulsing)
            }

            // Middle glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            viewModel.currentSound.secondaryColor,
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 160
                    )
                )
                .animation(.easeInOut(duration: 0.8), value: viewModel.currentSound.category)

            // Main filled circle
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
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                )
                .shadow(color: viewModel.currentSound.primaryColor.opacity(0.5),
                        radius: 30, x: 0, y: 0)
                .padding(24)
                .animation(.spring(response: 0.6, dampingFraction: 0.7),
                           value: viewModel.currentSound.category)

            // Emoji + label inside circle
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
            // Source badge (which model detected it)
            if viewModel.isListening && viewModel.currentSound.category != .quiet {
                sourceIndicator
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Status text
            Text(viewModel.statusText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .animation(.easeInOut(duration: 0.3), value: viewModel.statusText)

            // Main CTA button
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
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
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
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
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

// MARK: - Preview

#Preview {
    HomeView()
}
