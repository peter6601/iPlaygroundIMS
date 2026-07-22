# iPlayground IMS 工作人員任務 App 實作計畫

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 https://gztin.github.io/iPlayground/staff/ 做成 iOS app，工作人員選自己的名字後，用 local notification、主畫面/鎖屏 Widget、Live Activity 提醒他「當下任務是什麼、下一場什麼時候、要去哪做什麼」。TestFlight 發給 34 位工作人員。

**Architecture:** 純本地架構、無自建後端。App 啟動時抓 GitHub Pages 上的 `schedule.js` + `corrections.js`，用 **JavaScriptCore 原樣執行**取得跟網站 100% 一致的資料（含修正），cache 到 App Group 供 Widget 共用。選定人員後：一次預排整個活動的 local notifications、預排整條 Widget timeline（任務切換不需喚醒 app）、活動日啟動 Live Activity 倒數。

**Tech Stack:** SwiftUI + iOS 17.0、JavaScriptCore（資料解析）、UserNotifications、WidgetKit、ActivityKit、App Group 共享。無第三方套件。

**Deadline 現實：**
- 今天 2026-07-22 完成 Build 1（任務表＋通知＋Widget）→ 晚上上傳送 Beta App Review
- 7/23 過審 → TestFlight public link 發群組；Build 2 加 Live Activity（同版號通常免重審）
- 7/24 D0 場佈實戰

---

## 設計規格

### 色系（取自 iplayground.io/2026 官網 CSS 變數，固定深色）

| Token | 值 | 用途 |
|---|---|---|
| `accent` | `#D2FF00` | 亮黃：強調、當前任務、按鈕 |
| `bg` | `#000000` | 全域背景 |
| `surface` | `#14160F` | 卡片背景 |
| `surface2` | `#282C20` | 次卡片、分隔 |
| `ink` | 近白 | 主文字 |
| `ink2` / `ink3` | 灰階 | 次要文字 |

日系科技感元素：等寬數字（`.monospacedDigit()` / SF Mono）、大寫小字 section label（如 `CURRENT MISSION`）、細格線、黃黑對比。App 顯示名稱：**IMS**（iPlayground Mission System）。

### 三個提醒面的分工

| 面 | 內容 | 更新機制 |
|---|---|---|
| Local Notification | 任務前 10 分鐘：「10 分鐘後｜中控室1（09:00–10:30）」＋工作內容 | 選人後一次預排全部（未來場次），資料更新時重排 |
| Widget（systemSmall/Medium＋鎖屏 accessoryRectangular） | 當下任務＋下一場預告＋倒數 | Timeline entries 預排在每個任務邊界，系統自動切換 |
| Live Activity（Build 2） | 活動日的即時倒數（Dynamic Island＋鎖屏） | `Text(timerInterval:)` 自動倒數；app 進前景時刷新內容 |

### 資料層關鍵決策

1. **用 JavaScriptCore 執行網站原始 JS**，不要在 Swift 重寫 corrections 邏輯。`corrections.js`（22KB）包含人名修正、補漏任務等，且 gztin 會持續更新——原樣執行才能永遠跟網站一致：
   ```
   JSContext → eval "var window = {};"
             → eval schedule.js（來自遠端或 bundle fallback）
             → eval corrections.js
             → eval "JSON.stringify(window.OFFLINE_SCHEDULE)"
             → Swift JSONDecoder
   ```
   若 corrections.js eval 失敗（例如未來版本用到 `document`），fallback 成只用 schedule.js 並記 log。
2. **遠端 URL**（更新排班＝gztin push 網站，app 不用發新 build）：
   - `https://gztin.github.io/iPlayground/staff/data/schedule.js`
   - `https://gztin.github.io/iPlayground/staff/data/corrections.js`
   - 加 `?t=<timestamp>` cache-bust；成功後存入 App Group container；抓不到用 cache，再沒有用 bundle 內建版。
3. **日期對應**（Asia/Taipei）：`D0=2026-07-24`、`D1=2026-07-25`、`D2=2026-07-26`。
4. **任務合併**（照網站 `app.js` 邏輯）：過濾 `休息(10)` 段 → 依 day/start 排序 → 同日同 role 且時間相連（前段 end == 後段 start）合併成一個 block。通知與 widget 都以合併後的 block 為單位（也解掉 64 則通知上限問題：每人每天約 5–12 blocks）。

