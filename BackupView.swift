import SwiftUI
import UIKit

struct BackupSheet: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    HStack {
                        Text("Einstellungen")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Button { isPresented = false } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(AppTheme.controlBackground).clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 18)

                    // Appearance
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Darstellung")

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Name")
                            DarkTextField(
                                placeholder: "Name für die Startseite",
                                text: Binding(
                                    get: { store.displayName },
                                    set: { store.setDisplayName($0) }
                                )
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Modus")
                            HStack(spacing: 10) {
                                ForEach(AppAppearance.allCases) { appearance in
                                    settingsOption(
                                        title: appearance.title,
                                        isSelected: store.appAppearance == appearance,
                                        swatch: appearance == .dark ? Color.black : Color.white
                                    ) {
                                        store.setAppearance(appearance)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Theme")
                            HStack(spacing: 12) {
                                ForEach(AppAccentTheme.allCases) { theme in
                                    ThemePreviewTile(
                                        theme: theme,
                                        isLight: store.appAppearance == .light,
                                        isSelected: store.appAccentTheme == theme
                                    ) {
                                        store.setAccentTheme(theme)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .glassCard()

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, AppTheme.phoneScreenPadding)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        // Re-render the whole sheet live when the appearance/theme changes,
        // so the cards instantly adopt the new colours (not only after reopen).
        .preferredColorScheme(store.appAppearance.preferredColorScheme)
        .id("\(store.appAppearance.rawValue)-\(store.appAccentTheme.rawValue)")
    }

    private func settingsOption(title: String, isSelected: Bool, swatch: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(swatch)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(AppTheme.glassBorder, lineWidth: 1))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? AppTheme.onAccent : AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background {
                if isSelected {
                    AppTheme.accent
                } else {
                    AppTheme.controlBackground
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous).stroke(isSelected ? AppTheme.accent.opacity(0.45) : AppTheme.glassBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Preview Tile (live palette mock per pack)

struct ThemePreviewTile: View {
    let theme: AppAccentTheme
    let isLight: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let p = theme.palette(light: isLight)
        Button(action: action) {
            VStack(spacing: 10) {
                // Miniature app mock rendered in this pack's palette
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Circle().fill(p.accent).frame(width: 9, height: 9)
                        Circle().fill(p.accentSecondary).frame(width: 9, height: 9)
                        Circle().fill(p.success).frame(width: 9, height: 9)
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        RoundedRectangle(cornerRadius: 3).fill(p.textPrimary.opacity(0.85)).frame(width: 52, height: 6)
                        RoundedRectangle(cornerRadius: 3).fill(p.textSecondary.opacity(0.7)).frame(width: 34, height: 5)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(p.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(p.border, lineWidth: 0.5))
                    Capsule().fill(p.accent).frame(width: 50, height: 16)
                }
                .padding(12)
                .frame(width: 150, alignment: .leading)
                .background(p.background)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                        .stroke(isSelected ? p.accent : AppTheme.glassBorder, lineWidth: isSelected ? 2 : 0.5)
                )

                HStack(spacing: 6) {
                    Text(theme.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.accent)
                    }
                    Spacer()
                }
                .frame(width: 150)
            }
        }
        .buttonStyle(.plain)
    }
}
