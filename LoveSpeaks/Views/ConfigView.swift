//
//  ConfigView.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

// Configuración general de la app

// TODO: 

import SwiftUI

struct ConfigView: View {
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
    ConfigView()
}
