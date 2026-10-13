# Witcher 3 × CS2 AK-47 Mod — 專案說明

> 這份檔案記錄了開發前的所有討論與決策。每次開始工作前先讀完。
> 接著讀 `docs\handoff.md`（進行中的狀態），從那裡接著做；使用者不用另外交代。
> 回覆請一律使用**繁體中文**，排版用短句、一行一個重點、段落分明。

---

## 1. 專案目標

- 在《巫師3》**Remastered（5.x，Steam 版）**加入 **CS2 的 AK-47**，讓 Geralt 能開槍射擊
- **維持第三人稱**，不做第一人稱
- 射擊手感盡量接近 CS2：後座力彈道、散布、射速、停火回復、全自動連射
- 第一階段**只做一把：AK-47**
- **個人使用，不公開散布**（CS2 素材版權屬 Valve，不上傳 Nexus 或任何平台）

---

## 2. 路徑（2026-10-12 確認）

| 代號 | 路徑 | 備註 |
|---|---|---|
| `<REDKIT_PROJECT>` | `D:\OneDrive\Desktop\gunforgeralt` | REDkit 建立的專案資料夾，**Claude 在這裡啟動**；專案檔 `gunforgeralt.w3edit` |
| `<W3_GAME_DIR>` | `D:\Program Files (x86)\Steam\steamapps\common\The Witcher 3` | 巫師3 安裝資料夾（唯讀）；`bin\x64_dx12\witcher3.exe` 版本 **5.0.0.1048522** |
| `<W3_VANILLA_SCRIPTS>` | `<W3_GAME_DIR>\content\content0\scripts` | 原版 WitcherScript 原始碼（唯讀）；UTF-8，1525 個 `.ws` |
| `<REDKIT_DIR>` | `D:\Program Files (x86)\Steam\steamapps\common\The Witcher 3 REDkit` | REDkit 安裝資料夾（唯讀） |
| `<REDKIT_DEPOT>` | `<REDKIT_DIR>\r4data` | REDkit 的 uncook depot（唯讀）；**原版物品 XML 散檔在 `gameplay\items\`** |
| `<W3MODS_DIR>` | `D:\OneDrive\Desktop\W3Mods` | 放參考 mod 與 CS2 匯出素材 |
| `<CS2_VPK>` | `D:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\pak01_dir.vpk` | CS2 素材封存檔的**索引檔**（唯讀）；資料在同資料夾的 `pak01_000`～`pak01_505.vpk` |

**路徑相關的已查證事實**

- `<REDKIT_DEPOT>\scripts` 與 `<W3_VANILLA_SCRIPTS>` 內容完全相同（2026-10-12 用 `diff -rq` 比對）
- **Python 3.14.7**（2026-10-12 用 winget 安裝，使用者範圍）：`C:\Users\beyon\AppData\Local\Programs\Python\Python314\python.exe`
  - 已加入使用者 PATH，排在 Microsoft Store 空殼之前；**重開終端機後** `python`、`py` 才會生效
  - 系統語系是 **cp950**，Python 要加 `-X utf8`（或設 `PYTHONUTF8=1`），否則輸出特殊字元會出錯
  - `tools\` 的工具腳本用 Python 寫；小型串接用 PowerShell 7

---

## 3. 開發環境

| 工具 | 版本 / 狀態 | 用途 |
|---|---|---|
| Windows + PowerShell 7 + Windows Terminal | 已裝 | 開發環境 |
| Claude Code CLI | 已裝 | 文字檔開發 |
| 巫師3 Remastered | 5.x（Steam） | 目標遊戲 |
| REDkit | **5.0.0.1048625** | 官方 mod 工具；內含 Script Studio、`wcc_lite`（可命令列編譯腳本，見 `docs\findings.md` §12.5） |
| Python | **3.14.7** | 工具腳本（後座力模擬、資料解析、繪圖） |
| Blender | **5.2** | 模型處理（內建 glTF 匯入、FBX 匯出） |
| REDkit Blender 外掛 | `<REDKIT_DIR>\bin\tools\BlenderPlugin\blender_re_animations_plugin.zip` | **動畫階段才裝**；Blender 5.x 移除了部分舊 API，不相容時另裝 Blender 3.6 專做動畫 |
| Wwise | ⚠️ **待重新確認**：原本寫 2021.1.7.7796，但 REDkit 5.0 Changelog 寫「requires Wwise 2023 with the Mastering Suite and Motion plugins」 | 聲音階段；授權每 3 個月重新申請；M4 前查清確切版號 |
| ffmpeg | 聲音階段 | 把 REDkit 原版音效 `.opus` 轉 `.wav` |
| Source 2 Viewer | GUI + CLI | 從 CS2 的 VPK 匯出模型、貼圖、聲音 |
| Git | 已裝 | 版本控制 |
| VS Code + WitcherScript（作者 webspam） | 選用 | 使用者自己讀程式碼用 |

**兩個 Blender 版本並用時**：用 FBX / glTF 交換檔案，不要直接互開 `.blend`。

---

## 4. 資料夾配置

```
<REDKIT_PROJECT>\                 ← Claude 的工作目錄（可修改）
  CLAUDE.md
  .claude\settings.local.json
  docs\                           ← 調查筆記、決策紀錄
  data\cs2\weapons.vdata          ← CS2 武器數值（文字檔，納入 git）
  tools\                          ← 遊戲外驗證用腳本（後座力模擬、Blender 腳本）
  gunforgeralt.w3edit             ← REDkit 專案檔
  LocalEditorStringDataBaseW3_UTF8_mod.db   ← 專案字串資料庫（物品名稱等；ID 從 10000000 起；SQLite）
  LocalEditorStringDataBaseW3_UTF8_mod_export.csv   ← 字串資料庫的文字版（REDkit 存字串時自動寫出，檔名寫死在 editor.exe）；納入 git 以便看出字串的變更
  workspace\                      ← REDkit 虛擬 depot 的專案層（第一次新增檔案時建立）；路徑和 depot 一一對應
    dlc\<dlc名稱>\                ← 自訂 DLC：物品 XML、實體模板、.reddlc（.reddlc 要在 REDkit 建立）
    scripts\local\                ← mod 腳本（annotation）；2026-10-12 確認會被遊戲載入
  packed\、publish\               ← REDkit 打包輸出（不納入 git）

