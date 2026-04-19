//
//  BabySound.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

// Models/BabySound.swift
// LoveSpeaks
//
// Represents a detected baby sound event with all display properties.

import SwiftUI

// MARK: - Sound Category

/// High-level emotional categories derived from raw ML labels.
enum SoundCategory: String, CaseIterable {
    case happy      = "happy"
    case hungry     = "hungry"
    case discomfort = "discomfort"
    case tired      = "tired"
    case babbling   = "babbling"
    case crying     = "crying"
    case quiet      = "quiet"

    // MARK: Display Properties

    var displayTitle: String {
        switch self {
        case .happy:      return "Baby is happy!"
        case .hungry:     return "Baby is hungry"
        case .discomfort: return "Baby is uncomfortable"
        case .tired:      return "Baby is sleepy"
        case .babbling:   return "Baby is talking"
        case .crying:     return "Baby is crying"
        case .quiet:      return "All quiet"
        }
    }

    var displayEmoji: String {
        switch self {
        case .happy:      return "😄"
        case .hungry:     return "🍼"
        case .discomfort: return "😣"
        case .tired:      return "😴"
        case .babbling:   return "🗣️"
        case .crying:     return "😢"
        case .quiet:      return "🌙"
        }
    }

    var primaryColor: Color {
        switch self {
        case .happy:      return Color(red: 1.0, green: 0.85, blue: 0.0)   // Warm yellow
        case .hungry:     return Color(red: 1.0, green: 0.55, blue: 0.0)   // Orange
        case .discomfort: return Color(red: 0.95, green: 0.25, blue: 0.25) // Red
        case .tired:      return Color(red: 0.55, green: 0.40, blue: 0.85) // Soft purple
        case .babbling:   return Color(red: 0.25, green: 0.75, blue: 0.65) // Teal/mint
        case .crying:     return Color(red: 0.90, green: 0.20, blue: 0.20) // Deep red
        case .quiet:      return Color(red: 0.55, green: 0.60, blue: 0.65) // Slate grey
        }
    }

    var secondaryColor: Color {
        primaryColor.opacity(0.25)
    }

    /// Maps a raw ML label string → SoundCategory.
    /// Handles both your custom model labels and Apple's Sound Analysis labels.
    static func from(label: String) -> SoundCategory {
        switch label.lowercased() {

        // ── Your custom model labels ──────────────────────────────────────
        case "laughter":
            return .happy
        case "babbling":
            return .babbling
        case "hungry":
            return .hungry
        case "discomfort":
            return .discomfort
        case "tired":
            return .tired
        case "ambient_noise":
            return .quiet

        // ── Apple's built-in Sound Analysis labels ────────────────────────
        // The Apple "Baby crying" classifier uses these identifiers:
        case "baby_cry_infant_cry", "crying", "baby crying", "infant crying":
            return .crying

        default:
            return .quiet
        }
    }
}

// MARK: - BabySound

/// A single sound detection result, ready for the UI to consume.
struct BabySound: Equatable {
    let category: SoundCategory
    let confidence: Double      // 0.0 – 1.0
    let source: DetectionSource

    // MARK: Convenience accessors (delegates to category)

    var displayTitle: String    { category.displayTitle }
    var displayEmoji: String    { category.displayEmoji }
    var primaryColor: Color     { category.primaryColor }
    var secondaryColor: Color   { category.secondaryColor }

    /// Human-readable confidence percentage, e.g. "87%"
    var confidenceText: String {
        "\(Int(confidence * 100))%"
    }

    // MARK: Default / idle state

    static let idle = BabySound(
        category: .quiet,
        confidence: 1.0,
        source: .none
    )

    // MARK: Equatable

    static func == (lhs: BabySound, rhs: BabySound) -> Bool {
        lhs.category == rhs.category && lhs.source == rhs.source
    }
}

// MARK: - DetectionSource

/// Which model produced the result.
enum DetectionSource: String, Equatable {
    case customModel  = "Custom Model"
    case appleModel   = "Apple Sound Analysis"
    case merged       = "Combined"
    case none         = "—"
}
