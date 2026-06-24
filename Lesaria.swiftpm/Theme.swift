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
    let surface: Color           // solid cards / rows / tiles / bars
    let surfaceElevated: Color   // slightly lifted surface (selected rows)
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

// MARK: - Theme Pack (currently a single pack: Ocean)

enum AppAccentTheme: String, CaseIterable, Codable, Identifiable {
    case ocean
    case rubin
    case sol
    case tanne

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean: return "Ocean"
        case .rubin: return "Rubin"
        case .sol: return "Sol"
        case .tanne: return "Tanne"
        }
    }

    var subtitle: String {
        switch self {
        case .ocean: return "Frisches Blau & Cyan"
        case .rubin: return "Rubinrot & Violett"
        case .sol: return "Koralle, Mint & Gold"
        case .tanne: return "Tanne, Kupfer & Teal"
        }
    }

    /// Full token set for this pack in the requested appearance.
    func palette(light: Bool) -> Palette {
        switch self {
        case .ocean:
            if light {
                return Palette(
                    background:       Color(red: 0.945, green: 0.965, blue: 0.986),
                    surface:          Color(red: 1.0,   green: 1.0,   blue: 1.0),
                    surfaceElevated:  Color(red: 0.976, green: 0.984, blue: 0.996),
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
                surfaceElevated:  Color(red: 0.122, green: 0.161, blue: 0.235),
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
        case .rubin:
            if light {
                return Palette(
                    background:       Color(red: 0.988, green: 0.947, blue: 0.966),
                    surface:          Color(red: 1.0,   green: 0.985, blue: 0.992),
                    surfaceElevated:  Color(red: 0.988, green: 0.930, blue: 0.960),
                    control:          Color(red: 0.420, green: 0.055, blue: 0.200).opacity(0.07),
                    accent:           Color(red: 0.835, green: 0.110, blue: 0.365),
                    accentSecondary:  Color(red: 0.505, green: 0.245, blue: 0.930),
                    success:          Color(red: 0.060, green: 0.645, blue: 0.465),
                    warning:          Color(red: 0.965, green: 0.520, blue: 0.185),
                    textPrimary:      Color(red: 0.135, green: 0.050, blue: 0.095),
                    textSecondary:    Color(red: 0.455, green: 0.315, blue: 0.390),
                    textTertiary:     Color(red: 0.670, green: 0.530, blue: 0.610),
                    border:           Color(red: 0.250, green: 0.045, blue: 0.130).opacity(0.10),
                    separator:        Color(red: 0.250, green: 0.045, blue: 0.130).opacity(0.08),
                    ringTrack:        Color(red: 0.250, green: 0.045, blue: 0.130).opacity(0.13),
                    shadow:           Color(red: 0.330, green: 0.055, blue: 0.145).opacity(0.16)
                )
            }
            return Palette(
                background:       Color(red: 0.085, green: 0.025, blue: 0.052),
                surface:          Color(red: 0.145, green: 0.060, blue: 0.105),
                surfaceElevated:  Color(red: 0.190, green: 0.080, blue: 0.145),
                control:          Color(red: 0.210, green: 0.100, blue: 0.170).opacity(0.94),
                accent:           Color(red: 0.980, green: 0.220, blue: 0.475),
                accentSecondary:  Color(red: 0.680, green: 0.370, blue: 1.0),
                success:          Color(red: 0.180, green: 0.805, blue: 0.590),
                warning:          Color(red: 1.0, green: 0.560, blue: 0.240),
                textPrimary:      Color(red: 0.990, green: 0.935, blue: 0.965),
                textSecondary:    Color(red: 0.785, green: 0.650, blue: 0.735),
                textTertiary:     Color(red: 0.575, green: 0.455, blue: 0.540),
                border:           Color.white.opacity(0.105),
                separator:        Color.white.opacity(0.070),
                ringTrack:        Color.white.opacity(0.140),
                shadow:           Color.black.opacity(0.48)
            )
        case .sol:
            if light {
                return Palette(
                    background:       Color(red: 0.992, green: 0.962, blue: 0.925),
                    surface:          Color(red: 1.000, green: 0.992, blue: 0.975),
                    surfaceElevated:  Color(red: 0.982, green: 0.940, blue: 0.895),
                    control:          Color(red: 0.520, green: 0.210, blue: 0.125).opacity(0.075),
                    accent:           Color(red: 0.890, green: 0.295, blue: 0.195),
                    accentSecondary:  Color(red: 0.030, green: 0.555, blue: 0.560),
                    success:          Color(red: 0.145, green: 0.675, blue: 0.420),
                    warning:          Color(red: 0.930, green: 0.620, blue: 0.120),
                    textPrimary:      Color(red: 0.150, green: 0.075, blue: 0.055),
                    textSecondary:    Color(red: 0.455, green: 0.330, blue: 0.275),
                    textTertiary:     Color(red: 0.690, green: 0.560, blue: 0.480),
                    border:           Color(red: 0.340, green: 0.155, blue: 0.080).opacity(0.105),
                    separator:        Color(red: 0.340, green: 0.155, blue: 0.080).opacity(0.075),
                    ringTrack:        Color(red: 0.340, green: 0.155, blue: 0.080).opacity(0.120),
                    shadow:           Color(red: 0.415, green: 0.165, blue: 0.075).opacity(0.155)
                )
            }
            return Palette(
                background:       Color(red: 0.095, green: 0.046, blue: 0.034),
                surface:          Color(red: 0.155, green: 0.082, blue: 0.060),
                surfaceElevated:  Color(red: 0.210, green: 0.115, blue: 0.085),
                control:          Color(red: 0.245, green: 0.140, blue: 0.105).opacity(0.94),
                accent:           Color(red: 1.000, green: 0.405, blue: 0.270),
                accentSecondary:  Color(red: 0.180, green: 0.780, blue: 0.760),
                success:          Color(red: 0.310, green: 0.835, blue: 0.535),
                warning:          Color(red: 1.000, green: 0.705, blue: 0.210),
                textPrimary:      Color(red: 1.000, green: 0.945, blue: 0.900),
                textSecondary:    Color(red: 0.805, green: 0.690, blue: 0.610),
                textTertiary:     Color(red: 0.610, green: 0.505, blue: 0.450),
                border:           Color.white.opacity(0.105),
                separator:        Color.white.opacity(0.070),
                ringTrack:        Color.white.opacity(0.135),
                shadow:           Color.black.opacity(0.46)
            )
        case .tanne:
            if light {
                return Palette(
                    background:       Color(red: 0.930, green: 0.965, blue: 0.938),
                    surface:          Color(red: 0.985, green: 1.000, blue: 0.988),
                    surfaceElevated:  Color(red: 0.910, green: 0.956, blue: 0.925),
                    control:          Color(red: 0.055, green: 0.265, blue: 0.170).opacity(0.075),
                    accent:           Color(red: 0.045, green: 0.460, blue: 0.300),
                    accentSecondary:  Color(red: 0.760, green: 0.350, blue: 0.145),
                    success:          Color(red: 0.105, green: 0.640, blue: 0.330),
                    warning:          Color(red: 0.865, green: 0.535, blue: 0.145),
                    textPrimary:      Color(red: 0.045, green: 0.130, blue: 0.095),
                    textSecondary:    Color(red: 0.285, green: 0.410, blue: 0.340),
                    textTertiary:     Color(red: 0.505, green: 0.615, blue: 0.545),
                    border:           Color(red: 0.035, green: 0.165, blue: 0.105).opacity(0.105),
                    separator:        Color(red: 0.035, green: 0.165, blue: 0.105).opacity(0.080),
                    ringTrack:        Color(red: 0.035, green: 0.165, blue: 0.105).opacity(0.125),
                    shadow:           Color(red: 0.040, green: 0.170, blue: 0.105).opacity(0.155)
                )
            }
            return Palette(
                background:       Color(red: 0.030, green: 0.080, blue: 0.060),
                surface:          Color(red: 0.060, green: 0.125, blue: 0.095),
                surfaceElevated:  Color(red: 0.090, green: 0.170, blue: 0.130),
                control:          Color(red: 0.095, green: 0.190, blue: 0.145).opacity(0.94),
                accent:           Color(red: 0.190, green: 0.760, blue: 0.500),
                accentSecondary:  Color(red: 0.960, green: 0.490, blue: 0.220),
                success:          Color(red: 0.310, green: 0.850, blue: 0.460),
                warning:          Color(red: 0.980, green: 0.650, blue: 0.250),
                textPrimary:      Color(red: 0.900, green: 0.980, blue: 0.930),
                textSecondary:    Color(red: 0.645, green: 0.760, blue: 0.690),
                textTertiary:     Color(red: 0.455, green: 0.565, blue: 0.505),
                border:           Color.white.opacity(0.105),
                separator:        Color.white.opacity(0.072),
                ringTrack:        Color.white.opacity(0.135),
                shadow:           Color.black.opacity(0.48)
            )
        }
    }

    static func storedValue(_ rawValue: String?) -> AppAccentTheme {
        switch rawValue {
        case "rubin", "ruby", "sunset": return .rubin
        case "sol", "sun", "coral": return .sol
        case "tanne", "forest", "pine": return .tanne
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
    static var surface: Color { p.surface }
    static var cardSolid: Color { p.surface }

    // Surfaces / glass (solid for smooth scrolling)
    static var glassBackground: Color { p.surface }
    static var glassBorder: Color { p.border }
    static var glassHighlight: Color { isLight ? Color.white.opacity(0.9) : Color.white.opacity(0.12) }
    static var controlBackground: Color { p.control }
    static var selectedControlBackground: Color { p.accent.opacity(isLight ? 0.14 : 0.26) }
    static var ringTrack: Color { p.ringTrack }
    static var shadow: Color { p.shadow }
    static var onAccent: Color { Color.white }

    // Text
    static var textPrimary: Color { p.textPrimary }
    static var textSecondary: Color { p.textSecondary }
    static var textTertiary: Color { p.textTertiary }

    // Accent colors (semantic — harmonised)
    static var accent: Color { p.accent }
    static var accentSecondary: Color { p.accentSecondary }
    static var accentBlue: Color { p.accent }
    static var accentGreen: Color { p.success }
    static var accentAmber: Color { p.warning }
    static var accentPurple: Color { p.accentSecondary }

    static var heroBaseColors: [Color] {
        switch accentTheme {
        case .ocean:
            return [
                Color(red: 0.067, green: 0.102, blue: 0.180),
                Color(red: 0.098, green: 0.184, blue: 0.365),
                Color(red: 0.031, green: 0.051, blue: 0.102)
            ]
        case .rubin:
            return [
                Color(red: 0.135, green: 0.034, blue: 0.078),
                Color(red: 0.285, green: 0.070, blue: 0.185),
                Color(red: 0.070, green: 0.022, blue: 0.055)
            ]
        case .sol:
            return [
                Color(red: 0.220, green: 0.070, blue: 0.040),
                Color(red: 0.460, green: 0.165, blue: 0.080),
                Color(red: 0.060, green: 0.160, blue: 0.145)
            ]
        case .tanne:
            return [
                Color(red: 0.025, green: 0.115, blue: 0.085),
                Color(red: 0.055, green: 0.250, blue: 0.170),
                Color(red: 0.150, green: 0.075, blue: 0.040)
            ]
        }
    }

    static var heroGlowColors: [Color] {
        switch accentTheme {
        case .ocean:
            return [
                accentAmber.opacity(0.00),
                accentAmber.opacity(0.58),
                accent.opacity(0.16),
                accentSecondary.opacity(0.54),
                accentGreen.opacity(0.18),
                accentAmber.opacity(0.00)
            ]
        case .rubin:
            return [
                accentAmber.opacity(0.00),
                accent.opacity(0.62),
                accentAmber.opacity(0.22),
                accentSecondary.opacity(0.58),
                accentGreen.opacity(0.16),
                accentAmber.opacity(0.00)
            ]
        case .sol:
            return [
                accentAmber.opacity(0.00),
                accent.opacity(0.58),
                accentSecondary.opacity(0.46),
                accentAmber.opacity(0.50),
                accentGreen.opacity(0.18),
                accentAmber.opacity(0.00)
            ]
        case .tanne:
            return [
                accentAmber.opacity(0.00),
                accent.opacity(0.56),
                accentSecondary.opacity(0.42),
                accentAmber.opacity(0.30),
                accentGreen.opacity(0.28),
                accentAmber.opacity(0.00)
            ]
        }
    }

    static var microHabit: Color { accentGreen }
    static var microTask: Color { accent }
    static var microPrayer: Color { accentAmber }
    static var microStatus: Color { accentSecondary }

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

// MARK: - Card (solid, lightweight — no real-time blur for smooth scrolling)

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = AppTheme.radiusLarge
    @State private var glow = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                ZStack(alignment: .bottomTrailing) {
                    AppTheme.surface
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(AppTheme.accent.opacity(glow ? 0.105 : 0.055))
                        .frame(width: 118, height: 118)
                        .rotationEffect(.degrees(glow ? 34 : 24))
                        .scaleEffect(glow ? 1.08 : 1)
                        .offset(x: glow ? 28 : 44, y: glow ? 34 : 48)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.glassBorder, lineWidth: 0.8)
            )
            .shadow(color: AppTheme.shadow.opacity(0.22), radius: 18, x: 0, y: 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 5.2).repeatForever(autoreverses: true)) {
                    glow = true
                }
            }
    }
}

