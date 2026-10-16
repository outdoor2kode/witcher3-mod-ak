#!/bin/bash
# 這個專案的狀態列（.claude/settings.local.json 的 statusLine，蓋過 ~/.claude/settings.json 的設定）
# 1. 把 context 使用率記到暫存檔，給 context-check.sh 用：
#    hook 的輸入沒有使用率，狀態列的輸入才有（官方文件 statusline 的 context_window.used_percentage、hooks 的 Common input fields）
# 2. 畫面照舊：交給使用者原本的 ~/.claude/statusline.sh
input=$(cat)

sid=$(jq -r '.session_id // empty' <<<"$input")
pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
if [ -n "$sid" ] && [ -n "$pct" ]; then
    dir=/tmp/claude/gfg-context
    mkdir -p "$dir"
    printf '%s\n' "$pct" > "$dir/$sid.pct"
fi

printf '%s' "$input" | bash "$HOME/.claude/statusline.sh"
