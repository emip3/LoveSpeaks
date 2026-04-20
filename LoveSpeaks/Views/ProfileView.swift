//
//  ProfileView.swift
//  LoveSpeaks
//

// ProfileView.swift
// LoveSpeaks — CODA App
//
// UI HCAI: Zero gráficas aburridas.
// Anillo de energía semántico, tarjetas de diálogo reactivas,
// skeleton loading mientras Foundation Models genera el insight.

import SwiftUI
import Charts

// ─────────────────────────────────────────────
// MARK: - ProfileView (raíz)
// ─────────────────────────────────────────────

struct ProfileView: View {
    @StateObject private var vm  = ProfileViewModel()
    @State private var showBreathing = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo dinámico que respira con el estado
                backgroundGlow
                    .ignoresSafeArea()

                if vm.isLoadingHealth {
                    LoadingScreen()
                        .transition(.opacity)
                } else {
                    mainContent
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .navigationBarHidden(true)
            .animation(.easeInOut(duration: 0.5), value: vm.isLoadingHealth)
        }
        .sheet(isPresented: $showBreathing) { BreathingView() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await vm.runFullPipeline() } }
        }
        .alert("Acceso a Salud", isPresented: $vm.permissionDenied) {
            Button("Abrir Ajustes") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Activa el acceso en Ajustes › Privacidad › Salud › LoveSpeaks para ver tus datos reales del Apple Watch.")
        }
    }

    // ─── Fondo que cambia suavemente con el estado ──

    private var backgroundGlow: some View {
        ZStack {
            Color.white
            RadialGradient(
                colors: [vm.wellnessLabel.accentColor.opacity(0.12), Color.clear],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
            .animation(.easeInOut(duration: 1.2), value: vm.wellnessLabel)
        }
    }

    // ─── Contenido principal ──────────────────

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                headerSection
                    .padding(.top, 16)

                // 1. Tarjeta de diálogo IA (Foundation Models)
                InsightDialogCard(vm: vm, showBreathing: $showBreathing)

                // 2. Anillo de energía + métricas rápidas
                EnergyRingSection(vm: vm)

                // 3. Arquitectura del sueño
                SemanticSleepCard(sleep: vm.sleep)

                // 4. Estado del bebé (vivo, viene del audio)
                BabyStateCard(sound: vm.currentBabySound)

                // 5. Tendencias semanales
                WeeklyTrendsCard(vm: vm)

                Spacer(minLength: 110)
            }
            .padding(.horizontal, 20)
        }
    }

    // ─── Header ───────────────────────────────

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.lsCream)
                .frame(width: 46, height: 46)
                .overlay(
                    Text(String(vm.userName.prefix(1)))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Hola, \(vm.userName)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                Text(vm.currentDate)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate.opacity(0.65))
            }

            Spacer()

            // Badge de estado con icono del modelo
            HStack(spacing: 5) {
                Image(systemName: vm.wellnessLabel.sfSymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(vm.wellnessLabel.accentColor)
                Text(vm.wellnessLabel.rawValue.capitalized)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(vm.wellnessLabel.accentColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(vm.wellnessLabel.accentColor.opacity(0.12))
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.4), value: vm.wellnessLabel)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - InsightDialogCard
// La tarjeta más importante. Muestra el texto de Foundation Models.
// Si isGeneratingInsight == true → skeleton suave.
// ─────────────────────────────────────────────

struct InsightDialogCard: View {
    @ObservedObject var vm: ProfileViewModel
    @Binding var showBreathing: Bool
    @State private var appeared = false

    var accent: Color { vm.wellnessLabel.accentColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Header de la tarjeta ──
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: vm.isGeneratingInsight
                          ? "sparkles" : vm.wellnessLabel.sfSymbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accent)
                        .symbolEffect(.pulse, isActive: vm.isGeneratingInsight)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("IA LOVESPEAKS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                        .kerning(1.0)
                    if !vm.isGeneratingInsight {
                        Text(vm.insight.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .transition(.blurReplace)
                    } else {
                        SkeletonLine(width: 140, height: 12)
                    }
                }
                Spacer()
            }

            // ── Cuerpo: explicación ──
            if vm.isGeneratingInsight {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLine(width: .infinity, height: 13)
                    SkeletonLine(width: 260, height: 13)
                }
            } else {
                Text(vm.insight.explanation)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.primary.opacity(0.78))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.blurReplace)
            }

            // ── Acción ──
            if vm.isGeneratingInsight {
                SkeletonLine(width: 200, height: 13)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(accent)
                        .padding(.top, 1)
                    Text(vm.insight.action)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(accent)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .transition(.blurReplace)
            }

            // ── Botón de respiración (solo en estados alert) ──
            if vm.wellnessLabel.isAlert && !vm.isGeneratingInsight {
                Button {
                    showBreathing = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wind")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Pausa de respiración")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent)
                    .clipShape(Capsule())
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.opacity(vm.wellnessLabel.isAlert ? 0.5 : 0.15), lineWidth: 1.5)
        )
        .shadow(color: accent.opacity(0.12), radius: 16, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.4), value: vm.isGeneratingInsight)
        .animation(.easeInOut(duration: 0.5), value: vm.wellnessLabel)
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - EnergyRingSection
// Anillo principal (score 0-100) + 3 métricas rápidas
// ─────────────────────────────────────────────

