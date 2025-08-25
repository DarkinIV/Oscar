import SwiftUI

struct GuardianHomeView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var guardianManager = GuardianChildManager()
    @StateObject private var notificationManager = InAppNotificationManager()

    
    @State private var childEmail = ""
    @State private var linkError: String? = nil
    @State private var isLinking = false
    @State private var showNotifications = false
    
    @State private var selectedDate = Date()
    @State private var selectedChildId: String? = nil
    @State private var showAddChildSheet = false
    @State private var childManagers: [String: MedicationScheduleManager] = [:]
    @State private var selectedTab = 0
    
    private func scrollToDate(date: Date, offset: Int, proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            selectedDate = date
            proxy.scrollTo(offset, anchor: .center)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color("AccentColor"),
                    Color("SecondColor").opacity(0.75)
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

                VStack(spacing: 10) {
                    // Welcome Header
                    GuardianWelcomeHeader(showNotifications: $showNotifications, notificationCount: notificationManager.unreadCount)
                    
                    // Child Selector
                    ChildSelectorView(
                        children: guardianManager.linkedChildren,
                        selectedChildId: $selectedChildId,
                        showAddChildSheet: $showAddChildSheet
                    )
                    
                    if let childId = selectedChildId {

                        // Calendar View
                        CalendarView(selectedDate: $selectedDate, scrollToDate: scrollToDate)
                        
                        // Child's Medication List
                        let manager = childManagers[childId] ?? MedicationScheduleManager(userId: childId)
                        ChildMedicationListView(childId: childId, selectedDate: selectedDate, medicationManager: manager)
                            .onAppear {
                                if childManagers[childId] == nil {
                                    childManagers[childId] = manager
                                }
                            }
                        Spacer(minLength: 55)

                    }
                    else {
                        Spacer()
                        VStack(spacing: 20) {
                            Image("Talking Right")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                            
                            Text(guardianManager.linkedChildren.isEmpty ?
                                 "No children linked to your account yet" :
                                    "Select a child to view their medications")
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button(action: { showAddChildSheet = true }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add Child Account")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color("SecondColor"))
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        Spacer(minLength: 150)

                    }
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
        .accentColor(Color("AccentColor"))
        .overlay {
            if showAddChildSheet {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showAddChildSheet = false
                            childEmail = ""
                            linkError = nil
                        }
                    }
                
                AddChildView(
                    childUserId: $childEmail,
                    linkError: $linkError,
                    isLinking: $isLinking,
                    guardianManager: guardianManager,
                    isPresented: $showAddChildSheet
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.98).combined(with: .opacity)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8)),
                    removal: .scale(scale: 0.98).combined(with: .opacity)
                        .animation(.spring(response: 0.2, dampingFraction: 0.85))
                ))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showAddChildSheet)
    }
}

struct GuardianWelcomeHeader: View {
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



struct DateNavigationView: View {
    @Binding var selectedDate: Date
    let scrollToDate: (Date, Int, ScrollViewProxy) -> Void
    let proxy: ScrollViewProxy
    
