import SwiftUI

struct ConfigView: View {
    @State private var shareHealthData   = true
    @State private var microphoneAccess  = true
    @State private var pushNotifications = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LSToggleRow(
                        icon: "heart.fill",
                        iconColor: Color.lsSalmon,
                        title: "Compartir datos de Salud",
                        subtitle: "Acceso a Apple Health para FC y HRV",
                        isOn: $shareHealthData
                    )
                    LSToggleRow(
                        icon: "mic.fill",
                        iconColor: Color.lsSky,
                        title: "Permisos de Micrófono",
                        subtitle: "Necesario para detectar sonidos del bebé",
                        isOn: $microphoneAccess
                    )
                    LSToggleRow(
                        icon: "bell.fill",
                        iconColor: Color.lsMint,
                        title: "Notificaciones Push",
                        subtitle: "Recibe alertas cuando se detecte un sonido",
                        isOn: $pushNotifications
                    )
                } header: {
                    Text("Permisos")
                        .font(Font.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                }

                Section {
                    NavigationLink(destination: EmptyView()) {
                        Label {
                            Text("Perfil del bebé")
                                .font(Font.system(size: 15, weight: .medium, design: .rounded))
                        } icon: {
                            Image(systemName: "figure.and.child.holdinghands")
                                .foregroundColor(Color.lsSky)
                        }
                    }
                    NavigationLink(destination: EmptyView()) {
                        Label {
                            Text("Dispositivos conectados")
                                .font(Font.system(size: 15, weight: .medium, design: .rounded))
                        } icon: {
                            Image(systemName: "applewatch")
                                .foregroundColor(Color.lsMint)
                        }
                    }
                } header: {
                    Text("Cuenta")
                        .font(Font.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                }

                Section {
                    HStack {
                        Text("Versión")
                            .font(Font.system(size: 15, design: .rounded))
                            .foregroundColor(Color.primary)
                        Spacer()
                        Text("1.0.0 (1)")
                            .font(Font.system(size: 15, design: .rounded))
                            .foregroundColor(Color.lsSlate)
                    }
                    HStack {
                        Text("Desarrollado con ♥ para papás")
                            .font(Font.system(size: 13, design: .rounded))
                            .foregroundColor(Color.lsSlate)
                        Spacer()
                    }
                } header: {
                    Text("Sobre la app")
                        .font(Font.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.lsSlate)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct LSToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(iconColor.opacity(0.18))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(Font.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color.primary)
                Text(subtitle)
                    .font(Font.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.lsSlate)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.lsSalmon)
        }
        .padding(.vertical, 4)
    }
}

#Preview { ConfigView() }
