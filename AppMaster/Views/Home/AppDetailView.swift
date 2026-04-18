import SwiftUI

struct AppDetailView: View {
    let app: AppEntry
    @EnvironmentObject var appState: AppState
    @StateObject private var installer = IPAInstaller()
    @State private var showInstallAlert = false
    @State private var installError: String?
    @State private var showError = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Header
                    heroSection

                    // App Info
                    infoSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    // Description
                    descriptionSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Screenshots
                    if let screenshots = app.screenshotURLs, !screenshots.isEmpty {
                        screenshotsSection(screenshots)
                            .padding(.top, 20)
                    }

                    Spacer(minLength: 120)
                }
            }

            // Install Button
            VStack {
                Spacer()
                installButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(LocalizedStringKey("error_title"), isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(installError ?? "")
        }
    }

    var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: app.category.gradient + [Color(hex: "0A0A0F")],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 200)
                .ignoresSafeArea(edges: .top)

            HStack(spacing: 16) {
                AsyncImage(url: URL(string: app.iconURL ?? "")) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default:
                        ZStack {
                            LinearGradient(colors: app.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            Text(String(app.name.prefix(1)))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))

                VStack(alignment: .leading, spacing: 5) {
                    Text(app.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    if let dev = app.developer {
                        Text(dev)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    CategoryBadge(category: app.category)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    var infoSection: some View {
        HStack(spacing: 0) {
            infoItem(value: app.version, label: LocalizedStringKey("info_version"))
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            if let size = app.size {
                infoItem(value: formatSize(size), label: LocalizedStringKey("info_size"))
                Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            }
            infoItem(value: app.minOSVersion ?? "15.0+", label: LocalizedStringKey("info_ios"))
        }
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "1A1A28")))
    }

    func infoItem(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey("description_title"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Text(app.description.isEmpty ? NSLocalizedString("no_description", comment: "") : app.description)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(4)
        }
    }

    func screenshotsSection(_ urls: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("screenshots_title"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(urls, id: \.self) { url in
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 270)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            default:
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "1A1A28"))
                                    .frame(width: 150, height: 270)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    var installButton: some View {
        VStack(spacing: 8) {
            if installer.isInstalling {
                VStack(spacing: 8) {
                    ProgressView(value: installer.progress)
                        .tint(Color(hex: "7B2FBE"))
                    Text(installer.statusMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
            } else {
                Button {
                    if appState.certificate == nil {
                        installError = NSLocalizedString("error_no_certificate", comment: "")
                        showError = true
                    } else {
                        installApp()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: app.isInstalled ? "arrow.clockwise" : "square.and.arrow.down")
                        Text(LocalizedStringKey(app.isInstalled ? "button_reinstall" : "button_install"))
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(colors: [Color(hex: "7B2FBE"), Color(hex: "5B1A9A")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    func installApp() {
        installer.install(app: app, certificate: appState.certificate) { success, error in
            if success {
                appState.markInstalled(app)
                appState.showToast(NSLocalizedString("install_success", comment: ""))
            } else if let error = error {
                installError = error
                showError = true
            }
        }
    }

    func formatSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_000_000
        if mb > 1000 { return String(format: "%.1f GB", mb / 1000) }
        return String(format: "%.0f MB", mb)
    }
}

struct CategoryBadge: View {
    let category: AppCategory
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon).font(.system(size: 10))
            Text(category.localizedName).font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.15)))
    }
}
