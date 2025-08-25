import SwiftUI
import SwiftUI

struct ChildHomeView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var medicationManager = MedicationScheduleManager()
    @StateObject private var notificationManager = InAppNotificationManager()
    @State private var selectedDate = Date()
    @State private var showRewardAnimation = false
    @State private var showNotifications = false
    
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
        // Home Tab with Calendar
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color("AccentColor"),
                    Color("SecondColor").opacity(0.75)
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Welcome Header
                    ChildWelcomeHeader(showNotifications: $showNotifications, notificationCount: notificationManager.unreadCount)
                    
                    // Calendar View
                    CalendarView(selectedDate: $selectedDate, scrollToDate: scrollToDate)
                    
                    // Medication List (read-only for children)
                    ChildMedicationView(medications: dailyMedications, selectedDate: selectedDate)
                }
                .padding(.vertical)
                
                // Notification Panel Overlay
                if showNotifications {
                    VStack {
                        HStack {
                            Spacer()
                            NotificationPanel(notificationManager: notificationManager, isExpanded: $showNotifications)
                                .frame(width: 300)
                                .padding(.top, 60)
                                .padding(.trailing, 20)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        Spacer()
                    }
                    .background(Color.black.opacity(0.001)) // Invisible background to capture taps
                    .onTapGesture {
                        withAnimation {
                            showNotifications = false
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct ChildWelcomeHeader: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showAccountSettings = false
    @State private var userName: String = ""
    @State private var userAvatar: String = "Talking Right"
    @Binding var showNotifications: Bool
    let notificationCount: Int
    
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
            
            // Notification Bell
            Button(action: {
                withAnimation(.spring()) {
                    showNotifications.toggle()
                }
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if notificationCount > 0 {
                        Text("\(notificationCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 8, y: -5)
                    }
                }
            }
            .padding(.horizontal, 8)
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

struct ChildMedicationView: View {
    let medications: [MedicationSchedule]
    let selectedDate: Date
    @State private var completedMedications: Set<UUID> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Today's Medications")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                if medications.isEmpty {
                    VStack {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 10)
                        Text("No medications scheduled for this day")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                } else {
                    let sortedMedications = medications.sorted { $0.time < $1.time }
                    ForEach(sortedMedications) { medication in
                        ChildMedicationCard(
                            medication: medication,
                            isCompleted: completedMedications.contains(medication.id),
                            onToggleCompletion: { toggleCompletion(medication) }
                        )
                    }
                }
            }
        }
    }
    
    private func toggleCompletion(_ medication: MedicationSchedule) {
        if completedMedications.contains(medication.id) {
            completedMedications.remove(medication.id)
        } else {
            completedMedications.insert(medication.id)
            // Here you would update the medication status in the database
            // and potentially trigger reward animations
        }
    }
}

struct ChildMedicationCard: View {
    let medication: MedicationSchedule
    let isCompleted: Bool
    let onToggleCompletion: () -> Void
    
    var body: some View {
        HStack {
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
            
            Button(action: onToggleCompletion) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .opacity(isCompleted ? 0.7 : 1.0)
    }
}

#Preview {
    ChildHomeView()
}
