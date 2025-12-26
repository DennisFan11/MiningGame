# 多人連線架構支援文件

## 架構概述

本專案採用 **Server-Authoritative (Server 權威)** 多人連線架構：
- **Server**: 唯一執行遊戲邏輯和物理運算的節點
- **Client**: 僅負責輸入收集、顯示同步狀態、播放特效

## 組件多人連線支援

### CommonComponents (通用組件)

#### ✅ BodyComponent
**狀態**: 完全支援
- **同步方式**: MultiplayerSynchronizer (自動創建)
- **同步屬性**:
  - `body.position` - CharacterBody2D 位置
  - `body.velocity` - CharacterBody2D 速度
- **說明**: 
  - BodyComponent 自動創建 MultiplayerSynchronizer
  - Server Authority (權限設為 Server)
  - Client 自動插值顯示位置

#### ✅ HealthComponent
**狀態**: 完全支援
- **同步方式**: RPC (Server Authority)
- **API**:
  - `damage(amount, source)` - 自動處理 RPC，Server 執行
  - `heal(amount)` - 自動處理 RPC，Server 執行
- **內部 RPC**:
  - `_rpc_damage()` - Client -> Server 傷害請求
  - `_rpc_heal()` - Client -> Server 治療請求
- **同步變數建議**: 
  - 在 Entity 層級添加 `MultiplayerSynchronizer` 同步 `current_hp`

#### ✅ HitboxComponent
**狀態**: 完全支援
- **同步方式**: 無需同步（每個客戶端本地創建）
- **說明**: Area2D 碰撞檢測在 Server 執行，Client 僅顯示

### UnitDataComponents (Unit 專用組件)

#### ✅ UnitMoveComponent
**狀態**: 完全支援
- **同步方式**: Server-Only 物理運算
- **執行邏輯**:
  - `set_physics_process(multiplayer.is_server())` - 只在 Server 執行
  - `_physics_process()` - Double-check Server 權限
- **位置同步**: 由 Entity 的 MultiplayerSynchronizer 負責

#### ✅ VisionComponent
**狀態**: 完全支援
- **同步方式**: 無需同步（純查詢功能）
- **說明**: `can_see_target()` 可在任何節點調用，通常在 Server AI 邏輯中使用

## Entity 層級同步建議

### UnitEntity 同步配置範例

```gdscript
func _setup_multiplayer_synchronizer():
    var synchronizer = MultiplayerSynchronizer.new()
    synchronizer.set_multiplayer_authority(1) # Server Authority
    
    var config = SceneReplicationConfig.new()
    # 注意: Body 位置/速度已由 BodyComponent 自動同步，無需重複配置
    
    # 同步 HP（HealthComponent）
    config.add_property(NodePath("HealthComponent:current_hp"))
    # 其他 Entity 層級的狀態...
    
    synchronizer.replication_config = config
    add_child(synchronizer)
```

**重要提醒**: `BodyComponent` 已自動創建 Synchronizer 同步 position/velocity，Entity 層級無需重複設定。

## 使用指南

### Client-Side 調用範例

```gdscript
# Client 可以安全調用，會自動 RPC 到 Server
health_component.damage(10.0, attacker)
health_component.heal(5.0)
```

### Server-Side 邏輯範例

```gdscript
# Server AI 邏輯
func _physics_process(delta):
    if not multiplayer.is_server(): return
    
    if vision_component.can_see_target(player):
        # 移動邏輯由 UnitMoveComponent 自動處理
        # 攻擊邏輯
        player_health.damage(damage_amount, self)
```

## 注意事項

1. **所有修改遊戲狀態的操作都必須由 Server 執行**
2. **Client 透過 RPC 請求 Server 執行操作**
3. **HealthComponent 的 current_hp 應在 Entity 層級同步給 Client**
4. **物理運算只在 Server 執行，Client 透過 Synchronizer 插值顯示**
5. **特效、音效等表現層邏輯可在 Client 本地播放**

## 測試檢查清單

- [ ] Server 可以對 Unit 造成傷害
- [ ] Client 調用 damage() 會正確 RPC 到 Server
- [ ] HP 變化正確同步到所有 Client
- [ ] Unit 移動只在 Server 計算
- [ ] Client 顯示的位置正確插值（平滑）
- [ ] 死亡邏輯只在 Server 執行一次
