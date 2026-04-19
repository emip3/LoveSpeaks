//
//  SummaryViewModel.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 19/04/26.
//

import SwiftUI
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {
    @Published var showHistory: Bool = false

    // This will eventually come from a data layer / persistence
    let events: [SoundEvent] = [
        SoundEvent(time: "09:15 AM", category: .hungry,     detail: "Llanto sostenido con ritmo regular."),
        SoundEvent(time: "11:30 AM", category: .tired,      detail: "Frotando ojos, llanto débil y corto."),
        SoundEvent(time: "14:45 PM", category: .discomfort, detail: "Señales de malestar. Posibles gases."),
        SoundEvent(time: "16:05 PM", category: .babbling,   detail: "Balbuceo activo. Todo bien."),
    ]

    // This will eventually come from Apple Intelligence / SummarizationAPI
    var aiSummaryBullets: [String] {
        [
            "El bebé ha mostrado \(events.count) episodios de sonido identificados.",
            "Discomfort detectado a las 14:45 — posibles gases.",
            "1 episodio de balbuceo activo: buen desarrollo.",
            "Noche anterior: 5h 40min de sueño continuo.",
        ]
    }
}
