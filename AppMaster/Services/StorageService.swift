import Foundation

class StorageService {
    private let defaults = UserDefaults.standard

    // MARK: - Sources
    func saveSources(_ sources: [Source]) {
        if let data = try? JSONEncoder().encode(sources) {
            defaults.set(data, forKey: "saved_sources")
        }
    }

    func loadSources() -> [Source] {
        guard let data = defaults.data(forKey: "saved_sources"),
              let sources = try? JSONDecoder().decode([Source].self, from: data) else {
            return []
        }
        return sources
    }

    // MARK: - Installed Apps
    func saveInstalledApps(_ apps: [AppEntry]) {
        if let data = try? JSONEncoder().encode(apps) {
            defaults.set(data, forKey: "installed_apps")
        }
    }

    func loadInstalledApps() -> [AppEntry] {
        guard let data = defaults.data(forKey: "installed_apps"),
              let apps = try? JSONDecoder().decode([AppEntry].self, from: data) else {
            return []
        }
        return apps
    }

    // MARK: - Certificate
    func saveCertificate(_ cert: Certificate) {
        if let data = try? JSONEncoder().encode(cert) {
            defaults.set(data, forKey: "certificate")
        }
    }

    func loadCertificate() -> Certificate? {
        guard let data = defaults.data(forKey: "certificate"),
              let cert = try? JSONDecoder().decode(Certificate.self, from: data) else {
            return nil
        }
        return cert
    }

    // MARK: - User Profile
    func saveUserProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: "user_profile")
        }
    }

    func loadUserProfile() -> UserProfile {
        guard let data = defaults.data(forKey: "user_profile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }
}
