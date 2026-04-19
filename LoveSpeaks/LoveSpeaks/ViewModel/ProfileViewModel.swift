// ProfileViewModel.swift
// LoveSpeaks — CODA App
//
// El Director del pipeline de IA:
//   HealthKit → SaludPadreModel (Core ML) → generateEmpatheticInsight (Foundation Models)
//
// Flujo automático y reactivo. Sin botones manuales en la UI.

import SwiftUI
import HealthKit
import CoreML
import Combine

// ─────────────────────────────────────────────
// MARK: - WellnessLabel
// Mapea los outputs de SaludPadreModel a semántica visual
// ─────────────────────────────────────────────

enum WellnessLabel: String, CaseIterable {
    case recovered     = "recovered"
    case normal        = "normal"
    case fatigued      = "fatigued"
    case stressed      = "stressed"
    case hypervigilance = "hypervigilance"
    case critical      = "critical"

    // ── Semántica visual ──
    var accentColor: Color {
        switch self {
        case .recovered:      return Color.lsMint
        case .normal:         return Color.lsSky
        case .fatigued:       return Color(hex: "E8A045")
        case .stressed:       return Color.lsSalmon
        case .hypervigilance: return Color(hex: "C88AC0")
        case .critical:       return Color(hex: "D94040")
        }
    }

    var sfSymbol: String {
        switch self {
        case .recovered:      return "checkmark.seal.fill"
        case .normal:         return "heart.fill"
        case .fatigued:       return "battery.25"
        case .stressed:       return "waveform.path.ecg.rectangle.fill"
        case .hypervigilance: return "eye.trianglebadge.exclamationmark.fill"
        case .critical:       return "exclamationmark.triangle.fill"
        }
    }

    var ringScore: Int {
        switch self {
        case .recovered:      return 92
        case .normal:         return 72
        case .fatigued:       return 50
        case .stressed:       return 30
        case .hypervigilance: return 22
        case .critical:       return 10
        }
    }

    var isAlert: Bool { self == .stressed || self == .hypervigilance || self == .critical }
}

// ─────────────────────────────────────────────
// MARK: - EmpatheticInsight
// Output del paso Foundation Models
// ─────────────────────────────────────────────

struct EmpatheticInsight: Equatable {
    var title:       String = ""
    var explanation: String = ""   // Por qué la IA dice lo que dice (transparencia)
    var action:      String = ""   // Acción concreta y empática
    var isAlert:     Bool   = false
}

// ─────────────────────────────────────────────
// MARK: - SleepBreakdown (para SemanticSleepCard)
// ─────────────────────────────────────────────

struct SleepBreakdown: Equatable {
    var deep:  Double = 0
    var core:  Double = 0
    var rem:   Double = 0
    var total: Double { deep + core + rem }

    var qualityInsight: String {
        let deepPct = total > 0 ? (deep / total) * 100 : 0
        if total < 5     { return "Poco sueño anoche. Tu cuerpo físico lo sentirá hoy." }
        if deepPct < 15  { return "Sueño superficial. La recuperación física fue limitada." }
        if rem < 1.0     { return "Poco sueño REM. Regular emociones puede costarte más hoy." }
        if total > 7.5   { return "Excelente descanso. Tu sistema nervioso se recuperó bien." }
        return "Descanso adecuado. Buen equilibrio entre fases de sueño."
    }
}

// ─────────────────────────────────────────────
// MARK: - ProfileViewModel
// ─────────────────────────────────────────────

@MainActor
final class ProfileViewModel: ObservableObject {

    // ── Estado de carga ───────────────────────
    @Published var isLoadingHealth  = true
    @Published var isGeneratingInsight = false   // Skeleton en la tarjeta IA
    @Published var permissionDenied = false

    // ── Datos del usuario ─────────────────────
    @Published var userName    = "Papá"
    @Published var currentDate = Self.formatDate(Date())

    // ── Output del modelo Core ML ─────────────
    @Published var wellnessLabel   = WellnessLabel.normal
    @Published var ringScore       = 0          // 0-100 para el anillo

    // ── Output del paso Foundation Models ─────
    @Published var insight = EmpatheticInsight()

    // ── Métricas para visualizaciones ─────────
    @Published var sleep       = SleepBreakdown()
    @Published var hrv         = 0.0
    @Published var heartRate   = 0.0
    @Published var restingHR   = 0.0
    @Published var steps       = 0
    @Published var calories    = 0
    @Published var respRate    = 0.0

    // ── Series semanales ──────────────────────
    @Published var weeklyHRV:   [Double] = []
    @Published var weeklySleep: [Double] = []
    @Published var weeklySteps: [Double] = []
    @Published var weekLabels:  [String] = []

    // ── Estado del bebé (viene del HomeViewModel vía AudioClassifierService) ──
    @Published var currentBabySound = BabySound.idle

