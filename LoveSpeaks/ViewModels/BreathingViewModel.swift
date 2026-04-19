//
//  BreathingViewModel.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 19/04/26.
//

import SwiftUI
import Combine

enum BreathPhase: String {
    case inhale = "Inhala"
    case hold   = "Sostén"
    case exhale = "Exhala"
}

@MainActor
final class BreathingViewModel: ObservableObject {
    @Published var phase: BreathPhase = .inhale
    @Published var scale: CGFloat = 1.0
    @Published var cycleCount: Int = 0
    @Published var finished: Bool = false

    let totalCycles = 3

    var subText: String {
        switch phase {
        case .inhale: return "Lucas está en calma.\nDisfruta tu respiro."
        case .hold:   return "Mantén el aire. Casi\nterminas."
        case .exhale: return "Lucas está en calma.\nDisfruta tu respiro."
        }
    }

    var phaseDuration: Double {
        switch phase {
        case .inhale: return 4.0
        case .hold:   return 2.0
        case .exhale: return 4.0
        }
    }

    func startCycles() {
        runCycle()
    }

    private func runCycle() {
        guard cycleCount < totalCycles else {
            withAnimation { finished = true }
            return
        }
        phase = .inhale
        withAnimation(.easeInOut(duration: 4)) { scale = 1.28 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self else { return }
            self.phase = .hold

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self else { return }
                self.phase = .exhale
                withAnimation(.easeInOut(duration: 4)) { self.scale = 1.0 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                    guard let self else { return }
                    self.cycleCount += 1
                    self.runCycle()
                }
            }
        }
    }
}
