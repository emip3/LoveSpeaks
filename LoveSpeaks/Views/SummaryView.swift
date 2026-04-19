import SwiftUI

struct SoundEvent: Identifiable {
    let id = UUID()
    let time: String
    let category: SoundCategory
    let detail: String
}

enum SoundCategory: String {
    case hungry     = "Hungry"
    case tired      = "Tired"
    case discomfort = "Discomfort"
    case babbling   = "Babbling"
    case laughter   = "Laughter"
    case cry        = "Cry"

    var color: Color {
        switch self {
        case .hungry:     return Color.lsHungry
        case .tired:      return Color.lsTired
        case .discomfort: return Color.lsDiscomfort
        case .babbling:   return Color.lsBabbling
        case .laughter:   return Color.lsLaughter
        case .cry:        return Color.lsCry
        }
    }

    var icon: String {
        switch self {
        case .hungry:     return "fork.knife"
        case .tired:      return "moon.fill"
        case .discomfort: return "bandage.fill"
        case .babbling:   return "ellipsis.bubble.fill"
        case .laughter:   return "face.smiling.fill"
        case .cry:        return "drop.fill"
        }
    }
}

struct SummaryView: View {
    @State private var showHistory = false

    let events: [SoundEvent] = [
        SoundEvent(time: "09:15 AM", category: .hungry,     detail: "Llanto sostenido con ritmo regular."),
        SoundEvent(time: "11:30 AM", category: .tired,      detail: "Frotando ojos, llanto débil y corto."),
        SoundEvent(time: "14:45 PM", category: .discomfort, detail: "Señales de malestar. Posibles gases."),
        SoundEvent(time: "16:05 PM", category: .babbling,   detail: "Balbuceo activo. Todo bien."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Resumen del día")
                        .font(Font.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.primary)
                        .padding(.top, 8)

                    // MARK: AI Summary Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("+ RESUMEN IA")
                            .font(Font.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.lsSalmon)

                        VStack(alignment: .leading, spacing: 6) {
                            LSBulletRow(text: "El bebé ha mostrado 4 episodios de sonido identificados.")
                            LSBulletRow(text: "Discomfort detectado a las 14:45 — posibles gases.")
                            LSBulletRow(text: "1 episodio de balbuceo activo: buen desarrollo.")
                            LSBulletRow(text: "Noche anterior: 5h 40min de sueño continuo.")
                        }
                    }
                    .padding(16)
                    .background(Color.lsCream.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // MARK: Events List
                    VStack(spacing: 8) {
                        ForEach(events) { event in
                            LSEventRow(event: event)
                        }
                    }

                    // MARK: History Button
                    Button {
                        showHistory = true
                    } label: {
                        Text("Historial de registros")
                            .font(Font.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.lsSlate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                Capsule().stroke(Color.lsSlate.opacity(0.4), lineWidth: 0.5)
                            )
                    }
                    .padding(.bottom, 110)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showHistory) {
                FullDataView()
            }
        }
    }
}

struct LSBulletRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(Font.system(size: 13, weight: .bold))
                .foregroundColor(Color.lsSalmon)
                .padding(.top, 1)
            Text(text)
                .font(Font.system(size: 13, weight: .regular, design: .rounded))
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
                .fill(event.category.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: event.category.icon)
                        .font(Font.system(size: 14, weight: .medium))
                        .foregroundColor(event.category.color)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Llanto · \(event.category.rawValue)")
                        .font(Font.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primary)
                    Spacer()
                    Text(event.time)
                        .font(Font.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                }
                Text(event.detail)
                    .font(Font.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(Color.lsSlate)
            }
        }
        .padding(10)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(event.category.color)
                .frame(width: 3)
                .padding(.vertical, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview { SummaryView() }
