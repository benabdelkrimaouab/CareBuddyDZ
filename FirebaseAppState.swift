import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import UserNotifications

struct AppointmentStatusNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class AppState: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var selectedTab: Int = 0
    @Published var currentUserProfile = UserProfile(firstName: "Patient", lastName: "Principal", phone: "0555123456", age: 35, email: "patient@email.com")
    @Published var doctors: [Doctor] = []
    @Published var activeDoctorID: UUID?
    @Published var authUserID: String?
    @Published var role: UserRole?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var appointmentStatusNotification: AppointmentStatusNotification?
    @Published var authChecked = false
    @Published var filteredAppointments: [Appointment] = []
    @AppStorage("notificationsEnabled")
    var notificationsEnabled = true

    private lazy var db = Firestore.firestore()
    private var doctorsListener: ListenerRegistration?
    private var appointmentsListener: ListenerRegistration?
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var knownAppointmentStatuses: [UUID: AppointmentStatus] = [:]
    private var autoRemovalTimers: [UUID: Timer] = [:]

    init() {
        doctors = Self.seedDoctors

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            authChecked = true
            return
        }

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self else { return }

                self.authUserID = user?.uid

                if user == nil {
                    self.role = nil
                    self.activeDoctorID = nil
                    self.appointments = []
                    self.knownAppointmentStatuses = [:]
                    self.detachListeners()
                    self.authChecked = true
                } else {
                    await self.loadCurrentUserProfile()
                    await self.loadRole()
                    self.startDoctorsListener()
                    self.startAppointmentsListener()
                    self.authChecked = true
                }
            }
        }
    }

    deinit {
        doctorsListener?.remove()
        appointmentsListener?.remove()
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
        autoRemovalTimers.values.forEach { $0.invalidate() }
    }

    var currentPatientName: String { currentUserProfile.fullName }
    var currentPatientEmail: String { currentUserProfile.email }

    var activeDoctor: Doctor? {
        guard let activeDoctorID else { return nil }
        return doctors.first { $0.id == activeDoctorID }
    }

    var patientAppointments: [Appointment] {
        guard let authUserID else { return appointments }
        return appointments.filter { $0.patientUID == authUserID }
    }

    var pendingAppointmentsForDoctor: [Appointment] {
        guard let authUserID else { return [] }
        return appointments.filter {
            $0.doctorUID == authUserID && $0.status == .pending
        }
    }

    var allAppointmentsForDoctor: [Appointment] {
        guard let authUserID else { return [] }
        return appointments.filter { $0.doctorUID == authUserID }
    }

    func reloadCurrentAuthUser() async {
        guard let user = Auth.auth().currentUser else {
            authUserID = nil
            role = nil
            activeDoctorID = nil
            appointments = []
            detachListeners()
            authChecked = true
            return
        }

        do {
            try await user.reload()
        } catch {
            do {
                try Auth.auth().signOut()
            } catch {
                errorMessage = error.localizedDescription
            }

            authUserID = nil
            role = nil
            activeDoctorID = nil
            appointments = []
            knownAppointmentStatuses = [:]
            detachListeners()
            authChecked = true
        }
    }

    func registerDoctor(from draft: DoctorDraft) async throws {
        guard let uid = authUserID else {
            throw ValidationError.message("Please sign in first.")
        }

        var doctor = try draft.toDoctor()
        doctor.ownerUID = uid

        let data = try Firestore.Encoder().encode(doctor)

        try await db.collection("doctors")
            .document(doctor.id.uuidString)
            .setData(data, merge: true)

        try await db.collection("users")
            .document(uid)
            .setData([
                "role": UserRole.doctor.rawValue,
                "doctorID": doctor.id.uuidString
            ], merge: true)

        activeDoctorID = doctor.id
        role = .doctor
        startAppointmentsListener()
    }

    func updateDoctorProfile(id: UUID, with draft: DoctorDraft) async throws {
        guard let index = doctors.firstIndex(where: { $0.id == id }) else { return }

        let existing = doctors[index]
        var updated = try draft.toDoctor(existingID: id, rating: existing.rating, reviews: existing.reviews)
        updated.ownerUID = existing.ownerUID

        let data = try Firestore.Encoder().encode(updated)

        try await db.collection("doctors")
            .document(id.uuidString)
            .setData(data, merge: true)
    }

    func updateUserProfile(with draft: UserProfileDraft) async throws {
        guard let uid = authUserID else {
            throw ValidationError.message("Please sign in first.")
        }

        let profile = try draft.toUserProfile()
        var data = try Firestore.Encoder().encode(profile)
        data["role"] = UserRole.patient.rawValue

        try await db.collection("users")
            .document(uid)
            .setData(data, merge: true)

        currentUserProfile = profile
        role = .patient
        startAppointmentsListener()
    }

    func bookAppointment(doctor: Doctor, date: Date, time: String) async throws {
        guard let uid = authUserID else {
            throw ValidationError.message("Please sign in first.")
        }

        guard let doctorUID = doctor.ownerUID, !doctorUID.isEmpty else {
            throw ValidationError.message("This doctor profile is not connected to a Firebase account.")
        }

        let appointment = Appointment(
            doctor: doctor,
            doctorUID: doctorUID,
            patientUID: uid,
            patientName: currentPatientName,
            patientEmail: currentPatientEmail,
            date: date,
            time: time,
            status: .pending,
            createdAt: Date(),
            statusChangedAt: nil
        )

        let data = try Firestore.Encoder().encode(appointment)

        appointments.insert(appointment, at: 0)

        try await db.collection("appointments")
            .document(appointment.id.uuidString)
            .setData(data)

        selectedTab = 2
    }

    func approveAppointment(_ appointment: Appointment) async throws {
        var updatedAppointment = appointment
        updatedAppointment.statusChangedAt = Date()
        
        try await setAppointment(updatedAppointment, status: .approved)
        scheduleAppointmentRemoval(appointmentID: appointment.id, delaySeconds: 86400) // 24 hours
    }

    func rejectAppointment(_ appointment: Appointment) async throws {
        var updatedAppointment = appointment
        updatedAppointment.statusChangedAt = Date()
        
        try await setAppointment(updatedAppointment, status: .rejected)
        scheduleAppointmentRemoval(appointmentID: appointment.id, delaySeconds: 86400) // 24 hours
    }

    func cancelAppointmentByPatient(_ appointment: Appointment) async throws {
        appointments.removeAll { $0.id == appointment.id }
        knownAppointmentStatuses.removeValue(forKey: appointment.id)
        autoRemovalTimers[appointment.id]?.invalidate()
        autoRemovalTimers.removeValue(forKey: appointment.id)

        try await db.collection("appointments")
            .document(appointment.id.uuidString)
            .delete()
    }

    private func setAppointment(_ appointment: Appointment, status: AppointmentStatus) async throws {
        try await db.collection("appointments")
            .document(appointment.id.uuidString)
            .updateData([
                "status": status.rawValue,
                "statusChangedAt": Timestamp(date: Date())
            ])
    }

    private func scheduleAppointmentRemoval(appointmentID: UUID, delaySeconds: Int) {
        autoRemovalTimers[appointmentID]?.invalidate()
        
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(delaySeconds), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.appointments.removeAll { $0.id == appointmentID }
                self?.knownAppointmentStatuses.removeValue(forKey: appointmentID)
                self?.autoRemovalTimers.removeValue(forKey: appointmentID)
            }
        }
        
        autoRemovalTimers[appointmentID] = timer
    }

    private func startDoctorsListener() {
        doctorsListener?.remove()

        doctorsListener = db.collection("doctors").addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let snapshot = snapshot else {
                    self.doctors = Self.seedDoctors
                    return
                }

                let fetched = snapshot.documents.compactMap { document in
                    try? document.data(as: Doctor.self)
                }

                if fetched.isEmpty {
                    self.doctors = Self.seedDoctors
                } else {
                    self.doctors = fetched.sorted { $0.rating > $1.rating }
                }
                
                print(" Doctors updated. Total: \(self.doctors.count)")
            }
        }
    }

    private func startAppointmentsListener() {
        appointmentsListener?.remove()
        knownAppointmentStatuses = [:]

        guard let uid = authUserID, let role else {
            appointments = []
            return
        }

        let query: Query

        if role == .patient {
            query = db.collection("appointments")
                .whereField("patientUID", isEqualTo: uid)
        } else {
            query = db.collection("appointments")
                .whereField("doctorUID", isEqualTo: uid)
        }

        appointmentsListener = query.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                let fetched = snapshot?.documents.compactMap { document in
                    try? document.data(as: Appointment.self)
                } ?? []

                let sortedAppointments = fetched.sorted { $0.date > $1.date }

                if self.role == .patient {
                    for appointment in sortedAppointments {
                        if let oldStatus = self.knownAppointmentStatuses[appointment.id],
                           oldStatus != appointment.status {

                            if appointment.status == .approved {

                                let title = "Rendez-vous accepté"
                                let message = "Votre demande avec \(appointment.doctor.name) a été acceptée."

                                self.appointmentStatusNotification =
                                AppointmentStatusNotification(
                                    title: title,
                                    message: message
                                )

                                if self.notificationsEnabled {

                                    NotificationManager.shared.sendNotification(
                                        title: title,
                                        body: message
                                    )
                                }

                                self.scheduleAppointmentRemoval(
                                    appointmentID: appointment.id,
                                    delaySeconds: 86400
                                )
                            }

                            if appointment.status == .rejected {

                                let title = "Rendez-vous refusé"
                                let message = "Votre demande avec \(appointment.doctor.name) a été refusée."

                                self.appointmentStatusNotification =
                                AppointmentStatusNotification(
                                    title: title,
                                    message: message
                                )

                                if self.notificationsEnabled {

                                    NotificationManager.shared.sendNotification(
                                        title: title,
                                        body: message
                                    )
                                }

                                self.scheduleAppointmentRemoval(
                                    appointmentID: appointment.id,
                                    delaySeconds: 86400
                                )
                            }
                        }
                    }
                }

                self.knownAppointmentStatuses = Dictionary(
                    uniqueKeysWithValues: sortedAppointments.map { ($0.id, $0.status) }
                )

                self.appointments = sortedAppointments
            }
        }
    }

    private func detachListeners() {
        doctorsListener?.remove()
        appointmentsListener?.remove()
        doctorsListener = nil
        appointmentsListener = nil
    }

    private func loadRole() async {
        guard let uid = authUserID else { return }

        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            let data = doc.data() ?? [:]

            role = (data["role"] as? String).flatMap(UserRole.init(rawValue:))

            if let doctorID = data["doctorID"] as? String {
                activeDoctorID = UUID(uuidString: doctorID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadCurrentUserProfile() async {
        guard let uid = authUserID else { return }

        do {
            let doc = try await db.collection("users").document(uid).getDocument()

            if let profile = try? doc.data(as: UserProfile.self) {
                currentUserProfile = profile
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Account Deletion

    func deleteAccount() async throws {
        guard let uid = authUserID else {
            throw ValidationError.message("No user is currently logged in.")
        }

        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.logout()
            }
        }

        if role == .doctor, let doctorID = activeDoctorID {
            try await db.collection("doctors")
                .document(doctorID.uuidString)
                .delete()
        }

        let appointmentDocs = try await db.collection("appointments")
            .whereField("patientUID", isEqualTo: uid)
            .getDocuments()

        for doc in appointmentDocs.documents {
            try await doc.reference.delete()
        }

        try await db.collection("users")
            .document(uid)
            .delete()

        try await Auth.auth().currentUser?.delete()
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            authUserID = nil
            role = nil
            activeDoctorID = nil
            appointments = []
            selectedTab = 0
            knownAppointmentStatuses = [:]
            autoRemovalTimers.values.forEach { $0.invalidate() }
            autoRemovalTimers.removeAll()
            detachListeners()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    static let seedDoctors: [Doctor] = [
        Doctor(
            firstName: "Amina",
            lastName: "Bensaid",
            specialty: "Cardiologie",
            rating: 4.9,
            reviews: 128,
            experience: 12,
            sex: "Femme",
            image: "heart.fill",
            price: 2500,
            hospital: "Clinique El Amal",
            location: "M'Sila",
            phone: "0555123456",
            license: "CARD10293",
            bio: "Spécialiste en cardiologie interventionnelle avec plus de 12 ans d'expérience.",
            availableTimes: ["09:00", "09:30", "10:00", "11:00", "14:00", "15:30", "16:00"]
        ),
        Doctor(
            firstName: "Karim",
            lastName: "Meziane",
            specialty: "Neurologie",
            rating: 4.7,
            reviews: 95,
            experience: 8,
            sex: "Homme",
            image: "brain.head.profile",
            price: 3000,
            hospital: "CHU M'Sila",
            location: "M'Sila",
            phone: "0661234567",
            license: "NEUR22310",
            bio: "Neurologue spécialisé dans les maladies dégénératives et les AVC.",
            availableTimes: ["08:30", "10:30", "11:30", "14:30", "16:30"]
        ),
        Doctor(
            firstName: "Fatima Zahra",
            lastName: "Hadj",
            specialty: "Pédiatrie",
            rating: 4.8,
            reviews: 210,
            experience: 15,
            sex: "Femme",
            image: "figure.and.child.holdinghands",
            price: 1800,
            hospital: "Polyclinique Centrale",
            location: "M'Sila",
            phone: "0771234567",
            license: "PEDI77890",
            bio: "Pédiatre avec une expertise en néonatologie et maladies infantiles.",
            availableTimes: ["09:00", "10:00", "11:00", "13:30", "14:30", "15:00"]
        )
    ]
}
