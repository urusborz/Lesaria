import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedMode: AppMode = .persoenlich
    @State private var selectedTab: TabItem = .startseite
    @State private var selectedTrackerSection: TrackerSection = .habits
    @State private var showingBackup = false
    @State private var showingQuickActions = false
    @State private var quickActionTarget: QuickActionTarget? = nil

    var body: some View {
        Group {
            if store.isAuthenticated {
                mainApp
            } else {
                AuthView()
            }
        }
        .preferredColorScheme(store.appAppearance.preferredColorScheme)
        .id("\(store.appAppearance.rawValue)-\(store.appAccentTheme.rawValue)-\(store.isAuthenticated)")
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMode)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
        .onAppear { store.bootstrapNotifications() }
        .sheet(isPresented: $showingBackup) {
            BackupSheet(isPresented: $showingBackup).environmentObject(store)
        }
        .sheet(isPresented: $showingQuickActions) {
            QuickActionMenuSheet(mode: selectedMode, onSelect: openQuickAction, isPresented: $showingQuickActions)
        }
        .sheet(item: $quickActionTarget) { target in
            quickActionSheet(for: target)
        }
    }

    private var mainApp: some View {
        GeometryReader { proxy in
            let screenPadding = AppTheme.screenPadding(for: proxy.size.width)

            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        ModeSwitcherView(selectedMode: $selectedMode)
                        AddButton { showingQuickActions = true }
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

                    ZStack {
                        switch selectedTab {
                        case .startseite:
                            if selectedMode == .persoenlich {
                                StartseitePersoenlichView(
                                    mode: $selectedMode,
                                    selectedTab: $selectedTab,
                                    selectedTrackerSection: $selectedTrackerSection,
                                    onQuickAction: openQuickAction
                                )
                            } else {
                                StartseiteFamilieView(
                                    mode: $selectedMode,
                                    selectedTab: $selectedTab,
                                    onQuickAction: openQuickAction
                                )
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
    }

    private func openQuickAction(_ target: QuickActionTarget) {
        navigateForQuickAction(target)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            quickActionTarget = target
        }
    }

    private func navigateForQuickAction(_ target: QuickActionTarget) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            switch target {
            case .event:
                selectedTab = .kalender
            case .reminder:
                selectedTab = .erinnerungen
            case .note:
                selectedTab = .notizen
            case .habit:
                selectedMode = .persoenlich
                selectedTrackerSection = .habits
                selectedTab = .tracker
            case .withdrawal:
                selectedMode = .persoenlich
                selectedTrackerSection = .entzug
                selectedTab = .tracker
            case .shopping:
                selectedMode = .familie
                selectedTab = .tracker
            }
        }
    }

    private var quickActionPresented: Binding<Bool> {
        Binding(
            get: { quickActionTarget != nil },
            set: { if !$0 { quickActionTarget = nil } }
        )
    }

    @ViewBuilder
    private func quickActionSheet(for target: QuickActionTarget) -> some View {
        switch target {
        case .event:
            EventSheet(mode: selectedMode, existing: nil, defaultDate: Date(), isPresented: quickActionPresented)
                .environmentObject(store)
        case .reminder:
            ReminderSheet(mode: selectedMode, existing: nil, isPresented: quickActionPresented)
                .environmentObject(store)
        case .note:
            NoteSheet(mode: selectedMode, existing: nil, isPresented: quickActionPresented)
                .environmentObject(store)
        case .habit:
            HabitSheet(existing: nil, isPresented: quickActionPresented)
                .environmentObject(store)
        case .withdrawal:
            WithdrawalSheet(existing: nil, isPresented: quickActionPresented)
                .environmentObject(store)
        case .shopping:
            ShoppingSheet(existing: nil, isPresented: quickActionPresented)
                .environmentObject(store)
        }
    }
}

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
        .liquidTabBarGlass(cornerRadius: 30)
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
                        LiquidSelectedTabBackground()
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

struct LiquidSelectedTabBackground: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.accent.opacity(AppTheme.isLight ? 0.62 : 0.50))
            LinearGradient(
                colors: [
                    Color.white.opacity(AppTheme.isLight ? 0.42 : 0.24),
                    Color.white.opacity(0.04),
                    AppTheme.accentSecondary.opacity(AppTheme.isLight ? 0.18 : 0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(AppTheme.isLight ? 0.44 : 0.24), lineWidth: 0.8)
        )
        .shadow(color: AppTheme.accent.opacity(AppTheme.isLight ? 0.22 : 0.34), radius: 10, x: 0, y: 4)
        .padding(2)
    }
}
