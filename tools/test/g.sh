# 測試輔助：Claude 操作 REDkit、遊戲用的 bash 函式（Git Bash 裡 source）
# 2026-10-19 從 session 暫存整理進專案（第 41 項回顧：好用的輔助放在暫存，換 session 就找不到；docs\retrospective.md）
#
# 用法
#   P=<截圖放哪>; source tools/test/g.sh   ← 不給 P：%TEMP%\claude\gfg-test；Claude 用 session 暫存（例 <scratchpad>/desk）
#   分號不能省：`P=… source …`（同一行沒分號）的 P 只在 source 期間有效，之後函式讀到空的 P（10-20 實測：寫到 /handles.sh 被拒）
#   Bash 工具每次呼叫都是新的 shell → 每次都要 source
#   第一次、REDkit 重開、AnimBrowser 重開：set_mw、set_gab（視窗 handle 存在 $P/handles.sh，之後 source 會讀回來）
#   除錯指令（gfgfree、gfgshots、gfgmag…）在同資料夾的 gfg_debug.ws：game_end → dbg_on → reload_edit → game_start；測完 dbg_off → reload_edit
#
# 前提：螢幕 1920x1080、REDkit 最大化、遊戲在 REDkit 裡跑
# 座標都是 10-16～10-19 截圖量的；介面不一樣（例：動畫多一條軌道、選單往上開）先截圖再改
# 每個函式是用過的最後一版；舊名寫在說明裡（搜得到）

T=$(cygpath -m "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")   # 這個資料夾
PROJ=$(cygpath -m "$(cd "$T/../.." && pwd)")                        # 專案
P="${P:-$(cygpath -m "$TEMP")/claude/gfg-test}"; mkdir -p "$P"      # 截圖、拼圖的輸出
D="powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PROJ/tools/desk.ps1"
LOG="/d/Program Files (x86)/Steam/steamapps/common/The Witcher 3 REDkit/bin/editor.log"
WS="$PROJ/workspace/scripts/local"
ANIMS="$PROJ/workspace/dlc/gunforgeralt/data/animations/gfg_ak47_geralt.w2anims"

# ===== 基本 =====
d() { $D "$@" >/dev/null; }                                                     # desk.ps1，不印輸出
shot() { $D shot "$P/$1.png" scale=${2:-0.5} >/dev/null; echo "$P/$1.png"; }   # 全螢幕截圖：shot 名稱 [縮放=0.5]
# 主控台打指令（~ 開、打字、Enter、~ 關）：con "god()" "settime(1, 12)" …
con() { for c in "$@"; do d key oem3; sleep 0.5; d keys "$c"; d key enter; sleep 0.6; d key oem3; sleep 0.4; done; }

# editor.log：先記下大小，之後只看新增的部分
logsize() { wc -c < "$LOG"; }   # 不用 stat：REDkit 開著檔案在寫時，目錄項的大小會落後 → 起點太前面、舊的紀錄被當成新的（專家訓練 tools\lab\l3.sh）
has_log() { tail -c +$(( $1 + 1 )) "$LOG" | grep -a -q "$2"; }   # has_log 起點 樣式
# wait_log 起點 樣式 秒數：每 0.5 秒看一次，出現就回來
wait_log() { local i; for ((i=0; i<$3*2; i++)); do has_log "$1" "$2" && return 0; sleep 0.5; done; return 1; }
# 起點之後我們的紀錄（[GFG]），去掉時間前綴：gfg_log 起點
gfg_log() { tail -c +$(( $1 + 1 )) "$LOG" | grep -a "Script_GFG\]" | sed 's/^.*Script_GFG\] //'; }

# ===== 視窗 handle =====
# desk.ps1 windows 的第一欄可能是 *（前景視窗）→ 抓 0x 開頭的那欄
[ -f "$P/handles.sh" ] && . "$P/handles.sh"
_save_handles() { printf 'MW=%s\nGAB=%s\n' "$MW" "$GAB" > "$P/handles.sh"; }
_handle() { $D windows | grep -a " editor " | grep -a "$1" | grep -o '0x[0-9A-Fa-f]*' | head -1; }
set_mw() { MW=$(_handle "REDkit"); _save_handles; echo "MW=$MW"; }                                    # REDkit 主視窗
set_gab() { GAB=$(_handle "AnimBrowser - .*gfg_ak47_geralt.w2anims"); _save_handles; echo "GAB=$GAB"; }   # 我們動畫組的 AnimBrowser
_dialog() { $D windows | grep -a "$1" | grep -o '0x[0-9A-Fa-f]*' | head -1; }                       # 對話框的 handle（標題含 $1）

