import SwiftUI

struct EmailView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    @State private var showAlert = false
    @State private var showPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.10),
                        Color.green.opacity(0.08),
                        Color.pink.opacity(0.05),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection

                        VStack(spacing: 18) {
                            inputField(
                                title: "Email Address",
                                text: $viewModel.email,
                                icon: "envelope.fill",
                                keyboard: .emailAddress
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.emailAddress)

                            passwordField
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

                        Button {
                            validateAndContinue()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.right.circle.fill")
                                Text(viewModel.isLoading ? "Loading..." : "Continue")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.green.opacity(0.25), radius: 10, x: 0, y: 5)
                        }
                        .disabled(viewModel.isLoading)

                        if let error = viewModel.errorMessage, !error.isEmpty {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .font(.footnote)
                                .padding(.horizontal, 8)
                        }

                        VStack(spacing: 8) {
                            Text("Secure Login")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)

                            Text("Sign in to continue and access your CareBuddyDZ profile.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                ChoixView()
                    .environmentObject(appState)
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown Error")
            }
        }
    }

    private var headerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.green.opacity(0.85), Color.pink.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 230)
                .shadow(color: Color.blue.opacity(0.20), radius: 16, x: 0, y: 8)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 82, height: 82)

                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Login to continue your medical journey with elegance and simplicity.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding()
        }
    }

    private func inputField(title: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.10))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundColor(.blue)
            }

            TextField(title, text: text)
                .keyboardType(keyboard)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.green.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private var passwordField: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.10))
                    .frame(width: 42, height: 42)

                Image(systemName: "lock.fill")
                    .foregroundColor(.blue)
            }

            Group {
                if showPassword {
                    TextField("Password", text: $viewModel.password)
                } else {
                    SecureField("Password", text: $viewModel.password)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(.password)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.green.opacity(0.8))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.green.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private func validateAndContinue() {
        let cleanEmail = viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty else {
            viewModel.errorMessage = "Please enter your email address."
            showAlert = true
            return
        }

        guard cleanEmail.contains("@"), cleanEmail.contains(".") else {
            viewModel.errorMessage = "Please enter a valid email address."
            showAlert = true
            return
        }

        guard !cleanPassword.isEmpty else {
            viewModel.errorMessage = "Please enter your password."
            showAlert = true
            return
        }

        guard cleanPassword.count >= 6 else {
            viewModel.errorMessage = "Password must contain at least 6 characters."
            showAlert = true
            return
        }

        viewModel.login()
    }
}

#Preview {
    EmailView()
        .environmentObject(AppState())
}
