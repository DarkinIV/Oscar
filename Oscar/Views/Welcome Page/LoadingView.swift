import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var showHomeView = false
    @State private var greetingText = "Welcome!"
    let isNewUser: Bool
    
    var body: some View {
        Group {
            if showHomeView {
                MainHomeView()
                    .navigationBarBackButtonHidden(true)
            } else {
                VStack(spacing: 20) {
                    Image("Talking Right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text(greetingText)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeIn(duration: 0.5).delay(0.3), value: isAnimating)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: [
                        Color("AccentColor"),
                        Color("SecondColor").opacity(0.8)
                    ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                )
                .onAppear {
                    isAnimating = true
                    
                    // Simulate loading and update greeting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        greetingText = "Getting everything ready..."
                    }
                    
                    // Navigate to appropriate view after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showHomeView = true
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    LoadingView(isNewUser: true)
}
