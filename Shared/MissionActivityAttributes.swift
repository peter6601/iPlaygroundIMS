import Foundation
import ActivityKit

/// Live Activity 的資料定義。
/// 動態部分聚焦「現在該關注的任務」：進行中優先，否則下一場。
struct MissionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// 焦點任務職務（nil = 今日任務已完成）。
        var focusRole: String?
        /// 執行時間，例如 "15:00–16:00"（endPending 時為 "15:00 開始"）。
        var focusTimeLabel: String?
        /// 一句話要做什麼。
        var focusDuty: String?
        /// 焦點是否進行中（true = NOW，false = NEXT）。
        var isCurrent: Bool
        /// 焦點任務開始時間（NEXT 狀態用於倒數到開始）。
        var focusStartDate: Date?
        /// 進行中才有，用於倒數到結束。
        var focusEndDate: Date?
        var endPending: Bool
        /// 進行中時順帶預告下一場，例如 "中控室1 · 16:00"。
        var upNext: String?
    }

    var person: String
}