<W3MODS_DIR>\reference\                          ← 參考 mod（唯讀；這裡的副本沒有裝進遊戲，但遊戲另外裝了 MCME，見 §12）
  Firearms\                                      ← Roenaxx：燧發槍作為十字弩替代武器（舊版遊戲）
  FirearmsNextGen\                               ← RickThedope：次世代版（4.x）
  CompleteCrossbowOverhaul\                      ← 2017 年 v1.0：半自動／全自動／狙擊／霰彈弩，含射速、彈匣、散布
  CompleteCrossbowOverhaul_base_game_steering\   ← 同 mod 的選用檔：只把 defaultSteering 設為 true，恢復原版操作（放開「使用物品」鍵時發射）
  MCME_Remastered\                               ← Multi Companion Mod Remastered：已確認能在 5.x 運作的「腳本」mod（annotation 寫法範本）
  Required_for_MCME_Remastered\                  ← Relapse's Mod Manager Redux 2.4：5.x 用的 mod 管理器（工具程式，不是遊戲 mod）
                                               

<W3MODS_DIR>\cs2_export\ak47\     ← 從 CS2 匯出的素材
  model\                          ← glTF + 貼圖（worldmodel）
  sounds\                         ← WAV
```

---

## 5. 分工

**Claude 負責（文字檔與命令列）：**

- WitcherScript（`.ws`）、物品定義 XML
- 解析 `weapons.vdata`，轉成巫師3 用的數值
- 後座力產生演算法與遊戲外驗證
- Blender Python 腳本（`blender --background --python`）
- Source 2 Viewer CLI 批次匯出
- git、除錯、文件

**使用者負責（圖形介面與測試）：**

- REDkit 編輯器：check out 檔案、匯入模型與貼圖、設定實體、處理動畫
- Wwise：建立聲音
- Blender 需要目視調整的部分（大小、方向、握把對齊）
- 從 REDkit 啟動遊戲測試，回報結果給 Claude

---

## 6. 已查證的重要限制

1. **Remastered 5.x**（2026-09-29 上線）讓含腳本、XML、w3strings 的舊 mod 失效，需用 REDkit 更新
   → 參考 mod 大多不能直接用，**只參考作法**
2. REDkit 專案中，要修改的原版檔案需先在 REDkit **check out**，REDkit 才會打包
3. 從 **REDkit 編輯器啟動遊戲**時，可在遊戲中**熱重載腳本**（Tools → Debuggers → Reload scripts，2026-10-13 實測）；XML 要重新啟動遊戲，模型等資源未確認
   - 這時遊戲跑在 `editor.exe` 裡，直接讀 `workspace` 的原始檔（`docs\findings.md` §13.16）
   - 已安裝的 mod 都在 `<W3_GAME_DIR>\mods\`；我們的 mod 還沒打包、沒安裝，打包後的檔案與安裝位置未驗證
4. REDkit 匯入動畫時，**骨骼名稱與階層必須完全一致**
   → CS2 的動畫不能套到 Geralt，持槍／開槍／換彈動作要用 Geralt 骨架重做
5. 模型流程：Source 2 Viewer 匯出 glTF → Blender 內建 glTF 匯入 → 調整 → 匯出 FBX → REDkit Asset Browser「Import > Mesh」
   REDkit 與 Blender 有**座標系差異**，匯入時注意骨骼軸向
6. Windows 上 Claude Code 權限規則的絕對路徑寫法：`D:\W3Mods` → `//d/W3Mods`
7. **5.x 的腳本 mod 用 annotation**（`@wrapMethod` / `@addMethod` / `@addField`），檔案放 `content\scripts\local\`
   → 本專案**不整檔覆寫原版腳本**（MCME 與已安裝的 5.x mod 都這樣做）
8. **AK 的實體類別必須繼承 `Crossbow`**
   → `thePlayer.rangedWeapon` 的型別是 `Crossbow`（`r4Player.ws:17`），射擊流程也會強制轉型（`r4Player.ws:10712`）
9. 原版十字弩的**發射時機由動畫事件 `'ProjectileThrow'` 決定**，每發都要換彈
   → 全自動要從腳本直接觸發（CCO 的作法）
10. 舊版參考 mod 的 `.ws` 是 **UTF-16 LE**；5.x 原版與 5.x mod 是 UTF-8
11. **新物品 XML 要放在自訂 DLC 資料夾，並由 `.reddlc` 掛載**（`CR4DefinitionsDLCMounter`）
    → `.reddlc` 是二進位檔，**只能在 REDkit 建立**（使用者操作）；原版範例 `<REDKIT_DEPOT>\dlc\dlc5\`
    - **`.reddlc` 一定要填 `id`**（本專案 `gunforgeralt`），否則整個 DLC 被拒絕（`has empty DLC ID`）
    - 新 DLC 第一次被掃描時只登記，**之後再啟動遊戲才會掛載**；改了 XML 也要重新啟動遊戲
    - 本專案：`workspace\dlc\gunforgeralt\test.reddlc` 掛載 `dlc\gunforgeralt\data\gameplay\items\gunforgeralt_items.xml`
    - **腳本放 `workspace\scripts\local\`**，會被從 REDkit 啟動的遊戲載入（2026-10-12 確認）
12. **annotation 寫法規則**（2026-10-12 用 wcc_lite 編譯驗證，見 `docs\findings.md` §12.5）
    - annotation 後面**一律接 `function`**：包 `event` 也一樣，寫 `event` 會語法錯誤
    - 包 `event` 時**不能寫回傳型別**（固定是 bool），但可以 `return wrappedMethod(...)`
    - `@replaceMethod` 後面**不能加** `protected` 等修飾詞；`@addMethod` 可以加 `public`
    - **state 的方法可以包**：類別名稱 = 父類別 + `State` + 狀態名，例如 `CR4PlayerStateAimThrow`
      → 後座力可以包 `CR4PlayerStateAimThrow.OnGameCameraTick`（已編譯通過）
    - **`wrappedMethod` 在同一個函式裡只能寫一次**：第二次出現會報 `Could not find function 'wrappedMethod'`（2026-10-13，`docs\findings.md` §17.6）
    - **不能直接寫入其他物件的欄位**（`thePlayer.欄位 = 值` 報 `Left hand side is const`）→ 在那個類別 `@addMethod` 一個設定函式
    - annotation 裡能不能用 `super.`：官方 Wiki（頁面 36241598）沒寫；編譯會過，但行為沒驗證過，目前不用
    - **`.ws` 和 `.xml` 一律存成 UTF-8 加 BOM**：REDkit 開專案時會檢查，缺 BOM 會跳出 invalid encoding（`docs\findings.md` §12.7）
      - 可以寫繁體中文註解；換行 LF 或 CRLF 都可以
13. 詳細出處（檔案路徑、行號、Wiki 頁面 ID）見 `docs\findings.md`

---

## 7. 設計決策（已定案）

**系統基礎**

- **借用十字弩系統**（遠程武器、投射物、瞄準模式），不從零寫武器系統
- **範圍只做 AK 本身**：AK 以外的物理效果照遊戲原本的行為（例：箭打在牆上沒有痕跡就算了），不另外處理（使用者 2026-10-13）

**第三人稱射擊**

- **後座力：鏡頭照彈道轉動（像 GTA5），準心固定在畫面中央，子彈飛向準心**（2026-10-13 使用者第二次改定）
  - 要求：鏡頭移動不能一頓一頓的；拿著 AK 時準心一直顯示，不能因為射擊而消失
  - 經過：最早定案是鏡頭版 → 實測一頓一頓的，改成「鏡頭不動、準心照彈道移動」→ 使用者決定回到鏡頭版（`docs\findings.md` §14.4～§14.6）
  - 一頓一頓的原因：每發的後座力在開火那一格一次轉完，兩發之間鏡頭完全不動 → 改成每發在 0.1 秒內等速轉完
  - 壓槍：往下拉滑鼠，抵銷鏡頭往上的轉動
- **射擊方向**：從鏡頭沿著鏡頭正前方（＝畫面中央的準心）打射線找出目標點，子彈從槍口飛向該點
  → 避免「準心對著敵人，子彈卻打到旁邊牆壁」的視差問題
- **腰射與瞄準分開**：瞄準沿用十字弩的瞄準模式（散布小、移動慢）
- **命中方式**：模擬即時命中（射線檢測或極高速投射物）
  → 先查原版腳本有哪些可用 API，**不可臆測函式名稱**

**素材**

- 只用 CS2 的 **worldmodel**（第三人稱），不用 viewmodel
- CS2 的粒子特效無法移植，槍口火光、曳光用巫師3 原有特效

**手感參考**（只看影片，不需要檔案）

- Remnant 2：第三人稱 + 近戰 + 翻滾閃避，類型最接近巫師3
- PUBG 第三人稱模式：第三人稱下的 CS 式壓槍

---

## 8. CS2 AK-47 資料

**來源**：SteamTracking/GameTracking-CS2 的 `game/csgo/pak01_dir/scripts/weapons.vdata`

```
https://raw.githubusercontent.com/SteamTracking/GameTracking-CS2/master/game/csgo/pak01_dir/scripts/weapons.vdata
```

下載到 `data\cs2\weapons.vdata`。以下為 2026-10-12 讀取的 `weapon_ak47_prefab` 數值，**開工時重新下載，以檔案為準**：

| 欄位 | 值 | 說明 |
|---|---|---|
| `m_nDamage` | 36 | 傷害 |
| `m_iMaxClip1` | 30 | 彈匣容量 |
| `m_bIsFullAuto` | true | 全自動 |
| `m_flCycleTime` | 0.1 | 射擊間隔（秒），即 600 RPM |
| `m_flDeployDuration` | 1.0 | 拔槍時間 |
| `m_flDisallowAttackAfterReloadStartDuration` | 2.466667 | 換彈開始後禁止射擊的時間（換彈時長參考） |
| `m_flSpread` | [0.0006, 0.0006] | 基礎散布 |
| `m_flInaccuracyStand` | [0.00641, 0.00641] | 站立 |
| `m_flInaccuracyCrouch` | [0.00481, 0.00481] | 蹲下 |
| `m_flInaccuracyMove` | [0.17506, 0.17506] | 移動 |
| `m_flInaccuracyJump` | [0.14076, 0.14076] | 跳躍（`JumpInitial` 0.10094） |
| `m_flInaccuracyLand` | [0.000242, 0.000242] | 落地 |
| `m_flInaccuracyFire` | [0.0078, 0.0078] | 每發增加 |
| `m_flRecoveryTimeStand` | 0.368（Final 0.506） | 站立回復時間 |
| `m_flRecoveryTimeCrouch` | 0.305257（Final 0.419728） | 蹲下回復時間 |
| `m_nRecoveryTransitionStartBullet` / `EndBullet` | 2 / 5 | 回復時間過渡區間 |
| `m_flRecoilAngle` | [0.0, 0.0] | 後座力角度 |
| `m_flRecoilAngleVariance` | [70.0, 70.0] | 角度變化量 |
| `m_flRecoilMagnitude` | [30.0, 30.0] | 後座力大小 |
| `m_flRecoilMagnitudeVariance` | [0.0, 0.0] | 大小變化量 |
| `m_nRecoilSeed` | 223 | 後座力種子 |
| `m_flHeadshotMultiplier` | 4.0 | 爆頭倍率 |
| `m_flRange` / `m_flRangeModifier` | 8192 / 0.98 | 射程與距離衰減 |
| `m_flMaxSpeed` | [215.0, 215.0] | 持槍移動速度 |
| `m_nTracerFrequency` | 3 | 曳光頻率 |
| `m_vecMuzzlePos0` | [37.422, -4.938, -3.394] | 槍口位置 |

陣列的兩個值是 **[一般, 第二模式（開鏡／連發／消音器）]**（推論，證據充分）。
AK-47 的兩個值都相同 → **一律取第一個值**。證據與完整數值見 `docs\ak47_params.md`。

**素材路徑**（在 `<CS2_VPK>` 內）：

- 模型：`weapons/models/ak47/weapon_rif_ak47.vmdl`
- 彈匣：`weapons/models/ak47/weapon_rif_ak47_mag.vmdl`
- 槍聲事件：`Weapon_AK47.Single`（實際音檔路徑需在 VPK 內查找）

---

## 9. 後座力實作注意

- CS2 的射擊是**兩套系統疊加**：
  - **後座力**：固定、可學習的彈道
  - **散布**：依站立、移動、跳躍等狀態疊加的隨機誤差
- `weapons.vdata` 只有參數（種子、角度、大小、變化量），**不是每發子彈的座標表**
  → 需要實作產生彈道的演算法（社群有逆向研究，引用時要註明來源）
- **先在遊戲外驗證**：
  1. 在 `tools\` 寫一個小腳本，輸出 AK-47 前 30 發的彈道
  2. 與 csdb.gg 的 AK-47 彈道比對
  3. 吻合後，才轉成 WitcherScript 的資料表或演算法
- **2026-10-13 的做法**（`docs\findings.md` §14）：
  - 找不到演算法的公開資料；使用者同意 AK 的數據**可以推測、任何來源都可以**
  - 數據：`data\recoil\ak47_artanis-rcs.csv`（Artanis-RCS，MIT），來源與換算見 `data\recoil\README.md`
  - 工具：`python -X utf8 tools/recoil_pattern.py [--ascii] [--svg 檔名]`，輸出每發落點（度）
  - 形狀（兩個獨立來源一致）：第 0～7 發往上爬、略偏左 → 第 7～14 發往右 → 第 14～19 發往左 → 之後往右
    - 原本這裡寫「之後先往左飄，再往右擺回」，和資料相反，已更正
  - 大小：往上最多 11.7°（工具的換算）；CSGODOT 則是**假設** 16°。真正的大小沒有實測過，所以遊戲裡要留一個可調的倍率

---

## 10. 里程碑

| 階段 | 內容 | 完成條件 |
|---|---|---|
| **M0 盤點** | 讀原版十字弩相關腳本與物品定義、參考 mod、5.x 範例 mod（MCME_Remastered）；解析 AK-47 數值。起點：Complete Crossbow Overhaul 替換的是 `rangedWeapon.ws`，先從原版的這個檔案找十字弩射擊邏輯；比對舊版 mod 與 5.x 範例 mod 的寫法差異 | `docs\findings.md`（附檔案路徑與行號）、`docs\ak47_params.md` |
| **M1 佔位 AK** | 複製十字弩的物品定義，做成新物品並改成 AK 數值，不換模型 | 主控台可取得、可裝備、可射擊，數值有變 |
| **M2 射擊機制** | 全自動 600 RPM、彈匣 30、換彈；鏡頭後座力（CS2 彈道）、散布狀態、停火回復 | 遊戲內手感接近 CS2，壓槍有效 |
| **M3 模型** | CS2 AK-47 → Blender → FBX → REDkit，掛到 Geralt 手上 | 外觀為 AK-47，握持位置正確 |
| **M4 聲音** | Wwise SoundBank 加入 AK-47 槍聲 | 射擊時播放 CS2 槍聲 |
| **M5 打磨** | 槍口火光、曳光、命中回饋、準心 | 整體手感完成 |

每個里程碑內：**小步修改 → 提供測試步驟 → 使用者回報 → git commit**

---

## 11. 工作規則

- **只修改 `<REDKIT_PROJECT>` 內的檔案**
  遊戲安裝資料夾、REDkit 安裝資料夾、`reference\` 一律唯讀
  - **例外（2026-10-12 使用者同意）**：執行 `wcc_lite` 時，工具**自動**寫入的檔案可以接受
    - `<REDKIT_DIR>\bin\wcc.log`（紀錄檔）
    - `<REDKIT_DEPOT>\x64.release.redscripts`（腳本編譯快取，每次啟動引擎都會重建）
  - Claude **不得用其他方式**寫入 REDkit 資料夾（不手動複製、不還原、不刪除），需要時先問
  - `wcc_lite` 一定要用 `<REDKIT_DIR>\bin\x64_RedKit` 當工作目錄，否則紀錄檔會寫到別處（見 `docs\findings.md` §12.5）
  - 暫存檔放 Claude 的 scratchpad，不放專案資料夾外的其他地方
- **自己寫任何新東西（程式、指令、工具）之前先問使用者**（2026-10-13）
  - 已經有現成的（遊戲內建、REDkit 功能、網路上別人做過的）就直接用，不要從頭做
- 不確定的 API、欄位、檔案格式：
  先在原版腳本或參考 mod 搜尋，**引用出處（檔案路徑與行號）**；查不到就明說，**不要臆測**
- 修改前先說明要改什麼、為什麼
- 每次修改後提供：
  - 測試步驟
  - 需要輸入的主控台指令
  - 預期結果
- **不刪除既有檔案**，除非使用者同意
- git：每個可運作的小步 commit 一次
  大型二進位（模型、貼圖、音檔、打包輸出）先用 `.gitignore` 排除，需要納入時先問
- **交接檔 `docs\handoff.md`**：記錄「進行中」的狀態，讓新 session 不用重新推敲
  - **每次 commit 時一起更新**：session 可能被用量上限突然切斷（2026-10-13 發生過），不能等結束才寫
  - 只寫還在變動的：現在做到哪、還沒寫進本檔的決定、沒 commit 的檔案與測試進度、下一步、試過放棄的做法、相關的 `docs\findings.md` 章節
  - 已定案的寫進本檔，查證過的事實寫進 `docs\findings.md`
- 確認了新的重要事實（路徑、API、格式）就更新本檔

---

## 12. 測試方式

- **開啟主控台**：`<W3_GAME_DIR>\bin\config\base\general.ini` 的 `[General]` 加 `DBGConsoleOn=true`，遊戲中按 `~`
- **取得物品**：`additem('物品名稱')`（物品名稱以實際定義為準）
- **在 REDkit 編輯器直接放物件**（Wiki「HOW-TO: Add objects into the world multiple times」，頁面 15499265；未實測）
  - 開著世界、在 Scene 面板雙擊圖層使它變粗體（啟用）→ Asset Browser（Ctrl+A）選模型或實體 → 點一下畫面 → 按 **C** 放在滑鼠位置；也可以直接拖進畫面
  - 放模型時選 Static Mesh 才有碰撞（搜尋結果引用的同一頁內容）
  - 怪物：放遭遇區域、生成點、守衛區域，用 spawn tree 生成（Wiki「HOW-TO: Create a monster encounter」，頁面 6326170）
  - ⚠️ 放進原版世界的圖層等於修改原版檔案；測完不要存檔（§13.4 的原則）
- **測試用靶子**（原版主控台指令；2026-10-13 查程式碼，**未實測**，見 `docs\findings.md` §15）
  - `spawnPath('characters\npc_entities\monsters\wolf_lvl1.w2ent', true)`：在面前生成**敵對**的狼（`temp.ws:6790-6813`）；不加 `true` 會設成友善
  - ⚠️ **友善的角色打不到**：玩家射出的投射物碰到友善角色不算命中（`throwable.ws:126-128`）
  - `spawn(名稱, 數量, 距離, 是否敵對, 等級)`（`temp.ws:6815-6942`）；「不敵對」時保留生物原本的態度，怪物照樣會攻擊
  - 人物也用 `spawnPath`，例：`characters\npc_entities\main_npc\ciri.w2ent`
  - `spawnPath` 可以生成任何實體模板（`temp.ws:6790-6813` 用 `CreateEntity`），牆也可以，例：`dlc\bob\data\environment\architecture\grey_box_blockout\brick_wall_system\entities\wall_super_wide.w2ent`（寬 8 公尺、高 4.75 公尺；箭不會插在上面：`docs\findings.md` §15.2）
  - `killall(範圍)` 清掉附近的敵人（`playerCheats.ws:9`）；`statstarget()` 印出目前目標的數值（`temp.ws:6168`）
  - 原版**沒有**調整 NPC 血量、讓怪物不攻擊的指令
  （已安裝 Multi Companion Mod Remastered，但它生成的是**友方同伴**，不適合當靶子）
- **寫完腳本先編譯檢查**（Claude 自己做，約 20 秒）：`python -X utf8 tools/wcc_compile.py`
  - 預設檢查 `workspace/scripts`；通過了才交給使用者進遊戲測試
  - 錯誤訊息只有行號，工具會列出各檔案的第 N 行
- **開發時從 REDkit 啟動遊戲**，以便使用 Script Studio 熱重載
  - 工具列按鈕（使用者 2026-10-12 確認的提示文字，左到右）：
    `play game`、`play game on the current layer only. Fast.`、**`load a saved game`**、`enable editor streaming`、`leave game camera postion`
    - 另有 `use selected game definition`（把 Asset Browser 選取的 `.redgame` 放進下拉選單）與 `play game from definition`（用該定義檔開始；預設 `witcher3.redgame` 是從新遊戲開頭）
  - **改了 XML：結束遊戲，重新按 `play game` 或 `play game on the current layer only. Fast.`**（約 10 秒）
    - 每次啟動遊戲、回到編輯器時，都會重新讀我們的 XML；**不需要讀存檔**（2026-10-12 紀錄確認，見 `docs\findings.md` §13.7）
    - 編輯器裡要先開著世界：REDkit 重開後若沒有世界，用 **File → Open World** 開 `levels\novigrad\novigrad.w2w`（不必讀存檔）
    - 不讀存檔時 Geralt 是預設狀態，要重新 `additem` 拿 AK
  - **改了腳本檔：遊戲進行中按 REDkit 的 Tools → Debuggers → Reload scripts，就會重新編譯並套用**（2026-10-13 實測，`docs\findings.md` §13.14）
    - 不用結束遊戲，也不用重開 REDkit；只重開遊戲則**不會**重新編譯（§13.10）
    - Script Studio 的 **Debug → Reload scripts（F7）** 是同名功能，未實測
  - **測試用世界建議 `engine\reference_level\world\reference_level.w2w`**：官方的測試關卡，實測載入 0.20 秒（Novigrad 約 2～3 秒），見 `docs\findings.md` §13.9
  - 需要平常存檔的狀態時才用 `load a saved game`（約 35 秒，會播前情提要影片）
  - **按 `Fast` 前先把鏡頭放到地面附近**，否則 Geralt 會從鏡頭位置掉下來摔死（Wiki「Start the game from the editor」）
    - 滑鼠指向地面按 **J**：鏡頭瞬移到該點；**Q／E** 升降；**Ctrl+Alt+0～9** 存鏡頭位置、**Ctrl+0～9** 叫回（Wiki「Useful shortcuts」、「Control the camera」）
    - 存的位置寫在 `<REDKIT_DIR>\bin\r4LavaEditor2.sessions.ini` 各世界的 `WorldCameraBookmarks` 區段
  - **F10**：Wiki 兩頁說法不同——「Switch between the game and editor」寫切回編輯器、再按回到遊戲；「Useful shortcuts」寫結束遊戲（quit game session）；實際行為未確認
  - 遊戲中其他快捷鍵（Wiki「Useful shortcuts」）：數字鍵盤 **1** 殺死範圍內所有敵人、數字鍵盤 **+／-** 調整時間流速、**F1** 自由鏡頭
  - 存檔資料夾：`C:\Users\beyon\OneDrive\Documents\The Witcher 3\gamesaves`（REDkit 的紀錄檔所示）
- 測試前備份存檔：`文件\The Witcher 3\gamesaves`

---

## 13. 參考資料

**REDkit 官方 Wiki**

- Script Studio：https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36864027/WS+Script+Studio+basics
- 新增物品與屬性：https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/136445979/HOW-TO+Add+items+and+attributes
- 動畫與 Blender：https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6326649/HOW-TO+Use+animations+in+REDkit+and+Blender
- 蒙皮模型與 Blender：https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6326771/HOW-TO+Use+skinned+meshes+in+Blender
- Blender 外掛安裝：https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6326607/HOW-TO+Install+the+Blender+plugin
- Wwise 授權：https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6327958/HOW-TO+Get+a+Wwise+license
- Wwise 聲音實作：https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6327994/HOW-TO+Implement+sounds+and+use+Wwise

**CS2 素材與數值**

- Source 2 Viewer 匯出模型：https://s2v.app/ValveResourceFormat/guides/exporting-models.html
- Source 2 Viewer 命令列：https://s2v.app/ValveResourceFormat/guides/command-line.html
- CS2 武器數值檔：https://raw.githubusercontent.com/SteamTracking/GameTracking-CS2/master/game/csgo/pak01_dir/scripts/weapons.vdata
- CS2 彈道圖（驗證用）：https://csdb.gg/recoil-patterns/

**參考 mod（Nexus）**

- Firearms：https://www.nexusmods.com/witcher3/mods/4903
- Complete Crossbow Overhaul：https://www.nexusmods.com/witcher3/mods/2755

**音效設定**

- REDkit & Wwise 設定教學：https://www.audiokinetic.com/en/blog/the-witcher-3-redkit-tutorial
