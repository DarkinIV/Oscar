import SwiftUI
import FirebaseFirestore

struct ProfileSection: View {
    @Binding var name: String
    let selectedAvatar: String
    @Binding var isEditingName: Bool
    @State private var showingConfirmation = false
    @State private var tempName = ""
    
    let onAvatarTap: () -> Void
    let onNameUpdate: (String) -> Void
    let userId: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(selectedAvatar)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .onTapGesture(perform: onAvatarTap)
            
            if isEditingName {
                TextField("Name", text: $tempName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color("AccentColor").opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .onSubmit {
                        if tempName != name {
                            showingConfirmation = true
                        } else {
                            isEditingName = false
                        }
                    }
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .onAppear{
                        tempName = name
                    }
                    .alert("Confirm Name Change", isPresented: $showingConfirmation) {
                        Button("Cancel", role: .cancel) {
                            tempName = name
                            isEditingName = false
                        }
                        Button("Yes") {
                            name = tempName
                            onNameUpdate(tempName)
                            isEditingName = false
                        }
                    } message: {
                        Text("Are you sure you want to change your name to \(tempName)?")
                    }
            } else {
                HStack(spacing: 4) {
                    Spacer()
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Button(action: { isEditingName = true }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    Spacer()
                }
            }
            
            // User ID
            VStack(spacing: 5) {
                Text("Your User ID")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    Text(userId)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(5)
                    
                    Button(action: {
                        UIPasteboard.general.string = userId
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.white)
                    }
                }
                
                Text("Share this ID with guardians to connect accounts")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct PreferencesSection: View {
    @Binding var notificationsEnabled: Bool
    @Binding var soundEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            
            Toggle("Enable Sounds", isOn: $soundEnabled)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var name = ""
    @State private var selectedAvatar = ""
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var showAvatarPicker = false
    @State private var isEditingName = false
    
    private let avatars = [
        "Talking Right",
        "Talking Left",
        "Jumping",
        "Writing notes",
        "Help"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color("AccentColor"),
                    Color("SecondColor").opacity(0.8)
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        ProfileSection(
                            name: $name,
                            selectedAvatar: selectedAvatar,
                            isEditingName: $isEditingName,
                            onAvatarTap: { showAvatarPicker = true },
                            onNameUpdate: { newName in
                                updateUserProfile()
                            },
                            userId: authManager.currentUser?.userID ?? "No ID"
                        )
                        
                        PreferencesSection(
                            notificationsEnabled: $notificationsEnabled,
                            soundEnabled: $soundEnabled
                        )
                        
                        Button(action: {
                            dismiss()
                            NavigationUtil.switchToSettingsView()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.white)
                                Text("Settings")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPickerView(selectedAvatar: $selectedAvatar, avatars: avatars) {
                    updateUserProfile()
                }
            }
            .onAppear {
                if let user = authManager.currentUser {
                    name = user.name
                    selectedAvatar = user.avatar ?? "default_avatar"
                }
            }
        }
    }
    
    @MainActor
    private func updateUserProfile() {
        Task {
            do {
                let db = Firestore.firestore()
                guard let userId = authManager.currentUser?.id else { return }
                
                let userData: [String: Any] = [
                    "name": name,
                    "avatar": selectedAvatar
                ]
                
                try await db.collection("users").document(userId).updateData(userData)
                
                if var updatedUser = authManager.currentUser {
                    updatedUser.name = name
                    updatedUser.avatar = selectedAvatar
                    authManager.currentUser = updatedUser
                }
            } catch {
                print("Error updating profile: \(error)")
            }
        }
    }
}

struct AvatarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAvatar: String
    let avatars: [String]
    let onSelect: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                    ForEach(avatars, id: \.self) { avatar in
                        Image(avatar)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(selectedAvatar == avatar ? Color("AccentColor") : Color.clear, lineWidth: 3))
                            .onTapGesture {
                                selectedAvatar = avatar
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSelect()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AccountSettingsView()
}
