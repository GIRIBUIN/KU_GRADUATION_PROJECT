import Foundation
import SQLite3
import WidgetKit
import UserNotifications

struct KuWidgetTask: Identifiable {
    let id: String
    let title: String
    let due: Date?
    let status: String
    let origin: String
    var completed: Bool { status == "completed" }
}

enum KuWidgetStoreError: LocalizedError {
    case groupUnavailable, setupRequired, database(String), changed
    var errorDescription: String? {
        switch self {
        case .groupUnavailable: return "App Group 서명 설정을 확인해주세요."
        case .setupRequired: return "앱을 한 번 열어 초기 설정을 마쳐주세요."
        case .database: return "일정을 읽거나 저장하지 못했습니다. 잠금 해제 후 다시 시도해주세요."
        case .changed: return "다른 곳에서 변경된 일정입니다. 위젯을 새로고침해주세요."
        }
    }
}

enum KuWidgetStore {
    static var group: String {
        let configured = Bundle.main.object(forInfoDictionaryKey: "KuWidgetAppGroup") as? String ?? "group.com.example.kuTaskManagement"
        // AltStore re-signs both targets with the installer's team-specific group.
        // Its official re-signing operation records those groups in ALTAppGroups.
        let resigned = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] ?? []
        return resigned.first { $0.contains(configured) } ?? configured
    }
    static var defaults: UserDefaults { UserDefaults(suiteName: group)! }
    static func container() throws -> URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            throw KuWidgetStoreError.groupUnavailable
        }
        return url
    }
    static func databaseURL() throws -> URL { try container().appendingPathComponent("ku_task_management.sqlite") }

    /// SQLite backup includes uncheckpointed WAL pages. Never copy a live .sqlite file alone.
    static func prepareDatabase(source: String) throws -> String {
        let destination = try databaseURL()
        guard !FileManager.default.fileExists(atPath: destination.path) else { return destination.path }
        if FileManager.default.fileExists(atPath: source) && source != destination.path {
            var from: OpaquePointer?, to: OpaquePointer?
            guard sqlite3_open_v2(source, &from, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
                if let from = from { sqlite3_close(from) }
                throw KuWidgetStoreError.database("migration source")
            }
            defer { sqlite3_close(from) }
            let temporary = destination.appendingPathExtension("migration")
            defer { try? FileManager.default.removeItem(at: temporary) }
            guard sqlite3_open_v2(temporary.path, &to, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
                if let to = to { sqlite3_close(to) }
                throw KuWidgetStoreError.database("migration destination")
            }
            guard let backup = sqlite3_backup_init(to, "main", from, "main") else {
                sqlite3_close(to); throw KuWidgetStoreError.database("backup")
            }
            sqlite3_busy_timeout(to, 5000)
            let copied = sqlite3_backup_step(backup, -1)
            let finished = sqlite3_backup_finish(backup)
            sqlite3_close(to)
            guard copied == SQLITE_DONE && finished == SQLITE_OK else { throw KuWidgetStoreError.database("backup failed") }
            try FileManager.default.moveItem(at: temporary, to: destination)
            // Retain the private source as a recovery copy; future writes use only the App Group DB.
        }
        return destination.path
    }

    private static func withDatabase<T>(_ action: (OpaquePointer) throws -> T) throws -> T {
        let path = try databaseURL().path
        guard FileManager.default.fileExists(atPath: path) else { throw KuWidgetStoreError.setupRequired }
        var handle: OpaquePointer?
        guard sqlite3_open_v2(path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK, let db = handle else {
            if let handle = handle { sqlite3_close(handle) }
            throw KuWidgetStoreError.database("open")
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 5000)
        var version: OpaquePointer?
        guard sqlite3_prepare_v2(db, "PRAGMA user_version", -1, &version, nil) == SQLITE_OK else { throw KuWidgetStoreError.database("schema") }
        let step = sqlite3_step(version)
        let supported = step == SQLITE_ROW && sqlite3_column_int(version, 0) == 5
        sqlite3_finalize(version)
        guard supported else { throw KuWidgetStoreError.setupRequired }
        return try action(db)
    }

    static func tasks() throws -> [KuWidgetTask] {
        try withDatabase { db in
            var query: OpaquePointer?
            guard sqlite3_prepare_v2(db, "SELECT id,title,due_date,status,origin FROM tasks WHERE status IN ('active','completed') ORDER BY due_date IS NULL,due_date,sort_order", -1, &query, nil) == SQLITE_OK else { throw KuWidgetStoreError.database("query") }
            defer { sqlite3_finalize(query) }
            var result: [KuWidgetTask] = []
            var status = sqlite3_step(query)
            while status == SQLITE_ROW {
                func text(_ column: Int32) -> String { sqlite3_column_text(query, column).map { String(cString: $0) } ?? "" }
                result.append(KuWidgetTask(id: text(0), title: text(1),
                    due: sqlite3_column_type(query, 2) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double(query, 2)),
                    status: text(3), origin: text(4)))
                status = sqlite3_step(query)
            }
            guard status == SQLITE_DONE else { throw KuWidgetStoreError.database("read") }
            return result
        }
    }

    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    private static func execute(_ db: OpaquePointer, _ sql: String, _ arguments: [Any?] = []) throws {
        var query: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK else { throw KuWidgetStoreError.database("prepare") }
        defer { sqlite3_finalize(query) }
        for (index, value) in arguments.enumerated() {
            let position = Int32(index + 1)
            if let string = value as? String { sqlite3_bind_text(query, position, string, -1, transient) }
            else if let number = value as? Int64 { sqlite3_bind_int64(query, position, number) }
            else if let number = value as? Double { sqlite3_bind_double(query, position, number) }
            else { sqlite3_bind_null(query, position) }
        }
        guard sqlite3_step(query) == SQLITE_DONE else { throw KuWidgetStoreError.database("write") }
    }

    static func changeStatus(id: String, delete: Bool = false) throws {
        try withDatabase { db in
            try execute(db, "BEGIN IMMEDIATE")
            do {
                let stamp = Int64(Date().timeIntervalSince1970)
                try execute(db, """
                    UPDATE tasks SET status = \(delete ? "'deleted'" : "CASE status WHEN 'active' THEN 'completed' ELSE 'active' END"),
                    completed_at = CASE WHEN ? = 'delete' THEN completed_at WHEN status = 'active' THEN ? ELSE NULL END,
                    deleted_at = CASE WHEN ? = 'delete' THEN ? ELSE NULL END, updated_at = ?
                    WHERE id = ? AND status IN ('active','completed')
                    """, [delete ? "delete" : "toggle", stamp, delete ? "delete" : "toggle", stamp, stamp, id])
                guard sqlite3_changes(db) == 1 else { throw KuWidgetStoreError.changed }
                try execute(db, "UPDATE notification_settings SET scheduled_at = NULL WHERE task_id = ?", [id])
                try execute(db, "COMMIT")
            } catch { try? execute(db, "ROLLBACK"); throw error }
        }
        // Match Flutter's UTF-16 notification ID; do not leave a completed task's alarm active.
        var hash: Int64 = 0
        for code in id.utf16 { hash = (hash * 31 + Int64(code)) & 0x7fffffff }
        let request = String(hash == 0 ? 1 : hash)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [request])
        if !delete { restoreReminder(id: id, request: request) }
        changed()
    }

    private static func restoreReminder(id: String, request: String) {
        let reminder: (String, Double)? = try? withDatabase { db -> (String, Double)? in
            var query: OpaquePointer?
            guard sqlite3_prepare_v2(db, """
                SELECT t.title, t.due_date - n.days_before_due * 60 FROM tasks t
                JOIN notification_settings n ON n.task_id = t.id
                WHERE t.id = ? AND t.status = 'active' AND n.enabled = 1 AND t.due_date IS NOT NULL
                """, -1, &query, nil) == SQLITE_OK else { throw KuWidgetStoreError.database("reminder") }
            defer { sqlite3_finalize(query) }
            sqlite3_bind_text(query, 1, id, -1, transient)
            guard sqlite3_step(query) == SQLITE_ROW, let title = sqlite3_column_text(query, 0) else { return nil }
            return (String(cString: title), sqlite3_column_double(query, 1))
        }
        guard let reminder = reminder, reminder.1 > Date().timeIntervalSince1970 else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            let content = UNMutableNotificationContent()
            content.title = "KU Todo"; content.body = "\(reminder.0) 마감 알림"
            content.sound = .default; content.userInfo = ["payload": id]
            let delay = reminder.1 - Date().timeIntervalSince1970
            guard delay > 0 else { return }
            center.add(UNNotificationRequest(identifier: request, content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)), withCompletionHandler: nil)
        }
    }

    static func quickAdd(title: String, day: String) throws {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw KuWidgetStoreError.changed }
        let parts = day.split(separator: "-").compactMap { Int($0) }
        let calendar = Calendar.current
        let chosen = parts.count == 3 ? calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 23, minute: 59)) : nil
        let due = chosen ?? calendar.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!
        try withDatabase { db in
            try execute(db, "BEGIN IMMEDIATE")
            do {
                let stamp = Int64(Date().timeIntervalSince1970)
                try execute(db, """
                    INSERT INTO tasks(id,origin,status,title,due_date,memo,created_at,updated_at,sort_order)
                    VALUES(?,'personal','active',?,?,'',?,?,(SELECT COALESCE(MAX(sort_order),-1)+1 FROM tasks))
                    """, [UUID().uuidString, clean, Int64(due.timeIntervalSince1970), stamp, stamp])
                try execute(db, "COMMIT")
            } catch { try? execute(db, "ROLLBACK"); throw error }
        }
        changed()
    }

    static func changed() {
        defaults.set(true, forKey: "widget_refresh_required")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
