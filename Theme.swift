import SwiftUI

// MARK: - Design System

enum AppAppearance: String, CaseIterable, Codable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: return "Dunkel"
        case .light: return "Hell"
        }
    }

    var preferredColorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }
}

// MARK: - Palette (a full set of tokens for one theme in one appearance)

struct Palette {
    let background: Color        // app background (solid)
    let surface: Color           // solid cards / rows / tiles
    let glassTint: Color         // translucent tint layered over the glass material
    let control: Color           // segmented / control fills
    let accent: Color            // primary action / selection
    let accentSecondary: Color   // secondary accent (family, alternate hue)
    let success: Color           // done / streak / progress
    let warning: Color           // prayers / overdue / attention
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let border: Color
    let separator: Color
    let ringTrack: Color
    let shadow: Color
}

// MARK: - Theme Packs

enum AppAccentTheme: String, CaseIterable, Codable, Identifiable {
    case ocean
    case sunset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean:  return "Ocean"
        case .sunset: return "Sunset"
        }
    }

    var subtitle: String {
        switch self {
        case .ocean:  return "Frisches Blau & Cyan"
        case .sunset: return "Warmes Orange & Gold"
        }
    }

    /// Full token set for this pack in the requested appearance.
    func palette(light: Bool) -> Palette {
        switch self {

        // MARK: Ocean – cool blue / cyan
        case .ocean:
            if light {
                return Palette(
                    background:       Color(red: 0.945, green: 0.965, blue: 0.986),
                    surface:          Color(red: 1.0,   green: 1.0,   blue: 1.0),
                    glassTint:        Color(red: 1.0,   green: 1.0,   blue: 1.0).opacity(0.60),
                    control:          Color(red: 0.094, green: 0.231, blue: 0.412).opacity(0.06),
                    accent:           Color(red: 0.106, green: 0.451, blue: 0.886),
                    accentSecondary:  Color(red: 0.043, green: 0.557, blue: 0.671),
                    success:          Color(red: 0.078, green: 0.671, blue: 0.475),
                    warning:          Color(red: 0.902, green: 0.604, blue: 0.110),
                    textPrimary:      Color(red: 0.063, green: 0.106, blue: 0.169),
                    textSecondary:    Color(red: 0.298, green: 0.357, blue: 0.447),
                    textTertiary:     Color(red: 0.506, green: 0.565, blue: 0.651),
                    border:           Color(red: 0.063, green: 0.137, blue: 0.247).opacity(0.10),
                    separator:        Color(red: 0.063, green: 0.137, blue: 0.247).opacity(0.08),
                    ringTrack:        Color(red: 0.063, green: 0.137, blue: 0.247).opacity(0.12),
                    shadow:           Color(red: 0.102, green: 0.200, blue: 0.353).opacity(0.13)
                )
            }
            return Palette(
                background:       Color(red: 0.043, green: 0.067, blue: 0.118),
                surface:          Color(red: 0.090, green: 0.122, blue: 0.184),
                glassTint:        Color(red: 0.129, green: 0.176, blue: 0.267).opacity(0.55),
                control:          Color(red: 0.137, green: 0.176, blue: 0.251).opacity(0.92),
                accent:           Color(red: 0.255, green: 0.561, blue: 0.969),
                accentSecondary:  Color(red: 0.149, green: 0.776, blue: 0.835),
                success:          Color(red: 0.176, green: 0.800, blue: 0.580),
                warning:          Color(red: 0.980, green: 0.706, blue: 0.251),
                textPrimary:      Color(red: 0.929, green: 0.949, blue: 0.984),
                textSecondary:    Color(red: 0.624, green: 0.682, blue: 0.776),
                textTertiary:     Color(red: 0.420, green: 0.482, blue: 0.580),
                border:           Color.white.opacity(0.10),
                separator:        Color.white.opacity(0.07),
                ringTrack:        Color.white.opacity(0.13),
                shadow:           Color.black.opacity(0.45)
            )

        // MARK: Sunset – warm orange / gold
        case .sunset:
            if light {
                return Palette(
                    background:       Color(red: 0.984, green: 0.961, blue: 0.937),
                    surface:          Color(red: 1.0,   green: 0.996, blue: 0.988),
                    glassTint:        Color(red: 1.0,   green: 1.0,   blue: 1.0).opacity(0.60),
                    control:          Color(red: 0.451, green: 0.231, blue: 0.094).opacity(0.06),
                    accent:           Color(red: 0.878, green: 0.388, blue: 0.106),
                    accentSecondary:  Color(red: 0.851, green: 0.255, blue: 0.353),
                    success:          Color(red: 0.345, green: 0.620, blue: 0.247),
                    warning:          Color(red: 0.882, green: 0.580, blue: 0.110),
                    textPrimary:      Color(red: 0.149, green: 0.094, blue: 0.067),
                    textSecondary:    Color(red: 0.412, green: 0.329, blue: 0.282),
                    textTertiary:     Color(red: 0.596, green: 0.514, blue: 0.459),
                    border:           Color(red: 0.247, green: 0.137, blue: 0.063).opacity(0.10),
                    separator:        Color(red: 0.247, green: 0.137, blue: 0.063).opacity(0.08),
                    ringTrack:        Color(red: 0.247, green: 0.137, blue: 0.063).opacity(0.12),
                    shadow:           Color(red: 0.353, green: 0.200, blue: 0.102).opacity(0.13)
                )
            }
            return Palette(
                background:       Color(red: 0.098, green: 0.063, blue: 0.051),
                surface:          Color(red: 0.165, green: 0.110, blue: 0.090),
                glassTint:        Color(red: 0.220, green: 0.149, blue: 0.122).opacity(0.55),
                control:          Color(red: 0.235, green: 0.165, blue: 0.133).opacity(0.92),
                accent:           Color(red: 0.969, green: 0.475, blue: 0.169),
                accentSecondary:  Color(red: 0.961, green: 0.357, blue: 0.451),
                success:          Color(red: 0.451, green: 0.745, blue: 0.353),
                warning:          Color(red: 0.973, green: 0.690, blue: 0.196),
                textPrimary:      Color(red: 0.980, green: 0.945, blue: 0.918),
                textSecondary:    Color(red: 0.776, green: 0.698, blue: 0.643),
                textTertiary:     Color(red: 0.561, green: 0.490, blue: 0.443),
                border:           Color.white.opacity(0.10),
                separator:        Color.white.opacity(0.07),
                ringTrack:        Color.white.opacity(0.13),
                shadow:           Color.black.opacity(0.45)
            )
        }
    }

    /// Quick accent swatch (selected appearance not required).
    var swatch: Color { palette(light: false).accent }

    static func storedValue(_ rawValue: String?) -> AppAccentTheme {
        switch rawValue {
        case "sunset", "rubin":            return .sunset
        case "ocean", "azur", "klar", "emerald": return .ocean
        default: return .ocean
        }
    }
}

