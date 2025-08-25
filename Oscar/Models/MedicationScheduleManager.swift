import Foundation
import FirebaseFirestore
import FirebaseAuth

class MedicationScheduleManager: ObservableObject {
    @Published private(set) var dailySchedules: [DailyMedicationSchedule] = []
    private let db = Firestore.firestore()
    private let userId: String
    
    init(userId: String? = nil) {
        if let userId = userId {
            self.userId = userId
        } else if let current = Auth.auth().currentUser?.uid {
            self.userId = current
        } else {
            self.userId = ""
        }
        loadSchedules()
    }
    
    func getMedicationsForDate(_ date: Date) -> [MedicationSchedule] {
        if let schedule = dailySchedules.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return schedule.medications
        }
        return []
    }
    
    func addMedication(_ medication: MedicationSchedule, forDate date: Date) {
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
    
    func removeMedication(_ medication: MedicationSchedule, forDate date: Date) {
        if let scheduleIndex = dailySchedules.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dailySchedules[scheduleIndex].medications.removeAll { $0.id == medication.id }
            if dailySchedules[scheduleIndex].medications.isEmpty {
                let scheduleToDelete = dailySchedules[scheduleIndex]
                dailySchedules.remove(at: scheduleIndex)
                deleteSchedule(scheduleToDelete)
            } else {
                saveSchedule(dailySchedules[scheduleIndex])
            }
            NotificationManager.shared.cancelNotification(for: medication)
        }
    }
    
    private func loadSchedules() {
        guard !userId.isEmpty else { return }
        db.collection("users")
            .document(userId)
            .collection("schedules")
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
    
    private func saveSchedule(_ schedule: DailyMedicationSchedule) {
        guard !userId.isEmpty else { return }
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
        guard !userId.isEmpty else { return }
        db.collection("users")
            .document(userId)
            .collection("schedules")
            .document(schedule.id.uuidString)
            .delete()
    }
    
    // Create a default empty schedule for a child
    func createDefaultSchedule() {
        guard !userId.isEmpty else { return }
        
        // Create a default schedule for today
        let defaultSchedule = DailyMedicationSchedule(
            date: Date(),
            medications: []
        )
        
        // Save the default schedule
        saveSchedule(defaultSchedule)
    }
    
    // Static function to create default schedules for all child accounts
    static func createDefaultSchedulesForAllChildren() async {
        let db = Firestore.firestore()
        
        do {
            // Get all child accounts
            let childDocs = try await db.collection("users")
                .whereField("userType", isEqualTo: "kid")
                .getDocuments()
            
            for childDoc in childDocs.documents {
                let childId = childDoc.documentID
                
                // Check if the child already has a schedule
                let scheduleDocs = try await db.collection("users")
                    .document(childId)
                    .collection("schedules")
                    .getDocuments()
                
                // If no schedules exist, create a default one
                if scheduleDocs.documents.isEmpty {
                    let scheduleManager = MedicationScheduleManager(userId: childId)
                    scheduleManager.createDefaultSchedule()
                }
            }
        } catch {
            print("Error creating default schedules: \(error)")
        }
    }
}
