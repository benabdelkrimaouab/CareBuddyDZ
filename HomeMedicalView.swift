import SwiftUI
import Foundation
import MapKit
import CoreLocation

struct HomeMedicalView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var selectedSpecialty = "ALL"
    @State private var sortOption = "Popularité"
    @State private var searchText: String = ""
    @State private var coordinate = CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588)

    var specialties: [String] {
        ["ALL"] + Array(Set(appState.doctors.map(\.specialty))).sorted()
    }

    let sortOptions = ["Popularité", "Prix", "Expérience"]

    var filteredDoctors: [Doctor] {
        let filtered = appState.doctors.filter { doctor in
            let matchSearch = searchText.isEmpty ||
            doctor.name.localizedCaseInsensitiveContains(searchText) ||
            doctor.specialty.localizedCaseInsensitiveContains(searchText) ||
            doctor.hospital.localizedCaseInsensitiveContains(searchText) ||
            doctor.location.localizedCaseInsensitiveContains(searchText)

            let matchSpecialty = selectedSpecialty == "ALL" || doctor.specialty == selectedSpecialty
            return matchSearch && matchSpecialty
        }

        switch sortOption {
        case "Prix":
            return filtered.sorted { $0.price < $1.price }
        case "Expérience":
            return filtered.sorted { $0.experience > $1.experience }
        default:
            return filtered.sorted { $0.rating > $1.rating }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.medBackground,
                        Color.white,
                        Color.medPrimary.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        modernHeader

                        SearchBarView(searchText: $searchText)
                            .padding(.horizontal, 20)

                        Picker("Trier", selection: $sortOption) {
                            ForEach(sortOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(specialties, id: \.self) { spec in
                                    SpecialtyChip(title: spec, isSelected: selectedSpecialty == spec) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedSpecialty = spec
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Available doctor ")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.medText)

                                Text("Choose a specialty and look for your suitable doctor.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.medSubtext)
                            }

                            Spacer()

                            Text("\(filteredDoctors.count)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.medPrimary)
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 20)

                        LazyVStack(spacing: 16) {
                            ForEach(filteredDoctors) { doctor in
                                NavigationLink(destination: DoctorDetailView(doctor: doctor).environmentObject(appState)) {
                                    DoctorCardView(doctor: doctor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var modernHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.medPrimary, Color.medSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 190, height: 190)
                .offset(x: 230, y: -60)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 130, height: 130)
                .offset(x: -35, y: 115)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Hello  👋")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))

                        Text("Find  for a Doctor ")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button {
                        appState.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                    }
                }

                HStack(spacing: 12) {
                    miniStat(title: "Demandes", value: "\(appState.patientAppointments.count)", icon: "calendar.badge.clock")
                    miniStat(title: "Médecins", value: "\(appState.doctors.count)", icon: "stethoscope")
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 58)
            .padding(.bottom, 22)
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .shadow(color: Color.medPrimary.opacity(0.25), radius: 18, x: 0, y: 10)
    }

    private func miniStat(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.82))
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.14))
        .cornerRadius(18)
    }
}

struct SearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.medSubtext)
                .font(.system(size: 16))

            TextField("Search a, doctor , specialty , City ...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.medText)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.medSubtext)
                }
            }
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct SpecialtyChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .medSubtext)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color.medPrimary : Color.white)
                .cornerRadius(20)
                .shadow(color: isSelected ? Color.medPrimary.opacity(0.28) : Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}

struct DoctorCardView: View {
    let doctor: Doctor

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                LinearGradient(
                    colors: [Color.medPrimary.opacity(0.16), Color.medSecondary.opacity(0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: doctor.image)
                    .font(.system(size: 30))
                    .foregroundColor(.medPrimary)
            }
            .frame(width: 76, height: 76)
            .cornerRadius(20)

            VStack(alignment: .leading, spacing: 6) {
                Text(doctor.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.medText)
                    .lineLimit(1)

                Text(doctor.specialty)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.medPrimary)

                Text(doctor.displayLocation)
                    .font(.system(size: 12))
                    .foregroundColor(.medSubtext)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)

                    Text(String(format: "%.1f", doctor.rating))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.medText)

                    Text("(\(doctor.reviews))")
                        .font(.system(size: 12))
                        .foregroundColor(.medSubtext)

                    Spacer()

                    Text("\(doctor.price) DA")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.medPrimary)
                }
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(.blue)

                    Text(doctor.serviceType)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.medSubtext.opacity(0.5))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 5)
    }
}

struct DoctorDetailView: View {
    @EnvironmentObject var appState: AppState
    let doctor: Doctor
    private var latitude: Double {
        extractCoordinates().0
    }

    private var longitude: Double {
        extractCoordinates().1
    }

    private func extractCoordinates() -> (Double, Double) {

        let text = doctor.location

        let parts = text.components(separatedBy: "|")

        if parts.count == 2 {

            let latText = parts[0]
                .replacingOccurrences(of: "Lat:", with: "")
                .trimmingCharacters(in: .whitespaces)

            let lonText = parts[1]
                .replacingOccurrences(of: "Lon:", with: "")
                .trimmingCharacters(in: .whitespaces)

            return (
                Double(latText) ?? 36.7538,
                Double(lonText) ?? 3.0588
            )
        }

        return (36.7538, 3.0588)
    }

    @State private var selectedDate = Date()
    @State private var selectedTime: String? = nil
    @State private var showConfirmation = false
    @State private var showBookedAlert = false
    @Environment(\.dismiss) var dismiss

