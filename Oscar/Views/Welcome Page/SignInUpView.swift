import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct SignInUpView: View {
    @State private var isShowingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isEmailValid = true
    @State private var isPasswordValid = true
    @State private var emailErrorMessage = ""
    @State private var passwordErrorMessage = ""
    @State private var shakeEmail = false
    @State private var shakePassword = false
    @State private var isAnimating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showUserTypeSelection = false
    
    @StateObject private var authManager = AuthenticationManager.shared
    
    private func validateEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validatePassword() -> Bool {
        let hasMinLength = password.count >= 8
        let hasUppercase = password.contains { $0.isUppercase }
        let hasNumber = password.contains { $0.isNumber }
        return hasMinLength && hasUppercase && hasNumber
    }
    
    var body: some View {
        NavigationStack {
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
                    
                    Text("Oscar - ChildMed")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    
                    VStack(spacing: 10) {
                        Picker("Mode", selection: $isShowingSignUp) {
                            Text("Sign In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 30)
                        .onAppear {
                            let appearance = UISegmentedControl.appearance()
                            appearance.selectedSegmentTintColor = .white
                            appearance.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                            appearance.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                            appearance.backgroundColor = UIColor.systemGray
                        }
                        .onChange(of: isShowingSignUp) { oldValue, newValue in
                            email = ""
                            password = ""
                            name = ""
                            isEmailValid = true
                            isPasswordValid = true
                            emailErrorMessage = ""
                            passwordErrorMessage = ""
                            shakeEmail = false
                            shakePassword = false
                        }
                        
                        VStack(spacing: 10) {
                            if isShowingSignUp {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                    TextField("Full Name", text: $name)
                                        .textContentType(.name)
                                        .autocapitalization(.words)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                
                                VStack {
                                    if !name.isEmpty && name.count < 2 {
                                        Text("Name must be at least 2 characters long")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 5)
                                    }
                                }
                                .frame(height: 15)
                            }
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .onChange(of: email) { oldValue, newValue in
                                        isEmailValid = validateEmail()
                                        if !isEmailValid && !email.isEmpty {
                                            emailErrorMessage = "Please enter a valid email address"
                                        } else {
                                            emailErrorMessage = ""
                                        }
                                    }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .overlay(
                                !isEmailValid && !email.isEmpty ?
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 2)
                                : nil
                            )
                            .modifier(ShakeEffect(animatableData: shakeEmail ? 1 : 0))
                            
                            VStack {
                                if !emailErrorMessage.isEmpty {
                                    Text(emailErrorMessage)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 5)
                                }
                            }
                            .frame(height: 15)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                SecureField("Password", text: $password)
                                    .textContentType(isShowingSignUp ? .newPassword : .password)
                                    .onChange(of: password) { oldValue, newValue in
                                        isPasswordValid = isShowingSignUp ? validatePassword() : true
                                        if isShowingSignUp && !password.isEmpty && !isPasswordValid {
                                            passwordErrorMessage = "Password must be at least 8 characters with one uppercase letter and one number"
                                        } else {
                                            passwordErrorMessage = ""
                                        }
                                    }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .overlay(
                                !isPasswordValid && !password.isEmpty ?
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 2)
                                : nil
                            )
                            .modifier(ShakeEffect(animatableData: shakePassword ? 1 : 0))
                            
                            VStack {
                                if !passwordErrorMessage.isEmpty {
                                    Text(passwordErrorMessage)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 5)
                                }
                            }
                            .frame(height: 15)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                if !isShowingSignUp {
                                    _ = try await authManager.signIn(email: email, password: password)
                                    // After successful signin, show loading view for existing user
                                    NavigationUtil.switchToLoadingView(isNewUser: false)
                                } else {
                                    _ = try await authManager.signUp(name: name, email: email, password: password, userType: .guardian)
                                    // After successful signup, show user type selection
                                    showUserTypeSelection = true
                                }
                            } catch let error as AuthError {
                                switch error {
                                case .invalidEmail, .userNotFound:
                                    emailErrorMessage = error.localizedDescription
                                    shakeEmail = true
                                    withAnimation { shakeEmail = false }
                                case .invalidPassword, .weakPassword, .wrongPassword:
                                    passwordErrorMessage = error.localizedDescription
                                    shakePassword = true
                                    withAnimation { shakePassword = false }
                                default:
                                    if isShowingSignUp {
                                        passwordErrorMessage = error.localizedDescription
                                    } else {
                                        emailErrorMessage = error.localizedDescription
                                    }
                                }
                            } catch {
                                emailErrorMessage = "An unexpected error occurred"
                            }
                        }
                    }) {
                        Text(isShowingSignUp ? "Sign Up" : "Sign In")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.4, green: 0.2, blue: 0.8))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .disabled(authManager.isLoading)
                    
                    if !isShowingSignUp {
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot Password?")
                                .foregroundColor(.white)
                        }
                    }
                    
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            }
            
            .navigationDestination(isPresented: $showUserTypeSelection) {
                UserTypeSelectionView()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
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
    SignInUpView()
}
