import SwiftUI

// MARK: - App State

enum AppMode: String, CaseIterable {
    case persoenlich = "Persönlich"
    case familie = "Familie"
}

enum TabItem: Int, CaseIterable {
    case startseite
    case kalender
    case erinnerungen
    case notizen
    case tracker

    func label(for mode: AppMode) -> String {
        switch self {
        case .startseite:   return "Startseite"
        case .kalender:     return "Kalender"
        case .erinnerungen: return "Erinnerungen"
        case .notizen:      return "Notizen"
        case .tracker:      return mode == .persoenlich ? "Tracker" : "Liste"
        }
    }

    func icon(for mode: AppMode) -> String {
        switch self {
        case .startseite:   return "house.fill"
        case .kalender:     return "calendar"
        case .erinnerungen: return "bell.fill"
        case .notizen:      return "note.text"
        case .tracker:      return mode == .persoenlich ? "chart.bar.fill" : "list.bullet"
        }
    }
}

// MARK: - Recurrence

enum Recurrence: String, Codable, CaseIterable, Identifiable {
    case none, daily, weekly, monthly, yearly
    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:    return "Einmalig"
        case .daily:   return "Täglich"
        case .weekly:  return "Wöchentlich"
        case .monthly: return "Monatlich"
        case .yearly:  return "Jährlich"
        }
    }
    var short: String {
        switch self {
        case .none:    return ""
        case .daily:   return "Täglich"
        case .weekly:  return "Wöchentl."
        case .monthly: return "Monatl."
        case .yearly:  return "Jährl."
        }
    }
}

// MARK: - Calendar Event (supports recurrence)

struct CalendarEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date          // first occurrence, includes time of day
    var hasTime: Bool = true
    var isFamily: Bool = false
    var recurrence: Recurrence = .none

    enum CodingKeys: String, CodingKey { case id, title, date, hasTime, isFamily, recurrence }

    init(id: UUID = UUID(), title: String, date: Date, hasTime: Bool = true,
         isFamily: Bool = false, recurrence: Recurrence = .none) {
        self.id = id; self.title = title; self.date = date
        self.hasTime = hasTime; self.isFamily = isFamily; self.recurrence = recurrence
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        date = (try? c.decode(Date.self, forKey: .date)) ?? Date()
        hasTime = (try? c.decode(Bool.self, forKey: .hasTime)) ?? true
        isFamily = (try? c.decode(Bool.self, forKey: .isFamily)) ?? false
        recurrence = (try? c.decode(Recurrence.self, forKey: .recurrence)) ?? .none
    }

    /// Concrete datetime if an occurrence of this event falls on `day`, else nil.
    func occurrence(on day: Date, calendar cal: Calendar = .current) -> Date? {
        let dayStart = cal.startOfDay(for: day)
        let baseStart = cal.startOfDay(for: date)

        let matches: Bool
        if dayStart < baseStart {
            matches = false
        } else {
            switch recurrence {
            case .none:    matches = cal.isDate(date, inSameDayAs: day)
            case .daily:   matches = true
            case .weekly:  matches = cal.component(.weekday, from: date) == cal.component(.weekday, from: day)
            case .monthly: matches = cal.component(.day, from: date) == cal.component(.day, from: day)
            case .yearly:  matches = cal.component(.day, from: date) == cal.component(.day, from: day)
                                  && cal.component(.month, from: date) == cal.component(.month, from: day)
            }
        }
        guard matches else { return nil }
        let t = cal.dateComponents([.hour, .minute], from: date)
        return cal.date(bySettingHour: t.hour ?? 0, minute: t.minute ?? 0, second: 0, of: day)
    }
}

// A concrete dated instance of a (possibly recurring) event.
struct EventOccurrence: Identifiable {
    let id: String
    let event: CalendarEvent
    let date: Date
}

// MARK: - Reminder (supports recurrence)

struct Reminder: Identifiable, Codable {
    var id = UUID()
    var title: String
    var dueDate: Date? = nil
    var isCompleted: Bool = false
    var isFamily: Bool = false
    var recurrence: Recurrence = .none

    enum CodingKeys: String, CodingKey { case id, title, dueDate, isCompleted, isFamily, recurrence }

    init(id: UUID = UUID(), title: String, dueDate: Date? = nil, isCompleted: Bool = false,
         isFamily: Bool = false, recurrence: Recurrence = .none) {
        self.id = id; self.title = title; self.dueDate = dueDate
        self.isCompleted = isCompleted; self.isFamily = isFamily; self.recurrence = recurrence
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        dueDate = try? c.decode(Date.self, forKey: .dueDate)
        isCompleted = (try? c.decode(Bool.self, forKey: .isCompleted)) ?? false
        isFamily = (try? c.decode(Bool.self, forKey: .isFamily)) ?? false
        recurrence = (try? c.decode(Recurrence.self, forKey: .recurrence)) ?? .none
    }

