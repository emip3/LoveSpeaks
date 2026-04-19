//
//  BabySound.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

import SwiftUI

// MARK: - SoundCategory
// Single source of truth used by HomeViewModel, SummaryView, and FullDataView.

enum SoundCategory: String, CaseIterable {
    case hungry     = "Hungry"
    case discomfort = "Discomfort"
    case tired      = "Tired"
    case babbling   = "Babbling"
    case crying     = "Crying"
    case laughter   = "Laughter"
    case quiet      = "Quiet"

    // MARK: Display

    var displayTitle: String {
        switch self {
    
        case .hungry:     return "Baby is hungry"
        case .discomfort: return "Baby is uncomfortable"
        case .tired:      return "Baby is sleepy"
        case .babbling:   return "Baby is talking"
        case .crying:     return "Baby is crying"
        case .laughter:   return "Baby is laughing"
        case .quiet:      return "All quiet"
        }
    }

    var displayEmoji: String {
        switch self {
        
        case .hungry:     return "🍼"
        case .discomfort: return "😣"
        case .tired:      return "😴"
        case .babbling:   return "🗣️"
        case .crying:     return "😢"
        case .laughter:   return "😂"
        case .quiet:      return "🌙"
        }
    }

    // MARK: Colors (used by HomeView detection circle)

    var primaryColor: Color {
        switch self {
        
        case .hungry:     return Color(red: 1.0,  green: 0.55, blue: 0.0)
        case .discomfort: return Color(red: 0.95, green: 0.25, blue: 0.25)
        case .tired:      return Color(red: 0.55, green: 0.40, blue: 0.85)
        case .babbling:   return Color(red: 0.25, green: 0.75, blue: 0.65)
        case .crying:     return Color(red: 0.90, green: 0.20, blue: 0.20)
        case .laughter:   return Color(red: 1.0,  green: 0.75, blue: 0.20)
        case .quiet:      return Color(red: 0.55, green: 0.60, blue: 0.65)
        }
    }

    var secondaryColor: Color { primaryColor.opacity(0.25) }

    // MARK: Icon (used by SummaryView and FullDataView)

    var icon: String {
        switch self {
        
        case .hungry:     return "fork.knife"
        case .discomfort: return "bandage.fill"
        case .tired:      return "moon.fill"
        case .babbling:   return "ellipsis.bubble.fill"
        case .crying:     return "drop.fill"
        case .laughter:   return "face.smiling.fill"
        case .quiet:      return "speaker.slash.fill"
        }
    }

    // MARK: Color alias (used by SummaryView / FullDataView chip rows)

    var color: Color { primaryColor }

    // MARK: ML Label Mapping

    static func from(label: String) -> SoundCategory {
        switch label.lowercased() {
        case "laughter":                                        return .laughter
        case "babbling":                                        return .babbling
        case "hungry":                                          return .hungry
        case "discomfort":                                      return .discomfort
        case "tired":                                           return .tired
        case "ambient_noise":                                   return .quiet
        case "baby_cry_infant_cry", "crying",
             "baby crying", "infant crying":                    return .crying
        default:                                                return .quiet
        }
    }
}

// MARK: - SoundEvent
// A single detected or logged sound event. Used by SummaryView and FullDataView.

struct SoundEvent: Identifiable {
    let id = UUID()
    let time: String
    let category: SoundCategory
    let detail: String
}

// MARK: - BabySound
// Real-time detection result published by AudioClassifierService → HomeViewModel.

struct BabySound: Equatable {
    let category: SoundCategory
    let confidence: Double
    let source: DetectionSource

    var displayTitle: String  { category.displayTitle }
    var displayEmoji: String  { category.displayEmoji }
    var primaryColor: Color   { category.primaryColor }
    var secondaryColor: Color { category.secondaryColor }

    var confidenceText: String { "\(Int(confidence * 100))%" }

    static let idle = BabySound(category: .quiet, confidence: 1.0, source: .none)

    static func == (lhs: BabySound, rhs: BabySound) -> Bool {
        lhs.category == rhs.category && lhs.source == rhs.source
    }
}

// MARK: - DetectionSource

enum DetectionSource: String, Equatable {
    case customModel = "Custom Model"
    case appleModel  = "Apple Sound Analysis"
    case merged      = "Combined"
    case none        = "—"
}

// MARK: - BabyRecord
// A day's worth of logged sound events. Used by FullDataView and FullDataViewModel.

struct BabyRecord: Identifiable {
    let id = UUID()
    let date: String
    let dayLabel: String
    let events: [SoundEvent]
}

extension BabyRecord {
    static let sampleHistory: [BabyRecord] = [
        BabyRecord(
            date: "Hoy",
            dayLabel: "Sábado 18 abr",
            events: [
                SoundEvent(time: "07:12 AM", category: .hungry,     detail: "Llanto rítmico al despertar."),
                SoundEvent(time: "09:45 AM", category: .babbling,   detail: "Balbuceo activo post desayuno."),
                SoundEvent(time: "11:30 AM", category: .tired,      detail: "Frotando ojos, señal de sueño."),
                SoundEvent(time: "14:45 PM", category: .discomfort, detail: "Posibles gases tras la siesta."),
                SoundEvent(time: "16:05 PM", category: .babbling,   detail: "Comunicación activa. Todo bien."),
                SoundEvent(time: "18:22 PM", category: .laughter,   detail: "Risa espontánea prolongada."),
            ]
        ),
        BabyRecord(
            date: "Ayer",
            dayLabel: "Viernes 17 abr",
            events: [
                SoundEvent(time: "06:55 AM", category: .hungry,     detail: "Llanto al despertar, hambre."),
                SoundEvent(time: "10:10 AM", category: .laughter,   detail: "Risa al interactuar con papá."),
                SoundEvent(time: "13:00 PM", category: .crying,     detail: "Llanto fuerte sin causa clara."),
                SoundEvent(time: "15:30 PM", category: .tired,      detail: "Señales de cansancio post juego."),
                SoundEvent(time: "19:40 PM", category: .babbling,   detail: "Balbuceo tranquilo antes de dormir."),
            ]
        ),
        BabyRecord(
            date: "Hace 2 días",
            dayLabel: "Jueves 16 abr",
            events: [
                SoundEvent(time: "08:00 AM", category: .hungry,     detail: "Llanto matutino regular."),
                SoundEvent(time: "11:15 AM", category: .discomfort, detail: "Incomodidad, postura incómoda."),
                SoundEvent(time: "14:00 PM", category: .laughter,   detail: "Risa durante tummy time."),
                SoundEvent(time: "17:50 PM", category: .babbling,   detail: "Muchas vocales nuevas hoy."),
            ]
        ),
        BabyRecord(
            date: "Hace 3 días",
            dayLabel: "Miércoles 15 abr",
            events: [
                SoundEvent(time: "07:30 AM", category: .hungry,     detail: "Despertó con hambre puntual."),
                SoundEvent(time: "09:00 AM", category: .tired,      detail: "Siesta temprana, sueño profundo."),
                SoundEvent(time: "12:45 PM", category: .crying,     detail: "Llanto por cambio de pañal."),
                SoundEvent(time: "16:20 PM", category: .babbling,   detail: "Sesión larga de balbuceo."),
                SoundEvent(time: "20:05 PM", category: .tired,      detail: "Señales claras de ir a dormir."),
            ]
        ),
    ]
}
