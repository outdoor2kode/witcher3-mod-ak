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
| `<REDKIT_DEPOT>` | `<REDKIT_DIR>\r4data` | REDkit 自帶的 depot（唯讀；虛擬 depot 的最底層）；**原版物品 XML 散檔在 `gameplay\items\`**；原版實體模板（`.w2ent`）、材質圖（`.w2mg`）也在這 |
| `<UNCOOK_DEPOT>` | `D:\depot` | REDkit 第一次設定時把遊戲素材 uncook 到這裡（唯讀；虛擬 depot 的中間層）；原版模型（`.w2mesh`）、貼圖（`.xbm`）在這；REDkit 的 Export Asset 會把貼圖（TGA）寫到這裡（2026-10-15，`docs\m3.md`） |
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
| REDkit Blender 外掛 | `<REDKIT_DIR>\bin\tools\BlenderPlugin\blender_re_animations_plugin.zip` | 2026-10-15 備好：複本在 `tools\_vendor\`、h5py 3.16.0 在 `tools\_vendor\pylib\`（都不進 git；不裝進 Blender）；Blender 5.2 背景模式能匯入（範例檔實測）；用法和注意事項見 `docs\m3.md`「Blender 外掛」 |
| Wwise | ⚠️ **待重新確認**：原本寫 2021.1.7.7796，但 REDkit 5.0 Changelog 寫「requires Wwise 2023 with the Mastering Suite and Motion plugins」 | 聲音階段；授權每 3 個月重新申請；M4 前查清確切版號 |
| ffmpeg | 聲音階段 | 把 REDkit 原版音效 `.opus` 轉 `.wav` |
| Source 2 Viewer | GUI + CLI | 從 CS2 的 VPK 匯出模型、貼圖、聲音 |
| Git | 已裝 | 版本控制 |
| VS Code + WitcherScript（作者 webspam） | 選用 | 使用者自己讀程式碼用 |

**兩個 Blender 版本並用時**：用 FBX / glTF 交換檔案，不要直接互開 `.blend`。

**Claude Code 的專案設定**（`.claude\settings.local.json`，不納入 git；2026-10-15）

- effort 固定 **max**：`env` 的 `CLAUDE_CODE_EFFORT_LEVEL`
  - `max` 只能用這個環境變數保存；設定檔的 `effortLevel` 不收 `max`（官方文件 model-config「Adjust effort level」）
  - 環境變數優先於 `/effort`：要換等級就改這裡（官方文件 env-vars）
- context 用量提醒（§11）：
  - `statusLine` 換成 `.claude\hooks\statusline.sh`：畫面照舊（交給 `~\.claude\statusline.sh`），另外把使用率記到 `%TEMP%\claude\gfg-context\<session_id>.pct`
    - hook 的輸入沒有 context 使用率，只有狀態列的輸入有（官方文件 statusline、hooks）
  - `hooks` 的 PostToolUse、UserPromptSubmit 跑 `.claude\hooks\context-check.sh`：到門檻提醒一次（Claude 收到 additionalContext、使用者看到 systemMessage）；降回門檻以下再重新計算
  - 2026-10-15 實測：設定存檔後，執行中的 session 立刻套用；提醒訊息送得到 Claude
- 自動壓縮（2026-10-16）：`autoCompactWindow` 480000 → context 到 48 萬 tokens（這個模型 100 萬的 48%）時自動壓縮、接著做（保險用；平常 45% 由 Claude 自己壓縮，§14；16:2x 從 400000 調高，免得比 45% 先觸發）
  - 官方文件 model-config「Set the auto-compact window」：`autoCompactWindow` 任何設定檔都能放；預設要到約 96.7 萬才壓縮
  - 官方文件 settings「When edits take effect」：設定檔存檔後，執行中的 session 會重讀（`model`、`effortLevel`、`modelSettings` 例外）
  - Claude 不能從工具直接下 `/clear`、`/compact`（官方文件 slash-commands：內建指令只有 `/init` 等少數能用 Skill 叫）
  - **Claude 自己清理**（使用者 2026-10-16 要求：「你都能控制 WINDOWS 了」）：`tools\claude_compact.ps1` 在背景跑 → 等 Claude 這一輪結束（對話紀錄出現 `end_turn`）→ 在 Windows Terminal 打 `/compact`（或 `/clear`）→ 等壓縮完成（紀錄出現 `compact_boundary`）→ 打「讀交接檔接著做」
    - 自主模式中 context 到 45%：先更新交接檔、commit → 背景跑這支 → 結束這一輪
    - 預設 `/compact`：保留摘要、接續性較好（10-16 兩次自動壓縮也是 compact）；`/clear` 完全靠交接檔，換大任務時再用
    - 這個 session 的 `autoCompactWindow` 沒生效：實際自動壓縮在 96 萬、62 萬 tokens（10-16 04:13、06:59）

---

## 4. 資料夾配置

```
<REDKIT_PROJECT>\                 ← Claude 的工作目錄（可修改）
  CLAUDE.md
  .claude\settings.local.json     ← Claude Code 的專案設定（不納入 git；內容見 §3）
  .claude\hooks\                  ← 設定用到的腳本：context 用量提醒（納入 git）
  docs\                           ← 調查筆記、決策紀錄
  data\cs2\weapons.vdata          ← CS2 武器數值（文字檔，納入 git）
  tools\                          ← 遊戲外驗證用腳本（後座力模擬、Blender 腳本）
  gunforgeralt.w3edit             ← REDkit 專案檔
  LocalEditorStringDataBaseW3_UTF8_mod.db   ← 專案字串資料庫（物品名稱等；ID 從 10000000 起；SQLite）
  LocalEditorStringDataBaseW3_UTF8_mod_export.csv   ← 字串資料庫的文字版（REDkit 存字串時自動寫出，檔名寫死在 editor.exe）；納入 git 以便看出字串的變更
  workspace\                      ← REDkit 虛擬 depot 的專案層（第一次新增檔案時建立）；路徑和 depot 一一對應
    dlc\<dlc名稱>\                ← 自訂 DLC：物品 XML、實體模板、.reddlc（.reddlc 要在 REDkit 建立）
      data\items\weapons\gfg_ak47\  ← AK 的實體模板（納入 git）、模型、貼圖（REDkit 匯入的產物，不納入 git）
    scripts\local\                ← mod 腳本（annotation）；2026-10-12 確認會被遊戲載入
    gameplay\behaviors\pc\behaviorgraph\pc_overlay.w2beh、pc_gameplay.w2beh  ← 改過的原版動畫圖（tools\overlay_patch.py、gameplay_patch.py 產生，不納入 git；§6.16）
  assets\ak47\                    ← M3 腳本的輸出（.blend、.fbx、.png 不納入 git）、匯入模型用的材質 XML（納入 git）
  thumbnails\                     ← REDkit Asset Browser 的縮圖（自動產生，不納入 git）
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
- **REDkit 和遊戲的畫面操作、測試**：`tools\desk.ps1`（使用者 2026-10-16：不接受「做不到」，要 Claude 自己操作、自己驗證；§12）