    var dateRange: [Date] {
        (0..<14).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: Date())
        }
    }

    var body: some View {
        ZStack {
            Color.medBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    DoctorBannerView(doctor: doctor, dismiss: { dismiss() })

                    VStack(spacing: 20) {
                        DoctorStatsRow(doctor: doctor)
                            .padding(.horizontal, 20)

                        detailSection(title: "À propos") {
                            Text(doctor.bio)
                                .font(.system(size: 14))
                                .foregroundColor(.medSubtext)
                                .lineSpacing(5)
                        }
                        detailSection(title: "Localisation") {
                            Map {
                                Marker(
                                    doctor.hospital,
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: latitude,
                                        longitude: longitude
                                    )
                                )
                            }
                            .frame(height: 220)
                            .cornerRadius(16)

                            VStack(alignment: .leading, spacing: 12) {

                                Label(
                                    doctor.displayLocation,
                                    systemImage: "mappin.and.ellipse"
                                )

                                Label(
                                    "+213 \(doctor.phone.dropFirst())",
                                    systemImage: "phone.fill"
                                )

                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Choisir une date")
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(dateRange, id: \.self) { date in
                                        DateChipView(
                                            date: date,
                                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                        ) {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedDate = date
                                                selectedTime = nil
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Choisir l'heure")
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                                ForEach(doctor.availableTimes, id: \.self) { time in
                                    TimeChipView(time: time, isSelected: selectedTime == time) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedTime = time
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Button {
                            if selectedTime != nil {
                                showConfirmation = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "calendar.badge.plus")
                                Text("Envoyer la demande")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                selectedTime != nil
                                ? LinearGradient(colors: [Color.medPrimary, Color.medSecondary], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(18)
                            .shadow(color: selectedTime != nil ? Color.medPrimary.opacity(0.32) : .clear, radius: 10, x: 0, y: 4)
                        }
                        .disabled(selectedTime == nil)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }

            if showConfirmation {
                ConfirmationOverlayView(
                    doctor: doctor,
                    date: selectedDate,
                    time: selectedTime ?? "",
                    onConfirm: {
                        Task {
                            do {
                                try await appState.bookAppointment(
                                    doctor: doctor,
                                    date: selectedDate,
                                    time: selectedTime ?? ""
                                )
                                showConfirmation = false
                                showBookedAlert = true
                            } catch {
                                appState.errorMessage = error.localizedDescription
                                showConfirmation = false
                            }
                        }
                    },
                    onCancel: {
                        showConfirmation = false
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationBarHidden(true)
        .alert("Demande envoyée", isPresented: $showBookedAlert) {
            Button("Voir mes RDV") {
                dismiss()
                appState.selectedTab = 2
            }
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Votre demande de rendez-vous est maintenant en attente dans Mes RDV.")
        }
    }

    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

struct DoctorBannerView: View {
    let doctor: Doctor
    let dismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color.medPrimary, Color.medSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 170)
                .offset(x: 260, y: -35)

            VStack(spacing: 0) {
                HStack {
                    Button(action: dismiss) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 55)

                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 86, height: 86)

                        Image(systemName: doctor.image)
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(doctor.name)
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(.white)

                        Text(doctor.specialty)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.18))
                            .cornerRadius(10)

                        Text(doctor.displayLocation)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
        }
        .frame(height: 215)
    }
}

struct DoctorStatsRow: View {
    let doctor: Doctor

    var body: some View {
        HStack(spacing: 0) {
            StatItem(icon: "star.fill", value: String(format: "%.1f", doctor.rating), label: "Note", color: .yellow)
            Divider().frame(height: 40)
            StatItem(icon: "clock.fill", value: "\(doctor.experience) ans", label: "Exp.", color: .medPrimary)
            Divider().frame(height: 40)
            StatItem(icon: "person.3.fill", value: "\(doctor.reviews)", label: "Avis", color: .medSecondary)
            Divider().frame(height: 40)
            StatItem(icon: "banknote.fill", value: "\(doctor.price) DA", label: "Tarif", color: .orange)
        }
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.medText)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.medSubtext)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.medText)
    }
}

struct DateChipView: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName.prefix(3).uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .medSubtext)

                Text(dayNumber)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? .white : .medText)
            }
            .frame(width: 54, height: 62)
            .background(isSelected ? Color.medPrimary : Color.white)
            .cornerRadius(15)
            .shadow(color: isSelected ? Color.medPrimary.opacity(0.3) : Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}

struct TimeChipView: View {
    let time: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(time)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .medText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isSelected ? Color.medPrimary : Color.white)
                .cornerRadius(12)
                .shadow(color: isSelected ? Color.medPrimary.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct ConfirmationOverlayView: View {
    let doctor: Doctor
    let date: Date
    let time: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE dd MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.medPrimary, Color.medSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)

                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Confirmer la demande")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.medText)

                    Text("Votre rendez-vous sera envoyé au médecin et restera en attente.")
                        .font(.system(size: 13))
                        .foregroundColor(.medSubtext)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    ConfirmRow(icon: "person.fill", label: "Médecin", value: doctor.name)
                    ConfirmRow(icon: "stethoscope", label: "Spécialité", value: doctor.specialty)
                    ConfirmRow(icon: "calendar", label: "Date", value: formattedDate)
                    ConfirmRow(icon: "clock.fill", label: "Heure", value: time)
                    ConfirmRow(icon: "hourglass", label: "Statut", value: "En attente")
                }
                .padding(16)
                .background(Color.medBackground)
                .cornerRadius(16)

                HStack(spacing: 14) {
                    Button(action: onCancel) {
                        Text("Annuler")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.medSubtext)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.medBackground)
                            .cornerRadius(14)
                    }

                    Button(action: onConfirm) {
                        Text("Envoyer")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.medPrimary, Color.medSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(26)
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 10)
        }
    }
}

struct ConfirmRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.medPrimary)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.medSubtext)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.medText)
        }
    }
}

#Preview {
    HomeMedicalView()
        .environmentObject(AppState())
}
