import Foundation
import FirebaseFirestore

struct LinkedChild: Identifiable, Codable {
    let id: String // Child's user ID
    let name: String
    let avatar: String?
    let linkDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatar
        case linkDate
    }
}

struct LinkRequest: Identifiable, Codable {
    let id: String
    let guardianId: String
    let childId: String
    let status: LinkRequestStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case guardianId
        case childId
        case status
        case createdAt
    }
}

class GuardianChildManager: ObservableObject {
    @Published private(set) var linkedChildren: [LinkedChild] = []
    @Published private(set) var pendingRequests: [LinkRequest] = []
    private let db = Firestore.firestore()
    
    init() {
        loadLinkedChildren()
        loadPendingRequests()
    }
    
    // Add this method for testing purposes
    func setLinkedChildrenForTesting(_ children: [LinkedChild]) {
        self.linkedChildren = children
    }
    
    private func loadLinkedChildren() {
        guard let guardianId = AuthenticationManager.shared.currentUser?.id else {
            print("Error: No authenticated user found")
            return
        }
        
        guard AuthenticationManager.shared.currentUser?.userType == .guardian else {
            print("Error: User is not a guardian")
            return
        }
        
        db.collection("guardianChildLinks")
            .whereField("guardianId", isEqualTo: guardianId)
            .whereField("status", isEqualTo: LinkRequestStatus.accepted.rawValue)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    if (error as NSError).code == 7 {
                        print("Permission denied: Please check if you have the correct access rights")
                    } else {
                        print("Error fetching linked children: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No linked children found")
                    return
                }
                
                Task {
                    var children: [LinkedChild] = []
                    
                    for document in documents {
                        if let childId = document.data()["childId"] as? String {
                            do {
                                let childDoc = try await self.db.collection("users").document(childId).getDocument()
                                if let childData = childDoc.data() {
                                    let child = LinkedChild(
                                        id: childId,
                                        name: childData["name"] as? String ?? "",
                                        avatar: childData["avatar"] as? String,
                                        linkDate: document.data()["createdAt"] as? Date ?? Date()
                                    )
                                    children.append(child)
                                }
                            } catch {
                                if (error as NSError).code == 7 {
                                    print("Permission denied: Cannot access child data. Please check permissions")
                                } else {
                                    print("Error fetching child data: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.linkedChildren = children
                    }
                }
            }
    }
    
    private func loadPendingRequests() {
        guard let currentUserId = AuthenticationManager.shared.currentUser?.id else {
            print("Error: No authenticated user found")
            return
        }
        
        db.collection("guardianChildLinks")
            .whereField("status", isEqualTo: LinkRequestStatus.pending.rawValue)
            .whereField(currentUserId == AuthenticationManager.shared.currentUser?.id ? "childId" : "guardianId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching pending requests: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No pending requests found")
                    return
                }
                
                let requests = documents.compactMap { try? $0.data(as: LinkRequest.self) }
                DispatchQueue.main.async {
                    self.pendingRequests = requests
                }
            }
    }
    
    func sendLinkRequest(childId: String) async throws {
        print("Starting link request for childId: \(childId)")
        
        // Validate input format
        guard childId.count == 9, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: childId)) else {
            print("Invalid childId format")
            throw LinkError.invalidChildId
        }
        
        guard let guardianId = AuthenticationManager.shared.currentUser?.id else {
            print("Guardian not found in AuthenticationManager")
            throw LinkError.guardianNotFound
        }
        
        // Check if user is a guardian
        guard let currentUser = AuthenticationManager.shared.currentUser else {
            print("Current user not found")
            throw LinkError.userNotFound
        }
        
        guard currentUser.userType == .guardian else {
            print("User is not a guardian. UserType: \(currentUser.userType)")
            throw LinkError.notGuardian
        }
        
        print("Searching for child account with userID: \(childId)")
        
        // Search for child account by userID
        let querySnapshot = try await db.collection("users")
            .whereField("userID", isEqualTo: childId)
            .whereField("userType", isEqualTo: UserType.kid.rawValue)
            .getDocuments()
        
        guard let childDoc = querySnapshot.documents.first else {
            print("Child account not found in database")
            throw LinkError.childNotFound
        }
        
        let childData = childDoc.data()
        let childUserId = childDoc.documentID
        
        print("Found child account. DocumentID: \(childUserId)")
        
        // Verify the child's userID matches the provided one
        guard let storedUserID = childData["userID"] as? String,
              storedUserID == childId else {
            print("Stored userID mismatch. Expected: \(childId), Found: \(childData["userID"] ?? "nil")")
            throw LinkError.invalidChildId
        }
        
        // Check if already linked
        let existingLinks = try await db.collection("guardianChildLinks")
            .whereField("guardianId", isEqualTo: guardianId)
            .whereField("childId", isEqualTo: childUserId)
            .whereField("status", isEqualTo: LinkRequestStatus.accepted.rawValue)
            .getDocuments()
        
        if !existingLinks.documents.isEmpty {
            print("Already linked to this child")
            throw LinkError.alreadyLinked
        }
        