# ===== REDkit =====
# 重載腳本：Tools (232,32) → Debuggers (280,478) → Reload scripts (540,638)；成功回 0（平常約 10 秒）
# 遊戲開著時滑鼠被鎖在遊戲裡、選單點不到 → 先 game_end；不要用 Script Studio 的 F7（CLAUDE.md §12）
reload_edit() {
  local o; d focus $MW; d click 232 32; sleep 0.7; d click 280 478; sleep 0.7; o=$(logsize); d click 540 638
  wait_log $o "Scriptables reloaded\|Script compilation failed\|Error\]\[Core\].*script" 40
  tail -c +$((o+1)) "$LOG" | grep -a "Scriptables reloaded\|failed\|Error\]\[Core\]" | tail -3 | cut -c1-200
  has_log $o "Scriptables reloaded"
}
# 除錯指令放進 workspace／拿出來（正本一直在 tools/test）；之後都要 reload_edit
dbg_on() { cp "$T/gfg_debug.ws" "$WS/gfg_debug.ws" && echo "gfg_debug.ws 放進 workspace → reload_edit"; }
dbg_off() {
  [ -f "$WS/gfg_debug.ws" ] || { echo "workspace 沒有 gfg_debug.ws"; return 0; }
  if cmp -s "$T/gfg_debug.ws" "$WS/gfg_debug.ws"; then rm "$WS/gfg_debug.ws"; echo "gfg_debug.ws 拿出 workspace → reload_edit"
  else echo "workspace 的 gfg_debug.ws 改過：先合併回 tools/test/gfg_debug.ws 再 dbg_off"; return 1; fi
}

# ===== 遊戲 =====
# 開遊戲：play game (650,86) → 一進去就 god()（編輯器鏡頭高，從空中掉下會摔死）→ 死了選 DEBUG RESURRECT → 關教學、中午、拿 AK（舊名 game_start3）
# 等級 1 就裝得上 AK（10-19 實測）→ 不打 setlevel；要比對傷害再打 setlevel(31)
game_start() {
  local o i; d focus $MW; o=$(logsize); d click 650 86
  wait_log $o "INPUT CONTEXT CHANGED" 40 || { echo "遊戲沒開起來：$(shot start_fail)"; return 1; }
  sleep 0.5; con "god()"; sleep 2
  if has_log $o "INPUT CONTEXT CHANGED Death\|CR4DeathScreenMenu::OnConfigUI"; then
    echo "死了，復活"; d move 150 950; sleep 0.3; d key escape; sleep 0.5; d key home; sleep 0.3; for i in 1 2 3; do d key down; sleep 0.3; done; d key enter
    wait_log $o "previousInputContext Death" 10
    sleep 2; con "god()"
  fi
  con "closeTutorialPopup()" "settime(1, 12)" "additem('gfg_ak47', 1, true)"
  echo "遊戲開好了"
}
# 結束遊戲回編輯器：點遊戲畫面（拿鍵盤焦點）→ F10 → 點編輯器畫面；F10 的結束紀錄有時晚 15 秒以上才寫 → 看兩次
game_end() {
  local o; d focus $MW; d click 860 555; sleep 0.4; o=$(logsize); d key f10
  wait_log $o "EndSession force fade off" 15 || wait_log $o "EndSession force fade off" 15 || { echo "F10 後 30 秒沒有結束紀錄：$(shot f10_fail)"; return 1; }
  d click 800 300; sleep 0.5
}
# 改了腳本後重開：結束 → 重載腳本 → 開遊戲 → 拿出 AK
restart_all() { game_end && reload_edit && game_start && ak_select; }
# 輪盤選弓弩格、不拿出：Tab 按住 → 輪盤教學（Quick Access Menu）每頁按 Esc 關（空白鍵在第二頁會連帶冥想）
# → 滑鼠往下（弓弩格）→ 放開 Tab；關過教學時 Tab 不算按著 → 再按一下確定
radial_select() {
  local o n=0 i; d focus $MW; o=$(logsize); d keydown tab; sleep 1.5
  for i in 1 2 3; do
    n=$(tail -c +$((o+1)) "$LOG" | grep -a -c "populateData - title :  Quick Access")
    [ "$n" -ge "$i" ] || break; d key escape; sleep 1.5
  done
  d rmove 0 300 10 15; sleep 0.4; d keyup tab; sleep 0.3
  if [ "$n" -ge 1 ]; then d keydown tab; sleep 0.3; d keyup tab; fi
  sleep 1
}
# 輪盤選 AK、左鍵拿出（舊名 ak_select2）
ak_select() { radial_select; d click 860 555; sleep 2; }
# AK 的狀態（要 gfg_debug.ws）：已射幾發、武器狀態、拿出來沒、彈匣在不在左手
ak_state() { local o; o=$(logsize); con "gfgshots()" "gfgmag()"; sleep 0.5; gfg_log $o; }
# 騎馬拿 AK（game_start、ak_select 之後）：中午、收槍、X 叫馬、instantMount、左鍵拿出、截圖
horse_start() { d focus $MW; con "settime(1, 12)"; d key c; sleep 1.5; d key x; sleep 6; con "instantMount('playerHorse')"; sleep 2.5; d click 860 555; sleep 2; shot horse_start; }
# 側面看換彈（第 39 項；要 gfg_debug.ws）：慢動作 → 剩 2 發 → R 換彈 → 13 秒後（彈匣到左手）開自由鏡頭 → 連拍 → 關鏡頭、恢復速度
# 自由鏡頭開著時 OnGameCameraTick 不跑（抓彈匣在裡面）→ 彈匣出來之後才開
# side_after 前綴 角度 距離 高度 [張數=14] [間隔毫秒=3000]：角度＝從 Geralt 正前方往左轉幾度；例 side_after fl_ 45 2.0 0.2
side_after() {
  local o t0; con "slow(0.04)" "gfgshots(28)"; o=$(logsize); d key r; t0=$(date +%s)
  while [ $(( $(date +%s) - t0 )) -lt 13 ]; do sleep 0.5; done
  con "gfgmag()" "gfgfree($2, $3, $4)"; $D burst "$P/$1" ${5:-14} ${6:-3000} rect=420,140,900,860 scale=0.6 | tail -1
  con "gfgfree(0, 0, 0, true)" "slow(1)"
  gfg_log $o | grep -a "magOut"
}

