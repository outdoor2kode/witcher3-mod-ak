# 交接：進行中的狀態

> 新 session 開始時讀這份，接著做。
> 只放「還在變動」的東西：已定案的決策在 `CLAUDE.md`，查證過的事實在 `docs\findings.md`。
> 每次 commit 時一起更新（`CLAUDE.md` §11）。內容是「現在」的快照：過時的直接改掉，不累積。

最後更新：2026-10-15（凌晨，使用者去睡了，白天接著做）

---

## 現在在做

- **M3 模型**：AK 已經出現在遊戲裡 Geralt 的左手，方向、上下都對；**但遊戲裡沒有顏色**（整把灰白色），編輯器預覽有顏色
  - 詳細的過程、證據、指令都在 `docs\m3.md`，**接著做就讀那份**；重點章節：
    - 「第 3 步」：`tools\m3_build_ak.py`（AK 轉方向、放到握把、匯出 FBX）
    - 「第 4 步：準備好的檔案」：`tools\m3_textures.py`、材質 XML、檔案位置
    - 「第一次匯入的模型沒用到骨頭群組」「改用 NODE 模式」：為什麼 FBX 是現在這樣
    - 「第一次進遊戲」：顏色問題的線索
  - 使用者 2026-10-14～15 的決定：原尺寸（比例 1.0）、用 `body_hd`（已含彈匣）、Blender 的部分由 Claude 寫腳本、貼圖腳本、物品 XML 改 `equip_template`（都同意了）
- **拿掉偵測紀錄：編譯通過、未實測、未 commit**（使用者 2026-10-14 同意；`findings.md` §25）
  - `gfg_ak47.ws` 的 `LogChannel` 42 行全部拿掉；只為記錄而寫的包裝、欄位一起拿掉
  - 2026-10-15 使用者有進遊戲開槍（看 AK 外觀），但沒照下面的清單測 → 還不算通過
- 規則（`CLAUDE.md` §11）：自己寫任何新東西前先問；有現成的就直接用
- 範圍（`CLAUDE.md` §7）：只做 AK 本身

### 跟使用者溝通（2026-10-15 學到的）

- 使用者有軟體工程背景，但不熟 REDkit、3D 模型、Blender，**想學**：解釋時用白話，可以用軟體工程的比喻（例：蒙皮連結像用骨頭名稱做 join、實體模板像 prefab）
- 使用者不想在 Blender 裡找視角、按快捷鍵：需要目視時，Claude 用 Blender 背景模式渲染成圖片給他看（雙擊就能開）
- REDkit 的操作請使用者做，步驟要寫到「點哪裡、按哪個按鈕」；沒實測過的介面要說明，請他截圖

## AK 現在怎麼做出來的（重做時照這個順序）