        // Check for pending requests
        let pendingRequests = try await db.collection("guardianChildLinks")
            .whereField("guardianId", isEqualTo: guardianId)
            .whereField("childId", isEqualTo: childUserId)
            .whereField("status", isEqualTo: LinkRequestStatus.pending.rawValue)
            .getDocuments()
        
        if !pendingRequests.documents.isEmpty {
            print("Pending request already exists")
            throw LinkError.pendingRequestExists
        }
        
        print("Creating new link request")
        
        // Create link request
        let requestId = UUID().uuidString
        let request = LinkRequest(
            id: requestId,
            guardianId: guardianId,
            childId: childUserId,
            status: .pending,
            createdAt: Date()
        )
        
        do {
            // Store the request in Firestore
            try await db.collection("guardianChildLinks").document(requestId).setData(from: request)
            print("Link request created successfully")
        
            // Create notifications
            let notificationManager = await InAppNotificationManager()
            
            print("Sending notification to child")
        try await notificationManager.createNotification(
            for: childUserId,
            title: "New Guardian Link Request",
            message: "A guardian would like to link to your account. Would you like to accept?",
            type: .childLinked,
            relatedChildId: childUserId,
            requestId: requestId
        )
        
            print("Sending notification to guardian")
        try await notificationManager.createNotification(
            for: guardianId,
            title: "Link Request Sent",
            message: "Your request to link with the child account has been sent. Waiting for approval.",
            type: .guardianRequestSent,
            relatedChildId: childUserId,
            requestId: requestId
        )
            
            print("Link request process completed successfully")
        } catch {
            print("Error during link request process: \(error.localizedDescription)")
            throw error
        }
    }
    
    func handleLinkRequest(requestId: String, accept: Bool) async throws {
        guard let currentUserId = AuthenticationManager.shared.currentUser?.id else {
            throw LinkError.userNotFound
        }

        let requestDoc = try await db.collection("guardianChildLinks").document(requestId).getDocument()
        guard let request = try? requestDoc.data(as: LinkRequest.self) else {
            throw LinkError.linkNotFound
        }

        // Verify that the current user is the child who received the request
        guard currentUserId == request.childId else {
            throw LinkError.insufficientPermissions
        }
        
        // Update request status
        try await db.collection("guardianChildLinks").document(requestId).updateData([
            "status": accept ? LinkRequestStatus.accepted.rawValue : LinkRequestStatus.rejected.rawValue
        ])
        
        // If the request is accepted, create a default schedule for the child
        if accept {
            let scheduleManager = MedicationScheduleManager(userId: currentUserId)
            scheduleManager.createDefaultSchedule()
        }
        
        // Create notification for guardian
        let notificationManager = await InAppNotificationManager()
        try await notificationManager.createNotification(
            for: request.guardianId,
            title: accept ? "Link Request Accepted" : "Link Request Declined",
            message: accept ? "Your link request has been accepted." : "Your link request has been declined.",
            type: .childLinked,
            relatedChildId: request.childId
        )
    }
    
    func unlinkChild(childId: String) async throws {
        guard let guardianId = AuthenticationManager.shared.currentUser?.id else {
            throw LinkError.guardianNotFound
        }
        
        let links = try await db.collection("guardianChildLinks")
            .whereField("guardianId", isEqualTo: guardianId)
            .whereField("childId", isEqualTo: childId)
            .whereField("status", isEqualTo: LinkRequestStatus.accepted.rawValue)
            .getDocuments()
        
        guard let linkDoc = links.documents.first else {
            throw LinkError.linkNotFound
        }
        
        try await linkDoc.reference.delete()
        
        // Create notification for child
        let notificationManager = await InAppNotificationManager()
        try await notificationManager.createNotification(
            for: childId,
            title: "Account Unlinked",
            message: "A guardian has unlinked from your account.",
            type: .childUnlinked,
            relatedChildId: childId
        )
    }
    
    static func getGuardianIds(forChildId childId: String) async throws -> [String] {
        let db = Firestore.firestore()
        let links = try await db.collection("guardianChildLinks")
            .whereField("childId", isEqualTo: childId)
            .whereField("status", isEqualTo: LinkRequestStatus.accepted.rawValue)
            .getDocuments()
        
        return links.documents.compactMap { $0.data()["guardianId"] as? String }
    }
}

enum LinkError: LocalizedError {
    case notGuardian
    case childNotFound
    case insufficientPermissions
    case userNotFound
    case guardianNotFound
    case linkNotFound
    case alreadyLinked
    case pendingRequestExists
    case invalidChildId
    
    var errorDescription: String? {
        switch self {
        case .notGuardian:
            return "Only guardians can send link requests"
        case .childNotFound:
            return "Child account not found"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .userNotFound:
            return "User not found"
        case .guardianNotFound:
            return "Guardian not found"
        case .linkNotFound:
            return "Link not found"
        case .alreadyLinked:
            return "Already linked to this child"
        case .pendingRequestExists:
            return "A pending request already exists"
        case .invalidChildId:
            return "Please enter a valid 9-digit User ID"
        }
    }
}
