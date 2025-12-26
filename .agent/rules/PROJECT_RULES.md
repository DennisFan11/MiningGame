# 專案開發規範 (Project Rules)

本文件記錄專案的關鍵架構規範與開發準則，所有貢獻者必須嚴格遵守，以避免重蹈覆轍。

## 1. 核心組件系統 (Component System)
- **嚴禁修改核心**: `ComponentDB.gd` 和 `ComponentData.gd` 是核心基礎設施。
    - `ComponentDB.inject_component` **不應有返回值** (void)。
    - `ComponentData.inject_to` **不應有返回值** (void)。
- **依賴注入**: 任何組件的注入與依賴管理應透過 `LocalInjector` 和 `ComponentData` 機制完成，不得隨意更改核心接口。

## 2. UnitDB 註冊機制
- **靜態常數**: `UnitDB` 的資料註冊應使用 **靜態常數 (Static Constants)**，而非 Dictionary 表。
    - 正確: `static var PLAYER := PlayerData.new()`
    - 錯誤: `static var units = {"Player": ...}`
- **工廠方法**: `create_player` 等工廠方法應直接引用這些靜態常數。

## 3. Entity 初始化與生命週期
- **自動初始化**: `UnitEntity` 的 `final_setup()` 方法採用 `await ready` 機制。
    - 這意味著當 Unit 被加入場景樹 (SceneTree) 後，系統會自動遞歸呼叫所有子組件的 `_on_setuped()`。
- **禁止手動 Setup**: 在 `create_unit` 或 `create_player` 中，**嚴禁** 手動呼叫 `child._on_setuped()`。這不僅冗餘，還可能導致重複初始化或邏輯錯誤。

## 4. 全域依賴注入 (Global Dependency Injection)
- **嚴禁隨意 Autoload**: 像 `BitmaskManager`, `BulletManager` 這類 Manager 屬於 **Scene-Scoped** (場景轄域)，不得註冊為 Global Autoload。
- **注入原則**:
    - 組件 (如 `HitboxComponent`) 應宣告對應變數 (如 `var _bitmask_manager`) 並等待 **全域注入 (`DI.injection`)** 自動填入。
    - **禁止** 在組件內手動尋找 (get_node) 或嘗試修正依賴。
- **測試規範**:
    - 單元測試若需要這些 Manager，必須在測試場景中手動建立該節點 (Mocking)，**絕不允許** 修改 `project.godot` 來滿足測試需求。

## 5. 強型態與類型安全
- **Input Provider**: 輸入介面必須使用強型態 (如 `UnitInputProvider`)，禁止使用弱型態 `Object` 或 `HasMethod` 檢查。
