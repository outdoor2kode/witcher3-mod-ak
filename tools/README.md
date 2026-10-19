# tools：工具索引

> 每支工具的用法在它的檔頭（docstring／`<# #>`）；這裡只列用途和相關文件（第 41 項回顧：工具多了找不到，2026-10-19 建）
> 新增工具時在這裡加一行
> Python：`python -X utf8 tools/<檔名>`；動畫類要 h5py → 用 Blender 內建的 Python（`"D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I`，h5py 在 `_vendor\pylib`）

## 要改什麼 → 去哪個檔

| 要改的 | 檔案 | 文件 |
|---|---|---|
| 射擊、換彈、彈匣、HUD、按鍵、騎馬、船上水裡的行為 | `workspace\scripts\local\gfg_*.ws`（9 個檔；`gfg_core.ws` 檔頭寫每個檔管什麼；10-20 從一個 `gfg_ak47.ws` 拆開） | `docs\findings.md` §14～§37 |
| 物品（AK、子彈）的數值、名稱 ID | `workspace\dlc\gunforgeralt\data\gameplay\items\gunforgeralt_items.xml` | `CLAUDE.md` §6.11 |
| 物品名稱、說明的文字 | 字串資料庫 `LocalEditorStringDataBaseW3_UTF8_mod.db`（＋文字版 `.csv`） | `docs\findings.md` §37.2 |
| 動畫（89 段） | `workspace\dlc\gunforgeralt\data\animations\gfg_ak47_geralt.w2anims`（AnimBrowser 匯入下面「動畫」工具產生的 `.re`） | `CLAUDE.md` §6.11、`docs\m3.md` |
| 動畫圖（AK 專用的 4 張） | `ak_graphs.py` 產生（不進 git） | `docs\findings.md` §34 |
| 模型、貼圖、slot | `workspace\dlc\gunforgeralt\data\items\weapons\gfg_ak47\`（`.w2ent` 進 git；模型、貼圖是匯入的產物） | `docs\m3.md` |
| 圖示 | `workspace\dlc\gunforgeralt\data\gameplay\gui_new\icons\…` | `CLAUDE.md` §6.19 |
| 槍聲 | `ak_soundbank.py` → `workspace\soundbanks\pc\gfg_ak47.bnk` | `CLAUDE.md` §6.20 |
| DLC 掛載器 | `workspace\dlc\gunforgeralt\test.reddlc`（只能在 REDkit 改） | `CLAUDE.md` §6.11 |

## 驗證、操作（每天用）

| 工具 | 用途 | 文件 |
|---|---|---|
| `desk.ps1` | 截圖（含格線、被擋住的視窗）、滑鼠、鍵盤、連拍、保持清醒：操作 REDkit、遊戲、Blender | `CLAUDE.md` §12 |
| `wcc_compile.py` | 用 wcc_lite 編譯 mod 腳本（約 20 秒，不進遊戲） | `CLAUDE.md` §12 |
| `claude_compact.ps1` | 自主模式：Claude 自己壓縮 context（compact／clear）、看門狗（watch） | `CLAUDE.md` §3、§14 |
| `audio_rec.py` | 錄電腦播的聲音、分析每發的起點和音量（Claude 聽不到時） | `CLAUDE.md` §6.20 |
| `pose_check.py` | 解析 `editor.log` 的雙手持槍紀錄（要 `gfg_ak47.ws` 印 pose 紀錄；10-17 清理後沒有印了） | `docs\m3.md` |
| `..\.githooks\check_ctrl.py` | commit 前擋控制字元（pre-commit 會叫；也可以手動檢查檔案） | `CLAUDE.md` §15 |

## 讀、改二進位檔

| 工具 | 用途 | 文件 |
|---|---|---|
| `cr2w_dump.py` | CR2W 檔（`.w2beh`、`.w2ent`、`.w2anims`…）印成文字（`--find`、`--tree`） | `CLAUDE.md` §12 |
| `ak_graphs.py` | 原版 5 張動畫圖的複本＋改名（`gfg_`）＋套用下面兩支的修改 | `docs\findings.md` §34 |
| `overlay_patch.py` | 上半身動畫圖（`pc_overlay`）的手臂覆蓋（直接跑會停：給 `ak_graphs.py` 用） | `CLAUDE.md` §6.16 |
| `gameplay_patch.py` | 主動畫圖（`pc_gameplay`）直線走跑的兩手臂（同上） | `CLAUDE.md` §6.16 |
| `mesh_material_patch.py` | 改 `.w2mesh` 材質的數值參數（原地改、重算校驗碼） | `docs\findings.md` §32 |
| `sound_cache.py` | 聲音封存檔 `soundspc.cache`：列出、取出、檢查、打包（裝進遊戲時用） | `CLAUDE.md` §6.20 |
| `vpk_extract.py` | 從 CS2 的 VPK 取出檔案（只讀） | `CLAUDE.md` §4 |

## 動畫（輸出 `.re` → AnimBrowser 同名匯入；檔名 `gfg_` 開頭）

| 工具 | 產生的動畫 | 文件 |
|---|---|---|
| `square_pose.py` | 走跑時正面持槍；也是共用的 FK、兩節 IK 函式 | `docs\m3.md`「走跑時正面持槍」 |
| `two_hand_pose.py` | 雙手持槍的底層姿勢（第 1 步） | `docs\m3.md`「第 1 步」 |
| `aim_delta.py` | 瞄準差值 4 段（第 2 步）；也是共用的 `.re` 讀寫 | `docs\m3.md`「第 2 步」 |
| `move_pose.py` | 走跑時上半身的雙手持槍 | `docs\m3.md` |
| `charge_pose.py` | 沒開槍時走跑：持槍衝鋒（第 30 項） | `docs\m3.md`「持槍衝鋒」 |
| `horse_pose.py` | 騎馬瞄準的差值（第 3 項） | `docs\m3.md`「騎馬」 |
| `draw_pose.py` | 騎馬拔槍的雙手版（第 16 項） | `docs\m3.md` |
| `reload_pose.py` | 換彈（第 8、34、39 項）：每格檢查手腕角度、穿插 | `docs\m3.md`「換彈姿勢重做」、`docs\findings.md` §38 |
| `inv_pose.py` | 物品欄預覽的展示動畫（第 24 項） | `docs\m3.md` |
| `re_blender.py` | 用 REDkit 的 Blender 外掛匯入、匯出 `.re`（背景模式） | `docs\m3.md`「Blender 外掛」 |
| `re_fix.py` | 修補外掛匯出的 `.re`（骨頭位置、Root 改回原檔） | `docs\m3.md`「Blender 外掛」 |

## 素材（模型、貼圖、圖示、聲音）

| 工具 | 用途 | 文件 |
|---|---|---|
| `m3_build_ak.py` | CS2 的 AK → 十字弩的方向、握把在原點 → `.fbx`（Blender 背景模式） | `docs\m3.md` |
| `m3_inspect.py` | 印模型的大小、方向、骨頭、材質（只讀） | `docs\m3.md` |
| `m3_textures.py` | CS2 的貼圖 → 巫師3 `pbr_std` 用的 PNG | `docs\m3.md` |
| `ammo_build.py` | 子彈：物品圖示、彈頭模型、貼圖 | `docs\findings.md` §35、§37.3 |
| `ak_icon.ps1` | AK 的物品欄、輪盤圖示 | `CLAUDE.md` §6.19 |
| `ak_soundbank.py` | CS2 的 WAV → 槍聲 SoundBank（不用 Wwise） | `CLAUDE.md` §6.20 |
| `recoil_pattern.py` | 後座力彈道：換算成角度、畫圖、產生腳本的資料表 | `CLAUDE.md` §9 |

## 測試輔助（`test\`；Claude 進遊戲測試時用；2026-10-19 從 session 暫存搬進來）

| 檔案 | 用途 |
|---|---|
| `test\g.sh` | bash 函式：`P=<截圖資料夾> source tools/test/g.sh`；`set_mw`／`set_gab`（視窗）、`reload_edit`、`game_start`、`ak_select`、`game_end`、`restart_all`、`horse_start`、`side_after`（側面連拍換彈）、AnimBrowser 的 `import_one`／`add_ev`／`add_dur`／`add_track`／`rm_anim`／`save_gab`、圖片 `crop`／`gridm`／`mont`；說明在每個函式上面 |
| `test\gfg_debug.ws` | 測試用的主控台指令（`gfgfree`、`gfgshots`、`gfgmag`、`gfgbv`、`gfgstack`、`gfggraphs`、`gfgdrawlog`、`gfgammo`、`gfgbulletwatch`、`gfgbulletview`、`gfgakstate`、`gfgakshow`）；`dbg_on` 放進 workspace、`dbg_off` 拿出來（**打包前要拿出來**） |
| `test\crop.ps1`、`grid.ps1`、`montage.ps1` | 裁切放大、拼成格子（標編號）、橫向拼接（`g.sh` 的 `crop`、`gridm`、`mont` 會叫） |

- 座標是 1920x1080、REDkit 最大化時量的：介面不一樣先截圖再改
- 10-19 17:3x 遊戲裡從頭跑過一次：`dbg_on` → `reload_edit` → `game_start` → `ak_select` → 每個除錯指令 → `side_after` → `game_end` → `dbg_off` → `reload_edit`（AnimBrowser 那幾個這次沒跑；10-16～10-19 用過）
- `gfg_debug.ws` 用到 `workspace\scripts\local\gfg_*.ws` 的欄位、函式：那邊改名時這裡跟著改；檢查：全部放進同一個暫存資料夾給 `wcc_compile.py` 編譯

## 資料夾

- `_vendor\`：第三方（REDkit 的 Blender 外掛、h5py、wwiser）；不進 git
