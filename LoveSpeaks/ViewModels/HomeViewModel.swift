//
//  HomeViewModel.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
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

    // MARK: - Propiedades Privadas
    private let service = AudioClassifierService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        bindService()
    }

    // MARK: - Interfaz Pública
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        service.start()
    }

    func stopListening() {
        service.stop()
        currentSound = .idle
    }

    // MARK: - Vinculación con el Servicio
    private func bindService() {
        // Estado de escucha
        service.$isListening
            .receive(on: DispatchQueue.main)
            .assign(to: &$isListening)

        // Sonido actual detectado
        service.$currentSound
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSound)

        // Manejo de errores
        service.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.errorDescription }
            .sink { [weak self] message in
                self?.errorMessage = message
                self?.showingError = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers de Texto y Color
    var statusText: String {
        if !isListening { return "Toca para empezar a escuchar" }
        if currentSound.category == .quiet { return "Escuchando..." }
        return "Detectado con \(currentSound.confidenceText) de confianza"
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
