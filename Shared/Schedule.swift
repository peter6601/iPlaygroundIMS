import Foundation

enum IMSShared {
    static let appGroupID = "group.io.iplayground.ims"
}

/// 一筆原始任務，對應網站 `window.OFFLINE_SCHEDULE.schedule` 的元素。
/// 欄位以 `decodeIfPresent` 容錯，因為 corrections.js 補進來的任務欄位不一定齊全。
struct RawTask: Codable, Hashable {
    let person: String
    let role: String
    let day: String        // "D0" | "D1" | "D2"
    let start: String      // "8:00"
    let end: String
    let content: String
    let speaker: String
    let title: String
    /// corrections.js 為場務/待補充/場佈任務組好的「去哪做什麼」完整說明；一般議程任務為空。
    let duty: String
    /// corrections.js 標記：工作人員 / 負責人 / 拍照手 / 待補充；一般任務為空。
    let assignment: String
    /// 結束時間待定（例如場復）。
    let endPending: Bool

    enum CodingKeys: String, CodingKey {
        case person, role, day, start, end, content, speaker, title, duty, assignment, endPending
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        person = try c.decodeIfPresent(String.self, forKey: .person) ?? ""
        role = try c.decodeIfPresent(String.self, forKey: .role) ?? ""
        day = try c.decodeIfPresent(String.self, forKey: .day) ?? ""
        start = try c.decodeIfPresent(String.self, forKey: .start) ?? ""
        end = try c.decodeIfPresent(String.self, forKey: .end) ?? ""
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        speaker = try c.decodeIfPresent(String.self, forKey: .speaker) ?? ""
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        duty = try c.decodeIfPresent(String.self, forKey: .duty) ?? ""
        assignment = try c.decodeIfPresent(String.self, forKey: .assignment) ?? ""
        endPending = try c.decodeIfPresent(Bool.self, forKey: .endPending) ?? false
    }

    init(person: String, role: String, day: String, start: String, end: String,
         content: String = "", speaker: String = "", title: String = "",
         duty: String = "", assignment: String = "", endPending: Bool = false) {
        self.person = person; self.role = role; self.day = day
        self.start = start; self.end = end
        self.content = content; self.speaker = speaker; self.title = title
        self.duty = duty; self.assignment = assignment; self.endPending = endPending
    }
}

/// 每人的支線任務（對應網站 `source.sideMissions`）。
struct SideMission: Codable, Hashable {
    let person: String
    let title: String
    let detail: String
    let link: String?

    enum CodingKeys: String, CodingKey { case person, title, detail, link }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        person = try c.decodeIfPresent(String.self, forKey: .person) ?? ""
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        detail = try c.decodeIfPresent(String.self, forKey: .detail) ?? ""
        link = try c.decodeIfPresent(String.self, forKey: .link)
    }

    init(person: String, title: String, detail: String, link: String? = nil) {
        self.person = person; self.title = title; self.detail = detail; self.link = link
    }
}

/// 解析後的完整排班（對應 `window.OFFLINE_SCHEDULE`）。
struct OfflineSchedule: Codable, Equatable {
    let people: [String]
    let schedule: [RawTask]
    let sideMissions: [SideMission]

    enum CodingKeys: String, CodingKey { case people, schedule, sideMissions }

    init(people: [String], schedule: [RawTask], sideMissions: [SideMission] = []) {
        self.people = people; self.schedule = schedule; self.sideMissions = sideMissions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        people = try c.decodeIfPresent([String].self, forKey: .people) ?? []
        schedule = try c.decodeIfPresent([RawTask].self, forKey: .schedule) ?? []
        sideMissions = try c.decodeIfPresent([SideMission].self, forKey: .sideMissions) ?? []
    }

    static let empty = OfflineSchedule(people: [], schedule: [], sideMissions: [])
}
