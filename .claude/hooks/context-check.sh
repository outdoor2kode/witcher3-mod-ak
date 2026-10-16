#!/bin/bash
# context 用到 42% 時提醒（45% 壓縮前先收尾）：Claude 寫交接、使用者 /clear（CLAUDE.md §11）
# .claude/settings.local.json 掛在 PostToolUse（任務進行中）和 UserPromptSubmit（使用者送出訊息時）
# 使用率由 statusline.sh 記在暫存檔；到門檻後每個 session 只提醒一次，降回門檻以下（/compact、/clear）再重新計算
threshold=42
dir=/tmp/claude/gfg-context

input=$(cat)
# 一次取出要的欄位：這個 hook 每次用工具都會跑，jq 每呼叫一次約 40 毫秒
IFS=, read -r sid event agent <<<"$(jq -r '[.session_id, .hook_event_name, .agent_id] | map(. // "") | join(",")' <<<"$input")"
[ -n "$sid" ] || exit 0
# subagent 裡用工具也會觸發（輸入有 agent_id）；提醒要給主對話
[ -z "$agent" ] || exit 0

[ -f "$dir/$sid.pct" ] || exit 0
read -r pct < "$dir/$sid.pct"
pct_int=${pct%.*}
[[ $pct_int =~ ^[0-9]+$ ]] || exit 0

marker="$dir/$sid.reminded"
if (( pct_int < threshold )); then
    [ -f "$marker" ] && rm -f "$marker"
    exit 0
fi
[ -f "$marker" ] && exit 0
touch "$marker"

cat <<EOF
{
  "systemMessage": "Context 已用 ${pct}%（門檻 ${threshold}%）：Claude 會一邊做一邊寫交接，這次回覆最後提醒你 /clear",
  "hookSpecificOutput": {
    "hookEventName": "${event}",
    "additionalContext": "Context 已用 ${pct}%，到了 ${threshold}% 的門檻（CLAUDE.md §11）：手上的任務照做，同時更新 docs/handoff.md；這次回覆的最後提醒使用者 /clear。"
  }
}
EOF
