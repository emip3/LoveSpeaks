//
//  HomeViewModel.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

//
//  HomeViewModel.swift
//  LoveSpeaks
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Estado Publicado
    @Published private(set) var currentSound: BabySound = .idle
    @Published private(set) var isListening: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published var showingError: Bool = false

    // MARK: - Privado
    private let service = AudioClassifierService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        bindService()
    }

    // MARK: - Interfaz Pública
    func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    func startListening() {
        service.start()
    }

    func stopListening() {
        service.stop()
        currentSound = .idle
    }

    // MARK: - Binding
    private func bindService() {
        service.$isListening
            .receive(on: DispatchQueue.main)
            .assign(to: &$isListening)

        service.$currentSound
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSound)

        service.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.errorDescription }
            .sink { [weak self] message in
                self?.errorMessage = message
                self?.showingError = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers de UI
    var statusText: String {
        if !isListening { return "Toca para empezar a escuchar" }
        if currentSound.category == .crying {
            return "Llanto detectado con \(currentSound.confidenceText) de confianza"
        }
        return "Escuchando..."
    }

    var buttonLabel: String {
        isListening ? "Detener" : "Empezar a escuchar"
    }

    var buttonIcon: String {
        isListening ? "mic.fill" : "mic.slash.fill"
    }

    var primaryActionButtonColor: Color {
        isListening ? Color.lsSlate.opacity(0.75) : currentSound.primaryColor.opacity(0.85)
    }
}
