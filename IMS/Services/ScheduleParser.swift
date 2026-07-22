import Foundation
import JavaScriptCore

/// 用 JavaScriptCore 原樣執行網站的 `schedule.js` 與 `corrections.js`，
/// 取得與網站 100% 一致的排班資料（含所有人名修正、補漏任務）。
///
/// 之所以不在 Swift 重寫 corrections 邏輯：corrections.js 會被 gztin 持續更新，
/// 唯有原樣 eval 才能永遠跟網站同步；我們不需要理解它做了什麼。
enum ScheduleParser {

    enum ParseError: Error, LocalizedError {
        case scheduleEvalFailed(String)
        case noOfflineSchedule
        case jsonSerializationFailed
        case decodeFailed(String)

        var errorDescription: String? {
            switch self {
            case .scheduleEvalFailed(let m): return "schedule.js 執行失敗：\(m)"
            case .noOfflineSchedule: return "執行後找不到 window.OFFLINE_SCHEDULE"
            case .jsonSerializationFailed: return "無法將 OFFLINE_SCHEDULE 轉為 JSON"
            case .decodeFailed(let m): return "JSON 解碼失敗：\(m)"
            }
        }
    }

    /// 執行 schedule.js（必要）與 corrections.js（可選、失敗則略過），回傳解析結果。
    /// - Parameter correctionsJS: 傳 nil 或執行失敗時，只用 schedule.js 的原始資料。
    static func parse(scheduleJS: String, correctionsJS: String?) throws -> OfflineSchedule {
        guard let ctx = JSContext() else {
            throw ParseError.scheduleEvalFailed("無法建立 JSContext")
        }

        var lastException: String?
        ctx.exceptionHandler = { _, exception in
            lastException = exception?.toString()
        }

        // 網站 JS 假設有全域 window；提供一個空物件即可。
        ctx.evaluateScript("var window = {};")

        lastException = nil
        ctx.evaluateScript(scheduleJS)
        if let ex = lastException {
            throw ParseError.scheduleEvalFailed(ex)
        }

        let typeCheck = ctx.evaluateScript("typeof window.OFFLINE_SCHEDULE")?.toString()
        guard typeCheck == "object" else {
            throw ParseError.noOfflineSchedule
        }

        // corrections.js 是加值修正：失敗不致命，退回只用 schedule.js。
        if let correctionsJS {
            lastException = nil
            ctx.evaluateScript(correctionsJS)
            if let ex = lastException {
                #if DEBUG
                print("[ScheduleParser] corrections.js 執行失敗，退回未修正資料：\(ex)")
                #endif
            }
        }

        guard let json = ctx.evaluateScript("JSON.stringify(window.OFFLINE_SCHEDULE)")?.toString(),
              let data = json.data(using: .utf8) else {
            throw ParseError.jsonSerializationFailed
        }

        do {
            return try JSONDecoder().decode(OfflineSchedule.self, from: data)
        } catch {
            throw ParseError.decodeFailed(String(describing: error))
        }
    }
}
