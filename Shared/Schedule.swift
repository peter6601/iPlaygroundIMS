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

    enum CodingKeys: String, CodingKey {
        case person, role, day, start, end, content, speaker, title
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
    }

    init(person: String, role: String, day: String, start: String, end: String,
         content: String = "", speaker: String = "", title: String = "") {
        self.person = person; self.role = role; self.day = day
        self.start = start; self.end = end
        self.content = content; self.speaker = speaker; self.title = title
    }
}

/// 解析後的完整排班（對應 `window.OFFLINE_SCHEDULE`）。
struct OfflineSchedule: Codable, Equatable {
    let people: [String]
    let schedule: [RawTask]

    static let empty = OfflineSchedule(people: [], schedule: [])
}