    var body: some View {
        HStack(spacing: 0) {
            let calendar = Calendar.current
            let dayDifference = calendar.dateComponents([.day], from: Date(), to: selectedDate).day ?? 0
            
            // Past date button
            Button(action: {
                scrollToDate(Date(), 0, proxy)
            }) {
                HStack(spacing: 4) {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(15)
            }
            .opacity(dayDifference < -3 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: dayDifference)
            
            Spacer()
            
            Text(selectedDate.formatted(.dateTime.month().day().year()))
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Future date button
            Button(action: {
                scrollToDate(Date(), 0, proxy)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(15)
            }
            .opacity(dayDifference > 2 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: dayDifference)
        }
        .padding(.horizontal)
    }
}

struct ChildSelectorView: View {
    let children: [LinkedChild]
    @Binding var selectedChildId: String?
    @Binding var showAddChildSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your Children")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
            }
            .padding(.horizontal)
            
            if children.isEmpty {
                HStack {
                    Spacer()
                    Text("No children linked yet")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
                .padding(.vertical, 10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack(spacing: 5) {
                        // Add Child Button
                        Button(action: {
                            // Trigger your add child flow here
                            showAddChildSheet = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color("AccentColor").opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        .padding(.top, -15)
                        .accessibilityLabel("Add Child")
                        ForEach(children) { child in
                            ChildAvatarView(
                                child: child,
                                isSelected: selectedChildId == child.id,
                                action: {
                                    selectedChildId = child.id
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ChildAvatarView: View {
    let child: LinkedChild
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(child.avatar ?? "Talking Right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(isSelected ? Color("AccentColor") : Color.white, lineWidth: 2))
                    .shadow(color: isSelected ? Color("AccentColor").opacity(0.6) : Color.clear, radius: 5)
                
                Text(child.name.prefix(6))
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
            .cornerRadius(10)
        }
    }
}

struct AddChildView: View {
    @Binding var childUserId: String
    @Binding var linkError: String?
    @Binding var isLinking: Bool
    @ObservedObject var guardianManager: GuardianChildManager
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Add Child Account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AccentColor"))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Child's User ID")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    TextField("Enter 9-digit User ID", text: $childUserId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disabled(isLinking)
                        .onChange(of: childUserId) { newValue in
                            // Only allow numbers and limit to 9 digits
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue || filtered.count > 9 {
                                childUserId = String(filtered.prefix(9))
                            }
                            // Clear any previous error when user starts typing
                            if !childUserId.isEmpty {
                                linkError = nil
                            }
                        }
                    
                    if let error = linkError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                Button(action: linkChildAccount) {
                    HStack {
                        if isLinking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                        } else {
                            Text("Link Child Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AccentColor"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .opacity(childUserId.count == 9 && !isLinking ? 1 : 0.6)
                }
                .disabled(childUserId.count != 9 || isLinking)
                .padding(.horizontal)
                
                Text("You can only link child accounts that have been created with the 'Kid' account type.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Cancel") {
                    withAnimation {
                        isPresented = false
                        childUserId = ""
                        linkError = nil
                    }
                }
                .foregroundColor(Color("AccentColor"))
            }
            .padding(.vertical, 30)
            .frame(width: UIScreen.main.bounds.width * 0.9)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
    
    private func linkChildAccount() {
        isLinking = true
        linkError = nil
        
        // Validate input format
        guard childUserId.count == 9, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: childUserId)) else {
            linkError = "Please enter a valid 9-digit User ID"
            isLinking = false
            return
        }
        
        Task {
            do {
                try await guardianManager.sendLinkRequest(childId: childUserId)
                await MainActor.run {
                    withAnimation {
                        isPresented = false
                        childUserId = ""
                    }
                }
            } catch LinkError.childNotFound {
                await MainActor.run {
                    linkError = "Child account not found. Please verify the User ID."
                }
            } catch LinkError.alreadyLinked {
                await MainActor.run {
                    linkError = "This child is already linked to your account."
                }
            } catch LinkError.pendingRequestExists {
                await MainActor.run {
                    linkError = "A pending request already exists for this child."
                }
            } catch LinkError.notGuardian {
                await MainActor.run {
                    linkError = "Only guardian accounts can link to children."
                }
            } catch {
                await MainActor.run {
                    linkError = "Failed to send link request: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isLinking = false
            }
        }
    }
}

struct ChildMedicationListView: View {
    let childId: String
    let selectedDate: Date
    @ObservedObject var medicationManager: MedicationScheduleManager
    
    private var dailyMedications: [MedicationSchedule] {
        medicationManager.getMedicationsForDate(selectedDate)
    }
    
    var body: some View {
        MedicationListView(
            medications: dailyMedications,
            selectedDate: selectedDate,
            medicationManager: medicationManager
        )
    }
}

#Preview {
    GuardianHomeView()

}
