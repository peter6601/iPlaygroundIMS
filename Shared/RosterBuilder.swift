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

    /// 指定時段中，各職務群組有哪些人（去重、排序）。
    static func roster(day: String, start: String, in schedule: OfflineSchedule) -> [RosterGroup] {
        let atMin = minutes(start)
        // 該時段作用中的任務：同一天、start <= atMin < end
        var byCategory: [String: [String]] = [:]
        var order: [String] = []
        var seenPerson: [String: Set<String>] = [:]

        for t in schedule.schedule where t.day == day {
            guard !t.role.isEmpty, !t.person.isEmpty else { continue }
            let s = minutes(t.start), e = minutes(t.end)
            guard s <= atMin, atMin < e else { continue }
            guard !isBreak(t.content) else { continue }
            let cat = category(for: t.role)
            if byCategory[cat] == nil {
                byCategory[cat] = []
                order.append(cat)
                seenPerson[cat] = []
            }
            if !(seenPerson[cat]?.contains(t.person) ?? false) {
                seenPerson[cat]?.insert(t.person)
                byCategory[cat]?.append(t.person)
            }
        }

        return order
            .sorted { categoryRank($0) < categoryRank($1) }
            .map { RosterGroup(category: $0, people: byCategory[$0]!.sorted()) }
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

    private static let rankOrder = ["負責人", "主持人", "中控室", "計時／舉牌", "櫃檯",
                                    "便當組", "講者便當", "攝影", "後製", "採訪", "共筆",
                                    "工作坊", "活動", "講者"]

    private static func categoryRank(_ cat: String) -> Int {
        rankOrder.firstIndex(of: cat) ?? rankOrder.count
    }
}
