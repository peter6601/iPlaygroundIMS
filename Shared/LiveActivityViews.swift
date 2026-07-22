import SwiftUI

/// Live Activity 的鎖屏橫幅內容，抽成可重用 View：
/// Live Activity widget 與 app 內的 debug 預覽都用同一份，確保預覽＝真機樣子。
struct LiveActivityLockScreenView: View {
    let state: MissionActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                if let role = state.currentRole {
                    Text("NOW").font(.mono(10, .heavy)).foregroundStyle(Theme.bg)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.accent, in: Capsule())
                    Text(role).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
                        .lineLimit(1)
                } else if let next = state.nextRole {
                    Text("NEXT").font(.mono(10, .heavy)).foregroundStyle(Theme.accent)
                    Text(next).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
                        .lineLimit(1)
                } else {
                    Text("今日任務完成").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.ink2)
                }
                if let next = state.nextRole, state.currentRole != nil,
                   let start = state.nextStartLabel {
                    Text("下一場 \(next) · \(start)").font(.mono(11)).foregroundStyle(Theme.ink3)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            trailing
        }
    }

    @ViewBuilder private var trailing: some View {
        if let role = state.currentRole, !role.isEmpty {
            VStack(alignment: .trailing, spacing: 2) {
                if state.endPending {
                    Text("結束待定").font(.mono(12)).foregroundStyle(Theme.ink2)
                } else if let end = state.currentEndDate {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.mono(20, .heavy)).foregroundStyle(Theme.accent)
                        .monospacedDigit().frame(maxWidth: 92)
                    Text("至 \(state.currentEndLabel ?? "")").font(.mono(10)).foregroundStyle(Theme.ink3)
                }
            }
        }
    }
}
