import Foundation
import UIKit

class IPAInstaller: ObservableObject {
    @Published var progress: Double = 0
    @Published var statusMessage: String = ""
    @Published var isInstalling: Bool = false

    static let cinemanaKeyword = "cinemana"

    /// Installs or delivers an IPA: opens enterprise/OTA links, otherwise downloads and presents the share sheet
    /// (AltStore, Files, AirDrop, etc.). True on-device re-signing is not available inside the client app.
    func install(app: AppEntry, certificate: Certificate?, completion: @escaping (Bool, String?) -> Void) {
        guard certificate != nil else {
            completion(false, NSLocalizedString("error_no_certificate", comment: ""))
            return
        }

        guard let remote = URL(string: app.downloadURL) else {
            completion(false, InstallError.invalidURL.errorDescription)
            return
        }

        isInstalling = true
        progress = 0
        statusMessage = NSLocalizedString("status_downloading", comment: "")

        Task {
            do {
                if remote.scheme == "itms-services" {
                    await MainActor.run {
                        UIApplication.shared.open(remote)
                        self.finishInstallProgress()
                        completion(true, nil)
                    }
                    return
                }

                let localURL = try await downloadIPAToTemporaryFile(from: app.downloadURL)
                await MainActor.run {
                    self.progress = 1.0
                    self.finishInstallProgress()
                    Self.presentShare(for: localURL) { success, err in
                        completion(success, err)
                    }
                }
            } catch InstallError.directInstall {
                await MainActor.run {
                    self.finishInstallProgress()
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    self.finishInstallProgress()
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    func installFromURL(_ url: URL, certificate: Certificate?, completion: @escaping (Bool, String?) -> Void) {
        if certificate == nil && url.scheme != "itms-services" {
            completion(false, NSLocalizedString("error_no_certificate", comment: ""))
            return
        }

        isInstalling = true
        progress = 0
        statusMessage = NSLocalizedString("status_preparing", comment: "")

        if url.scheme == "itms-services" {
            UIApplication.shared.open(url)
            finishInstallProgress()
            completion(true, nil)
            return
        }

        if url.isFileURL {
            Task {
                let access = url.startAccessingSecurityScopedResource()
                defer {
                    if access { url.stopAccessingSecurityScopedResource() }
                }
                do {
                    let dest = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + ".ipa")
                    if FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.removeItem(at: dest)
                    }
                    try FileManager.default.copyItem(at: url, to: dest)
                    await MainActor.run {
                        self.progress = 1.0
                        self.finishInstallProgress()
                        Self.presentShare(for: dest) { success, err in
                            completion(success, err)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.finishInstallProgress()
                        completion(false, error.localizedDescription)
                    }
                }
            }
            return
        }

        if url.scheme == "https" || url.scheme == "http" {
            Task {
                do {
                    let localURL = try await downloadIPAToTemporaryFile(from: url.absoluteString)
                    await MainActor.run {
                        self.progress = 1.0
                        self.finishInstallProgress()
                        Self.presentShare(for: localURL) { success, err in
                            completion(success, err)
                        }
                    }
                } catch InstallError.directInstall {
                    await MainActor.run {
                        self.finishInstallProgress()
                        completion(true, nil)
                    }
                } catch {
                    await MainActor.run {
                        self.finishInstallProgress()
                        completion(false, error.localizedDescription)
                    }
                }
            }
            return
        }

        finishInstallProgress()
        completion(false, InstallError.unsupportedURL.errorDescription)
    }

    private func finishInstallProgress() {
        isInstalling = false
        statusMessage = ""
    }

    private func downloadIPAToTemporaryFile(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw InstallError.invalidURL
        }

        if url.scheme == "itms-services" {
            await MainActor.run { UIApplication.shared.open(url) }
            throw InstallError.directInstall
        }

        let (tempURL, response) = try await URLSession.shared.download(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            try? FileManager.default.removeItem(at: tempURL)
            throw InstallError.downloadFailed
        }

        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest
    }

    private static func presentShare(for fileURL: URL, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
                  let root = scene.keyWindow?.rootViewController else {
                completion(false, NSLocalizedString("error_install_failed", comment: ""))
                return
            }
            let presenter = topViewController(from: root)
            let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            activity.completionWithItemsHandler = { _, _, _, _ in
                completion(true, nil)
            }
            if let pop = activity.popoverPresentationController {
                pop.sourceView = presenter.view
                pop.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
            presenter.present(activity, animated: true)
        }
    }

    private static func topViewController(from vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        if let presented = vc.presentedViewController {
            return topViewController(from: presented)
        }
        return vc
    }
}

enum InstallError: LocalizedError {
    case invalidURL
    case downloadFailed
    case signingFailed
    case installFailed
    case directInstall
    case noCertificate
    case unsupportedURL

    var errorDescription: String? {
        switch self {
        case .invalidURL: return NSLocalizedString("error_invalid_url", comment: "")
        case .downloadFailed: return NSLocalizedString("error_download_failed", comment: "")
        case .signingFailed: return NSLocalizedString("error_signing_failed", comment: "")
        case .installFailed: return NSLocalizedString("error_install_failed", comment: "")
        case .directInstall: return "Direct install"
        case .noCertificate: return NSLocalizedString("error_no_certificate", comment: "")
        case .unsupportedURL: return NSLocalizedString("error_unsupported_url", comment: "")
        }
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow } ?? windows.first
    }
}
