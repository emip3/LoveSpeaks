//
//  SummaryView.swift
//  LoveSpeaks
//

import SwiftUI

// SoundEvent and SoundCategory are defined in BabySound.swift

struct SummaryView: View {
    @StateObject private var viewModel = SummaryViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    titleHeader
                    aiSummaryCard
                    eventsList
                    historyButton
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showHistory) {
                FullDataView()
            }
        }
    }

    private var titleHeader: some View {
        Text("Resumen del día")
            .font(.system(size: 26, weight: .heavy, design: .rounded))
            .foregroundColor(Color.primary)
            .padding(.top, 8)
    }

    private var aiSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("+ RESUMEN IA")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color.lsSalmon)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(viewModel.aiSummaryBullets, id: \.self) { bullet in
                    LSBulletRow(text: bullet)
                }
            }
        }
        .padding(16)
        .background(Color.lsCream.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var eventsList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.events) { event in
                LSEventRow(event: event)
            }
        }
    }

    private var historyButton: some View {
        Button {
            viewModel.showHistory = true
        } label: {
            Text("Historial de registros")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color.lsSlate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(Capsule().stroke(Color.lsSlate.opacity(0.4), lineWidth: 0.5))
        }
        .padding(.bottom, 110)
    }
}

// MARK: - Reusable Subviews

struct LSBulletRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.lsSalmon)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(Color(UIColor.label).opacity(0.75))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct LSEventRow: View {
    let event: SoundEvent
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(event.category.primaryColor.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: event.category.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(event.category.primaryColor)
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.category.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primary)
                    Spacer()
                    Text(event.time)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                }
                Text(event.detail)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(Color.lsSlate)
            }
        }
        .padding(10)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(event.category.primaryColor)
                .frame(width: 3)
                .padding(.vertical, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview { SummaryView() }
