import SwiftUI

struct BrowseCategoriesView: View {
    @EnvironmentObject var appState: AppState

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text(LocalizedStringKey("tab_browse"))
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 60)

                        // Categories Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(AppCategory.allCases.filter { $0 != .unknown }) { cat in
                                NavigationLink(destination: CategoryAppsView(category: cat)) {
                                    CategoryGridCard(category: cat, count: appState.appsForCategory(cat).count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                }
            }
        }
    }
}

struct CategoryGridCard: View {
    let category: AppCategory
    let count: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 140)
                .overlay(
                    Image(systemName: category.icon)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.white.opacity(0.12))
                        .offset(x: 40, y: -10),
                    alignment: .trailing
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(category.localizedName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(count) \(NSLocalizedString("apps_count", comment: ""))")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
        }
    }
}

// MARK: - Category Apps View
struct CategoryAppsView: View {
    let category: AppCategory
    @EnvironmentObject var appState: AppState
    @State private var viewMode: ViewMode = .grid
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    enum ViewMode { case grid, list }

    var apps: [AppEntry] { appState.appsForCategory(category) }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()
            VStack(spacing: 0) {
                // Sub-header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .foregroundStyle(LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("\(apps.count) \(NSLocalizedString("apps_count", comment: ""))")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    // Toggle view mode
                    Button {
                        withAnimation(.spring()) {
                            viewMode = viewMode == .grid ? .list : .grid
                        }
                    } label: {
                        Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.3x3")
                            .foregroundStyle(Color(hex: "7B2FBE"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if apps.isEmpty {
                    emptyView
                } else if viewMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
        }
        .navigationTitle(category.localizedName)
        .navigationBarTitleDisplayMode(.large)
    }

    var gridView: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(apps) { app in
                    NavigationLink(destination: AppDetailView(app: app)) {
                        AppCardSmall(app: app)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    var listView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(apps) { app in
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
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: category.icon)
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "7B2FBE").opacity(0.4))
            Text(LocalizedStringKey("no_apps_category"))
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
    }
}
