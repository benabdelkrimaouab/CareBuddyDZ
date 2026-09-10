import SwiftUI
import MapKit
import CoreLocation

struct FillUtiView1: View {
    @EnvironmentObject var appState: AppState
    @State private var draft = UserProfileDraft()
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @State private var goToHomeMedical = false
    @State private var locationText = ""
    @State private var coordinate = CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private let geocoder = CLGeocoder()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.medBackground, Color.medPrimary.opacity(0.08), Color.white],
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
                            customField("Phone Number (+213)", text: $draft.phone, icon: "phone.fill")
                                .keyboardType(.numberPad)
                            customField("Age", text: $draft.age, icon: "calendar")
                                .keyboardType(.numberPad)
                            customField("Email Address", text: $draft.email, icon: "envelope.fill")
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                            formSection(title: "Location") {

                                TextField("Enter your location", text: $locationText)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)

                                Button("Find location") {
                                    geocodeAddress()
                                }
                                .foregroundColor(.medPrimary)

                                Map(coordinateRegion: $region,
                                    annotationItems: [MapPin(coordinate: coordinate)]) { item in
                                    MapMarker(coordinate: item.coordinate, tint: .red)
                                }
                                .frame(height: 220)
                                .cornerRadius(16)

                                Text("📍 \(coordinate.latitude), \(coordinate.longitude)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                        }

                        Button(action: saveProfile) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(appState.isLoading ? "Saving..." : "Save Profile")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color.medPrimary, Color.medSecondary], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(20)
                            .shadow(color: Color.medPrimary.opacity(0.25), radius: 10, x: 0, y: 5)
                        }
                        .disabled(appState.isLoading)
                        .padding(.top, 6)

                        NavigationLink(destination: DoctorDashboardView().environmentObject(appState), isActive: $goToHomeMedical) {
                            EmptyView()
                        }
                        .hidden()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("Open Home") { goToHomeMedical = true }
            } message: {
                Text("Your profile has been saved successfully.")
            }
        }
    }
    func geocodeAddress() {
        geocoder.geocodeAddressString(locationText) { placemarks, error in
            guard let location = placemarks?.first?.location else { return }

            DispatchQueue.main.async {
                let newCoord = location.coordinate
                self.coordinate = newCoord

                self.region = MKCoordinateRegion(
                    center: newCoord,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }

    private var headerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color.medPrimary, Color.medSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 220)
                .shadow(color: Color.medPrimary.opacity(0.20), radius: 16, x: 0, y: 8)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 80, height: 80)

                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Complete Your Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Add your personal information to continue booking doctors easily.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding()
        }
    }

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(title)
            VStack(spacing: 14) { content() }
        }
        .padding(18)
        .background(Color.white.opacity(0.95))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.medText)
    }

    private func customField(_ title: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundColor(.medPrimary)
            }

            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(title)
                        .foregroundColor(Color.gray.opacity(0.75))
                        .padding(.horizontal, 2)
                }

                TextField("", text: text)
                    .autocorrectionDisabled(true)
                    .foregroundColor(.medText)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func saveProfile() {
        Task {
            do {
                appState.isLoading = true
                defer { appState.isLoading = false }
                
                try await appState.updateUserProfile(with: draft)
                showSuccessAlert = true
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    FillUtiView1()
        .environmentObject(AppState())
}
struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