struct EnergyRingSection: View {
    @ObservedObject var vm: ProfileViewModel
    @State private var ringProgress: CGFloat = 0

    var body: some View {
        HStack(spacing: 16) {

            // ── Anillo ──────────────────────────
            ZStack {
                // Track
                Circle()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 14)

                // Progress
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(vm.wellnessLabel.accentColor,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.2, dampingFraction: 0.75), value: ringProgress)

                // Centro
                VStack(spacing: 0) {
                    Text("\(vm.ringScore)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    Text("/ 100")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.lsSlate.opacity(0.5))
                }
            }
            .frame(width: 96, height: 96)
            .onAppear { ringProgress = CGFloat(vm.ringScore) / 100 }
            .onChange(of: vm.ringScore) { _, v in ringProgress = CGFloat(v) / 100 }

            // ── Métricas rápidas ────────────────
            VStack(spacing: 8) {
                QuickMetricRow(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: vm.hrv > 0 ? "\(Int(vm.hrv)) ms" : "—",
                    color: vm.hrv > 50 ? Color.lsMint : vm.hrv > 35 ? Color.lsSky : Color.lsSalmon
                )
                Divider().opacity(0.4)
                QuickMetricRow(
                    icon: "heart.fill",
                    label: "FC reposo",
                    value: vm.restingHR > 0 ? "\(Int(vm.restingHR)) bpm" : "—",
                    color: Color.lsSky
                )
                Divider().opacity(0.4)
                QuickMetricRow(
                    icon: "figure.walk",
                    label: "Pasos",
                    value: vm.steps > 0 ? "\(vm.steps)" : "—",
                    color: vm.steps > 7000 ? Color.lsMint : Color.lsSlate
                )
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
        }
    }
}

struct QuickMetricRow: View {
    let icon: String; let label: String; let value: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 18)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color.lsSlate)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - SemanticSleepCard
// Barra de fases animada + insight contextual
// ─────────────────────────────────────────────

