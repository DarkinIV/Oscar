import SwiftUI

enum NavigationUtil {
    static func switchToLoadingView(isNewUser: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: LoadingView(isNewUser: isNewUser))
            window.makeKeyAndVisible()
        }
    }
    
    static func switchToHomeView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: MainMenuView())
            window.makeKeyAndVisible()
        }
    }
    
    static func switchToUserTypeSelection() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: UserTypeSelectionView())
            window.makeKeyAndVisible()
        }
    }
    static func switchToSignInView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: SignInUpView())
            window.makeKeyAndVisible()
        }
    }
    static func switchToSettingsView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: SettingsView())
            window.makeKeyAndVisible()
        }
    }
    static func switchToAccountSettingsView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: AccountSettingsView())
            window.makeKeyAndVisible()
        }
    }
}
