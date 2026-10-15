# 交接：進行中的狀態

> 新 session 開始時讀這份，接著做。
> 只放「還在變動」的東西：已定案的決策在 `CLAUDE.md`，查證過的事實在 `docs\findings.md`。
> 每次 commit 時一起更新（`CLAUDE.md` §11）。內容是「現在」的快照：過時的直接改掉，不累積。

最後更新：2026-10-16 00:2x（查到站著時原版把右手臂換成另一段動畫；使用者選改原版動畫圖的曲線 → `tools\overlay_patch.py` 寫好、執行；等使用者進遊戲測）

---

## 現在在做

- **雙手持槍，走「用 Blender 改動畫」這條路**（使用者 2026-10-15 選；背景、證據、做法在 `docs\m3.md`，從「雙手持槍：初步查詢」到「右手臂被換成另一段動畫」）
  - 已經做完的：
    - 第一個實驗：DLC 動畫組裡的同名動畫蓋過原版（`man_geralt_gabriel_aim_idle_rp` 換成 NPC 的雙手瞄準 `man_npc_bow_idle_aiming_01`）→ 可行；檔案 `gfg_ak47_geralt.w2anims`、`test.reddlc` 的第 3 個掛載器（都已 commit）
    - 擺法 A（只把 AK 放到兩手之間）進遊戲錯誤；偵測紀錄量出：AK 的 `handle` 骨頭在遊戲裡繞槍管轉了 180°、原版的瞄準疊加層上下瞄幾乎只動左手、站著時右手比動畫低 14 公分
    - 改動畫的流程打通：REDkit 匯出 `.re` → `tools\re_blender.py`（Blender 外掛匯入、改、匯出、`re_fix` 修補）→ REDkit 匯入（動畫組那一行右鍵 **Import simple/plain animations** → 問 override 按 **Overide** → Save all）；頭轉 30° 的測試成功
    - 4 段 `aimpose_*` 的時間和角度：第 60 格 = 不偏；左右 ±180° ↔ ±1 秒；上下約 ±90° ↔ ±1 秒
  - **2026-10-16（/clear 之後）**：使用者選「先做第 1 步」→ 動手前查到：**站著、沒拿劍時，原版把右手臂換成 `man_ger_sword_axii_arm_override`**（`pc_overlay.w2beh` #18505，總權重 0.75；`docs\m3.md`「右手臂被換成另一段動畫」）→ 第 1 步把右手放上握把也會被拉走
    - 使用者選「**改原版動畫圖的曲線**」（Claude 建議）→ `tools\overlay_patch.py`（使用者同意寫）已執行：
      - 讀原檔（唯讀）→ 曲線 #18561 的 4 個值全部改 0 → 重算三層校驗碼（CRC32；算法用原檔驗證過）→ 寫到 `workspace\gameplay\behaviors\pc\behaviorgraph\pc_overlay.w2beh`（= check out 再修改）
      - 讀回來檢查過：和原檔只差 16 bytes；`.gitignore` 排除這個檔（用腳本可以重做）
    - **等使用者進遊戲測**（步驟在下面）
    - 這次查到、還沒用到的：Geralt 原版動畫的 `IK_r_hand` 等骨頭 = 對應骨頭的模型座標；NPC 那段對不上；`pc_overlay.w2beh` 沒用它們做 IK（`pc_gameplay.w2beh` 有 16 處，沒查）→ 第 1 步改右手時，`IK_r_hand` 先照原檔（`re_fix` 會把所有骨頭的位置改回原檔）
  - 測完之後（使用者選的順序：先做 1、看預覽圖和 REDkit 預覽確認，再做 2）：
    1. **第 1 步：底層姿勢**——NPC 雙手瞄準的右手用 Blender 內建的 IK 移到 AK 握把（左手不動、AK 的護木放在左掌）→ 烘焙 → `export_re`；同時算 AK 相對 `l_weapon` 的擺法（`m3_build_ak.py --place`，照「`handle` 繞槍管轉 180°」修正）和 `bolt` slot；Blender 渲染預覽圖給使用者看
       - 骨架：`r_shoulder` → `r_bicep` → `r_forearm` → `r_hand`（扭轉骨頭 `r_bicep2`、`r_elbowRoll`、`r_forearmRoll1`→`r_forearmRoll2`→`r_handRoll` 掛在上臂、前臂底下）
    2. **第 2 步：瞄準差值**——4 段 aimpose 換成「只轉上半身（`torso`～`torso3`），手臂和槍跟著胸口一起轉」的版本，照上面的時間對應做，放進我們的動畫組（同名蓋過原版）
    3. 使用者：匯入動畫、重匯 AK 模型（Import > Mesh，`importAsSkinnedMesh` true）、改 slot → 重開 REDkit → 進遊戲（偵測紀錄 `GfgLogHoldPose` 還在 `gfg_ak47.ws` 裡，可以量）
    - 還沒處理的右手覆蓋：拔槍 `WeaponDraw`（#22145，只有 `r_hand`，也用 `man_ger_sword_axii_arm_override`）；拿劍時 `WeaponAim` #21346、`WeaponShoot` #17768
  - 暫存資料夾（session 結束就沒了）：`pose_2206.log`（2026-10-15 22:06 的 396 行偵測紀錄，從 `editor.log` 複製；數字摘要在 `docs\m3.md`「遊戲裡實測」）；查動畫圖用的 `graph_walk_lib.py` 等（做法寫在 `docs\m3.md`）

