import Foundation

/// 某個時段的「現場全覽」：一個職務群組 → 有哪些人。
struct RosterGroup: Identifiable, Equatable {
    let category: String
    let people: [String]
    var id: String { category }
}

/// 一個可選的時段（某天的一段時間 + 當下議程標題）。
struct RosterSlot: Identifiable, Equatable {
    let day: String
    let start: String
    let end: String
    let title: String        // 議程/內容，例如 "session(40)"
    var id: String { "\(day)|\(start)|\(end)" }
    var label: String { "\(start)–\(end)" }
}

enum RosterBuilder {

    private static func minutes(_ hhmm: String) -> Int {
        let p = hhmm.split(separator: ":").compactMap { Int($0) }
        guard let h = p.first else { return 0 }
        return h * 60 + (p.count > 1 ? p[1] : 0)
    }

    /// 某天所有不重複時段（依開始時間排序）。
    static func slots(day: String, in schedule: OfflineSchedule) -> [RosterSlot] {
        var seen = Set<String>()
        var result: [RosterSlot] = []
        for t in schedule.schedule where t.day == day {
            guard !t.start.isEmpty, !t.end.isEmpty else { continue }
            let key = "\(t.start)|\(t.end)"
            if seen.contains(key) { continue }
            seen.insert(key)
            let title = t.title.isEmpty ? t.content : t.title
            result.append(RosterSlot(day: day, start: t.start, end: t.end, title: title))
        }
        return result.sorted { minutes($0.start) < minutes($1.start) }
    }

    /// 指定時段中作用中的任務。
    private static func activeTasks(day: String, start: String, in schedule: OfflineSchedule) -> [RawTask] {
        let atMin = minutes(start)
        return schedule.schedule.filter { t in
            t.day == day && !t.role.isEmpty && !t.person.isEmpty && !isBreak(t.content)
                && minutes(t.start) <= atMin && atMin < minutes(t.end)
        }
    }

    /// 指定時段中，各組別有哪些人（去重、排序）。優先用 xlsx 的組別，沒有就用職務分類。
    static func roster(day: String, start: String, in schedule: OfflineSchedule) -> [RosterGroup] {
        var byGroup: [String: [String]] = [:]
        var order: [String] = []
        var seen: [String: Set<String>] = [:]

        for t in activeTasks(day: day, start: start, in: schedule) {
            let g = t.group.isEmpty ? category(for: t.role) : t.group
            if byGroup[g] == nil { byGroup[g] = []; order.append(g); seen[g] = [] }
            if !(seen[g]?.contains(t.person) ?? false) {
                seen[g]?.insert(t.person)
                byGroup[g]?.append(t.person)
            }
        }

        return order
            .sorted { groupRank($0) < groupRank($1) }
            .map { RosterGroup(category: $0, people: byGroup[$0]!.sorted()) }
    }

    /// 指定時段中「沒有排到任何工作」的人員（可用來掌握誰有空）。
    static func freePeople(day: String, start: String, in schedule: OfflineSchedule) -> [String] {
        let busy = Set(activeTasks(day: day, start: start, in: schedule).map(\.person))
        return schedule.people.filter { !busy.contains($0) }.sorted()
    }

    private static func isBreak(_ content: String) -> Bool {
        content.trimmingCharacters(in: .whitespaces) == "休息(10)"
    }

    /// 把細分職務歸類成好讀的群組。
    static func category(for role: String) -> String {
        if role == "講者" { return "講者" }
        if role.hasPrefix("工作坊") { return "工作坊" }
        if role.contains("中控") && role.contains("負責人") { return "負責人" }
        if role.hasSuffix("負責人") || role == "總指揮" { return "負責人" }
        if role.hasPrefix("中控") { return "中控室" }
        if role == "主持人" { return "主持人" }
        if role.hasPrefix("計時") || role == "小組長&電腦操作" { return "計時／舉牌" }
        if role.hasPrefix("便當組") { return "便當組" }
        if role == "講者便當" { return "講者便當" }
        if role.contains("攝影") { return "攝影" }
        if role == "後製" { return "後製" }
        if role.contains("採訪") { return "採訪" }
        if role.contains("櫃檯") { return "櫃檯" }
        if role == "共筆" { return "共筆" }
        if role == "技術活動" || role == "學生活動" { return "活動" }
        return role
    }

    // 組別顯示順序（現場動線相關的先）。
    private static let groupOrder = ["總指揮", "中控組", "中控室組", "場內組", "內場＋workshop",
                                     "場外組", "外場＋採訪", "採訪組", "攝影組", "便當組",
                                     "workshop組", "工作坊", "活動"]

    private static func groupRank(_ g: String) -> Int {
        groupOrder.firstIndex(of: g) ?? groupOrder.count
    }
}
