import Foundation

// MARK: - Prayer Engine
// Builds live prayer times for any day from the embedded IZW Vienna 2026 table.

enum PrayerEngine {

    // Order MUST match PrayerData columns: Fajr, Sonnenaufgang, Dhuhr, Asr, Maghrib, Isha
    static let meta: [(name: String, german: String, trackable: Bool)] = [
        ("Fajr",          "Morgengebet",       true),
        ("Sonnenaufgang", "Shuruq",            false),
        ("Dhuhr",         "Mittagsgebet",      true),
        ("Asr",           "Nachmittagsgebet",  true),
        ("Maghrib",       "Abendgebet",        true),
        ("Isha",          "Nachtgebet",        true)
    ]

    // Day-of-year index into PrayerData.daily (0-based), clamped to valid range.
    static func dayIndex(for date: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let doy = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        return min(max(doy - 1, 0), PrayerData.daily.count - 1)
    }

    // Raw "HHmm" strings for a given day (6 values).
    static func rawTimes(for date: Date) -> [String] {
        let line = PrayerData.daily[dayIndex(for: date)]
        return line.split(separator: ",").map(String.init)
    }

    // Build a concrete Date for an "HHmm" string on a given calendar day.
    static func dateFor(_ hhmm: String, on day: Date) -> Date {
        let cal = Calendar(identifier: .gregorian)
        let h = Int(hhmm.prefix(2)) ?? 0
        let m = Int(hhmm.suffix(2)) ?? 0
        return cal.date(bySettingHour: h, minute: m, second: 0, of: day) ?? day
    }

    // Key for storing per-day done state, e.g. "2026-06-22".
    static func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
