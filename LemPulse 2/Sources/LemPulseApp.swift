import SwiftUI

@main
struct LemPulseApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
        }
    }
}