**使用者負責：**

- 要用使用者帳號的事：例如 Wwise 授權
- 使用者在場、想自己操作時：REDkit 編輯器（check out、匯入模型與貼圖、設定實體、處理動畫）、從 REDkit 啟動遊戲測試
- Blender 不用使用者操作：需要目視時 Claude 渲染成圖片

---

## 6. 已查證的重要限制

1. **Remastered 5.x**（2026-09-29 上線）讓含腳本、XML、w3strings 的舊 mod 失效，需用 REDkit 更新
   → 參考 mod 大多不能直接用，**只參考作法**
2. REDkit 專案中，要修改的原版檔案需先在 REDkit **check out**，REDkit 才會打包
3. 從 **REDkit 編輯器啟動遊戲**時，可在遊戲中**熱重載腳本**（Tools → Debuggers → Reload scripts，2026-10-13 實測）；XML 要重新啟動遊戲，模型等資源未確認
   - 這時遊戲跑在 `editor.exe` 裡，直接讀 `workspace` 的原始檔（`docs\findings.md` §13.16）
   - 已安裝的 mod 都在 `<W3_GAME_DIR>\mods\`；我們的 mod **2026-10-17 打包成功**（Publish → Save and publish mod project，輸出在專案的 `packed\`：`docs\findings.md` §27；最新一次 05:46、版本 0.2），**還沒裝進遊戲、沒在 Steam 版驗證**（使用者 2026-10-17：開發完整再裝；裝進去要寫遊戲資料夾 → 先問使用者）
   - 打包後同一次開著的 REDkit 按 play game 會當掉 → 打包完重開 REDkit 再測
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
    - **實體模板**用 `CR4DefinitionsEntitieTemplatesDLCMounter` 掛載資料夾（`entitieTemplatesDirectoryPath`，本專案 `dlc\gunforgeralt\data\items\`）
      - 物品 XML 的 `equip_template` = 模板的**檔名**（不含 `.w2ent`），放在掛載資料夾往下任何一層都找得到（2026-10-15 遊戲實測，`docs\m3.md`）
      - 模板的 slot 在 Entity Editor 下方分頁 **Slots**（和 Node properties 同一排）改；使用者 2026-10-15 改過 `bolt`
      - slot 的 transform 存檔時，旋轉的 3 個 float 是 **(Roll, Pitch, Yaw)**（填 Pitch -20.4、Yaw -90 存成 (0, 339.6, 270)；第一個是 Roll 是推論；`docs\m3.md`）
    - **DLC 可以替現有的角色模板加動畫組**：`CR4EntityTemplateParamDLCMounter` ＋ `CAnimAnimsetsParam`（元件名稱＋動畫組清單）
      - 原版 bob 用它替 `man_base.w2ent` 加 Geralt 的動畫；NPC 十字弩兵的模板也用 `CAnimAnimsetsParam` 掛動畫組（`docs\m3.md`「雙手持槍：第二輪查詢」）
      - 本專案 2026-10-15 實測可用：掛在 `geralt_player.w2ent`（照 dlc16），`componentName` = `man_base`
      - **同名動畫：遊戲用 DLC 加的那段，蓋過原版**（2026-10-15 實測 `man_geralt_gabriel_aim_idle_rp` 換成 NPC 的雙手瞄準，Geralt 站著瞄準的姿勢跟著變；只測了這一段；`docs\m3.md`「第 12～15 步的結果」）
        - 原版用同名動畫的地方（例：Geralt 的十字弩）也會跟著變
        - **動畫事件不在動畫裡，在動畫組的那一筆**（例：換彈中段裝箭的 `OnWeaponReload`）→ 同名蓋過去會少掉事件，要自己加（2026-10-16 實測，`docs\m3.md`「雙手持槍：換彈」）
          - AnimBrowser 選動畫 → 下方時間軸右鍵 **Add simple event**／**Add duration event** → 雙擊事件 → 右邊改 `eventName`、`startTime`、`duration` → Ctrl+S
          - 不要用 Copy／Paste 原版那筆再同名匯入：事件帶得過來，但遊戲裡每格報 `fully streamable` 錯誤（原因沒找到）
          - 我們動畫組裡已經有的動畫，用 Import 同名重匯（換動畫資料）：那一筆的事件會保留（2026-10-16 23:0x 實測：騎馬換彈 4 段的 6 個事件、aim_cycle 8 段的韁繩事件都在）
      - Geralt 的模板鏈：`geralt_player.w2ent` → `player_base_m.w2ent` → `man_base.w2ent`；骨架 `man_base.w2rig`，和人類 NPC 同一套
      - 遊戲生成的玩家是 `gameplay\templates\characters\player\player.w2ent`（`game\witcher3.redgame` 的 `defaultPlayerTemplate`），它 include `geralt_player.w2ent`；dlc16 替 `geralt_player.w2ent` 加動畫組（2026-10-15 讀原版資料，`docs\m3.md`「第三輪查詢」）
      - **複製動畫到自己的動畫組**：Asset Browser 雙擊 `.w2anims` 開 AnimBrowser → **All animations** → 動畫右鍵 **Copy animation** → 另一個動畫組最上面那行右鍵 **Paste animation to set** → 右鍵 **Rename**；動畫資料原封不動（2026-10-15 實測，`docs\m3.md`「第 1～7 步的結果」）
        - 新的動畫組：資料夾空白處右鍵 → Create → Set of animations
        - 開動畫組時問「Entity doesn't have animated component with select animset…」→ 按 **No**（預覽角色預設是 Geralt；不需要預覽）
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
13. **原版 Flash 介面（HUD、選單）的 ActionScript 原始碼在 `<REDKIT_DEPOT>\gameplay\gui_new\actionscript\`**（2026-10-14）
    - 和遊戲用的是同一版：`editor.log` 裡 Scaleform 錯誤的行號對得上（`docs\findings.md` §24.7）
    - 腳本呼叫的 Flash 函式（`GetMemberFlashFunction`）、Flash 呼叫的腳本事件（`GameEvent.CALL`）都查得到
14. **REDkit 匯入 Blender 做的蒙皮 FBX 時，不會用 FBX 裡的骨頭權重**（2026-10-15，`docs\m3.md`）
    - `editor.log` 寫 `HasSkinning: true (NODE '模型名稱')`：整個模型綁在一根「和模型節點同名」的骨頭上，綁定矩陣是單位矩陣
    - 照 Wiki 的 Blender 匯出設定、照 REDkit 自己匯出的 FBX 結構都試過，結果一樣
    - → 要掛在既有骨架上的模型：匯出不帶骨架、名稱取成骨頭名的模型，頂點先換到那根骨頭的座標系（`tools\m3_build_ak.py`）
    - **匯入、重匯時 `importAsSkinnedMesh` 都要設 true**：REDkit 不保存匯入選項，重開後變回 false；沒設的話模型沒綁骨頭，遊戲裡看不到（2026-10-15）
      - 確認方式：`editor.log` 要有 `HasSkinning: true (NODE '骨頭名')`；`Created mesh chunk … 0 bones` 就是沒綁
      - Reimport → Mesh only 會沿用 REDkit 記憶體裡的匯入設定，不會讓人改 → 重開 REDkit 後要換模型，用 **Import > Mesh** 蓋掉舊檔
    - **匯入模型後，同一次開著的 REDkit 裡進遊戲沒有貼圖顏色**：重開 REDkit（或在 Mesh editor 重新指定貼圖）就正常；硬碟上的檔案沒問題（2026-10-15 比對前後兩版只差 `authorName`；`docs\m3.md`）
15. **量動畫裡骨頭的位置：AnimBrowser 對動畫按右鍵 → Calc bone MS**（2026-10-15 實測，`docs\m3.md`「Calc bone 的結果」）
    - 輸入骨頭名稱、時間 → 跳出 Result 視窗，同時寫進 `editor.log`（`Bone MS - '骨頭' - time - '時間'`、`>Position:`、`>Rotation:`）
    - MS = 角色的模型座標：**X 右、Y 前、Z 上**，公尺
    - Rotation 的 3 個數字是 **(Pitch, Yaw, Roll)**，矩陣 = Rz(Yaw)·Rx(Pitch)·Ry(Roll)（用骨架參考姿勢和兩手、頭驗證過）
    - 骨架 `.w2rig` 的參考姿勢在 `CSkeleton` 的自訂資料：每根骨頭 48 bytes（位置、四元數 x y z w、縮放），父骨頭在 `parentIndices`
16. **原版的 CR2W 檔（例：動畫圖 `.w2beh`）可以用腳本改數值**：改好的檔放到 `workspace` 的相同路徑（= check out），遊戲會讀（2026-10-16 實測 `pc_overlay.w2beh`；`docs\m3.md`「右手臂被換成另一段動畫」）
    - 校驗碼有 3 層，都是 CRC32：每個物件（存在物件表）→ 物件表（存在檔頭的表格欄位）→ 檔頭（前 160 bytes，校驗碼欄位先填 `0xDEADBEEF` 再算）；改一個物件要 3 層都重算
    - 做法、檢查的方式照 `tools\overlay_patch.py`：原檔只讀、先驗證原檔的校驗碼和要改的內容、寫完讀回來檢查
    - 改過的原版檔用 `.gitignore` 排除，靠腳本重做
    - 本專案改過的：`pc_overlay.w2beh` 的曲線 #18561（站著瞄準時右手臂不再被換成 `man_ger_sword_axii_arm_override`）；`pc_gameplay.w2beh` 3 個直線走跑節點的骨頭表（`tools\gameplay_patch.py`：拿十字弩直線走跑時兩隻手臂都用十字弩動畫；`docs\m3.md`「直線走路、跑步的右手」）
    - 物件變大小也可以改：物件資料連續排列、沒有 buffer 的檔，後面的物件位移往後挪、更新物件表和檔頭的檔案大小（第 6、7 個 u32）（`tools\gameplay_patch.py`）
    - **REDkit 開著時新建的 workspace 檔，遊戲讀不到 → 重開 REDkit 才生效**（2026-10-16 `pc_gameplay.w2beh` 實測）；改既有的檔不用重開
17. 詳細出處（檔案路徑、行號、Wiki 頁面 ID）見 `docs\findings.md`
18. **拿在手上的物品：畫面上的模型跟著物品系統掛在 slot 的動畫元件，不跟物品實體**（2026-10-16 遊戲實測，`docs\findings.md` §26）
    - 對物品實體 `CreateAttachment`（帶偏移）只移動實體矩陣；物品骨架（例：AK 的 `handle`）、蒙皮的模型照原版跟著 slot 骨頭
    - 量畫面上的擺法要看物品骨架的骨頭，不要看實體矩陣
    - 要改畫面上的擺法：自己生成同模板的替身（骨架跟著實體走），藏起真的那把（第 5 項的提槍就是這樣做）
19. **物品圖示（PNG）放在 DLC 的 `data\gameplay\gui_new\` 下**（物品 XML 的 `icon_path` 相對於這裡），`.reddlc` 要有 `CR4ScaleformContentDLCMounter`（2026-10-18 遊戲實測，`docs\findings.md` §31）
    - **加了掛載器、新建圖檔，都要重開 REDkit 才生效**
    - `editor.log` 的 `Failed to convert path` 只列找不到的路徑；找到的不寫
    - 本專案：`icons\inventory\weapons\gfg_ak47_64x128.png`（物品欄，直的）、`gfg_ak47_128x64.png`（輪盤，水平：腳本換掉輪盤資料裡的路徑）

---

## 7. 設計決策（已定案）

**系統基礎**

- **借用十字弩系統**（遠程武器、投射物、瞄準模式），不從零寫武器系統
- **範圍只做 AK 本身**：AK 以外的物理效果照遊戲原本的行為（例：箭打在牆上沒有痕跡就算了），不另外處理（使用者 2026-10-13）
- **AK 是選用物品時不准拿劍**（使用者 2026-10-17：「強制裝上 AK 的情況下，不准拿劍，進到狼群或戰鬥，要自動做的事情是舉槍」）
  - 原版自動拔劍的時候改成舉 AK（進戰鬥、被打、敵人靠近、騎馬）；1／2 鍵拔劍擋掉；手上已經有劍時先收劍再拿 AK
  - 戰鬥中按 C 收起 AK，會再自動舉起（同原版戰鬥中收劍會馬上再拔）
  - 選用物品換成別的（炸彈等）時照原版；做法與原版的拔劍路線見 `docs\findings.md` §29
- **移動時朝哪裡：照持劍**（使用者 2026-10-18：「持劍走入怪物群，即便按下 S 後退時，不會整個人往後走，而是一直面對怪物。我認為持槍時也該仿照這樣」）
  - 戰鬥中、附近有敵人（`PCS_AlertNear`）、沒衝刺：身體一直朝目標，腳用側移、後退的步伐（約 2 公尺／秒；持劍的戰鬥走路 2.3～2.6）
  - 開槍中又在移動：朝準心；衝刺、敵人遠（`PCS_AlertFar`）、不在戰鬥中：朝移動方向（同持劍）
  - 實測與原版機制見 `docs\findings.md` §30

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
- **物品圖示**：CS2 物品欄的 AK 圖；物品欄用直的（64×128）、輪盤用水平的（128×64）（使用者 2026-10-18；`docs\findings.md` §31）

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
  - **context 用到 42%**：hook 會提醒（§3）→ 手上的任務照做，同時更新交接檔；這次回覆的最後提醒使用者 `/clear`（使用者 2026-10-15；2026-10-16 16:2x 門檻改成 45% 壓縮，提醒跟著從 35% 移到 42%）
  - 48% 自動壓縮當保險（§3）；使用者不在時（交接檔的「自主模式」）不用提醒 `/clear`
  - **自主模式另有規則：§14**（context 到 45% 自己用 `tools\claude_compact.ps1` 壓縮）
- 確認了新的重要事實（路徑、API、格式）就更新本檔

---

## 12. 測試方式

- **Claude 自己操作 REDkit 和遊戲**：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/desk.ps1 <指令>`（用法在檔頭；2026-10-16 實測）
  - 截圖：`wshot proc:editor 檔名.png mode=print grid=50`（REDkit 被終端機擋住也截得到，含 D3D12 畫面；格線標螢幕座標）→ 用 Read 看圖
  - 點擊、按鍵前先 `focus`；REDkit 是 wxWidgets，UI Automation 看不到元件 → 看截圖的座標點
  - 只對 editor、witcher3、blender 送輸入（工具會擋終端機、瀏覽器）；做完把終端機叫回前面
  - 螢幕鎖定、睡眠時截圖和輸入都會失效 → 長時間自己跑時用 `awake`
