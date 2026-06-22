import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedMode: AppMode = .persoenlich
    @State private var selectedTab: TabItem = .startseite
    @State private var selectedTrackerSection: TrackerSection = .habits
    @State private var showingBackup = false

    var body: some View {
        GeometryReader { proxy in
            let screenPadding = AppTheme.screenPadding(for: proxy.size.width)

            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Mode Switcher at top + backup access
                    HStack(spacing: 10) {
                        ModeSwitcherView(selectedMode: $selectedMode)
                        Button { showingBackup = true } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 46, height: 40)
                                .floatingGlass(cornerRadius: 14)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, screenPadding)
                    .padding(.bottom, 8)

                    // Main content area — the nav floats OVER this via safeAreaInset,
                    // so content scrolls underneath it instead of being clipped in a
                    // hard line right above the menu (which read as a "bar").
                    ZStack {
                        switch selectedTab {
                        case .startseite:
                            if selectedMode == .persoenlich {
                                StartseitePersoenlichView(mode: $selectedMode, selectedTab: $selectedTab, selectedTrackerSection: $selectedTrackerSection)
                            } else {
                                StartseiteFamilieView(mode: $selectedMode, selectedTab: $selectedTab)
                            }
                        case .kalender:
                            KalenderView(mode: selectedMode)
                        case .erinnerungen:
                            ErinnerungenView(mode: selectedMode)
                        case .notizen:
                            NotizenView(mode: selectedMode)
                        case .tracker:
                            TrackerView(mode: selectedMode, section: $selectedTrackerSection)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        BottomNavBarView(selectedTab: $selectedTab, mode: selectedMode)
                            .padding(.horizontal, screenPadding + 6)
                            .padding(.bottom, 6)
                    }
                }
            }
        }
        .preferredColorScheme(store.appAppearance.preferredColorScheme)
        .id("\(store.appAppearance.rawValue)-\(store.appAccentTheme.rawValue)")
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMode)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
        .onAppear { store.bootstrapNotifications() }
        .sheet(isPresented: $showingBackup) {
            BackupSheet(isPresented: $showingBackup).environmentObject(store)
        }
    }
}

// MARK: - Mode Switcher

struct ModeSwitcherView: View {
    @Binding var selectedMode: AppMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppMode.allCases, id: \.rawValue) { mode in
                ModeSwitcherButton(
                    title: mode.rawValue,
                    isSelected: selectedMode == mode,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedMode = mode
                        }
                    }
                )
            }
        }
        .floatingGlass(cornerRadius: 24)
    }
}

struct ModeSwitcherButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundColor(isSelected ? AppTheme.onAccent : AppTheme.textTertiary)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(AppTheme.accent)
                                .padding(4)
                                .shadow(color: AppTheme.accent.opacity(0.35), radius: 8, x: 0, y: 3)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom Navigation

struct BottomNavBarView: View {
    @Binding var selectedTab: TabItem
    let mode: AppMode

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TabItem.allCases, id: \.rawValue) { tab in
                TabBarButtonView(
                    tab: tab,
                    mode: mode,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 8)
        .floatingGlass(cornerRadius: 30, strong: true)
    }
}

struct TabBarButtonView: View {
    let tab: TabItem
    let mode: AppMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tab.icon(for: mode))
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                Text(tab.label(for: mode))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundColor(isSelected ? AppTheme.onAccent : AppTheme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.accent)
                            .shadow(color: AppTheme.accent.opacity(0.35), radius: 8, x: 0, y: 3)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}
