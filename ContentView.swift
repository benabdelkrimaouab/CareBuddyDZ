import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: appState.selectedTab == 0 ? "house.fill" : "house")
                    Text("Accueil")
                }
                .tag(0)

            HomeMedicalView()
                .tabItem {
                    Image(systemName: appState.selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    Text("Recherche")
                }
                .tag(1)

            DoctorView()
                .tabItem {
                    Image(systemName: appState.selectedTab == 2 ? "calendar.badge.clock" : "calendar")
                    Text("Mes RDV")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: appState.selectedTab == 3 ? "gear.fill" : "gear")
                    Text("Paramètres")
                }
                .tag(3)
        }
        .environmentObject(appState)
        .tint(.medPrimary)
    }
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.medBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        HomeHeaderView()

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Bienvenue dans CareBuddyDZ")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.medText)

                            Text("Réservez facilement un médecin et suivez l'état de votre demande.")
                                .font(.system(size: 14))
                                .foregroundColor(.medSubtext)
                                .lineSpacing(4)

                            Button {
                                appState.selectedTab = 1
                            } label: {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Chercher un médecin")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.medPrimary, .medSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Statistiques rapides")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.medText)

                            HStack(spacing: 12) {
                                QuickStatCard(
                                    title: "Total",
                                    value: "\(appState.patientAppointments.count)",
                                    systemImage: "calendar"
                                )
                                QuickStatCard(
                                    title: "En attente",
                                    value: "\(appState.patientAppointments.filter { $0.status == .pending }.count)",
                                    systemImage: "clock.badge"
                                )
                            }

                            HStack(spacing: 12) {
                                QuickStatCard(
                                    title: "Acceptés",
                                    value: "\(appState.patientAppointments.filter { $0.status == .approved }.count)",
                                    systemImage: "checkmark.circle.fill"
                                )
                                QuickStatCard(
                                    title: "Refusés",
                                    value: "\(appState.patientAppointments.filter { $0.status == .rejected }.count)",
                                    systemImage: "xmark.circle.fill"
                                )
                            }
                            
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                    VStack(alignment: .leading, spacing: 12) {

                        Text("Map Preview")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.medText)

                        SimpleMapView(
                            coordinate: CLLocationCoordinate2D(
                                latitude: 36.7538,
                                longitude: 3.0588
                            )
                        )
                        .frame(height: 220)
                        .cornerRadius(16)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundColor(.medPrimary)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.medText)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.medSubtext)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct HomeHeaderView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.medPrimary, Color(red: 0.08, green: 0.55, blue: 0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 180, height: 180)
                .offset(x: 260, y: -30)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 120, height: 120)
                .offset(x: 300, y: 30)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bonjour 👋")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.85))
                        Text("Trouvez votre médecin")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 46, height: 46)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 150)
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.medBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Paramètres")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.medText)

                                Text(appState.currentUserProfile.fullName)
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
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 24)

                    ScrollView {
                        VStack(spacing: 14) {
                            // Profile Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Profile Information")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.medText)
                                    .padding(.horizontal)

                                profileInfoCard(
                                    label: "Name",
                                    value: appState.currentUserProfile.fullName,
                                    icon: "person.fill"
                                )
                                profileInfoCard(
                                    label: "Email",
                                    value: appState.currentUserProfile.email,
                                    icon: "envelope.fill"
                                )
                                profileInfoCard(
                                    label: "Phone",
                                    value: appState.currentUserProfile.phone,
                                    icon: "phone.fill"
                                )
                                profileInfoCard(
                                    label: "Age",
                                    value: "\(appState.currentUserProfile.age) years",
                                    icon: "calendar"
                                )
                            }
                            .padding(.horizontal)

                            Divider()
                                .padding(.vertical, 8)
                                .padding(.horizontal)

                            // Danger Zone
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Danger Zone")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal)

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
                                .padding(.horizontal)

                                Text("Deleting your account will permanently remove all your data and cannot be undone.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.7))
                                    .padding(.horizontal)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarHidden(true)
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

    private func profileInfoCard(label: String, value: String, icon: String) -> some View {
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
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
struct SimpleMapView: View {
    let coordinate: CLLocationCoordinate2D

    @State private var region: MKCoordinateRegion

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Map(position: .constant(.region(region))) {
            Marker("Location", coordinate: coordinate)
        }
        .frame(height: 200)
        .cornerRadius(16)
    }
}
