import SwiftUI
import MapKit
import CoreLocation

struct FillDoctorView: View {
    @EnvironmentObject var appState: AppState

    enum DoctorPlaceType: String, CaseIterable, Identifiable {
        case home = "Home Doctor"
        case clinic = "Clinic"
        case both = "Home + Clinic"
        var id: String { rawValue }
    }

    
    
   
    @State private var locationText: String = ""
    @State private var placeType: DoctorPlaceType = .clinic
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedLocation = CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588)
    @State private var coordinate = CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588)

   
    @State private var draft = DoctorDraft()
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var showSuccessAlert = false
    @State private var goToDashboard = false

   
    private let imageOptions = [
        "stethoscope","heart.fill","brain.head.profile","cross.case.fill","bandage.fill",
        "eye.fill","nose","cross.case.fill","figure.walk","figure.and.child.holdinghands",
        "person.crop.circle.badge.plus","drop","cross.vial","testtube.2"
    ]
    private let genderOptions = ["Homme", "Femme"]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.pink.opacity(0.10), Color.blue.opacity(0.08), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        headerSection

                        formSection(title: "Personal Information") {
                            customField("First Name", text: $draft.firstName, icon: "person.fill")
                            customField("Last Name", text: $draft.lastName, icon: "person.text.rectangle.fill")
                            customField("Phone Number (+213)", text: $draft.phone, icon: "phone.fill").keyboardType(.numberPad)
                            customField("Age", text: $draft.age, icon: "calendar").keyboardType(.numberPad)
                        }

                        formSection(title: "Professional Information") {
                            customField("Specialty", text: $draft.specialty, icon: "stethoscope")
                            customField("License Number", text: $draft.license, icon: "checkmark.seal.fill")
                            customField("Consultation Price (DA)", text: $draft.price, icon: "banknote.fill").keyboardType(.numberPad)
                            customField("Hospital / Clinic", text: $draft.hospital, icon: "cross.case.fill")

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Doctor Type").font(.system(size: 15, weight: .semibold))
                                Picker("Doctor Type", selection: $placeType) {
                                    ForEach(DoctorPlaceType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }


                            formSection(title: "Location") {
                                TextField("Enter your location", text: $locationText)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)

                                Button("Find location") { geocodeAddress() }
                                    .foregroundColor(.medPrimary)

                                VStack(alignment: .leading, spacing: 10) {
                                    customField("City / Location", text: $draft.location, icon: "mappin.and.ellipse")
                                        .disabled(true)

                                    Text("Select Clinic Location").font(.headline)
                                    Map(
                                        coordinateRegion: $region,
                                        annotationItems: [MapMarkerItem(coordinate: selectedLocation)]
                                    ) { item in
                                        MapMarker(coordinate: item.coordinate, tint: .red)
                                    }
                                    .frame(height: 250)
                                    .cornerRadius(20)
                                    .onChange(of: region.center.latitude) { _ in updateSelectedFromRegion() }
                                    .onChange(of: region.center.longitude) { _ in updateSelectedFromRegion() }

                                    Text("Latitude: \(selectedLocation.latitude)").font(.caption)
                                    Text("Longitude: \(selectedLocation.longitude)").font(.caption)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            sectionTitle("Profile Style")

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Gender").font(.system(size: 15, weight: .semibold))
                                Picker("Gender", selection: $draft.sex) {
                                    ForEach(genderOptions, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Profile Icon").font(.system(size: 15, weight: .semibold))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    IconPickerView(imageOptions: imageOptions, selection: $draft.image)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(24)

                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Short Bio")
                            TextEditor(text: $draft.bio)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(18)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Available Times")
                            Text("Use HH:mm format separated by commas. Example: 09:00, 10:30")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            customField("09:00, 10:30", text: $draft.availableTimesText, icon: "clock.fill")
                        }

                        Button {
                            saveDoctor()
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text(appState.isLoading ? "Saving..." : "Save Professional Profile")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color.pink, Color.blue], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(20)
                        }
                        .disabled(appState.isLoading)

                        NavigationLink(destination: DoctorDashboardView().environmentObject(appState), isActive: $goToDashboard) {
                            EmptyView()
                        }
                        .hidden()
                    }
                    .padding()
                }
            }
            .navigationTitle("Doctor Profile")
            .alert("Error", isPresented: $showAlert) { Button("OK", role: .cancel) {} } message: { Text(errorMessage) }
            .alert("Success", isPresented: $showSuccessAlert) { Button("Open Dashboard") { goToDashboard = true } } message: { Text("Your doctor profile has been saved successfully.") }
        }
    }

    
    private var headerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(colors: [Color.pink, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 200)
            Text("Welcome Doctor").font(.title).foregroundColor(.white)
        }
    }

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)
            content()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.headline).foregroundColor(.blue)
    }

    private func customField(_ title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.pink)
            TextField(title, text: text)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private func updateSelectedFromRegion() {
        selectedLocation = region.center
        coordinate = region.center
        draft.location = "Lat: \(String(format: "%.4f", region.center.latitude)) | Lon: \(String(format: "%.4f", region.center.longitude))"
    }

    private func geocodeAddress() {
        let geocoder = CLGeocoder()
        let query = locationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        geocoder.geocodeAddressString(query) { placemarks, error in
            guard error == nil, let location = placemarks?.first?.location else { return }
            DispatchQueue.main.async {
                let newCoord = location.coordinate
                coordinate = newCoord
                draft.location =
                "Lat: \(newCoord.latitude) | Lon: \(newCoord.longitude)"
                region = MKCoordinateRegion(
                    center: newCoord,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }

    private func saveDoctor() {
        Task {
            do {
                appState.isLoading = true
                defer { appState.isLoading = false }

                draft.serviceType = placeType.rawValue

                try await appState.registerDoctor(from: draft)

                showSuccessAlert = true
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

private struct IconPickerView: View {
    let imageOptions: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 12) {
            ForEach(imageOptions, id: \.self) { icon in
                Button(action: { selection = icon }) {
                    ZStack {
                        let isSelected = selection == icon
                        let bgColor: Color = isSelected ? Color.pink.opacity(0.18) : Color.gray.opacity(0.08)
                        let fgColor: Color = isSelected ? .purple : .blue

                        RoundedRectangle(cornerRadius: 18)
                            .fill(bgColor)
                            .frame(width: 64, height: 64)
                        Image(systemName: icon)
                            .foregroundStyle(fgColor)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(selection == icon ? Color.purple : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
    }
}

#Preview {
    FillDoctorView()
        .environmentObject(AppState())
}

struct MapMarkerItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

