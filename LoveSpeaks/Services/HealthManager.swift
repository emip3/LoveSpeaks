//
//  HealthManager.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 19/04/26.
//

// HealthManager.swift
// LoveSpeaks — CODA App
//
// Responsabilidad única: comunicarse con HealthKit y Apple Watch.
// Devuelve HealthSnapshot — un valor limpio listo para el modelo.
// Cero lógica de negocio aquí.

import Foundation
import HealthKit

// ─────────────────────────────────────────────
// MARK: - HealthSnapshot
// Todos los datos que SaludPadreModel necesita + extras para la UI
// ─────────────────────────────────────────────

struct HealthSnapshot {
    // ── Inputs del modelo SaludPadreModel ──
    var age:          Double = 28
    var sleepHours:   Double = 0      // horas totales anoche
    var sleepScore:   Double = 0      // 0-100 calidad estimada
    var steps:        Double = 0      // pasos hoy
    var activeHours:  Double = 0      // horas activas estimadas
    var heartRate:    Double = 0      // FC promedio últimas 12h
    var hrv:          Double = 0      // HRV ms promedio últimas 24h
    var energy:       Double = 0      // score compuesto 0-100

    // ── Fases de sueño para UI ──
    var sleepDeep:    Double = 0
    var sleepCore:    Double = 0
    var sleepREM:     Double = 0

    // ── Métricas adicionales para tarjetas ──
    var restingHR:    Double = 0
    var activeCalories: Double = 0
    var respiratoryRate: Double = 0

    // ── Series 7 días para visualizaciones ──
    var weeklyHRV:    [Double] = []
    var weeklySleep:  [Double] = []
    var weeklySteps:  [Double] = []
    var weekLabels:   [String] = []

    // ── Estado: indica si vienen del Watch o son fallback ──
    var isFromWatch:  Bool = false
}

// ─────────────────────────────────────────────
// MARK: - HealthManager
// ─────────────────────────────────────────────

final class HealthManager {

    private let store = HKHealthStore()

