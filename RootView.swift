import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !appState.authChecked {
                ProgressView("Loading...")
            } else if appState.authUserID == nil {
                Logpage()
           
            } else if appState.role == nil {
                ChoixView()
            } else if appState.role == .doctor && appState.activeDoctorID == nil {
                FillDoctorView()
            } else if appState.role == .doctor {
                DoctorDashboardView()
            } else if appState.role == .patient &&
                        appState.currentUserProfile.firstName == "Patient" {
                FillUtiView1()
            } else {
                ContentView()
            }
        }
        .environmentObject(appState)
        .task {
            await appState.reloadCurrentAuthUser()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    await appState.reloadCurrentAuthUser()
                }
            }
        }
    }
}

