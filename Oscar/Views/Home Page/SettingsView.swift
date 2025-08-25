import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showDeleteConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    Button(action: { showLogoutConfirmation = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Log Out")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isLoggingOut)
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Link(destination: URL(string: "https://www.example.com/privacy")!) {
                        Text("Privacy Policy")
                    }
                    
                    Link(destination: URL(string: "https://www.example.com/terms")!) {
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { NavigationUtil.switchToHomeView() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Home")
                        }
                        .foregroundColor(Color("AccentColor"))
                    }
                }
            }
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    isLoggingOut = true
                    Task {
                        do {
                            // First set the loading state
                            isLoggingOut = true
                            
                            // Perform the sign out operation
                            try await authManager.signOut()
                            
                            // Ensure UI updates happen on the main thread
                            await MainActor.run {
                                // Clear any cached data or states if needed
                                UserDefaults.standard.synchronize()
                                
                                // Reset the loading state
                                isLoggingOut = false
                                
                                // Dismiss the current view and switch to sign in
                                dismiss()
                                NavigationUtil.switchToSignInView()
                            }
                        } catch {
                            print("Error signing out: \(error)")
                            // Ensure UI updates happen on the main thread
                            await MainActor.run {
                                isLoggingOut = false
                            }
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await authManager.deleteAccount()
                            dismiss()
                            NavigationUtil.switchToSignInView()
                        } catch {
                            print("Error deleting account: \(error)")
                        }
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .overlay {
                if isLoggingOut {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                Text("Logging out...")
                                    .foregroundColor(.white)
                                    .padding(.top)
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
