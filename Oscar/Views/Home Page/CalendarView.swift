import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let scrollToDate: (Date, Int, ScrollViewProxy) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 15) {
                        HStack(spacing: 10) {
                            let calendar = Calendar.current
                            let currentDate = Date()
                            
                            ForEach(-15...15, id: \.self) { offset in
                                let date = calendar.date(byAdding: .day, value: offset, to: currentDate)!
                                let isToday = calendar.isDate(date, inSameDayAs: currentDate)
                                
                                VStack(spacing: 8) {
                                    Text(date.formatted(.dateTime.weekday()))
                                        .font(.system(size: 14))
                                        .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? Color("AccentColor") : .white)
                                    
                                    ZStack {
                                        Circle()
                                            .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? Color("AccentColor") : (isToday ? .white : .clear))
                                            .frame(width: 36, height: 36)
                                            .shadow(color: calendar.isDate(date, inSameDayAs: selectedDate) ? Color("AccentColor").opacity(0.5) : (isToday ? .white.opacity(0.3) : .clear), radius: 4)
                                        
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : (isToday ? Color("AccentColor") : .white))
                                    }
                                    .scaleEffect(calendar.isDate(date, inSameDayAs: selectedDate) ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedDate)
                                }
                                .frame(width: UIScreen.main.bounds.width / 7 - 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(calendar.isDate(date, inSameDayAs: selectedDate) ?
                                              Color.white :
                                                (isToday ? Color.white.opacity(0.15) : Color.white.opacity(0.1)))
                                        .shadow(color: calendar.isDate(date, inSameDayAs: selectedDate) ?
                                                Color.white.opacity(0.3) : .clear,
                                                radius: 8, x: 0, y: 4)
                                )
                                .cornerRadius(12)
                                .onTapGesture {
                                    scrollToDate(date, offset, proxy)
                                }
                                .id(offset)
                            }
                        }
                        .padding(.horizontal)
                        .onAppear {
                            scrollToDate(Date(), 0, proxy)
                        }
                    }
                }
                
                DateNavigationView(selectedDate: $selectedDate, scrollToDate: scrollToDate, proxy: proxy)
            }
        }
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}
