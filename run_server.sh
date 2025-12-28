#!/bin/bash

# 取得腳本所在的目錄 (即專案根目錄)
PROJECT_PATH="$(cd "$(dirname "$0")" && pwd)"
GODOT_BIN=""

# 偵測作業系統
OS="$(uname -s)"

echo "---------------------------------------------------"
echo "正在啟動 Miningame Headless Server..."
echo "作業系統: $OS"
echo "專案路徑: $PROJECT_PATH"

if [ "$OS" = "Darwin" ]; then
    # macOS 預設路徑
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ "$OS" = "Linux" ]; then
    # Linux: 優先尋找目錄下的 Godot 執行檔 (通常是 Godot_vX.X.X_linux.x86_64)
    # 搜尋當前目錄下含有 "Godot" 且可執行的檔案
    GODOT_BIN=$(find "$PROJECT_PATH" -maxdepth 1 -name "*Godot*linux*" -type f -executable | head -n 1)
    
    # 如果專案目錄下找不到，嘗試往上一層目錄找 (例如 workspace root)
    if [ -z "$GODOT_BIN" ]; then
        GODOT_BIN=$(find "$PROJECT_PATH/.." -maxdepth 1 -name "*Godot*linux*" -type f -executable | head -n 1)
    fi
    
    # 如果找不到，嘗試使用系統路徑的 godot 指令
    if [ -z "$GODOT_BIN" ]; then
        if command -v godot &> /dev/null; then
            GODOT_BIN="godot"
        fi
    fi
else
    echo "未知的作業系統: $OS"
    exit 1
fi

# 檢查是否找到 Godot
if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ] && [ "$GODOT_BIN" != "godot" ]; then
    echo "錯誤: 找不到 Godot 執行檔！"
    echo "---------------------------------------------------"
    if [ "$OS" = "Linux" ]; then
        echo "請下載 Godot Headless Server (Linux) 並放入此目錄。"
        echo "例如: wget https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_linux.x86_64.zip"
        echo "      unzip Godot_v4.5.1-stable_linux.x86_64.zip"
        echo "      chmod +x Godot_v4.5.1-stable_linux.x86_64"
    else
        echo "請確保 Godot 安裝於 /Applications/Godot.app"
    fi
    exit 1
fi

echo "使用 Godot: $GODOT_BIN"
echo "---------------------------------------------------"

# 執行 Godot
# 2>&1 代表將錯誤輸出 (stderr) 也導向標準輸出 (stdout)
# 執行 Godot
# 2>&1 代表將錯誤輸出 (stderr) 也導向標準輸出 (stdout)
"$GODOT_BIN" --path "$PROJECT_PATH" --headless --server --port=17777"$@" 2>&1 | tee server.log

