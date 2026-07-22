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

    /// 載入排班。會嘗試遠端下載並在成功時更新 cache 與 Widget 快照。
    /// 只有 App target 呼叫這裡（會執行 JSCore）；Widget 改讀 `SharedStore.readSnapshot()`。
    static func load() async -> Result {
        // 1) 嘗試遠端
        if let scheduleJS = await fetchRemote(.schedule) {
            let correctionsJS = await fetchRemote(.corrections)
            if let parsed = try? ScheduleParser.parse(scheduleJS: scheduleJS, correctionsJS: correctionsJS) {
                SharedStore.writeCachedJS(scheduleJS, kind: .schedule)
                if let correctionsJS { SharedStore.writeCachedJS(correctionsJS, kind: .corrections) }
                SharedStore.lastFetched = Date()
                let final = withTestData(parsed)
                SharedStore.writeSnapshot(final)
                return Result(schedule: final, source: .remote)
            }
        }

        // 2) 退回 cache（app 之前下載的原始 JS）
        if let scheduleJS = SharedStore.cachedJS(.schedule),
           let parsed = try? ScheduleParser.parse(scheduleJS: scheduleJS,
                                                  correctionsJS: SharedStore.cachedJS(.corrections)) {
            let final = withTestData(parsed)
            SharedStore.writeSnapshot(final)
            return Result(schedule: final, source: .cache)
        }

        // 3) 退回 bundle 內建快照
        if let parsed = loadFromBundle() {
            let final = withTestData(parsed)
            SharedStore.writeSnapshot(final)
            return Result(schedule: final, source: .bundle)
        }

        return Result(schedule: .empty, source: .bundle)
    }

    /// DEBUG 測試模式：注入 DinDin 今天下午的測試任務（見 TestClock）。
    private static func withTestData(_ schedule: OfflineSchedule) -> OfflineSchedule {
        #if DEBUG
        guard TestClock.testTodayEnabled else { return schedule }
        return OfflineSchedule(people: schedule.people,
                               schedule: schedule.schedule + TestClock.dinDinTodayTasks,
                               sideMissions: schedule.sideMissions)
        #else
        return schedule
        #endif
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
