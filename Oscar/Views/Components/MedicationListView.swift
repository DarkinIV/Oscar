import SwiftUI

struct MedicationListView: View {
    let medications: [MedicationSchedule]
    let selectedDate: Date
    @State private var showingQuickAdd = false
    @State private var searchText = ""
    @State private var selectedMedication: MedicationInfo?
    @State private var newMedicationTime = Date()
    @State private var newMedicationNote = ""
    @State private var selectedDosage = ""
    @ObservedObject var medicationManager: MedicationScheduleManager
    private let medicationDB = MedicationDatabase.shared
    
    private var filteredMedications: [MedicationInfo] {
        medicationDB.searchMedications(query: searchText)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Today's Medications")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                if medications.isEmpty {
                    VStack {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 10)
                        Text("No medications scheduled for this day")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                } else {
                    let sortedMedications = medications.sorted { $0.time < $1.time }
                    ForEach(sortedMedications) { medication in
                        MedicationCard(medication: medication)
                    }
                }
                
                Button(action: { showingQuickAdd = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Medication")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("SecondColor"))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
        }
        .sheet(isPresented: $showingQuickAdd) {
            NavigationView {
                VStack(spacing: 0) {
                    // Search Bar with Category Filter
                    VStack(spacing: 12) {
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        if selectedMedication == nil {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(["All", "Antibiotics", "Pain Relievers", "Antihistamines", "Antacids", "Decongestants", "Vitamins"], id: \.self) { category in
                                        Text(category)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color("AccentColor").opacity(0.1))
                                            .cornerRadius(20)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color("AccentColor").opacity(0.1))
                    
                    if let selectedMed = selectedMedication {
                        Form {
                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(selectedMed.name)
                                                .font(.headline)
                                            Text(selectedMed.genericName)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Button(action: { selectedMedication = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .imageScale(.large)
                                        }
                                    }
                                    Text(selectedMed.category)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color("AccentColor").opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            Section(header: Text("Dosage").textCase(.uppercase)) {
                                Picker("Select Dosage", selection: $selectedDosage) {
                                    Text("Select a dosage").tag("")
                                    ForEach(selectedMed.standardDosages, id: \.self) { dosage in
                                        Text(dosage).tag(dosage)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Section(header: Text("Schedule").textCase(.uppercase)) {
                                DatePicker("Time", selection: $newMedicationTime, displayedComponents: .hourAndMinute)
                                TextField("Add notes (optional)", text: $newMedicationNote)
                            }
                            
                            Section {
                                VStack(alignment: .leading, spacing: 12) {
                                    InfoRow(title: "Instructions", text: selectedMed.usageInstructions)
                                    InfoRow(title: "Side Effects", items: selectedMed.commonSideEffects)
                                    if !selectedMed.precautions.isEmpty {
                                        InfoRow(title: "Precautions", text: selectedMed.precautions, isWarning: true)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    } else {
                        List(filteredMedications) { medication in
                            Button(action: {
                                withAnimation {
                                    selectedMedication = medication
                                    selectedDosage = medication.standardDosages.first ?? ""
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(medication.name)
                                            .font(.headline)
                                        Text(medication.genericName)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .navigationTitle(selectedMedication == nil ? "Select Medication" : "Add Medication")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingQuickAdd = false
                        selectedMedication = nil
                        searchText = ""
                        selectedDosage = ""
                    },
                    trailing: Group {
                        if selectedMedication != nil {
                            Button("Add") {
                                if let selectedMed = selectedMedication {
                                    let newMedication = MedicationSchedule(
                                        name: selectedMed.name,
                                        time: newMedicationTime,
                                        note: newMedicationNote,
                                        dosage: selectedDosage
                                    )
                                    medicationManager.addMedication(newMedication, forDate: selectedDate)
                                    showingQuickAdd = false
                                    selectedMedication = nil
                                    searchText = ""
                                    newMedicationTime = Date()
                                    newMedicationNote = ""
                                    selectedDosage = ""
                                }
                            }
                            .disabled(selectedDosage.isEmpty)
                        }
                    }
                )
            }
        }
    }
}
