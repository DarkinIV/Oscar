import SwiftUI

// MARK: - Header View
struct NotificationHeader: View {
    let unreadCount: Int
    let onMarkAllAsRead: () -> Void
    
    var body: some View {
            HStack {
            Text("Your Messages")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
            Button(action: onMarkAllAsRead) {
                Text("All caught up!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            .disabled(unreadCount == 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color("AccentColor"), Color("SecondColor")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}
            
// MARK: - Empty State View
struct EmptyNotificationsView: View {
    var body: some View {
                VStack {
                    Spacer()
            Image(systemName: "bell.badge.waveform")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.bottom, 8)
                .scaleEffect(1.1)
            Text("All quiet here!")
                        .font(.headline)
                        .foregroundColor(.gray)
            Text("We'll let you know when something happens")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
                .frame(height: 150)
                .background(Color("LightColor").opacity(0.1))
    }
}

// MARK: - Notification List View
struct NotificationListView: View {
    let notifications: [InAppNotification]
    let onNotificationTap: (InAppNotification) -> Void
    
    var body: some View {
                ScrollView {
                    LazyVStack(spacing: 0) {
                ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                                .background(
                                    notification.isRead ? 
                                        Color("LightColor").opacity(0.1) : 
                                        Color("AccentColor").opacity(0.15)
                                )
                                .onTapGesture {
                            onNotificationTap(notification)
                                }
                            
                            Divider()
                                .background(Color("AccentColor").opacity(0.1))
                        }
                    }
                }
    }
}

// MARK: - Main Notification Panel
struct NotificationPanel: View {
    @ObservedObject var notificationManager = InAppNotificationManager.shared
    @Binding var isExpanded: Bool
    var maxHeight: CGFloat = 300
    
    var body: some View {
        VStack(spacing: 0) {
            NotificationHeader(
                unreadCount: notificationManager.unreadCount,
                onMarkAllAsRead: {
                    Task {
                        await notificationManager.markAllAsRead()
                    }
                }
            )
            
            if notificationManager.notifications.isEmpty {
                EmptyNotificationsView()
            } else {
                NotificationListView(
                    notifications: notificationManager.notifications,
                    onNotificationTap: { notification in
                        Task {
                            await notificationManager.markAsRead(notification.id)
                        }
                    }
                )
                .frame(maxHeight: maxHeight)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color("AccentColor").opacity(0.2), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: InAppNotification
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with icon and title
            HStack(spacing: 8) {
                NotificationIcon(type: notification.type)
                
                Text(notification.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("AccentColor"))
                
                Spacer()
                
                Text(timeAgoString(from: notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Message
            Text(notification.message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.leading, 32)
            
            // Action buttons for link requests
            if shouldShowActionButtons {
                LinkRequestButtons(
                    isProcessing: isProcessing,
                    onAccept: { handleLinkAction(accept: true) },
                    onDecline: { handleLinkAction(accept: false) }
                )
            }
        }
        .overlay(
            isProcessing ? 
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
                    .padding(8)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(8) : nil
        )
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Notification"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var shouldShowActionButtons: Bool {
        notification.type == .childLinked && 
        notification.title.contains("Request") && 
        !notification.isRead
    }
    
    // Handle accept/decline actions for link requests
    private func handleLinkAction(accept: Bool) {
        guard let requestId = extractRequestId(from: notification) else {
            alertMessage = "Could not process this request. Please try again later."
            showAlert = true
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let guardianManager = GuardianChildManager()
                try await guardianManager.handleLinkRequest(requestId: requestId, accept: accept)
                
                await MainActor.run {
                    isProcessing = false
                    showAlert = true
                    alertMessage = accept ? "Link request accepted successfully" : "Link request declined"
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    showAlert = true
                    alertMessage = error.localizedDescription
                }
            }
        }
    }
    
    // Extract request ID from notification
    private func extractRequestId(from notification: InAppNotification) -> String? {
        // First check if we have a requestId directly on the notification
        if let requestId = notification.requestId {
            return requestId
        }
        
        // Fallback to related child ID if needed (for backward compatibility)
        if let childId = notification.relatedChildId, notification.type == .childLinked {
            // Try to find the pending request for this child
        }
        
        return nil // If we can't find it synchronously
    }
}

// MARK: - Supporting Views
struct NotificationIcon: View {
    let type: NotificationType
    
    var body: some View {
        Image(systemName: iconForType(type))
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(colorForType(type))
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(colorForType(type).opacity(0.15))
            )
    }
    
    private func iconForType(_ type: NotificationType) -> String {
        switch type {
        case .medicationReminder: return "pill.fill"
        case .medicationTaken: return "checkmark.circle.fill"
        case .childLinked: return "person.2.fill"
        case .accountActivity: return "person.crop.circle.fill"
        case .guardianRequestSent: return "envelope.fill"
        case .childUnlinked: return "person.xmark.circle.fill"
        }
    }
    
    private func colorForType(_ type: NotificationType) -> Color {
        switch type {
        case .medicationReminder: return Color("AccentColor")
        case .medicationTaken: return .green
        case .childLinked: return Color("SecondColor")
        case .accountActivity: return .orange
        case .guardianRequestSent: return Color("AccentColor")
        case .childUnlinked: return .blue
        }
    }
}

struct LinkRequestButtons: View {
    let isProcessing: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            
            Button(action: onAccept) {
                Text("Accept")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .disabled(isProcessing)
            
            Button(action: onDecline) {
                Text("Decline")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
            }
            .disabled(isProcessing)
        }
        .padding(.top, 8)
        .padding(.trailing, 8)
    }
}

// MARK: - Helper Functions
private func timeAgoString(from date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
    
    if let day = components.day, day > 0 {
        return day == 1 ? "Yesterday" : "\(day) days ago"
    } else if let hour = components.hour, hour > 0 {
        return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
    } else if let minute = components.minute, minute > 0 {
        return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
    } else {
        return "Just now"
    }
}

// MARK: - Preview Provider
struct NotificationPanel_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPanel(isExpanded: .constant(true))
            .frame(width: 300)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
