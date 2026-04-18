import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCertSheet = false
    @State private var showProfileEdit = false
    @State private var selectedLanguage = Locale.current.languageCode ?? "ar"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile Header
                        profileHeader
                            .padding(.top, 60)

                        // Device Info Card
                        udidCard

                        // Certificate Card
                        certificateCard

                        // App Settings
                        appSettingsCard

                        // About / Channel Card
                        aboutCard

                        // Developer Card
                        developerCard

                        // Footer
                        footerText

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .sheet(isPresented: $showCertSheet) {
            CertificateSetupView(isPresented: $showCertSheet)
        }
        .sheet(isPresented: $showProfileEdit) {
            ProfileEditView(isPresented: $showProfileEdit)
        }
    }

    // MARK: - Profile Header
    var profileHeader: some View {
        VStack(spacing: 14) {
            Button {
                showProfileEdit = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let data = appState.userProfile.avatarData,
                           let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                LinearGradient(colors: [Color(hex: "7B2FBE"), Color(hex: "4A1580")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                Text(appState.userProfile.displayName.isEmpty ? "?" : String(appState.userProfile.displayName.prefix(1)))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "7B2FBE"), lineWidth: 2))

                    // Edit badge
                    ZStack {
                        Circle().fill(Color(hex: "7B2FBE")).frame(width: 26, height: 26)
                        Image(systemName: "pencil").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }

            VStack(spacing: 4) {
                Text(appState.userProfile.displayName.isEmpty ? NSLocalizedString("tap_to_set_name", comment: "") : appState.userProfile.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(appState.userProfile.displayName.isEmpty ? .white.opacity(0.4) : .white)

                Text(LocalizedStringKey("settings_title"))
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - UDID Card
    var udidCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(LocalizedStringKey("udid_title"), systemImage: "iphone")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            HStack {
                Text(appState.userProfile.udid)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                Spacer()
                Button {
                    UIPasteboard.general.string = appState.userProfile.udid
                    appState.showToast(NSLocalizedString("udid_copied", comment: ""))
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(Color(hex: "7B2FBE"))
                }
            }
        }
        .padding(16)
        .background(settingsCardBackground)
    }

    // MARK: - Certificate Card
    var certificateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(LocalizedStringKey("certificate_title"), systemImage: "lock.shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            if let cert = appState.certificate {
                VStack(spacing: 10) {
                    certRow(label: LocalizedStringKey("cert_team_name"), value: cert.teamName)
                    certRow(label: LocalizedStringKey("cert_team_id"), value: cert.teamID)
                    certRow(label: LocalizedStringKey("cert_bundle_id"), value: cert.bundleID)
                    certRow(label: LocalizedStringKey("cert_expiry"), value: cert.formattedExpiry)

                    if cert.isExpired {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(LocalizedStringKey("cert_expired"))
                        }
                        .foregroundStyle(.red)
                        .font(.system(size: 12, weight: .medium))
                    }
                }

                Button {
                    showCertSheet = true
                } label: {
                    Text(LocalizedStringKey("replace_certificate"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "7B2FBE"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "7B2FBE").opacity(0.12)))
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: "7B2FBE").opacity(0.5))
                    Text(LocalizedStringKey("no_certificate"))
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                    Button {
                        showCertSheet = true
                    } label: {
                        Text(LocalizedStringKey("add_certificate"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(LinearGradient(colors: [Color(hex: "7B2FBE"), Color(hex: "5B1A9A")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(settingsCardBackground)
    }

    func certRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
        }
    }

    // MARK: - App Settings
    var appSettingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(LocalizedStringKey("app_settings"), systemImage: "gearshape.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            // Language
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(Color(hex: "7B2FBE"))
                Text(LocalizedStringKey("language"))
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Picker("", selection: $selectedLanguage) {
                    Text("العربية").tag("ar")
                    Text("English").tag("en")
                    Text("Русский").tag("ru")
                    Text("中文").tag("zh")
                    Text("Deutsch").tag("de")
                    Text("فارسی").tag("fa")
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "7B2FBE"))
            }
            .padding(.vertical, 4)
        }
        .padding(16)
        .background(settingsCardBackground)
    }

    // MARK: - About Card (Channel)
    var aboutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(LocalizedStringKey("about_section"), systemImage: "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            // Channel Row
            Link(destination: URL(string: "https://t.me/Appmasster")!) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "7B2FBE"), Color(hex: "4A1580")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        // Placeholder for channel image
                        Text("A")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("AppMaster")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text("t.me/Appmasster")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(Color(hex: "7B2FBE"))
                        .font(.system(size: 14))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(settingsCardBackground)
    }

    // MARK: - Developer Card
    var developerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(LocalizedStringKey("developer_section"), systemImage: "hammer.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            // Developer Row
            Link(destination: URL(string: "https://t.me/auuua1")!) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "1DA1F2"), Color(hex: "0D47A1")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        // Placeholder for developer image
                        Text("ع")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("عباس عقيل")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text("t.me/auuua1")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(Color(hex: "1DA1F2"))
                        .font(.system(size: 14))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(settingsCardBackground)
    }

    // MARK: - Footer
    var footerText: some View {
        VStack(spacing: 6) {
            Text("AppMaster v1.0.0")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.25))
            Text("هذا التطبيق مُلك لقناة AppMaster")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    var settingsCardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(hex: "1A1A28"))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Profile Edit View
