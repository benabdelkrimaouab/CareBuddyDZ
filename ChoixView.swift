import SwiftUI

struct ChoixView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showUserProfile = false
    @State private var showDoctorProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.medBackground, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    headerSection

                    VStack(spacing: 18) {
                        roleCard(
                            title: "Doctor",
                            subtitle: "Create and manage your professional profile, consultation details, price, and availability.",
                            icon: "stethoscope",
                            iconBackground: Color.pink.opacity(0.14),
                            accent: Color.medPrimary
                        ) {
                            showDoctorProfile = true
                        }

                        roleCard(
                            title: "User",
                            subtitle: "Complete your personal profile and start booking doctors near you quickly.",
                            icon: "person.fill",
                            iconBackground: Color.blue.opacity(0.14),
                            accent: Color.medSecondary
                        ) {
                            showUserProfile = true
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 30)
            }
            .navigationDestination(isPresented: $showDoctorProfile) {
                FillDoctorView()
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $showUserProfile) {
                FillUtiView1()
                    .environmentObject(appState)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.logout()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.medPrimary)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.medPrimary, Color.medSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 220)
                    .shadow(color: Color.medPrimary.opacity(0.18), radius: 18, x: 0, y: 10)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 78, height: 78)

                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        Text("Choose your role")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Select how you want to continue in CareBuddyDZ")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding()
            }

            VStack(spacing: 8) {
                Text("Professional access")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.medText)

                Text("Doctors can manage their professional information, while users can create a patient profile and book appointments.")
                    .font(.system(size: 14))
                    .foregroundColor(.medSubtext)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 6)
        }
    }

    private func roleCard(
        title: String,
        subtitle: String,
        icon: String,
        iconBackground: Color,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 72, height: 72)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.medText)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.medSubtext)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.medSubtext.opacity(0.7))
            }
            .padding(18)
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChoixView()
        .environmentObject(AppState())
}
