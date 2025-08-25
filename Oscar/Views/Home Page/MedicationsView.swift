import SwiftUI

struct MedicationsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Medications")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            // Placeholder for medication list
            List {
                ForEach(0..<5) { index in
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundColor(Color("AccentColor"))
                        VStack(alignment: .leading) {
                            Text("Medication Name \(index + 1)")
                                .font(.headline)
                            Text("Dosage and details here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .frame(maxHeight: 350)
            
            Spacer()
        }
        .padding()
        .background(Color("LightColor").opacity(0.08))
    }
}

#Preview {
    MedicationsView()
} 