### 專案結構

```
/Users/dinding/Documents/iOS Project/iPlaygroundIMS/
├── project.yml                     # xcodegen 定義（app + widget extension 兩個 target）
├── docs/plans/                     # 本計畫
├── IMS/                            # App target
│   ├── IMSApp.swift
│   ├── Theme.swift
│   ├── Models/Schedule.swift       # RawTask, TaskBlock, PersonSchedule
│   ├── Services/ScheduleService.swift    # 下載＋JSCore 解析＋cache
│   ├── Services/BlockBuilder.swift       # 過濾/排序/合併
│   ├── Services/NotificationScheduler.swift
│   ├── Services/AppState.swift
│   ├── Views/PersonPickerView.swift
│   ├── Views/TimelineView.swift
│   ├── Resources/schedule.bundle.js      # bundle fallback（build 時抓最新）
│   └── Resources/corrections.bundle.js
├── IMSWidget/                      # Widget extension target（widget + Live Activity 同一個 extension）
│   ├── IMSWidgetBundle.swift
│   ├── MissionWidget.swift         # TimelineProvider + views
│   └── MissionLiveActivity.swift   # Build 2
├── Shared/                         # 兩個 target 共用（models + shared storage）
│   └── SharedStore.swift           # App Group UserDefaults + cache 檔案存取
└── IMSTests/
    ├── ScheduleParserTests.swift
    └── BlockBuilderTests.swift
```

- **App Group**: `group.io.iplayground.ims`（若帳號下不可用，改 `group.com.peter6601.iplaygroundims`，全域搜尋替換）
- **Bundle ID**: `com.peter6601.iplaygroundims`（app）、`.widget`（extension）
- 專案生成用 **xcodegen**（`brew install xcodegen`），避免headless 手改 pbxproj 加 extension target 的風險；`project.yml` 進 git，改 target 設定＝改 yml 重跑。
- Git：個人帳號 peter6601（per [git-author-personal-projects]），`git init` 後 local config 設 user.name/user.email 為個人身分。

---

## Build 1（今天必須完成）

### Task 0: 取得資料快照 + git init

**Step 1:** `git init`，設定個人 git 身分（peter6601 / peter779701@gmail.com）。
**Step 2:** 下載 `schedule.js`、`corrections.js` 到 `IMS/Resources/` 作 bundle fallback（檔名加 `.bundle.js` 避免與遠端混淆）。
**Step 3:** Commit `chore: project scaffold + bundled schedule snapshot`。

### Task 1: xcodegen 專案骨架

**Files:** Create `project.yml`

**Step 1:** 確認 xcodegen：`which xcodegen || brew install xcodegen`
**Step 2:** 寫 `project.yml`：

```yaml
name: iPlaygroundIMS
options:
  bundleIdPrefix: com.peter6601
  deploymentTarget:
    iOS: "17.0"
settings:
  base:
    SWIFT_VERSION: "5.9"
    CURRENT_PROJECT_VERSION: 1
    MARKETING_VERSION: 1.0.0
    ITSAppUsesNonExemptEncryption: false
targets:
  IMS:
    type: application
    platform: iOS
    sources: [IMS, Shared]
    dependencies:
      - target: IMSWidget
    info:
      path: IMS/Info.plist
      properties:
        CFBundleDisplayName: IMS
        UILaunchScreen: {}
        NSSupportsLiveActivities: true
        ITSAppUsesNonExemptEncryption: false
    entitlements:
      path: IMS/IMS.entitlements
      properties:
        com.apple.security.application-groups: [group.io.iplayground.ims]
  IMSWidget:
    type: app-extension
    platform: iOS
    sources: [IMSWidget, Shared]
    info:
      path: IMSWidget/Info.plist
      properties:
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
    entitlements:
      path: IMSWidget/IMSWidget.entitlements
      properties:
        com.apple.security.application-groups: [group.io.iplayground.ims]
  IMSTests:
    type: bundle.unit-test
    platform: iOS
    sources: [IMSTests]
    dependencies:
      - target: IMS
```