| # | 做什麼 | 誰 | 產物 |
|---|---|---|---|
| 1 | `tools\m3_build_ak.py`（指令在 `docs\m3.md`「第 3 步」） | Claude | `assets\ak47\gfg_ak47.fbx`（只有一個叫 `handle` 的模型，頂點在 `handle` 骨頭座標系）、`gfg_ak47_m3.blend`（目視用） |
| 2 | `tools\m3_textures.py`（指令在 `docs\m3.md`「第 4 步：準備好的檔案」） | Claude | `assets\ak47\gfg_ak47_d01.png`、`gfg_ak47_n01.png`（2048，法線圖的 alpha 是粗糙度） |
| 3 | REDkit 匯入貼圖：資料夾 `dlc\gunforgeralt\data\items\weapons\gfg_ak47\` 右鍵 → Import → 2D Texture；群組 `WorldDiffuse`、`NormalmapGloss` | 使用者 | `gfg_ak47_d01.xbm`、`gfg_ak47_n01.xbm` |
| 4 | REDkit 匯入模型：右鍵 → Import → Mesh；`importAsSkinnedMesh` = true、`xmlMetadataLocation` = `assets\ak47\gfg_ak47.xml`；接著的「Import mesh」選材質對話框按 **Cancel** | 使用者 | `gfg_ak47.w2mesh` |
| 4' | 只換模型時：Mesh editor → **Reimport** → **Mesh only** → Save（材質會保留） | 使用者 | |
| 5 | 實體模板 `gfg_ak47.w2ent`：十字弩模板的複本，模型元件 `witcher_crossbow_lvl1` 的 `mesh` 指到 AK（已完成、已 commit） | — | |
| 6 | `test.reddlc` 的實體模板掛載、物品 XML 的 `equip_template = "gfg_ak47"`（已完成、已 commit） | — | |

- 改了 XML、`.reddlc`、模型後，都要從 REDkit 重開遊戲

## M2 進度

| 項目 | 狀態 | 出處 |
|---|---|---|
| 全自動 600 RPM | 實測通過 | `findings.md` §13.15、§13.17 |
| 彈匣 30 發、換彈 | 實測通過 | `findings.md` §13.13、§13.15 |
| 點射 | 實測通過 | `findings.md` §13.17 |
| 後座力（鏡頭版） | 實測通過 | `findings.md` §14.6、§14.7 |
| 散布（站立／移動、連發累積、停火回復） | 實測有作用 | `findings.md` §16.3、§16.4 |
| 衝刺 | 衝刺中不開火（使用者選）；實測通過 | `findings.md` §17.10、§17.11 |
| 跳躍 | 空中不開火（使用者選）；起跳不收槍；實測通過 | `findings.md` §17.11 |
| 一般跑步（只按 W） | 實測能連射、會舉槍 | `findings.md` §17.7、§17.9 |
| 收槍 | 只在換成其他道具時收（實測，使用者同意維持） | `findings.md` §17.8、§17.9 |
| 射程 208 公尺 | 實測通過 | `findings.md` §18 |
| 牆壁、地面上的箭 | 不限時間、最多 100 支；實測通過 | `findings.md` §18.5 |
| 換彈後的姿勢 | 一律舉槍；實測通過 | `findings.md` §19 |
| 附近有敵人時移動 | 照野外的規則跑、舉槍姿勢；實測通過 | `findings.md` §20.10～§20.12 |
| Z 鎖定、鎖定時的準心 | 實測通過 | `findings.md` §20.7、§20.12、§20.13 |
| 背對怪物跑時的上半身 | 固定往右轉、最多扭 150°；實測通過 | `findings.md` §21 |
| 騎馬上下馬、主動收槍（C） | 實測通過 | `findings.md` §22、§23 |
| 騎馬時左鍵開槍 | 實測通過 | `findings.md` §24 |
| 馬上法印輪盤一開就關 | 已修正、實測正常；卡住的情況沒有直接重現（待目測） | `findings.md` §24.8、§24.9 |

## 沒 commit 的檔案

- `workspace\scripts\local\gfg_ak47.ws`：拿掉偵測紀錄（編譯通過、未照清單實測）
- `.gitignore` 排除、不 commit 的：
  - `assets\ak47\` 的 `.blend`、`.fbx`、`.png`：腳本的輸出（材質 XML `gfg_ak47.xml` 有 commit）
  - `workspace\dlc\gunforgeralt\data\items\weapons\gfg_ak47\` 的 `.w2mesh`、`.xbm`：REDkit 匯入的產物（照上表的步驟可以重做）
  - `thumbnails\`：REDkit 的縮圖

## 下一步

1. **M3 顏色問題：先做這個測試**（分辨是「我們的貼圖檔」還是「材質」的問題）
   1. 打開 `gfg_ak47.w2mesh` → **Materials** 分頁 → 選 `weapon_rif_ak47`
   2. 把 `Diffuse` 暫時換成原版的 `items\weapons\ranged\witcher_crossbow\model\witcher_crossbow_lvl1_d01.xbm`（Asset Browser 點選 → 綠色箭頭）→ 存檔
   3. 開遊戲、`additem('gfg_ak47')`：
      - 有顏色（咖啡色、花紋亂掉）→ 原版貼圖讀得到，問題在我們的 `.xbm`：可疑的是遊戲裡沒 cook 的貼圖怎麼串流（`docs\m3.md`「第一次進遊戲」的線索）；我們的 `.xbm` 比原版 uncook 的多了 `importFile`、`sourceData`
      - 還是灰的 → 問題在材質或模型（例：NODE 模式的模型在遊戲裡的材質綁定）
   4. 測完把 `Diffuse` 換回 `dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47_d01.xbm`
   - Materials 分頁的介面沒看過，找不到請使用者截圖
   - **REDkit 重開時 `editor.log` 會被整個重寫**：遊戲測完、重開 REDkit 之前，先讓 Claude 讀紀錄
2. M3 其他還沒做的：
   - `bolt` slot 移到槍口：箭現在從 `chord` 骨頭（AK 彈匣附近）出來；槍口在十字弩模型座標 (9.34, -0.21, 66.91) 公分（`docs\m3.md`「第 3 步」），要換成 `handle` 骨頭座標（乘上 `handle` 的綁定矩陣）再設到 slot
   - 握把位置、槍托會不會穿過手臂：進遊戲看；要調就用 `m3_build_ak.py --offset`
3. 拿掉紀錄的測試（下面「測試方式補充」）；通過就 commit `gfg_ak47.ws`
4. 輪盤的待驗證項目（`findings.md` §24.9）：使用者下次騎馬時順便目測
5. 之後再做（使用者決定時機）：傷害平衡（CS2 36、爆頭 ×4）、子彈方向與速度、M4 聲音（要先確認 Wwise 版本：`CLAUDE.md` §3）
6. M5 候選：持槍衝刺／跳躍的動畫（`findings.md` §17.10）；跳躍散布（§16.2）

### 測試方式補充

- **拿掉紀錄之後的測試**（`findings.md` §25）：在地面按 Reload scripts，照常玩一輪
  - 地面：左鍵連射到換彈、接著射；Z 鎖定時準心在目標身上；背對怪物跑邊射；C 收槍；衝刺、跳躍時不開火，落地還按著就接著射
  - 騎馬：叫馬、上馬 → 左鍵拿出、連射、換彈後接著射；中鍵射一發後馬要能照常操作；C 收槍後能下馬
  - 預期：和拿掉之前一樣；`editor.log` 裡不再有 `GFG` 的紀錄
- **輪盤的目測**（§24.9）：用 E 下馬 → 再上馬 → 直接在馬上按 Tab：輪盤照原版規則（點一下開著），不會一開就關
- 騎馬時重載腳本可能卡住下馬鎖（§22.4）→ 一律在地面重載
- 遊戲開著時改腳本：REDkit 的 **Tools → Debuggers → Reload scripts**；**使用者沒按就不會套用**
- 遠處的怪物：`spawn('wolf', 1, 60, true)`（`CLAUDE.md` §12）
- REDkit 的 Mesh editor 預覽：底下的環境選單預設 `ENV - OFF` 會全黑，換成任何環境（例：`usm\battle_02_noblue_lights.env`）才看得到貼圖；Entity Editor：在 Asset Browser 雙擊 `.w2ent` 開
- M3 用過的暫存分析腳本（在 session 的暫存資料夾，**新 session 不會有**；要再用得先問使用者）：
  - Blender Workbench 正交渲染（AK、十字弩各角度的預覽圖）
  - 用 Blender 內建的 `io_scene_fbx.parse_fbx` 解析 FBX（GlobalSettings、節點、Cluster、Pose）
  - 用 Blender＋numpy 算 PNG 各通道的統計
  - `.w2mesh` 骨頭名稱和綁定矩陣：已經做進 `tools\m3_build_ak.py` 的 `read_rig_matrices()`

## 已知限制（還沒處理）

- **M3：遊戲裡 AK 沒有顏色**（上面「下一步」1）
- M3：箭從 AK 彈匣附近伸出來（`bolt` slot 還在 `chord` 骨頭）
- M3：Mesh editor 的預覽裡 AK 轉了方向：模型存在 `handle` 骨頭的座標系裡，正常（`docs\m3.md`「改用 NODE 模式」）
- 傷害還是 M1 的佔位值：十字弩 1 的 2 倍（`gunforgeralt_items.xml` 的 `attack_power`）；CS2 的 36、爆頭 ×4 沒套
- 原版自動瞄準：有戰鬥音樂、畫面目標是人型時，箭飛向身體不照準心（`findings.md` §15.2、§20.13；使用者：先不管）
- 箭速 60 公尺／秒、發射角度 5°：遠的目標要飛一段時間，中段會比直線高（`findings.md` §18.2；使用者：先不管）
- 停火後鏡頭轉回原位：沿用推測的衰減公式（約 0.2～0.3 秒轉回）
- 前兩發沒有後座力：彈道資料的前兩發在同一點（`findings.md` §14.3）
- 每發轉完的時間 `GfgKickTime` 目前 0.1 秒，可調
- 開始墜落、攀爬、翻滾仍會收槍（`findings.md` §17.4）
- 拿著 AK 時不能存檔（存檔鎖：`findings.md` §17.8、§20.7）；另外 17 個動作也被鎖，使用者選維持原版（§20.12）
- 戰鬥中 AK 常被收起又拔出（`findings.md` §20.2），原因沒查
- 騎馬沒測過的（§24.5）：騎馬跳躍時拿著 AK 的動作、拿著 AK 施法
- 每輪連射第 30 發寫一行錯誤 `Value '30' not handled`（不影響：`findings.md` §24.6）
- `UpdateLookAtVariables` 的包裝每個 session 寫一次 `Accessing invalid handle` 警告；原因沒查，沒看到影響

## 試過、放棄的做法

- 鏡頭版後座力第一版：每發在開火那一格一次轉完 → 一頓一頓的（`findings.md` §14.4、§14.6）
- 準心版（鏡頭不動、準心照彈道移動）：使用者決定回到鏡頭版（§14.5、§14.6）
- 自己寫測試指令 `gfgwall()`、`gfgtarget()`：使用者要求刪除（§15.2）
- `CanSprint` 包裝裡用 `super.CanSprint`：官方沒寫 annotation 裡 `super` 的行為 → 改成暫時清空 `rangedWeapon`（§17.6）
- 卡住的推測，偵測後都排除：移動鎖、戰鬥動作沒結束（§20.4）、被狼的身體擋住（§20.9）、`RotateToTarget`（§20.10）
- 只改 `fullBodyAnimWeight`（§20.5）：上半身動畫圖不看它（§20.10）
- **M3：帶骨架的蒙皮 FBX**（`docs\m3.md`「第一次匯入的模型沒用到骨頭群組」）：
  - 照 Wiki 的匯出設定（Null、Secondary -Y）：REDkit 用 NODE 模式，骨頭變成模型名稱；而且 `handle` 的方向差 180°
  - 改成和 REDkit 匯出的 FBX 同樣的結構（骨架節點 Root、Secondary Y、Up Z、Forward -Y）：還是 NODE 模式
  - → 改用「不帶骨架、模型叫 `handle`、頂點先換到骨頭座標」的做法
- M3：`wcc_lite import` 測試 FBX 匯入：用空的暫存資料夾當 depot，300 秒沒有輸出就中止；而且沒有蒙皮匯入的選項
- M3：第一版 AK 上下顛倒（猜十字弩的上方是 +X）→ 照使用者的遊戲截圖改成 -X
- **在 Bash 的 heredoc 裡寫含反斜線的 Python**：`\\` 會變成 `\`，`\a` 會變成控制字元（2026-10-15 弄壞過交接檔一次）→ 含路徑的字串用 Write／Edit 工具，或在 Python 裡用 `chr(92)`