# ===== AnimBrowser（我們的動畫組；GAB） =====
# 匯入一段動畫：import_one <plain|local> <檔名.re>（對話框在上次的資料夾；不能多選；檔名要 gfg_ 開頭：CLAUDE.md §6.11）
# 清掉篩選 → 樹狀清單 Home、Left（收起）、Right（展開）、Down（動畫組那一行）→ 右鍵 (880,166) → plain (1006,245)／Additive I (Local) (1017,289)
# 右鍵選單跟「選取中的項目」，不是游標下的那一行；沒出現 Open files → 看有沒有 Recompression 對話框（按 Cancel）
import_one() {
  local mx my w i
  if [ "$1" = plain ]; then mx=1006; my=245; else mx=1017; my=289; fi
  d focus $GAB; d click 867 92; d key ctrl+a; d key delete; d key enter; sleep 1.2
  d click 760 300; sleep 0.3; d key home; sleep 0.3; d key left; sleep 0.3; d key right; sleep 0.5; d key down; sleep 0.4
  d click 880 166 right; sleep 0.8; d click $mx $my
  for i in $(seq 1 12); do w=$(_dialog "Open files"); [ -n "$w" ] && break; sleep 0.5; done
  [ -z "$w" ] && { echo "沒有對話框：$2"; $D windows | head -3; return 1; }
  d focus $w; d click 470 512; sleep 0.2; d key ctrl+a; $D type "$2" >/dev/null; d key enter
  for i in $(seq 1 30); do [ -z "$(_dialog "Open files")" ] && { echo "ok $2"; return 0; }; sleep 0.5; done
  echo "對話框沒關：$2"; $D windows | head -3; return 1
}
# 存動畫組：點 AnimBrowser 的工具列 (657,63) 拿焦點 → Ctrl+S → 印檔案時間（確認有寫）
save_gab() { d focus $GAB; d click 657 63; sleep 0.4; d key ctrl+s; sleep 4; echo "$(date -r "$ANIMS" +%T) $(stat -c %s "$ANIMS") bytes"; }
# 移除一段動畫：rm_anim 完整名稱（篩選後只能有這一筆；選單 Remove 在右鍵位置 +(61,13)）
rm_anim() {
  d focus $GAB; d click 867 92; d key ctrl+a; $D type "$1" >/dev/null; d key enter; sleep 1.2
  d click 812 184; sleep 0.8; d click 812 184 right; sleep 0.8; d click 873 197; sleep 1
}
# 加 simple event：add_ev 篩選字 事件名 秒數
# 篩選 (867,92) → 選第一筆 (812,184) → 時間軸右鍵 (600,460) → Add simple event (687,473) → 雙擊事件 (600,467) → eventName (1335,457)、startTime (1335,476) → 點下一列確定
add_ev() {
  d focus $GAB; d click 867 92; d key ctrl+a; $D type "$1" >/dev/null; d key enter; sleep 1.2
  d click 812 184; sleep 1; d click 600 460 right; sleep 0.8; d click 687 473; sleep 0.8
  d click 600 467 left 2; sleep 0.8
  d click 1335 457; sleep 0.4; d key ctrl+a; $D type "$2" >/dev/null; d key enter; sleep 0.5
  d click 1335 476; sleep 0.4; d key ctrl+a; $D type "$3" >/dev/null; d key enter; sleep 0.5
  d click 1180 515; sleep 0.5; d click 1150 600; sleep 0.3
}
# 加 duration event（第一條軌道；屬性欄已經開著時的位置）：add_dur 篩選字 事件名 起點 長度
# 時間軸右鍵 (600,460) → Add duration event (692,495) → 雙擊黃色條的圖示 (641,468) → eventName (1335,457)、startTime (1335,476)、duration (1335,552)
add_dur() {
  d focus $GAB; d click 867 92; d key ctrl+a; $D type "$1" >/dev/null; d key enter; sleep 1.2
  d click 812 184; sleep 1; d click 600 460 right; sleep 0.8; d click 692 495; sleep 0.8
  d click 641 468 left 2; sleep 0.8
  d click 1335 457; sleep 0.4; d key ctrl+a; $D type "$2" >/dev/null; d key enter; sleep 0.5
  d click 1335 476; sleep 0.4; d key ctrl+a; $D type "$3" >/dev/null; d key enter; sleep 0.5
  d click 1335 552; sleep 0.4; d key ctrl+a; $D type "$4" >/dev/null; d key enter; sleep 0.5
  d click 1180 514; sleep 0.5; d click 1150 600; sleep 0.3
}
# 在目前選取的動畫、某條軌道（列的螢幕 y）加 duration event：add_dur_row y 事件名 起點 長度 [選單那一項的 y]
# 右鍵 (600,y) → Add duration event (692, y+35) → 雙擊新方塊 (641, y+8) → 屬性欄
# 靠下面的軌道選單會往上開（舊名 add_dur_row4、add_dur_row5）：第 4 條 y≈605 → 選單 y=171；第 5 條 y≈655 → 222
add_dur_row() {
  local y=$1
  d focus $GAB; d click 600 $y right; sleep 0.8; d click 692 ${5:-$((y+35))}; sleep 0.8
  d click 641 $((y+8)) left 2; sleep 0.8
  d click 1335 457; sleep 0.4; d key ctrl+a; $D type "$2" >/dev/null; d key enter; sleep 0.5
  d click 1335 476; sleep 0.4; d key ctrl+a; $D type "$3" >/dev/null; d key enter; sleep 0.5
  d click 1335 552; sleep 0.4; d key ctrl+a; $D type "$4" >/dev/null; d key enter; sleep 0.5
  d click 1180 514; sleep 0.5; d click 700 750; sleep 0.5
}
# 加一條新軌道（軌道下面的空白處右鍵 → Add new track → 名稱）：add_track 名稱（軌道多了空白處會往下移）
add_track() {
  local w; d focus $GAB; d click 60 750 right; sleep 0.8; d click 135 761; sleep 1.2
  w=$(_dialog "Track name"); [ -z "$w" ] && { echo "沒有 Track name 視窗"; return 1; }
  d focus $w; d key ctrl+a; $D type "$1" >/dev/null; d key enter; sleep 0.8
}

# ===== 圖片（都在 $P，名稱不含 .png） =====
# 裁切放大：crop 輸入名 輸出名 x y w h [倍數=3]
crop() { powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$T/crop.ps1")" "$(cygpath -w "$P/$1.png")" "$(cygpath -w "$P/$2.png")" $3 $4 $5 $6 ${7:-3} | tail -1; }
# 拼成格子（每格左上角編號）：gridm 輸出名 每行張數 裁切x:y:w:h（0:0:0:0＝不裁） 圖1 圖2 …
gridm() { local out=$1 cols=$2 crop=$3 a=() f; shift 3; for f in "$@"; do a+=("$(cygpath -w "$P/$f.png")"); done; powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$T/grid.ps1")" "$(cygpath -w "$P/$out.png")" $cols $crop "${a[@]}" | tail -1; }
# 橫向拼成一張：mont 輸出名 圖1 圖2 …
mont() { local out="$1" a=() f; shift; for f in "$@"; do a+=("$(cygpath -w "$P/$f.png")"); done; powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$T/montage.ps1")" "$(cygpath -w "$P/$out.png")" "${a[@]}" | tail -1; }

[ -z "$MW" ] && echo "g.sh：先跑 set_mw（REDkit 主視窗）"
true
