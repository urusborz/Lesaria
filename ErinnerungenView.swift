import SwiftUI

struct ErinnerungenView: View {
    let mode: AppMode
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false
    @State private var editing: Reminder? = nil

    private var list: [Reminder] {
        mode == .persoenlich ? store.personalReminders : store.familyReminders
    }
    private var open: [Reminder]   { store.sortedReminders(list.filter { !$0.isCompleted }) }
    private var done: [Reminder]   { list.filter { $0.isCompleted } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .persoenlich ? "Erinnerungen" : "Gemeinsame Erinnerungen")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("\(open.count) offen · \(done.count) erledigt")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    if !done.isEmpty {
                        Button { store.deleteCompletedReminders(isFamily: mode == .familie) } label: {
                            Text("Erledigt löschen")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textTertiary)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    AddButton { showingAdd = true }
                }
                .padding(.top, 8)

                if !open.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Offen")
                        reminderList(open)
                    }
                }

                if !done.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Erledigt")
                        reminderList(done)
                    }
                }

                if list.isEmpty {
                    EmptyStateView(icon: "bell", text: "Noch keine Erinnerungen")
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingAdd) {
            ReminderSheet(mode: mode, existing: nil, isPresented: $showingAdd)
                .environmentObject(store)
        }
        .sheet(item: $editing) { reminder in
            ReminderSheet(mode: mode, existing: reminder, isPresented: Binding(
                get: { editing != nil },
                set: { if !$0 { editing = nil } }
            ))
            .environmentObject(store)
        }
    }

    private func reminderList(_ items: [Reminder]) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { reminder in
                SwipeToDeleteRow(onDelete: { store.deleteReminder(id: reminder.id) }) {
                    ReminderRow(reminder: reminder).environmentObject(store)
                }
                .itemContextMenu(onEdit: { editing = reminder },
                                 onDelete: { store.deleteReminder(id: reminder.id) })
            }
        }
    }
}

// MARK: - Reminder Row

struct ReminderRow: View {
    let reminder: Reminder
    @EnvironmentObject var store: DataStore

    private var isOverdue: Bool {
        guard let due = reminder.dueDate, !reminder.isCompleted else { return false }
        return due < Date()
    }

    var body: some View {
        HStack(spacing: 14) {
            Button { store.toggleReminder(id: reminder.id) } label: {
                ZStack {
                    Circle()
                        .stroke(reminder.isCompleted ? AppTheme.accentGreen : Color.white.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if reminder.isCompleted {
                        Circle().fill(AppTheme.accentGreen).frame(width: 22, height: 22)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(reminder.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                    .strikethrough(reminder.isCompleted, color: AppTheme.textTertiary)
                if let due = reminder.dueDate {
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar").font(.system(size: 10))
                            Text(dueLabel(due)).font(.system(size: 11, weight: isOverdue ? .semibold : .regular))
                        }
                        .foregroundColor(isOverdue ? AppTheme.accentAmber : AppTheme.textTertiary)
                        if reminder.recurrence != .none {
                            HStack(spacing: 3) {
                                Image(systemName: "repeat").font(.system(size: 9))
                                Text(reminder.recurrence.short).font(.system(size: 11))
                            }
                            .foregroundColor(AppTheme.accentBlue)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func dueLabel(_ date: Date) -> String {
        let day = date.deWeekdayDayMonth
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        if (comps.hour ?? 0) == 0 && (comps.minute ?? 0) == 0 {
            return isOverdue ? "Überfällig · \(day)" : day
        }
        return (isOverdue ? "Überfällig · " : "") + "\(day), \(date.deTime)"
    }
}

// MARK: - Reminder Sheet (Add + Edit)

struct ReminderSheet: View {
    let mode: AppMode
    let existing: Reminder?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore

    @State private var title: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var recurrence: Recurrence

    init(mode: AppMode, existing: Reminder?, isPresented: Binding<Bool>) {
        self.mode = mode
        self.existing = existing
        self._isPresented = isPresented
        _title = State(initialValue: existing?.title ?? "")
        _hasDueDate = State(initialValue: existing?.dueDate != nil)
        _dueDate = State(initialValue: existing?.dueDate ?? Date())
        _recurrence = State(initialValue: existing?.recurrence ?? .none)
    }

    var body: some View {
        DarkSheet(title: existing == nil ? "Neue Erinnerung" : "Erinnerung bearbeiten",
                  isPresented: $isPresented, detents: [.medium, .large]) {
            VStack(spacing: 14) {
                DarkTextField(placeholder: "Erinnerung eingeben...", text: $title)
                DarkToggleRow(title: "Fälligkeitsdatum", isOn: $hasDueDate.animation())
                if hasDueDate {
                    DatePicker("Fällig am", selection: $dueDate)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .tint(AppTheme.accentBlue)
                        .padding(.horizontal, 4)
                    RecurrencePicker(selection: $recurrence)
                }
            }
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            var r = existing ?? Reminder(title: "", isFamily: mode == .familie)
            r.title = title
            r.dueDate = hasDueDate ? dueDate : nil
            r.recurrence = hasDueDate ? recurrence : .none
            if existing == nil { store.addReminder(r) } else { store.updateReminder(r) }
            isPresented = false
        }
    }
}
