# 交接：進行中的狀態

> 新 session 開始時讀這份，接著做。
> 只放「還在變動」的東西：已定案的決策在 `CLAUDE.md`，查證過的事實在 `docs\findings.md`。
> 每次 commit 時一起更新（`CLAUDE.md` §11）。內容是「現在」的快照：過時的直接改掉，不累積。

最後更新：2026-10-13

---

## 現在在做

- **測試用的主控台指令：`gfgwall()` 生成牆、`gfgtarget()` 生成靶子**（使用者 2026-10-13 要求）
  - 用途：鏡頭版後座力只剩「看牆上的箭是不是插在準心附近」沒測；另外要測鎖定（Z 鍵）時的行為
  - 寫好、wcc_lite 編譯通過，**等使用者進遊戲測試**
  - 做法與出處：`findings.md` §15.2

## M2 進度

| 項目 | 狀態 | 出處 |
|---|---|---|
| 全自動 600 RPM | 實測通過 | `findings.md` §13.15、§13.17 |
| 彈匣 30 發、換彈 | 實測通過 | `findings.md` §13.13、§13.15 |
| 點射 | 實測通過 | `findings.md` §13.17 |
| 後座力（鏡頭版） | 實測通過，只剩「牆上的箭」沒測 | `findings.md` §14.6、§14.7 |
| 散布狀態（站立／移動／跳躍） | `findings.md` 還沒有實作紀錄 | `CLAUDE.md` §10 |

## 沒 commit 的檔案

| 檔案 | 內容 | 狀態 |
|---|---|---|
| `workspace\scripts\local\gfg_test.ws`（新檔） | `gfgwall()`、`gfgtarget()` | 編譯通過，未實測 |
| `workspace\scripts\local\gfg_ak47.ws` | `aim:` 紀錄改記 `displayTarget=`、`hardLock=`、`combatMusic=`（拿掉已驗證的 `camOffset`、`theCamera-gameCam`） | 編譯通過，未實測 |

照 `CLAUDE.md` §10：使用者測試回報後才 commit。

## 下一步

1. 使用者測試（步驟見下）
2. 讀 `editor.log` 的 `[Script_GFG]`：
   - `test wall: spawned=… pos=… heading=…`、`test wall box N: min=… max=…`（確認牆的大小、朝向：§15.2 的推論）
   - 打牆時 `aim: distance=…`（約 10 公尺＝射線打到牆）
   - `test target: spawned … hostile=true immortal=true`
   - 打靶子時 `aim: … displayTarget=… hardLock=… combatMusic=…`（原版自動瞄準的條件）
3. 牆的位置或朝向不對 → 依外框修正 `GfgSpawnTestWall` 的旋轉與位移
4. 沒問題就 commit 兩個腳本；`CLAUDE.md` §12「測試用靶子」補上這兩個指令

### 測試步驟

1. 套用腳本：遊戲開著時，REDkit 的 **Tools → Debuggers → Reload scripts**
2. 牆：主控台 `gfgwall()` → 面前約 8 公尺出現一面素面牆（高約 4.75 公尺、寬約 5 公尺）→ 對著牆連射，看箭插的位置和準心
3. 靶子：先轉向沒有牆的方向，主控台 `gfgtarget()` → 面前約 8 公尺出現一個盜賊
   - 按 Z 鎖定；射擊；確認打得到（受擊動作、血條）、不反擊、不會死（血最多扣到剩 1）
4. 指令可以指定距離，例：`gfgwall(15)`、`gfgtarget(5)`

## 已知限制（還沒處理）

- 停火後鏡頭轉回原位：沿用 §14.4 推測的衰減公式（約 0.2～0.3 秒轉回），沒改
- 前兩發沒有後座力：彈道資料的前兩發在同一點（`findings.md` §14.3）
- 戰鬥中鎖定敵人時，原版讓箭自動射向敵人身體（`playerBoltProjectile.ws:353-377`）
- 弩箭飛行距離上限 25 公尺（`playerBoltProjectile.ws:348`）
- 每發轉完的時間 `GfgKickTime` 目前 0.1 秒，可調
- 靶子不會死，血最多扣到剩 1 點；扣到底之後就看不出傷害

## 試過、放棄的做法

- 鏡頭版第一版：每發在開火那一格一次轉完 → 一頓一頓的（`findings.md` §14.4、§14.6）
- 準心版（鏡頭不動、準心照彈道移動）：`theCamera` 的位置不是畫面上的鏡頭，準心亂跳（§14.5）；使用者決定回到鏡頭版（§14.6）
- 靶子用尾聲的訓練木樁 `q505_training_dummy.w2ent`：`CActor`、沒有 AI，看不出有沒有血量、能不能被鎖定 → 改用真的敵對角色（§15.1、§15.2）
- 在 Bash 的 heredoc 裡寫 `\\`：會變成單一個 `\`，用 Python 替換含路徑的字串會對不上 → 改用 Edit 工具