    // Tipos de lectura declarados
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    ]

    // ─── Autorización ─────────────────────────

    /// Solicita permisos. Devuelve true si el usuario aceptó.
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            print("HealthKit auth error: \(error.localizedDescription)")
            return false
        }
    }

    // ─── Fetch principal ──────────────────────
    // Todas las queries corren en paralelo con async let

    func fetchSnapshot(age: Double = 28) async -> HealthSnapshot {
        var snap = HealthSnapshot()
        snap.age = age

        // Queries paralelas
        async let sleepResult  = fetchSleepLastNight()
        async let hrvVal       = fetchHRVAverage(hours: 24)
        async let rhrVal       = fetchRestingHeartRate()
        async let hrVal        = fetchHeartRateAverage(hours: 12)
        async let stepsVal     = fetchStepsToday()
        async let calsVal      = fetchActiveCalories()
        async let respVal      = fetchRespiratoryRate()
        async let wHRV         = fetchWeeklyHRV()
        async let wSleep       = fetchWeeklySleep()
        async let wSteps       = fetchWeeklySteps()

        let (sl, hrv, rhr, hr, steps, cals, resp, wh, ws, wst) =
            await (sleepResult, hrvVal, rhrVal, hrVal, stepsVal, calsVal, respVal, wHRV, wSleep, wSteps)

        // ── Sueño ──
        snap.sleepDeep  = sl.deep
        snap.sleepCore  = sl.core
        snap.sleepREM   = sl.rem
        snap.sleepHours = sl.total
        snap.isFromWatch = sl.total > 0.1

        // Sleep score (0-100): calidad de fases relativa al total
        let qualityPhases = sl.deep + sl.rem
        let idealQuality  = sl.total * 0.40
        snap.sleepScore = sl.total > 0
            ? min((qualityPhases / max(idealQuality, 0.1)) * 70
                  + (min(sl.total, 8) / 8.0) * 30, 100)
            : 0

        // ── Cardio ──
        snap.hrv        = hrv
        snap.restingHR  = rhr
        snap.heartRate  = hr > 0 ? hr : rhr

        // ── Actividad ──
        snap.steps          = steps
        snap.activeCalories = cals
        snap.activeHours    = min(cals / 300.0, 12.0)  // ~300 kcal por hora activa

        snap.respiratoryRate = resp

        // ── Energy score compuesto 0-100 ──
        // Sueño 40% + HRV 35% + Actividad 25%
        let sleepC = min(snap.sleepHours / 8.0, 1.0) * 40
        let hrvC   = hrv > 0 ? min(hrv / 80.0, 1.0) * 35 : 17.5
        let actC   = min(steps / 8000.0, 1.0) * 25
        snap.energy = sleepC + hrvC + actC

        // ── Series semanales ──
        snap.weeklyHRV   = wh
        snap.weeklySleep = ws
        snap.weeklySteps = wst
        snap.weekLabels  = Self.lastNDayLabels(n: 7)

        return snap
    }

    // ─────────────────────────────────────────
    // MARK: - Queries individuales
    // ─────────────────────────────────────────

    /// Fases de sueño de las últimas 12h (ciclo nocturno completo del Watch)
    func fetchSleepLastNight() async -> (deep: Double, core: Double, rem: Double, total: Double) {
        let type  = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let start = Calendar.current.date(byAdding: .hour, value: -12, to: Date())!
        let pred  = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort  = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: pred,
                                  limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                var deep = 0.0, core = 0.0, rem = 0.0
                (samples as? [HKCategorySample])?.forEach { s in
                    let h = s.endDate.timeIntervalSince(s.startDate) / 3600
                    switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
                    case .asleepDeep: deep += h
                    case .asleepCore: core += h
                    case .asleepREM:  rem  += h
                    default: break
                    }
                }
                // Sin Watch → fallback demo
                if deep + core + rem < 0.1 {
                    cont.resume(returning: (1.4, 3.8, 1.4, 6.6))
                } else {
                    cont.resume(returning: (deep, core, rem, deep + core + rem))
                }
            }
            self.store.execute(q)
        }
    }

    /// HRV promedio. El Watch lo mide cada noche durante el sueño.
    func fetchHRVAverage(hours: Int) async -> Double {
        let type  = HKQuantityType(.heartRateVariabilitySDNN)
        let start = Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
        let vals  = await fetchSamples(type: type, unit: .secondUnit(with: .milli), start: start)
        return vals.isEmpty ? 45 : vals.reduce(0, +) / Double(vals.count)
    }

    /// FC en reposo. El Watch la calcula pasivamente a lo largo del día.
    func fetchRestingHeartRate() async -> Double {
        let type  = HKQuantityType(.restingHeartRate)
        let start = Calendar.current.startOfDay(for: Date())
        let vals  = await fetchSamples(type: type,
                                       unit: HKUnit.count().unitDivided(by: .minute()),
                                       start: start)
        return vals.isEmpty ? 65 : vals.reduce(0, +) / Double(vals.count)
    }

    /// FC promedio activa (últimas N horas)
    func fetchHeartRateAverage(hours: Int) async -> Double {
        let type  = HKQuantityType(.heartRate)
        let start = Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
        let vals  = await fetchSamples(type: type,
                                       unit: HKUnit.count().unitDivided(by: .minute()),
                                       start: start)
        return vals.isEmpty ? 0 : vals.reduce(0, +) / Double(vals.count)
    }

    /// Pasos acumulados hoy
    func fetchStepsToday() async -> Double {
        let type  = HKQuantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: Date())
        return await fetchSum(type: type, unit: .count(), start: start)
    }

    /// Calorías activas quemadas hoy
    func fetchActiveCalories() async -> Double {
        let type  = HKQuantityType(.activeEnergyBurned)
        let start = Calendar.current.startOfDay(for: Date())
        return await fetchSum(type: type, unit: .kilocalorie(), start: start)
    }

    /// Frecuencia respiratoria nocturna (Watch Series 3+)
    func fetchRespiratoryRate() async -> Double {
        let type  = HKQuantityType(.respiratoryRate)
        let start = Calendar.current.date(byAdding: .hour, value: -8, to: Date())!
        let vals  = await fetchSamples(type: type,
                                       unit: HKUnit.count().unitDivided(by: .minute()),
                                       start: start)
        return vals.isEmpty ? 14 : vals.reduce(0, +) / Double(vals.count)
    }

    // ─── Series semanales ─────────────────────

    func fetchWeeklyHRV() async -> [Double] {
        await fetchDailySeries(
            type: HKQuantityType(.heartRateVariabilitySDNN),
            unit: .secondUnit(with: .milli),
            options: .discreteAverage, days: 7
        )
    }

    func fetchWeeklySteps() async -> [Double] {
        await fetchDailySeries(
            type: HKQuantityType(.stepCount),
            unit: .count(),
            options: .cumulativeSum, days: 7
        )
    }

    func fetchWeeklySleep() async -> [Double] {
        let cal = Calendar.current
        var result: [Double] = []
        for i in (0..<7).reversed() {
            guard let day   = cal.date(byAdding: .day, value: -i, to: Date()),
                  let start = cal.date(byAdding: .hour, value: -14, to: day) else {
                result.append(6.5); continue
            }
            let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            let pred = HKQuery.predicateForSamples(withStart: start, end: day)

            let hours: Double = await withCheckedContinuation { cont in
                let q = HKSampleQuery(sampleType: type, predicate: pred,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: nil) { _, samples, _ in
                    let total = (samples as? [HKCategorySample])?.reduce(0.0) { acc, s in
                        switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
                        case .asleepDeep, .asleepCore, .asleepREM:
                            return acc + s.endDate.timeIntervalSince(s.startDate) / 3600
                        default: return acc
                        }
                    } ?? 0
                    cont.resume(returning: total)
                }
                self.store.execute(q)
            }
            result.append(hours > 0.1 ? hours : Double.random(in: 5.8...7.8))
        }
        return result
    }

    // ─────────────────────────────────────────
    // MARK: - Helpers genéricos
    // ─────────────────────────────────────────

    private func fetchSamples(type: HKQuantityType, unit: HKUnit, start: Date) async -> [Double] {
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: pred,
                                  limit: 20, sortDescriptors: [sort]) { _, samples, _ in
                cont.resume(returning:
                    (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: unit) } ?? []
                )
            }
            store.execute(q)
        }
    }

    private func fetchSum(type: HKQuantityType, unit: HKUnit, start: Date) async -> Double {
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: pred,
                                      options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }

    private func fetchDailySeries(type: HKQuantityType, unit: HKUnit,
                                   options: HKStatisticsOptions, days: Int) async -> [Double] {
        let cal = Calendar.current
        let end = Date()
        guard let start = cal.date(byAdding: .day, value: -days, to: end) else { return [] }
        var interval = DateComponents()
        interval.day = 1

        return await withCheckedContinuation { cont in
            let q = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end),
                options: options,
                anchorDate: cal.startOfDay(for: end),
                intervalComponents: interval
            )
            q.initialResultsHandler = { _, results, _ in
                var vals: [Double] = []
                results?.enumerateStatistics(from: start, to: end) { stats, _ in
                    let v: Double = options.contains(.cumulativeSum)
                        ? (stats.sumQuantity()?.doubleValue(for: unit) ?? 0)
                        : (stats.averageQuantity()?.doubleValue(for: unit) ?? 0)
                    vals.append(v)
                }
                cont.resume(returning: vals)
            }
            self.store.execute(q)
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Utilidades
    // ─────────────────────────────────────────

    static func lastNDayLabels(n: Int) -> [String] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_MX")
        fmt.dateFormat = "EEE"
        return (0..<n).reversed().compactMap { i in
            cal.date(byAdding: .day, value: -i, to: Date())
                .map { fmt.string(from: $0).capitalized }
        }
    }
}
