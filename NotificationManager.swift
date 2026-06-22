import Foundation
import UserNotifications

// MARK: - Local Notification Manager
// Handles permission + scheduling for reminders (due dates) and prayer times.
// Purely local notifications — no server, works offline.

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func isDenied(_ completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus == .denied) }
        }
    }

    // MARK: - Reminders

    private func reminderID(_ id: UUID) -> String { "reminder-\(id.uuidString)" }

    func scheduleReminder(_ reminder: Reminder) {
        cancelReminder(id: reminder.id)
        guard let due = reminder.dueDate, !reminder.isCompleted, due > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Erinnerung"
        content.body = reminder.title
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: reminderID(reminder.id), content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder(id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID(id)])
    }

    func rescheduleAllReminders(_ reminders: [Reminder]) {
        for r in reminders { scheduleReminder(r) }
    }

    // MARK: - Prayers (rolling window, capped well below iOS' 64-pending limit)

    func reschedulePrayers(enabled: Bool, now: Date = Date()) {
        // Remove existing prayer notifications first.
        center.getPendingNotificationRequests { [weak self] requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix("prayer-") }
            self?.center.removePendingNotificationRequests(withIdentifiers: ids)
            guard enabled else { return }
            self?.scheduleUpcomingPrayers(count: 40, from: now)
        }
    }

    private func scheduleUpcomingPrayers(count: Int, from now: Date) {
        let cal = Calendar(identifier: .gregorian)
        var scheduled = 0
        var dayOffset = 0

        while scheduled < count && dayOffset < 14 {
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: now) else { break }
            let raw = PrayerEngine.rawTimes(for: day)
            for (i, meta) in PrayerEngine.meta.enumerated() where meta.trackable && i < raw.count {
                let time = PrayerEngine.dateFor(raw[i], on: day)
                guard time > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Gebetszeit"
                content.body = "\(meta.name) · \(time.deTime) Uhr"
                content.sound = .default

                let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: time)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "prayer-\(PrayerEngine.dateKey(day))-\(meta.name)"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))

                scheduled += 1
                if scheduled >= count { break }
            }
            dayOffset += 1
        }
    }
}
