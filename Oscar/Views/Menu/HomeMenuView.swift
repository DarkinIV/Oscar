import SwiftUI

struct HomeMenuView: View {
    let selectedChildId: String?
    @Binding var selectedDate: Date
    let scrollToDate: (Date, Int, ScrollViewProxy) -> Void
    var body: some View {
        if let childId = selectedChildId {
            CalendarView(selectedDate: $selectedDate, scrollToDate: scrollToDate)
            //ChildMedicationListView(childId: childId, selectedDate: selectedDate)
        } else {
            Spacer()
            VStack(spacing: 20) {
                Image("Talking Right")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                Text("No children linked to your account yet")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            Spacer()
        }
    }
} 
