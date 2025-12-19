# 待辦事項 (Deferred Tasks)

- [ ] **修復敵人 AI 目標鎖定 (Fix Enemy AI Targeting)**:
    - `Zako.gd` 和其他敵人腳本目前依賴單一的 `_player` 參照。
    - 需要更新為向 `PlayerManager` 查詢（例如 `get_nearest_player()`）。
    - 由於已從 Main 場景移除 `%Player`，目前此功能已損壞。
