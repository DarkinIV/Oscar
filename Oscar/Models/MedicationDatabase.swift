import Foundation

struct MedicationInfo: Identifiable, Codable {
    var id = UUID()
    let name: String
    let genericName: String
    let category: String
    let standardDosages: [String]
    let usageInstructions: String
    let commonSideEffects: [String]
    let precautions: String
    
    static let sampleMedications: [MedicationInfo] = [
        // Antibiotics
        MedicationInfo(
            name: "Amoxicillin",
            genericName: "Amoxicillin",
            category: "Antibiotic",
            standardDosages: ["250mg", "500mg", "875mg"],
            usageInstructions: "Take with or without food. Complete the full course as prescribed.",
            commonSideEffects: ["Diarrhea", "Nausea", "Rash"],
            precautions: "Inform doctor if allergic to penicillin."
        ),
        MedicationInfo(
            name: "Azithromycin",
            genericName: "Azithromycin",
            category: "Antibiotic",
            standardDosages: ["250mg", "500mg"],
            usageInstructions: "Take once daily. Complete the full course as prescribed.",
            commonSideEffects: ["Diarrhea", "Nausea", "Abdominal pain"],
            precautions: "Take on an empty stomach 1 hour before or 2 hours after meals."
        ),
        // Pain Relievers
        MedicationInfo(
            name: "Ibuprofen",
            genericName: "Ibuprofen",
            category: "Pain Reliever/Anti-inflammatory",
            standardDosages: ["200mg", "400mg", "600mg"],
            usageInstructions: "Take with food to prevent stomach upset.",
            commonSideEffects: ["Stomach pain", "Heartburn", "Dizziness"],
            precautions: "Not recommended for long-term use without medical supervision."
        ),
        MedicationInfo(
            name: "Tylenol",
            genericName: "Acetaminophen",
            category: "Pain Reliever/Fever Reducer",
            standardDosages: ["325mg", "500mg", "650mg"],
            usageInstructions: "Take every 4-6 hours as needed. Do not exceed 4000mg per day.",
            commonSideEffects: ["Nausea", "Headache", "Skin reactions"],
            precautions: "Avoid alcohol. Do not exceed recommended dose."
        ),
        // Antihistamines
        MedicationInfo(
            name: "Cetirizine",
            genericName: "Cetirizine Hydrochloride",
            category: "Antihistamine",
            standardDosages: ["5mg", "10mg"],
            usageInstructions: "Take once daily. May cause drowsiness.",
            commonSideEffects: ["Drowsiness", "Dry mouth", "Fatigue"],
            precautions: "Avoid alcohol. Use caution when driving."
        ),
        MedicationInfo(
            name: "Benadryl",
            genericName: "Diphenhydramine",
            category: "Antihistamine",
            standardDosages: ["25mg", "50mg"],
            usageInstructions: "Take every 4-6 hours. Do not exceed 300mg daily.",
            commonSideEffects: ["Severe drowsiness", "Dry mouth", "Blurred vision"],
            precautions: "May cause significant drowsiness. Avoid driving or operating machinery."
        ),
        // Antacids
        MedicationInfo(
            name: "Omeprazole",
            genericName: "Omeprazole",
            category: "Antacid/Proton Pump Inhibitor",
            standardDosages: ["20mg", "40mg"],
            usageInstructions: "Take before meals. Best taken in the morning.",
            commonSideEffects: ["Headache", "Nausea", "Diarrhea"],
            precautions: "Long-term use may increase risk of bone fractures."
        ),
        // Decongestants
        MedicationInfo(
            name: "Sudafed",
            genericName: "Pseudoephedrine",
            category: "Decongestant",
            standardDosages: ["30mg", "60mg"],
            usageInstructions: "Take every 4-6 hours. Do not exceed 240mg daily.",
            commonSideEffects: ["Nervousness", "Dizziness", "Sleep problems"],
            precautions: "May increase blood pressure. Not recommended for those with heart conditions."
        ),
        // Vitamins
        MedicationInfo(
            name: "Vitamin D3",
            genericName: "Cholecalciferol",
            category: "Vitamin Supplement",
            standardDosages: ["1000IU", "2000IU", "5000IU"],
            usageInstructions: "Take daily with food for better absorption.",
            commonSideEffects: ["Nausea", "Constipation", "Weakness"],
            precautions: "High doses may cause calcium buildup. Monitor blood levels regularly."
        )
    ]
}

class MedicationDatabase {
    static let shared = MedicationDatabase()
    private init() {}
    
    var medications: [MedicationInfo] = MedicationInfo.sampleMedications
    
    func searchMedications(query: String) -> [MedicationInfo] {
        guard !query.isEmpty else { return medications }
        
        return medications.filter { medication in
            medication.name.lowercased().contains(query.lowercased()) ||
            medication.genericName.lowercased().contains(query.lowercased())
        }
    }
    
    func getMedicationByName(_ name: String) -> MedicationInfo? {
        return medications.first { $0.name == name }
    }
    
    func addMedication(_ medication: MedicationInfo) {
        medications.append(medication)
    }
}