- **開啟主控台**：`<W3_GAME_DIR>\bin\config\base\general.ini` 的 `[General]` 加 `DBGConsoleOn=true`，遊戲中按 `~`
- **取得物品**：`additem('物品名稱')`（物品名稱以實際定義為準）
- **開物品欄**：拿著 AK 時打不開（十字弩的 `Lock()`，`docs\findings.md` §31）→ 先按 C 收槍再按 I；Enter 開面板（2026-10-18 實測）
- **在 REDkit 編輯器直接放物件**（Wiki「HOW-TO: Add objects into the world multiple times」，頁面 15499265；未實測）
  - 開著世界、在 Scene 面板雙擊圖層使它變粗體（啟用）→ Asset Browser（Ctrl+A）選模型或實體 → 點一下畫面 → 按 **C** 放在滑鼠位置；也可以直接拖進畫面
  - 放模型時選 Static Mesh 才有碰撞（搜尋結果引用的同一頁內容）
  - 怪物：放遭遇區域、生成點、守衛區域，用 spawn tree 生成（Wiki「HOW-TO: Create a monster encounter」，頁面 6326170）
  - ⚠️ 放進原版世界的圖層等於修改原版檔案；測完不要存檔（§13.4 的原則）
- **測試用靶子**（原版主控台指令；2026-10-13 查程式碼；`spawnPath` 生成牆已實測，其餘**未實測**；見 `docs\findings.md` §15、§18.4）
  - `spawnPath('characters\npc_entities\monsters\wolf_lvl1.w2ent', true)`：在面前生成**敵對**的狼（`temp.ws:6790-6813`）；不加 `true` 會設成友善
    - 位置固定在玩家前方 3 公尺、面向玩家（`temp.ws:6797-6803`）
  - ⚠️ **友善的角色打不到**：玩家射出的投射物碰到友善角色不算命中（`throwable.ws:126-128`）
  - `spawn(名稱, 數量, 距離, 是否敵對, 等級)`（`temp.ws:6815-6942`）；「不敵對」時保留生物原本的態度，怪物照樣會攻擊
    - **可以指定距離 → 遠處的靶子用這個**，例：`spawn('wolf', 1, 60, true)`；沿鏡頭的水平方向，生成後往下找地面（上下 5 公尺內：`:6838-6849`、`:6903-6906`）
    - 名稱是**資源別名**，不能寫路徑（找不到別名時，拼出來的路徑少一個反斜線：`:6862-6867`）
    - 別名表：`<REDKIT_DEPOT>\gameplay\globals\resources\gameplay.xml`（例：`wolf`、`drowner`、`nekker`、`ghoul`、`bear_black`；盜賊沒有一般的別名）
  - 人物也用 `spawnPath`，例：`characters\npc_entities\main_npc\ciri.w2ent`；盜賊：`characters\npc_entities\crowd_npc\bandit\bandit_lvl1.w2ent`（§15.2 用過）
  - `spawnPath` 可以生成任何實體模板（`temp.ws:6790-6813` 用 `CreateEntity`），牆也可以（2026-10-13 實測），例：`dlc\bob\data\environment\architecture\grey_box_blockout\brick_wall_system\entities\wall_super_wide.w2ent`（寬 8 公尺、高 4.75 公尺；箭會插在上面，約 5 秒後消失：`docs\findings.md` §18.4）
    - 建築：`<REDKIT_DEPOT>` 裡路徑含 `architecture` 的 `.w2ent` 有 1598 個，例：`environment\architecture\human\redania\nomans_land\thatched_buildings\entities\nml_thatched_house_big_exterior.w2ent`（未實測；大小沒查過，生成在面前 3 公尺，可能壓到 Geralt）
  - `killall(範圍)` 清掉附近的敵人（`playerCheats.ws:9`）；`statstarget()` 印出目前目標的數值（`temp.ws:6168`）
  - 十字弩兵：`spawn('xbow', 1, 15, true)`（別名 `gameplay.xml:1149` → `gameplay\templates\characters\npcs\test_enemies\enemy_crossbow.w2ent`；未實測）
  - `god()`：無敵（`temp.ws:6054-6066`；未實測）
  - 時間、天氣（看清楚畫面用）：`settime(1, 12)` 改成中午（`gameTime.ws:182`）；`changeweather('WT_Clear')` 改成晴天（`temp.ws:737`；2026-10-16 實測，下雨時中午也很暗）
  - 原版**沒有**調整 NPC 血量、讓怪物不攻擊的指令
  （已安裝 Multi Companion Mod Remastered，但它生成的是**友方同伴**，不適合當靶子）