**Step 3:** 建最小可編譯檔案（`IMSApp.swift` 空殼、widget bundle 空殼），跑 `xcodegen generate`。
**Step 4:** `mcp__XcodeBuildMCP__build_sim` 確認兩個 target 編譯通過。
**Step 5:** Commit。

⚠️ **Signing checkpoint（需要 DinDin）**：Task 8 上傳前，DinDin 要在 Xcode 登入付費帳號、把兩個 target 的 team 設好、在 developer portal 建 App Group。開發與模擬器驗證階段不需要。

### Task 2: Models + JSCore 解析（TDD）

**Files:** Create `Shared/Schedule.swift`, `IMS/Services/ScheduleService.swift`, Test `IMSTests/ScheduleParserTests.swift`

**Step 1: 失敗測試** — 用 bundle 快照餵 parser：

```swift
func testParsesBundledSchedule() throws {
    let parsed = try ScheduleParser.parse(
        scheduleJS: fixture("schedule.bundle.js"),
        correctionsJS: fixture("corrections.bundle.js"))
    XCTAssertTrue(parsed.people.contains("DinDin"))
    // corrections.js 會把非講者的 Ethan 改名 ggt — 驗證 corrections 有生效
    XCTAssertFalse(parsed.schedule.contains { $0.person == "Ethan" && $0.role != "講者" })
    XCTAssertTrue(parsed.schedule.contains { $0.person == "ggt" })
}

func testCorruptCorrectionsFallsBackToScheduleOnly() throws {
    let parsed = try ScheduleParser.parse(
        scheduleJS: fixture("schedule.bundle.js"),
        correctionsJS: "this is not js ((")
    XCTAssertTrue(parsed.people.contains("DinDin"))  // 仍可解析
}
```

**Step 2:** `test_sim` 跑，確認 FAIL（型別不存在）。
**Step 3: 實作** `Schedule.swift`：

```swift
struct RawTask: Codable, Hashable {
    let person: String
    let role: String
    let day: String      // "D0" | "D1" | "D2"
    let start: String    // "8:00"
    let end: String
    let content: String
    let speaker: String?
    let title: String?
}
struct OfflineSchedule: Codable {
    let people: [String]
    let schedule: [RawTask]
}
```

`ScheduleService.swift` 內 `ScheduleParser.parse`：JSContext 依序 eval `var window = {};`、scheduleJS、（try correctionsJS，失敗略過）、`JSON.stringify(window.OFFLINE_SCHEDULE)` → `JSONDecoder` decode。注意 `RawTask` 用 `decodeIfPresent` 容錯（missingTasks 的欄位可能不齊）。
**Step 4:** 測試轉綠。
**Step 5:** `ScheduleService`：`func load() async -> OfflineSchedule` — URLSession 抓兩個遠端檔（`?t=` cache-bust、timeout 10s）→ parse 成功則寫入 App Group cache（原始 js 文字直接存檔）→ 失敗依序 fallback：App Group cache → bundle。回傳來源標記（`.remote/.cache/.bundle`）供 UI 顯示資料時間。
**Step 6:** Commit `feat: schedule parsing via JavaScriptCore with corrections`。

### Task 3: BlockBuilder — 過濾、排序、合併（TDD）

**Files:** Create `Shared/BlockBuilder.swift`, Test `IMSTests/BlockBuilderTests.swift`

**Step 1: 失敗測試**（合成資料，不依賴真實快照）：

```swift
func testMergesConsecutiveSameRole() {
    let tasks = [
        rawTask(role: "中控室1", day: "D1", start: "9:00", end: "9:40"),
        rawTask(role: "中控室1", day: "D1", start: "9:40", end: "10:20"),
        rawTask(role: "主持人",  day: "D1", start: "10:30", end: "11:00"),
    ]
    let blocks = BlockBuilder.blocks(for: "X", in: tasks)
    XCTAssertEqual(blocks.count, 2)
    XCTAssertEqual(blocks[0].end, "10:20")
}
func testFiltersBreaks() { /* content == "休息(10)" 的段要被剔除 */ }
func testStartDateInTaipei() {
    let block = TaskBlock(role: "r", day: "D1", start: "8:00", end: "9:00", contents: [])
    // D1 = 2026-07-25 08:00 Asia/Taipei
    XCTAssertEqual(block.startDate.ISO8601Format(), "2026-07-25T00:00:00Z")
}
```

