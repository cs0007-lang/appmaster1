import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var sources: [Source] = []
    @Published var installedApps: [AppEntry] = []
    @Published var certificate: Certificate?
    @Published var userProfile: UserProfile = UserProfile()
    @Published var pendingInstallURL: URL?
    @Published var showInstallSheet: Bool = false
    @Published var isLoading: Bool = false
    @Published var toastMessage: String?

    private let sourceService = SourceService()
    private let storageService = StorageService()

    init() {
        loadData()
    }

    func loadData() {
        self.sources = storageService.loadSources()
        self.installedApps = storageService.loadInstalledApps()
        self.certificate = storageService.loadCertificate()
        self.userProfile = storageService.loadUserProfile()
        // Load built-in source
        let builtIn = Source(
            id: "builtin",
            name: "AppMaster Official",
            url: "https://raw.githubusercontent.com/appmaster-dev/sources/main/sources.json",
            isBuiltIn: true
        )
        if !sources.contains(where: { $0.id == "builtin" }) {
            sources.insert(builtIn, at: 0)
        }
    }

    func handleIncomingURL(_ url: URL) {
        if url.pathExtension == "ipa" || url.scheme == "itms-services" {
            pendingInstallURL = url
            showInstallSheet = true
        }
    }

    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.toastMessage = nil
        }
    }

    func refreshAllSources() async {
        await MainActor.run { isLoading = true }
        for i in sources.indices {
            if let apps = await sourceService.fetchApps(from: sources[i].url) {
                await MainActor.run {
                    sources[i].apps = apps
                }
            }
        }
        await MainActor.run { isLoading = false }
        storageService.saveSources(sources)
    }

    func refreshSource(id: String) async {
        guard let idx = sources.firstIndex(where: { $0.id == id }) else { return }
        await MainActor.run { isLoading = true }
        if let apps = await sourceService.fetchApps(from: sources[idx].url) {
            await MainActor.run {
                sources[idx].apps = apps
            }
            storageService.saveSources(sources)
        }
        await MainActor.run { isLoading = false }
    }

    func addSource(url: String) async -> Bool {
        guard let apps = await sourceService.fetchApps(from: url) else { return false }
        let name = apps.first?.sourceTitle ?? url
        let newSource = Source(id: UUID().uuidString, name: name, url: url, apps: apps)
        await MainActor.run {
            sources.append(newSource)
            storageService.saveSources(sources)
        }
        return true
    }

    func deleteSource(id: String) {
        sources.removeAll { $0.id == id }
        storageService.saveSources(sources)
    }

    func allApps() -> [AppEntry] {
        sources.flatMap { $0.apps }
    }

    func appsForCategory(_ category: AppCategory) -> [AppEntry] {
        allApps().filter { $0.category == category }
    }

    func saveCertificate(_ cert: Certificate) {
        certificate = cert
        storageService.saveCertificate(cert)
    }

    func saveUserProfile(_ profile: UserProfile) {
        userProfile = profile
        storageService.saveUserProfile(profile)
    }

    func markInstalled(_ app: AppEntry) {
        var updated = app
        updated.isInstalled = true
        if !installedApps.contains(where: { $0.id == app.id }) {
            installedApps.append(updated)
        }
        storageService.saveInstalledApps(installedApps)
    }
}