- **讀動畫圖等 CR2W 二進位檔**：`python -X utf8 tools/cr2w_dump.py <檔案> --out <輸出.txt>`（`--tree N`、`--find 值` 可縮小範圍；`docs\findings.md` §17.9）
- **REDkit 的紀錄 `<REDKIT_DIR>\bin\editor.log` 在 REDkit 重開時會被整個重寫**（2026-10-15）→ 遊戲測完、重開 REDkit 之前，先讓 Claude 讀紀錄
- **DLC 掛載器有沒有生效**：從 REDkit 開遊戲時會重讀 `.reddlc`，`editor.log` 寫 `[DLC] Mounted N DLC mounter(s).`（2026-10-15 是 165，含我們的 2 個）；加了掛載器，數字會跟著變（2026-10-15 加 1 個變成 166）
- **寫完腳本先編譯檢查**（Claude 自己做，約 20 秒）：`python -X utf8 tools/wcc_compile.py`
  - 預設檢查 `workspace/scripts`；通過了才交給使用者進遊戲測試
  - 錯誤訊息只有行號，工具會列出各檔案的第 N 行
  - 超過 1 分鐘沒結束：可能是 `wcc_lite` 的 EULA 視窗又跳出來（2026-10-15 發生過；要使用者按 Agree；`docs\findings.md` §12.5）
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

