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
