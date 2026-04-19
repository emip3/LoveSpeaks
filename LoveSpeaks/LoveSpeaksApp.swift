import SwiftUI
 
@main
struct LoveSpeaksApp: App {
    @State private var showSplash = true
 
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: showSplash)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showSplash = false
                }
            }
        }
    }
}
 
