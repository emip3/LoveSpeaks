import SwiftUI
 
struct SplashView: View {
    @State private var pulse = false
 
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
 
            // Outer aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.lsMint.opacity(0.35),
                            Color.lsSky.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(pulse ? 1.15 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                    value: pulse
                )
 
            // Inner aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.lsSky.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .scaleEffect(pulse ? 1.22 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.4),
                    value: pulse
                )
 
            VStack(spacing: 10) {
                LoveSpeaksLogo()
                    .frame(width: 72, height: 66)
 
                Text("LoveSpeaks")
                    .font(Font.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.primary)
 
                Text("Verificando conexión...")
                    .font(Font.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate)
            }
        }
        .onAppear { pulse = true }
    }
}
 
// MARK: - Logo
struct LoveSpeaksLogo: View {
    var body: some View {
        ZStack {
            HeartShape().fill(Color.lsSky.opacity(0.22))
            HeartShape().fill(Color.lsMint.opacity(0.45)).scaleEffect(0.88)
            HeartShape().fill(Color.lsCream.opacity(0.75)).scaleEffect(0.73)
            HeartShape().fill(Color.lsSalmon.opacity(0.55)).scaleEffect(0.60)
            HeartShape().fill(Color.lsSky.opacity(0.70)).scaleEffect(0.48)
            HeartShape().fill(Color.lsMint.opacity(0.90)).scaleEffect(0.35)
        }
    }
}
 
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        path.move(to: CGPoint(x: cx, y: h * 0.27))
        path.addCurve(
            to: CGPoint(x: cx, y: h),
            control1: CGPoint(x: w, y: -h * 0.05),
            control2: CGPoint(x: w, y: h * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: h * 0.27),
            control1: CGPoint(x: 0, y: h * 0.65),
            control2: CGPoint(x: 0, y: -h * 0.05)
        )
        path.closeSubpath()
        return path
    }
}
 
#Preview { SplashView() }
 
