import SwiftUI

struct SourcesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddSource = false
    @State private var sourceURL = ""
    @State private var isAdding = false
    @State private var addError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey("tab_sources"))
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Button {
                            showAddSource = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: "7B2FBE"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    if appState.sources.isEmpty {
                        emptyView
                    } else {
                        sourcesList
                    }
                }
            }
            .sheet(isPresented: $showAddSource) {
                AddSourceSheet(isPresented: $showAddSource)
            }
        }
    }

    var sourcesList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(appState.sources) { source in
                    SourceCard(source: source)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "7B2FBE").opacity(0.4))
            Text(LocalizedStringKey("no_sources"))
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.4))
            Button {
                showAddSource = true
            } label: {
                Text(LocalizedStringKey("add_source"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient(colors: [Color(hex: "7B2FBE"), Color(hex: "5B1A9A")],
                                               startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }
}

// MARK: - Source Card
struct SourceCard: View {
    let source: Source
    @EnvironmentObject var appState: AppState
    @State private var showDeleteAlert = false
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "7B2FBE").opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: source.isBuiltIn ? "star.fill" : "antenna.radiowaves.left.and.right")
                        .foregroundStyle(Color(hex: "7B2FBE"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(source.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        if source.isBuiltIn {
                            Text(LocalizedStringKey("official"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: "7B2FBE"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: "7B2FBE").opacity(0.15)))
                        }
                    }
                    Text("\(source.apps.count) \(NSLocalizedString("apps_count", comment: ""))")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                // Actions
                HStack(spacing: 12) {
                    Button {
                        refreshSource()
                    } label: {
                        Image(systemName: isRefreshing ? "arrow.clockwise" : "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "7B2FBE"))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }

                    if !source.isBuiltIn {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                }
            }

            // URL
            Text(source.url)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.3))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "1A1A28"))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
        .alert(LocalizedStringKey("confirm_delete"), isPresented: $showDeleteAlert) {
            Button(LocalizedStringKey("delete"), role: .destructive) {
                appState.deleteSource(id: source.id)
            }
            Button(LocalizedStringKey("cancel"), role: .cancel) {}
        }
    }

    func refreshSource() {
        isRefreshing = true
        Task {
            await appState.refreshSource(id: source.id)
            await MainActor.run { isRefreshing = false }
        }
    }
}

// MARK: - Add Source Sheet
struct AddSourceSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var error: String?

    let popularSources = [
        ("AltStore", "https://cdn.altstore.io/file/altstore/apps.json"),
        ("Feather Beta", "https://github.com/khcrysalis/Feather/raw/main/Feather.json"),
        ("Scarlet", "https://usescarlet.com/apps.json"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // URL Input
                        VStack(alignment: .leading, spacing: 10) {
                            Text(LocalizedStringKey("source_url_label"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))

                            HStack(spacing: 12) {
                                TextField("", text: $urlText,
                                          prompt: Text("https://example.com/apps.json")
                                              .foregroundStyle(.white.opacity(0.25)))
                                    .foregroundStyle(.white)
                                    .font(.system(size: 14))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "1A1A28"))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            )

                            if let error = error {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                            }
                        }

                        // Popular Sources
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey("popular_sources"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)

                            ForEach(popularSources, id: \.0) { name, url in
                                Button {
                                    urlText = url
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(name)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text(url)
                                                .font(.system(size: 11))
                                                .foregroundStyle(.white.opacity(0.3))
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(Color(hex: "7B2FBE"))
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: "1A1A28"))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(LocalizedStringKey("add_source"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) { isPresented = false }
                        .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView().tint(Color(hex: "7B2FBE"))
                    } else {
                        Button(LocalizedStringKey("add")) {
                            addSource()
                        }
                        .foregroundStyle(Color(hex: "7B2FBE"))
                        .disabled(urlText.isEmpty)
                    }
                }
            }
        }
    }

    func addSource() {
        error = nil
        isLoading = true
        Task {
            let success = await appState.addSource(url: urlText)
            await MainActor.run {
                isLoading = false
                if success {
                    isPresented = false
                    appState.showToast(NSLocalizedString("source_added", comment: ""))
                } else {
                    error = NSLocalizedString("error_source_invalid", comment: "")
                }
            }
        }
    }
}
