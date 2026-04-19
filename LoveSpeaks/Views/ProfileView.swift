//
//  ProfileView.swift
//  LoveSpeaks
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerSection
                    tranquilityCard
                    biometricCards
                    aiInsightCard
                    breathingButton
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showBreathing) {
            BreathingView()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.lsCream)
                .frame(width: 44, height: 44)
                .overlay(
                    Text("P")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Hola, Papá")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.primary)
                Text("LoveSpeaks Wellness")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Tranquility Index

    private var tranquilityCard: some View {
        LSGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Índice de Tranquilidad")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                    Spacer()
                    Text(viewModel.tranquilityLabel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                }
                HStack {
                    Text("Tranquilo")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.lsMenta)
                    Spacer()
                    Text("Inquieto")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.lsSalmon)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 99)
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 8)
                        LinearGradient(
                            colors: [Color.lsMenta, Color.lsSky],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * viewModel.tranquilityLevel, height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 99))
                    }
                }
                .frame(height: 8)
            }
        }
    }

    // MARK: - Biometric Cards

    private var biometricCards: some View {
        HStack(spacing: 10) {
            LSBiometricCard(
                label: "FC (LPM)",
                value: viewModel.heartRate,
                trend: viewModel.heartRateTrend,
                color: Color.lsSky
            )
            LSBiometricCard(
                label: "HRV (ms)",
                value: viewModel.hrv,
                trend: viewModel.hrvTrend,
                color: Color.lsMenta
            )
        }
    }

    // MARK: - AI Insight

    private var aiInsightCard: some View {
        LSGlassCard(borderColor: Color.lsSalmon.opacity(0.3)) {
            VStack(alignment: .leading, spacing: 6) {
                Text("+ IA LOVESPEAKS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.lsSalmon)
                Text(viewModel.aiInsight)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color(UIColor.label).opacity(0.75))
                    .lineSpacing(3)
            }
        }
    }

    // MARK: - Breathing Button

    private var breathingButton: some View {
        Button {
            viewModel.showBreathing = true
        } label: {
            Text("Pausa para respirar")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.lsSalmon)
                .clipShape(Capsule())
        }
        .padding(.top, 4)
        .padding(.bottom, 110)
    }
}

// MARK: - Reusable Components

struct LSGlassCard<Content: View>: View {
    var borderColor: Color = Color.black.opacity(0.06)
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .background(Color.lsCream.opacity(0.60))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct LSBiometricCard: View {
    let label: String
    let value: String
    let trend: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color.lsSlate)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.primary)
                Text(trend)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            LSWaveShape()
                .stroke(color, lineWidth: 1.5)
                .frame(height: 16)
                .opacity(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct LSWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h / 2
        path.move(to: CGPoint(x: 0, y: midY))
        for i in stride(from: 0, through: Int(w), by: 2) {
            let x = CGFloat(i)
            let y = midY + sin(x / w * .pi * 4) * (h * 0.38)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

#Preview {
    ProfileView()
}
