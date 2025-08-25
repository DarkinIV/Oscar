//
//  ContentView.swift
//  Oscar-ChildMed
//
//  Created by Asim Yilmaz on 02/02/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            NavigationView {
                ZStack {
                    // Custom gradient background
                    LinearGradient(gradient: Gradient(colors: [
                        Color("AccentColor"),
                        Color("SecondColor").opacity(0.8)
                    ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Oscar welcome animation
                        VStack(spacing: 20) {
                            Image("Talking Right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                            
                            VStack(spacing: 15) {
                                Text("Hey there! I'm Oscar,")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("your friendly meds reminder.")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("I'm here to make sure\nyou never miss your medication\nand to help you navigate\nthrough the app.")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 5)
                                
                                NavigationLink(destination: SignInUpView()) {
                                    Text("Let's get started!")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("AccentColor"))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 40)
                                .padding(.top, 20)
                            }
                            .opacity(isAnimating ? 1 : 0)
                            .animation(.easeIn(duration: 1.0).delay(0.5), value: isAnimating)
                        }
                    }
                }
                .onAppear {
                    isAnimating = true
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
}
