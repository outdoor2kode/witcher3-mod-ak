# 交接：進行中的狀態

> 新 session 開始時讀這份，接著做。
> 只放「還在變動」的東西：已定案的決策在 `CLAUDE.md`，查證過的事實在 `docs\findings.md`。
> 每次 commit 時一起更新（`CLAUDE.md` §11）。內容是「現在」的快照：過時的直接改掉，不累積。

最後更新：2026-10-19 11:3x（壓縮前；自主模式：交辦的 8 項＋收尾、流程圖都做完；REDkit 專家訓練 B-5、B-6 進行中，進度改記在 `D:\OneDrive\Desktop\redkit_expert\docs\handoff.md`）

---

## 使用者 10-19 02:0x 的新指示（自主模式繼續，不結束）

原文：「如果你全做完了已交辦任務 整理一份你至今開發的流程圖 例如，要自己製作動畫，會先透過什麼工具做到什麼事再匯出或者怎樣，來完成這件事 然後標注是否工具為自己開發的。還是別人開發的。 流程圖儘量簡單明瞭好閱讀。 這個做完後，我要你訓練自己，變成 redkit 這軟體的開發專家，也就是資深軟體工程師，你可以操控該軟體以達到讓自己更理解所有功能。 創建你需要重建的資料夾檔案等到以助你學習。 也請參考 redkit 的官方文件。然後也可以參考相關社群。 訓練目標就是變成實質上的資深有經驗的開發人員。然後讓我以後可以呼叫你。例如，我呼叫你開啟自主模式，你就自動做某些事執行某些程式。 我呼叫 你現在是 redkit 開發專家，你就要變成擁有這軟體實際開發經歷的專家，知悉這軟體一切功能。 一樣，自主模式下訓練自己。 然後不要搞砸這個 mod，需要就換資料夾。 此外，我到時候還是會回來繼續開發這個 mod，直到我接收前，不斷訓練自己。然後注意 context」

| # | 任務 | 狀態 |
|---|---|---|
| A | 開發流程圖：每件事用什麼工具、做什麼、匯出到哪；標出工具是自己寫的還是別人的；簡單好讀 | **完成**（02:2x）：https://claude.ai/artifact/DXfFwfWpFmxteVoZKkFA4Z（「AK 模組工具鏈」；原始檔在 session 暫存 `flow\ak_pipeline.html`，要改：Artifact read 這個網址） |
| B | REDkit 專家訓練：操作 REDkit 學全部功能、讀官方文件和社群、做成以後叫得出來的技能；一直做到使用者回來 | **進行中**（下面「B 的計畫」；進度在 `D:\OneDrive\Desktop\redkit_expert\docs\handoff.md`） |

**決定**
- 流程圖：發布成網頁（Artifact），連結寫在這裡和最後的回覆；內容來源 = `CLAUDE.md`、`docs\m3.md`、`docs\findings.md`、`tools\`
- 訓練用另一個資料夾 `D:\OneDrive\Desktop\redkit_expert\`（使用者：「不要搞砸這個 mod，需要就換資料夾」）：知識庫、練習用的 REDkit 專案都放那裡；**這個 mod 的專案不拿來做實驗**
  - REDkit 一次只開一個專案 → 練習時關掉這個 mod 的專案、開練習專案；mod 的檔案都在 git 裡、不受影響
- 叫用方式：使用者層級的技能（`C:\Users\beyon\.claude\skills\`，任何資料夾都叫得到）
  - 「你現在是 redkit 開發專家」→ 技能 `redkit-expert`：讀知識庫的索引、照裡面的做法工作
  - 「開啟自主模式」→ 技能 `autonomous-mode`（做 `CLAUDE.md` §14「開始時」那幾步；工具用絕對路徑，任何資料夾都能跑）
- 自主模式**不跑結束程序**（使用者：「直到我接收前，不斷訓練自己」）：保持清醒、看門狗、每小時續做排程都繼續；排程 7 天過期（10-18 22:3x 建立 → 10-24 重排）

**B 的計畫**（02:2x 定；做完一步就在這裡打勾、commit 到訓練資料夾的 git）
1. 建資料夾 `D:\OneDrive\Desktop\redkit_expert\`（`git init`；不放 CS2 素材、不放遊戲檔）
   - `CLAUDE.md`：這個資料夾的規則（唯讀的資料夾同 mod 的 §11、不動 mod 專案、回覆繁體中文、自主模式照 mod 的 §14）
   - `knowledge\INDEX.md`：主題索引（每個主題一個檔 `knowledge\topics\NN-名稱.md`：是什麼、在 REDkit 哪裡（選單、快捷鍵）、做法步驟、查證過的事實（出處：Wiki 頁面 ID、原版檔案路徑行號、實測日期）、常見問題）
   - `sources\wiki_pages.md`：官方 Wiki（Atlassian 空間 W3REDkit）的頁面清單（標題、ID、讀過沒、重點）
   - `labs\LOG.md`：每個練習（目標、步驟、結果、截圖路徑）；練習用的 REDkit 專案放 `labs\`（REDkit 的 New project 建）
2. 技能（使用者層級，`C:\Users\beyon\.claude\skills\`）
   - `redkit-expert\SKILL.md`：使用者說「你現在是 redkit 開發專家」或問 REDkit／巫師3 模組開發 → 讀 `knowledge\INDEX.md` 和相關主題，照裡面的做法、規則工作（工具：mod 專案的 `tools\desk.ps1`、`cr2w_dump.py` 等）
   - `autonomous-mode\SKILL.md`：使用者說「開啟自主模式」→ 做 mod 的 `CLAUDE.md` §14「開始時」（保持清醒、每小時續做排程、看門狗、交接檔寫「自主模式」）
3. 先把 mod 已經查證過的 REDkit 知識整理進知識庫（`CLAUDE.md` §3、§6、§12，`docs\findings.md`，`docs\m3.md`）：寫成通用的（不只 AK）
4. 讀官方 Wiki：先抓頁面清單（Confluence REST：`https://cdprojektred.atlassian.net/wiki/rest/api/content?spaceKey=W3REDkit&limit=100&start=N`，或搜尋），一頁一頁讀、記重點
5. 社群：Nexus 的 REDkit 文章、GitHub（REDkit 範例、工具）、Reddit r/witcher3mods 等（WebSearch）；只記有來源的
6. 實際操作 REDkit（練習專案，**不開 mod 的專案做實驗**）：世界和圖層、放實體、物品＋DLC、任務（quest）、對話（scene）、NPC 生成（community、encounter）、日誌、字串、動畫圖編輯器、材質、環境、Script Studio 除錯（中斷點）、遊戲裡 F8／F9 的除錯視窗、Publish
   - 每個練習：照 Wiki 做 → 截圖驗證 → 寫進主題檔＋`labs\LOG.md`
   - 切換專案前：mod 的 REDkit 要先存好（AnimBrowser 沒有未存的變更）；練完切回 mod 的專案（使用者回來時 REDkit 開著 mod 的專案最方便）
7. 一直做到使用者回來；每完成一個主題 commit；context 到 45% 照 §14 壓縮

