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
        focusRole: "外場負責人",
        focusTimeLabel: "16:00–17:30",
        focusDuty: "外場動線與人力調度。",
        isCurrent: true,
        focusStartDate: Date().addingTimeInterval(-5 * 60),
        focusEndDate: Date().addingTimeInterval(25 * 60),
        endPending: false,
        upNext: "便當發放 · 17:30"
    )
    private let sampleNext = MissionActivityAttributes.ContentState(
        focusRole: "場佈支援",
        focusTimeLabel: "15:00–16:00",
        focusDuty: "負責場佈支援，地點：中庭展廳。",
        isCurrent: false,
        focusStartDate: Date().addingTimeInterval(9 * 60),
        focusEndDate: nil,
        endPending: false,
        upNext: nil
    )

    var body: some View {
        VStack(spacing: 24) {
            Text("LIVE ACTIVITY · 鎖屏 / Dynamic Island 預覽")
                .font(.mono(11, .heavy)).foregroundStyle(Theme.accent).kerning(1)

            Text("鎖屏橫幅 · 進行中").font(.mono(12)).foregroundStyle(Theme.ink3)
            banner(sample)

            Text("鎖屏橫幅 · 下一場").font(.mono(12)).foregroundStyle(Theme.ink3)
            banner(sampleNext)

            Text("Dynamic Island（展開）").font(.mono(12)).foregroundStyle(Theme.ink3)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sample.focusRole ?? "").font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(sample.focusTimeLabel ?? "").font(.mono(10)).foregroundStyle(Theme.accent)
                }
                Spacer()
                if let end = sample.focusEndDate {
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

    private func banner(_ state: MissionActivityAttributes.ContentState) -> some View {
        LiveActivityLockScreenView(state: state)
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.rule, lineWidth: 1))
            .padding(.horizontal, 16)
    }
}
#endif
