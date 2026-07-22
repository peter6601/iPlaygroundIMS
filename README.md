# IMS · iPlayground Mission System

iPlayground 2026 工作人員任務 app。工作人員選自己的名字，即可查看當下/下一場任務、
收到任務前 10 分鐘的本地通知、在主畫面與鎖屏 Widget 看到「現在該做什麼」。

網站原版：https://gztin.github.io/iPlayground/staff/index.html

## 架構重點

- **純本地、無自建後端。** App 啟動時抓 GitHub Pages 上的 `schedule.js` + `corrections.js`，
  用 **JavaScriptCore 原樣執行**，取得與網站 100% 一致的資料（含所有人名修正、補漏任務、
  `duty` 說明、`sideMissions`）。gztin 更新網站 → app 自動跟上，不用發新 build。
- **JSCore 只在 App，不在 Widget。** App 解析後把結果寫成 JSON 快照到 App Group；
  Widget 純原生讀取（避開 widget extension 的記憶體限制）。
- **三個提醒面：** 本地通知（前 10 分＋每日摘要）、Widget（timeline 預排、自動切換）、
  Live Activity（Build 2 追加）。
- 資料 fallback：遠端下載 → App Group cache → app/widget bundle 內建快照。

## 開發

```bash
xcodegen generate          # 由 project.yml 生成 xcodeproj（改 target 設定就改 yml 再跑這個）
open iPlaygroundIMS.xcodeproj
```

- iOS 17.0+、SwiftUI、無第三方套件。
- 單元測試：資料解析、任務合併、通知日期、Widget timeline 切片。
- App Group：`group.io.iplayground.ims`

### 更新內建資料快照

活動前若要更新 app 內建的離線 fallback（平時不需要，遠端會自動更新）：

```bash
curl -s https://gztin.github.io/iPlayground/staff/data/schedule.js   -o IMS/Resources/schedule.bundle.js
curl -s https://gztin.github.io/iPlayground/staff/data/corrections.js -o IMS/Resources/corrections.bundle.js
# Widget 的 snapshot.bundle.json 由 scripts 重新產生（見 git 歷史的 gen.swift）
```

## TestFlight 上架（需 DinDin 手動）

> 目標：今天送 Beta App Review，外部 TestFlight 首個 build 通常 24–48h 過審，
> 過審後開 public link 給 34 位工作人員。

1. **Apple 帳號**：用付費 Apple Developer 帳號登入 Xcode（Settings → Accounts）。
2. **App Group**：到 developer.apple.com → Identifiers 建 App Group `group.io.iplayground.ims`，
   並確認兩個 App ID（`com.peter6601.iplaygroundims` 與 `.widget`）都勾選加入該 group。
   （若此 ID 已被占用，改 `group.com.peter6601.iplaygroundims`，把 `Shared/Schedule.swift`
   的 `appGroupID` 與 `project.yml` 兩處 entitlements 一起改，再 `xcodegen generate`。）
3. **Signing**：Xcode 選 IMS 與 IMSWidget 兩個 target → Signing & Capabilities → 勾 Automatically manage signing、
   選 Team。
4. **App Store Connect**：建立新 app record（Bundle ID `com.peter6601.iplaygroundims`）。
5. **Archive**：Xcode → Product → Destination 選「Any iOS Device」→ Product → Archive → Distribute App → App Store Connect → Upload。
6. **TestFlight**：填 Test Information（測試說明、聯絡人），建 External group，加入 build，
   Submit for Beta Review。過審後開 **Public Link** 貼到工作人員群組。
7. **提醒工作人員**：安裝後選自己的名字、允許通知；建議把 IMS 通知設「立即傳送」，活動日避免開專注模式。

### Build 2（Live Activity，等 Build 1 審核時做）

Live Activity 進第二個 build（同版號後續 build 通常自動過、不重審），先求核心功能卡位過審。

## 授權

資料版權屬 iPlayground / gztin。此 app 為工作人員內部使用。
