//
//  ProfileViewModel.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 19/04/26.
//

import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var showBreathing: Bool = false

    // MARK: - Biometrics
    // These will eventually come from HealthKit / Apple Watch
    let tranquilityLevel: Double = 0.35
    let heartRate: String = "72"
    let hrv: String = "48"
    let heartRateTrend: String = "↗"
    let hrvTrend: String = "↘"

    // MARK: - AI Insight
    // This will eventually come from a HealthKit + CoreML pipeline
    var aiInsight: String {
        "Tu FC está elevada, pero el bebé está tranquilo. Toma un momento para ti."
    }

    // MARK: - Derived
    var tranquilityPercent: Int {
        Int(tranquilityLevel * 100)
    }

    var tranquilityLabel: String {
        switch tranquilityLevel {
        case 0..<0.4:  return "Necesitas un descanso"
        case 0.4..<0.7: return "Moderadamente tranquilo"
        default:        return "Muy tranquilo"
        }
    }
}
