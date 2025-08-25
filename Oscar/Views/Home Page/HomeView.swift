import SwiftUI
import Foundation

struct WelcomeHeader: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showAccountSettings = false
    @State private var userName: String = ""
    @State private var userAvatar: String = "Talking Right"
    
    var body: some View {
        HStack {
            Image(userAvatar)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            
            Text("Hi, \(userName)!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal)
        .onTapGesture {
            showAccountSettings = true
        }
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView()
        }
        .onAppear {
            updateUserInfo()
        }
        .onChange(of: authManager.currentUser) { _, _ in
            updateUserInfo()
        }
    }
    
    private func updateUserInfo() {
        Task { @MainActor in
            userName = authManager.currentUser?.name ?? "Friend"
            userAvatar = authManager.currentUser?.avatar ?? "Talking Right"
        }
    }
}

struct HomeView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var medicationManager = MedicationScheduleManager()
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    
    private func scrollToDate(date: Date, offset: Int, proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            selectedDate = date
            proxy.scrollTo(offset, anchor: .center)
        }
    }
    
    // Get medications for selected date
    private var dailyMedications: [MedicationSchedule] {
        medicationManager.getMedicationsForDate(selectedDate)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab with Calendar
            NavigationView {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [
                        Color("AccentColor"),
                        Color("SecondColor").opacity(0.8)
                    ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Welcome Header
                        WelcomeHeader()
                        
                        // Calendar View
                        CalendarView(selectedDate: $selectedDate, scrollToDate: scrollToDate)
                        
                        // Medication List
                        MedicationListView(medications: dailyMedications, selectedDate: selectedDate, medicationManager: medicationManager)
                    }
                    .padding(.vertical)
                }
                .navigationBarHidden(true)
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Other tabs
            Text("My Medicines")
                .tabItem {
                    Image(systemName: "pill.fill")
                    Text("Medicines")
                }
                .tag(1)
            
            Text("I Took It!")
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Took It")
                }
                .tag(2)
            
            Text("My Rewards")
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Rewards")
                }
                .tag(3)
            
            Text("Parent Mode")
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Parent")
                }
                .tag(4)
            
            Text("Need Help?")
                .tabItem {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Help")
                }
                .tag(5)
        }
        .accentColor(Color("AccentColor"))
    }
}

struct MedicationCard: View {
    let medication: MedicationSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pill.fill")
                    .foregroundColor(Color("AccentColor"))
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundColor(Color("AccentColor"))
                }
                Spacer()
                Text(medication.time, format: .dateTime.hour().minute())
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if !medication.note.isEmpty {
                Text(medication.note)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.leading, 28)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
}