struct ProfileEditView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarData: Data?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                VStack(spacing: 24) {
                    // Avatar picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let data = avatarData, let ui = UIImage(data: data) {
                                    Image(uiImage: ui).resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    ZStack {
                                        LinearGradient(colors: [Color(hex: "7B2FBE"), Color(hex: "4A1580")],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                                        Text(name.isEmpty ? "?" : String(name.prefix(1)))
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(hex: "7B2FBE"), lineWidth: 2))

                            ZStack {
                                Circle().fill(Color(hex: "7B2FBE")).frame(width: 30, height: 30)
                                Image(systemName: "camera.fill").font(.system(size: 13)).foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.top, 20)

                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("display_name"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        TextField("", text: $name,
                                  prompt: Text(LocalizedStringKey("name_placeholder")).foregroundStyle(.white.opacity(0.3)))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1A28")))
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle(LocalizedStringKey("edit_profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) { isPresented = false }
                        .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("save")) {
                        var profile = appState.userProfile
                        profile.displayName = name
                        if let data = avatarData { profile.avatarData = data }
                        appState.saveUserProfile(profile)
                        isPresented = false
                    }
                    .foregroundStyle(Color(hex: "7B2FBE"))
                }
            }
            .onAppear {
                name = appState.userProfile.displayName
                avatarData = appState.userProfile.avatarData
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        avatarData = data
                    }
                }
            }
        }
    }
}

// MARK: - Certificate Setup View
struct CertificateSetupView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var teamID = ""
    @State private var teamName = ""
    @State private var bundleID = ""
    @State private var showP12Picker = false
    @State private var showProvisionPicker = false
    @State private var p12Data: Data?
    @State private var provisionData: Data?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Info
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color(hex: "7B2FBE"))
                            Text(LocalizedStringKey("cert_info"))
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "7B2FBE").opacity(0.1)))

                        // Fields
                        certField(title: LocalizedStringKey("cert_team_name"), text: $teamName, placeholder: "My Team")
                        certField(title: LocalizedStringKey("cert_team_id"), text: $teamID, placeholder: "ABC123XYZ")
                        certField(title: LocalizedStringKey("cert_bundle_id"), text: $bundleID, placeholder: "com.example.*")

                        // P12 Upload
                        filePickerRow(
                            title: LocalizedStringKey("p12_file"),
                            icon: "key.fill",
                            hasFile: p12Data != nil,
                            action: { showP12Picker = true }
                        )

                        // Provision Upload
                        filePickerRow(
                            title: LocalizedStringKey("provision_file"),
                            icon: "doc.badge.gearshape.fill",
                            hasFile: provisionData != nil,
                            action: { showProvisionPicker = true }
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle(LocalizedStringKey("add_certificate"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) { isPresented = false }
                        .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("save")) {
                        saveCertificate()
                    }
                    .foregroundStyle(Color(hex: "7B2FBE"))
                    .disabled(teamID.isEmpty || teamName.isEmpty || bundleID.isEmpty)
                }
            }
            .fileImporter(isPresented: $showP12Picker, allowedContentTypes: [.init(filenameExtension: "p12") ?? .data]) { result in
                if case .success(let url) = result {
                    p12Data = try? Data(contentsOf: url)
                }
            }
            .fileImporter(isPresented: $showProvisionPicker, allowedContentTypes: [.init(filenameExtension: "mobileprovision") ?? .data]) { result in
                if case .success(let url) = result {
                    provisionData = try? Data(contentsOf: url)
                }
            }
        }
    }

    func certField(title: LocalizedStringKey, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.6))
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.25)))
                .foregroundStyle(.white)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1A28")))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }

    func filePickerRow(title: LocalizedStringKey, icon: String, hasFile: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(hasFile ? Color(hex: "27AE60") : Color(hex: "7B2FBE"))
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Text(LocalizedStringKey(hasFile ? "file_loaded" : "choose_file"))
                    .font(.system(size: 13))
                    .foregroundStyle(hasFile ? Color(hex: "27AE60") : .white.opacity(0.4))
                Image(systemName: hasFile ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(hasFile ? Color(hex: "27AE60") : .white.opacity(0.3))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "1A1A28")))
        }
        .buttonStyle(.plain)
    }

    func saveCertificate() {
        let cert = Certificate(
            teamID: teamID,
            teamName: teamName,
            bundleID: bundleID,
            expiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            p12Data: p12Data,
            mobileProvisionData: provisionData
        )
        appState.saveCertificate(cert)
        isPresented = false
        appState.showToast(NSLocalizedString("certificate_saved", comment: ""))
    }
}
