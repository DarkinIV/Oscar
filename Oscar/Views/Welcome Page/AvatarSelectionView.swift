import SwiftUI

struct AvatarSelectionView: View {
    @State private var selectedAvatar = 0
    @State private var showHomeView = false
    
    let userType: UserType
    let onAvatarSelected: (String) -> Void
    
    let avatars = [
        "Talking Right",
        "Talking Left",
        "Jumping",
        "Writing notes",
        "Help"
    ]
    
    var body: some View {
        NavigationView {
            if showHomeView {
                MainMenuView()
            } else {
                VStack(spacing: 30) {
                    Text("Choose Your Avatar")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Selected avatar preview
                    Image(avatars[selectedAvatar])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(.vertical)
                    
                    // Avatar options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(0..<avatars.count, id: \.self) { index in
                                Image(avatars[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selectedAvatar == index ? Color.white : Color.clear,
                                                    lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedAvatar = index
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        onAvatarSelected(avatars[selectedAvatar])
                        withAnimation {
                            showHomeView = true
                        }
                    }) {
                        Text("Continue")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AccentColor"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: [
                        Color("AccentColor"),
                        Color("SecondColor").opacity(0.8)
                    ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
    
}

#Preview {
    AvatarSelectionView(userType: .guardian) { _ in }
}
