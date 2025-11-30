# Miningame

這是一個使用 Godot 4.5 開發的 2D 採礦與建造遊戲。

## 項目概述

Miningame 結合了採礦、建造與戰鬥元素。玩家可以收集資源、建造設施，並抵禦敵人的攻擊。

## 技術棧

- **引擎**: Godot 4.5 (Forward Plus)
- **語言**: GDScript
- **核心架構**:
	- **DI (Dependency Injection)**: 依賴注入系統，用於管理模塊間的依賴。
	- **Entity-Component**: 實體組件模式 (在 `Entity/_components` 中可見)。
	- **Manager Pattern**: 使用多個管理器 (GameSystem) 處理特定邏輯 (如 BuildingManager, TerrainManager)。

## 目錄結構

- **Asset/**: 遊戲資源 (圖片、音效等)。
- **Core/**: 核心系統代碼。
	- `DI/`: 依賴注入系統。
	- `InputManager/`: 輸入管理。
	- `Utility.gd`: 通用工具函數。
- **Entity/**: 遊戲實體。
	- `Player/`, `Enemy/`, `Building/`, `Item/`, `Weapon/`, `Bullet/`: 各類實體。
	- `_components/`: 可復用的組件。
- **GameSystem/**: 遊戲子系統。
	- `BuildingManager/`: 建造系統。
	- `TerrainManager/`: 地形系統。
	- `GameController/`: 遊戲流程控制。
	- ... (其他系統如 UI, Light, Particle 等)
- **Scene/**: 遊戲場景文件。

## 安裝與運行

1. 下載並安裝 [Godot 4.5](https://godotengine.org/)。
2. 克隆此倉庫。
3. 使用 Godot 導入 `project.godot` 文件。
4. 運行項目。

## 輸入控制

項目已配置以下輸入 (詳見 `project.godot`):
- **移動**: W/A/S/D 或 左搖桿
- **瞄準**: 右搖桿
- **攻擊**: 滑鼠左鍵 或 RT/R2
- **建造**: 方向鍵 (Up/Down/Left/Right)
- **互動**: Enter
- **暫停**: Esc

## 開發規範

- **文件命名**: PascalCase (類/腳本), snake_case (資源)。
- **代碼風格**: 遵循 GDScript 風格指南。
