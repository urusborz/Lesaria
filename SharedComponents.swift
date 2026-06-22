import SwiftUI
import UIKit

// MARK: - Haptics

enum Haptics {
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - Swipe to Delete (custom, works inside ScrollView)

struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    let content: Content

    @State private var offset: CGFloat = 0
    private let reveal: CGFloat = 80

    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        content
            .background(AppTheme.cardSolid)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
            .offset(x: offset)
            .background(alignment: .trailing) {
                Button {
                    Haptics.warning()
                    withAnimation(.spring(response: 0.3)) { onDelete() }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.onAccent)
                        .frame(width: reveal)
                        .frame(maxHeight: .infinity)
                        .background(Color.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
                }
                .buttonStyle(.plain)
                .opacity(offset < 0 ? 1 : 0)
            }
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onChanged { v in
                        if abs(v.translation.width) > abs(v.translation.height) {
                            offset = min(0, max(v.translation.width, -reveal))
                        }
                    }
                    .onEnded { v in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = (v.translation.width < -reveal / 2) ? -reveal : 0
                        }
                    }
            )
    }
}

// MARK: - Add Button

struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.onAccent)
                .frame(width: 34, height: 34)
                .background(AppTheme.accent)
                .clipShape(Circle())
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(AppTheme.textTertiary)
            .padding(.horizontal, 4)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textTertiary)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Dark Sheet (reusable bottom sheet)

struct DarkSheet<Content: View>: View {
    let title: String
    @Binding var isPresented: Bool
    var detents: Set<PresentationDetent> = [.medium]
    @ViewBuilder let content: Content
    let onSave: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.textTertiary.opacity(0.5))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                content

                HStack(spacing: 12) {
                    Button("Abbrechen") { isPresented = false }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))

                    Button("Speichern") { onSave() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
        }
        .presentationDetents(detents)
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Dark Text Field

struct DarkTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text)
            .placeholder(when: text.isEmpty) {
                Text(placeholder).foregroundColor(AppTheme.textTertiary)
            }
            .font(.system(size: 16))
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.controlBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }
}

// MARK: - Dark Text Editor

struct DarkTextEditor: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(AppTheme.textTertiary)
                    .font(.system(size: 16))
                    .padding(.horizontal, AppTheme.phoneScreenPadding)
                    .padding(.vertical, 18)
            }
            TextEditor(text: $text)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: 100)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .background(AppTheme.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }
}

// MARK: - Toggle Row (for sheets, e.g. "Fälligkeitsdatum")

struct DarkToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.accentBlue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }
}

// MARK: - Item Context Menu (long-press → Bearbeiten / Löschen)

extension View {
    func itemContextMenu(onEdit: (() -> Void)? = nil, onDelete: @escaping () -> Void) -> some View {
        self.contextMenu {
            if let onEdit = onEdit {
                Button { onEdit() } label: { Label("Bearbeiten", systemImage: "pencil") }
            }
            Button(role: .destructive) { onDelete() } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}

// MARK: - Circular Progress Ring (biometric style)

struct CircularProgressRing: View {
    let progress: Double           // 0...1
    var size: CGFloat = 92
    var lineWidth: CGFloat = 9
    var color: Color = AppTheme.accentGreen
    var centerTop: String? = nil
    var centerBottom: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.ringTrack, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
            VStack(spacing: 1) {
                if let centerTop {
                    Text(centerTop).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                }
                if let centerBottom {
                    Text(centerBottom).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Mini Stat (label + value with accent dot)

struct MiniStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Recurrence Picker (chips)

struct RecurrencePicker: View {
    @Binding var selection: Recurrence

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wiederholung")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textTertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Recurrence.allCases) { r in
                        ChipButton(title: r.label, isSelected: selection == r) { selection = r }
                    }
                }
            }
        }
    }
}

// MARK: - Interval Picker (chips, for clean tasks)

struct IntervalPicker: View {
    @Binding var days: Int
    private let options = [1, 3, 7, 14, 30]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intervall")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textTertiary)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { d in
                    ChipButton(title: intervalLabel(d), isSelected: days == d) { days = d }
                }
            }
        }
    }

    private func intervalLabel(_ d: Int) -> String {
        switch d {
        case 1:  return "Täglich"
        case 3:  return "3 Tage"
        case 7:  return "Wöchentl."
        case 14: return "2 Wochen"
        case 30: return "Monatl."
        default: return "\(d) T."
        }
    }
}

// MARK: - Chip Button

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? AppTheme.onAccent : AppTheme.textTertiary)
                .padding(.vertical, 8).padding(.horizontal, 14)
                .background {
                    if isSelected {
                        AppTheme.accent
                    } else {
                        AppTheme.controlBackground
                    }
                }
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? AppTheme.accent.opacity(0.4) : AppTheme.glassBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Denied Banner

struct NotificationDeniedBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accentAmber)
            VStack(alignment: .leading, spacing: 2) {
                Text("Benachrichtigungen deaktiviert")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("In den iOS-Einstellungen aktivieren, um erinnert zu werden.")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Öffnen")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.onAccent)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(AppTheme.accentAmber.opacity(0.85))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.accentAmber.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.accentAmber.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - Status Pill

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - German date helpers

extension Date {
    var deWeekdayDayMonth: String {
        if Calendar.current.isDateInToday(self) { return "Heute" }
        if Calendar.current.isDateInTomorrow(self) { return "Morgen" }
        if Calendar.current.isDateInYesterday(self) { return "Gestern" }
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "EE, d. MMM"
        return f.string(from: self)
    }

    var deTime: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "HH:mm"
        return f.string(from: self)
    }

    var deDayMonth: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "d. MMM"
        return f.string(from: self)
    }
}