**接續的步驟**（11:3x）
- **訓練的進度、決定、接續的步驟都改寫在 `D:\OneDrive\Desktop\redkit_expert\docs\handoff.md`** → 壓縮後先讀那份（這裡只留指標，免得 mod 的交接檔塞滿訓練的東西）
- B-1 ✓（`ec318b3`）、B-2 ✓（02:4x：技能 `redkit-expert`、`autonomous-mode` 在 `C:\Users\beyon\.claude\skills\`，技能清單已出現）
- B-3 ✓（02:4x）；B-4 ✓（03:2x：官方 Wiki 85 頁都讀完，21 個主題都有內容）；B-5 社群、B-6 實際操作 REDkit 進行中（05:3x：L3 練習專案 `labs\lab01`：XML on_conflict、Journal Editor、新世界＋地形、新世界 ID、日誌在遊戲裡出現、遭遇（要先產生 navigation data）、NPC 模板、地形材質、編輯器放實體、L4a DLC 任務、L4b 場景、L4c NPC 對話、L4d 場景的選項、L4e Interaction dialog、L4f Script Studio 除錯、L4g annotation 的除錯、L4h 場景的動畫事件、L4i Behavior Editor（遊戲中的 Behavior Debugger）、L4j 打包 lab01 都做完（打包的發現寫進 `CLAUDE.md` §6.3、`docs\findings.md` §27：`.w2je` 讓打包失敗、`succesfullyCooked` 抄打包前的值）、L4k 植被、L4l 環境和天氣、L4m 水、L4n 點光源、L4o 粒子系統、L4p 曳光（自己的投射物＋MotionBlur 粒子；400 m/s 一發約 3 公尺的細亮線：M5 曳光可以照這個做，做法在訓練資料夾 `knowledge\topics\18-environment.md`「曳光」）、L4q 生成就自己播的特效（`autoPlayEffectName`）、L4r 鏡頭震動（腳本 `GCameraShake`：lvl1 約 0.4°、lvl3 約 3°；M5 開槍的震動可以參考）都做完、L4s 燈光閃爍做一半（粒子的發現補進 `docs\findings.md` §28：Particle Editor 的預覽看得到粒子）；發現寫進 `CLAUDE.md` §12：Script Studio 的 F7 不要用、mod 腳本的中斷點不會停、`@wrapMethod` 改在被包的原版方法下中斷點）
- 10-19 03:25 練習時（在這個 mod 專案只開工具視窗看）：關 Journal Editor 時 REDkit 自動在 `workspace\` 根目錄寫了 `.w2je`（空的日誌資源）→ 已搬到 `D:\OneDrive\Desktop\redkit_expert\labs\artifacts\`；檔案快照比對：mod 專案回到原狀
- **下一步看 `D:\OneDrive\Desktop\redkit_expert\docs\handoff.md` 的「接續的步驟」**
- **REDkit 現在開著練習專案 lab01、世界 labworld**（`D:\OneDrive\Desktop\redkit_expert\labs\lab01`；03:45 換過去，換之前 mod 專案的快照 31 個檔、換之後比對沒有變）
  - 練完會切回 mod 專案；使用者回來時如果還在 lab01：File → Restart...（File 選單第 13 項左右）→ Recent projects 點 gunforgeralt 那一列的**空白處**（點名稱文字沒反應）→ File 選單最近的世界開 reference_level
  - mod 的 git 乾淨（只有 `gunforgeralt.w3edit` 照例不 commit）
- `tools\desk.ps1` 10-19 加了 `pause` 鍵（Pause Break，用虛擬鍵碼送）：REDkit 開的遊戲裡沒效果；遊戲中要點 REDkit 選單 → 叫出另一個 REDkit 視窗（遊戲會暫停、滑鼠放開）
- 流程圖：https://claude.ai/artifact/DXfFwfWpFmxteVoZKkFA4Z（最後的回覆要給使用者）

**8 項之後的收尾（02:2x 做完）**
- 收尾測試發現：按 R 換完彈後跑步變回原版十字弩的拿法 → 修好（`docs\findings.md` §36.2「修正」；commit `d96b4b8`）
- `gfg_debug.ws` 移到 `backup\`（不進 git、不被遊戲載入；舊的 `gfg_debug_2026-10-19.ws`、這次的 `gfg_debug_gfgbv_2026-10-19.ws`）
- `tools\overlay_patch.py`、`gameplay_patch.py`：不加 `--override` 就不寫原版的覆蓋路徑
- `CLAUDE.md` §4、§6.16、§12 更新
- REDkit 還開著 mod 的專案、遊戲已 F10 結束（reference_level 開著）

---

## 自主模式（2026-10-18 22:3x 開始；使用者：「自主模式開始，從上次暫停的地方繼續。然後，我剛剛實際遊玩後有發現幾個需要改善的部分，你再加入代辦清單中」）

- 背景：保持清醒 `b0uy1btvh`、看門狗 `b9v28vbgt`、每小時續做排程 `0ad00fc5`（第 13 分）
- 使用者在 Steam 版玩過 0.3 版 → mod 在 Steam 版能載入、能玩（回報的都是手感、動作問題）

| # | 任務（使用者的描述） | 狀態 |
|---|---|---|
| 24 | 物品欄預覽的握槍方式（左手拿、槍口朝下） | **完成**（10-18 23:1x 遊戲驗證：下面「#24 結果」） |
| 28 | 物品欄子彈圖示：一顆子彈、不要死死的垂直 | **完成**（02:0x 遊戲驗證：`docs\findings.md` §35.5） |
| 29 | 戰鬥時要能翻滾、閃避（和持劍時一樣的戰鬥動作） | **完成**（10-19 00:3x 遊戲驗證：`docs\findings.md` §36.4） |
| 30 | 沒進戰鬥、按 A／D 往左右跑（走）時上半身太挺、很滑稽 → 參考持劍未戰鬥時的左右走跑，做成持槍衝鋒的姿勢 | **完成**（01:4x 遊戲驗證：`docs\m3.md`「沒開槍時走跑：持槍衝鋒的姿勢」） |
| 31 | 持槍時按滑鼠中鍵（滾輪）會照十字弩單發射出 → 改成沒有行為；**十字弩的原有行為一律不動，只改 AK** | **完成**（00:0x；§36.1） |
| 32 | 右下角的操作提示（現在是衝刺、跳躍、專注）加「C 收槍」 | **完成**（00:1x；§36.3） |
| 33 | 主動換彈：Claude 選一個適合的鍵；也加進右下角提示 | **完成**（R；00:0x；§36.2） |
| 34 | 換彈只有左手在動、太不明顯（玩家不知道為什麼突然停火）→ 動作明顯一點，例如右手也動；找最合適的動畫並實作 | **完成**（01:3x 遊戲驗證：`docs\m3.md`「換彈動作明顯一點」） |

**順序**：8 項、收尾都完成 → 上面「新指示」的 A、B

**決定**（理由寫在各項；已定案的寫進 `CLAUDE.md` §7）：
- #24 展示姿勢＝**低持**：槍托頂在右胸前（肩窩）、槍口往前下約 27°、略往左；左手沿護木往後 7 公分
  - 不用「斜放胸前、槍口往左上」：握法是瞄準時的握法，斜放時右手腕一定多扭 130° 左右（idle 第 0 格試了幾千組，暫存 `scratchpad\s30\inv_search*.py`）
  - 拿出／收回時甩的那段：AK 跟著原版的左手（左手握護木），再混到兩手低持
- #31：水中（游泳、潛水）、船上的中鍵照原版（潛水時中鍵是 AK 唯一的開火方式）→ 要不要也拿掉：**交給使用者決定**
- #33：R（CS2 也是 R；拿 AK 時重擊沒用；不用改按鍵設定）
- #32：Flash 只有 5 格 → 探索時「叫馬」排最後、有空格才列；戰鬥時照原版的位置換成射擊、換彈、閃躲、法印、收槍
- #29：閃躲時 AK 留在手上（不收槍）；翻完馬上能射
- #30：跑步前傾 16°、槍口朝前下 24°；走路前傾 8°（槍口 16°）；走跑瞄準差值沒重算（沒開槍移動時上半身不跟鏡頭）
- #28：一顆、往右斜 25°（同原版魚叉箭的方向）、淡淡的暗影
- #34：原版沒有槍的換彈動畫可借 → 自己的關鍵格：上半身右轉、槍移到身體右前方、槍口上翹；最後右手拉槍機（手肘抬高）；從背後的鏡頭看得到

**現在在做**：上面「新指示」的 B（REDkit 專家訓練）

**#24 結果**（23:1x，reference_level 遊戲裡驗證）
- 動畫：`tools\inv_pose.py` → `assets\anims\gfg\gfg_akinv_*.re` 5 段（不進 git；重做：`"D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/inv_pose.py`）→ 匯入我們的動畫組（89 段＝原本 84＋5；原本 84 段的資料、事件一個 byte 都沒變：`scratchpad\s31\cmp_anims.py` 比對 HEAD）
  - 物品事件照原版（`scratchpad\s31\entry_events.py` 解析原版動畫組）：拿出 1.58054 秒 `CExtAnimItemEvent`（crossbow、`IA_MountToLeftHand`、`GI_ByName`）；收回 2.00114 秒（crossbow、`IA_Mount` 預設值）
  - AnimBrowser 加物品事件：時間軸右鍵 → **Items → Add item event** → 雙擊事件 → category 按右邊的小按鈕開 Inventory Category 清單（打字沒用）、action 是下拉選單
- 圖：`tools\ak_graphs.py` 的 `gfg_inventory.w2beh`；腳本：`gfg_ak47.ws`「物品欄預覽人物」一節
- 遊戲裡：預覽人物生成時紀錄 `preview graph AK true`；物品欄裝 AK → 背後拿出、兩手低持在胸前（右手握把、左手護木、槍口朝前下）、翻看、約 10 秒收回 → 空手（原版十字弩也是：收起來的弩在預覽裡不顯示）
- 裝原版十字弩 → 紀錄 `preview graph AK false`、原版的左手展示（截圖比對過）
- 外觀選單（`CR4TransmogMenu`）：包了同樣兩個函式，沒進遊戲測（要找得到外觀選單的地方）
- 拿出、收回途中槍托掃過身體中線（拿出 2.2 秒、收回 0.3 秒附近）：連拍看不出穿模，先不處理
- **誤判紀錄**：AK 拿在手上、從預設鏡頭（背後偏左）看不到槍 → 以為槍不見了，查了 20 分鐘；其實是正常的側身持槍（左肩朝前）被身體擋住（下午白果園的截圖也一樣）；確認槍在不在：中鍵瞄準（鏡頭拉近）或 `gfgakstate()`（暫時的指令，`gfg_debug.ws`：held、掛在哪、實體位置）

---

## 打包、裝進遊戲（2026-10-18 20:2x～21:1x，完成；使用者：「將目前的開發打包一下，我要在遊戲試玩一下」）

