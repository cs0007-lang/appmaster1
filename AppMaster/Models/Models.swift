import SwiftUI
import UIKit

// MARK: - AppCategory
enum AppCategory: String, Codable, CaseIterable, Identifiable {
    case games = "games"
    case social = "social"
    case design = "design"
    case entertainment = "entertainment"
    case tools = "tools"
    case productivity = "productivity"
    case unknown = "unknown"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .games: return NSLocalizedString("category_games", comment: "")
        case .social: return NSLocalizedString("category_social", comment: "")
        case .design: return NSLocalizedString("category_design", comment: "")
        case .entertainment: return NSLocalizedString("category_entertainment", comment: "")
        case .tools: return NSLocalizedString("category_tools", comment: "")
        case .productivity: return NSLocalizedString("category_productivity", comment: "")
        case .unknown: return NSLocalizedString("category_other", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .games: return "gamecontroller.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .design: return "paintbrush.fill"
        case .entertainment: return "film.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .productivity: return "briefcase.fill"
        case .unknown: return "square.grid.2x2.fill"
        }
    }

    var gradient: [Color] {
        switch self {
        case .games: return [Color(hex: "7B2FBE"), Color(hex: "4A1580")]
        case .social: return [Color(hex: "1DA1F2"), Color(hex: "0D47A1")]
        case .design: return [Color(hex: "FF6B6B"), Color(hex: "C0392B")]
        case .entertainment: return [Color(hex: "E50914"), Color(hex: "7B0000")]
        case .tools: return [Color(hex: "F39C12"), Color(hex: "B7770D")]
        case .productivity: return [Color(hex: "27AE60"), Color(hex: "1A6B3C")]
        case .unknown: return [Color(hex: "636E72"), Color(hex: "2D3436")]
        }
    }

    // Smart categorization
    static func classify(name: String, description: String = "", bundleID: String = "") -> AppCategory {
        let combined = "\(name) \(description) \(bundleID)".lowercased()

        let gameKeywords = ["game", "لعبة", "ألعاب", "arcade", "puzzle", "rpg", "shooter", "racing", "sport", "minecraft", "fortnite", "pubg", "clash", "angry", "candy", "words"]
        let socialKeywords = ["social", "تواصل", "instagram", "facebook", "twitter", "telegram", "whatsapp", "tiktok", "snapchat", "discord", "messenger", "chat", "message", "تيليجرام", "واتساب"]
        let designKeywords = ["design", "تصميم", "photo", "edit", "creative", "art", "draw", "paint", "canva", "figma", "photoshop", "lightroom", "procreate", "illustrat", "vector", "sketch"]
        let entertainmentKeywords = ["movie", "film", "series", "فيلم", "مسلسل", "افلام", "cinemana", "netflix", "youtube", "video", "stream", "watch", "tv", "show", "anime"]
        let productivityKeywords = ["productivity", "office", "document", "note", "task", "calendar", "email", "work", "manage", "organiz"]

        for keyword in gameKeywords { if combined.contains(keyword) { return .games } }
        for keyword in socialKeywords { if combined.contains(keyword) { return .social } }
        for keyword in designKeywords { if combined.contains(keyword) { return .design } }
        for keyword in entertainmentKeywords { if combined.contains(keyword) { return .entertainment } }
        for keyword in productivityKeywords { if combined.contains(keyword) { return .productivity } }

        return .tools
    }
}

// MARK: - AppEntry
struct AppEntry: Identifiable, Codable {
    var id: String
    var name: String
    var bundleID: String
    var version: String
    var description: String
    var iconURL: String?
    var downloadURL: String
    var size: Int64?
    var developer: String?
    var screenshotURLs: [String]?
    var category: AppCategory
    var isInstalled: Bool = false
    var sourceTitle: String?
    var minOSVersion: String?
    var date: String?

    enum CodingKeys: String, CodingKey {
        case id, name, bundleID, version, description, iconURL
        case downloadURL, size, developer, screenshotURLs, category
        case isInstalled, sourceTitle, minOSVersion, date
    }

    init(id: String = UUID().uuidString,
         name: String,
         bundleID: String = "",
         version: String = "1.0",
         description: String = "",
         iconURL: String? = nil,
         downloadURL: String,
         size: Int64? = nil,
         developer: String? = nil,
         screenshotURLs: [String]? = nil,
         category: AppCategory? = nil,
         sourceTitle: String? = nil,
         minOSVersion: String? = nil,
         date: String? = nil) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.version = version
        self.description = description
        self.iconURL = iconURL
        self.downloadURL = downloadURL
        self.size = size
        self.developer = developer
        self.screenshotURLs = screenshotURLs
        self.category = category ?? AppCategory.classify(name: name, description: description, bundleID: bundleID)
        self.sourceTitle = sourceTitle
        self.minOSVersion = minOSVersion
        self.date = date
    }
}

// MARK: - Source
struct Source: Identifiable, Codable {
    var id: String
    var name: String
    var url: String
    var apps: [AppEntry] = []
    var isBuiltIn: Bool = false
    var iconURL: String?
    var description: String?

    enum CodingKeys: String, CodingKey {
        case id, name, url, apps, isBuiltIn, iconURL, description
    }
}

// MARK: - Certificate
struct Certificate: Codable {
    var teamID: String
    var teamName: String
    var bundleID: String
    var expiryDate: Date?
    var p12Data: Data?
    var mobileProvisionData: Data?
    var udid: String?

    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }

    var formattedExpiry: String {
        guard let expiry = expiryDate else { return NSLocalizedString("unknown", comment: "") }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expiry)
    }
}

// MARK: - UserProfile
struct UserProfile: Codable {
    var displayName: String = ""
    var avatarData: Data?
    var udid: String = ""

    init() {
        self.udid = Self.fetchUDID()
    }

    static func fetchUDID() -> String {
        // Returns device identifier (proxy for UDID in modern iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }
}

// MARK: - InstallTask
struct InstallTask: Identifiable {
    var id: String = UUID().uuidString
    var app: AppEntry
    var progress: Double = 0
    var status: InstallStatus = .pending

    enum InstallStatus {
        case pending, downloading, signing, installing, completed, failed(String)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
