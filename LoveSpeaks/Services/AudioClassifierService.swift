//
//  AudioClassifierService.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

// Manages the microphone, AVAudioEngine, and Apple's built-in baby cry classifier.
// Publishes a BabySound (.crying or .quiet) so any observer can react
// without knowing anything about SoundAnalysis or AVAudio.

import Foundation
import AVFoundation
import SoundAnalysis
import Combine

// MARK: - AudioClassifierService

final class AudioClassifierService: NSObject, ObservableObject {

    // MARK: Published output

    @Published private(set) var currentSound: BabySound = .idle
    @Published private(set) var isListening: Bool = false
    @Published private(set) var error: AudioClassifierError? = nil

    // MARK: Private – Audio Engine

    private let audioEngine = AVAudioEngine()

    // MARK: Private – Sound Analysis

    private var analyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.lovespeaks.audioAnalysis",
                                              qos: .userInitiated)

    // MARK: Configuration

    /// Minimum confidence required to publish a crying event.
    private let confidenceThreshold: Double = 0.50

    // MARK: - Public API

    func start() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    self.startEngine()
                } else {
                    self.error = .microphonePermissionDenied
                }
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        analyzer = nil
        isListening = false
        currentSound = .idle
    }

    // MARK: - Private – Engine Setup

    private func startEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            let streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
            self.analyzer = streamAnalyzer

            try addAppleModelRequest(to: streamAnalyzer)

            inputNode.installTap(onBus: 0,
                                 bufferSize: 8192,
                                 format: inputFormat) { [weak self] buffer, time in
                guard let self else { return }
                self.analysisQueue.async {
                    self.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
                }
            }

            audioEngine.prepare()
            try audioEngine.start()

            DispatchQueue.main.async { self.isListening = true }
            print("✅ AudioEngine iniciado correctamente.")

        } catch {
            DispatchQueue.main.async {
                self.error = .engineStartFailed(error.localizedDescription)
            }
            print("❌ Error al iniciar AudioEngine: \(error)")
        }
    }

    // MARK: - Private – Apple Model Request

    private func addAppleModelRequest(to analyzer: SNAudioStreamAnalyzer) throws {
        // Apple's built-in classifier — ships with the OS, no model file needed.
        // Available on iOS 15+.
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        request.windowDuration = CMTimeMakeWithSeconds(1.5, preferredTimescale: 44_100)
        request.overlapFactor = 0.5

        try analyzer.add(request, withObserver: AppleModelObserver { [weak self] confidence in
            self?.didReceiveResult(confidence: confidence)
        })
    }

    // MARK: - Private – Result Handling

    private func didReceiveResult(confidence: Double) {
        let sound: BabySound = confidence >= confidenceThreshold
            ? BabySound(category: .crying, confidence: confidence)
            : .idle

        guard sound != currentSound else { return }
        DispatchQueue.main.async { [weak self] in
            self?.currentSound = sound
        }
    }
}

// MARK: - SNResultsObserving Helper

private final class AppleModelObserver: NSObject, SNResultsObserving {
    private let onResult: (Double) -> Void

    init(onResult: @escaping (Double) -> Void) {
        self.onResult = onResult
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }

        // 🔍 DEBUG temporal: muestra los top 5 identificadores en consola.
        // Comenta o elimina este bloque una vez que todo funcione.
        #if DEBUG
        classificationResult.classifications.prefix(5).forEach {
            print("🔊 \($0.identifier.padding(toLength: 35, withPad: " ", startingAt: 0)) → \(Int($0.confidence * 100))%")
        }
        #endif

        // ✅ Fix: identificador real del modelo de Apple para llanto
        let confidence = classificationResult.classifications
            .first(where: { $0.identifier == "crying_sobbing" })?
            .confidence ?? 0.0

        onResult(confidence)
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("⚠️ Apple model error: \(error.localizedDescription)")
    }
}

// MARK: - AudioClassifierError

enum AudioClassifierError: LocalizedError, Equatable {
    case microphonePermissionDenied
    case engineStartFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Se necesita acceso al micrófono para detectar el llanto. Actívalo en Ajustes."
        case .engineStartFailed(let msg):
            return "El motor de audio no pudo iniciar: \(msg)"
        }
    }

    static func == (lhs: AudioClassifierError, rhs: AudioClassifierError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}