**Step 2:** 確認 FAIL。
**Step 3: 實作** `TaskBlock`（`role/day/start/end/contents:[String]`、computed `startDate`/`endDate`：以 `Asia/Taipei` + day 對應日期組 `Date`）與 `BlockBuilder.blocks(for:in:)`：filter person + 休息 → sort（day, start 分鐘數）→ 依「同 day 同 role 且 `prev.end == next.start`」合併，`contents` 收集各段 content（含講者場次 `speaker｜title`）。
**Step 4:** 轉綠、commit。

### Task 4: SharedStore + AppState

**Files:** Create `Shared/SharedStore.swift`, `IMS/Services/AppState.swift`

**Step 1:** `SharedStore`：App Group UserDefaults 存 `selectedPerson: String?`；cache 目錄（`FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`）讀寫 `schedule.js`/`corrections.js` 快照與 `lastFetched: Date`。Widget 端只讀。
**Step 2:** `AppState`（`@Observable`）：`schedule`、`selectedPerson`（寫入時同步 SharedStore + 觸發 reschedule + `WidgetCenter.shared.reloadAllTimelines()`）、`refresh() async`（load → 若資料 hash 改變 → reschedule + reload widgets）。App 進前景自動 `refresh()`。
**Step 3:** Build 過、commit。

### Task 5: UI — 人員選擇 + 任務 Timeline

**Files:** Create `IMS/Theme.swift`, `IMS/Views/PersonPickerView.swift`, `IMS/Views/TimelineView.swift`, modify `IMSApp.swift`

**Step 1:** `Theme.swift`：上表色票（`Color(hex:)` helper）＋字體 helper（`.mono(size:weight:)` 用 `.monospaced` design）。
**Step 2:** `PersonPickerView`：黑底、`LazyVGrid` 名字卡（surface 卡＋黃色 hover 樣式），頂部大標 `IMS ／ iPlayground Mission System`（accent 黃、mono 大寫）。搜尋欄可過濾。選定後存 `AppState.selectedPerson`。
**Step 3:** `TimelineView`：
- 頂部 summary（人名黃字＋D0/D1/D2 tab，預設今天：`<7/24→D0、7/25→D1、其餘→D2`）
- Block 卡片：左側時間欄（mono 大字 start↓end）＋右側 role 標題、contents 列表；**進行中的 block** 用黃色邊框＋`NOW` badge＋「還剩 mm:ss」（`Text(timerInterval:)`）
- 下拉更新（呼叫 `refresh()`），footer 顯示資料來源與更新時間（`資料 07/22 14:00 更新｜異動以現場總指揮為準`）
- 「換人」按鈕回 picker
**Step 4:** 模擬器 build_run + screenshot 驗證（黑底黃字、選 DinDin 看 D1 任務）。
**Step 5:** Commit。

### Task 6: NotificationScheduler（TDD 日期計算部分）

**Files:** Create `IMS/Services/NotificationScheduler.swift`, Test 加進 `BlockBuilderTests.swift`

**Step 1: 失敗測試** — 純函式：`func testFireDateIsTenMinutesBeforeStart()`（`fireDate(for: block) == startDate - 600s`）、過去的 block 不排（`futureBlocks(now:)`）。
**Step 2:** FAIL 確認。
**Step 3: 實作**：
- `requestAuthorization()`（選完名字後才要權限）
- `reschedule(blocks:)`：`removeAllPendingNotificationRequests()` → 對每個未來 block 排 `UNCalendarNotificationTrigger`（start-10min）：
  - title: `10 分鐘後｜\(role)`
  - body: `\(start)–\(end)\n\(contents.joined("\n"))`
  - 另在**每日第一個 block 前 30 分**加一則「今日任務開始」摘要通知
- 上限保護：blocks > 60 時只排最近 60 則（實際每人約 10–25，不會觸發）
**Step 4:** 轉綠；模擬器手動驗證：把系統時間概念改用「排一則 10 秒後的測試通知」debug 按鈕（`#if DEBUG`）確認通知會跳。
**Step 5:** Commit。

### Task 7: Widget（主畫面＋鎖屏）