    // ─────────────────────────────────────────
    // Privado
    // ─────────────────────────────────────────

    private let healthManager = HealthManager()
    private var lastSnapshot  = HealthSnapshot()

    // ─────────────────────────────────────────
    // MARK: - Setup
    // ─────────────────────────────────────────

    init() {
        Task { await boot() }
    }

    /// Punto de entrada. Llamado también desde .onChange(scenePhase)
    func boot() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            loadDemoData(); return
        }
        let granted = await healthManager.requestAuthorization()
        if granted {
            await runFullPipeline()
        } else {
            permissionDenied = true
            loadDemoData()
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Pipeline principal de IA
    // ─────────────────────────────────────────

    /// Paso 1 → 2 → 3 completamente automático.
    func runFullPipeline() async {
        isLoadingHealth = true

        // ── Paso 1: HealthKit ─────────────────
        let snapshot = await healthManager.fetchSnapshot(age: 28)
        lastSnapshot = snapshot

        // Publicar métricas para la UI
        publishMetrics(from: snapshot)

        isLoadingHealth = false

        // ── Paso 2: Core ML ───────────────────
        let label = runSaludPadreModel(snapshot: snapshot)
        wellnessLabel = label
        ringScore     = computeRingScore(label: label, hrv: snapshot.hrv)

        // ── Paso 3: Foundation Models (automático) ──
        await generateEmpatheticInsight(from: label.rawValue)
    }

    // ─────────────────────────────────────────
    // MARK: - Paso 2: SaludPadreModel (Core ML)
    // ─────────────────────────────────────────

    private func runSaludPadreModel(snapshot: HealthSnapshot) -> WellnessLabel {
        do {
            // Instanciar el modelo entrenado con Create ML Tabular Classifier
            let model = try SaludPadreModel(configuration: MLModelConfiguration())

            // Los inputs se adaptan al schema real del modelo.
            // SaludPadreModel lee: age, sleep_hours, sleep_score, steps,
            //                     active_hours, heart_rate, hrv, energy
            // El baby_sound_label se cruza con la heurística abajo.
            let input = SaludPadreModelInput(
                age:          Double(snapshot.age),
                sleep_hours:  Double(snapshot.sleepHours),
                sleep_score:  Double(snapshot.sleepScore),
                steps:        Double(snapshot.steps),
                active_hours: Double(snapshot.activeHours),
                heart_rate:   Double(snapshot.heartRate > 0 ? snapshot.heartRate : snapshot.restingHR),
                hrv:          Double(snapshot.hrv > 0 ? snapshot.hrv : 45),
                energy:       Double(snapshot.energy)
            )

            let output   = try model.prediction(input: input)
            let rawLabel = output.label
                .trimmingCharacters(in: .whitespaces)
                .lowercased()

            // Cruzar con estado del bebé: si el bebé no está en calma,
            // el label no puede ser "recovered" — penaliza un nivel.
            let mlLabel = WellnessLabel(rawValue: rawLabel) ?? .normal
            return adjustForBabyState(mlLabel)

        } catch {
            print("⚠️ SaludPadreModel error: \(error.localizedDescription)")
            return heuristicFallback(snapshot: snapshot)
        }
    }

    /// Si el bebé no está en calma, ajusta el label hacia más alerta.
    private func adjustForBabyState(_ label: WellnessLabel) -> WellnessLabel {
        let babyNeedsAttention = currentBabySound.category != .quiet
            && currentBabySound.category != .happy

        guard babyNeedsAttention else { return label }

        switch label {
        case .recovered: return .normal
        case .normal:    return .fatigued
        case .fatigued:  return .stressed
        default:         return label
        }
    }

    /// Fallback heurístico si el modelo falla (HRV + sueño)
    private func heuristicFallback(snapshot: HealthSnapshot) -> WellnessLabel {
        let h = snapshot.sleepHours
        let v = snapshot.hrv
        if v < 20 || h < 4    { return .critical }
        if v < 30 || h < 5    { return .stressed }
        if v < 45 || h < 6.5  { return .fatigued }
        if v > 65 && h > 7    { return .recovered }
        return .normal
    }

    // ─────────────────────────────────────────
    // MARK: - Paso 3: Foundation Models
    // generateEmpatheticInsight(from:)
    //
    // Se dispara AUTOMÁTICAMENTE justo después del modelo.
    // isGeneratingInsight → true dispara el skeleton en la UI.
    // ─────────────────────────────────────────

    func generateEmpatheticInsight(from label: String) async {
        isGeneratingInsight = true

        // ── iOS 26+: Foundation Models on-device ──────────────────
        // Descomenta este bloque cuando Foundation Models esté disponible.
        //
        // import FoundationModels
        //
        // let session = LanguageModelSession(instructions: """
        //     Eres un compañero empático para un padre sordo que cuida a su bebé.
        //     Responde SIEMPRE en español. Máximo 3 oraciones por campo.
        //     Tono: cálido, directo, sin condescendencia. Sin tecnicismos médicos.
        //     El usuario es sordo: prioriza metáforas visuales y sensoriales.
        //     Devuelve JSON: { "title": "", "explanation": "", "action": "" }
        // """)
        //
        // let prompt = buildFoundationModelsPrompt(label: label)
        // do {
        //     let response = try await session.respond(to: prompt)
        //     if let parsed = parseInsightJSON(response.content) {
        //         insight = parsed
        //     } else {
        //         insight = contextualInsight(for: WellnessLabel(rawValue: label) ?? .normal)
        //     }
        // } catch {
        //     insight = contextualInsight(for: WellnessLabel(rawValue: label) ?? .normal)
        // }
        // ─────────────────────────────────────────────────────────

        // Delay de 1 segundo simulando la llamada al LLM on-device
        try? await Task.sleep(for: .seconds(1))

        let parsed = WellnessLabel(rawValue: label) ?? .normal
        insight = contextualInsight(for: parsed)
        isGeneratingInsight = false
    }

    // ─────────────────────────────────────────
    // MARK: - Prompt para Foundation Models
    // ─────────────────────────────────────────

    private func buildFoundationModelsPrompt(label: String) -> String {
        let snap = lastSnapshot
        return """
        Estado del padre sordo ahora mismo:
        - Diagnóstico del modelo: \(label)
        - Bebé: \(currentBabySound.displayTitle) (categoría: \(currentBabySound.category.rawValue))
        - Sueño anoche: \(String(format:"%.1f", snap.sleepHours))h
          (Profundo: \(String(format:"%.1f", snap.sleepDeep))h, REM: \(String(format:"%.1f", snap.sleepREM))h)
        - HRV del Apple Watch: \(Int(snap.hrv))ms
        - FC en reposo: \(Int(snap.restingHR))bpm
        - Pasos hoy: \(Int(snap.steps))
        - Score energía: \(Int(snap.energy))/100

        Genera un insight JSON con 3 campos:
        - title: título empático corto (máx 6 palabras)
        - explanation: por qué dices esto, basado en los datos reales (máx 2 oraciones)
        - action: qué hacer concretamente ahora mismo (máx 2 oraciones)

        El padre no puede oír — evita referencias auditivas. Usa metáforas visuales.
        Responde SOLO el JSON, sin backticks.
        """
    }

    private func parseInsightJSON(_ raw: String) -> EmpatheticInsight? {
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let title = json["title"],
              let explanation = json["explanation"],
              let action = json["action"] else { return nil }

        return EmpatheticInsight(
            title: title,
            explanation: explanation,
            action: action,
            isAlert: WellnessLabel(rawValue: wellnessLabel.rawValue)?.isAlert ?? false
        )
    }

    // ─────────────────────────────────────────
    // MARK: - Insights contextuales (fallback)
    // Alta calidad, personalizados con datos reales
    // ─────────────────────────────────────────

    private func contextualInsight(for label: WellnessLabel) -> EmpatheticInsight {
        let snap = lastSnapshot
        let hrv  = Int(snap.hrv)
        let h    = String(format: "%.1f", snap.sleepHours)
        let babyCalm = currentBabySound.category == .quiet || currentBabySound.category == .happy

        switch label {

        case .recovered:
            return EmpatheticInsight(
                title: "Tu cuerpo está en su mejor momento",
                explanation: "Tu HRV de \(hrv)ms indica que tu sistema nervioso se recuperó completamente esta noche. Las \(h)h de sueño hicieron su trabajo.",
                action: babyCalm
                    ? "Aprovecha esta energía para conectar con tu bebé. Hoy tienes recursos para disfrutarlo."
                    : "El bebé necesita atención, y hoy estás en condiciones óptimas para responder con calma.",
                isAlert: false
            )

        case .normal:
            return EmpatheticInsight(
                title: "Equilibrio sostenible",
                explanation: "Tu HRV (\(hrv)ms) y tus \(h)h de sueño muestran que tu cuerpo está procesando bien el estrés de la crianza.",
                action: "Mantén el ritmo. Si el bebé está tranquilo, un momento de quietud ahora consolida tu recuperación.",
                isAlert: false
            )

        case .fatigued:
            return EmpatheticInsight(
                title: "Tu cuerpo pide pausa",
                explanation: "Con \(h)h de sueño y HRV de \(hrv)ms, tu sistema nervioso tiene reservas limitadas hoy. No es falla tuya — es biología.",
                action: babyCalm
                    ? "El bebé está tranquilo. Cierra los ojos 15 minutos ahora mismo — eso cambia tu tarde por completo."
                    : "Atiende al bebé, luego busca la primera ventana de calma para descansar aunque sea 10 minutos.",
                isAlert: false
            )

        case .stressed:
            return EmpatheticInsight(
                title: "Tensión acumulada detectada",
                explanation: "Tu HRV bajo (\(hrv)ms) revela que tu sistema nervioso está en modo alerta. El cuerpo de un padre sordo trabaja más al no poder descansar el oído.",
                action: "Pon una mano en tu pecho y siente tu ritmo cardíaco. Tres respiraciones largas — el Watch confirmará que bajan.",
                isAlert: true
            )

        case .hypervigilance:
            return EmpatheticInsight(
                title: "Modo hipervigilancia activo",
                explanation: "Llevas horas con todos los sentidos al máximo. Tu HRV (\(hrv)ms) lo confirma: tu sistema nervioso no ha podido bajar la guardia.",
                action: babyCalm
                    ? "El bebé está bien. LoveSpeaks está mirando por ti. Puedes soltar la guardia 20 minutos."
                    : "Atiende al bebé con calma — tu tensión se transfiere. Después busca un momento solo para ti.",
                isAlert: true
            )

        case .critical:
            return EmpatheticInsight(
                title: "Descanso urgente necesario",
                explanation: "Tu HRV de \(hrv)ms y las \(h)h de sueño indican agotamiento profundo. Tu cuerpo no puede seguir en este nivel sin consecuencias.",
                action: babyCalm
                    ? "El bebé está seguro. Acuéstate ahora. LoveSpeaks te alertará si algo cambia. 20 minutos pueden cambiar todo."
                    : "Pide ayuda si puedes. Si estás solo, atiende al bebé y descansa en cuanto puedas — esto es una señal seria.",
                isAlert: true
            )
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────

    private func publishMetrics(from snap: HealthSnapshot) {
        sleep      = SleepBreakdown(deep: snap.sleepDeep, core: snap.sleepCore, rem: snap.sleepREM)
        hrv        = snap.hrv
        heartRate  = snap.heartRate
        restingHR  = snap.restingHR
        steps      = Int(snap.steps)
        calories   = Int(snap.activeCalories)
        respRate   = snap.respiratoryRate
        weeklyHRV  = snap.weeklyHRV
        weeklySleep = snap.weeklySleep
        weeklySteps = snap.weeklySteps
        weekLabels = snap.weekLabels
    }

    private func computeRingScore(label: WellnessLabel, hrv: Double) -> Int {
        let base = Double(label.ringScore)
        let bonus = hrv > 0 ? min(max((hrv - 40) / 40.0 * 8, -8), 8) : 0
        return min(max(Int(base + bonus), 0), 100)
    }

    /// Llamado desde HomeViewModel cuando el estado del bebé cambia
    func updateBabySound(_ sound: BabySound) {
        currentBabySound = sound
        // Re-evalúa el label ajustado con el nuevo estado del bebé
        let adjusted = adjustForBabyState(wellnessLabel)
        if adjusted != wellnessLabel {
            wellnessLabel = adjusted
            ringScore = computeRingScore(label: adjusted, hrv: hrv)
        }
        Task { await generateEmpatheticInsight(from: wellnessLabel.rawValue) }
    }

    // ─────────────────────────────────────────
    // MARK: - Demo data
    // ─────────────────────────────────────────

    func loadDemoData() {
        lastSnapshot = HealthSnapshot(
            age: 28, sleepHours: 6.1, sleepScore: 70,
            steps: 4200, activeHours: 1.0,
            heartRate: 70, hrv: 41, energy: 58,
            sleepDeep: 1.3, sleepCore: 3.5, sleepREM: 1.3,
            restingHR: 63, activeCalories: 310, respiratoryRate: 14.0,
            weeklyHRV:   [42, 46, 37, 52, 48, 35, 41],
            weeklySleep: [6.5, 7.1, 5.7, 6.8, 7.4, 5.1, 6.1],
            weeklySteps: [5100, 7700, 3300, 6000, 8100, 2800, 4200],
            weekLabels:  ["Lun","Mar","Mié","Jue","Vie","Sáb","Hoy"]
        )
        publishMetrics(from: lastSnapshot)

        // Simular el modelo con datos demo
        wellnessLabel = .fatigued
        ringScore     = computeRingScore(label: .fatigued, hrv: 41)
        isLoadingHealth = false

        Task { await generateEmpatheticInsight(from: wellnessLabel.rawValue) }
    }

    // ─────────────────────────────────────────
    // MARK: - Date formatter
    // ─────────────────────────────────────────

    static func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "EEEE, d 'de' MMMM"
        return f.string(from: d).capitalized
    }
}