// MARK: - Active Theme Tokens

struct AppTheme {
    static var appearance: AppAppearance {
        AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .dark
    }

    static var accentTheme: AppAccentTheme {
        AppAccentTheme.storedValue(UserDefaults.standard.string(forKey: "appAccentTheme"))
    }

    static var isLight: Bool { appearance == .light }

    private static var p: Palette { accentTheme.palette(light: isLight) }

    // Backgrounds
    static var background: Color { p.background }
    static var backgroundPrimary: Color { p.background }
    static var backgroundSecondary: Color { p.surface }
    static var backgroundTertiary: Color { p.surface }
    static var cardSolid: Color { p.surface }

    // Glass
    static var glassTint: Color { p.glassTint }
    static var glassBackground: Color { p.surface }
    static var glassBorder: Color { p.border }
    static var glassHighlight: Color { isLight ? Color.white.opacity(0.9) : Color.white.opacity(0.12) }
    static var controlBackground: Color { p.control }
    static var selectedControlBackground: Color { p.accent.opacity(isLight ? 0.14 : 0.26) }
    static var ringTrack: Color { p.ringTrack }
    static var shadow: Color { p.shadow }
    static var cardShadow: Color { p.shadow.opacity(isLight ? 0.7 : 0.8) }
    static var onAccent: Color { Color.white }

    // Text
    static var textPrimary: Color { p.textPrimary }
    static var textSecondary: Color { p.textSecondary }
    static var textTertiary: Color { p.textTertiary }

    // Accent colors (semantic — harmonised per theme)
    static var accent: Color { p.accent }
    static var accentSecondary: Color { p.accentSecondary }
    static var accentBlue: Color { p.accent }
    static var accentGreen: Color { p.success }
    static var accentAmber: Color { p.warning }
    static var accentPurple: Color { p.accentSecondary }

    // Separators
    static var separator: Color { p.separator }

    // Corner radii
    static let radiusSmall: CGFloat = 12
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 22
    static let radiusXL: CGFloat = 28

    static let phoneScreenPadding: CGFloat = 14
    static let compactPhoneScreenPadding: CGFloat = 12

    static func screenPadding(for width: CGFloat) -> CGFloat {
        width <= 390 ? compactPhoneScreenPadding : phoneScreenPadding
    }
}

// MARK: - Liquid Glass Card

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = AppTheme.radiusLarge

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.glassTint, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.glassBorder, lineWidth: 0.8)
            )
            .shadow(color: AppTheme.cardShadow, radius: 16, x: 0, y: 10)
    }
}

extension View {
    func glassCard(padding: CGFloat = 16, radius: CGFloat = AppTheme.radiusLarge) -> some View {
        modifier(GlassCard(padding: padding, radius: radius))
    }

    /// Floating glass treatment for bars (nav bar, mode switcher).
    func floatingGlass(cornerRadius: CGFloat, strong: Bool = false) -> some View {
        self
            .background(AppTheme.glassTint, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.glassBorder, lineWidth: 0.8)
            )
            .shadow(color: AppTheme.cardShadow, radius: strong ? 20 : 12, x: 0, y: strong ? 12 : 6)
    }
}

// MARK: - Section Header Style

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}
