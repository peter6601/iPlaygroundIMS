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

## 互動模型：檢視 vs 開啟提醒

- **選名字＝只看行程**，不會啟動任何提醒（可以放心瀏覽別人的行程）。
- 任務畫面上的 **「這是我 · 開啟提醒」** 開關才會：請求通知授權、排本人的通知、啟動 Live Activity，
  並把這個人記成本人（`activatedPerson`，持久化）。
- Widget / 本地通知 / Live Activity 一律以 `activatedPerson` 為準；按「關閉」即取消全部。

## 真機測試（活動日以外也能測）

Live Activity / Dynamic Island / 本地通知**必須真機**測（模擬器不 render Live Activity）。
用 `IMS_TEST_TODAY` 讓 D0 變成「今天」並注入 DinDin 今天 15:00–20:00 的測試任務：

1. Xcode → Edit Scheme → Run → Arguments → Environment Variables，新增 `IMS_TEST_TODAY = 1`。
2. 選 **IMS** scheme、destination 選你的 iPhone，Run。
3. app 內選 **DinDin** → 按 **「這是我 · 開啟提醒」** → 允許通知。
4. 預期：任務前 10 分鐘收到通知（14:50 / 15:50 / 17:20 / 18:20）；進行中任務會有 Live Activity +
   Dynamic Island 倒數（下午 3–8 點之間）。
5. 測完把該環境變數的勾勾取消即可回正常資料。

> 註：`IMS_TEST_TODAY` 只影響 App 行程，Widget（獨立行程）仍以真實 D0=7/24 計算，
> 所以 Widget 的「今日測試」需在真正活動日驗證。其餘 debug 旗標：
> `IMS_PRESELECT=<名字>`（預選檢視）、`IMS_ACTIVATE=1`（順便開啟提醒）、
> `IMS_PREVIEW_BANNER=1`（Live Activity 版面預覽）、`IMS_TEST_LIVEACTIVITY=1`（強制啟一個示範）。

## TestFlight 上架

> 目標：今天送 Beta App Review，外部 TestFlight 首個 build 通常 24–48h 過審，
> 過審後開 public link 給 34 位工作人員。

**一個 build 含全部功能**（任務表＋通知＋Widget＋Live Activity）。當初規劃的「Build 1／Build 2」
已合併——Live Activity 是標準功能、審核風險低，不需拆兩次上傳。

**已驗證（2026/07/22）**：
- Team 已設 `QD39SW5YJ4`（寫在 `project.yml`，`xcodegen generate` 不會掉）。
- CLI `xcodebuild archive -allowProvisioningUpdates` 成功：自動簽章、provisioning、
  App Group `group.io.iplayground.ims` 皆自動建好並簽入 app + widget。
- 版本 1.0.0 / build 1，app 與 widget 一致；icon 1024² 無 alpha；出口加密合規已設。

**剩下需要你在 App Store Connect 手動做的：**
1. **建 app record**：appstoreconnect.apple.com → Apps → ＋ → New App，Bundle ID `com.peter6601.iplaygroundims`。
2. **上傳**：Xcode → Product → Archive → Organizer → Distribute App → App Store Connect → Upload。
   （簽章已驗證可過，Archive 會成功。）
3. **隱私標籤**：選「**不收集資料**」（app 只讀 gztin 公開網站，不上傳任何個資）。
4. **TestFlight**：填 Test Information → 建 External group → 加入 build → Submit for Beta Review。
   過審後開 **Public Link** 貼工作人員群組。
5. **提醒工作人員**：安裝後選自己的名字、允許通知；建議把 IMS 通知設「立即傳送」，活動日避免開專注模式。

## 授權

資料版權屬 iPlayground / gztin。此 app 為工作人員內部使用。
