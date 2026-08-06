import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CampaignsListView()
                .tabItem { Label("Campañas", systemImage: "megaphone") }

            MailboxesListView()
                .tabItem { Label("Correos", systemImage: "envelope") }

            ReviewsView()
                .tabItem { Label("Reseñas", systemImage: "star.bubble") }

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSettings())
}