**Files:** Create `IMSWidget/IMSWidgetBundle.swift`, `IMSWidget/MissionWidget.swift`

**Step 1:** `MissionEntry: TimelineEntry`：`date`、`person`、`current: TaskBlock?`、`next: TaskBlock?`。
**Step 2:** `MissionProvider: TimelineProvider`：從 SharedStore 讀 cache → parse → blocks(person) → **在每個 block 的 start/end 時間點各生成一個 entry**（entry 內容＝該時刻的 current/next），`policy: .atEnd`。未選人顯示「開啟 App 選擇名字」。資料為兩天活動，entries 總數 < 60，一條 timeline 蓋完全場。
**Step 3:** Views：
- systemSmall：黑底，`NOW` 黃 label＋role 大字＋`–HH:mm` 結束時間；無任務時顯示 `NEXT`＋下一場
- systemMedium：左 current（黃）右 next（灰）兩欄
- accessoryRectangular（鎖屏）：`▶ 中控室1 → 10:30` 一行式
- `containerBackground(Theme.bg, for: .widget)`
**Step 4:** 模擬器驗證：`build_run_sim` app 選人 → 加 widget 到桌面 → screenshot。
**Step 5:** Commit。

### Task 8: App icon + TestFlight 上架準備

**Step 1:** 產 app icon：1024px 黑底＋黃色 `IMS` mono 字＋細格線（用 Python/PIL 或 SwiftUI ImageRenderer 腳本產生），塞 asset catalog。
**Step 2:** Info.plist 檢查：display name、`ITSAppUsesNonExemptEncryption=false`（免出口合規審問）。通知權限不需 usage description（系統 alert 自帶）。
**Step 3:** `xcodegen generate` → release build 過。
**Step 4:** ⚠️ **DinDin 手動**：Xcode 登入帳號、設 team、portal 建 App Group、App Store Connect 建 app record → Archive → Upload → TestFlight 填 test information → 開 external group + public link → Submit for review。
**Step 5:** Commit + tag `v1.0.0-build1`。

---

## Build 2（7/23，等審核時做）

### Task 9: Live Activity

**Files:** Create `Shared/MissionActivityAttributes.swift`, `IMSWidget/MissionLiveActivity.swift`, modify `AppState.swift`

**Step 1:** `MissionActivityAttributes`：static `person`；`ContentState`：`currentRole/currentEndDate/nextRole/nextStart/nextLocationHint`。
**Step 2:** `MissionLiveActivity` widget：鎖屏 banner（黑底黃字：目前任務＋`Text(timerInterval:)` 倒數到結束＋下一場預告）；Dynamic Island compact（黃點＋剩餘分鐘）/ expanded。
**Step 3:** AppState：活動日（7/24–26）app 進前景時自動 `Activity.request`（若未啟動）並 `update` 成當下 block，`staleDate = current.endDate`；當天最後 block 結束後 `end`。UI 加手動開關。
**Step 4:** 模擬器驗證 Dynamic Island 顯示。
**Step 5:** Commit，版號 build 2 上傳（同版號通常免重審，直接推給 testers）。

### Task 10（buffer）: 現場回饋修正日

7/24 D0 實戰後的 hotfix 窗口——資料層改動**不需要**發 build（改網站即可），只有 UI/邏輯 bug 才需要 build 3。

---

## 風險與對策

| 風險 | 對策 |
|---|---|
| Beta review 卡超過 24h | 今晚一定要送出；Build 1 完全不含 Live Activity 降低 reject 面積；被 reject 就走 internal testers（核心幹部先用）＋public link 補上 |
| corrections.js 未來改版用到 browser API | parser 有 fallback（只吃 schedule.js）；bundle 快照保底 |
| 34 人中有 Android | 網站不下架，Android 繼續用網站 |
| 排班在活動前大改 | 資料層走遠端，gztin push＝app 自動更新；app 進前景就 refresh＋重排通知 |
| App Group id 在帳號下衝突 | 換 `group.com.peter6601.iplaygroundims`，`project.yml` 一處改完重生 |
| 通知在勿擾/專注模式被吞 | TestFlight 說明頁提醒工作人員把 IMS 通知設為「立即傳送」；活動日建議關專注模式 |
