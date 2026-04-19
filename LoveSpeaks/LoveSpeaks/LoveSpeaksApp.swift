

import SwiftUI

@main
struct LoveSpeaksApp: App {
    var body: some Scene {
        WindowGroup {
            // Ya no necesitamos NavigationView aquí porque
            // ProfileView ya tiene su propio NavigationStack interno.
            ProfileView()
        }
    }
}
