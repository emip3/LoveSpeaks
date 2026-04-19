//
//  SummaryView.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

// Resúmen del día del infante.

// TODO: Ícono del bebé con información

// TODO: Incluir Apple Intelligence o SummarizationAPI para generar resúmen.

// TODO: Emociones de hoy (bebé)

// TODO: Botón para ir a "FullDataView.swift"

import SwiftUI

struct SummaryView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)
                    .symbolRenderingMode(.hierarchical)

                Text("Summary")
                    .font(.largeTitle).bold()

                Text("Your conversation insights will appear here.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Summary")
        }
    }
}

#Preview {
    SummaryView()
}