---

## 14. 自主模式（使用者 2026-10-16 定；每次自主模式都照這一節做）

**開關**
- 只有使用者說「開始自主模式」（或「恢復自主模式」）才開；**沒說就是互動模式**（照 §11：寫新東西前先問等）
- 任務清單全部完成，或只剩使用者能做的事（例：要用使用者帳號）→ 照下面「結束」收尾

**心態**
- **假設使用者一年後才回來**：不停地做，直到任務完成；不問使用者、不等回覆
- 要決定的事自己決定（選合理、可還原的做法），決定和理由寫進交接檔
- **不說「做不到」**：能操作 Windows、REDkit、檔案、終端機，就自己找方法（使用者 2026-10-16：「你都能控制 WINDOWS 了」）
- 範圍不變：只做 AK 本身（§7）；只改專案資料夾（§11）；不刪既有檔案；不動使用者其他的 Claude 分頁、其他程式

**不准停超過 10 秒**（使用者 2026-10-16：「有任何任何情況讓你沒有執行任何事超過10秒，就開始檢查原因並且排除」）
- 任何情況沒有在執行東西超過 10 秒 → 馬上查原因、排除；合理的等待除外（例：遊戲、REDkit 載入、編譯、壓縮）
- 這一輪不要結束；只有兩種情況可以結束：context 到 45% 交給 `claude_compact.ps1` 壓縮、自主模式結束
- 看門狗（開始時啟動）：`claude_compact.ps1 <對話紀錄> watch`：分頁閒置（標題開頭 ✳）超過 10 秒、紀錄 10 秒沒變、沒有在壓縮 → 打一段 `[gfg-watchdog]` 開頭的訊息叫醒
  - 收到 `[gfg-watchdog]`：查停下來的原因、寫進交接檔、排除，接著做
  - 叫醒後很快又停：下一次等久一點（10 → 20 → … 秒，最多 10 分鐘）；使用者 5 秒內有操作鍵盤滑鼠時先等（最多 60 秒），免得接在使用者打的字後面

