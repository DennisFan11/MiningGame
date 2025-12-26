# PlayerControllerComponent 使用指南

## 📋 概述

`PlayerControllerComponent` 是一個專門用於處理玩家輸入的組件，它讓玩家可以透過鍵盤/手把操控 Unit。

## 🎯 功能特性

- ✅ **自動 RPC 處理**: 自動將 Client 的輸入發送到 Server
- ✅ **多人連線支援**: 完全符合 Server-Authoritative 架構
- ✅ **與 UnitMoveComponent 整合**: 無縫提供輸入向量
- ✅ **衝刺事件**: 支援衝刺按鍵的可靠事件觸發

## 🔧 使用方式

### 1. 在 UnitData 中添加組件

```gdscript
// PlayerData.gd
func get_component_datas() -> Array[ComponentData]:
    return [
        BodyComponentData.new(get_body_polygon()),
        ComponentDB.UNIT_MOVEMENT,
        ComponentDB.PLAYER_CONTROLLER,  // ← 添加這個！
        // ...
    ]
```

### 2. 設定 Multiplayer Authority

PlayerController 會自動檢查 `is_multiplayer_authority()`，只有擁有權限的 Client 才會收集輸入。

通常在生成 Player Entity 時設定：

```gdscript
var player_entity = unit_db.create_player()
player_entity.set_multiplayer_authority(peer_id)  // 設定為該玩家的 peer_id
```

### 3. （可選）監聽衝刺事件

```gdscript
// 在 UnitEntity 或其他組件中
func _ready():
    var controller = $PlayerControllerComponent
    if controller:
        controller.on_dash_requested.connect(_on_dash)

func _on_dash():
    print("Player requested dash!")
    // 執行衝刺邏輯
```

## 🔄 工作流程

```
Client (有權限)
    ↓ 收集輸入 (Input.get_vector)
    ↓ RPC 發送到 Server
    
Server
    ↓ 接收輸入
    ↓ 儲存到 _current_input_vec
    ↓ UnitMoveComponent 調用 get_input_vector()
    ↓ 執行物理運算
    ↓ BodyComponent 自動同步位置
    
Client (所有)
    ↓ 接收同步的位置
    ↓ 顯示
```

## ⚙️ 配置選項

```gdscript
var controller = $PlayerControllerComponent

// 自訂輸入動作（預設值如下）
controller.action_left = "left"
controller.action_right = "right"
controller.action_up = "up"
controller.action_down = "down"
controller.action_dash = "dash"
```

## 🧩 與其他組件的關係

### UnitMoveComponent
- **依賴**: PlayerController 透過 `__unit_move_component` 注入獲取
- **整合**: 自動替換 `_get_input_vector()` 方法
- **結果**: MoveComponent 自動使用玩家輸入

### BodyComponent
- **同步**: Body 自動同步位置給所有 Client
- **無需配置**: 完全自動化

### HealthComponent
- **獨立**: 不直接關聯
- **可能用途**: 可監聽 on_die 事件來禁用輸入

## 📡 RPC 詳情

### `_rpc_update_input(input_vec)`
- **類型**: `unreliable_ordered`
- **方向**: Client → Server
- **頻率**: 每幀 (高頻)
- **用途**: 發送移動輸入向量

### `_rpc_dash()`
- **類型**: `reliable`
- **方向**: Client → Server  
- **頻率**: 按鍵觸發 (低頻)
- **用途**: 發送衝刺請求

## ⚠️ 注意事項

1. **權限檢查**: 確保在生成 Entity 時正確設定 `multiplayer_authority`
2. **輸入動作**: 確保專案中定義了對應的輸入動作（left, right, up, down, dash）
3. **組件順序**: PlayerController 必須在 UnitMoveComponent **之後**註冊（ComponentDB 順序）
4. **Server-Only**: 所有遊戲邏輯（移動運算）只在 Server 執行

## 🎮 完整範例

```gdscript
// PlayerData.gd
class_name PlayerData
extends UnitData

func get_max_hp() -> float:
    return 100.0

func get_speed() -> float:
    return 300.0

func get_body_polygon() -> PackedVector2Array:
    return PackedVector2Array([
        Vector2(-20, -20),
        Vector2(20, -20),
        Vector2(20, 20),
        Vector2(-20, 20)
    ])

func get_component_datas() -> Array[ComponentData]:
    return [
        BodyComponentData.new(get_body_polygon()),
        HitboxComponentData.new(BitmaskManager.TEAM.PLAYER),
        ComponentDB.UNIT_MOVEMENT,
        HealthComponentData.new(get_max_hp()),
        ComponentDB.PLAYER_CONTROLLER,
    ]
```

## 🐛 疑難排解

**問題**: Player 不移動
- 檢查 multiplayer authority 是否正確設定
- 確認輸入動作（left/right/up/down）是否在專案設定中定義
- 檢查 Console 是否有 "[PlayerControllerComponent] Missing ..." 錯誤

**問題**: 移動有延遲
- 這是正常的，因為使用 Server Authority
- 延遲取決於網路 ping
- 位置會自動插值顯示，看起來應該是平滑的

**問題**: 衝刺沒反應
- 確認 "dash" 動作是否定義
- 檢查是否有監聽 `on_dash_requested` 信號
- 在信號處理中實作衝刺邏輯
