# final_project Spec

## 1. 目標

此專案是一個以 SwiftUI 建置的校園漢服社團整合系統，提供以下功能：

- 帳號登入、註冊、忘記密碼
- 會員資訊維護
- 活動列表與活動報名
- 漢服圖鑑瀏覽
- 漢服租借與歸還
- 社群貼文與留言互動
- 公告管理
- 管理員功能入口

目前專案採用 `MVVM` 分層，並以 `FirebaseService` 作為資料與商業邏輯的統一入口。

## 2. 專案結構

目前已整理為單層主目錄，避免巢狀的重複資料夾：

- `final_project/AppModels.swift`
- `final_project/FirebaseService.swift`
- `final_project/AppViewModel.swift`
- `final_project/AppViews.swift`
- `final_project/ContentView.swift`
- `final_project/final_projectApp.swift`
- `final_project/Assets.xcassets`
- `final_project/Products/`

## 3. 模組職責

### `AppModels.swift`

定義全域資料模型與通用工具：

- `AppRole`
- `HanfuDynasty`
- `AppUser`
- `Event`
- `Hanfu`
- `Costume`
- `Post`
- `Comment`
- `Rental`
- `Announcement`
- `AppSnapshot`
- `Date` 與 `String` 延伸

這一層只負責資料結構與基本格式化，不處理 UI 與資料存取。

### `FirebaseService.swift`

負責所有資料操作與商業規則，包含：

- 登入、註冊、登出、密碼重設
- 會員資料更新
- 活動新增、修改、刪除、報名、取消報名
- 漢服資料新增、修改、刪除
- 租借與歸還流程
- 社群貼文、按讚、留言
- 公告管理
- 圖片上傳

目前此檔以 `AppSnapshot.sample()` 作為本機模擬資料來源，未來可替換成真正的 Firebase 後端實作。

### `AppViewModel.swift`

作為 UI 與服務層之間的橋接，負責：

- 持有 `snapshot` 狀態
- 提供目前使用者與管理員判斷
- 提供畫面所需的衍生資料，例如：
  - 已報名活動
  - 我的租借紀錄
  - 我的貼文
  - 我的留言
- 對外包裝 service 操作，並在異動後刷新畫面資料

### `AppViews.swift`

集中管理大部分 SwiftUI 畫面元件，包含：

- 登入 / 註冊 / 忘記密碼流程
- 主分頁 Tab
- 首頁
- 活動列表與詳情
- 漢服圖鑑與詳情
- 其他業務畫面元件

此檔目前偏大，適合後續再依功能拆成更小的檔案，但在現階段保留單檔可加快開發與維護初期速度。

### `ContentView.swift`

App 進入後的根畫面。根據登入狀態切換：

- 未登入：顯示 `AuthFlowView`
- 已登入：顯示 `RootTabView`

### `final_projectApp.swift`

SwiftUI App 進入點，負責啟動 `ContentView`。

### `Assets.xcassets`

集中管理圖示、顏色與圖片等資源。

## 4. 資料流

1. 使用者從 `ContentView` 進入 App。
2. `ContentView` 建立 `AppViewModel`。
3. `AppViewModel` 透過 `FirebaseService` 讀取或修改 `AppSnapshot`。
4. 畫面元件透過 `@EnvironmentObject` 或 `@StateObject` 取得狀態。
5. 當資料異動後，`AppViewModel` 重新 `refresh()`，讓 UI 自動更新。

## 5. 設計原則

- `Model` 只放資料結構與可重用格式化工具。
- `Service` 只放資料存取與商業規則，不直接操作 UI。
- `ViewModel` 負責狀態與流程協調。
- `View` 只負責呈現與使用者互動。

## 6. 後續建議

- 將 `AppViews.swift` 依功能拆分成更小的檔案，例如 `AuthViews.swift`、`EventViews.swift`、`SocialViews.swift`。
- 若確定只保留單一根畫面，可評估移除 `AppRootView`，避免與 `ContentView` 重複。
- 若要接 Firebase 正式後端，可把 `FirebaseService` 拆成協定與實作兩層，方便切換 mock 與 production。
- 補上測試與資料驗證規則，降低日後修改時的回歸風險。
