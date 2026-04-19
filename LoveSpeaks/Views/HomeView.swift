//
//  HomeView.swift
//  LoveSpeaks
//

//
//  HomeView.swift
//  LoveSpeaks
//

import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Capa de fondo: El Blob animado
            FluctuatingBlob(
                primaryColor: viewModel.currentSound.primaryColor,
                secondaryColor: viewModel.currentSound.secondaryColor,
                isListening: viewModel.isListening
            )
            .frame(width: 260, height: 260)
            .offset(y: -40)

            VStack {
                // Barra superior de estado
                DynamicIslandBar(isListening: viewModel.isListening)
                
                Spacer()
                
                // Controles inferiores extraídos para limpieza
                bottomSection
                    .padding(.bottom, 110)
            }
        }
        .ignoresSafeArea()
        .alert("Algo salió mal",
               isPresented: $viewModel.showingError,
               presenting: viewModel.errorMessage) { _ in
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cerrar", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Componentes de la Interfaz

    private var bottomSection: some View {
        VStack(spacing: 16) {
            // Indicador visual (Emoji)
            Text(viewModel.currentSound.displayEmoji)
                .font(.system(size: 52))
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.currentSound.category)

            // Títulos y estado
            VStack(spacing: 4) {
                Text(viewModel.currentSound.displayTitle)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)

                Text(viewModel.statusText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentSound.category)

            // Badge de fuente de sonido
            if viewModel.isListening && viewModel.currentSound.category != .quiet {
                SourceIndicatorBadge(sound: viewModel.currentSound)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Botón principal de acción
            MainToggleButton(viewModel: viewModel)
        }
    }
}

// MARK: - Subvistas Extraídas

struct SourceIndicatorBadge: View {
    let sound: BabySound
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(sound.primaryColor)
                .frame(width: 7, height: 7)
            Text(sound.source.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.lsSlate)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.05))
                .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
        )
    }
}

struct MainToggleButton: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
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
                    .fill(viewModel.primaryActionButtonColor)
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            )
            .shadow(
                color: viewModel.isListening ? .clear : viewModel.currentSound.primaryColor.opacity(0.35),
                radius: 16, x: 0, y: 6
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isListening)
    }
}

// MARK: - Componentes Visuales Animados

struct DynamicIslandBar: View {
    let isListening: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(red: 0.10, green: 0.19, blue: 0.25))
                .frame(width: 8, height: 8)
            Circle()
                .fill(isListening ? Color.lsMint : Color.lsSlate)
                .frame(width: 8, height: 8)
                .opacity(pulse ? 0.4 : 1.0)
                .animation(
                    isListening
                        ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        : .default,
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

struct FluctuatingBlob: View {
    let primaryColor: Color
    let secondaryColor: Color
    let isListening: Bool

    @State private var phase: Double = 0
    @State private var timer: AnyCancellable? = nil

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let baseR = min(size.width, size.height) * 0.42

            // Capas de Aura
            let auras: [(Double, Color, Double)] = [
                (1.30, secondaryColor, 0.35),
                (1.18, primaryColor,   0.22),
                (1.08, primaryColor,   0.28),
            ]
            
            for (scale, color, alpha) in auras {
                let r = baseR * scale
                let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(color.opacity(alpha + sin(phase * 0.8) * 0.05))
                )
            }

            // Forma del Blob dinámico
            var blobPath = Path()
            let pts = 80
            let noiseAmp: Double = isListening ? 1.0 : 0.4
            
            for i in 0...pts {
                let angle = (Double(i) / Double(pts)) * .pi * 2
                let noise = (
                    sin(angle * 2 + phase * 0.7) * 0.12 +
                    sin(angle * 3 - phase * 0.5) * 0.08 +
                    sin(angle * 5 + phase * 0.9) * 0.05
                ) * noiseAmp
                let r = baseR * (1 + noise)
                let x = cx + cos(angle) * r
                let y = cy + sin(angle) * r
                if i == 0 { blobPath.move(to: CGPoint(x: x, y: y)) }
                else       { blobPath.addLine(to: CGPoint(x: x, y: y)) }
            }
            blobPath.closeSubpath()

            context.fill(blobPath, with: .color(primaryColor.opacity(0.65)))
            context.fill(blobPath, with: .color(secondaryColor.opacity(0.45)))
            context.fill(blobPath, with: .color(Color.white.opacity(0.28)))
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

#Preview {
    HomeView()
}
