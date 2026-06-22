import SwiftUI

struct StartseiteFamilieView: View {
    @Binding var mode: AppMode
    @Binding var selectedTab: TabItem
    @EnvironmentObject var store: DataStore

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_AT")
        f.dateFormat = "EEEE, d. MMMM"
        return f.string(from: .now)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textSecondary)
                        Text("Familien-Übersicht").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        StatusDot(color: AppTheme.accentPurple)
                        StatusDot(color: AppTheme.accentBlue)
                    }
                }
                .padding(.top, 8)

                // Family overview (connects shared areas)
                familyOverview

                // Shared appointments
                sharedAppointments

                // Reminders + Shopping
                HStack(alignment: .top, spacing: 14) {
                    sharedReminders
                    shoppingPreview
                }

                // Shared notes
                sharedNotes

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Family Overview

    private var familyOverview: some View {
        let upcomingCount = store.upcomingEventOccurrences(store.familyEvents, from: Date(), days: 30, limit: 50).count
        let openReminders = store.familyReminders.filter { !$0.isCompleted }.count
        let totalShopping = store.shoppingItems.count
        let checkedShopping = store.shoppingItems.filter { $0.isChecked }.count
        let openShopping = totalShopping - checkedShopping
        let notesCount = store.familyNotes.count
        let shoppingProgress = totalShopping == 0 ? 0 : Double(checkedShopping) / Double(totalShopping)

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Familien-Überblick")
            HStack(spacing: 18) {
                CircularProgressRing(progress: shoppingProgress,
                                     color: AppTheme.accentPurple,
                                     centerTop: "\(checkedShopping)/\(totalShopping)",
                                     centerBottom: "Einkauf")
                VStack(spacing: 12) {
                    MiniStat(label: "Termine demnächst", value: "\(upcomingCount)", color: AppTheme.accentPurple)
                    MiniStat(label: "Offene Erinnerungen", value: "\(openReminders)", color: AppTheme.accentBlue)
                    MiniStat(label: "Einkauf offen", value: "\(openShopping)", color: AppTheme.accentAmber)
                    MiniStat(label: "Notizen", value: "\(notesCount)", color: AppTheme.accentGreen)
                }
            }
        }
        .glassCard()
    }

    private var sharedAppointments: some View {
        let upcoming = store.upcomingEventOccurrences(store.familyEvents, from: Date(), days: 60, limit: 3)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Gemeinsame Termine")
            if upcoming.isEmpty {
                Text("Noch keine Termine").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                VStack(spacing: 8) {
                    ForEach(upcoming) { occ in
                        HStack(spacing: 12) {
                            Rectangle().fill(AppTheme.accentPurple).frame(width: 3, height: 38).clipShape(Capsule())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(occ.event.title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                                Text(eventLabel(occ.event, occ.date)).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(AppTheme.glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                    }
                }
            }
        }
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .kalender } }
    }

    private var sharedReminders: some View {
        let open = store.sortedReminders(store.familyReminders.filter { !$0.isCompleted })
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Erinnerungen")
            if open.isEmpty {
                Text("Alles erledigt").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(open.prefix(3)) { r in
                        HStack(spacing: 10) {
                            Button { store.toggleReminder(id: r.id) } label: {
                                Image(systemName: "circle").font(.system(size: 15)).foregroundColor(AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            Text(r.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .erinnerungen } }
    }

    private var shoppingPreview: some View {
        let open = store.shoppingItems.filter { !$0.isChecked }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Einkauf")
            if open.isEmpty {
                Text("Liste leer").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(open.prefix(3)) { item in
                        HStack(spacing: 10) {
                            Button { store.toggleShoppingItem(id: item.id) } label: {
                                Image(systemName: "circle").font(.system(size: 15)).foregroundColor(AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            Text(item.name).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Spacer()
                            if !item.quantity.isEmpty {
                                Text(item.quantity).font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .tracker } }
    }

    private var sharedNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Gemeinsame Notizen")
            if store.familyNotes.isEmpty {
                Text("Noch keine Notizen").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                HStack(spacing: 12) {
                    ForEach(store.familyNotes.prefix(2)) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Text(note.body).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary).lineLimit(2)
                            Spacer()
                            Text(note.date.deDayMonth).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                        .background(AppTheme.glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
        .onTapGesture { withAnimation { selectedTab = .notizen } }
    }

    private func eventLabel(_ event: CalendarEvent, _ date: Date) -> String {
        let day = date.deWeekdayDayMonth
        return event.hasTime ? "\(day), \(date.deTime)" : day
    }
}
