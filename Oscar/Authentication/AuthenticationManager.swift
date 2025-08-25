import SwiftUI
import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthError?
    
    @MainActor
    func updateUserAvatar(_ avatar: String) async throws {
        guard let userId = currentUser?.id else { throw AuthError.signInFailed }
        
        let db = Firestore.firestore()
        let userData: [String: String] = ["avatar": avatar]
        try await db.collection("users").document(userId).updateData(userData)
        
        // Update local user object
        if var updatedUser = currentUser {
            updatedUser.avatar = avatar
            currentUser = updatedUser
        }
    }
    
    static let shared = AuthenticationManager()
    
    private init() {
        setupAuthStateHandler()
    }
    
    private func setupAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let firebaseUser = user {
                // Get user data from Firestore
                let db = Firestore.firestore()
                Task {
                    do {
                        let document = try await db.collection("users").document(firebaseUser.uid).getDocument()
                        guard let data = document.data() else { return }
                        
                        let userTypeString = data["userType"] as? String ?? UserType.guardian.rawValue
                        let userType = UserType(rawValue: userTypeString) ?? .guardian
                        let avatar = data["avatar"] as? String ?? "default_avatar"
                        let userID = data["userID"] as? String
                        
                        let user = User(id: firebaseUser.uid,
                                        name: firebaseUser.displayName ?? "",
                                        email: firebaseUser.email ?? "",
                                        userType: userType,
                                        avatar: avatar,
                                        userID: userID)
                        
                        // Dispatch UI updates to the main thread
                        await MainActor.run {
                            self.currentUser = user
                            self.isAuthenticated = true
                        }
                    } catch {
                        print("Error fetching user data: \(error)")
                    }
                }
            } else {
                // Dispatch UI updates to the main thread
                Task { @MainActor in
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    // Generate a random 9-digit userID
    private func generateUserID() -> String {
        // Generate a random 9-digit number
        let randomNumber = Int.random(in: 100000000...999999999)
        return String(randomNumber)
    }
    
    func signUp(name: String, email: String, password: String, userType: UserType) async throws -> User {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard isValidPassword(password) else {
            throw AuthError.invalidPassword
        }
        
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let firebaseUser = authResult.user
            
            // Update display name if provided
            if !name.isEmpty {
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
            }
            
            // Generate a unique 9-digit userID
            let userID = generateUserID()
            
            // Store user data in Firestore with default avatar and userID
            let db = Firestore.firestore()
            let defaultAvatar = "default_avatar"
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "userType": userType.rawValue,
                "createdAt": FieldValue.serverTimestamp(),
                "avatar": defaultAvatar,
                "userID": userID
            ]
            
            try await db.collection("users").document(firebaseUser.uid).setData(userData)
            
            // Create our User model with default avatar and userID
            let user = User(id: firebaseUser.uid, name: name, email: email, userType: userType, avatar: defaultAvatar, userID: userID)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            return user
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                throw AuthError.emailAlreadyInUse
            case AuthErrorCode.invalidEmail.rawValue:
                throw AuthError.invalidEmail
            case AuthErrorCode.weakPassword.rawValue:
                throw AuthError.weakPassword
            default:
                throw AuthError.signUpFailed
            }
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user
            
            // Get user data from Firestore
            let db = Firestore.firestore()
            let document = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            guard let data = document.data() else {
                throw AuthError.userNotFound
            }
            
            let userTypeString = data["userType"] as? String ?? UserType.guardian.rawValue
            let userType = UserType(rawValue: userTypeString) ?? .guardian
            let avatar = data["avatar"] as? String ?? "default_avatar"
            let userID = data["userID"] as? String
            
            let user = User(id: firebaseUser.uid,
                            name: firebaseUser.displayName ?? "",
                            email: firebaseUser.email ?? "",
                            userType: userType,
                            avatar: avatar,
                            userID: userID)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            return user
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.userNotFound.rawValue:
                throw AuthError.userNotFound
            case AuthErrorCode.wrongPassword.rawValue:
                throw AuthError.wrongPassword
            case AuthErrorCode.invalidEmail.rawValue:
                throw AuthError.invalidEmail
            default:
                throw AuthError.signInFailed
            }
        }
    }
    
    func signInWithGoogle() async throws -> User {
        throw AuthError.signInFailed
    }
    
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        } catch {
            throw AuthError.signOutFailed
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let hasMinLength = password.count >= 8
        let hasUppercase = password.contains { $0.isUppercase }
        let hasNumber = password.contains { $0.isNumber }
        return hasMinLength && hasUppercase && hasNumber
    }
    
    func deleteAccount() async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        guard let user = Auth.auth().currentUser, let userId = currentUser?.id else {
            throw AuthError.userNotFound
        }
        
        do {
            // Delete user data from Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(userId).delete()
            
            // Delete user from Firebase Authentication
            try await user.delete()
            
            // Clear local user data
            await MainActor.run {
                currentUser = nil
                isAuthenticated = false
            }
        } catch {
            throw AuthError.deleteFailed
        }
    }
    
    @MainActor
    func resetPassword(email: String) async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.userNotFound.rawValue:
                throw AuthError.userNotFound
            case AuthErrorCode.invalidEmail.rawValue:
                throw AuthError.invalidEmail
            default:
                throw AuthError.resetPasswordFailed
            }
        }
    }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidName
    case invalidEmail
    case invalidPassword
    case signInFailed
    case signUpFailed
    case signOutFailed
    case emailAlreadyInUse
    case weakPassword
    case userNotFound
    case wrongPassword
    case configurationError
    case presentationError
    case invalidCredential
    case passwordsDontMatch
    case deleteFailed
    case resetPasswordFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Please enter a valid name"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 8 characters with one uppercase letter and one number"
        case .signInFailed:
            return "Failed to sign in. Please try again"
        case .signUpFailed:
            return "Failed to create account. Please try again"
        case .signOutFailed:
            return "Failed to sign out. Please try again"
        case .emailAlreadyInUse:
            return "This email is already in use"
        case .weakPassword:
            return "Password is too weak"
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .configurationError:
            return "Error in app configuration"
        case .presentationError:
            return "Unable to present sign in screen"
        case .invalidCredential:
            return "Invalid credentials"
        case .passwordsDontMatch:
            return "Passwords do not match"
        case .deleteFailed:
            return "Failed to delete account. Please try again"
        case .resetPasswordFailed:
            return "Failed to send password reset email. Please try again"
        }
    }
}
