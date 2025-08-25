import Foundation

struct MedicationSchedule: Identifiable, Codable {
    var id = UUID()
    let name: String
    let time: Date
    let note: String
    let dosage: String
    let createdAt: Date
    let status: MedicationStatus
    let completedAt: Date?
    
    init(id: UUID = UUID(), name: String, time: Date, note: String, dosage: String, createdAt: Date = Date(), status: MedicationStatus = .scheduled, completedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.time = time
        self.note = note
        self.dosage = dosage
        self.createdAt = createdAt
        self.status = status
        self.completedAt = completedAt
    }
}

enum MedicationStatus: String, Codable {
    case scheduled
    case completed
    case missed
    case skipped
}