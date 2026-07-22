import SwiftUI

@main
struct IMSApp: App {
    @State private var state = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(state: state)
                .task {
                    #if DEBUG
                    // 截圖用：只啟動示範 Live Activity，跳過正常 refresh/sync
                    // （否則活動日以外 sync 會把示範 activity 收掉）
                    if ProcessInfo.processInfo.environment["IMS_TEST_LIVEACTIVITY"] != nil {
                        LiveActivityController.startSample()
                        return
                    }
                    #endif
                    await state.refresh()
                    // 測試/截圖用（production 不會設定）：
                    // IMS_PRESELECT 只檢視；再加 IMS_ACTIVATE 才開啟提醒。
                    if let preselect = ProcessInfo.processInfo.environment["IMS_PRESELECT"] {
                        state.select(preselect)
                        if ProcessInfo.processInfo.environment["IMS_ACTIVATE"] != nil {
                            await state.activateSelected()
                        }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["IMS_TEST_LIVEACTIVITY"] != nil { return }
                    #endif
                    if phase == .active {
                        Task { await state.refresh() }
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    let state: AppState

    var body: some View {
        Group {
            #if DEBUG
            if ProcessInfo.processInfo.environment["IMS_PREVIEW_BANNER"] != nil {
                LiveActivityPreviewScreen()
            } else if state.selectedPerson == nil {
                PersonPickerView(state: state)
            } else {
                TaskTimelineView(state: state)
            }
            #else
            if state.selectedPerson == nil {
                PersonPickerView(state: state)
            } else {
                TaskTimelineView(state: state)
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }
}

#if DEBUG
/// Debug 預覽：把 Live Activity 的鎖屏橫幅用同一份 View 直接 render，
/// 因為 iOS 模擬器不會實際顯示 Live Activity，用這個預覽真機樣子。
struct LiveActivityPreviewScreen: View {
    private let sample = MissionActivityAttributes.ContentState(
        currentRole: "外場負責人",
        currentEndDate: Date().addingTimeInterval(25 * 60),
        currentEndLabel: "10:20",
        nextRole: "中控室1",
        nextStartLabel: "7/25 10:30",
        endPending: false
    )

    var body: some View {
        VStack(spacing: 24) {
            Text("LIVE ACTIVITY · 鎖屏 / Dynamic Island 預覽")
                .font(.mono(11, .heavy)).foregroundStyle(Theme.accent).kerning(1)

            Text("鎖屏橫幅").font(.mono(12)).foregroundStyle(Theme.ink3)
            LiveActivityLockScreenView(state: sample)
                .padding(16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.rule, lineWidth: 1))
                .padding(.horizontal, 16)

            Text("Dynamic Island（展開）").font(.mono(12)).foregroundStyle(Theme.ink3)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sample.currentRole ?? "").font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text("下一場 \(sample.nextStartLabel ?? "")").font(.mono(10)).foregroundStyle(Theme.ink3)
                }
                Spacer()
                if let end = sample.currentEndDate {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.mono(15, .bold)).foregroundStyle(Theme.accent)
                        .monospacedDigit().frame(maxWidth: 64)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(Color.black, in: Capsule())
            .overlay(Capsule().stroke(Theme.rule, lineWidth: 1))
            .padding(.horizontal, 16)

            Text("※ 模擬器不 render 真的 Live Activity；這是同一份 SwiftUI 的預覽")
                .font(.mono(10)).foregroundStyle(Theme.ink3)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}
#endif