**開始時**
1. 背景跑 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/desk.ps1 awake 2147483`（保持清醒，約 24.8 天；已經在跑就不用再開：查命令列含 `desk.ps1 awake` 的 `powershell.exe`）
2. CronCreate 每小時（第 13 分）的續做排程：內容＝讀交接檔「自主模式」「現在在做」接著做、確認保持清醒還在；排程 7 天會過期 → 第 6 天重排
3. 交接檔最上面寫「自主模式」：開始時間、任務清單（每項一列、狀態）、決定
4. 讀 context 使用率（`%TEMP%\claude\gfg-context\<session id>.pct`）
5. 背景跑看門狗：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/claude_compact.ps1 <對話紀錄.jsonl> watch`（它會建立旗標 `%TEMP%\claude\gfg-context\<session id>.autonomous`；已經在跑就不用再開）

**context 到 45% 才壓縮**（使用者 2026-10-16 16:2x：「context 改成到 45% 再 compact or clear」；原本 38%）
- 每次 commit 後、每做完一個大步驟，讀使用率
- **到 45%**：把手上的小步驟做完（或停在安全的地方）→ 交接檔寫好「接續的步驟」→ commit → 背景跑 `tools\claude_compact.ps1 <對話紀錄.jsonl>`（Bash 的 run_in_background）→ **結束這一輪**
  - 它會選自己的分頁、打 `/compact`、等壓縮完，再打「讀交接檔接著做」（§3）
  - 預設 `/compact`；換到新的大項目、而且交接檔完整時可以用 `clear`
