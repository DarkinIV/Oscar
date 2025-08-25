import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable {
    case medicationReminder
    case medicationTaken
    case childLinked
    case accountActivity
    case guardianRequestSent
    case childUnlinked
}

struct InAppNotification: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let type: NotificationType
    let createdAt: Date
    var isRead: Bool
    var relatedMedicationId: String?
    var relatedChildId: String?
    var requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case type
        case createdAt
        case isRead
        case relatedMedicationId
        case relatedChildId
        case requestId
    }
}

@MainActor
class InAppNotificationManager: ObservableObject {
    static let shared = InAppNotificationManager()
    private let db = Firestore.firestore()
    
    @Published private(set) var notifications: [InAppNotification] = []
    @Published private(set) var unreadCount: Int = 0
    
    init() {
        loadNotifications()
    }
    
    private func loadNotifications() {
        guard let userId = AuthenticationManager.shared.currentUser?.id else { return }
        
        let notificationsRef = db.collection("users")
            .document(userId)
            .collection("notifications")
            .order(by: "createdAt", descending: true)
        
        notificationsRef.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching notifications: \(error)")
                    return
                }
                
            guard let documents = querySnapshot?.documents else {
                print("No notifications found")
                return
            }
            
            let decodedNotifications = documents.compactMap { document -> InAppNotification? in
                try? document.data(as: InAppNotification.self)
            }
            
            Task { @MainActor in
                self.notifications = decodedNotifications
                self.unreadCount = self.notifications.filter { !$0.isRead }.count
            }
        }
    }
    
    func createNotification(for userId: String, title: String, message: String, type: NotificationType, relatedMedicationId: String? = nil, relatedChildId: String? = nil, requestId: String? = nil) async throws {
        let notification = InAppNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            type: type,
            createdAt: Date(),
            isRead: false,
            relatedMedicationId: relatedMedicationId,
            relatedChildId: relatedChildId,
            requestId: requestId
        )
        
        let notificationRef = db.collection("users")
            .document(userId)
            .collection("notifications")
            .document(notification.id)
        
        do {
            try await notificationRef.setData(from: notification)
        } catch {
            print("Error creating notification: \(error)")
            throw error
        }
    }
    
    func markAsRead(_ notificationId: String) async {
        guard let userId = AuthenticationManager.shared.currentUser?.id else { return }
        
        let notificationRef = db.collection("users")
            .document(userId)
            .collection("notifications")
            .document(notificationId)
        
        do {
            let updateData: [String: Any] = ["isRead": true]
            try await notificationRef.updateData(updateData)
            
            await MainActor.run {
                if let index = self.notifications.firstIndex(where: { $0.id == notificationId }) {
                    self.notifications[index].isRead = true
                    self.unreadCount = self.notifications.filter { !$0.isRead }.count
                }
            }
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    func markAllAsRead() async {
        guard let userId = AuthenticationManager.shared.currentUser?.id else { return }
        
        let batch = db.batch()
        let notificationsRef = db.collection("users")
            .document(userId)
            .collection("notifications")
        
        let updateData: [String: Any] = ["isRead": true]
        
        for notification in notifications where !notification.isRead {
            let docRef = notificationsRef.document(notification.id)
            batch.updateData(updateData, forDocument: docRef)
        }
        
        do {
            try await batch.commit()
            
            await MainActor.run {
                for index in notifications.indices {
                    notifications[index].isRead = true
                }
                unreadCount = 0
            }
        } catch {
            print("Error marking all notifications as read: \(error)")
        }
    }
    
    func deleteNotification(_ notificationId: String) async {
        guard let userId = AuthenticationManager.shared.currentUser?.id else { return }
        
        let notificationRef = db.collection("users")
            .document(userId)
            .collection("notifications")
            .document(notificationId)
        
        do {
            try await notificationRef.delete()
            
            await MainActor.run {
                self.notifications.removeAll { $0.id == notificationId }
                self.unreadCount = self.notifications.filter { !$0.isRead }.count
            }
        } catch {
            print("Error deleting notification: \(error)")
        }
    }
}
