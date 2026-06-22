import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedMode: AppMode = .persoenlich
    @State private var selectedTab: TabItem = .startseite
    @State private var showingBackup = false

    var body: some View {
        ZStack {
            // OLED Background
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Mode Switcher at top + backup access
                HStack(spacing: 12) {
                    ModeSwitcherView(selectedMode: $selectedMode)
                    Button { showingBackup = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 46, height: 40)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 56)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                // Main content area
                ZStack {
                    switch selectedTab {
                    case .startseite:
                        if selectedMode == .persoenlich {
                            StartseitePersoenlichView(mode: $selectedMode, selectedTab: $selectedTab)
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
                        TrackerView(mode: selectedMode)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating bottom navigation
                BottomNavBarView(selectedTab: $selectedTab, mode: selectedMode)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
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
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.glassBorder, lineWidth: 0.5))
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
                .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textTertiary)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(Color.white.opacity(0.11))
                                .padding(4)
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
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.04))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.glassBorder, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
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
            }
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.38))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}
