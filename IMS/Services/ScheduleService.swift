import Foundation

/// 負責取得排班資料：優先遠端下載（gztin 更新網站即生效），
/// 失敗時依序退回 App Group cache → app bundle 內建快照。
enum ScheduleService {

    enum Source: String {
        case remote      // 這次成功從網路抓到
        case cache       // 用上次下載存下的 cache
        case bundle      // 連 cache 都沒有，用內建快照
    }

    struct Result {
        let schedule: OfflineSchedule
        let source: Source
    }

    /// 載入排班。會嘗試遠端下載並在成功時更新 cache。
    static func load() async -> Result {
        // 1) 嘗試遠端
        if let scheduleJS = await fetchRemote(.schedule) {
            let correctionsJS = await fetchRemote(.corrections)
            if let parsed = try? ScheduleParser.parse(scheduleJS: scheduleJS, correctionsJS: correctionsJS) {
                SharedStore.writeCachedJS(scheduleJS, kind: .schedule)
                if let correctionsJS { SharedStore.writeCachedJS(correctionsJS, kind: .corrections) }
                SharedStore.lastFetched = Date()
                return Result(schedule: parsed, source: .remote)
            }
        }

        // 2) 退回 cache
        if let scheduleJS = SharedStore.cachedJS(.schedule),
           let parsed = try? ScheduleParser.parse(scheduleJS: scheduleJS,
                                                  correctionsJS: SharedStore.cachedJS(.corrections)) {
            return Result(schedule: parsed, source: .cache)
        }

        // 3) 退回 bundle 內建快照
        if let parsed = loadFromBundle() {
            return Result(schedule: parsed, source: .bundle)
        }

        return Result(schedule: .empty, source: .bundle)
    }

    /// 同步版本：只讀 cache → bundle，不連網。Widget extension 用這個。
    static func loadCachedOrBundle() -> OfflineSchedule {
        if let scheduleJS = SharedStore.cachedJS(.schedule),
           let parsed = try? ScheduleParser.parse(scheduleJS: scheduleJS,
                                                  correctionsJS: SharedStore.cachedJS(.corrections)) {
            return parsed
        }
        return loadFromBundle() ?? .empty
    }

    // MARK: - Private

    private static func fetchRemote(_ kind: ScheduleFileKind) async -> String? {
        var components = URLComponents(url: kind.remoteURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970)))]
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private static func loadFromBundle() -> OfflineSchedule? {
        func bundleJS(_ kind: ScheduleFileKind) -> String? {
            guard let url = Bundle.main.url(forResource: kind.bundleResourceName, withExtension: "js") else {
                return nil
            }
            return try? String(contentsOf: url, encoding: .utf8)
        }
        guard let scheduleJS = bundleJS(.schedule) else { return nil }
        return try? ScheduleParser.parse(scheduleJS: scheduleJS, correctionsJS: bundleJS(.corrections))
    }
}
