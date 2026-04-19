//
//  HomeView.swift
//  LoveSpeaks
//

import SwiftUI
import Combine

// MARK: - HomeView
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            // Fondo blanco puro — diseño código 1
            Color.white.ignoresSafeArea()

            // Blob animado centrado, ligeramente arriba
            // Pasa los colores del sonido actual para que el aura reaccione
            FluctuatingBlob(
                soundColor:  viewModel.currentSound.primaryColor,
                isListening: viewModel.isListening
            )
            .frame(width: 320, height: 320)
            .offset(y: -60)

            // Layout vertical sobre el blob
            VStack(spacing: 0) {
                Spacer()

                // Sección inferior: símbolo, título, estado, badge, botón
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

    // MARK: - Bottom section
    private var bottomSection: some View {
        VStack(spacing: 14) {

            // SF Symbol que representa la emoción detectada
            SoundSymbolView(category: viewModel.currentSound.category)
                .animation(
                    .interpolatingSpring(stiffness: 200, damping: 20),
                    value: viewModel.currentSound.category
                )

            // Título del sonido detectado + subtítulo de estado
            VStack(spacing: 4) {
                Text(viewModel.currentSound.displayTitle)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)

                Text(viewModel.statusText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentSound.category)

            // Badge de fuente (modelo que detectó el sonido) — solo visible escuchando
            if viewModel.isListening && viewModel.currentSound.category != .quiet {
                SourceIndicatorBadge(sound: viewModel.currentSound)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Botón principal toggle — colores diseño código 1
            MainToggleButton(viewModel: viewModel)
        }
    }
}

// MARK: - SF Symbol por emoción
struct SoundSymbolView: View {
    // Usa el mismo tipo que expone BabySound.category en tu proyecto
    let category: SoundCategory

    var symbolName: String {
        switch category {
        case .quiet:      return "waveform.slash"
        case .crying:        return "drop.fill"
        case .hungry:     return "fork.knife"
        case .tired:      return "moon.fill"
        case .discomfort: return "bandage.fill"
        case .babbling:   return "ellipsis.bubble.fill"
        case .laughter:   return "face.smiling.fill"
        }
    }

    var symbolColor: Color {
        switch category {
        // Hex directo para .quiet — evita depender de Color.lsNoSound
        // si ese token no está definido en tu Color+Extensions
        case .quiet:      return Color(red: 0.820, green: 0.835, blue: 0.859)
        case .crying:        return Color.lsCry
        case .hungry:     return Color.lsHungry
        case .tired:      return Color.lsTired
        case .discomfort: return Color.lsDiscomfort
        case .babbling:   return Color.lsBabbling
        case .laughter:   return Color.lsLaughter
      
            
        }
    }

    var body: some View {
        ZStack {
            // Halo de color detrás del símbolo
            Circle()
                .fill(symbolColor.opacity(0.15))
                .frame(width: 72, height: 72)
                .blur(radius: 8)

            // Símbolo SF
            Image(systemName: symbolName)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(symbolColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 64, height: 64)
        }
    }
}

// MARK: - Badge de fuente de detección (del código 2, colores diseño 1)
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
                .fill(Color.black.opacity(0.04))
                .overlay(Capsule().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
        )
    }
}

// MARK: - Botón toggle — lógica código 2, colores código 1
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
            .frame(width: 230, height: 54)
            .background(
                Capsule()
                    // Escuchando → salmon; Pausado → slate oscuro semitransparente
                    .fill(viewModel.isListening
                          ? Color.lsSalmon
                          : Color.lsSlate)
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
            )
            // Sombra salmon suave solo cuando está activo
            .shadow(
                color: viewModel.isListening
                    ? Color.lsSalmon.opacity(0.35)
                    : Color.clear,
                radius: 16, x: 0, y: 6
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isListening)
    }
}

// MARK: - FluctuatingBlob (diseño código 1 íntegro)
// Arquitectura de dos capas:
//   Capa 1 — Elipses SwiftUI con .blur() REAL → aura difuminada
//   Capa 2 — BlobCanvas (Canvas) → forma orgánica animada encima
struct FluctuatingBlob: View {
    /// Color del sonido detectado actualmente; tinta el aura salmon según emoción
    let soundColor:  Color
    let isListening: Bool

