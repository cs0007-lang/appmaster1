import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var searchResults: [AppEntry] = []

    var featuredApps: [AppEntry] {
        Array(appState.allApps().prefix(5))
    }

    var recentlyAdded: [AppEntry] {
        Array(appState.allApps().prefix(10))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 60)

                        // Search Bar
                        searchBar
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        if searchText.isEmpty {
                            mainContent
                        } else {
                            searchResultsView
                        }

                        Spacer(minLength: 100)
                    }
                }
                .refreshable {
                    await appState.refreshAllSources()
                }
            }
        }
        .onChange(of: searchText) { _, query in
            searchResults = query.isEmpty ? [] : appState.allApps().filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.description.localizedCaseInsensitiveContains(query)
            }
        }
    }

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text("AppMaster")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "7B2FBE"), Color(hex: "A855F7")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
            }
            Spacer()
            if appState.isLoading {
                ProgressView()
                    .tint(Color(hex: "7B2FBE"))
            }
        }
    }

    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.4))
            TextField("", text: $searchText, prompt: Text(LocalizedStringKey("search_placeholder")).foregroundStyle(.white.opacity(0.3)))
                .foregroundStyle(.white)
                .font(.system(size: 16))
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "1A1A28"))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    @ViewBuilder
    var mainContent: some View {
        // Featured Banner
        if !featuredApps.isEmpty {
            featuredSection
                .padding(.top, 24)
        }

        // Categories Quick Access
        categoriesSection
            .padding(.top, 28)

        // Recently Added
        if !recentlyAdded.isEmpty {
            recentlyAddedSection
                .padding(.top, 28)
        }

        // All Categories Apps
        ForEach(AppCategory.allCases.filter { $0 != .unknown }) { cat in
            let apps = appState.appsForCategory(cat)
            if !apps.isEmpty {
                categoryRowSection(category: cat, apps: apps)
                    .padding(.top, 28)
            }
        }
    }

    var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: LocalizedStringKey("section_featured"), showAll: false)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(featuredApps) { app in
                        NavigationLink(destination: AppDetailView(app: app)) {
                            FeaturedCard(app: app)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: LocalizedStringKey("section_categories"), showAll: false)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppCategory.allCases.filter { $0 != .unknown }) { cat in
                        NavigationLink(destination: CategoryAppsView(category: cat)) {
                            CategoryChip(category: cat)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: LocalizedStringKey("section_new"), showAll: false)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentlyAdded) { app in
                        NavigationLink(destination: AppDetailView(app: app)) {
                            AppCardSmall(app: app)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    func categoryRowSection(category: AppCategory, apps: [AppEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: LocalizedStringKey(category.localizedName), showAll: true)
                Spacer()
                NavigationLink(destination: CategoryAppsView(category: category)) {
                    Text(LocalizedStringKey("see_all"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "7B2FBE"))
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(apps.prefix(8)) { app in
                        NavigationLink(destination: AppDetailView(app: app)) {
                            AppCardSmall(app: app)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    var searchResultsView: some View {
        LazyVStack(spacing: 0) {
            ForEach(searchResults) { app in
                NavigationLink(destination: AppDetailView(app: app)) {
                    AppListRow(app: app)
                }
                .buttonStyle(.plain)
                Divider().background(Color.white.opacity(0.06))
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return NSLocalizedString("greeting_morning", comment: "") }
        if hour < 18 { return NSLocalizedString("greeting_afternoon", comment: "") }
        return NSLocalizedString("greeting_evening", comment: "")
    }

    func sectionHeader(title: LocalizedStringKey, showAll: Bool) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
    }
}

// MARK: - Featured Card
struct FeaturedCard: View {
    let app: AppEntry
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: app.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 300, height: 170)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(app.category.localizedName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: AppCategory
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            Text(category.localizedName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
        }
        .frame(width: 72)
    }
}

// MARK: - App Card Small
struct AppCardSmall: View {
    let app: AppEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: app.iconURL ?? "")) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                default:
                    ZStack {
                        LinearGradient(colors: app.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        Text(String(app.name.prefix(1)))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))

            Text(app.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
                .frame(width: 80, alignment: .leading)

            Text(app.version)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(width: 80)
    }
}

// MARK: - App List Row
struct AppListRow: View {
    let app: AppEntry
    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: app.iconURL ?? "")) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default:
                    ZStack {
                        LinearGradient(colors: app.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        Text(String(app.name.prefix(1))).font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(app.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                Text(app.category.localizedName).font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.vertical, 10)
    }
}
