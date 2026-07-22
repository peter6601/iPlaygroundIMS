import Foundation

/// 把某位人員的原始任務清單，合併成一組「值勤區塊」(TaskBlock)。
enum BlockBuilder {

    private static func minutes(_ hhmm: String) -> Int {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        guard let h = parts.first else { return 0 }
        return h * 60 + (parts.count > 1 ? parts[1] : 0)
    }

    /// 網站上被視為「休息」而不列入議程的內容。
    private static func isBreak(_ content: String) -> Bool {
        content.trimmingCharacters(in: .whitespaces) == "休息(10)"
    }

    /// 一筆任務要顯示在議程裡的標籤（對齊網站 agendaLabel）。
    private static func contentLabel(_ task: RawTask) -> String {
        if !task.title.isEmpty {
            return task.speaker.isEmpty ? task.title : "\(task.speaker)｜\(task.title)"
        }
        return task.content
    }

    static func blocks(for person: String, in tasks: [RawTask]) -> [TaskBlock] {
        let mine = tasks.filter { $0.person == person }

        // 依 (day, role) 分組
        var groups: [String: [RawTask]] = [:]
        for task in mine {
            groups["\(task.day)|\(task.role)", default: []].append(task)
        }

        var blocks: [TaskBlock] = []
        for (_, groupTasks) in groups {
            let sorted = groupTasks.sorted { minutes($0.start) < minutes($1.start) }
            var runs: [[RawTask]] = []
            for task in sorted {
                if var last = runs.last,
                   let prev = last.last,
                   minutes(task.start) <= minutes(prev.end) {
                    // 相連或重疊 → 併入目前這段
                    last.append(task)
                    runs[runs.count - 1] = last
                } else {
                    runs.append([task])
                }
            }
            for run in runs {
                blocks.append(makeBlock(run))
            }
        }

        return blocks.sorted {
            $0.day != $1.day ? $0.day < $1.day : minutes($0.start) < minutes($1.start)
        }
    }

    private static func makeBlock(_ run: [RawTask]) -> TaskBlock {
        let first = run[0]
        let endMinutesMax = run.max { minutes($0.end) < minutes($1.end) }?.end ?? first.end

        // 議程內容：去休息、去空、保序去重
        var seen = Set<String>()
        var contents: [String] = []
        for task in run {
            guard !isBreak(task.content) else { continue }
            let label = contentLabel(task)
            guard !label.isEmpty, !seen.contains(label) else { continue }
            seen.insert(label)
            contents.append(label)
        }

        let duty = run.first { !$0.duty.isEmpty }?.duty ?? ""
        let endPending = run.contains { $0.endPending }

        return TaskBlock(role: first.role, day: first.day,
                         start: first.start, end: endMinutesMax,
                         contents: contents, duty: duty, endPending: endPending)
    }
}
