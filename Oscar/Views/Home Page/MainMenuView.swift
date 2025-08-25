import SwiftUI

struct MainMenuView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home, medications, calendar, reports
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(Tab.home)
            
            MedicationsView()
                .tabItem {
                    Image(systemName: "pills.fill")
                    Text("Medications")
                }
                .tag(Tab.medications)
            
            ReportView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(Tab.calendar)
            
            ReportView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }
                .tag(Tab.reports)
        }
        .accentColor(Color("AccentColor"))
    }
}

#Preview {
    MainMenuView()
} 
