//
//  SummaryViewModel.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 19/04/26.
//

//
//  SummaryViewModel.swift
//  LoveSpeaks
//

import SwiftUI
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {
    @Published var showHistory: Bool = false

    // This will eventually come from a data layer / persistence
    let events: [SoundEvent] = [
        SoundEvent(time: "07:12 AM", category: .crying, detail: "Llanto al despertar."),
        SoundEvent(time: "11:30 AM", category: .crying, detail: "Llanto antes de la siesta."),
        SoundEvent(time: "14:45 PM", category: .crying, detail: "Llanto post siesta."),
        SoundEvent(time: "18:22 PM", category: .crying, detail: "Llanto al anochecer."),
    ]

    // This will eventually come from Apple Intelligence / SummarizationAPI
    var aiSummaryBullets: [String] {
        [
            "Se detectaron \(events.count) episodios de llanto hoy.",
            "El episodio más largo fue a las 11:30 AM.",
            "Promedio de \(events.count * 3) minutos entre episodios.",
            "Sin episodios detectados durante la noche.",
        ]
    }
}
