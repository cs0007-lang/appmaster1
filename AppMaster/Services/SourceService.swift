import Foundation

class SourceService {

    // AltStore / Feather compatible JSON format
    struct AltSourceResponse: Codable {
        var name: String?
        var identifier: String?
        var apps: [AltApp]?
        var news: [AltNews]?
    }

    struct AltApp: Codable {
        var name: String?
        var bundleIdentifier: String?
        var version: String?
        var versionDescription: String?
        var localizedDescription: String?
        var iconURL: String?
        var downloadURL: String?
        var size: Int64?
        var developerName: String?
        var screenshotURLs: [String]?
        var minimumOSVersion: String?
        var versionDate: String?
        var category: String?
    }

    struct AltNews: Codable {
        var title: String?
        var identifier: String?
    }

    // AppMaster native JSON format
    struct AppMasterSourceResponse: Codable {
        var name: String?
        var apps: [AppMasterApp]?
    }

    struct AppMasterApp: Codable {
        var id: String?
        var name: String?
        var bundleID: String?
        var version: String?
        var description: String?
        var iconURL: String?
        var downloadURL: String?
        var category: String?
        var developer: String?
        var size: Int64?
    }

    func fetchApps(from urlString: String) async -> [AppEntry]? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // Try AppMaster native format first
            if let apps = parseAppMasterFormat(data: data, sourceTitle: urlString) {
                return apps
            }
            // Fallback to AltStore format
            if let apps = parseAltStoreFormat(data: data, sourceTitle: urlString) {
                return apps
            }
            return nil
        } catch {
            print("Source fetch error: \(error)")
            return nil
        }
    }

    private func parseAppMasterFormat(data: Data, sourceTitle: String) -> [AppEntry]? {
        guard let response = try? JSONDecoder().decode(AppMasterSourceResponse.self, from: data),
              let rawApps = response.apps, !rawApps.isEmpty else { return nil }

        return rawApps.compactMap { raw in
            guard let name = raw.name, let downloadURL = raw.downloadURL else { return nil }
            return AppEntry(
                id: raw.id ?? UUID().uuidString,
                name: name,
                bundleID: raw.bundleID ?? "",
                version: raw.version ?? "1.0",
                description: raw.description ?? "",
                iconURL: raw.iconURL,
                downloadURL: downloadURL,
                size: raw.size,
                developer: raw.developer,
                category: AppCategory(rawValue: raw.category ?? "") ?? AppCategory.classify(name: name, description: raw.description ?? "", bundleID: raw.bundleID ?? ""),
                sourceTitle: response.name ?? sourceTitle
            )
        }
    }

    private func parseAltStoreFormat(data: Data, sourceTitle: String) -> [AppEntry]? {
        guard let response = try? JSONDecoder().decode(AltSourceResponse.self, from: data),
              let rawApps = response.apps, !rawApps.isEmpty else { return nil }

        return rawApps.compactMap { raw in
            guard let name = raw.name, let downloadURL = raw.downloadURL else { return nil }
            let desc = raw.localizedDescription ?? raw.versionDescription ?? ""
            let bundleID = raw.bundleIdentifier ?? ""
            return AppEntry(
                id: UUID().uuidString,
                name: name,
                bundleID: bundleID,
                version: raw.version ?? "1.0",
                description: desc,
                iconURL: raw.iconURL,
                downloadURL: downloadURL,
                size: raw.size,
                developer: raw.developerName,
                screenshotURLs: raw.screenshotURLs,
                category: AppCategory.classify(name: name, description: desc, bundleID: bundleID),
                sourceTitle: response.name ?? sourceTitle,
                minOSVersion: raw.minimumOSVersion,
                date: raw.versionDate
            )
        }
    }
}
