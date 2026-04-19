import SwiftUI

// MARK: - Model
struct BabyRecord: Identifiable {
    let id = UUID()
    let date: String
    let dayLabel: String
    let events: [SoundEvent]
}

// MARK: - Sample Data
extension BabyRecord {
    static let sampleHistory: [BabyRecord] = [
        BabyRecord(
            date: "Hoy",
            dayLabel: "Sábado 18 abr",
            events: [
                SoundEvent(time: "07:12 AM", category: .hungry,     detail: "Llanto rítmico al despertar."),
                SoundEvent(time: "09:45 AM", category: .babbling,   detail: "Balbuceo activo post desayuno."),
                SoundEvent(time: "11:30 AM", category: .tired,      detail: "Frotando ojos, señal de sueño."),
                SoundEvent(time: "14:45 PM", category: .discomfort, detail: "Posibles gases tras la siesta."),
                SoundEvent(time: "16:05 PM", category: .babbling,   detail: "Comunicación activa. Todo bien."),
                SoundEvent(time: "18:22 PM", category: .laughter,   detail: "Risa espontánea prolongada."),
            ]
        ),
        BabyRecord(
            date: "Ayer",
            dayLabel: "Viernes 17 abr",
            events: [
                SoundEvent(time: "06:55 AM", category: .hungry,     detail: "Llanto al despertar, hambre."),
                SoundEvent(time: "10:10 AM", category: .laughter,   detail: "Risa al interactuar con papá."),
                SoundEvent(time: "13:00 PM", category: .cry,        detail: "Llanto fuerte sin causa clara."),
                SoundEvent(time: "15:30 PM", category: .tired,      detail: "Señales de cansancio post juego."),
                SoundEvent(time: "19:40 PM", category: .babbling,   detail: "Balbuceo tranquilo antes de dormir."),
            ]
        ),
        BabyRecord(
            date: "Hace 2 días",
            dayLabel: "Jueves 16 abr",
            events: [
                SoundEvent(time: "08:00 AM", category: .hungry,     detail: "Llanto matutino regular."),
                SoundEvent(time: "11:15 AM", category: .discomfort, detail: "Incomodidad, postura incómoda."),
                SoundEvent(time: "14:00 PM", category: .laughter,   detail: "Risa durante tummy time."),
                SoundEvent(time: "17:50 PM", category: .babbling,   detail: "Muchas vocales nuevas hoy."),
            ]
        ),
        BabyRecord(
            date: "Hace 3 días",
            dayLabel: "Miércoles 15 abr",
            events: [
                SoundEvent(time: "07:30 AM", category: .hungry,     detail: "Despertó con hambre puntual."),
                SoundEvent(time: "09:00 AM", category: .tired,      detail: "Siesta temprana, sueño profundo."),
                SoundEvent(time: "12:45 PM", category: .cry,        detail: "Llanto por cambio de pañal."),
                SoundEvent(time: "16:20 PM", category: .babbling,   detail: "Sesión larga de balbuceo."),
                SoundEvent(time: "20:05 PM", category: .tired,      detail: "Señales claras de ir a dormir."),
            ]
        ),
    ]
}

// MARK: - Main View
struct FullDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: SoundCategory? = nil

    let history = BabyRecord.sampleHistory

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Stats Summary
                    StatsSummaryCard(history: history)
                        .padding(.top, 4)

                    // MARK: Filter Chips
                    FilterChipsRow(selected: $selectedFilter)

                    // MARK: Timeline
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(history) { record in
                            let filtered = selectedFilter == nil
                                ? record.events
                                : record.events.filter { $0.category == selectedFilter }

                            if !filtered.isEmpty {
                                DaySection(record: record, events: filtered)
                            }
                        }
                    }

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
                                .font(Font.system(size: 14, weight: .semibold))
                            Text("Resumen")
                                .font(Font.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.lsSalmon)
                    }
                }
            }
        }
    }
}

// MARK: - Stats Card
struct StatsSummaryCard: View {
    let history: [BabyRecord]

    var totalEvents: Int { history.flatMap(\.events).count }
    var happyEvents: Int { history.flatMap(\.events).filter { $0.category == .laughter || $0.category == .babbling }.count }
    var alertEvents: Int { history.flatMap(\.events).filter { $0.category == .cry || $0.category == .discomfort }.count }

    var happyPercent: Int {
        guard totalEvents > 0 else { return 0 }
        return Int((Double(happyEvents) / Double(totalEvents)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Últimos 4 días")
                .font(Font.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color.lsSlate)

            HStack(spacing: 10) {
                MiniStatCard(value: "\(totalEvents)", label: "Eventos", color: Color.lsSky)
                MiniStatCard(value: "\(happyPercent)%", label: "Bienestar", color: Color.lsMint)
                MiniStatCard(value: "\(alertEvents)", label: "Alertas", color: Color.lsSalmon)
            }

            // Progress bar bienestar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Índice de bienestar del período")
                        .font(Font.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                    Spacer()
                    Text("\(happyPercent)%")
                        .font(Font.system(size: 11, weight: .bold, design: .rounded))
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
                            .frame(width: geo.size.width * (Double(happyPercent) / 100.0), height: 7)
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
                .font(Font.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Color.primary)
            Text(label)
                .font(Font.system(size: 10, weight: .medium, design: .rounded))
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
    @Binding var selected: SoundCategory?

    let filters: [(String, SoundCategory?, String)] = [
        ("Todos",       nil,          "square.grid.2x2.fill"),
        ("Hambre",      .hungry,      "fork.knife"),
        ("Cansancio",   .tired,       "moon.fill"),
        ("Malestar",    .discomfort,  "bandage.fill"),
        ("Balbuceo",    .babbling,    "ellipsis.bubble.fill"),
        ("Risa",        .laughter,    "face.smiling.fill"),
        ("Llanto",      .cry,         "drop.fill"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.0) { label, category, icon in
                    let isSelected = selected == category
                    let chipColor  = category?.color ?? Color.lsSky

                    Button {
                        withAnimation(Animation.spring(response: 0.25)) {
                            selected = isSelected ? nil : category
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: icon)
                                .font(Font.system(size: 11, weight: .medium))
                            Text(label)
                                .font(Font.system(size: 12, weight: .semibold, design: .rounded))
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
            // Day header
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(record.date)
                    .font(Font.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.primary)
                Text(record.dayLabel)
                    .font(Font.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate)
                Spacer()
                Text("\(events.count) eventos")
                    .font(Font.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.lsSlate)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(Capsule())
            }

            // Events
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

// MARK: - History Event Row (timeline style)
struct HistoryEventRow: View {
    let event: SoundEvent
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // Timeline column
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

            // Content
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(event.category.color.opacity(0.15))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: event.category.icon)
                            .font(Font.system(size: 13, weight: .medium))
                            .foregroundColor(event.category.color)
                    )
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(event.category.rawValue)
                            .font(Font.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primary)
                        Spacer()
                        Text(event.time)
                            .font(Font.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Color.lsSlate)
                    }
                    Text(event.detail)
                        .font(Font.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                        .lineSpacing(2)
                }
                .padding(.top, 10)
                .padding(.bottom, 14)
                .padding(.trailing, 14)
            }
        }
        .padding(.leading, 10)
        if !isLast {
            Divider()
                .opacity(0)
        }
    }
}

#Preview { FullDataView() }

import SwiftUI

struct FullDataView: View {
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
    FullDataView()
}
