#!/bin/bash

# 定義 Godot 執行檔路徑 (macOS 預設路徑)
# 如果您的 Godot 安裝在其他地方，請修改這裡
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"

# 取得腳本所在的目錄 (即專案根目錄)
PROJECT_PATH="$(cd "$(dirname "$0")" && pwd)"

echo "---------------------------------------------------"
echo "正在啟動 Miningame Headless Server..."
echo "專案路徑: $PROJECT_PATH"
echo "Godot路徑: $GODOT_BIN"
echo "---------------------------------------------------"

# 執行 Godot 並將輸出同時顯示在終端與寫入 server.log
# 2>&1 代表將錯誤輸出 (stderr) 也導向標準輸出 (stdout)
"$GODOT_BIN" --path "$PROJECT_PATH" --headless --server 2>&1 | tee server.log
