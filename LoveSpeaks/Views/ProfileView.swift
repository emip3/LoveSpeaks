//
//  ProfileView.swift
//  LoveSpeaks
//
//  Created by Emiliano Ruíz Plancarte on 18/04/26.
//

// Perfil del padre

// TODO: Gráfica "Índice de confianza"

// TODO: Ritmo cardiáco del padre (detectar estrés)

// TODO: Gráfica de sueño

// TODO: Botón de "DESCANSO" para activar solo las notificaciones de alerta.

import SwiftUI

struct ProfileView: View {
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
    ProfileView()
}
