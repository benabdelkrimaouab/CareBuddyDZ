import SwiftUI

struct DoctorView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.medBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    ProfileHeaderView(showEditProfile: $showEditProfile)

                    HStack(spacing: 0) {
                        TabButton(title: "My appointment", isSelected: selectedTab == 0) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = 0
                            }
                        }

                        TabButton(title: "My profile ", isSelected: selectedTab == 1) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = 1
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    if selectedTab == 0 {
                        PatientAppointmentListView()
                    } else {
                        ProfileDetailsView(showEditProfile: $showEditProfile)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                PatientProfileEditorView()
                    .environmentObject(appState)
            }
            .alert(item: $appState.appointmentStatusNotification) { notification in
                Alert(
                    title: Text(notification.title),
                    message: Text(notification.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct ProfileHeaderView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showEditProfile: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.medPrimary, Color.medSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 160)
                .offset(x: 150, y: -20)

            VStack(spacing: 12) {
                HStack {
                    Spacer()

                    Button {
                        appState.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.20))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 84, height: 84)

                    Image(systemName: "person.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.white)
                }

                VStack(spacing: 4) {
                    Text(appState.currentUserProfile.fullName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text(appState.currentUserProfile.email)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.bottom, 22)
            .padding(.top, 55)
        }
        .frame(height: 230)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .medPrimary : .medSubtext)

                Rectangle()
                    .fill(isSelected ? Color.medPrimary : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct PatientAppointmentListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            if appState.patientAppointments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 54))
                        .foregroundColor(.medSubtext.opacity(0.45))

                    Text("No Appoitments scheuled ")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.medText)

                    Text("Requests you send to a doctor will appear here with their status.")
                        .font(.system(size: 13))
                        .foregroundColor(.medSubtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 42)
                }
                .padding(.top, 65)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(appState.patientAppointments) { appointment in
                        PatientAppointmentCardView(appointment: appointment)
                    }
                }
                .padding()
            }
        }
    }
}

struct PatientAppointmentCardView: View {
    @EnvironmentObject var appState: AppState
    let appointment: Appointment

    @State private var showCancelAlert = false
    @State private var errorMessage = ""
    @State private var showError = false

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE dd MMM yyyy"
        return formatter.string(from: appointment.date).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.medPrimary.opacity(0.12))
                            .frame(width: 50, height: 50)

                        Image(systemName: appointment.doctor.image)
                            .font(.system(size: 21))
                            .foregroundColor(.medPrimary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.doctor.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.medText)

                        Text(appointment.doctor.specialty)
                            .font(.system(size: 12))
                            .foregroundColor(.medSubtext)
                    }
                }

                Spacer()

                Text(appointment.status.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(appointment.status.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(appointment.status.color.opacity(0.12))
                    .cornerRadius(10)
            }

            Divider()

            VStack(alignment: .leading, spacing: 9) {
                Label(formattedDate, systemImage: "calendar")
                Label(appointment.time, systemImage: "clock.fill")
                Label(appointment.doctor.displayLocation, systemImage: "mappin.and.ellipse")
            }
            .font(.system(size: 13))
            .foregroundColor(.medSubtext)

            if appointment.status == .pending {
                Button {
                    showCancelAlert = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Annuler la demande")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(14)
                }
            } else if appointment.status == .approved {
                Text("Le médecin a accepté votre rendez-vous.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
            } else {
                Text("Le médecin a refusé cette demande.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
            }
        }
        .padding(17)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 5)
        .alert("Annuler la demande ?", isPresented: $showCancelAlert) {
            Button("Non", role: .cancel) {}

            Button("Oui, annuler", role: .destructive) {
                cancelAppointment()
            }
        } message: {
            Text("Cette demande sera supprimée de Mes RDV.")
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func cancelAppointment() {
        Task {
            do {
                try await appState.cancelAppointmentByPatient(appointment)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct ProfileDetailsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showEditProfile: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ProfileSection(title: "Informations personnelles") {
                    ProfileRow(icon: "person.fill", label: "Nom complet", value: appState.currentUserProfile.fullName)
                    ProfileRow(icon: "phone.fill", label: "Téléphone", value: appState.currentUserProfile.phone)
                    ProfileRow(icon: "envelope.fill", label: "Email", value: appState.currentUserProfile.email)
                    ProfileRow(icon: "birthday.cake.fill", label: "Âge", value: "\(appState.currentUserProfile.age) ans")
                }

                Button {
                    showEditProfile = true
                } label: {
                    Label("Modifier le profil", systemImage: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.medPrimary)
                        .cornerRadius(14)
                }

                Button {
                    appState.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(14)
                }

                ProfileSection(title: "Paramètres") {
                    ProfileRow(icon: "bell.fill", label: "Notifications", value: "Activées")
                    ProfileRow(icon: "lock.fill", label: "Confidentialité", value: "")
                    ProfileRow(icon: "questionmark.circle.fill", label: "Aide & Support", value: "")
                }
            }
            .padding()
        }
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.medSubtext)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.medPrimary.opacity(0.1))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.medPrimary)
                }

                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.medText)

                Spacer()

                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.medSubtext)

                if value.isEmpty {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.medSubtext.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, 62)
        }
    }
}

struct PatientProfileEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = UserProfileDraft()
    @State private var errorMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("First name", text: $draft.firstName)
                    TextField("Last name", text: $draft.lastName)
                    TextField("Email", text: $draft.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("Contact") {
                    TextField("Phone", text: $draft.phone)
                        .keyboardType(.numberPad)
                    TextField("Age", text: $draft.age)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
            .onAppear {
                draft = UserProfileDraft(profile: appState.currentUserProfile)
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveProfile() {
        Task {
            do {
                try await appState.updateUserProfile(with: draft)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

#Preview {
    DoctorView()
        .environmentObject(AppState())
}
