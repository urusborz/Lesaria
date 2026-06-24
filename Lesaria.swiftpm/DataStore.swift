import SwiftUI

class DataStore: ObservableObject {

    // MARK: - Published Data

    @Published var events: [CalendarEvent] = []
    @Published var reminders: [Reminder] = []
    @Published var notes: [Note] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var withdrawalItems: [WithdrawalItem] = []
    @Published var habits: [Habit] = []

    // Prayer done-state, keyed "yyyy-MM-dd|Fajr". Times themselves come from PrayerData.
    @Published var prayerDone: [String: Bool] = [:]

    // Whether daily prayer-time notifications are enabled.
    @Published var prayerNotificationsEnabled: Bool = false

    @Published var appAppearance: AppAppearance = .dark
    @Published var appAccentTheme: AppAccentTheme = .ocean
    @Published var displayName: String = ""
    @Published var isSyncing: Bool = false
    @Published var syncStatusMessage: String = ""
    @Published var lastSupabaseSyncAt: Date?
    @Published var authSession: SupabaseAuthSession?
    @Published var isAuthenticating: Bool = false
    @Published var authStatusMessage: String = ""

    private var pendingSupabasePush: Task<Void, Never>?
    private var isApplyingRemoteSnapshot = false
    private let authSessionKey = "supabaseAuthSession"

    var isAuthenticated: Bool {
        authSession != nil
    }

    // MARK: - Init

    init() {
        loadAuthSession()
        load()
        resetHabitsIfNewDay()
        refreshSessionIfNeededThenSync()
    }

    // MARK: - Computed: Personal / Family splits (sorted)

    var personalEvents: [CalendarEvent]  { events.filter { !$0.isFamily }.sorted { $0.date < $1.date } }
    var familyEvents: [CalendarEvent]    { events.filter { $0.isFamily }.sorted { $0.date < $1.date } }
    var personalReminders: [Reminder]    { reminders.filter { !$0.isFamily } }
    var familyReminders: [Reminder]      { reminders.filter { $0.isFamily } }
    var personalNotes: [Note]            { notes.filter { !$0.isFamily }.sorted { $0.date > $1.date } }
    var familyNotes: [Note]              { notes.filter { $0.isFamily }.sorted { $0.date > $1.date } }

