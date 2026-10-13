# 交接：進行中的狀態

> 新 session 開始時讀這份，接著做。
> 只放「還在變動」的東西：已定案的決策在 `CLAUDE.md`，查證過的事實在 `docs\findings.md`。
> 每次 commit 時一起更新（`CLAUDE.md` §11）。內容是「現在」的快照：過時的直接改掉，不累積。

最後更新：2026-10-13

---

## 現在在做

- **回到核心目標：做出 AK-47**（使用者 2026-10-13）
- **跑射、跳射**：原因已查（`findings.md` §17.1～§17.5）；使用者選「讓 AK 能衝刺開槍」「做跳射」
  - 已實作、編譯通過、**未實測**（`findings.md` §17.6）：衝刺開槍、起跳不收槍、扳機紀錄加 `context=`／`inAir=`
  - 一般跑步：這次 723 發沒有一發是 `PMT_Run`，原因未確定（§17.3），和上面一起測
  - 空中的扳機：先看實測的 log，再決定怎麼做（跳躍中的按鍵情境 `JumpClimb` 沒有綁左鍵）
- 走路散布：使用者選「先不調」（能跑射之後，開槍時的速度會變）
- 規則（`CLAUDE.md` §11）：自己寫任何新東西前先問；有現成的（遊戲內建、網路上別人做過的）就直接用
- 範圍（`CLAUDE.md` §7）：只做 AK 本身，AK 以外的物理效果照遊戲原本的行為

## M2 進度

| 項目 | 狀態 | 出處 |
|---|---|---|
| 全自動 600 RPM | 實測通過 | `findings.md` §13.15、§13.17 |
| 彈匣 30 發、換彈 | 實測通過 | `findings.md` §13.13、§13.15 |
| 點射 | 實測通過 | `findings.md` §13.17 |
| 後座力（鏡頭版） | 實測通過；箭不會插在牆上，照範圍規則不處理 | `findings.md` §14.6、§14.7、§15.2 |
| 散布（站立／移動、連發累積、停火回復） | 實測有作用 | `findings.md` §16.3、§16.4 |
| 邊衝刺邊射 | 寫好、未實測 | `findings.md` §17.2、§17.6 |
| 邊跳邊射 | 第一步（起跳不收槍）寫好、未實測 | `findings.md` §17.4、§17.6 |
| 一般跑步（只按 W） | 原因未確定，等測試 | `findings.md` §17.3 |

## 沒 commit 的檔案

- `workspace/scripts/local/gfg_ak47.ws`：衝刺開槍、起跳不收槍、扳機紀錄（§17.6）；實測通過再 commit

## 下一步

1. 使用者測試（已給步驟）→ 讀 `editor.log` 的 `[Script_GFG]`：
   - 只按 W 跑著開槍：每發 `spread:` 的 `moveType` 是 `PMT_Run`（能跑）還是 `PMT_Walk`
     - 還是 `PMT_Walk` → 提議加一行診斷紀錄，記錄跑步條件的各個值（`locomotionDirectController.ws:933-938`），要先問
   - 衝刺開槍：`moveType=PMT_Sprint`、速度約 7.0；按 Shift 不收槍（戰鬥中也是）
   - 起跳：有 `jump: AK kept`、沒有 `crosshair hidden`；看 `trigger=false` 的 `context=` 是不是 `JumpClimb`
2. 依跳躍的 log 決定空中扳機的做法（先跟使用者說明再改）
3. 跳射能用之後：空中的散布（CS2 跳躍 8.41°：`findings.md` §16.2）要不要加，問使用者
4. 之後的候選（使用者還沒選）：鎖定敵人時的原版自動瞄準（`findings.md` §15.2）、M3 模型、M4 聲音

### 測試方式補充

- 牆、建築、靶子：REDkit 編輯器直接放（`CLAUDE.md` §12，Wiki 頁面 15499265），或原版 `spawnPath`
- 遊戲開著時改腳本：REDkit 的 **Tools → Debuggers → Reload scripts**

## 已知限制（還沒處理）

- 鎖定敵人且有戰鬥音樂時，原版讓箭自動射向敵人身體（`findings.md` §15.2 實測）
- 弩箭飛行距離上限 25 公尺（`playerBoltProjectile.ws:348`）
- 打盜賊時傷害處理記錄「action deals no damage」，盜賊卻一發就死；死因沒有查完（`findings.md` §15.2）
- 停火後鏡頭轉回原位：沿用推測的衰減公式（約 0.2～0.3 秒轉回）
- 前兩發沒有後座力：彈道資料的前兩發在同一點（`findings.md` §14.3）
- 每發轉完的時間 `GfgKickTime` 目前 0.1 秒，可調
- 開始墜落、攀爬、翻滾仍會收槍（`findings.md` §17.4），還沒改

## 試過、放棄的做法

- 鏡頭版第一版：每發在開火那一格一次轉完 → 一頓一頓的（`findings.md` §14.4、§14.6）
- 準心版（鏡頭不動、準心照彈道移動）：使用者決定回到鏡頭版（§14.5、§14.6）
- 自己寫測試指令 `gfgwall()`、`gfgtarget()`：使用者要求刪除，牆和靶子用原版 `spawnPath` 等指令（§15.2、`CLAUDE.md` §12）
- 在 Bash 的 heredoc 裡寫 `\\`：會變成單一個 `\`，用 Python 替換含路徑的字串會對不上 → 改用 Edit 工具
- `CanSprint` 包裝裡用 `super.CanSprint`：編譯會過，但官方沒寫 annotation 裡 `super` 的行為 → 改成暫時清空 `rangedWeapon`（§17.6）
