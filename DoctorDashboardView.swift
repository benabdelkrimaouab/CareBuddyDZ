import SwiftUI
import MapKit

struct DoctorDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showEditProfile = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.medBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    DoctorDashboardHeader(
                        showEditProfile: $showEditProfile,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )

                    Picker("Dashboard tabs", selection: $selectedTab) {
                        Text("Tous (En attente, Accepté, Refusé)").tag(0)
                        Text("En attente").tag(1)
                        Text("Profile").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        allAppointmentsView
                    } else if selectedTab == 1 {
                        requestsView
                    } else {
                        doctorProfileView
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                if let doctor = appState.activeDoctor {
                    DoctorProfileEditorView(doctor: doctor)
                        .environmentObject(appState)
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await appState.deleteAccount()
                        } catch {
                            appState.errorMessage = error.localizedDescription
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.")
            }
        }
    }

    @ViewBuilder
    private var requestsView: some View {
        if appState.pendingAppointmentsForDoctor.isEmpty {
            Spacer()
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 48))
                    .foregroundColor(.medSubtext.opacity(0.5))

                Text("Aucune demande en attente")
                    .font(.headline)
                    .foregroundColor(.medSubtext)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(appState.pendingAppointmentsForDoctor) { appointment in
                        DoctorRequestCardView(appointment: appointment)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private var allAppointmentsView: some View {
        if appState.allAppointmentsForDoctor.isEmpty {
            Spacer()
            VStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.system(size: 48))
                    .foregroundColor(.medSubtext.opacity(0.5))

                Text("Aucun rendez-vous")
                    .font(.headline)
                    .foregroundColor(.medSubtext)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(appState.allAppointmentsForDoctor) { appointment in
                        DoctorAllAppointmentsCardView(appointment: appointment)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private var doctorProfileView: some View {
        if let doctor = appState.activeDoctor {
            ScrollView {
                VStack(spacing: 14) {
                    doctorInfoCard(label: "Location", value: doctor.location, icon: "mappin.and.ellipse")
                    doctorInfoCard(label: "Doctor", value: doctor.name, icon: "person.text.rectangle")
                    doctorInfoCard(label: "Specialty", value: doctor.specialty, icon: "stethoscope")
                    doctorInfoCard(label: "Price", value: "\(doctor.price) DA", icon: "banknote.fill")
                    doctorInfoCard(label: "Clinic", value: doctor.hospital, icon: "cross.case.fill")
                    doctorInfoCard(label: "Location", value: doctor.location, icon: "mappin.and.ellipse")
                    doctorInfoCard(label: "License", value: doctor.license, icon: "doc.text.fill")
            
                    if let latitude = Double(
                        doctor.location.components(separatedBy: "|")
                            .first?
                            .replacingOccurrences(of: "Lat:", with: "")
                            .trimmingCharacters(in: .whitespaces) ?? ""
                    ),
                    let longitude = Double(
                        doctor.location.components(separatedBy: "|")
                            .last?
                            .replacingOccurrences(of: "Lon:", with: "")
                            .trimmingCharacters(in: .whitespaces) ?? ""
                    ) {

                        VStack(alignment: .leading, spacing: 10) {

                            Text("Clinic Location")
                                .font(.headline)

                            Map(
                                initialPosition: .region(
                                    MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(
                                            latitude: latitude,
                                            longitude: longitude
                                        ),
                                        span: MKCoordinateSpan(
                                            latitudeDelta: 0.01,
                                            longitudeDelta: 0.01
                                        )
                                    )
                                )
                            ) {

                                Marker(
                                    doctor.hospital,
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: latitude,
                                        longitude: longitude
                                    )
                                )
                            }
                            .frame(height: 250)
                            .cornerRadius(18)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                        Text(doctor.bio)
                            .foregroundColor(.medSubtext)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(18)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available times")
                            .font(.headline)
                        Text(doctor.availableTimes.joined(separator: ", "))
                            .foregroundColor(.medSubtext)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(18)

                    Button("Edit profile") {
                        showEditProfile = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.medPrimary)
                    .cornerRadius(16)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Account")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
        } else {
            Spacer()
            ContentUnavailableView("No registered doctor", systemImage: "stethoscope")
            Spacer()
        }
    }

    private func doctorInfoCard(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.medPrimary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.medSubtext)
                Text(value)
                    .foregroundColor(.medText)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
    }
}

struct DoctorDashboardHeader: View {
    @EnvironmentObject var appState: AppState
    @Binding var showEditProfile: Bool
    @Binding var showDeleteConfirmation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tableau du médecin")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.medText)

                    Text(appState.activeDoctor?.name ?? "Create your doctor profile")
                        .font(.system(size: 14))
                        .foregroundColor(.medSubtext)
                }

                Spacer()

                Button {
                    appState.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.red)
                        .clipShape(Circle())
                }

                if appState.activeDoctor != nil {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.medPrimary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct DoctorRequestCardView: View {
    @EnvironmentObject var appState: AppState
    let appointment: Appointment

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE dd MMM yyyy"
        return formatter.string(from: appointment.date).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.patientName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.medText)

                    Text(appointment.patientEmail)
                        .font(.system(size: 12))
                        .foregroundColor(.medSubtext)
                }

                Spacer()

                Text("En attente")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label(appointment.doctor.name, systemImage: "person.text.rectangle")
                Label(appointment.doctor.specialty, systemImage: "stethoscope")
                Label(formattedDate, systemImage: "calendar")
                Label(appointment.time, systemImage: "clock")
            }
            .font(.system(size: 13))
            .foregroundColor(.medSubtext)

            HStack(spacing: 10) {
                Button(action: {
                    Task { try? await appState.rejectAppointment(appointment) }
                }) {
                    Text("Refuser")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }

                Button(action: {
                    Task { try? await appState.approveAppointment(appointment) }
                }) {
                    Text("Accepter")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: [Color.medPrimary, Color.medSecondary], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct DoctorAllAppointmentsCardView: View {
    @EnvironmentObject var appState: AppState
    let appointment: Appointment

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE dd MMM yyyy"
        return formatter.string(from: appointment.date).capitalized
    }

    var statusBadge: (String, Color, String) {
        switch appointment.status {
        case .pending:
            return ("En attente", .orange, "clock")
        case .approved:
            return ("Accepté", .green, "checkmark.circle.fill")
        case .rejected:
            return ("Refusé", .red, "xmark.circle.fill")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.patientName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.medText)

                    Text(appointment.patientEmail)
                        .font(.system(size: 12))
                        .foregroundColor(.medSubtext)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: statusBadge.2)
                        .font(.system(size: 10, weight: .semibold))
                    Text(statusBadge.0)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusBadge.1)
                .cornerRadius(8)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label(appointment.doctor.name, systemImage: "person.text.rectangle")
                Label(appointment.doctor.specialty, systemImage: "stethoscope")
                Label(formattedDate, systemImage: "calendar")
                Label(appointment.time, systemImage: "clock")
            }
            .font(.system(size: 13))
            .foregroundColor(.medSubtext)

            if appointment.status == .pending {
                HStack(spacing: 10) {
                    Button(action: {
                        Task { try? await appState.rejectAppointment(appointment) }
                    }) {
                        Text("Refuser")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        Task { try? await appState.approveAppointment(appointment) }
                    }) {
                        Text("Accepter")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(LinearGradient(colors: [Color.medPrimary, Color.medSecondary], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(10)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: appointment.status == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(appointment.status == .approved ? .green : .red)
                    Text(appointment.status == .approved ? "Appointment confirmed" : "Appointment declined")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(appointment.status == .approved ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(appointment.status == .approved ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct DoctorProfileEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let doctor: Doctor
    @State private var draft: DoctorDraft
    @State private var errorMessage = ""
    @State private var showAlert = false

    init(doctor: Doctor) {
        self.doctor = doctor
        _draft = State(initialValue: DoctorDraft(doctor: doctor))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("First name", text: $draft.firstName)
                    TextField("Last name", text: $draft.lastName)
                    TextField("Specialty", text: $draft.specialty)
                    TextField("License", text: $draft.license)
                }

                Section("Contact") {
                    TextField("Phone", text: $draft.phone)
                        .keyboardType(.numberPad)
                    TextField("Age", text: $draft.age)
                        .keyboardType(.numberPad)
                    TextField("Price in DA", text: $draft.price)
                        .keyboardType(.numberPad)
                }

                Section("Location") {
                    TextField("Hospital / Clinic", text: $draft.hospital)
                    TextField("City / Location", text: $draft.location)
                }

                Section("Profile") {
                    TextEditor(text: $draft.bio)
                        .frame(minHeight: 100)
                    TextField("Available times", text: $draft.availableTimesText)
                }
            }
            .navigationTitle("Edit doctor profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDoctor()
                    }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveDoctor() {
        Task {
            do {
                try await appState.updateDoctorProfile(id: doctor.id, with: draft)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

#Preview {
    DoctorDashboardView()
        .environmentObject(AppState())
}
