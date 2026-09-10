
import SwiftUI
import FirebaseCore

@main
struct CareBuddyDZApp: App {

    @StateObject private var appState: AppState
    

    init() {

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {

            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }

        NotificationManager.shared.requestPermission()

        _appState = StateObject(
            wrappedValue: AppState()
        )
    }

    var body: some Scene {

        WindowGroup {

            RootView()
                .environmentObject(appState)
        }
    }
}


