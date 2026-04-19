//
//  AudioClassifierService.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

// Manages the microphone, AVAudioEngine, and BOTH ML models:
//
//   1. Your custom .mlmodel (trained in Create ML)
//   2. Apple's built-in baby crying classifier via SoundAnalysis
//
// Results are published as a BabySound so any observer (ViewModel) can react without knowing anything about Core ML or AVAudio.

import Foundation
import AVFoundation
import SoundAnalysis
import CoreML
import Combine

// MARK: - AudioClassifierService

final class AudioClassifierService: NSObject, ObservableObject {

    // MARK: Published output

    /// The most recent merged detection result. Observed by HomeViewModel.
    @Published private(set) var currentSound: BabySound = .idle

    /// True while the mic is actively streaming audio to the models.
    @Published private(set) var isListening: Bool = false

    /// Non-nil when something goes wrong (permission denied, model missing, etc.)
    @Published private(set) var error: AudioClassifierError? = nil

    // MARK: Private – Audio Engine

    private let audioEngine = AVAudioEngine()

    // MARK: Private – Sound Analysis (both models share one analyzer)

    private var analyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.lovespeaks.audioAnalysis",
                                              qos: .userInitiated)

    // MARK: Private – Result tracking (for merging)

    /// Latest result from your custom model.
    private var customResult: (label: String, confidence: Double)?

    /// Latest result from Apple's model.
    private var appleResult: (label: String, confidence: Double)?

    // MARK: Configuration

    /// Minimum confidence (0–1) required before publishing a non-quiet result.
    private let confidenceThreshold: Double = 0.55

    /// Name of your .mlmodel file (without extension) as added to the Xcode target.
    /// ⚠️ Change this to match your actual model file name.
    private let customModelFileName = "LoveSpeaksML"

    // MARK: - Public API

    /// Request microphone permission and, if granted, start both classifiers.
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

    /// Stop the audio engine and tear down the analyzer.
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
            // 1. Configure AVAudioSession for recording
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            // 2. Get the native input format
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            // 3. Create the stream analyzer using the mic's native format
            let streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
            self.analyzer = streamAnalyzer

            // 4. Add requests to the analyzer
            try addCustomModelRequest(to: streamAnalyzer)
            try addAppleModelRequest(to: streamAnalyzer)

            // 5. Install tap on the input node — feeds audio into analyzer
            inputNode.installTap(onBus: 0,
                                 bufferSize: 8192,
                                 format: inputFormat) { [weak self] buffer, time in
                guard let self else { return }
                self.analysisQueue.async {
                    self.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
                }
            }

            // 6. Start the engine
            audioEngine.prepare()
            try audioEngine.start()

            DispatchQueue.main.async { self.isListening = true }

        } catch {
            DispatchQueue.main.async {
                self.error = .engineStartFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Private – Custom Model Request

    private func addCustomModelRequest(to analyzer: SNAudioStreamAnalyzer) throws {
        // Load YOUR trained .mlmodel from the app bundle
        guard let modelURL = Bundle.main.url(forResource: customModelFileName,
                                             withExtension: "mlmodelc") ??
                             Bundle.main.url(forResource: customModelFileName,
                                             withExtension: "mlmodel") else {
            // Not a fatal crash — just log and skip custom model
            print("⚠️ LoveSpeaks: '\(customModelFileName).mlmodel' not found in bundle. " +
                  "Make sure the file is added to the Xcode target.")
            self.error = .customModelNotFound
            return
        }

        let compiledURL: URL
        if modelURL.pathExtension == "mlmodel" {
            compiledURL = try MLModel.compileModel(at: modelURL)
        } else {
            compiledURL = modelURL
        }

        let mlModel = try MLModel(contentsOf: compiledURL)
        let customMLModel = try SNClassifySoundRequest(mlModel: mlModel)
        customMLModel.windowDuration = CMTimeMakeWithSeconds(1.5, preferredTimescale: 44_100)
        customMLModel.overlapFactor = 0.5

        try analyzer.add(customMLModel,
                         withObserver: CustomModelObserver { [weak self] label, confidence in
                             self?.didReceiveCustomResult(label: label, confidence: confidence)
                         })
    }

    // MARK: - Private – Apple Model Request

    private func addAppleModelRequest(to analyzer: SNAudioStreamAnalyzer) throws {
        // Apple's built-in classifier — no model file needed, ships with the OS.
        // Available on iOS 15+. Detects "baby_cry_infant_cry" among ~300 sound classes.
        let appleRequest = try SNClassifySoundRequest(classifierIdentifier: .version1)
        appleRequest.windowDuration = CMTimeMakeWithSeconds(1.5, preferredTimescale: 44_100)
        appleRequest.overlapFactor = 0.5

        try analyzer.add(appleRequest,
                         withObserver: AppleModelObserver { [weak self] label, confidence in
                             self?.didReceiveAppleResult(label: label, confidence: confidence)
                         })
    }

    // MARK: - Private – Result Merging

    private func didReceiveCustomResult(label: String, confidence: Double) {
        analysisQueue.async { [weak self] in
            guard let self else { return }
            self.customResult = (label, confidence)
            self.mergeAndPublish()
        }
    }

    private func didReceiveAppleResult(label: String, confidence: Double) {
        analysisQueue.async { [weak self] in
            guard let self else { return }
            // Apple's classifier returns many classes — we only care about baby crying
            if label.lowercased().contains("baby") || label.lowercased().contains("cry") || label.lowercased().contains("infant") {
                self.appleResult = (label, confidence)
                self.mergeAndPublish()
            }
        }
    }

    /// Merge both model results and decide what to publish.
    ///
    /// Priority rules:
    ///   1. If Apple detects crying with high confidence → publish crying (Apple is
    ///      trained on far more data for this specific class).
    ///   2. Otherwise, use your custom model result.
    ///   3. If confidence is below threshold → publish quiet/idle.
    private func mergeAndPublish() {
        // Apple's crying takes priority at ≥ 0.60 confidence
        if let apple = appleResult,
           apple.confidence >= 0.60 {
            let sound = BabySound(
                category: .crying,
                confidence: apple.confidence,
                source: .appleModel
            )
            publishIfChanged(sound)
            return
        }

        // Fall back to your custom model
        if let custom = customResult,
           custom.confidence >= confidenceThreshold {
            let category = SoundCategory.from(label: custom.label)
            let sound = BabySound(
                category: category,
                confidence: custom.confidence,
                source: .customModel
            )
            publishIfChanged(sound)
            return
        }

        // Nothing confident enough → idle
        publishIfChanged(.idle)
    }

    private func publishIfChanged(_ sound: BabySound) {
        guard sound != currentSound else { return }
        DispatchQueue.main.async { [weak self] in
            self?.currentSound = sound
        }
    }
}

// MARK: - SNResultsObserving Helpers

// These private observer classes decouple the callback from the service.

private final class CustomModelObserver: NSObject, SNResultsObserving {
    private let onResult: (String, Double) -> Void

    init(onResult: @escaping (String, Double) -> Void) {
        self.onResult = onResult
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult,
              let best = classificationResult.classifications.first else { return }
        onResult(best.identifier, best.confidence)
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("⚠️ Custom model error: \(error.localizedDescription)")
    }
}

private final class AppleModelObserver: NSObject, SNResultsObserving {
    private let onResult: (String, Double) -> Void

    init(onResult: @escaping (String, Double) -> Void) {
        self.onResult = onResult
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }

        // Filter only baby/cry related classifications from Apple's ~300 classes
        let babyCryClasses = ["baby_cry_infant_cry", "crying", "baby", "infant"]

        for classification in classificationResult.classifications {
            let id = classification.identifier.lowercased()
            if babyCryClasses.contains(where: { id.contains($0) }) {
                onResult(classification.identifier, classification.confidence)
                return
            }
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("⚠️ Apple model error: \(error.localizedDescription)")
    }
}

// MARK: - AudioClassifierError

enum AudioClassifierError: LocalizedError, Equatable {
    case microphonePermissionDenied
    case customModelNotFound
    case engineStartFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required to detect baby sounds. Please enable it in Settings."
        case .customModelNotFound:
            return "Custom ML model not found. Make sure BabySoundClassifier.mlmodel is added to the Xcode target."
        case .engineStartFailed(let msg):
            return "Audio engine failed to start: \(msg)"
        }
    }

    static func == (lhs: AudioClassifierError, rhs: AudioClassifierError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}
