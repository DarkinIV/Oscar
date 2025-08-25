import SwiftUI

struct ReportView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Reports")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Example report cards
                ForEach(0..<3) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report Title \(index + 1)")
                            .font(.headline)
                        Text("Summary or key metrics for this report go here. You can add charts, stats, or other visuals.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
                }
                Spacer()
            }
            .padding()
            .background(Color("LightColor").opacity(0.08))
        }
    }
}

#Preview {
    ReportView()
} 