    @State private var phase: Double    = 0
    @State private var auraPulse: Bool  = false
    @State private var timer: AnyCancellable? = nil

    var body: some View {
        ZStack {
            // ── Aura salmon/mint/sky con blur SwiftUI real ──────────────────────

            // Glow salmon esquina superior derecha
            // Cuando hay un sonido activo, el color del sonido tiñe el aura
            Ellipse()
                .fill((isListening ? soundColor : Color.lsSalmon).opacity(0.90))
                .frame(width: 180, height: 160)
                .offset(x: 30, y: -20)
                .blur(radius: 38)
                .scaleEffect(auraPulse ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 3.2).repeatForever(autoreverses: true),
                    value: auraPulse
                )

            // Glow mint esquina inferior izquierda
            Ellipse()
                .fill(Color.lsMenta.opacity(0.80))
                .frame(width: 200, height: 180)
                .offset(x: -20, y: 20)
                .blur(radius: 40)
                .scaleEffect(auraPulse ? 1.0 : 1.09)
                .animation(
                    .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                    value: auraPulse
                )

            // Glow sky centro
            Ellipse()
                .fill(Color.lsSky.opacity(0.80))
                .frame(width: 160, height: 160)
                .blur(radius: 30)
                .scaleEffect(auraPulse ? 1.05 : 0.97)
                .animation(
                    .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                    value: auraPulse
                )

            // Cream glow fondo
            Ellipse()
                .fill(Color.lsCream.opacity(0.80))
                .frame(width: 220, height: 200)
                .blur(radius: 50)

            // ── Blob orgánico (Canvas) ───────────────────────────────────────────
            BlobCanvas(phase: phase, isListening: isListening)
                .frame(width: 280, height: 280)
        }
        .onAppear {
            auraPulse = true
            timer = Timer.publish(every: 0.016, on: .main, in: .common)
                .autoconnect()
                .sink { _ in phase += 0.018 }
        }
        .onDisappear { timer?.cancel() }
    }
}

// MARK: - BlobCanvas
// Forma orgánica animada. noiseAmp varía según si está escuchando (código 2).
struct BlobCanvas: View {
    let phase:       Double
    let isListening: Bool

    var body: some View {
        Canvas { context, size in
            let cx    = size.width  / 2
            let cy    = size.height / 2
            let blobR = min(size.width, size.height) * 0.32

            // La amplitud del noise se reduce cuando no está escuchando
            let noiseAmp: Double = isListening ? 1.0 : 0.45

            var blobPath = Path()
            let pts = 80
            for i in 0...pts {
                let angle = (Double(i) / Double(pts)) * .pi * 2
                let noise = (
                    sin(angle * 2 + phase * 0.7) * 0.12 +
                    sin(angle * 3 - phase * 0.5) * 0.08 +
                    sin(angle * 5 + phase * 0.9) * 0.05
                ) * noiseAmp
                let r = blobR * (1 + noise)
                let x = cx + cos(angle) * r
                let y = cy + sin(angle) * r
                if i == 0 { blobPath.move(to: CGPoint(x: x, y: y)) }
                else       { blobPath.addLine(to: CGPoint(x: x, y: y)) }
            }
            blobPath.closeSubpath()

            // Relleno multicapa: blanco → mint → sky → brillo
            context.fill(blobPath, with: .color(Color.white.opacity(0.90)))
            context.fill(blobPath, with: .color(Color.lsMenta.opacity(0.9)))
            context.fill(blobPath, with: .color(Color.lsSky.opacity(0.32)))
            context.fill(blobPath, with: .color(Color.white.opacity(0.18)))

            // Brillo especular superior izquierdo
            let hr    = blobR * 0.28
            let hRect = CGRect(
                x: cx - blobR * 0.22 - hr,
                y: cy - blobR * 0.28 - hr * 0.45,
                width:  hr * 2,
                height: hr * 0.85
            )
            let glareT = CGAffineTransform.identity
                .translatedBy(x: hRect.midX,      y: hRect.midY)
                .rotated(by: -0.35)
                .translatedBy(x: -hRect.width / 2, y: -hRect.height / 2)
            context.fill(
                Path(ellipseIn: CGRect(origin: .zero, size: hRect.size)).applying(glareT),
                with: .color(Color.white.opacity(0.50))
            )
        }
    }
}

// MARK: - Comparable helper
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview { HomeView() }
