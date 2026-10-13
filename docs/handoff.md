# 交接：進行中的狀態

> 新 session 開始時讀這份，接著做。
> 只放「還在變動」的東西：已定案的決策在 `CLAUDE.md`，查證過的事實在 `docs\findings.md`。
> 每次 commit 時一起更新（`CLAUDE.md` §11）。內容是「現在」的快照：過時的直接改掉，不累積。

最後更新：2026-10-13

---

## 現在在做

- **測試用的主控台指令：在面前生成「牆」和「可以鎖定、攻擊的靶子」**（使用者 2026-10-13 要求）
  - 用途：鏡頭版後座力只剩「看牆上的箭是不是插在準心附近」沒測，因為測試關卡沒有牆、也沒有靶子
  - 調查中的候選（出處見 `findings.md`，寫好後補章節）：
    - 牆：`dlc\bob\data\environment\architecture\grey_box_blockout\brick_wall_system\entities\wall_super_wide.w2ent`（模型在 `content0\collision.cache` 的名稱表裡 → 有碰撞資料）
    - 靶子：`characters\npc_entities\crowd_npc\bandit\bandit_lvl1.w2ent`，設成敵對＋強制「什麼都不做」的 AI（`DogNPC.ws:186-195` 的寫法）＋不死（`AIM_Immortal`）

## M2 進度

| 項目 | 狀態 | 出處 |
|---|---|---|
| 全自動 600 RPM | 實測通過 | `findings.md` §13.15、§13.17 |
| 彈匣 30 發、換彈 | 實測通過 | `findings.md` §13.13、§13.15 |
| 點射 | 實測通過 | `findings.md` §13.17 |
| 後座力（鏡頭版） | 實測通過，只剩「牆上的箭」沒測 | `findings.md` §14.6、§14.7 |
| 散布狀態（站立／移動／跳躍） | `findings.md` 還沒有實作紀錄 | `CLAUDE.md` §10 |

## 沒 commit 的檔案

- 無

## 下一步

1. 寫 `workspace\scripts\local\gfg_test.ws`：`gfgwall()`、`gfgtarget()` 兩個主控台指令，wcc_lite 編譯
2. 使用者測試：牆有沒有擋在正前方、箭插在準心附近嗎；靶子能不能用 Z 鎖定、打得到、不反擊
3. 回報後 commit，並把查證結果寫進 `findings.md`

## 已知限制（還沒處理）

- 停火後鏡頭轉回原位：沿用 §14.4 推測的衰減公式（約 0.2～0.3 秒轉回），沒改
- 前兩發沒有後座力：彈道資料的前兩發在同一點（`findings.md` §14.3）
- 戰鬥中鎖定敵人時，原版讓箭自動射向敵人身體（`playerBoltProjectile.ws:353-377`）
- 弩箭飛行距離上限 25 公尺（`playerBoltProjectile.ws:348`）
- 每發轉完的時間 `GfgKickTime` 目前 0.1 秒，可調

## 試過、放棄的做法

- 鏡頭版第一版：每發在開火那一格一次轉完 → 一頓一頓的（`findings.md` §14.4、§14.6）
- 準心版（鏡頭不動、準心照彈道移動）：`theCamera` 的位置不是畫面上的鏡頭，準心亂跳（§14.5）；使用者決定回到鏡頭版（§14.6）
- 靶子用尾聲的訓練木樁 `q505_training_dummy.w2ent`：`CActor`、沒有 AI，看不出有沒有血量、能不能被鎖定 → 改用真的敵對角色（`findings.md` §15.1）