struct LiquidTabBarGlass: ViewModifier {
    let cornerRadius: CGFloat
    @State private var sheen = false

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppTheme.isLight ? Color.white.opacity(0.30) : Color.white.opacity(0.075))

                    LinearGradient(
                        colors: [
                            Color.white.opacity(AppTheme.isLight ? 0.58 : 0.20),
                            Color.white.opacity(0.05),
                            AppTheme.accent.opacity(AppTheme.isLight ? 0.10 : 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    RadialGradient(
                        colors: [
                            AppTheme.accentSecondary.opacity(AppTheme.isLight ? 0.20 : 0.30),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 8,
                        endRadius: 180
                    )
                    .blendMode(.screen)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(AppTheme.isLight ? 0.82 : 0.34),
                                AppTheme.glassBorder,
                                AppTheme.accent.opacity(AppTheme.isLight ? 0.24 : 0.36)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(Color.white.opacity(AppTheme.isLight ? 0.62 : 0.28))
                    .frame(width: 90, height: 2)
                    .blur(radius: 1.2)
                    .offset(x: sheen ? 160 : 18, y: 7)
                    .opacity(0.75)
            }
            .shadow(color: AppTheme.shadow.opacity(AppTheme.isLight ? 0.24 : 0.50), radius: 22, x: 0, y: 10)
            .shadow(color: AppTheme.accent.opacity(AppTheme.isLight ? 0.08 : 0.18), radius: 18, x: 0, y: 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 5.4).repeatForever(autoreverses: true)) {
                    sheen = true
                }
            }
    }
}

extension View {
    func glassCard(padding: CGFloat = 16, radius: CGFloat = AppTheme.radiusLarge) -> some View {
        modifier(GlassCard(padding: padding, radius: radius))
    }

    /// Floating solid treatment for bars (nav bar, mode switcher). Only the nav
    /// gets a soft shadow so it reads as floating without a heavy halo "bar".
    func floatingGlass(cornerRadius: CGFloat, strong: Bool = false) -> some View {
        self
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.glassBorder, lineWidth: 0.8)
            )
            .shadow(color: strong ? AppTheme.shadow.opacity(0.45) : .clear,
                    radius: strong ? 12 : 0, x: 0, y: strong ? 5 : 0)
    }

    func liquidTabBarGlass(cornerRadius: CGFloat) -> some View {
        modifier(LiquidTabBarGlass(cornerRadius: cornerRadius))
    }
}

// MARK: - Button press feedback

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Section Header Style

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            Text(title)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .tracking(-0.7)
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
