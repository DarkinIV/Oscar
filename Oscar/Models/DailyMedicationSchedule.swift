import Foundation

struct DailyMedicationSchedule: Codable, Identifiable {
    let date: Date
    var medications: [MedicationSchedule]
    var id = UUID()
}
