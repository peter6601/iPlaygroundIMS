import Foundation

/// App 與 Widget extension 共用的儲存層（透過 App Group）。
/// - 選定的人員名字存在 App Group UserDefaults
/// - 下載到的 schedule.js / corrections.js 原始文字存成 App Group 容器內的檔案
///   （Widget 只讀 cache，不自己連網）
enum SharedStore {

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: IMSShared.appGroupID)
    }

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: IMSShared.appGroupID)
    }

    // MARK: - 選定人員

    private static let selectedPersonKey = "selectedPerson"
    private static let activatedPersonKey = "activatedPerson"

    /// 目前「檢視中」的人（導覽狀態，不代表開啟提醒）。
    static var selectedPerson: String? {
        get { defaults?.string(forKey: selectedPersonKey) }
        set {
            if let newValue { defaults?.set(newValue, forKey: selectedPersonKey) }
            else { defaults?.removeObject(forKey: selectedPersonKey) }
        }
    }

    /// 已「開啟提醒」並鎖定為本人的人。Widget / 通知 / Live Activity 都以此為準。
    static var activatedPerson: String? {
        get { defaults?.string(forKey: activatedPersonKey) }
        set {
            if let newValue { defaults?.set(newValue, forKey: activatedPersonKey) }
            else { defaults?.removeObject(forKey: activatedPersonKey) }
        }
    }

    // MARK: - 資料快照（原始 JS 文字）

    private static let lastFetchedKey = "lastFetched"

    static var lastFetched: Date? {
        get {
            let t = defaults?.double(forKey: lastFetchedKey) ?? 0
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set { defaults?.set(newValue?.timeIntervalSince1970 ?? 0, forKey: lastFetchedKey) }
    }

    static func cachedJS(_ kind: ScheduleFileKind) -> String? {
        guard let url = containerURL?.appendingPathComponent(kind.cacheFileName) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    static func writeCachedJS(_ text: String, kind: ScheduleFileKind) {
        guard let url = containerURL?.appendingPathComponent(kind.cacheFileName) else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - 已解析快照（供 Widget 純原生讀取，不需執行 JS）

    private static let snapshotFileName = "schedule.snapshot.json"

    /// App 端解析完成後呼叫，把結果寫成 JSON 給 Widget 讀。
    static func writeSnapshot(_ schedule: OfflineSchedule) {
        guard let url = containerURL?.appendingPathComponent(snapshotFileName),
              let data = try? JSONEncoder().encode(schedule) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Widget（或任何不想跑 JSCore 的地方）讀取已解析的排班。
    static func readSnapshot() -> OfflineSchedule? {
        guard let url = containerURL?.appendingPathComponent(snapshotFileName),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(OfflineSchedule.self, from: data)
    }
}

enum ScheduleFileKind: CaseIterable {
    case schedule
    case corrections

    var remoteURL: URL {
        switch self {
        case .schedule:
            return URL(string: "https://gztin.github.io/iPlayground/staff/data/schedule.js")!
        case .corrections:
            return URL(string: "https://gztin.github.io/iPlayground/staff/data/corrections.js")!
        }
    }

    var cacheFileName: String {
        switch self {
        case .schedule: return "schedule.cache.js"
        case .corrections: return "corrections.cache.js"
        }
    }

    var bundleResourceName: String {
        switch self {
        case .schedule: return "schedule.bundle"
        case .corrections: return "corrections.bundle"
        }
    }
}
