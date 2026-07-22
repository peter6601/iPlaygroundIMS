import WidgetKit
import SwiftUI

// MARK: - Timeline

struct MissionEntry: TimelineEntry {
    let date: Date
    let person: String?
    let current: TaskBlock?
    let next: TaskBlock?
}

struct MissionProvider: TimelineProvider {
    func placeholder(in context: Context) -> MissionEntry {
        MissionEntry(date: Date(), person: "DinDin",
                     current: TaskBlock(role: "外場負責人", day: "D1", start: "9:00", end: "18:00",
                                        contents: [], duty: "", endPending: false),
                     next: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MissionEntry) -> Void) {
        let schedule = WidgetData.loadSchedule()
        let entries = WidgetData.entries(person: SharedStore.activatedPerson, schedule: schedule, now: Date())
        completion(entries.first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MissionEntry>) -> Void) {
        let schedule = WidgetData.loadSchedule()
        let entries = WidgetData.entries(person: SharedStore.activatedPerson, schedule: schedule, now: Date())
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Widget

struct MissionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MissionWidget", provider: MissionProvider()) { entry in
            MissionWidgetView(entry: entry)
                .containerBackground(Theme.bg, for: .widget)
        }
        .configurationDisplayName("當下任務")
        .description("顯示你現在該做什麼、下一場任務。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Views

struct MissionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MissionEntry

    var body: some View {
        switch family {
        case .accessoryRectangular: rectangular
        case .systemMedium: medium
        default: small
        }
    }

    // 未選人：提示開啟 App
    @ViewBuilder private var needsSetup: some View {
        VStack(spacing: 4) {
            Text("IMS").font(.mono(20, .heavy)).foregroundStyle(Theme.accent)
            Text("開 App 開啟提醒").font(.mono(11)).foregroundStyle(Theme.ink2)
        }
    }

    // systemSmall
    @ViewBuilder private var small: some View {
        if entry.person == nil {
            needsSetup
        } else if let current = entry.current {
            VStack(alignment: .leading, spacing: 6) {
                label("NOW", filled: true)
                Text(current.role).font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.ink).lineLimit(2).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text(current.endPending ? "結束待定" : "至 \(current.end)")
                    .font(.mono(12)).foregroundStyle(Theme.ink2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else if let next = entry.next {
            VStack(alignment: .leading, spacing: 6) {
                label("NEXT", filled: false)
                Text(next.role).font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.ink).lineLimit(2).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text("\(DayInfoW.short(next.day)) \(next.start) 開始")
                    .font(.mono(12)).foregroundStyle(Theme.accent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                label("DONE", filled: false)
                Text("目前沒有任務").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    // systemMedium：當下 | 下一個
    @ViewBuilder private var medium: some View {
        if entry.person == nil {
            needsSetup
        } else {
            HStack(spacing: 14) {
                column(title: "NOW", filled: true, block: entry.current, emptyText: "休息中")
                Rectangle().fill(Theme.rule).frame(width: 1)
                column(title: "NEXT", filled: false, block: entry.next, emptyText: "今日結束")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func column(title: String, filled: Bool, block: TaskBlock?, emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label(title, filled: filled)
            if let block {
                Text(block.role).font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink).lineLimit(2).minimumScaleFactor(0.7)
                Text(block.endPending ? "\(block.start) 開始" : "\(block.start)–\(block.end)")
                    .font(.mono(11)).foregroundStyle(Theme.ink2)
            } else {
                Text(emptyText).font(.system(size: 14)).foregroundStyle(Theme.ink3)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // accessoryRectangular（鎖屏）
    @ViewBuilder private var rectangular: some View {
        if entry.person == nil {
            Text("IMS · 開 App 開啟提醒").font(.system(size: 13))
        } else if let current = entry.current {
            VStack(alignment: .leading, spacing: 2) {
                Text("▶ \(current.role)").font(.system(size: 15, weight: .bold)).lineLimit(1)
                Text(current.endPending ? "結束待定" : "至 \(current.end)").font(.system(size: 12))
            }
        } else if let next = entry.next {
            VStack(alignment: .leading, spacing: 2) {
                Text("下一場 \(next.role)").font(.system(size: 15, weight: .bold)).lineLimit(1)
                Text("\(next.start) 開始").font(.system(size: 12))
            }
        } else {
            Text("今日任務完成").font(.system(size: 14, weight: .medium))
        }
    }

    private func label(_ text: String, filled: Bool) -> some View {
        Text(text)
            .font(.mono(10, .heavy))
            .foregroundStyle(filled ? Theme.bg : Theme.accent)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(filled ? Theme.accent : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(Theme.accent, lineWidth: filled ? 0 : 1))
    }
}

/// Widget 端的日期短標（避免依賴 app target 的 DayInfo）。
enum DayInfoW {
    static func short(_ day: String) -> String {
        switch day {
        case "D0": return "7/24"
        case "D1": return "7/25"
        case "D2": return "7/26"
        default: return day
        }
    }
}
