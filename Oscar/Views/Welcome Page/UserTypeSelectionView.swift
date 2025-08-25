import SwiftUI
import FirebaseFirestore

struct UserTypeSelectionView: View {
    @State private var isAnimating = false
    @State private var selectedType: UserType? = nil
    @State private var showAvatarSelection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color("AccentColor"),
                    Color("SecondColor").opacity(0.8)
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Image("Writing notes")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 175)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    Text("I am a...")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            selectedType = .guardian
                            showAvatarSelection = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.title2)
                                Text("Guardian")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == .guardian ? Color(red: 0.4, green: 0.2, blue: 0.8) : Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            selectedType = .kid
                            showAvatarSelection = true
                        }) {
                            HStack {
                                Image(systemName: "face.smiling.fill")
                                    .font(.title2)
                                Text("Kid")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == .kid ? Color(red: 0.4, green: 0.2, blue: 0.8) : Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            .navigationDestination(isPresented: $showAvatarSelection) {
                if let userType = selectedType {
                    AvatarSelectionView(userType: userType) { selectedAvatar in
                        Task {
                            do {
                                // Update both avatar and user type in Firebase
                                let db = Firestore.firestore()
                                guard let userId = AuthenticationManager.shared.currentUser?.id else { throw AuthError.signInFailed }
                                
                                let userData: [String: Any] = [
                                    "avatar": selectedAvatar,
                                    "userType": userType.rawValue
                                ]
                                
                                try await db.collection("users").document(userId).updateData(userData)
                                
                                // Update local user object
                                if var updatedUser = AuthenticationManager.shared.currentUser {
                                    updatedUser.avatar = selectedAvatar
                                    updatedUser.userType = userType
                                    AuthenticationManager.shared.currentUser = updatedUser
                                }
                                
                                // Navigate to home view
                                NavigationUtil.switchToLoadingView(isNewUser: false)
                            } catch {
                                print("Error saving avatar: \(error)")
                            }
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        UserTypeSelectionView()
    }
}
