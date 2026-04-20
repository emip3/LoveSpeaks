//
//  FullDataViewModel.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 19/04/26.
//

import SwiftUI
import Combine

@MainActor
final class FullDataViewModel: ObservableObject {
    @Published var selectedFilter: SoundCategory? = nil

    // This will eventually come from a persistence layer (SwiftData / CoreData)
    let history: [BabyRecord] = BabyRecord.sampleHistory

    // MARK: - Filtering

    func filteredEvents(for record: BabyRecord) -> [SoundEvent] {
        guard let filter = selectedFilter else { return record.events }
        return record.events.filter { $0.category == filter }
    }

    func visibleRecords() -> [BabyRecord] {
        history.filter { !filteredEvents(for: $0).isEmpty }
    }

    func toggleFilter(_ category: SoundCategory?) {
        withAnimation(.spring(response: 0.25)) {
            selectedFilter = (selectedFilter == category) ? nil : category
        }
    }

    // MARK: - Stats

    var totalEvents: Int {
        history.flatMap(\.events).count
    }

    var quietPeriods: Int {
        history.flatMap(\.events).filter {
            $0.category == .quiet
        }.count
    }

    var alertEvents: Int {
        history.flatMap(\.events).filter {
            $0.category == .crying
        }.count
    }

    var quietPercent: Int {
        guard totalEvents > 0 else { return 0 }
        return Int((Double(quietPeriods) / Double(totalEvents)) * 100)
    }
}
