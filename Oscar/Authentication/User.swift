import Foundation

enum UserType: String, Codable {
    case guardian
    case kid
}

struct User: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var email: String
    
    var userType: UserType
    var createdAt: Date = Date()
    var lastLoginAt: Date?
    var avatar: String?
    var userID: String // Changed from optional to required
    
    init(id: String, name: String, email: String, userType: UserType, avatar: String? = nil, userID: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.avatar = avatar
        self.userType = userType
        
        // Generate a random 9-digit userID for kids if not provided
        if userType == .kid {
            if let providedID = userID {
                // Validate the provided ID
                guard providedID.count == 9, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: providedID)) else {
                    fatalError("Invalid userID format for kid. Must be 9 digits.")
                }
                self.userID = providedID
            } else {
                // Generate a random 9-digit ID
                let randomID = String(format: "%09d", Int.random(in: 0...999999999))
                self.userID = randomID
            }
        } else {
            self.userID = userID ?? ""
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case userType
        case createdAt
        case lastLoginAt
        case avatar
        case userID
    }
}
