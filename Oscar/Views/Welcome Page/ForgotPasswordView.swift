import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [
                Color("AccentColor"),
                Color("SecondColor").opacity(0.8)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Image("Writing notes")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 175)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text("Reset Password")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    Button(action: resetPassword) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Reset Link")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.4, green: 0.2, blue: 0.8))
                        .cornerRadius(12)
                    }
                    .disabled(authManager.isLoading)
                    .padding(.horizontal)
                    
                    Button(action: { dismiss() }) {
                        Text("Back to Login")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 5)
                }
                .padding(.top)
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        dismiss()
                    }
                }
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func resetPassword() {
        Task {
            do {
                try await authManager.resetPassword(email: email)
                await MainActor.run {
                    isSuccess = true
                    alertMessage = "Password reset link has been sent to your email."
                    showAlert = true
                }
            } catch let error as AuthError {
                await MainActor.run {
                    isSuccess = false
                    alertMessage = error.errorDescription ?? "An error occurred"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isSuccess = false
                    alertMessage = "An unexpected error occurred"
                    showAlert = true
                }
            }
        }
    }
}
#Preview {
    ForgotPasswordView()
}