    // MARK: - Events

    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        save()
    }

    func updateEvent(_ event: CalendarEvent) {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
            save()
        }
    }

    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
        save()
    }

    // MARK: - Event occurrences (recurrence expansion)

    func eventOccurrences(_ list: [CalendarEvent], on day: Date) -> [EventOccurrence] {
        let cal = Calendar.current
        return list.compactMap { e -> EventOccurrence? in
            guard let d = e.occurrence(on: day, calendar: cal) else { return nil }
            return EventOccurrence(id: "\(e.id.uuidString)-\(Int(d.timeIntervalSince1970))", event: e, date: d)
        }
        .sorted { $0.date < $1.date }
    }

    func upcomingEventOccurrences(_ list: [CalendarEvent], from start: Date = Date(),
                                  days: Int = 60, limit: Int = 20) -> [EventOccurrence] {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        var result: [EventOccurrence] = []
        for offset in 0..<days {
            guard let day = cal.date(byAdding: .day, value: offset, to: startDay) else { break }
            for occ in eventOccurrences(list, on: day) where occ.date >= start {
                result.append(occ)
                if result.count >= limit { return result }
            }
        }
        return result
    }

    func dayHasItems(_ list: [CalendarEvent], _ datedReminders: [Reminder], on day: Date) -> Bool {
        let cal = Calendar.current
        if list.contains(where: { $0.occurrence(on: day, calendar: cal) != nil }) { return true }
        return datedReminders.contains { r in
            guard let due = r.dueDate else { return false }
            return cal.isDate(due, inSameDayAs: day)
        }
    }

    // MARK: - Reminders

    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        NotificationManager.shared.scheduleReminder(reminder)
        save()
    }

    func updateReminder(_ reminder: Reminder) {
        if let i = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[i] = reminder
            NotificationManager.shared.scheduleReminder(reminder)
            save()
        }
    }

    func deleteCompletedReminders(isFamily: Bool) {
        reminders.removeAll { $0.isCompleted && $0.isFamily == isFamily }
        save()
    }

    func toggleReminder(id: UUID) {
        Haptics.tap()
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        // Repeating reminder being completed → roll forward instead of marking done.
        if !reminders[i].isCompleted,
           reminders[i].recurrence != .none,
           let next = reminders[i].nextDue() {
            reminders[i].dueDate = next
            reminders[i].isCompleted = false
        } else {
            reminders[i].isCompleted.toggle()
        }
        NotificationManager.shared.scheduleReminder(reminders[i])  // cancels if completed
        save()
    }

    func deleteReminder(id: UUID) {
        reminders.removeAll { $0.id == id }
        NotificationManager.shared.cancelReminder(id: id)
        save()
    }

    // Sorted: undated last, otherwise by due date ascending.
    func sortedReminders(_ list: [Reminder]) -> [Reminder] {
        list.sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (x?, y?): return x < y
            case (_?, nil):    return true
            case (nil, _?):    return false
            default:           return false
            }
        }
    }

    // MARK: - Notes

    func addNote(_ note: Note) {
        notes.insert(note, at: 0)
        save()
    }

    func updateNote(_ note: Note) {
        if let i = notes.firstIndex(where: { $0.id == note.id }) {
            notes[i] = note
            save()
        }
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    // MARK: - Shopping

    func addShoppingItem(_ item: ShoppingItem) {
        shoppingItems.append(item)
        save()
    }

    func updateShoppingItem(_ item: ShoppingItem) {
        if let i = shoppingItems.firstIndex(where: { $0.id == item.id }) {
            shoppingItems[i] = item
            save()
        }
    }

    func toggleShoppingItem(id: UUID) {
        Haptics.tap()
        if let i = shoppingItems.firstIndex(where: { $0.id == id }) {
            shoppingItems[i].isChecked.toggle()
            save()
        }
    }

    func deleteShoppingItem(id: UUID) {
        shoppingItems.removeAll { $0.id == id }
        save()
    }

    func deleteCheckedShoppingItems() {
        shoppingItems.removeAll { $0.isChecked }
        save()
    }

    // MARK: - Withdrawal

    func addWithdrawalItem(_ item: WithdrawalItem) {
        withdrawalItems.append(item)
        save()
    }

    func updateWithdrawalItem(_ item: WithdrawalItem) {
        if let i = withdrawalItems.firstIndex(where: { $0.id == item.id }) {
            withdrawalItems[i] = item
            save()
        }
    }

    func deleteWithdrawalItem(id: UUID) {
        withdrawalItems.removeAll { $0.id == id }
        save()
    }

    func logRelapse(id: UUID, resetStreak: Bool) {
        guard let i = withdrawalItems.firstIndex(where: { $0.id == id }) else { return }
        withdrawalItems[i].relapses.insert(RelapseEntry(date: Date(), resetStreak: resetStreak), at: 0)
        if resetStreak {
            withdrawalItems[i].startDate = Date()
        }
        Haptics.warning()
        save()
    }

    // MARK: - Habits

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        save()
    }

    func updateHabit(_ habit: Habit) {
        if let i = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[i] = habit
            save()
        }
    }

    func toggleHabit(id: UUID) {
        Haptics.tap()
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        if habits[i].isDone {
            // Undo today's completion.
            habits[i].isDone = false
            habits[i].streak = max(0, habits[i].streak - 1)
            habits[i].lastDoneDate = habits[i].streak > 0 ? yesterday : nil
        } else {
            // Complete today: continue streak if yesterday was done, else start new.
            habits[i].isDone = true
            if let last = habits[i].lastDoneDate, cal.isDate(last, inSameDayAs: yesterday) {
                habits[i].streak += 1
            } else {
                habits[i].streak = 1
            }
            habits[i].lastDoneDate = today
        }
        save()
    }

    func deleteHabit(id: UUID) {
        habits.removeAll { $0.id == id }
        save()
    }

    // MARK: - Prayers (live from PrayerData + stored done-state)

    func prayerSlots(now: Date = Date()) -> [PrayerSlot] {
        let raw = PrayerEngine.rawTimes(for: now)
        let key = PrayerEngine.dateKey(now)
        var slots: [PrayerSlot] = []
        for (i, m) in PrayerEngine.meta.enumerated() where i < raw.count {
            let time = PrayerEngine.dateFor(raw[i], on: now)
            let done = prayerDone["\(key)|\(m.name)"] ?? false
            slots.append(PrayerSlot(id: m.name, name: m.name, germanName: m.german,
                                    time: time, isDone: done, isNext: false, isTrackable: m.trackable))
        }
        if let nextIdx = slots.firstIndex(where: { $0.isTrackable && $0.time > now }) {
            slots[nextIdx].isNext = true
        }
        return slots
    }

    // Returns the upcoming prayer, rolling over to tomorrow's Fajr after Isha.
    func nextPrayer(now: Date = Date()) -> (name: String, germanName: String, date: Date) {
        let slots = prayerSlots(now: now)
        if let s = slots.first(where: { $0.isTrackable && $0.time > now }) {
            return (s.name, s.germanName, s.time)
        }
        let tomorrow = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: now) ?? now
        let raw = PrayerEngine.rawTimes(for: tomorrow)
        return ("Fajr", "Morgengebet", PrayerEngine.dateFor(raw[0], on: tomorrow))
    }

    func togglePrayer(name: String, on date: Date = Date()) {
        Haptics.tap()
        let key = "\(PrayerEngine.dateKey(date))|\(name)"
        prayerDone[key] = !(prayerDone[key] ?? false)
        save()
    }

    func setPrayerNotifications(_ enabled: Bool) {
        prayerNotificationsEnabled = enabled
        NotificationManager.shared.reschedulePrayers(enabled: enabled)
        save()
    }

    func setAppearance(_ appearance: AppAppearance) {
        UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance")
        appAppearance = appearance
        save()
    }

    func setAccentTheme(_ theme: AppAccentTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: "appAccentTheme")
        appAccentTheme = theme
        save()
    }

    func setDisplayName(_ name: String) {
        displayName = name
        save()
    }

    // Called once at app start: request permission and refresh all scheduled notifications.
    func bootstrapNotifications() {
        NotificationManager.shared.requestAuthorization()
        NotificationManager.shared.rescheduleAllReminders(reminders)
        NotificationManager.shared.reschedulePrayers(enabled: prayerNotificationsEnabled)
    }

    // MARK: - Backup (Export / Import)

    private func backupEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }
    private func backupDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func exportJSON() -> String {
        let payload = makeBackupPayload()
        guard let data = try? backupEncoder().encode(payload),
              let str = String(data: data, encoding: .utf8) else { return "" }
        return str
    }

    func exportFileURL() -> URL? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let name = "Lesaria-Backup-\(f.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try exportJSON().data(using: .utf8)?.write(to: url)
            return url
        } catch { return nil }
    }

    @discardableResult
    func importJSON(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8),
              let payload = try? backupDecoder().decode(BackupPayload.self, from: data) else { return false }
        applyBackupPayload(payload)
        save()
        bootstrapNotifications()
        return true
    }

    func signUp(email: String, password: String) {
        Task { await runSignUp(email: email, password: password) }
    }

    func signIn(email: String, password: String) {
        Task { await runSignIn(email: email, password: password) }
    }

    func signOut() {
        authSession = nil
        lastSupabaseSyncAt = nil
        UserDefaults.standard.removeObject(forKey: authSessionKey)
        UserDefaults.standard.removeObject(forKey: "lastSupabaseSyncAt")
        authStatusMessage = ""
        syncStatusMessage = ""
    }

    func syncWithSupabase() {
        Task { await runSupabaseSync() }
    }

    func refreshSessionIfNeededThenSync() {
        Task {
            await refreshSessionIfNeeded()
            await runSupabaseSync()
        }
    }

    @MainActor
    private func runSignUp(email: String, password: String) async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authStatusMessage = ""
        do {
            let session = try await SupabaseAuthService().signUp(email: email, password: password)
            setAuthSession(session)
            authStatusMessage = "Account erstellt."
            await runSupabaseSync()
        } catch {
            authStatusMessage = error.localizedDescription
        }
        isAuthenticating = false
    }

    @MainActor
    private func runSignIn(email: String, password: String) async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authStatusMessage = ""
        do {
            let session = try await SupabaseAuthService().signIn(email: email, password: password)
            setAuthSession(session)
            authStatusMessage = "Angemeldet."
            await runSupabaseSync()
        } catch {
            authStatusMessage = error.localizedDescription
        }
        isAuthenticating = false
    }

    @MainActor
    private func refreshSessionIfNeeded() async {
        guard let session = authSession, session.needsRefresh else { return }
        do {
            let refreshed = try await SupabaseAuthService().refresh(session)
            setAuthSession(refreshed)
        } catch {
            signOut()
            authStatusMessage = "Bitte neu anmelden."
        }
    }

    @MainActor
    private func runSupabasePush() async {
        await refreshSessionIfNeeded()
        guard SupabaseConfig.isConfigured, authSession != nil else { return }
        guard !isSyncing else { return }
        pendingSupabasePush?.cancel()
        isSyncing = true
        syncStatusMessage = "Sync laeuft..."
        do {
            let snapshot = try await supabaseService().upsertSnapshot(makeBackupPayload())
            lastSupabaseSyncAt = snapshot.updatedAt ?? Date()
            save()
            syncStatusMessage = "Sync abgeschlossen."
            Haptics.success()
        } catch {
            syncStatusMessage = error.localizedDescription
            Haptics.warning()
        }
        isSyncing = false
    }

    @MainActor
    private func runSupabaseSync() async {
        await refreshSessionIfNeeded()
        guard SupabaseConfig.isConfigured, authSession != nil else { return }
        guard !isSyncing else { return }
        pendingSupabasePush?.cancel()
        isSyncing = true
        syncStatusMessage = "Sync laeuft..."
        do {
            let remote = try? await supabaseService().fetchSnapshot()
            if let remote, shouldApplyRemoteSnapshot(remote) {
                isApplyingRemoteSnapshot = true
                applyBackupPayload(remote.payload)
                lastSupabaseSyncAt = remote.updatedAt ?? Date()
                save()
                isApplyingRemoteSnapshot = false
                bootstrapNotifications()
                syncStatusMessage = "Remote-Stand geladen."
            } else {
                let snapshot = try await supabaseService().upsertSnapshot(makeBackupPayload())
                lastSupabaseSyncAt = snapshot.updatedAt ?? Date()
                save()
                syncStatusMessage = "Lokaler Stand hochgeladen."
            }
            Haptics.success()
        } catch {
            isApplyingRemoteSnapshot = false
            syncStatusMessage = error.localizedDescription
            Haptics.warning()
        }
        isSyncing = false
    }

    private func shouldApplyRemoteSnapshot(_ snapshot: SupabaseSnapshot) -> Bool {
        guard let remoteUpdatedAt = snapshot.updatedAt else {
            return lastSupabaseSyncAt == nil
        }
        guard let localSyncedAt = lastSupabaseSyncAt else {
            return true
        }
        return remoteUpdatedAt > localSyncedAt
    }

    private func makeBackupPayload() -> BackupPayload {
        BackupPayload(events: events, reminders: reminders, notes: notes,
                      shoppingItems: shoppingItems, withdrawalItems: withdrawalItems,
                      habits: habits, prayerDone: prayerDone)
    }

    private func applyBackupPayload(_ payload: BackupPayload) {
        events = payload.events
        reminders = payload.reminders
        notes = payload.notes
        shoppingItems = payload.shoppingItems
        withdrawalItems = payload.withdrawalItems
        habits = payload.habits
        prayerDone = payload.prayerDone
    }

    private func supabaseService() -> SupabaseSyncService {
        let session = authSession
        return SupabaseSyncService(
            configuration: SupabaseSyncConfiguration(
                projectURL: SupabaseConfig.projectURL,
                anonKey: SupabaseConfig.anonKey,
                accessToken: session?.accessToken ?? "",
                userID: session?.userID ?? ""
            )
        )
    }

    private func scheduleSupabasePush() {
        guard SupabaseConfig.isConfigured, authSession != nil, !isSyncing, !isApplyingRemoteSnapshot else { return }
        pendingSupabasePush?.cancel()
        pendingSupabasePush = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            await runSupabasePush()
        }
    }

    private func setAuthSession(_ session: SupabaseAuthSession) {
        authSession = session
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: authSessionKey)
        }
    }

    private func loadAuthSession() {
        guard let data = UserDefaults.standard.data(forKey: authSessionKey),
              let session = try? JSONDecoder().decode(SupabaseAuthSession.self, from: data) else {
            authSession = nil
            return
        }
        authSession = session
    }

    func prayersDoneCount(on date: Date = Date()) -> Int {
        prayerSlots(now: date).filter { $0.isTrackable && $0.isDone }.count
    }

    // MARK: - Day Reset (habits reset daily)

    private func resetHabitsIfNewDay() {
        let key = "lastHabitResetDate"
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        if let stored = UserDefaults.standard.object(forKey: key) as? Date, stored < today {
            for i in habits.indices {
                habits[i].isDone = false
                // Break the streak if the habit wasn't completed yesterday.
                if let last = habits[i].lastDoneDate {
                    if !cal.isDate(last, inSameDayAs: yesterday) && cal.startOfDay(for: last) < yesterday {
                        habits[i].streak = 0
                    }
                } else {
                    habits[i].streak = 0
                }
            }
            UserDefaults.standard.set(today, forKey: key)
            save()
        } else if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(today, forKey: key)
        }
    }

    // MARK: - Persistence

    private func save() {
        encode(events,        key: "events")
        encode(reminders,     key: "reminders")
        encode(notes,         key: "notes")
        encode(shoppingItems, key: "shoppingItems")
        encode(withdrawalItems, key: "withdrawalItems")
        encode(habits,        key: "habits")
        encode(prayerDone,    key: "prayerDone")
        UserDefaults.standard.set(prayerNotificationsEnabled, forKey: "prayerNotificationsEnabled")
        UserDefaults.standard.set(appAppearance.rawValue, forKey: "appAppearance")
        UserDefaults.standard.set(appAccentTheme.rawValue, forKey: "appAccentTheme")
        UserDefaults.standard.set(displayName, forKey: "displayName")
        UserDefaults.standard.set(lastSupabaseSyncAt, forKey: "lastSupabaseSyncAt")
        scheduleSupabasePush()
    }

    private func load() {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunched")

        events        = decode([CalendarEvent].self, key: "events")        ?? (isFirstLaunch ? SeedData.events : [])
        reminders     = decode([Reminder].self,      key: "reminders")     ?? (isFirstLaunch ? SeedData.reminders : [])
        notes         = decode([Note].self,          key: "notes")         ?? (isFirstLaunch ? SeedData.notes : [])
        shoppingItems = decode([ShoppingItem].self,  key: "shoppingItems") ?? (isFirstLaunch ? SeedData.shoppingItems : [])
        withdrawalItems = decode([WithdrawalItem].self, key: "withdrawalItems") ?? (isFirstLaunch ? SeedData.withdrawalItems : [])
        habits        = decode([Habit].self,         key: "habits")        ?? (isFirstLaunch ? SeedData.habits : [])
        prayerDone    = decode([String: Bool].self,  key: "prayerDone")    ?? [:]
        prayerNotificationsEnabled = UserDefaults.standard.bool(forKey: "prayerNotificationsEnabled")
        appAppearance = AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .dark
        appAccentTheme = AppAccentTheme.storedValue(UserDefaults.standard.string(forKey: "appAccentTheme"))
        displayName = UserDefaults.standard.string(forKey: "displayName") ?? ""
        lastSupabaseSyncAt = UserDefaults.standard.object(forKey: "lastSupabaseSyncAt") as? Date

        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            save()
        }
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
