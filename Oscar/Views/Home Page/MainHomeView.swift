import SwiftUI

struct MainHomeView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.currentUser?.userType == .guardian {
                    GuardianHomeView()
                } else {
                    ChildHomeView()
                }
            } else {
                ContentView()
            }
        }
        .onAppear {
            // Check authentication status when view appears
            print("MainHomeView appeared, user type: \(authManager.currentUser?.userType.rawValue ?? "none")")
            
            // Create default schedules for all children if the user is a guardian
            if authManager.currentUser?.userType == .guardian {
                Task {
                    await MedicationScheduleManager.createDefaultSchedulesForAllChildren()
                }
            }
        }
    }
}

#Preview {
    MainHomeView()
}