- **使用者正在 Steam 版試玩**（第一次在 Steam 版跑我們的 mod）→ 等回報
- 版本 0.3（紀錄 `logs\publish 2026-10-18 21-09-47.log`；`info.json` 的 `succesfullyCooked` 是 true）
- 裝在 `<W3_GAME_DIR>\mods\modgunforgeralt`、`<W3_GAME_DIR>\dlc\gunforgeralt`（使用者同意 Claude 複製；`diff -rq` 和 `packed\` 一致）
  - 原本兩個資料夾都不存在；`Documents\The Witcher 3\mods.settings` 是空檔（沒有載入順序設定）
- 槍聲：`tools\sound_cache.py` 包進 `mods\modgunforgeralt\content\soundspc.cache`（校驗碼相符）；`gfg_ak47.bnk` 打包時移出 workspace，之後放回了
- 存檔備份：專案 `backup\gamesaves_2026-10-18\`（17 MB、73 個檔，`diff` 一致；`.gitignore` 加 `/backup/`）
- 遊戲是中文介面（`dx12user.settings`：`TextLanguage=ZH`）；主控台已開（`general.ini` `DBGConsoleOn=true`）
- AK 名稱補中文：字串 10000001 加 ZH 'AK-47'（字串庫＋CSV；`scratchpad\s28\add_zh_ak_name.py`）
  - `zh.w3strings` 只放有中文的字串，不拿英文代替（補之前 3 個 key、補之後 4 個）→ 沒補的話 AK 在中文遊戲裡沒有名字
- `gfg_debug.ws`：打包時移出 workspace（不包進去），打包完放回
- **Publish 當掉的解法**：REDkit 開好專案就打包 → 7 次都在 DLC 那一輪 cook `test.reddlc` 時當掉；**先開世界、按 play game 進一次遊戲、F10 結束，再打包 → 過了**（21:03、21:09 兩次）
  - 寫進 `docs\findings.md` §27
  - 故障回報視窗：`desk.ps1` 點不到（不在允許名單）→ `taskkill` 關（不送出）；dump 留在 `%LOCALAPPDATA%\REDEngine\ReportQueue\Witcher3_20261018_*`（REDkit 下次開會不會自己送出：不知道）
- 打包流程：REDkit 開專案（Welcome → Browse (1238,814) → typepath → Enter）→ File (20,32) → 最近的世界 reference_level (150,245) → play game (650,86) → F10 → Publish (185,32) → Save and publish mod project (281,346) → Next (1183,932) → Start cooking (1168,360) → 關世界 Yes (1070,518)；約 1.5 分鐘；之後的 Next 是發布到工作坊：不用
- 試玩回報可能遇到的：
  - 新 DLC 第一次只登記、再開一次遊戲才掛載（REDkit 裡是這樣：`CLAUDE.md` §6.11；Steam 版沒驗證）→ `additem` 沒反應就重開遊戲
  - 和使用者裝的其他腳本 mod（MCME、SeamlessAutoLoot、MoreSkillSlots 等）一起編譯：沒驗證過

## 使用者回來時先看這裡（2026-10-18 18:1x）

使用者 18:1x：「我要用電腦了，你先整理目前進度 handoff，然後結束自主模式直到我喚起你做」
- → 自主模式**結束**（互動模式：`CLAUDE.md` §11，寫新東西前先問）
- 背景程序都停了：保持清醒、看門狗、每小時續做排程
- 使用者說回來時要「喚起」才接著做

**這一輪的進度**（使用者 10-18 15:0x 回報的 4 項，加上 18:1x 新提的 1 項）

| # | 問題 | 狀態 |
|---|---|---|
| 24 | 物品欄預覽的握槍方式有誤（左手拿、槍口朝下） | **做到一半**：第 1 步做完、第 2 步的分析做完 → 下面「#24 接續」 |
| 25 | 原版十字弩的姿態要維持原樣 | 完成（`docs\findings.md` §34.1、34.2） |
| 26 | 槍到手上才開槍 | 完成（§34.3） |
| 27 | 子彈的樣子（物品欄、射出去的） | 完成（§35） |
| 28 | **新**（使用者 18:1x）：物品欄裝備子彈時，圖示是 3 顆子彈垂直排，「很醜沒質感」→ **一顆子彈就夠，不要死死的垂直呈現** | 只記錄，還沒做 |

**#28 的資料**（還沒動）
- 圖示檔：`workspace\dlc\gunforgeralt\data\gameplay\gui_new\icons\inventory\weapons\gfg_ak47_ammo_64x128.png`
  - 兩個子彈物品（一般、水中）共用：物品 XML 的 `icon_path`
- 做圖的工具：`tools\ammo_build.py`
  - 現在是 `--count 3`（並排直立、尖朝上）、`--pitch 8`
  - 改法：`--count 1`，再加一個斜放的角度參數（工具現在沒有）
- 圖檔同名覆蓋後要不要重開 REDkit：沒驗證過（`CLAUDE.md` §6.19 只說新建的圖檔要重開）

**#24 接續**（做法的 6 步在下面「#24 的做法」；第 1 步做完）
- 第 2 步的分析（18:0x；讀 5 段 .re 做 FK，`scratchpad\s28\inv_analyze.py`）：
  - 格數：unsheathe 143 格 4.733 秒、idle 151 格 5.0 秒、check1 167 格 5.533 秒、to_noequipment 49 格 1.6 秒、sheathe 155 格 5.133 秒
  - 5 段都是全身 94 根骨頭
  - 人在模型座標裡朝右前轉約 30°：左手在前、右手在後
  - unsheathe 的動作：
    - 0～1.5 秒：左手往後上伸，拿背上的十字弩
    - 2.0～2.5 秒：甩到前面
    - 3 秒以後：左手停在 (−0.40, +0.26, 1.13) 拿著展示
  - idle、check1、to_noequipment、sheathe 的第 0 格都是這個展示姿勢
- **物品事件**（REDkit AnimBrowser 的時間軸看到）：
  - unsheathe 1.58054 秒：`CExtAnimItemEvent`
    - category `crossbow`、action `IA_MountToLeft…`（欄位被截斷；推測是 IA_MountToLeftHand）、itemGetting `GI_ByName`
    - ＝十字弩在這時從背上換到左手
  - sheathe 約 2.0 秒：有一個事件圖示（沒打開看；推測是放回背上）
  - idle、check1、to_noequipment：縮圖上沒看到事件（圖太小，要放大確認）
  - → **AK 版也要有一樣的物品事件**，不然 AK 不會到手上、不會回背上
- 加物品事件的辦法（還沒試）：
  1. 時間軸右鍵選單找 item event 類：之前只用過 Add simple event／Add duration event
  2. 原版那筆 Copy animation → 我們的動畫組 Paste → Rename → 同名 Import 換動畫資料（那一筆的事件會留著）
     - ⚠️ `CLAUDE.md` §6.11 記過：複製原版那筆再同名匯入，遊戲裡每格報 `fully streamable` 錯誤；改名後會不會也這樣，要測
- 第 5 步要多包一個：`transmogMenu.ws:285-318` 也有一份 `PlayPaperdollAnimation`（5.x 的外觀選單），同樣送 `DrawCrossbow_Inv`
- AK 版的姿勢（第 2 步）：拿的時間點照原版事件；拿到之後兩手握槍、低持在胸前

**REDkit 的狀態**（21:1x）
- REDkit 關著（打包完 Claude 關掉的）；要接著做 #24 時重開，AnimBrowser 再開原版的 `geralt_inventory_gui_animation.w2anims`
- 平常用的世界：White Orchard（`levels\prolog_village\prolog_village.w2w`）

**要使用者決定的**
- 中鍵瞄準時短按左鍵沒開火、放開中鍵照原版射一發（`docs\findings.md` §35.2）：不在這次範圍，要不要改由使用者決定
- 下面「上一次自主模式結束時的交接」的「要使用者決定或操作的」還是有效（裝進 Steam 版已做：最上面）

---

## 自主模式（2026-10-18 15:0x 開始、18:1x 結束；使用者：「開啟自主模式，開始做吧」）

使用者 10-18 回報：槍聲音量「非常適合」、第 20～23 項都達成；接著要修的 4 個細節（截圖在 session 暫存 `images\2.png`～`5.png`）：

| # | 問題（使用者的描述） | 狀態 |
|---|---|---|
| 24 | 物品欄打開時，預覽人物握槍的方式有誤（截圖 2：AK 掛在左手、槍口朝下） | 做到一半（上面「#24 接續」） |
| 25 | 原版十字弩的所有姿態要維持原樣，AK 的改動不能影響十字弩（截圖 3、4：十字弩變成雙手拿，原本單手；截圖 5：拿十字弩時腰扭得很怪） | **完成**（遊戲驗證；`docs\findings.md` §34.1、34.2） |
| 26 | 按左鍵時槍還在背上（還沒拿好）就擊發 → 槍到手上才可以開槍 | **完成**（遊戲驗證；§34.3） |
| 27 | 子彈還是箭（物品欄看到的）→ 改成子彈：物品欄、射出去的樣子；原版的箭不受影響；其他會用到這子彈的地方也要做 | **完成**（遊戲驗證；`docs\findings.md` §35） |

**背景程序**：18:1x 都停了（保持清醒 bti6jlddx、看門狗 bfqd3uv04、續做排程 a5f72a93）

**停下時在做**：#24（物品欄預覽的握槍）第 2 步：上面「#24 接續」、下面「#24 查到的」「#24 的做法」

**#27 做完的重點**（17:5x；細節 `docs\findings.md` §35）
- 物品欄：子彈格圖示 3 顆子彈、提示框「7.62X39MM／AMMUNITION」（新字串 10000010 `gfg_item_category_ammo`：EN Ammunition、ZH 彈藥）、選取子彈格沒有「卸下」
- 開火時左下角道具格「7.62x39mm」；連射照常
- 射出去的：模型是彈頭（飛行中顯示、碰到東西藏起來）；原尺寸太小、太快，正常玩看不到（真的子彈也看不到）→ 用暫時指令放大 10 倍拍到一排彈頭
- 換武器：物品欄、主控台把 AK 換成原版十字弩 → Bodkin Bolt（原版圖示）；換回 AK → 子彈；裝著 AK 時裝箭被擋（You cannot do that now.）；輪盤 AK 那格沒有「Change Bolt」，原版十字弩那格有
- 水中：游泳時換成水中用的子彈；潛水時中鍵（原版的水中射擊）射出去的也是彈頭；上岸換回
- 暫時的測試行（`GfgBulletSpeed` 的 TEMP）已拿掉；`gfg_debug.ws` 多了 `gfgbulletwatch(秒, 放大)`、`gfgbulletview(距離)`（收尾時整個檔刪掉）
- 順便看到、沒處理（不是這次的範圍，給使用者決定）：中鍵瞄準時短按左鍵沒開火、放開中鍵照原版射一發（§35.2）

**收尾要做**（10-19 02:2x 都做完了）：
- 刪 `workspace\scripts\local\gfg_debug.ws`（暫時的測試指令：`gfgstack`、`gfggraphs`、`gfgdrawlog(秒)` 等；沒進 git）
- `tools\overlay_patch.py`、`gameplay_patch.py` 直接跑會寫到原版的覆蓋路徑（`workspace\gameplay\behaviors\pc\behaviorgraph\`）→ 改成擋掉或只給 `ak_graphs.py` 用
- `CLAUDE.md`：§4 加 `workspace\dlc\gunforgeralt\data\behaviors\`（`ak_graphs.py` 產生、不進 git）；§6 加「slot 換圖」「動畫用 gfg_ 名稱、匯入檔名 gfg_*.re」；§6.16 的「本專案改過的」改成複本；§12 加 F10、`xy()`

### #25、#26 做完的重點（細節在 findings §34）

- #25：`tools\ak_graphs.py` 產生 4 張 AK 專用圖（`workspace\dlc\gunforgeralt\data\behaviors\gfg_*.w2beh`，不進 git；重做：`python -X utf8 tools/ak_graphs.py`）；動畫組 84 段改名 `gfg_`；腳本每 0.1 秒檢查裝的是不是 AK，換 slot 的圖、重建實例（`gfg_ak47.ws` 開頭「AK 用自己的一套動畫圖」）
  - 舊的兩個覆蓋檔（直接改原版的 `pc_overlay`、`pc_gameplay`）移到 session 暫存 `scratchpad\s24\old_overrides\`
  - 腳本的包裝都檢查過：都有限定 AK（或只在 AK 開火、換彈時才有作用）
  - 之後在 REDkit 匯入動畫：**檔名要用 `gfg_*.re`**
- #26：兩手（`r_hand`–`l_weapon`）距離在 0.395～0.445 超過 0.02 秒（騎馬 0.2 秒）才開火（`GfgGripUpdate`、`GfgGripReady`）；拿掉了先前寫的「拿出後固定等 0.25 秒」
- `tools\desk.ps1 burst` 加 `mouse=left`：連拍開始時按住滑鼠鍵（看拿出到第一發）

### #24 查到的（15:2x 遊戲實測）

- 物品欄打開時預覽人物沒拿東西；**在物品欄的格子裡「裝上」十字弩類（Space）時**，`inventoryMenu.ws:2441-2442` 送 `DrawCrossbow_Inv` → 預覽的動畫圖（slot `Inventory` = `pc_inventory.w2beh`）播 `inventory_unsheathe_crossbow` → `inventory_crossbow_idle`（＋`_check1`、`_to_noequipment`、`inventory_sheathe_crossbow`）：左手拿著十字弩展示
  - 原版十字弩：左手拿著、橫在胸前（截圖 `scratchpad\desk\s24_m7.png` 左）；AK：同一個左手姿勢，模型擺法是雙手持槍的 → 槍口朝下、槍托穿過前臂（右）= 使用者截圖 2
- 預覽人物：`GeraltForUI` = `characters\player_entities\geralt\geralt_player.w2ent`（`gameplay.xml:162`），`OnGuiSceneEntitySpawned( entity )`（`inventoryMenu.ws:399-409`）拿得到實體、自己的 slot（換圖的做法同 #25）
- 打算：預覽人物也換一張改名的 `pc_inventory` 複本，5 段十字弩展示動畫換成 AK 版（雙手、自然的拿法），要自己做動畫；或其他較便宜的做法（還沒決定）
- 物品欄的預覽（X）只對衣服、染色有用，十字弩沒有
- 17:5x 再查（`cr2w_dump`）：`pc_inventory.w2beh` 用到 5 段十字弩展示動畫 `inventory_unsheathe_crossbow`、`inventory_crossbow_idle`、`inventory_crossbow_check1`、`inventory_crossbow_to_noequipment`、`inventory_sheathe_crossbow`（事件 `DrawCrossbow_Inv`、`HideCrossbow_Inv`、`RemoveCrossbow_Inv`）
  - 動畫在 `animations{B}man{B}inventory{B}geralt_inventory_gui_animation.w2anims`（26 段；dump 裡沒有動畫事件）；unsheathe 4.73 秒
  - 預覽人物的道具由 C++ 放（`CR4GuiSceneController.SetEntityItems`：`inventoryMenu.ws:3981-3996`）；`PlayPaperdollAnimation`（`:2415-2443`）只送事件
  - 物品欄裡裝上 AK（選取格子 → Space）就重現：預覽左手拿 AK、槍口朝下（截圖 `scratchpad{B}desk{B}inv14g.png`）
- **#24 的做法（17:5x 決定）**：照 #25 的換圖做法，只在裝著 AK 時換預覽人物的 `Inventory` slot
  1. REDkit AnimBrowser 開 `geralt_inventory_gui_animation.w2anims`，5 段匯出成 .re（`g.sh` 的 `export_anim`，要先改 `AB` 成 AnimBrowser 的 handle）
     - **18:00 狀態**：REDkit 17:51 重開過（主視窗 `0xD12FC`；遊戲已 F10 結束）；AnimBrowser 已經開著這個動畫組（`0x911790`，`g.sh` 的 `AB` 已改）；Asset Browser `0x91726` 停在 `animations\man\inventory`
     - `export_anim 名稱` 存到 `assets\anims\名稱.re`（存檔視窗按 Enter 用預設資料夾；先確認存檔視窗的資料夾是 `assets\anims`）
     - **第 1 步做完（18:01）**：5 段都匯出到 `assets\anims\inventory_*.re`（不進 git；unsheathe 0.93 MB、idle 0.96、check1 1.03、to_noequipment 0.54、sheathe 0.98）→ 下一步寫 `tools\inv_pose.py`
  2. 新工具 `tools{B}inv_pose.py`（Blender 內建 Python，照 `square_pose.py`、`two_hand_pose.py` 的 FK、兩節手臂 IK）：每一格保留原版的身體（腿、脊椎、頭），AK（`l_weapon`）放在胸前「低持」（槍口朝前下、斜過身體，跟著 torso3），兩手 IK 握槍（右手握把、左手護木）；格數、長度照原版 → 輸出 `gfg_akinv_*.re`（名稱：`inventory_` 換成同長度的 `gfg_akinv_`）
  3. 匯入我們的動畫組（`import_one plain`）、存檔
  4. `tools{B}ak_graphs.py` 加一張：`pc_inventory.w2beh` 複本，5 個名稱同長度改名 → `workspace{B}dlc{B}gunforgeralt{B}data{B}behaviors{B}gfg_pc_inventory.w2beh`（新檔 → 重開 REDkit）
  5. 腳本：包 `CR4InventoryMenu.PlayPaperdollAnimation`：類別 crossbow 時，依遠程武器格是不是 AK 換預覽人物（`m_player`）`Inventory` slot 的圖（`GfgSetSlotGraph` 的做法 ＋ `DetachBehavior`／`AttachBehaviorSync` 重建），再送原版的事件
  6. 遊戲驗證：物品欄裡裝 AK → 預覽兩手握槍；裝原版十字弩 → 原版的左手展示；開關物品欄、換來換去都對

### #27 查到的

- 原版的箭：`def_item_bolts.xml`（`Bodkin Bolt`：無限、`hold_template="bodkin_bolt"`；`Harpoon Bolt`：水下）；箭的模型（裝在十字弩上、射出去的）都是 `hold_template`
- 腳本已經有「子彈的樣子」（第 9 項：`gfg_ak47.ws`「子彈的樣子」一節：AK 射出的箭藏模型、拿掉軌跡）
- 原版自動裝無限箭：`W3PlayerWitcher.AddAndEquipInfiniteBolt`（`playerWitcher.ws:5679`：先刪光 Bodkin、Harpoon，再加 `GetCurrentInfiniteBoltName()` 的那種、裝到 `EES_Bolt`）
  - 呼叫的地方：裝上十字弩類且沒裝箭（`:6403-6406`；水中 `:6386-6400` 換 Harpoon）、卸下箭（`:6762-6772`：無限的刪掉、其他的補無限箭）、`r4Game.ws:1320`、`swimming.ws:137`（出水 Bodkin）、`:267`（入水 Harpoon）
  - 輪盤（`hudModuleRadialMenu.ws:1036-1130`）：十字弩格列出所有 `bolt` 類（跳過目前的無限箭），可以選特殊箭
  - 其他用到 Bodkin 名稱的：新物品通知跳過（`r4guimanager.ws:1636`）、物品欄右鍵選單（`inventoryContext.ws:297`、`:646`）、十字弩說明的傷害數字（`guiTooltipComponent.ws:931`、`CharacterStatsPopup.ws:919`）
- CS2 有 AK 的子彈模型（16:4x 取出到 `assets\ak47\ammo\`，不進 git；CLI：`Source2Viewer-CLI.exe -i pak01_dir.vpk -f weapons/models/shared/shells/ak47/ -o assets/ak47/ammo -d --gltf_export_format gltf --gltf_export_materials --gltf_textures_adapt`）
  - `ak47_bullet.gltf` = 整顆子彈（彈殼＋彈頭；長 0.063、直徑 0.010，長軸 Z：−0.021～0.042）；`ak47_casing.gltf` = 空彈殼（Z −0.021～0.021）；貼圖 `ak47_bullet_color`、`_normal`、`_ao`、粗糙度
- **計畫**（16:4x 定）：
  1. Blender 背景模式：`ak47_bullet` → 物品圖示 PNG（64×128 直的，同箭的圖示）；只留彈頭（Z ≥ 約 0.02）→ FBX（射出去的模型）
  2. REDkit：Import > Mesh（彈頭）＋貼圖 → `gfg_ak47_bullet.w2mesh`；`bodkin_bolt.w2ent` Save as `gfg_ak47_bullet.w2ent`，模型換成彈頭
  3. 物品 XML：`gfg_ak47_ammo`（照 `Bodkin Bolt`：bolt 類、無限、NoDrop、不能賣；`hold_template` = `gfg_ak47_bullet`；圖示；名稱、說明要加字串）
  4. 腳本：`GetCurrentInfiniteBoltName` 包裝（裝 AK 時回傳 `gfg_ak47_ammo`）；`AddAndEquipInfiniteBolt` 包裝（也刪我們的子彈）；換武器時互換（AK 配 Bodkin → 換子彈；十字弩配子彈 → 換 Bodkin）；AK 時輪盤、物品欄不能選原版的箭；裝在槍上的那顆藏起來、射出去才顯示、打到東西藏起來
  5. 遊戲驗證：物品欄（子彈格、物品格）、輪盤、HUD、射出去；換回十字弩 = 原版 Bodkin

**自己做的決定**：
- #27：水中也換成子彈（另一個物品，數值照 Harpoon Bolt）；裝著 AK 時只能用子彈（輪盤不列原版的箭、物品欄不能裝箭），換回十字弩照原版
- #27：提示框類別寫「Ammunition／彈藥」；傷害數字照原版 Bodkin（4-6）不動：AK 的傷害由腳本算
- #25：AK 用自己的一套動畫圖（原版的複本＋改名），裝上 AK 時換 slot 的圖；不用在原版圖裡加切換節點（要解很多自訂資料格式，風險高）
- 舊的兩個覆蓋檔（產生的檔、不在 git）移出專案 = 刪除：使用者要求十字弩完全照原版，一定得拿掉
- #26：條件用「兩手都握在槍上」而不是「拿出後等固定時間」：衝刺停下（槍從單手換回雙手）也會在槍沒對準時開火，同一個條件一起解決；槍管角度在近距離、騎馬時會變，不當條件

---

## 上一次自主模式結束時的交接（2026-10-18 04:0x）

自主模式（10-18 00:4x 開始）四項都做完、結束了。背景程序都停了：保持清醒、看門狗、每小時續做排程。

**做完的**（都在 REDkit 裡的遊戲驗證過）

| # | 任務 | 結果 |
|---|---|---|
| 20 | 持槍的面向方向參考持劍 | 戰鬥中、附近有敵人、沒衝刺 → 一直朝著目標，用側移、後退的腳步（同持劍：戰鬥中只能走）；衝刺、野外照舊朝移動方向（`docs\findings.md` §30；commit `2aa9cdc`） |
| 21 | 物品欄、輪盤的圖示換成 AK-47 | CS2 物品欄的 AK 圖：物品欄直的、輪盤水平（§31；commit `97a3981`） |
| 22 | AK 槍聲，不走 Wwise 授權 | 自己做 SoundBank：CS2 的 3 個槍聲、每開一槍播一次、同時 1 個（同 CS2）；Claude 聽不到 → 錄電腦播的聲音驗證（§33） |
| 23 | AK 的材質顏色不明顯 | 高光太強（用了十字弩金屬部分的數值）→ 改成一般非金屬的 0.04；白天看得到木頭、機匣的顏色（§32；commit `511eaec`） |

**自己做的決定**（理由在各 findings 章節）

- #20：戰鬥中的速度從跑變側移（約 2 公尺／秒；持劍在同樣情況也只能走）；站著不動照舊（準心偏 60° 以上才轉身）：使用者只說了移動
- #21：輪盤圖的角度 −8.4°（槍管水平）；其他地方（左下角道具格等）照物品欄，直的：使用者只說輪盤
- #22：
  - 用 AK 自己的事件 `gfg_ak47_shot`，原版十字弩的聲音不動（AK 開火本來就不播十字弩的射擊動畫，所以也沒有十字弩的射擊聲）
  - 照 CS2 的 `Weapon_AK47.Single`：只用 `ak47_01`、`02`、`04`，同時只播 1 個（下一發切掉上一發的尾音）
  - 音量 −3 dB：0 dB 時峰值頂到上限（快破音）；−3 dB 比原版十字弩射擊大聲約 3 dB
- #23：用 CS2 貼圖的定義（幾乎全是非金屬）→ 整把固定 0.04；不另外做金屬零件的高光貼圖
  - 要還原舊的：`tools\mesh_material_patch.py <三個模型檔> --material weapon_rif_ak47 --set SpecularColor=130,130,130 --set RSpecScale=1.5 --set RSpecBase=-0.4`

**要使用者決定或操作的**

1. **聽一下 AK 的槍聲、音量合不合適**：Claude 只用錄音量過（頻率分布和 CS2 原檔一致、連發間隔 0.1 秒、沒破音）
   - 改音量：`tools\ak_soundbank.py … --volume <dB>` 重做 bank（`CLAUDE.md` §6 第 20 項），重開 REDkit
2. **wcc_lite 的 EULA 又跳出來了**：10-18 03:34 Claude 直接跑 `wcc_lite.exe cooksounds`（想看用法）之後
   - 沒有替你按 Agree；下次 `tools\wcc_compile.py` 會跳出 EULA 視窗 → 要你本人按
   - 這段時間 Claude 用 REDkit 的 Reload scripts 確認編譯（`Scriptables reloaded.`）
3. 裝進 Steam 版遊戲：**10-18 21:1x 裝了 0.3 版**（最上面「打包、裝進遊戲」）
   - **槍聲另外打包**：Publish 不會包 bank → `python -X utf8 tools/sound_cache.py packed/mods/modgunforgeralt/content/soundspc.cache --pack workspace/soundbanks/pc/gfg_ak47.bnk`
   - 裝了之後要驗證：拿 AK、開槍（含槍聲）、換彈、騎馬 → 使用者試玩中
4. 下面「沒做完的」哪些要做、先做哪個

**沒做完的**（已知的小問題；要做的話跟 Claude 說）

- 開槍中按 D／A 側移：腿和上半身的總扭轉還是約 47°（每次混法不一定，有時只有 0～5°）
  - 要降得換一套側移的腳步動畫（NPC 的；速度、步伐要另外對上）→ 成本高，先不做
- 換彈結束、切回瞄準的約 0.2 秒，右手會離開握把一下（騎馬量到 4～21 公分）
- 狼：正面瞄口鼻不算爆頭（口鼻離頭部骨頭 0.35 公尺）
- 曳光：沒做（原版能從槍口連到目標的特效都是魔法光束；箭的軌跡在子彈速度下看不到；想法：另外生成一個慢速、發光的曳光）
- AK 其他的聲音（換彈、拿出、遠處聽到的槍聲）：沒做，這次只要求槍聲；CS2 的檔都有（`ak47_clipout_01`、`ak47_boltpull*`、`ak47_draw`、`ak47_distant`），做法同槍聲（`CLAUDE.md` §6 第 20 項）

**現在的狀態**

- REDkit 10-18 03:05 重開過；世界 White Orchard（`levels\prolog_village\prolog_village.w2w`）；遊戲已用 F10 結束
- `gunforgeralt.w3edit` 是 REDkit 自己改的 → 照舊不 commit
- 腳本沒有測試用的主控台指令；`[GFG]` 紀錄只有兩個「找不到模板」和 `shot bank loaded`（第一次載入槍聲 bank 時）
  - 測試用的指令要再用：`gfgwolf` 照 commit e0bfb09、`gfgfree` 照 commit 33a6a45；換 bank 內容後重新載入（`SoundUnloadBank`＋`SoundLoadBank`）要另外加
- 第三方工具（都在 `tools\_vendor\`，不進 git）：`wwiser\`（bank 解析）、`pylib314\`（soundcard、numpy：錄音）、`s2v_cli\`（Source 2 Viewer 命令列版：CS2 的聲音、圖轉檔）
- `assets\ak47\sound\` 的 WAV 不進 git：重取照 `CLAUDE.md` §4

## 10-17 自主模式自己做的決定（參考）

- 第 19 項的條件：「AK 是選用物品，或 AK 拿在手上」（`GfgNoSwordMode`）；選用物品換成別的（炸彈等）照原版
  - 1／2 鍵只擋掉、沒反應：不另外改成舉 AK（使用者沒要求）
  - 戰鬥中按 C 收起 AK 會再自動舉起（同原版戰鬥中收劍會馬上再拔）
- 開槍中側移：只把扭轉分給三節脊椎（`move_pose.py --spread 0.2 0.4 0.4`）；總量要換腳步來源 → 先不做（理由見 `docs\m3.md`「雙手持槍：開槍中側移」）
  - 試過、放棄：把 `f_45r` 的下半身轉 −45°（位移變正右）→ 按 D 實際移動偏到 69～86°（動畫圖照原本的 135° 補正）
- 曳光：先跳過（01:3x 決定；理由見上面「沒做完的」）
- 清理：所有主控台指令（`gfgfree`、`gfgnoturn`、`gfgmagshow`、`gfgbullet`、`gfgdmg`、`gfgwolf`、`gfghorsehere`、`gfgshots`、`gfgsword`）和定時／查問題的紀錄都拿掉；永久保留 `carry dummy template not found`、`mag template not found` 兩個錯誤紀錄
  - 要再用的話：從 git 找回（例：commit e0bfb09 的 `gfg_ak47.ws` 還有 `gfgnoturn`、`gfgfree`）
- 打包的版本號改成 0.2（第一次打包是 0.1）

## 第二批問題（使用者 2026-10-16 20:4x 回報、同時「恢復自主模式」）

使用者 20:2x～20:4x 自己玩了一下。截圖在 `C:\Users\beyon\AppData\Local\Temp\claude\D--OneDrive-Desktop-gunforgeralt\39998eff-46be-449b-9abb-ed90f487652c\images\10.png`～`16.png`（session 暫存）。

| # | 問題（使用者的描述） | 狀態 |
|---|---|---|
| 11 | 打不中（「你說打不中是個大問題」）：d8a67b8 之後子彈常穿過人 | **修好主要部分**（21:3x）：① 角色對射線、子彈都沒有可靠的碰撞（`RayCastSync` 只回傳地面和牆；`AtBone` 打頭、胸口會碰撞，打腳、小腿、骨盆會穿過去）→ 自己判斷：準心射線離角色最近的骨頭（`FindNearestBoneToEdgeWS`）在身體半徑內就算打中（人類 0.25 公尺、大型怪物跟著碰撞膠囊放大：troll 0.71），發射後立刻手動觸發原版的碰撞（`GfgManualHit`：傷害、聲音、子彈刪掉都走原版）；爆頭＝射線離頭部骨頭（`GetHeadBoneIndex`）0.17 公尺內 → 人類從腳掃到頭每發都判斷正確、爆頭 1365／1692（暴擊）；troll 打中 2 發；② 戰鬥鏡頭每格把上下角度拉回 −12°（`combat.ws:571-595`）→ 瞄頭後 1 秒內掉到腳邊（也是打不中的原因）→ 拿著 AK、沒硬鎖定時每格把目標角度設成現在的角度（同騎馬）：相隔 1.5 秒的截圖完全一樣。狼（21:4x，不動的狼）：瞄頭 → 爆頭（離頭部骨頭 0.10）、瞄口鼻 → 打中身體（0.12）；之前真狼有幾發 0.29～0.55 沒中，推測是鏡頭往下飄（已修）。可再改進：狼的口鼻離頭部骨頭 0.35 公尺，正面瞄口鼻不算爆頭 |
| 12 | 持槍衝刺開始和結束時，有槍的影像殘留 | **做好**（21:5x；22:0x 背對牆從側面每 30 毫秒連拍 `su3`～`su13`：衝刺開始只有一把槍從瞄準轉到提槍，沒有半透明殘影；結束是同一個切換）：原因＝真的 AK、替身用模型元件 `SetVisible` 切換時會淡出淡入 → 衝刺開始後約 0.1 秒，原本瞄準位置的空中有一把半透明的槍（21:4x 每 35 毫秒連拍 `sp8`～`sp10` 看到）→ 改成整個實體 `SetHideInGame( !visible, true )`（immediate：`entity.ws:241`；`GfgSetMeshVisible`）。改後衝刺中的連拍沒看到殘影，但轉換那一刻還沒拍清楚（背景是發光的大字、或貼著牆） |
| 13 | 按 A／D 左右跑的姿勢超滑稽，腰扭過多（截圖 10：腿往側面跑、上半身轉 90° 朝前瞄準） | **沒開槍的走跑做好**（22:3x）：截圖 10 是沒開槍往右跑（角色轉向移動方向、鏡頭從左側看），和第 14 項同一個原因、同一個修法（見下一列）；側面連拍 `rs1`～`rs4`：兩手握槍、上半身接近正面。**開槍中側移另外處理中**（接續步驟 0） |
| 14 | 直直走時腰扭太多；鏡頭從下往上看更明顯（截圖 11～13：腿朝前、肩膀朝右轉很多） | **做好**（22:3x）：遊戲裡量（暫時紀錄 `[GFG] twist`：兩大腿、兩肩連線的朝向）：沒開槍跑步時骨盆朝前、肩膀朝右 61°，而且 61° 全擠在 torso 一節（`move_pose.py` 只補正 torso）→ ① 新工具 `tools\square_pose.py`：走跑用的「正面持槍」底層姿勢（肩膀往左轉正 35°、頭維持看前方、槍跟著右肩、左鎖骨前推 25°、左手沿護木往後 7 公分、兩手 IK）；② `move_pose.py --spread 0.2 0.4 0.4`：補正分給三節脊椎（每節 4～8°）；③ 重做走跑 6 段＋走跑瞄準差值 8 段、匯入。遊戲裡：跑步腰扭 61° → 26°（W、D 都是），右掌心離握把 0.6～0.8 公分；背面連拍 `rd1`～`rd4`：肩膀接近正面。細節 `docs\m3.md`「雙手持槍：走跑時正面持槍」 |
| 15 | 按一下開槍，一停火就立刻放下槍；要射很多發才會一直舉著 | **改好**（21:4x）：停火後維持瞄準的時間（`GfgAimHoldTime`）0.5 → 3 秒（第三人稱射擊遊戲一般 2～3 秒）；這段時間內移動照樣全身瞄準、上半身朝準心。連拍：開一槍後往右走 2.8 秒都維持舉槍瞄準 |
| 16 | 騎馬拿出槍時，槍是反的（截圖 14） | **做好**（23:3x）：騎馬拔槍原本播十字弩的單手甩槍動畫（甩到一半槍口朝自己）→ 新工具 `tools\draw_pose.py` 做 4 段雙手版：上半身從騎乘姿勢平滑轉到正面持槍（0.45 秒，對齊原版 `RaiseWeapon`），補 5 個事件（`RaiseWeapon`、雙手的 `ReinOff`、`HandIkOff`）。慢動作連拍：槍先朝上、再往前放下成雙手持槍。收槍維持原版（連拍沒看到槍口朝自己）。細節 `docs\m3.md`「騎馬拔槍：雙手版」 |
| 17 | 騎馬換彈會變成 180° 往後看（人不可能扭成這樣），也沒有換彈動畫（截圖 15） | **180° 修好**（23:2x）：換彈的 torso 補正改用騎乘的骨盆（`move_pose.py --pelvis-from`）；走 3、Canter 6～7、Gallop 12.3 m/s 連射到換彈：腰扭 −23～−25°、連拍上半身朝前。「沒有換彈動畫」和第一批第 8 項一起做 |
| 18 | 騎馬往後射擊：上半身轉 180°、下半身不轉，不合人體工學（截圖 16；「還是沒改正」） | **做好**（23:2x）：騎馬瞄準底層換成正面持槍（瞄前方腰扭 −58° → −24°）；左右範圍限制右 60°、左 110°（腰扭最多約 85°），超出時姿勢停在邊界、不開火、準心藏起；從背後換邊時上半身經過前方轉過去（約 0.5 秒）；瞄準姿勢改成跟子彈同方向（只有 Z 鎖定時朝目標）。遊戲裡：右 50° 腰扭 −74°、左 100° +76°、右 70°／左 130°／150° 停在邊界、範圍外 0 發。細節 `docs\m3.md`「騎馬：正面持槍、瞄準範圍、換彈朝前」 |

## 第一批問題（使用者 2026-10-16 12:2x 回報）：都處理完

使用者看過雙手持槍：站立、射擊、跑跳、收槍的姿態都好。要處理的：

| # | 問題（使用者的描述） | 狀態 |
|---|---|---|
| 1 | 往後跑（鏡頭朝 Geralt 按 W）或身體轉向時，上半身轉、下半身沒轉 → 扭曲 | **做好、遊戲裡看過**（commit 2729ec3、67ce769）：原因＝電腦版把 OT_Player 換成 OT_Camera（`r4Player.ws:5238-5246`）。移動沒開槍→上半身朝前（13:00 截圖：往鏡頭跑不扭）；站著／開槍→朝準心＋身體轉向（`GfgAkTurnTick`）；開槍中移動→全身瞄準側移（`gfgFireMoving`＋`inAimThrowForOverlay`，不設的話起步卡 1.5～2 秒）＋雙手版側移動畫 6 段（13:3x 截圖：側移、後退兩手都在槍上，1.6～1.9 公尺／秒）。側移動畫沒有原版的腳步事件（腳步聲） |
| 2 | 附近有敵人（30 隻狼）時的戰鬥準備姿勢：開槍時沒變成射擊姿勢 | **做好、遊戲裡看過**（14:50）：被打中時有兩條收槍路徑：`OnHitStart`→`OnRangedForceHolster`（已擋：`gfgInHitStart`）、`InputLockFailsafe`（`rangedWeapon.ws:458-466`：受擊動作期間 combatActionType 0、全身權重 1、不能做戰鬥動作 → 當成攻擊中收槍）→ `Crossbow.OnForceHolster` 包裝：failsafe 呼叫、拿著 AK、不是真的輕／重攻擊（`IsInCombatAction_Attack`）就不收。實測關無敵被 6 隻狼咬：紀錄 `forceHolster blocked`、AK 一直在手上、沒有自動拔劍；戰鬥中開槍是舉槍射擊姿勢（特寫截圖） |
| 3 | 騎馬的姿勢完全錯 → 修好 | **做好、遊戲裡看過**（18:5x）。使用者 17:4x 回報騎馬側面瞄準腰扭（`rein1.png`）→ 左右轉改成分給 torso 15%、torso2 40%、torso3 45%（`horse_pose.py` 的 `H_WEIGHTS`；骨盆不能分：覆蓋節點 #4423 只取 torso 以上）：側面 90° 時腰只轉 13.4°（原本 45°），截圖比對腰帶附近不再扭折；槍管差右 91° 0.2°、左 89° 0.9°、背後 0.4°。另外修了韁繩：同名蓋過原版 aim_cycle 時少了 `LeftReinOff` 事件 → 韁繩一直連在拿槍的雙手上 → 8 段 aim_cycle 補左右 `ReinOff`、4 段騎馬換彈補左右 `ReinOff`＋`HandIkOff`（截圖：韁繩垂在馬頸上；連射→換彈→回到瞄準正常）。細節 `docs\m3.md`「騎馬：腰扭、韁繩」。原本（17:3x）：騎馬瞄準換成雙手持槍：8 段 aim_cycle（`move_pose.py --full`）、16 段水平／垂直差值（`tools\horse_pose.py`，只轉脊椎、local）、24 段射擊／別射我（單位）、4 段換彈 `horse_*_reload_lowered`（雙手版＋事件 `OnWeaponReload` 0.7 秒、`RaiseWeapon` 1.05 秒）；拔槍、收槍照原版。驗證：停著、走、Canter、Gallop 槍管和鏡頭差 2.3° 以內；左右、背後、往上 30° 都跟得上；朝馬頭往下最多約 −20°（原版動畫圖的限制 #4315）；連射 30 發 → 換彈 1 秒 → 回到瞄準。細節 `docs\m3.md`「雙手持槍：騎馬」 |
| 4 | 上下馬流程不順：拿著 AK 要先按 C 收槍才能叫馬（X）、才出現長按 E 下馬 → 不影響功能的前提下順一點，不行就算了 | **做好、遊戲裡看過**（18:1x）：拿著 AK 時 X 叫馬、E 上馬、騎馬拿著 AK 按住 E 下馬都可以，開始上下馬時 AK 立刻收到背上（截圖：1.2 秒內坐上馬；騎馬拿著 AK 右下角有「Dismount [Hold] E」；下馬後站在地上、AK 在背上）。原因有三層：① AK 一直在瞄準狀態，`Lock()` 擋掉例外以外的所有動作（`rangedWeapon.ws:401-422`，含叫馬、上下馬），拿出時另外鎖上下馬（`:1145-1146`）→ `GfgCameraTick` 每格解開 `EIAB_CallHorse`、`EIAB_MountVehicle`、`EIAB_DismountVehicle`；② 不在戰鬥中時，互動元件看到拿著十字弩就把互動吃掉（`components.ws:139-157` `IsCrossbowHeld`）→ 包 `CInteractionComponent.OnInteraction`：上馬這一個互動在 AK 拿著、不是真的攻擊時放行；③ 戰鬥動作中把 `"MountHorse"` 列入封鎖（`interactionsManager.ws:111-114`）→ 包 `GetBlockedActions` 拿掉。上下馬開始時收槍：`MountTheVehicle`／`DismountTheVehicle` 的 `OnEnterState` 包裝（`GfgHolsterForVehicle`）。空手照原版；用 E 下馬後騎馬開輪盤正常（§24.8 的舊問題沒有再出現）。紀錄裡的 `DismountTheVehicle::OnLeaveState, 'vehicle' is still set` 斷言空手下馬也有（原版）。暫時指令 `gfghorsehere()`（reference_level 的馬跑不過來）留到最後清理 |
| 5 | 衝刺：維持不能開槍、擺手跑，但拿槍的姿勢要正確 | **做好、遊戲裡看過**（16:3x）。使用者 15:1x 更正：衝刺＝按 Shift；照原版擺手跑，但手上的槍要拿正（附圖：AK 直立在背後、槍口朝上）。做法：衝刺時手臂照原版擺；真的 AK（模型＋裝好的箭）藏起來，顯示「替身」AK（同模板自己生成，標籤 `gfg_carry_dummy`），每格帶偏移掛到左手：槍口朝前下 30°、往右 8°（相對玩家），握在彈匣前的機匣；開始 0.25 秒、結束 0.15 秒漸變；預測下一格手腕方向。為什麼要替身：物品系統把真的 AK 的動畫元件直接掛在 l_weapon，對實體 `CreateAttachment` 只動實體矩陣、畫面不變（15:4x 那版「驗證」看的是實體矩陣，其實沒效果；`docs\findings.md` §26、`CLAUDE.md` §6.18）。驗證（替身的 handle 骨頭）：槍管和目標差平均 2.3～2.6°、一直朝下 25°～38°；正常速度側面連拍：左手握機匣、槍口朝前下；衝刺跳躍、衝刺中按 C 收槍（槍回背上）、收拔後再衝刺都正常，沒有腳本錯誤 |
| 6 | 打完狼群有時解除不了鎖定 | **改了、長測沒重現**（commit 2729ec3；10-17 00:5x 長測）：原因（推論）＝拿十字弩時血條目標＝滑動目標（`r4Player.ws:6749-6753`），原版收槍時才清（`:13380-13385`）；`GfgClearDeadSlideTarget` 每格清掉死掉的。長測：`spawn('wolf', 30, 10, true)`、`spawn('wolf', 12, 5, true)` 兩輪，AK 打死 15 隻、其餘 `killall(60)`；打完 `[GFG] diag` 的 slide、target 都是 none、hard／actorLock 都 false，鏡頭轉 300 像素正好 90°（沒被鎖住）。原問題不是每次都會出現 → 使用者再遇到時回報 |
| 7 | 跳躍落地後瞬間變回持槍姿勢、不順 | **做好、遊戲裡看過**（14:42）：站立跳、衝刺跳各連拍 14～18 張（每 0.1 秒，`desk.ps1 burst`）：起跳、空中、落地、再跑，兩手一直在槍上，沒有從擺手突然跳成持槍 |
| 8 | 換彈現在完全沒有動畫 → 做一個真正的 AK-47 換彈動畫 | **A 動作做好、遊戲裡驗證過**（10-17 00:5x）：新工具 `tools\reload_pose.py`，2.4 秒：拿下彈匣 → 左腰換新的 → 裝上 → 繞到右邊拉槍機；地面 2 段、騎馬 4 段；紀錄：右手一直在握把、左手照設計走、約 2.1 秒後接著射；站著換彈時肩膀轉正 33°（槍仍朝準心）。細節 `docs\m3.md`「換彈動畫」。**B 彈匣分離（彈匣真的拿下來）做好、遊戲裡看過**（10-17 05:0x：地面、騎馬；`docs\m3.md`「換彈動畫：彈匣拿下來」） |
| 9 | 射出去的還是箭，不是子彈 → 要做 | **做好、遊戲裡看過**（19:2x）：箭的模型藏起來（只藏 `CMeshComponent`）、關掉箭的軌跡、715 公尺／秒直線；打到牆壁地面播火花（`sparks`），牆上不留箭；打狼命中正常。**曳光沒做**：原版箭的軌跡在子彈速度下看不到（細節 `docs\m3.md`「子彈、傷害」）→ 跟第 10 項槍口火光一起用 Entity Editor 做特效時再看 |
| 10 | 槍口火光、子彈速度；傷害由 Claude 設計一個符合這遊戲的 | 子彈速度 715（做好）；**傷害公式做好、遊戲裡驗證過**（20:0x）：每發 穿刺 10×等級＋20、銀 ×1.25、距離衰減 0.98^(距離/12.7)；31 級打 31 級的人類（2763.75 血）每發 384.87 → 8 發倒；銀 466.58（＝基礎×1.25＋58）。**爆頭做好**（21:3x，第 11 項一起改：射線離頭部骨頭 0.17 公尺內 ×4，人類 1365、加暴擊 1692）。推算和實測 `docs\m3.md`「子彈、傷害」。**槍口火光做好、遊戲裡看過**（10-17 01:2x）：自己的特效模板 `dlc\gunforgeralt\data\fx\gfg_muzzle_flash.w2ent`（原版刀劍火花的複本：拿掉刀劍聲、光 0.06 秒半徑 3、粒子只噴 0.1 秒），每發掛在 `l_weapon` 的槍口；連射時槍前端每發一團星狀閃光、晚上地面被照亮。細節 `docs\m3.md`「槍口火光」、REDkit 操作 `docs\findings.md` §28 |

## 測試小技巧（`desk\g.sh` 在 session 暫存資料夾，session 結束就沒了）

- `g.sh`（`source` 後用）：`game_start`＝開遊戲到拿出 AK（play、死了就復活、`setlevel(31)`＋`additem`＋`god()`、輪盤教學照紀錄按 Space、左鍵拔槍）；`reload_edit`＝REDkit 重新載入腳本；`restart_all`＝點遊戲畫面拿焦點 → F10 → 重載腳本 → 開遊戲（約 1.5 分鐘）
  - ⚠️ `game_start`、`horse_start`、`ak_select` 用 `[GFG] pose` 紀錄判斷 AK 拿出來了沒 → 這個紀錄 10-17 拿掉了，一定印「AK 沒拿出來」→ 用截圖確認
  - `side_reload2`（側面看換彈）用到已拿掉的 `gfgnoturn`、`gfgfree`
  - 視窗 handle 每次重開 REDkit 都會變：g.sh 裡的主視窗（10-18 15:3x 起 `0x9085C`）、`GAB`（AnimBrowser，現在沒開）要跟著換
- **10-18 新加（g.sh 最後面）**：`game_start2`（play → 等 `INPUT CONTEXT CHANGED` → 死了就復活 → 等級、無敵、中午、拿 AK；舊的 `game_start` 等的字串已經不對）、`reload_edit2`（F10 結束遊戲 → Tools → Debuggers → Reload scripts；遊戲中選單點不到）、`radial_select`（輪盤選弓弩格、不拔出）、`cb_aim 檔名 秒數`（中鍵瞄準截圖）
  - 空地：`con "xy(100, -40)"`（White Orchard 村外）；接著 `radial_select` 選 AK
  - 量拿出：`con "gfgdrawlog(秒)"`（`gfg_debug.ws`：每格印狀態、槍管夾角、兩手距離 d、發數 sh、衝刺 spr、握好多久 grip）＋ `desk.ps1 burst 前綴 張數 間隔 … mouse=left`
- 騎馬：`game_start` 之後 `horse_start`（白天、C 收槍、X 叫馬、`instantMount('playerHorse')`、左鍵拿出）
- 動畫組操作：`import_one plain|local 檔名`、`add_ev 篩選字 事件 秒`、`add_dur 篩選字 事件 起點 長度`、`rm_anim 完整名稱`、`save_gab`（座標和注意事項寫在 g.sh 的註解；AnimBrowser 右鍵選單跟著選取中的項目）
- 開遊戲前先把編輯器鏡頭移到地面（滑鼠指地面按 J）：10-17 00:40 從高處摔死、死亡選單選錯 → 遊戲直接結束
- 教學提示（升級的 Ability Point 等）會吃掉主控台指令 → 先 `closeTutorialPopup()`
- **F10 會結束遊戲**（不是切換）：改了腳本 → F10 → `reload_edit` → `game_start`；遊戲中用選單熱重載沒反應
- **REDkit 開久了，空手按 E 也上不了馬**（10-16 18:0x：互動輸入完全沒進腳本）→ 重開 REDkit 就好（使用者：「如果已經沒拿槍，就是之前遇到的問題又出現了，看你要修還是直接關掉 redkit 重開」）
  - 判斷順序：拿著 AK 不能上下馬＝第 4 項本身（已修好）；空手也不行＝環境問題 → 重開
- `additem` 前要先 `setlevel(31)`（沒設等級時主控台顯示 `Invalid Item ID: 0`、輪盤沒有 AK）
- 主控台指令曾打進 REDkit 右邊 Scene 的搜尋框（焦點在那裡）→ 編輯模式下點一下畫面空白處（天空）把焦點移走
- 點遊戲畫面＝左鍵＝AK 的扳機：AK 是選用物品時一點就拿出 AK（`docs\findings.md` §29）
- 原版十字弩的行為：換彈後不在戰鬥、沒瞄準 → 延遲後自動收起（`rangedWeapon.ws:146-157`）；測試時 AK 會被收起來，點一下畫面再拿出
- 原地跳旁邊有高台會變成攀爬（攀爬照原版收槍）→ 到空曠處測
- 連拍：`desk.ps1 burst <前綴> <張數> <間隔毫秒> rect=… hold=w,shift pre=1500 key=space`
  - **前綴寫完整路徑 `"$P/名稱"`**，不然存到專案資料夾；前綴不要和其他截圖同名（會被 `前綴1.png`… 蓋掉）
- **慢動作**：遊戲中按數字鍵盤減號（`d key numminus`）3 次 = 0.125 倍，`numplus` 3 次回到 1 倍；**F10 重開遊戲後不會重設**（右上角紅字 Time scale）
- 遊戲裡改白天：`settime(1, 12)`（`gameTime.ws:182`；重開遊戲會變回深夜）
- 看衝刺側面：按住 A＋Shift 往左跑（鏡頭直接看到左側）；連拍用工具內建的 `hold=a,shift pre=1500 [key=space|c]`（desk.ps1 每次呼叫要 0.3～0.5 秒，分開下指令時間會對不準）
- 側面拍左手：衝刺中 `d rmove -150 0 6 15`～`-250` 轉鏡頭（鏡頭在右後方時左手的槍被身體擋住：看起來「槍不見」不一定真的不見）

## 操作備忘（Claude 自己操作 REDkit、遊戲時用；2026-10-16 實測）

- `tools\desk.ps1`（用法在檔頭）：被擋住的視窗也截得到（`wshot <視窗> out.png mode=print grid=50`）；要點的話先 `focus`；只對 editor／witcher3／blender 送輸入
- REDkit 主視窗：`proc:editor`；直接開 `<REDKIT_DIR>\bin\x64_RedKit\editor.exe`（工作目錄同資料夾，沒有參數）
- 重開 REDkit：`close` 主視窗 → 問「Modified file found」照情況答 → 程序常卡在關閉（CPU 空轉、紀錄不再寫）→ 截圖確認後 `taskkill //PID … //F` → `Start-Process editor.exe` → Welcome 視窗按「Open existing project」的 Browse（約 (1236, 814)）→ 檔名框輸入 `D:\OneDrive\Desktop\gunforgeralt\gunforgeralt.w3edit` → Enter → File 選單的最近世界 `engine\reference_level\world\reference_level.w2w`（約 (180, 245)）
- 主視窗最大化時工具列：`play game` (650, 86)、`Fast` (682, 86)、`load a saved game` (713, 86)；Asset Browser（Ctrl+A，只按一次、等 5～6 秒）會跑到螢幕外 → `place "Asset Browser" 300 80 1300 900`
- 遊戲裡：
  - `play game`：Geralt 出生在 0,0,0 會死 → 死亡選單：先 `move 250 900`、`click 250 900` 拿回焦點，再 down ×3 → enter（DEBUG RESURRECT）
  - 主控台：`key oem3` 開、**用 `keys` 輸入**、`key enter`；再 `key oem3` 關
  - 拿 AK：**先 `setlevel(31)`** 再 `additem('gfg_ak47', 1, true)`；`god()`
  - 選 AK：`keydown tab` → 第一次有兩頁教學（Space 兩次；沒教學時不要按 Space，會變冥想）→ `rmove 0 300 10 15` → `keyup tab`
  - 左鍵開槍：`click 860 555`；按鍵前先點一下遊戲畫面（不然方向鍵會送到 REDkit 右邊的場景面板，跳「Changing layer preset」→ 按 No (1112, 526)）
  - 走路切換是 Alt：在 REDkit 裡會叫出選單列 → 按 Alt 後 Esc（遊戲暫停選單）→ Enter（RESUME）
  - **不要按 F1**（自由鏡頭）；**F10 結束遊戲**回編輯器；F8／F9 除錯選單在遊戲中點不到
  - 截圖間隔接近跑步循環時看不出腿在動 → 用偵測紀錄的腳位置判斷
