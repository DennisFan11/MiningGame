---
description: 此項目的詳細TDD開發流程
---

一律使用中文 plan也要

---

## 依賴注入系統

本專案使用兩層依賴注入系統：**全域 DI** 與 **LocalInjector**。

### 全域 DI（單底線 `_`）

用於遊戲系統層級的 Manager 類：

```gdscript
# 註冊（通常在 _ready 中）
func _ready():
    DI.register("_building_manager", self)

# 使用（自動注入）
var _building_manager: BuildingManager  # 變數名稱必須與 key 完全一致
```

**已註冊的全域依賴：**
- `_game_controller`, `_building_manager`, `_building_service`
- `_terrain_manager`, `_player_manager`, `_prop_manager`
- `_sound_manager`, `_particle_manager`, `_light_manager`
- `_debug_ui`, `_esc_ui`, `_player_item_repo`

### LocalInjector（雙底線 `__`）

用於 Entity 內部的組件間依賴：

```gdscript
# Entity 內部註冊
__loca_injector.register("__unit_data", unit_data)
__loca_injector.register("__health_component", health_comp)

# Component 中使用（自動注入）
var __unit_data: UnitData
var __health_component: HealthComponent
```

**命名規範：**
| 前綴 | 用途 | 範例 |
|:-----|:-----|:-----|
| `_xxx` | 全域 Manager | `_building_manager` |
| `__xxx` | Entity 內部組件/資料 | `__unit_data`, `__body_component` |

---

## 嚴格解耦原則

### Component 禁止事項

1. **禁止知道 Entity 類別** - 不可引用 `UnitEntity`, `BuildingEntity`
2. **禁止知道 LocalInjector** - 不可手動呼叫 `injection()`
3. **禁止依賴場景樹** - 不可使用 `get_node()`
4. **主動通知** - 如果需要違反上述原則，請先主動通知用戶 先跟用戶討論！！！ 不要自作主張！！！！！


### 正確的依賴獲取方式

```gdscript
# ❌ 錯誤
func _ready():
    var entity = get_parent()
    health = entity.get_node("HealthComponent")

# ✅ 正確 - 透過變數名稱自動注入
var __health_component: HealthComponent

func _on_setuped():
    # 此時 __health_component 已被 LocalInjector 注入
    __health_component.damage(10)
```

### 生命週期回調

| 回調 | 觸發時機 | 用途 |
|:-----|:---------|:-----|
| `_on_injected()` | 全域 DI 注入完成 | 存取 Manager |
| `_on_setuped()` | Entity 完全初始化 | 存取兄弟組件 |

---

## TDD 測試流程

使用 GUT 測試框架進行測試驅動開發：

### 測試目錄結構
- `test/unit/` - 單元測試
- `test/integration/` - 整合測試

### 測試檔案命名
- 測試檔案以 `test_` 開頭，例如 `test_utility.gd`
- 測試函數以 `test_` 開頭

### TDD 循環
1. **紅燈** - 先寫失敗的測試
2. **綠燈** - 寫最少的程式碼讓測試通過
3. **重構** - 改善程式碼品質，確保測試仍通過

### 執行測試
- 編輯器：GUT Panel → Run All
- CLI：`godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit`

```bash
godot --headless --import . --quit
```

### 測試原則 (重要)

1.  **禁止手動注入內部依賴 (Integration/Smoke Test)**
    -   在整合或完整性測試中，**嚴禁**使用 `__loca_injector.register` 手動填補依賴。
    -   **必須**使用 `EntityDB` 或標準 Factory 方法生成 Entity，確保測試環境與生產環境一致。
    -   *原因*：手動注入會導致測試出現偽陽性 (False Positive)，掩蓋實際生產環境中缺少的依賴錯誤。

2.  **Global DI Mocking (允許)**
    -   允許使用 `DI.register("_manager_name", mock_obj)` 來模擬外部系統 (System Managers)。
    -   這是因為 Integration Test 通常聚焦於 Entity 內部的行為，而非全域系統的整合。