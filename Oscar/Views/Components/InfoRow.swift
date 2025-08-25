import SwiftUI

struct InfoRow: View {
    let title: String
    var text: String? = nil
    var items: [String]? = nil
    var isWarning: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let text = text {
                Text(text)
                    .font(.body)
                    .foregroundColor(isWarning ? .red : .primary)
            }
            
            if let items = items {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 4, height: 4)
                        Text(item)
                            .font(.body)
                    }
                }
            }
        }
    }
}