- 改動畫的流程：REDkit AnimBrowser 動畫右鍵 Export animation（存 `assets\anims\`）→ `tools\re_blender.py`、`tools\move_pose.py` 等改 → AnimBrowser 動畫組那一行右鍵 **Import simple/plain animations**（(1126, 266)；Open files 檔名框 (570, 553)）→ 問 override 按 **Overide** → Ctrl+S
  - 瞄準差值 `aimpose_*`：**Import additive animations II (Ref)**
  - 動畫事件：時間軸右鍵 Add simple event／Add duration event → 雙擊事件 → 右邊改值 → Ctrl+S（`CLAUDE.md` §6.11）
  - 我們的動畫組在 Asset Browser 的 animations 分頁 (579, 263)；原版 `man_geralt_gabriel` 在 combat 分頁 (690, 230)；AnimBrowser 動畫組那一行 y=187；Export 的 Save file 檔名框 (644, 477)
- Bash 的 heredoc 裡 `\\` 會變成 `\`（16:4x 交接檔被寫進 BEL、換頁字元）→ Python 字串裡的反斜線用 `chr(92)`
- 沒有 numpy 的系統 Python 跑不了分析腳本 → 用 Blender 內建的 Python（`D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe -I`）
- 遊戲裡的參考值（平視站著）：`r_hand` (0.205, 0.133, 1.366)、`l_weapon` (0.148, 0.555, 1.353)（玩家座標）

## 雙手持槍（2026-10-15～16 做完；細節在 `docs\m3.md`「雙手持槍：第 1 步」到「雙手持槍：直線走路、跑步的右手」）

- 站著瞄準（上下左右跟準心）、連射、換彈（手在槍上、換完接著射）、收槍掛背上、直線和轉彎的走路、跑步都在遊戲裡量過
- 動畫組 `gfg_ak47_geralt.w2anims` 22 段（同名蓋過原版十字弩的動畫）；改過的原版動畫圖：`pc_overlay.w2beh`（`tools\overlay_patch.py`）、`pc_gameplay.w2beh`（`tools\gameplay_patch.py`）
- 工具：`tools\two_hand_pose.py`（第 1 步姿勢）、`tools\aim_delta.py`（瞄準差值）、`tools\move_pose.py`（走跑）、`tools\pose_check.py`（偵測紀錄分析）
- 偵測紀錄（`GfgLogHoldPose` 等）10-17 都拿掉了；要量的時候再暫時加（讀法見下一節）

### 偵測紀錄的讀法、用遊戲數據算擺法

- `[Script_GFG] pose <名稱> pos x y z w x … y … z …`（世界座標的位置和三個軸）；點換到某個骨頭座標 = 先減掉骨頭位置，再和那個骨頭的三個軸分別做內積
- 右手掌心 = `r_hand` 位置 + 0.061·x 軸 + 0.032·y 軸 − 0.002·z 軸
- 用遊戲裡的數據算擺法時：直接在 `handle` 座標算（偵測紀錄的矩陣），再用 `.w2mesh` 的綁定矩陣反算成 `--place`（工具會再乘回綁定矩陣，所以 `handle` 座標會對）
- 現在的狀態：REDkit 裡的 `gfg_ak47.w2mesh`、`gfg_ak47.w2ent` 的 `bolt` slot 都是第 1 步的擺法（已 commit；`docs\m3.md`「雙手持槍：第 1 步」）

### Calc bone 的步驟（2026-10-15 實測可用：輸入框兩格；開動畫組時按 No 也能算）

- 雙擊 `dlc\gunforgeralt\data\animations\gfg_ak47_geralt.w2anims` → 問預覽角色按 **No** → **All animations** → 動畫右鍵 → **Calc bone MS** → 骨頭名稱、時間 → 結果框按 OK
- 結果同時寫進 `editor.log`（`Bone MS - '骨頭' - time - '時間'`、`   >Position:`、`   >Rotation:`）；角度是 (Pitch, Yaw, Roll)、矩陣 = Rz(Yaw)·Rx(Pitch)·Ry(Roll)（`CLAUDE.md` §6.15）
- 做完**先不要重開 REDkit** → 跟 Claude 說，Claude 讀紀錄

### 跟使用者溝通（2026-10-15 學到的）

- 使用者有軟體工程背景，但不熟 REDkit、3D 模型、Blender，**想學**：解釋時用白話，可以用軟體工程的比喻（例：蒙皮連結像用骨頭名稱做 join、實體模板像 prefab）
- 使用者不想在 Blender 裡找視角、按快捷鍵：需要目視時，Claude 用 Blender 背景模式渲染成圖片（雙擊就能開）
- REDkit、遊戲的操作 **Claude 自己做**（2026-10-16 起，`tools\desk.ps1`）；使用者不接受「做不到」：沒有現成工具就找 Windows 內建的辦法
  - 要請使用者操作時（例：自主模式結束後），步驟寫到「點哪裡、按哪個按鈕」
- 使用者會主動截很多圖回報；Claude 用 Read 看圖時要對照描述，不要只看一張就下結論
  - 會用自由鏡頭從不同角度截（畫面角落有 `camera at position`），不同張可能是不同時間點（例：開槍中、換彈中混在一起）→ 判斷姿勢前先確認是哪個時間點
- 規則（`CLAUDE.md` §11）：自己寫任何新東西前先問；有現成的就直接用。範圍（`CLAUDE.md` §7）：只做 AK 本身

## AK 現在怎麼做出來的（重做時照這個順序）

| # | 做什麼 | 誰 | 產物 |
|---|---|---|---|
| 1 | `tools\m3_build_ak.py`（指令在 `docs\m3.md`「第 3 步」，**最後加第 1 步的 `--place 0.30323 0.01147 -0.23203 -0.80333 -0.21400 0.55576 -0.02721 0.94542 0.32472`**（`docs\m3.md`「雙手持槍：第 1 步」）；單手版是 `--pitch -20.5`） | Claude | `assets\ak47\gfg_ak47.fbx`（只有一個叫 `handle` 的模型，頂點在 `handle` 骨頭座標系）、`gfg_ak47_m3.blend`（目視用） |
| 2 | `tools\m3_textures.py`（指令在 `docs\m3.md`「第 4 步：準備好的檔案」） | Claude | `assets\ak47\gfg_ak47_d01.png`、`gfg_ak47_n01.png`（2048，法線圖的 alpha 是粗糙度） |
| 3 | REDkit 匯入貼圖：資料夾 `dlc\gunforgeralt\data\items\weapons\gfg_ak47\` 右鍵 → Import → 2D Texture；群組 `WorldDiffuse`、`NormalmapGloss` | 使用者 | `gfg_ak47_d01.xbm`、`gfg_ak47_n01.xbm` |
| 4 | REDkit 匯入模型：右鍵 → **Import → Mesh**（換模型時也用這個，蓋掉舊檔）；`importAsSkinnedMesh` = **true**、`xmlMetadataLocation` = `assets\ak47\gfg_ak47.xml`；接著的「Import mesh」選材質對話框按 **Cancel**；確認 `editor.log` 有 `HasSkinning: true (NODE 'handle')` | 使用者 | `gfg_ak47.w2mesh` |
| 4' | 匯入之後：**重開 REDkit** 再進遊戲（或 Mesh editor → Materials → 重新指定 `Diffuse`、`Normal`）；不然遊戲裡沒有顏色 | 使用者 | |
| 5 | 實體模板 `gfg_ak47.w2ent`：十字弩模板的複本，模型元件 `witcher_crossbow_lvl1` 的 `mesh` 指到 AK；slot `bolt`：骨頭 `handle`；第 1 步的值：位置 (0.067, −0.028, 0.019)、Pitch −53.4、Yaw −68.9、Roll 92.6（已 commit；單手版是 (0.435, 0, -0.031)、Roll 0／Pitch -20.4／Yaw -90） | Claude（desk.ps1） | |
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

- 都 commit 了，除了下面兩個（照舊不 commit）
- `gunforgeralt.w3edit`：只有 REDkit 自己改的 `dirtyTileCellIndices`（開過測試關卡）→ 不 commit
- REDkit 匯入的產物（不在 git）：`gfg_ak47.w2mesh` 是第 1 步的擺法（`m3_build_ak.py --place …`：`docs\m3.md`）
- `.claude\hooks\`（`context-check.sh`、`statusline.sh`）：已在 git 裡（10-13 起；`CLAUDE.md` §4）
- `.gitignore` 排除、不 commit 的：
  - `assets\ak47\` 的 `.blend`、`.fbx`、`.png`：腳本的輸出（材質 XML `gfg_ak47.xml` 有 commit）
  - `workspace\dlc\gunforgeralt\data\items\weapons\gfg_ak47\` 的 `.w2mesh`、`.xbm`：REDkit 匯入的產物（照上表的步驟可以重做）
  - `assets\anims\` 的 `.re`：使用者從 REDkit 匯出的 6 個原檔、`gfg\` 底下 Claude 做的（要匯入我們動畫組的）
  - `workspace\gameplay\behaviors\pc\behaviorgraph\pc_overlay.w2beh`：改過的原版動畫圖（`python -X utf8 tools/overlay_patch.py` 從原檔重做）
  - `workspace\gameplay\behaviors\pc\behaviorgraph\pc_gameplay.w2beh`：改過的原版主動畫圖（`python -X utf8 tools/gameplay_patch.py` 從原檔重做；新建時要重開 REDkit）
  - `assets\anims\` 底下 REDkit 匯出的原版走跑 6 段（`ex_man_geralt_gabriel_aim_run` 等；`tools\move_pose.py` 的輸入）
  - `thumbnails\`：REDkit 的縮圖

## 下一步

- 見最上面「沒做完的」「要使用者決定或操作的」
- 使用者給新任務時照 `CLAUDE.md` 做：沒說「恢復自主模式」就是互動模式（寫新東西前先問等）
- **REDkit 重開時 `editor.log` 會被整個重寫**：遊戲測完、重開 REDkit 之前，先讓 Claude 讀紀錄（或先複製到暫存資料夾）

### 測試方式補充

- **拿掉紀錄之後的測試**（`findings.md` §25）：在地面按 Reload scripts，照常玩一輪
  - 地面：左鍵連射到換彈、接著射；Z 鎖定時準心在目標身上；背對怪物跑邊射；C 收槍；衝刺、跳躍時不開火，落地還按著就接著射
  - 騎馬：叫馬、上馬 → 左鍵拿出、連射、換彈後接著射；中鍵射一發後馬要能照常操作；C 收槍後能下馬
  - 預期：和拿掉之前一樣；`editor.log` 裡不再有 `GFG` 的紀錄（`GfgLogHoldPose` 拿掉之後）
  - 2026-10-16 07:01 地面的結果：連射每秒 9～10 發；衝刺中 0 發、放開接著射；跳躍空中不射、落地接著射；Z 鎖定準心在狼身上、打死狼；C 收槍（06:25）
    - 落地時一行錯誤 `explorationstateland.ws(726) … Value 'EJT_IdleToWalk' not handled`：原版 switch 少一個 case，我們的包裝只是在呼叫堆疊裡
    - 沒測：背對怪物跑邊射、騎馬（測試關卡按 X 叫不出馬）
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

- 最上面「沒做完的」那幾項
- 雙手持槍（10-16 量的，之後沒重量）：
  - 轉彎跑時槍管和鏡頭最多差 19°（直線 0.8～5.5°）
  - 起步那一下手會離開握把（不到 0.3 秒；`aim_idle`、`aim_slow_run` 換掉後 4 次中 2 次 7、25 公分；推論是主動畫圖的起步動畫）
  - 換彈中槍管和鏡頭差 15～20°（換彈時沒有瞄準差值；換彈動畫 10-17 重做後沒重量）
  - 坡度沒測
  - 原版十字弩的瞄準、換彈、走跑也變成 AK 的雙手姿勢（同名動畫蓋過原版；主動畫圖改了直線走跑的骨頭表）
- M3：槍托後端和手套袖口有一點重疊
- M3：AK 從逆光的角度看整把銀白：是光線反射（真的 AK 同角度也銀白），不是少貼圖（10-17 做第 8 項 B 時看過）
- M3：Mesh editor 的預覽裡 AK 轉了方向：模型存在 `handle` 骨頭的座標系裡，正常（`docs\m3.md`「改用 NODE 模式」）
- 停火後鏡頭轉回原位：沿用推測的衰減公式（約 0.2～0.3 秒轉回）
- 前兩發沒有後座力：彈道資料的前兩發在同一點（`findings.md` §14.3）
- 每發轉完的時間 `GfgKickTime` 目前 0.1 秒，可調
- 開始墜落、攀爬、翻滾仍會收槍（`findings.md` §17.4）
- 拿著 AK 時不能存檔（存檔鎖：`findings.md` §17.8、§20.7）；另外 17 個動作也被鎖，使用者選維持原版（§20.12）
- 戰鬥中 AK 常被收起又拔出（`findings.md` §20.2），原因沒查（第 2 項擋掉了受擊時的兩條收槍路徑，其他情況沒再查）
- 騎馬沒測過的（§24.5）：騎馬跳躍時拿著 AK 的動作、拿著 AK 施法
- 每輪連射第 30 發寫一行錯誤 `Value '30' not handled`（不影響：`findings.md` §24.6）
- `UpdateLookAtVariables` 的包裝每個 session 寫一次 `Accessing invalid handle` 警告；原因沒查，沒看到影響

## 試過、放棄的做法

- 雙手持槍：上半身動畫圖 #18960 的 `secondValue` 改 0（移動時也走站著的瞄準）→ 按 W 角色完全不動（2026-10-16 03:09）→ 還原；`tools\overlay_patch.py --switch` 才會改

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
- 雙手持槍第 1 步：Blender 的 IK 約束（右手肘往側面彎 8°）、加 `ik_stiffness_y/z`（左手變更差）→ 改用兩節手臂的 IK 公式（`docs\m3.md`「雙手持槍：第 1 步：底層姿勢」）
- **在 Bash 的 heredoc 裡寫含反斜線的 Python**：`\\` 會變成 `\`，`\a` 會變成控制字元（2026-10-15 弄壞過交接檔一次）→ 含路徑的字串用 Write／Edit 工具，或在 Python 裡用 `chr(92)`
- **Bash 的 `cd` 會改掉 session 的工作目錄**（2026-10-15 `cd` 到唯讀資料夾三次）→ 用絕對路徑，不要 `cd` 到專案外