struct SemanticSleepCard: View {
    let sleep: SleepBreakdown
    @State private var barAnimated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SUEÑO ANOCHE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.lsSlate.opacity(0.6))
                        .kerning(1.0)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", sleep.total))
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                        Text("horas")
                            .font(.system(size: 14))
                            .foregroundColor(Color.lsSlate.opacity(0.6))
                    }
                }
                Spacer()
                // Badge de % meta
                let pct = min(Int((sleep.total / 8.0) * 100), 100)
                Text("\(pct)% meta")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.lsSky)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.lsSky.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Barra de fases proporcional animada
            GeometryReader { geo in
                let total = max(sleep.total, 0.01)
                let wD = geo.size.width * CGFloat(sleep.deep / total)
                let wC = geo.size.width * CGFloat(sleep.core / total)
                let wR = geo.size.width * CGFloat(sleep.rem  / total)

                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "4A55A2"))
                        .frame(width: barAnimated ? wD : 0)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "7895CB"))
                        .frame(width: barAnimated ? wC : 0)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.lsSky)
                        .frame(width: barAnimated ? wR : 0)
                }
                .animation(.easeOut(duration: 1.0).delay(0.2), value: barAnimated)
            }
            .frame(height: 20)
            .onAppear { barAnimated = true }

            // Leyenda
            HStack(spacing: 14) {
                SleepLegend(color: Color(hex: "4A55A2"), label: "Profundo",
                             hours: sleep.deep)
                SleepLegend(color: Color(hex: "7895CB"), label: "Ligero",
                             hours: sleep.core)
                SleepLegend(color: Color.lsSky, label: "REM", hours: sleep.rem)
            }

            // Insight semántico
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color.lsSky)
                    .padding(.top, 1)
                Text(sleep.qualityInsight)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.75))
                    .lineSpacing(3)
            }
            .padding(12)
            .background(Color(hex: "F0F8FA"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

struct SleepLegend: View {
    let color: Color; let label: String; let hours: Double
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(String(format: "%.1fh", hours))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.lsSlate)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - BabyStateCard
// Estado vivo del bebé desde AudioClassifierService
// ─────────────────────────────────────────────

struct BabyStateCard: View {
    let sound: BabySound
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 16) {
            // Ícono con aura pulsante
            ZStack {
                Circle()
                    .fill(sound.primaryColor.opacity(pulse ? 0.15 : 0.08))
                    .frame(width: 60, height: 60)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                               value: pulse)
                Text(sound.displayEmoji)
                    .font(.system(size: 28))
            }
            .onAppear { pulse = true }

            VStack(alignment: .leading, spacing: 4) {
                Text("ESTADO DEL BEBÉ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.lsSlate.opacity(0.6))
                    .kerning(1.0)
                Text(sound.displayTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.interpolate)
                Text("Audio en tiempo real")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate.opacity(0.5))
            }
            Spacer()

            // Confidence badge
            if sound.category != .quiet {
                Text(sound.confidenceText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(sound.primaryColor)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(sound.primaryColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(sound.primaryColor.opacity(sound.category == .quiet ? 0.06 : 0.25),
                        lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.4), value: sound.category)
    }
}

// ─────────────────────────────────────────────
// MARK: - WeeklyTrendsCard
// Gráficas semánticas con Swift Charts
// ─────────────────────────────────────────────

struct WeeklyTrendsCard: View {
    @ObservedObject var vm: ProfileViewModel
    @State private var selected = 0   // 0 HRV, 1 Sueño, 2 Pasos

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TU SEMANA")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(Color.lsSlate.opacity(0.6))
                .kerning(1.0)

            // Selector
            HStack(spacing: 0) {
                ForEach(["HRV", "Sueño", "Actividad"].indices, id: \.self) { i in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selected = i }
                    } label: {
                        Text(["HRV", "Sueño", "Actividad"][i])
                            .font(.system(size: 12, weight: selected == i ? .bold : .medium,
                                          design: .rounded))
                            .foregroundColor(selected == i ? .white : Color.lsSlate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selected == i ? Color.lsSky : Color.clear)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(3)
            .background(Color(UIColor.systemGray6))
            .clipShape(Capsule())

            // Gráfica
            switch selected {
            case 0:
                TrendChart(values: vm.weeklyHRV, labels: vm.weekLabels,
                           color: Color.lsSky, suffix: "ms",
                           goal: nil, type: .line)
            case 1:
                TrendChart(values: vm.weeklySleep, labels: vm.weekLabels,
                           color: Color(hex: "7895CB"), suffix: "h",
                           goal: 8.0, type: .bar)
            default:
                TrendChart(values: vm.weeklySteps, labels: vm.weekLabels,
                           color: Color.lsMint, suffix: "",
                           goal: 8000, type: .bar)
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

enum TrendType { case line, bar }

struct TrendChart: View {
    let values: [Double]; let labels: [String]
    let color: Color; let suffix: String
    let goal: Double?; let type: TrendType

    private var points: [(label: String, value: Double)] {
        let count = min(values.count, labels.count)
        return (0..<count).map { (labels[$0], values[$0]) }
    }

    var body: some View {
        Group {
            if points.isEmpty || points.filter({ $0.value > 0 }).isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemGray6))
                    .frame(height: 90)
                    .overlay(
                        Text("Sin datos del Watch")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color.lsSlate.opacity(0.5))
                    )
            } else {
                Chart {
                    ForEach(points, id: \.label) { pt in
                        if type == .line {
                            AreaMark(x: .value("Día", pt.label), y: .value(suffix, pt.value))
                                .foregroundStyle(color.opacity(0.1))
                            LineMark(x: .value("Día", pt.label), y: .value(suffix, pt.value))
                                .foregroundStyle(color)
                                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            PointMark(x: .value("Día", pt.label), y: .value(suffix, pt.value))
                                .foregroundStyle(color)
                                .symbolSize(22)
                        } else {
                            BarMark(x: .value("Día", pt.label), y: .value(suffix, pt.value))
                                .foregroundStyle(
                                    goal != nil && pt.value >= goal!
                                        ? color : color.opacity(0.4)
                                )
                                .cornerRadius(5)
                        }
                    }
                    if let g = goal {
                        RuleMark(y: .value("Meta", g))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(Color.lsSlate.opacity(0.25))
                    }
                }
                .chartXAxis {
                    AxisMarks { v in
                        AxisValueLabel {
                            Text(v.as(String.self) ?? "")
                                .font(.system(size: 9, design: .rounded))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { v in
                        AxisValueLabel {
                            let val = v.as(Double.self) ?? 0
                            let txt = val >= 1000
                                ? String(format: "%.0fk", val / 1000)
                                : String(format: "%.0f\(suffix)", val)
                            Text(txt).font(.system(size: 9, design: .rounded))
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 100)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Loading Screen
// ─────────────────────────────────────────────

struct LoadingScreen: View {
    @State private var pulse = false
    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.lsMint.opacity(pulse ? 0.25 : 0.08))
                    .frame(width: 110, height: 110)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                               value: pulse)
                Image(systemName: "heart.fill")
                    .font(.system(size: 38))
                    .foregroundColor(Color.lsMint)
            }
            .onAppear { pulse = true }

            VStack(spacing: 6) {
                Text("Conectando con Apple Health")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Leyendo tu Apple Watch…")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.lsSlate.opacity(0.6))
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - SkeletonLine
// Loading placeholder para las tarjetas de diálogo
// ─────────────────────────────────────────────

struct SkeletonLine: View {
    let width: CGFloat
    let height: CGFloat
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Color(UIColor.systemGray5))
            .frame(maxWidth: width == .infinity ? nil : width)
            .frame(height: height)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.55), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: shimmerPhase * geo.size.width * 2)
                    .animation(
                        .linear(duration: 1.3).repeatForever(autoreverses: false),
                        value: shimmerPhase
                    )
                    .onAppear { shimmerPhase = 1 }
                }
            )
            .clipped()
    }
}



// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────

#Preview {
    ProfileView()
}
