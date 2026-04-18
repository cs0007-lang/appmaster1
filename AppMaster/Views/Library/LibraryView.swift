import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var installer = IPAInstaller()
    @State private var showFilePicker = false
    @State private var showURLInput = false
    @State private var installURL = ""
    @State private var showURLSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(LocalizedStringKey("tab_library"))
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                        Spacer()
                        Menu {
                            Button {
                                showFilePicker = true
                            } label: {
                                Label(LocalizedStringKey("import_ipa_file"), systemImage: "doc.fill")
                            }
                            Button {
                                showURLSheet = true
                            } label: {
                                Label(LocalizedStringKey("import_ipa_url"), systemImage: "link")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: "7B2FBE"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    if installer.isInstalling {
                        installProgressView
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    if appState.installedApps.isEmpty {
                        emptyView
                    } else {
                        installedList
                    }
                }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.init(filenameExtension: "ipa") ?? .data]) { result in
                if case .success(let url) = result {
                    installer.installFromURL(url, certificate: appState.certificate) { success, error in
                        if success { appState.showToast(NSLocalizedString("install_started", comment: "")) }
                    }
                }
            }
            .sheet(isPresented: $showURLSheet) {
                InstallURLSheet(isPresented: $showURLSheet, installer: installer)
            }
        }
    }

    var installProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(installer.statusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(installer.progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "7B2FBE"))
            }
            ProgressView(value: installer.progress)
                .tint(Color(hex: "7B2FBE"))
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "1A1A28")))
    }

    var installedList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(appState.installedApps) { app in
                    NavigationLink(destination: AppDetailView(app: app)) {
                        AppListRow(app: app)
                    }
                    .buttonStyle(.plain)
                    Divider().background(Color.white.opacity(0.06))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "7B2FBE").opacity(0.4))
            Text(LocalizedStringKey("no_installed_apps"))
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
    }
}

// MARK: - Install from URL View (sheet)
struct InstallFromURLView: View {
    let url: URL
    @EnvironmentObject var appState: AppState
    @StateObject private var installer = IPAInstaller()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "arrow.down.app")
                        .font(.system(size: 60))
                        .foregroundStyle(Color(hex: "7B2FBE"))

                    Text(LocalizedStringKey("install_from_url"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text(url.lastPathComponent)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))

                    if installer.isInstalling {
                        ProgressView(value: installer.progress)
                            .tint(Color(hex: "7B2FBE"))
                        Text(installer.statusMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        Button {
                            installer.installFromURL(url, certificate: appState.certificate) { success, _ in
                                if success { dismiss() }
                            }
                        } label: {
                            Text(LocalizedStringKey("button_install"))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(LinearGradient(colors: [Color(hex: "7B2FBE"), Color(hex: "5B1A9A")],
                                                           startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(24)
            }
            .navigationTitle(LocalizedStringKey("install_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) { dismiss() }
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Install URL Sheet
struct InstallURLSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var installer: IPAInstaller
    @EnvironmentObject var appState: AppState
    @State private var urlText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color(hex: "7B2FBE"))
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("ipa_url_label"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))

                        TextField("", text: $urlText,
                                  prompt: Text("https://example.com/app.ipa")
                                      .foregroundStyle(.white.opacity(0.25)))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1A28")))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle(LocalizedStringKey("import_ipa_url"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) { isPresented = false }
                        .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("install")) {
                        if let url = URL(string: urlText) {
                            installer.installFromURL(url, certificate: appState.certificate) { success, _ in
                                isPresented = false
                            }
                        }
                    }
                    .foregroundStyle(Color(hex: "7B2FBE"))
                    .disabled(urlText.isEmpty)
                }
            }
        }
    }
}
