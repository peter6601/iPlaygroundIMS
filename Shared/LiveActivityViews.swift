import SwiftUI

/// Live Activity 的鎖屏橫幅內容，抽成可重用 View：
/// Live Activity widget 與 app 內的 debug 預覽都用同一份，確保預覽＝真機樣子。
struct LiveActivityLockScreenView: View {
    let state: MissionActivityAttributes.ContentState

    var body: some View {
        if let role = state.focusRole {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    badge
                    Text(role)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.ink).lineLimit(1)
                    if let time = state.focusTimeLabel {
                        Text(time).font(.mono(13, .medium)).foregroundStyle(Theme.accent)
                    }
                    if let duty = state.focusDuty, !duty.isEmpty {
                        Text(duty)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.ink2)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let up = state.upNext {
                        Text("下一場 \(up)").font(.mono(11)).foregroundStyle(Theme.ink3).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                countdown
            }
        } else {
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
                Text("今日任務完成").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.ink2)
            }
        }
    }

    @ViewBuilder private var badge: some View {
        if state.isCurrent {
            Text("NOW").font(.mono(10, .heavy)).foregroundStyle(Theme.bg)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Theme.accent, in: Capsule())
        } else {
            Text("NEXT").font(.mono(10, .heavy)).foregroundStyle(Theme.accent)
        }
    }

    @ViewBuilder private var countdown: some View {
        if state.isCurrent {
            if state.endPending {
                Text("結束待定").font(.mono(12)).foregroundStyle(Theme.ink2)
            } else if let end = state.focusEndDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.mono(22, .heavy)).foregroundStyle(Theme.accent)
                        .monospacedDigit().frame(maxWidth: 96)
                    Text("剩餘").font(.mono(10)).foregroundStyle(Theme.ink3)
                }
            }
        }
    }
}
