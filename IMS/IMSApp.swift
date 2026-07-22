import SwiftUI

@main
struct IMSApp: App {
    @State private var state = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(state: state)
                .task {
                    await state.refresh()
                    // 測試/截圖用：以環境變數預選人員（production 不會設定）
                    if let preselect = ProcessInfo.processInfo.environment["IMS_PRESELECT"],
                       state.selectedPerson == nil {
                        state.select(preselect)
                    }
                }
                .onChange(of: scenePhase) { _, phase in
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
            if state.selectedPerson == nil {
                PersonPickerView(state: state)
            } else {
                TaskTimelineView(state: state)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }
}