### 測試：改過的動畫圖（2026-10-16 給使用者）

1. 關掉 REDkit、重新開（讓它讀 workspace 的動畫圖；`editor.log` 會被重寫，上次的偵測紀錄已經複製出來）
2. File → Open World → `engine\reference_level\world\reference_level.w2w` → 鏡頭放到地面附近 → **play game on the current layer only. Fast.**
3. 主控台：`additem('gfg_ak47', 1, true)` → 左鍵拿出 AK
4. **不要拔劍**；站著不動、瞄水平，等 3 秒（偵測紀錄每 0.5 秒寫一次）
5. F1 自由鏡頭，從右側截一張（看右手）
6. 結束遊戲，跟 Claude 說；**不要重開 REDkit**（Claude 要讀 `editor.log`）

- 預期：右手比之前高、比之前前面——回到動畫的位置附近
  - 動畫（Calc bone MS）：`r_hand` (0.245, 0.078, 1.470)；之前遊戲裡量到 (0.26, 0.01, 1.33)（玩家座標：X 右、Y 前、Z 上，公尺）
- 不用管：AK 的位置（REDkit 裡還是擺法 A 的錯誤模型）、頭往左轉 30°（動畫組還是頭轉 30° 的測試版）
- 沒有變化 → Claude 讀 `editor.log`，查遊戲有沒有讀到 workspace 的動畫圖

### 偵測紀錄的讀法、用遊戲數據算擺法

- `[Script_GFG] pose <名稱> pos x y z w x … y … z …`（世界座標的位置和三個軸）；點換到某個骨頭座標 = 先減掉骨頭位置，再和那個骨頭的三個軸分別做內積
- 右手掌心 = `r_hand` 位置 + 0.061·x 軸 + 0.032·y 軸 − 0.002·z 軸
- 用遊戲裡的數據算擺法時：直接在 `handle` 座標算（偵測紀錄的矩陣），再用 `.w2mesh` 的綁定矩陣反算成 `--place`（工具會再乘回綁定矩陣，所以 `handle` 座標會對）
- 現在的狀態：REDkit 裡的 `gfg_ak47.w2mesh` 是擺法 A；`gfg_ak47.w2ent` 的 slot 是擺法 A 的值（**沒 commit**；要回到單手版：`git checkout` 這個檔＋用 `--pitch -20.5` 重做模型、重匯）

### Calc bone 的步驟（2026-10-15 實測可用：輸入框兩格；開動畫組時按 No 也能算）

- 雙擊 `dlc\gunforgeralt\data\animations\gfg_ak47_geralt.w2anims` → 問預覽角色按 **No** → **All animations** → 動畫右鍵 → **Calc bone MS** → 骨頭名稱、時間 → 結果框按 OK
- 結果同時寫進 `editor.log`（`Bone MS - '骨頭' - time - '時間'`、`   >Position:`、`   >Rotation:`）；角度是 (Pitch, Yaw, Roll)、矩陣 = Rz(Yaw)·Rx(Pitch)·Ry(Roll)（`CLAUDE.md` §6.15）
- 做完**先不要重開 REDkit** → 跟 Claude 說，Claude 讀紀錄

### 跟使用者溝通（2026-10-15 學到的）

- 使用者有軟體工程背景，但不熟 REDkit、3D 模型、Blender，**想學**：解釋時用白話，可以用軟體工程的比喻（例：蒙皮連結像用骨頭名稱做 join、實體模板像 prefab）
- 使用者不想在 Blender 裡找視角、按快捷鍵：需要目視時，Claude 用 Blender 背景模式渲染成圖片（雙擊就能開）
- REDkit 的操作請使用者做，步驟要寫到「點哪裡、按哪個按鈕」；沒實測過的介面要說明，請使用者截圖
- 使用者會主動截很多圖回報；Claude 用 Read 看圖時要對照描述，不要只看一張就下結論
  - 會用自由鏡頭從不同角度截（畫面角落有 `camera at position`），不同張可能是不同時間點（例：開槍中、換彈中混在一起）→ 判斷姿勢前先確認是哪個時間點
