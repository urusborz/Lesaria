import SwiftUI

// MARK: - Design System

struct AppTheme {
    // Backgrounds
    static let backgroundPrimary = Color(red: 0.024, green: 0.027, blue: 0.035)       // #060607 OLED black
    static let backgroundSecondary = Color(red: 0.047, green: 0.051, blue: 0.063)     // deep charcoal
    static let backgroundTertiary = Color(red: 0.07, green: 0.075, blue: 0.09)        // card background
    static let cardSolid = Color(red: 0.085, green: 0.09, blue: 0.105)                // opaque row card (for swipe)

    // Glass card
    static let glassBackground = Color.white.opacity(0.05)
    static let glassBorder = Color.white.opacity(0.08)
    static let glassHighlight = Color.white.opacity(0.12)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.55)
    static let textTertiary = Color(white: 0.35)

    // Accent colors (used sparingly)
    static let accentBlue = Color(red: 0.28, green: 0.55, blue: 1.0)
    static let accentGreen = Color(red: 0.22, green: 0.85, blue: 0.55)
    static let accentAmber = Color(red: 1.0, green: 0.72, blue: 0.25)
    static let accentPurple = Color(red: 0.65, green: 0.45, blue: 1.0)

    // Separators
    static let separator = Color.white.opacity(0.06)

    // Corner radii
    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 22
    static let radiusXL: CGFloat = 28
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLarge)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
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
