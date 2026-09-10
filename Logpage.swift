import SwiftUI
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

struct Logpage: View {
    var body: some View {
        OnBoarding()
    }
}

struct OnBoarding: View {
    @EnvironmentObject var appState: AppState

    @State private var showEmailLogin = false
    @State private var goToRoleChoice = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var currentNonce: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.medBackground, Color.white, Color.medBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection.padding(.top, 24)
                        illustrationCard
                        summaryCard
                        providerSection
                        emailButton
                        alreadyHaveAccountSection
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationDestination(isPresented: $showEmailLogin) {
                EmailView()
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $goToRoleChoice) {
                ChoixView()
                    .environmentObject(appState)
            }
            .alert("Login Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var emailButton: some View {
        Button {
            showEmailLogin = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                Text("Contineur with Email ")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.medPrimary, Color.medSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: Color.medPrimary.opacity(0.25), radius: 12, x: 0, y: 8)
        }
    }

    private var alreadyHaveAccountSection: some View {
        VStack(spacing: 10) {
            Text("Already  d'ont have an account?")
                .font(.footnote)
                .foregroundColor(.medSubtext)

            Button("Sign up") {
                showEmailLogin = true
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.medPrimary)
        }
        .padding(.bottom, 24)
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick access")
                .font(.headline)
                .foregroundColor(.medText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54)
                .cornerRadius(16)

                Button {
                    signInWithGoogle()
                } label: {
                    HStack(spacing: 10) {
                        Image("5")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)

                        Text("Google")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.medText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                }
            }
        }
    }
    

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else {
                errorMessage = "Unable to get Apple credential."
                showError = true
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            Auth.auth().signIn(with: credential) { _, error in
                DispatchQueue.main.async {
                    if let error {
                        errorMessage = error.localizedDescription
                        showError = true
                    } else {
                        goToRoleChoice = true
                    }
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Firebase client ID."
            showError = true
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        else {
            errorMessage = "Unable to find root view controller."
            showError = true
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                DispatchQueue.main.async {
                    errorMessage = "Unable to get Google token."
                    showError = true
                }
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { _, error in
                DispatchQueue.main.async {
                    if let error {
                        errorMessage = error.localizedDescription
                        showError = true
                    } else {
                        goToRoleChoice = true
                    }
                }
            }
        }
    }
    

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "cross.case.fill")
                    Text("CareBuddyDZ")
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .foregroundColor(.medPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Healthcare made simple")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.medText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Book appointments, discover specialists, and manage your medical follow-up in one place.")
                    .font(.system(size: 15))
                    .foregroundColor(.medSubtext)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(4)
            }
        }
    }

    private var illustrationCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color.medPrimary, Color.medSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 240)

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 170)
                .offset(x: 95, y: -60)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 120)
                .offset(x: -110, y: 70)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 92, height: 92)

                    Image(systemName: "stethoscope.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Trusted doctors near you")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)

                    Text("Search by specialty, compare prices, and request appointments quickly.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                }
            }
        }
        .shadow(color: Color.medPrimary.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                featurePill(icon: "checkmark.shield.fill", title: "Secure")
                featurePill(icon: "calendar.badge.plus", title: "Appointments")
                featurePill(icon: "mappin.and.ellipse", title: "Nearby")
            }

            VStack(alignment: .leading, spacing: 12) {
                infoRow(title: "Find specialists", subtitle: "Cardiology, pediatrics, dermatology and more...")
                infoRow(title: "Professional profiles", subtitle: "Consultation price, clinic and availability")
                infoRow(title: "Easy access", subtitle: "Use email or your preferred sign-in provider")
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    private func featurePill(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.medPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.medPrimary.opacity(0.08))
        .cornerRadius(14)
    }

    private func infoRow(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundColor(.medPrimary)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.medText)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.medSubtext)
            }

            Spacer()
        }
    }
}


private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)

        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }

        randoms.forEach { random in
            if remainingLength == 0 { return }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }

    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.map { String(format: "%02x", $0) }.joined()
}

#Preview {
    Logpage()
        .environmentObject(AppState())
}

