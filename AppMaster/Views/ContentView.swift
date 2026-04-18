import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                BrowseCategoriesView()
                    .tag(1)

                SourcesView()
                    .tag(2)

                LibraryView()
                    .tag(3)

                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .background(Color(hex: "0A0A0F").ignoresSafeArea())
        .sheet(isPresented: $appState.showInstallSheet) {
            if let url = appState.pendingInstallURL {
                InstallFromURLView(url: url)
            }
        }
        .overlay(alignment: .top) {
            if let msg = appState.toastMessage {
                ToastView(message: msg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: appState.toastMessage)
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, labelKey: String)] = [
        ("house.fill", "tab_home"),
        ("square.grid.2x2.fill", "tab_browse"),
        ("plus.circle.fill", "tab_sources"),
        ("square.and.arrow.down.fill", "tab_library"),
        ("gearshape.fill", "tab_settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 22, weight: selectedTab == i ? .bold : .regular))
                            .foregroundStyle(selectedTab == i ? Color(hex: "7B2FBE") : Color.white.opacity(0.4))
                            .scaleEffect(selectedTab == i ? 1.1 : 1.0)

                        Text(LocalizedStringKey(tabs[i].labelKey))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(selectedTab == i ? Color(hex: "7B2FBE") : Color.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "111118"))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 20, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Toast
struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(hex: "1E1E2E"))
                    .overlay(Capsule().stroke(Color(hex: "7B2FBE").opacity(0.5), lineWidth: 1))
            )
            .shadow(color: Color(hex: "7B2FBE").opacity(0.3), radius: 12)
            .padding(.top, 60)
    }
}
