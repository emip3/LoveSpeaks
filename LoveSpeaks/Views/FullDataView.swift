//
//  FullDataView.swift
//  LoveSpeaks
//

import SwiftUI

// MARK: - Main View

struct FullDataView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FullDataViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    StatsSummaryCard(viewModel: viewModel)
                        .padding(.top, 4)

                    FilterChipsRow(
                        selectedFilter: viewModel.selectedFilter,
                        onSelect: { viewModel.toggleFilter($0) }
                    )

                    timelineSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Historial de Lucas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Resumen")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.lsSalmon)
                    }
                }
            }
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(viewModel.visibleRecords()) { record in
                DaySection(
                    record: record,
                    events: viewModel.filteredEvents(for: record)
                )
            }
        }
    }
}

// MARK: - Stats Card

struct StatsSummaryCard: View {
    @ObservedObject var viewModel: FullDataViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Últimos 4 días")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color.lsSlate)

            HStack(spacing: 10) {
                MiniStatCard(value: "\(viewModel.totalEvents)", label: "Eventos",   color: Color.lsSky)
                MiniStatCard(value: "\(viewModel.happyPercent)%", label: "Bienestar", color: Color.lsMint)
                MiniStatCard(value: "\(viewModel.alertEvents)",  label: "Alertas",  color: Color.lsSalmon)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Índice de bienestar del período")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                    Spacer()
                    Text("\(viewModel.happyPercent)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.lsMint)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 99)
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 99)
                            .fill(
                                LinearGradient(
                                    colors: [Color.lsMint, Color.lsSky],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width * (Double(viewModel.happyPercent) / 100.0),
                                height: 7
                            )
                    }
                }
                .frame(height: 7)
            }
        }
        .padding(16)
        .background(Color.lsCream.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MiniStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Color.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Color.lsSlate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Filter Chips

struct FilterChipsRow: View {
    let selectedFilter: SoundCategory?
    let onSelect: (SoundCategory?) -> Void

    let filters: [(String, SoundCategory?, String)] = [
        ("Todos",     nil,          "square.grid.2x2.fill"),
        ("Hambre",    .hungry,      "fork.knife"),
        ("Cansancio", .tired,       "moon.fill"),
        ("Malestar",  .discomfort,  "bandage.fill"),
        ("Balbuceo",  .babbling,    "ellipsis.bubble.fill"),
        ("Risa",      .laughter,    "face.smiling.fill"),
        ("Llanto",    .crying,         "drop.fill"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.0) { label, category, icon in
                    let isSelected = selectedFilter == category
                    let chipColor  = category?.color ?? Color.lsSky

                    Button {
                        onSelect(category)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: icon)
                                .font(.system(size: 11, weight: .medium))
                            Text(label)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(isSelected ? Color.white : chipColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSelected ? chipColor : chipColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Day Section

struct DaySection: View {
    let record: BabyRecord
    let events: [SoundEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(record.date)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.primary)
                Text(record.dayLabel)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate)
                Spacer()
                Text("\(events.count) eventos")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(Capsule())
            }

            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    HistoryEventRow(event: event, isLast: index == events.count - 1)
                }
            }
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - History Event Row

struct HistoryEventRow: View {
    let event: SoundEvent
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            timelineColumn
            eventContent
        }
        .padding(.leading, 10)
    }

    private var timelineColumn: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(event.category.color)
                .frame(width: 10, height: 10)
                .padding(.top, 16)
            if !isLast {
                Rectangle()
                    .fill(event.category.color.opacity(0.2))
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 32)
    }

    private var eventContent: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(event.category.color.opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: event.category.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(event.category.color)
                )
                .padding(.top, 10)

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
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.lsSlate)
                    .lineSpacing(2)
            }
            .padding(.top, 10)
            .padding(.bottom, 14)
            .padding(.trailing, 14)
        }
    }
}

#Preview { FullDataView() }