- 42% 的 hook 提醒：開始收尾手上的步驟
- 保險：`autoCompactWindow` 480000（48%，§3），平常由上面的 45% 先處理
- 對話紀錄：`C:\Users\beyon\.claude\projects\D--OneDrive-Desktop-gunforgeralt\<session id>.jsonl`

**操作電腦**
- REDkit、遊戲、Blender、Script Studio：`tools\desk.ps1`（截圖、滑鼠、鍵盤；§12）；終端機只透過 `tools\claude_compact.ps1`（只打固定的兩段文字、先選自己的分頁）
- **等待**：一次最多 15 秒；經驗上更短就夠的步驟（例：選單、對話框出現）用 10 秒以下；到時間就截圖或讀紀錄判斷再決定，不是直接關程式；不寫長時間的輪詢
- 驗證自己做：遊戲裡截圖＋偵測紀錄（`[GFG]`）＋數字；每項要有遊戲裡的證據才算完成

**加快速度**（使用者 2026-10-16：流程上等待太久、花太多時間就改進）
- 重複的操作寫成函式或腳本（開遊戲、復活、拿 AK、選輪盤、重載腳本），穩定的放進 `tools\`
- 一次進遊戲把能測的都測完；能離線算的先離線算（Python、Blender 背景模式）
- 發現更快的做法（較短的等待、少一步）就改，寫進這一節或交接檔

**每次 commit**：一起更新交接檔（§11）

**結束**
1. CronDelete
2. 停掉保持清醒（TaskStop 背景工作，或殺掉命令列含 `desk.ps1 awake` 的 `powershell.exe`）；停掉看門狗：刪旗標 `<session id>.autonomous`（看門狗 1 秒內自己結束）或 TaskStop
3. 交接檔最上面寫「使用者回來時先看這裡」：做完的、沒做完的、要使用者決定或操作的
4. 終端機叫回前面（`desk.ps1 focus proc:windowsterminal`）
5. 最後的回覆：簡短列出結果
