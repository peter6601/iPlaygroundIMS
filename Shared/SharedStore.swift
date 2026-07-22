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

    static var selectedPerson: String? {
        get { defaults?.string(forKey: selectedPersonKey) }
        set {
            if let newValue { defaults?.set(newValue, forKey: selectedPersonKey) }
            else { defaults?.removeObject(forKey: selectedPersonKey) }
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
