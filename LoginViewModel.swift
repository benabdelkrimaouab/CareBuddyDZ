import Foundation
import FirebaseAuth
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    
    private var isRunningPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    func login() {
        
        errorMessage = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            errorMessage = "Email and password must not be empty."
            return
        }
        
        if isRunningPreview {
            isLoggedIn = true
            return
        }
        
        isLoading = true
        Auth.auth().signIn(withEmail: cleanEmail, password: cleanPassword) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                
                if error == nil {
                    self.isLoading = false
                    self.isLoggedIn = true
                    return
                }
                
                if let error = error as NSError?,
                   error.code == AuthErrorCode.userNotFound.rawValue ||
                   error.code == AuthErrorCode.invalidCredential.rawValue {
                    
                    Auth.auth().createUser(withEmail: cleanEmail, password: cleanPassword) { result, error in
                        
                        DispatchQueue.main.async {
                            self.isLoading = false
                            
                            if let error {
                                self.errorMessage = error.localizedDescription
                                self.isLoggedIn = false
                            } else {
                                print(" Account created automatically")
                                self.isLoggedIn = true
                            }
                        }
                    }
                    
                } else {
                    self.isLoading = false
                    self.errorMessage = error?.localizedDescription
                    self.isLoggedIn = false
                }
            }
        }
    }
}
