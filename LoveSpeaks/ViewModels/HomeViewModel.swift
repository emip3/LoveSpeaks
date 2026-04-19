//
//  HomeViewModel.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

// Bridges AudioClassifierService → HomeView.
// Owns the service lifecycle and exposes only what the View needs.

import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published state (consumed by HomeView)

    /// The current detected baby sound, ready to display.
    @Published private(set) var currentSound: BabySound = .idle

    /// Whether the app is actively listening.
    @Published private(set) var isListening: Bool = false

    /// Non-nil when there's an error to surface to the user.
    @Published private(set) var errorMessage: String? = nil

    /// Controls the alert shown when there's an error.
    @Published var showingError: Bool = false

    /// Pulse animation toggle — flips every second while listening,
    /// driving the animated ring in HomeView.
    @Published private(set) var isPulsing: Bool = false

    // MARK: - Private

    private let service = AudioClassifierService()
    private var cancellables = Set<AnyCancellable>()
    private var pulseTimer: AnyCancellable?

    // MARK: - Init

    init() {
        bindService()
    }

    // MARK: - Public API

    /// Toggle listening on/off. Called by HomeView's main button.
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        service.start()
        startPulseTimer()
    }

    func stopListening() {
        service.stop()
        stopPulseTimer()
        currentSound = .idle
    }

    // MARK: - Private – Service Binding

    private func bindService() {
        // Forward isListening
        service.$isListening
            .receive(on: DispatchQueue.main)
            .assign(to: &$isListening)

        // Forward currentSound
        service.$currentSound
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSound)

        // Handle errors
        service.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.errorDescription }
            .sink { [weak self] message in
                self?.errorMessage = message
                self?.showingError = true
                self?.stopPulseTimer()
            }
            .store(in: &cancellables)
    }

    // MARK: - Private – Pulse Timer

    private func startPulseTimer() {
        pulseTimer = Timer.publish(every: 1.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.6)) {
                    self?.isPulsing.toggle()
                }
            }
    }

    private func stopPulseTimer() {
        pulseTimer?.cancel()
        pulseTimer = nil
        isPulsing = false
    }

    // MARK: - Computed helpers for HomeView

    /// Short status line shown below the main circle.
    var statusText: String {
        if !isListening { return "Tap to start listening" }
        if currentSound.category == .quiet { return "Listening..." }
        return "Detected with \(currentSound.confidenceText) confidence"
    }

    /// Label for the toggle button.
    var buttonLabel: String {
        isListening ? "Stop Listening" : "Start Listening"
    }

    /// Icon for the toggle button.
    var buttonIcon: String {
        isListening ? "mic.fill" : "mic.slash.fill"
    }
}