    /// Next due date one cycle after the current one (for repeating reminders).
    func nextDue(calendar cal: Calendar = .current) -> Date? {
        guard let due = dueDate else { return nil }
        switch recurrence {
        case .none:    return nil
        case .daily:   return cal.date(byAdding: .day, value: 1, to: due)
        case .weekly:  return cal.date(byAdding: .weekOfYear, value: 1, to: due)
        case .monthly: return cal.date(byAdding: .month, value: 1, to: due)
        case .yearly:  return cal.date(byAdding: .year, value: 1, to: due)
        }
    }
}

// MARK: - Note

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var date: Date = Date()
    var isFamily: Bool = false
}

// MARK: - Shopping Item

struct ShoppingItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var quantity: String = ""
    var isChecked: Bool = false
}

// MARK: - Clean Task (interval-based maintenance)

struct CleanTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var intervalDays: Int = 7
    var lastDone: Date?

    enum CodingKeys: String, CodingKey { case id, title, intervalDays, lastDone }

    init(id: UUID = UUID(), title: String, intervalDays: Int = 7, lastDone: Date? = nil) {
        self.id = id; self.title = title; self.intervalDays = intervalDays; self.lastDone = lastDone
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        intervalDays = (try? c.decode(Int.self, forKey: .intervalDays)) ?? 7
        lastDone = try? c.decode(Date.self, forKey: .lastDone)
    }

    func daysSinceDone(_ now: Date = Date(), cal: Calendar = .current) -> Int? {
        guard let last = lastDone else { return nil }
        return cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: now)).day
    }
    func isDue(_ now: Date = Date()) -> Bool {
        guard let d = daysSinceDone(now) else { return true }
        return d >= intervalDays
    }
    // negative = overdue by N days, 0 = due today, positive = days remaining
    func daysUntilDue(_ now: Date = Date()) -> Int {
        guard let d = daysSinceDone(now) else { return 0 }
        return intervalDays - d
    }
    func cycleProgress(_ now: Date = Date()) -> Double {
        guard let d = daysSinceDone(now) else { return 0 }
        return max(0, min(1, 1 - Double(d) / Double(max(1, intervalDays))))
    }
}

// MARK: - Habit

struct Habit: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isDone: Bool = false
    var streak: Int = 0
    var lastDoneDate: Date?
}

// MARK: - Backup Payload (full data snapshot for export/import)

struct BackupPayload: Codable {
    var version: Int = 2
    var exportedAt: Date = Date()
    var events: [CalendarEvent]
    var reminders: [Reminder]
    var notes: [Note]
    var shoppingItems: [ShoppingItem]
    var cleanTasks: [CleanTask]
    var habits: [Habit]
    var prayerDone: [String: Bool]
}

// MARK: - Prayer Slot (built live from PrayerData, not stored)

struct PrayerSlot: Identifiable {
    let id: String
    let name: String
    let germanName: String
    let time: Date
    var isDone: Bool
    var isNext: Bool
    let isTrackable: Bool
}

// MARK: - Seed Data (first launch only)

struct SeedData {
    static let events: [CalendarEvent] = [
        CalendarEvent(title: "Zahnarzt", date: at(9, 30, plusDays: 2)),
        CalendarEvent(title: "Sport", date: at(18, 0, plusDays: 1), recurrence: .weekly),
        CalendarEvent(title: "Familienessen", date: at(19, 0, plusDays: 3), isFamily: true)
    ]

    static let reminders: [Reminder] = [
        Reminder(title: "Medikamente nehmen", dueDate: at(8, 0, plusDays: 0), recurrence: .daily),
        Reminder(title: "Rechnung bezahlen", dueDate: at(12, 0, plusDays: 1)),
        Reminder(title: "Elternabend vorbereiten", isFamily: true)
    ]

    static let notes: [Note] = [
        Note(title: "Gedanken", body: "Heute war ein guter Tag...", date: .now),
        Note(title: "Urlaubsplanung", body: "Wohin soll die Reise gehen?", date: .now, isFamily: true)
    ]

    static let shoppingItems: [ShoppingItem] = [
        ShoppingItem(name: "Milch", quantity: "2 Liter"),
        ShoppingItem(name: "Brot", quantity: "1 Laib"),
        ShoppingItem(name: "Tomaten", quantity: "500g")
    ]

    static let cleanTasks: [CleanTask] = [
        CleanTask(title: "Badezimmer putzen", intervalDays: 7,  lastDone: at(0, 0, plusDays: -9)),
        CleanTask(title: "Staubsaugen",       intervalDays: 3,  lastDone: at(0, 0, plusDays: -1)),
        CleanTask(title: "Küche wischen",     intervalDays: 2,  lastDone: at(0, 0, plusDays: -1)),
        CleanTask(title: "Fenster putzen",    intervalDays: 30, lastDone: at(0, 0, plusDays: -14))
    ]

    static let habits: [Habit] = [
        Habit(title: "Sport"),
        Habit(title: "Quran lesen"),
        Habit(title: "Wasser 2L"),
        Habit(title: "Journaling")
    ]

    private static func at(_ h: Int, _ m: Int, plusDays d: Int) -> Date {
        let cal = Calendar.current
        let base = cal.date(byAdding: .day, value: d, to: .now) ?? .now
        return cal.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
    }
}