- 規則（`CLAUDE.md` §11）：自己寫任何新東西前先問；有現成的就直接用。範圍（`CLAUDE.md` §7）：只做 AK 本身

## AK 現在怎麼做出來的（重做時照這個順序）

| # | 做什麼 | 誰 | 產物 |
|---|---|---|---|
| 1 | `tools\m3_build_ak.py`（指令在 `docs\m3.md`「第 3 步」，**最後加擺法 A 的 `--place …`**（`docs\m3.md`「使用者選 A」的表）；單手版是 `--pitch -20.5`） | Claude | `assets\ak47\gfg_ak47.fbx`（只有一個叫 `handle` 的模型，頂點在 `handle` 骨頭座標系）、`gfg_ak47_m3.blend`（目視用） |
| 2 | `tools\m3_textures.py`（指令在 `docs\m3.md`「第 4 步：準備好的檔案」） | Claude | `assets\ak47\gfg_ak47_d01.png`、`gfg_ak47_n01.png`（2048，法線圖的 alpha 是粗糙度） |
| 3 | REDkit 匯入貼圖：資料夾 `dlc\gunforgeralt\data\items\weapons\gfg_ak47\` 右鍵 → Import → 2D Texture；群組 `WorldDiffuse`、`NormalmapGloss` | 使用者 | `gfg_ak47_d01.xbm`、`gfg_ak47_n01.xbm` |
| 4 | REDkit 匯入模型：右鍵 → **Import → Mesh**（換模型時也用這個，蓋掉舊檔）；`importAsSkinnedMesh` = **true**、`xmlMetadataLocation` = `assets\ak47\gfg_ak47.xml`；接著的「Import mesh」選材質對話框按 **Cancel**；確認 `editor.log` 有 `HasSkinning: true (NODE 'handle')` | 使用者 | `gfg_ak47.w2mesh` |
| 4' | 匯入之後：**重開 REDkit** 再進遊戲（或 Mesh editor → Materials → 重新指定 `Diffuse`、`Normal`）；不然遊戲裡沒有顏色 | 使用者 | |
| 5 | 實體模板 `gfg_ak47.w2ent`：十字弩模板的複本，模型元件 `witcher_crossbow_lvl1` 的 `mesh` 指到 AK；slot `bolt`：骨頭 `handle`；擺法 A 是位置 (0.054, 0.037, -0.029)、Pitch 45.5／Yaw -124.6／Roll -76.2（**等使用者改**；已 commit 的是單手版 (0.435, 0, -0.031)、Roll 0／Pitch -20.4／Yaw -90） | 使用者 | |
| 6 | `test.reddlc` 的實體模板掛載、物品 XML 的 `equip_template = "gfg_ak47"`（已 commit） | — | |

- 不要用 Reimport → Mesh only：它沿用 REDkit 記憶體裡的匯入設定，REDkit 重開後 `importAsSkinnedMesh` 是 false → 模型沒綁骨頭、遊戲裡看不到槍
- 改了 XML、`.reddlc`、模型、模板後，都要從 REDkit 重開遊戲
- Mesh editor 換材質貼圖：**Materials** 分頁 → 選 `weapon_rif_ak47` → Asset Browser 點選 `.xbm` → 欄位的綠色箭頭 → 存檔
- 模型換了形狀，slot 的位置要重算：`m3_build_ak.py` 會印出 `handle` 骨頭座標的槍口與槍管方向；算法在 `docs\m3.md`「槍管往下轉 20.5°」、「使用者選 A」

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

- `workspace\scripts\local\gfg_ak47.ws`：兩件事混在一起
  - 拿掉舊的 `GFG` 偵測紀錄（編譯通過；清單沒測完）
  - 加了**暫時的** `GfgLogHoldPose`（雙手持槍量位置用；`GfgCameraTick` 裡呼叫）→ 決定方向後拿掉
- `workspace\dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47.w2ent`：`bolt` slot 改成擺法 A 的值（實驗失敗；退回單手版時用 `git checkout` 還原）
- REDkit 裡的 `gfg_ak47.w2mesh`（不在 git）：擺法 A 的模型
- `workspace\dlc\gunforgeralt\data\animations\gfg_ak47_geralt.w2anims`：頭轉 30° 的測試版 → **不 commit**；第 1 步做好的版本蓋掉，或用同樣方法匯入 `assets\anims\gfg_aim_idle_rp.re` 還原
- `gunforgeralt.w3edit`：只有 REDkit 自己改的 `dirtyTileCellIndices`（開過測試關卡）→ 不 commit
- `.claude\hooks\`（`context-check.sh`、`statusline.sh`）：使用者自己的設定，2026-10-15 18:35 出現，Claude 沒動過 → 不 commit
- `.gitignore` 排除、不 commit 的：
  - `assets\ak47\` 的 `.blend`、`.fbx`、`.png`：腳本的輸出（材質 XML `gfg_ak47.xml` 有 commit）
  - `workspace\dlc\gunforgeralt\data\items\weapons\gfg_ak47\` 的 `.w2mesh`、`.xbm`：REDkit 匯入的產物（照上表的步驟可以重做）
  - `assets\anims\` 的 `.re`：使用者從 REDkit 匯出的 6 個原檔、`gfg\` 底下 Claude 做的（要匯入我們動畫組的）
  - `workspace\gameplay\behaviors\pc\behaviorgraph\pc_overlay.w2beh`：改過的原版動畫圖（`python -X utf8 tools/overlay_patch.py` 從原檔重做）
  - `thumbnails\`：REDkit 的縮圖

## 下一步

1. **雙手持槍**：等使用者測「改過的動畫圖」→ 第 1 步（底層姿勢）→ 第 2 步（瞄準差值）（見「現在在做」）；之後再換開槍、換彈、走路的動畫
2. 箭第一次出現在槍口前 1～2 公尺：箭速 60 公尺／秒 × 每格約 30 毫秒（`docs\m3.md`「箭離槍口一段距離才出現的原因」）
   - Claude 建議留到 M5 用槍口火光、曳光處理；另一個選項是降低箭速；使用者還沒決定
3. 拿掉紀錄的測試（下面「測試方式補充」）；通過就 commit `gfg_ak47.ws`
4. 輪盤的待驗證項目（`findings.md` §24.9）：使用者下次騎馬時順便目測
5. 之後再做（使用者決定時機）：傷害平衡（CS2 36、爆頭 ×4）、M4 聲音（要先確認 Wwise 版本：`CLAUDE.md` §3）
6. M5 候選：槍口火光、曳光；持槍衝刺／跳躍的動畫（`findings.md` §17.10）；跳躍散布（§16.2）
7. 暫時方案（使用者沒選，雙手做不成時再考慮）：拿著 AK 時鏡頭移到 Geralt 左後方，讓左手的槍看得到

- **REDkit 重開時 `editor.log` 會被整個重寫**：遊戲測完、重開 REDkit 之前，先讓 Claude 讀紀錄（或先複製到暫存資料夾）

### 測試方式補充

- **拿掉紀錄之後的測試**（`findings.md` §25）：在地面按 Reload scripts，照常玩一輪
  - 地面：左鍵連射到換彈、接著射；Z 鎖定時準心在目標身上；背對怪物跑邊射；C 收槍；衝刺、跳躍時不開火，落地還按著就接著射
  - 騎馬：叫馬、上馬 → 左鍵拿出、連射、換彈後接著射；中鍵射一發後馬要能照常操作；C 收槍後能下馬
  - 預期：和拿掉之前一樣；`editor.log` 裡不再有 `GFG` 的紀錄
- **輪盤的目測**（§24.9）：用 E 下馬 → 再上馬 → 直接在馬上按 Tab：輪盤照原版規則（點一下開著），不會一開就關
- 騎馬時重載腳本可能卡住下馬鎖（§22.4）→ 一律在地面重載
- 遊戲開著時改腳本：REDkit 的 **Tools → Debuggers → Reload scripts**；**使用者沒按就不會套用**
- 遠處的怪物：`spawn('wolf', 1, 60, true)`；十字弩兵：`spawn('xbow', 1, 15, true)`；無敵：`god()`（`CLAUDE.md` §12；這兩個 2026-10-15 用過）
- REDkit 的 Mesh editor 預覽：底下的環境選單預設 `ENV - OFF` 會全黑，換成任何環境（例：`usm\battle_02_noblue_lights.env`）才看得到貼圖；Entity Editor：在 Asset Browser 雙擊 `.w2ent` 開
- 暫存資料夾的東西**新 session 不會有**（要再用得先問使用者）：
  - Blender Workbench 正交渲染（AK、十字弩各角度的預覽圖）
  - 用 Blender 內建的 `io_scene_fbx.parse_fbx` 解析 FBX
  - 用 Blender＋numpy 算 PNG 各通道的統計
  - 槍管斷面：Blender 讀 `gfg_ak47_m3.blend` 的頂點、乘 `handle` 綁定矩陣，沿槍管每 1 公分一段列出範圍
  - 讀材質參數、比對兩個 `.w2mesh`：用 `tools\cr2w_dump.py` 的 `Cr2wFile` 解自訂資料（格式：數量 u32，每筆「大小 u32（含自己）、名稱 u16、型別 u16、值」）
  - 2026-10-15 的模型備份（`mesh_snapshots\`）、`editor.log` 副本：只為那次比對，不用保留
  - `editor.exe` 的字串表：Python 用正規表示式抽 ASCII（5 字以上）和 UTF-16LE 字串，每行「位移、字串」；REDkit 介面的選單、對話框文字都查得到
  - 動畫組的動畫清單、長度：用 `tools\cr2w_dump.py` 的 `Cr2wFile` 讀每個 `CSkeletalAnimation` 的 `name`、`duration`
  - 比對兩段動畫的資料：兩邊都用 `cr2w_dump.py` 輸出，把 `array:數字,0,` 換成固定字（名稱表的編號不同）再 diff
  - 雙手持槍的計算（2026-10-15 /clear 之後）：骨架參考姿勢 FK、Calc bone 角度的解讀、指節位置、三種擺法、Blender 渲染預覽圖；算法和數字都在 `docs\m3.md`「Calc bone 的結果」
  - 原版 `.reddlc` 的 `entityTemplatePaths`（字串陣列）解碼：數量 u32，每個字串前一個長度位元組（0x80 = 單位元組字元、0x40 = 長度還有下一個位元組、低 6 位是長度）
- `.w2mesh` 骨頭名稱和綁定矩陣：`tools\m3_build_ak.py` 的 `read_rig_matrices()`；在 Blender 背景模式用 `--python-expr` 匯入 `m3_build_ak` 呼叫

## 已知限制（還沒處理）

- M3：十字弩的單手姿勢（左手伸直）：往右看、跑步時槍被身體擋住（槍在左手、鏡頭在右後方）→ 雙手持槍要解決
- 雙手持槍（實驗中）：只有站著瞄準換成 NPC 的雙手姿勢；原版十字弩也變成這個姿勢
  - NPC 姿勢的兩手一樣高，AK 的握把比護木低 7.6 公分 → 兩手都握到（擺法 A）槍口就朝下 9.6°；要完全貼合得改動畫（右手往下約 8 公分）
  - 擺法 A 的模型做好、還沒進遊戲（遊戲裡還沒換掉，現在是單手版的模型）
- M3：箭第一次出現在槍口前 1～2 公尺（見「下一步」2）
- M3：槍托後端和手套袖口有一點重疊（改雙手時會重調）
- M3：AK 被光直射時整把亮白（`docs\m3.md`「換回 AK 的貼圖再測」）：沒查，先不管
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
- **M3：帶骨架的蒙皮 FBX**（`docs\m3.md`「第一次匯入的模型沒用到骨頭群組」）：REDkit 一律用 NODE 模式 → 改用「不帶骨架、模型叫 `handle`、頂點先換到骨頭座標」的做法
- M3：`wcc_lite import` 測試 FBX 匯入：300 秒沒有輸出就中止；而且沒有蒙皮匯入的選項
- M3：第一版 AK 上下顛倒（猜十字弩的上方是 +X）→ 照使用者的遊戲截圖改成 -X
- M3：AK 對齊十字弩 `handle` 骨頭的方向 → 槍管比原版的箭高 20.4°，往上翹 → 改成 `--pitch -20.5`（槍管和 `chord` 骨頭的 x 軸平行）
- M3：REDkit 重開後用 Reimport → Mesh only 換模型 → 模型沒綁骨頭、槍不見（試了 3 次）→ 改用 Import > Mesh
- M3：顏色問題曾以為是 `.xbm` 或光照造成 → 都不是；是剛匯入模型的那次 REDkit 的狀態問題
- **在 Bash 的 heredoc 裡寫含反斜線的 Python**：`\\` 會變成 `\`，`\a` 會變成控制字元（2026-10-15 弄壞過交接檔一次）→ 含路徑的字串用 Write／Edit 工具，或在 Python 裡用 `chr(92)`
- **Bash 的 `cd` 會改掉 session 的工作目錄**（2026-10-15 `cd` 到唯讀資料夾三次）→ 用絕對路徑，不要 `cd` 到專案外
