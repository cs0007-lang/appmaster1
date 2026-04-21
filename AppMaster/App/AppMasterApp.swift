import SwiftUI

@main
struct AppMasterApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("app_interface_language") private var appLanguage: String = "ar"

    private var appLocale: Locale {
        if appLanguage.isEmpty { return Locale.current }
        return Locale(identifier: appLanguage)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(\.locale, appLocale)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    appState.handleIncomingURL(url)
                }
        }
    }
}
