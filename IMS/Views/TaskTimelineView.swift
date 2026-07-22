import SwiftUI

/// 選定人員後的任務時間軸：當下任務高亮、下一場預告、支線任務。
struct TaskTimelineView: View {
    let state: AppState
    @State private var day: String = DayInfo.defaultDay()

    private var person: String { state.selectedPerson ?? "" }

    private var allBlocks: [TaskBlock] { state.selectedBlocks }
    private var dayBlocks: [TaskBlock] { allBlocks.filter { $0.day == day } }

    var body: some View {
        SwiftUI.TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: context.date)
        }
        .background(Theme.bg)
    }

    private func content(now: Date) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                topBar
                dayTabs
                summary
                blockList(now: now)
                if !state.selectedMissions.isEmpty {
                    sideMissions
                }
                footer
            }
            .padding(20)
        }
        .refreshable { await state.refresh() }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack(alignment: .firstTextBaseline) {
            Button {
                state.clearSelection()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 13, weight: .bold))
                    Text("換人").font(.mono(13, .medium))
                }
                .foregroundStyle(Theme.ink2)
            }
            Spacer()
        }
    }

    private var dayTabs: some View {
        HStack(spacing: 8) {
            ForEach(DayInfo.all, id: \.self) { value in
                let active = value == day
                Button { day = value } label: {
                    Text(DayInfo.label(value))
                        .font(.mono(13, active ? .bold : .regular))
                        .foregroundStyle(active ? Theme.bg : Theme.ink2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(active ? Theme.accent : Theme.surface,
                                    in: Capsule())
                        .overlay(Capsule().stroke(Theme.rule, lineWidth: active ? 0 : 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(person)
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(Theme.accent)
            Text("\(dayBlocks.count) 段任務 · \(DayInfo.shortLabel(day))")
                .font(.mono(13))
                .foregroundStyle(Theme.ink3)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private func blockList(now: Date) -> some View {
        if dayBlocks.isEmpty {
            Text("這天沒有排定任務。")
                .font(.mono(14))
                .foregroundStyle(Theme.ink3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            VStack(spacing: 12) {
                ForEach(dayBlocks) { block in
                    blockCard(block, now: now)
                }
            }
        }
    }

    private func blockCard(_ block: TaskBlock, now: Date) -> some View {
        let isCurrent = now >= block.startDate && now < block.endDate
        let isPast = now >= block.endDate
        return HStack(alignment: .top, spacing: 14) {
            // 時間欄
            VStack(spacing: 2) {
                Text(block.start).font(.mono(16, .bold))
                Text("↓").font(.mono(11)).foregroundStyle(Theme.ink3)
                Text(block.endPending ? "待定" : block.end)
                    .font(.mono(16, .bold))
            }
            .foregroundStyle(isCurrent ? Theme.accent : Theme.ink2)
            .frame(width: 56)

            // 內容欄
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(block.role)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    if isCurrent {
                        nowBadge(until: block.endDate, now: now)
                    }
                }
                if !block.duty.isEmpty {
                    Text(block.duty)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !block.contents.isEmpty {
                    contentDisclosure(block)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? Theme.accent : Theme.rule,
                        lineWidth: isCurrent ? 2 : 1)
        )
        .opacity(isPast ? 0.5 : 1)
    }

    private func nowBadge(until end: Date, now: Date) -> some View {
        HStack(spacing: 5) {
            Circle().fill(Theme.accent).frame(width: 6, height: 6)
            Text("NOW").font(.mono(10, .heavy)).foregroundStyle(Theme.bg)
            Text(timerInterval: now...end, countsDown: true)
                .font(.mono(10, .heavy))
                .foregroundStyle(Theme.bg)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.accent, in: Capsule())
    }

    private func contentDisclosure(_ block: TaskBlock) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(block.contents, id: \.self) { item in
                    Text("· \(item)")
                        .font(.mono(12))
                        .foregroundStyle(Theme.ink3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 4)
        } label: {
            Text("同時段議程 \(block.contents.count)")
                .font(.mono(12, .medium))
                .foregroundStyle(Theme.ink3)
        }
        .tint(Theme.ink3)
    }

    private var sideMissions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIDE MISSIONS · 支線任務")
                .font(.mono(11, .heavy))
                .foregroundStyle(Theme.accent)
                .kerning(1)
            ForEach(Array(state.selectedMissions.enumerated()), id: \.offset) { _, mission in
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(mission.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let link = mission.link, let url = URL(string: link) {
                        Link("開啟相關資料 →", destination: url)
                            .font(.mono(12, .medium))
                            .tint(Theme.accent)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.top, 6)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(footerText)
                .font(.mono(11))
                .foregroundStyle(Theme.ink3)
            Text("如有異動，以現場總指揮通知為準")
                .font(.mono(11))
                .foregroundStyle(Theme.ink3)
        }
        .padding(.top, 10)
    }

    private var footerText: String {
        let sourceLabel: String
        switch state.source {
        case .remote: sourceLabel = "線上最新"
        case .cache: sourceLabel = "本機快取"
        case .bundle: sourceLabel = "內建版本"
        }
        guard let date = state.lastFetched else { return "資料來源：\(sourceLabel)" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd HH:mm"
        fmt.timeZone = TimeZone(identifier: "Asia/Taipei")
        return "資料 \(fmt.string(from: date)) 更新 · \(sourceLabel)"
    }
}
