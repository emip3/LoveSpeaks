//
//  BabySound.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

import SwiftUI
import Foundation
import Combine
import SoundAnalysis
import AVFoundation

// MARK: - SoundCategory
enum SoundCategory: String, CaseIterable {
    case crying = "crying_sobbing"  
    case quiet  = "quiet"

    var displayTitle: String {
        switch self {
        case .crying: return "Bebé llorando"
        case .quiet:  return "Todo tranquilo"
        }
    }

    var displayEmoji: String {
        switch self {
        case .crying: return "😢"
        case .quiet:  return "🌙"
        }
    }

    var primaryColor: Color {
        switch self {
        case .crying: return Color.red
        case .quiet:  return Color.gray
        }
    }

    var secondaryColor: Color { primaryColor.opacity(0.2) }

    var icon: String {
        switch self {
        case .crying: return "drop.fill"
        case .quiet:  return "speaker.slash.fill"
        }
    }
}

// MARK: - BabySound Model
struct BabySound: Equatable {
    let category: SoundCategory
    let confidence: Double

    var displayTitle: String  { category.displayTitle }
    var displayEmoji: String  { category.displayEmoji }
    var primaryColor: Color   { category.primaryColor }
    var secondaryColor: Color { category.secondaryColor }
    var confidenceText: String { "\(Int(confidence * 100))%" }

    static let idle = BabySound(category: .quiet, confidence: 1.0)
}

// MARK: - Sound Classifier Manager
class SoundClassifierManager: NSObject, ObservableObject, SNResultsObserving {
    @Published var currentSound: BabySound = .idle
    @Published var isRunning: Bool = false

    // ✅ Fix: umbral reducido a 0.4 para testing; súbelo a 0.65–0.75 en producción
    private let confidenceThreshold: Double = 0.4

    // ✅ Identificador real del clasificador de Apple para llanto
    private let cryingIdentifier = "crying_sobbing"

    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.lovespeaks.analysis")

    func toggleDetection() {
        if isRunning { stop() } else { start() }
    }

    private func start() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try session.setActive(true)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            analyzer = SNAudioStreamAnalyzer(format: format)

            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            try analyzer?.add(request, withObserver: self)

            inputNode.installTap(onBus: 0, bufferSize: 8192, format: format) { [weak self] buffer, time in
                self?.analysisQueue.async {
                    self?.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
                }
            }

            try audioEngine.start()
            isRunning = true
            print("✅ Detección de sonido iniciada correctamente.")
        } catch {
            print("❌ Error al iniciar detección: \(error)")
        }
    }

    private func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        analyzer = nil
        isRunning = false
        currentSound = .idle
        print("🛑 Detección de sonido detenida.")
    }

    // MARK: - SNResultsObserving
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }

        // 🔍 DEBUG: imprime los top 5 identificadores con su confianza.
        // Úsalo para confirmar el identificador correcto en tu versión de iOS.
        // Comenta o elimina este bloque una vez que todo funcione.
        #if DEBUG
        let top5 = result.classifications.prefix(5)
        print("──────────────────────────────────")
        for c in top5 {
            print("🔊 \(c.identifier.padding(toLength: 30, withPad: " ", startingAt: 0)) → \(Int(c.confidence * 100))%")
        }
        #endif

        // ✅ Busca el identificador correcto de llanto
        let target = result.classifications.first(where: { $0.identifier == cryingIdentifier })

        DispatchQueue.main.async {
            if let target, target.confidence > self.confidenceThreshold {
                self.currentSound = BabySound(category: .crying, confidence: target.confidence)
            } else {
                self.currentSound = .idle
            }
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("❌ Error en el clasificador: \(error.localizedDescription)")
    }

    func requestDidComplete(_ request: SNRequest) {
        print("ℹ️ Clasificador completado.")
    }
}

// MARK: - Historial
struct SoundEvent: Identifiable {
    let id = UUID()
    let time: String
    let category: SoundCategory
    let detail: String
}

struct BabyRecord: Identifiable {
    let id = UUID()
    let date: String
    let dayLabel: String
    let events: [SoundEvent]
}

extension BabyRecord {
    static let sampleHistory: [BabyRecord] = [
        BabyRecord(date: "Hoy", dayLabel: "Sábado 18 abr", events: [
            SoundEvent(time: "07:12 AM", category: .crying, detail: "Llanto al despertar.")
        ])
    ]
}
