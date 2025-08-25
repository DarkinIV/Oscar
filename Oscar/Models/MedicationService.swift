import Foundation
import FirebaseFirestore
import FirebaseAuth

class MedicationService: ObservableObject {
    static let shared = MedicationService()
    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard
    
    @Published private(set) var dailySchedules: [DailyMedicationSchedule] = []
    
    private init() {
        loadSchedules()
    }
    
    private func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func loadSchedules() {
        guard let userId = getCurrentUserId() else { return }
        
        db.collection("users")
            .document(userId)
            .collection("schedules")
            .order(by: "date", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching schedules: \(String(describing: error))")
                    return
                }
                
                self.dailySchedules = documents.compactMap { document -> DailyMedicationSchedule? in
                    try? document.data(as: DailyMedicationSchedule.self)
                }
            }
    }
    
    func getMedicationsForDate(_ date: Date) -> [MedicationSchedule] {
        if let schedule = dailySchedules.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return schedule.medications
        }
        return []
    }
    
    func addMedication(_ medication: MedicationSchedule, forDate date: Date) {
        //guard let userId = getCurrentUserId() else { return }
        
        if let index = dailySchedules.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dailySchedules[index].medications.append(medication)
            saveSchedule(dailySchedules[index])
        } else {
            let newSchedule = DailyMedicationSchedule(date: date, medications: [medication])
            dailySchedules.append(newSchedule)
            saveSchedule(newSchedule)
        }
        
        NotificationManager.shared.scheduleNotification(for: medication)
    }
    
    func updateMedicationStatus(_ medication: MedicationSchedule, status: MedicationStatus, forDate date: Date) {
        //guard let userId = getCurrentUserId() else { return }
        
        if let scheduleIndex = dailySchedules.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
           let medicationIndex = dailySchedules[scheduleIndex].medications.firstIndex(where: { $0.id == medication.id }) {
            
            var updatedMedication = medication
            let updatedSchedule = dailySchedules[scheduleIndex]
            
            // Create a new medication instance with updated status
            updatedMedication = MedicationSchedule(
                id: medication.id,
                name: medication.name,
                time: medication.time,
                note: medication.note,
                dosage: medication.dosage,
                createdAt: medication.createdAt,
                status: status,
                completedAt: status == .completed ? Date() : nil
            )
            
            // Update the medication in the schedule
            dailySchedules[scheduleIndex].medications[medicationIndex] = updatedMedication
            saveSchedule(updatedSchedule)
            
            // Update notifications based on status
            if status == .completed || status == .skipped {
                NotificationManager.shared.cancelNotification(for: medication)
            }
        }
    }
    
    func removeMedication(_ medication: MedicationSchedule, forDate date: Date) {
        //guard let userId = getCurrentUserId() else { return }
        
        if let scheduleIndex = dailySchedules.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dailySchedules[scheduleIndex].medications.removeAll { $0.id == medication.id }
            
            if dailySchedules[scheduleIndex].medications.isEmpty {
                deleteSchedule(dailySchedules[scheduleIndex])
                dailySchedules.remove(at: scheduleIndex)
            } else {
                saveSchedule(dailySchedules[scheduleIndex])
            }
            
            NotificationManager.shared.cancelNotification(for: medication)
        }
    }
    
    private func saveSchedule(_ schedule: DailyMedicationSchedule) {
        guard let userId = getCurrentUserId() else { return }
        
        do {
            try db.collection("users")
                .document(userId)
                .collection("schedules")
                .document(schedule.id.uuidString)
                .setData(from: schedule)
        } catch {
            print("Error saving schedule: \(error)")
        }
    }
    
    private func deleteSchedule(_ schedule: DailyMedicationSchedule) {
        guard let userId = getCurrentUserId() else { return }
        
        db.collection("users")
            .document(userId)
            .collection("schedules")
            .document(schedule.id.uuidString)
            .delete()
    }
}
