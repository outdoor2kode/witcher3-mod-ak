# 交接：進行中的狀態

> 新 session 開始時讀這份，接著做。
> 只放「還在變動」的東西：已定案的決策在 `CLAUDE.md`，查證過的事實在 `docs\findings.md`。
> 每次 commit 時一起更新（`CLAUDE.md` §11）。內容是「現在」的快照：過時的直接改掉，不累積。

最後更新：2026-10-17 05:3x（**自主模式**；第 8 項 B 做好；開槍中側移分三節脊椎；下一步：清理暫時指令與紀錄）

---

## 自主模式：10-17 02:1x 恢復（使用者 02:0x 暫停、看過後 02:1x 回報第 19 項、說「自主模式繼續做」）

- 使用者 02:1x：「我檢查了一下整體都很好」；**先不要裝進遊戲，開發完整再來裝**（之前問的「裝進 mods\、dlc\」→ 不裝，最後再說）
- 背景程序（02:1x 重開）：保持清醒 `desk.ps1 awake 2147483`（背景工作 bw5jir1f2）；續做排程 CronCreate 每小時 :13（job **e185db7f**；7 天後過期 → 10-23 之後重排）；看門狗 `claude_compact.ps1 <紀錄> watch`
- **第 19 項：做好、遊戲裡驗證過**（02:5x）：使用者 `spawn('wolf', 30, 30, true)`，還沒拿出 AK 就走進狼群 → 原版自動拔劍；拿著劍按射擊 → 單手拿 AK、AK 看不到、不能射擊（截圖 `C:\Users\beyon\AppData\Local\Temp\claude\D--OneDrive-Desktop-gunforgeralt\39998eff-46be-449b-9abb-ed90f487652c\images\18.png`）
  - 使用者要的：「強制裝上 AK 的情況下，不准拿劍；進到狼群或戰鬥，要自動做的事情是舉槍」→ 寫進 `CLAUDE.md` §7
  - 決定（自己定）：條件是「AK 是選用物品，或 AK 拿在手上」（`GfgNoSwordMode`）；選別的物品時照原版。1／2 鍵擋掉、沒反應（不另外改成舉 AK：使用者沒要求）
  - 做法：原版自動拔劍都先問「最適合的劍」→ 包 `WeaponHolster.GetMostConvenientMeleeWeapon`：劍換成空手（`CombatFists`）、記下要舉 AK；包 `OnEquipMeleeWeapon` 擋鋼劍、銀劍（收劍照原版）；每格（`GfgNoSwordTick`）收掉手上的劍（戰鬥中收成空手）、5 秒內找時機舉 AK（地面同按左鍵、騎馬同騎馬左鍵；上下馬等狀態不舉、試一次後隔 1 秒）；拿著劍按左鍵 → 先收劍、收好再舉 AK、左鍵還按著就接著射。原版路線、實測 `docs\findings.md` §29
  - 實測：30 隻狼、5 隻狼各一次：沒拔劍、自動舉 AK（`raise AK … pstate=CombatFists`）；收著 AK 按 1：`sword draw blocked`；暫時指令 `gfgsword()`（繞過擋劍直接拔鋼劍）：沒戰鬥 0.3 秒內收回背上、戰鬥中收完接著舉 AK；拔劍中按住左鍵：收劍 → 舉 AK → 連射 29 發；騎馬戰鬥開始：騎馬舉 AK、1.2 秒 17 發、W 照常走
  - 戰鬥中按 C 收起 AK 會再自動舉起（同原版戰鬥中收劍會馬上再拔）
  - 暫時的（清理時拿掉）：`gfgsword()`、`gfgSwordTestBypass`、紀錄 `sword draw blocked`、`sheathe sword for AK`、`raise AK`、`sword wait`、`raise wait`
- **第 8 項 B：做好**（10-17 05:0x）：換彈時彈匣真的拿下來（真的 AK 換成沒彈匣的替身、彈匣替身掛左手）；左手握著彈匣拉下、到左腰、帶回裝上
  - 遊戲裡看過：地面（左前方 45°、左邊 90°、拉槍機那段）、騎馬停著（左前方 60°）；騎馬 Canter、Gallop 的紀錄 `mag out t=0.315 dist=0.008`、`t=0.316 dist=0.009`
  - 做法、量法、側面看的方法：`docs\m3.md`「換彈動畫：彈匣拿下來」
  - 暫時指令（清理時拿掉）：`gfgnoturn`、`gfgfree`、`gfgshots`、`gfgmagshow`；紀錄 `[GFG] pose mag`、`mag out` 的 `attached=`、`mag no grab`
  - 測法（g.sh）：`side_reload2 前綴 [角度=45] [距離=1.3] [高度=0] [張數=14] [間隔毫秒=4000] [慢動作=0.02]`；騎馬：`horse_start` 之後 `side_reload2 名 60 1.3 0.1`；看拉槍機：等 `mag in` 之後才開 `gfgfree`
  - REDkit 03:15 重開：主視窗 `0xAD0A1C`、Asset Browser `0x35D0E38`（移到螢幕右下外面）；AnimBrowser 用時再開（上次 `0x890D56`，已關）
  - 原版十字弩行為：換彈後不在戰鬥、沒瞄準 → 延遲後自動收起（`rangedWeapon.ws:146-157`）；測試時 AK 會被收起來，點一下畫面再拿出
- **開槍中側移（第 13 項剩下的）：做了能做的部分**（05:2x）：6 段側移用 `--spread 0.2 0.4 0.4` 重做、匯入（單節最大扭轉減半以上，槍不變）；總腰扭（D、A 有兩種模式 ±47°）沒降：要換腳步來源，成本高 → 先不做；細節 `docs\m3.md`「雙手持槍：開槍中側移」
  - AnimBrowser 05:1x 開過：`0x2E41C84`（g.sh 的 `GAB` 已換；還開著）
- **現在做：清理暫時指令與紀錄**（05:3x 開始）
  - **第一次做完、編譯過，遊戲裡還沒測**（05:4x）：拿掉每格／定時的紀錄（`pose`、`twist`、`diag`、`horseCam`）、查問題用的紀錄（`forceHolster`、`rangedForceHolster`、`sword wait`、`raise wait`、`mag no grab`、`holster for vehicle`、`mount interaction allowed`、`manual hit`、`coll`、`bullet sparks/hit`、`ray hit/miss`、`ak dmg`、`CNewNPC.OnTakeDamage` 的包裝）、測試指令 `gfgfree`、`gfgnoturn`、`gfgmagshow`、`gfgbullet`、`gfgdmg`、`gfgwolf`、`gfghorsehere`
  - 第二次（回歸測試後）再拿：`gfgshots`、`gfgsword`／`gfgSwordTestBypass`、紀錄 `mag out`、`mag in`、`raise AK`、`sword draw blocked`、`sheathe sword for AK`；**永久保留**找不到模板的錯誤紀錄（`carry dummy template not found`、`mag template not found`）
  - g.sh 的 `side_reload2` 用到已拿掉的 `gfgnoturn`、`gfgfree`（要再側面看就從 git 找回 commit e0bfb09 的版本）
  - 接續：① `restart_all` 回歸測試：開槍、換彈（`mag out/in`）、衝刺、跳、騎馬開槍換彈、上下馬、`spawn('wolf', 5, 10, true)` 自動舉槍、1 鍵擋劍、`gfgsword()` ② 第二次清理、編譯、簡單再測 ③ 重新打包（Publish；打包後重開 REDkit）④ 照 §14 結束自主模式（裝進遊戲要使用者決定）
- 之後：曳光（先跳過）；**開發完整後**才打包、裝進遊戲、Steam 版驗證（使用者 02:1x）

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

## 自主模式（2026-10-16 12:3x 起；20:2x 暫停、20:4x 恢復）

- 使用者：「假設我要離開電腦一年才回來接手，你要一直 RUN 下去獨立操控電腦解決任務」
  - 規則（使用者 2026-10-16）：使用者說「恢復自主模式」才開；任務做完就結束；沒說就是互動模式
- 不問使用者；決定和理由寫進這份檔案；範圍照舊：只做 AK 本身、只改專案資料夾（`CLAUDE.md` §7、§11）
- **等待一次最多 15 秒**（使用者 2026-10-16 從 30 秒改成 15 秒）：到時間先截圖檢查狀態再決定，不是直接關程式
- 保持清醒：背景 `desk.ps1 awake 2147483`（12:3x 起，約 24.8 天；PowerShell 的 `Start-Sleep` 最多 2147483 秒）
- 續做排程：CronCreate 每小時 :13（job `6de2cbf7`，20:4x 重排；7 天後自動消失 → 2026-10-22 之後被叫醒時重排）
- **context 到 45%**（使用者 16:2x 從 38% 改成 45%）：更新交接檔、commit → 背景跑 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/claude_compact.ps1 <對話紀錄.jsonl>`（Bash 的 run_in_background）→ 結束這一輪；它會在終端機打 `/compact`、等壓縮完、再打「讀交接檔接著做」（`CLAUDE.md` §3、§14）
  - 14:22 實測成功：/compact 送出、壓縮完、接著做的訊息送出（使用者剛好在輸入框打字 → 兩段接在一起送出）
- **不准停超過 10 秒**（使用者 14:2x 加的規則，`CLAUDE.md` §14）：看門狗背景 `claude_compact.ps1 <紀錄> watch`（20:4x 重開，背景工作 b4r7kapce；保持清醒 bchoezw4w）；收到 `[gfg-watchdog]` 訊息就查原因、排除、接著做
  - 對話紀錄：`C:\Users\beyon\.claude\projects\D--OneDrive-Desktop-gunforgeralt\<session id>.jsonl`；context 使用率：`%TEMP%\claude\gfg-context\<session id>.pct`
- **結束自主模式**：CronDelete、停掉保持清醒（TaskStop 背景工作，或殺掉命令列含 `desk.ps1 awake` 的 `powershell.exe`）、這份檔案最上面寫「使用者回來時先看這裡」、終端機叫回前面（`desk.ps1 focus proc:windowsterminal`）

## 現在在做：使用者回報的 10 個問題（2026-10-16 12:2x）

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

### 接續的步驟（2026-10-17 00:0x 改順序）

- **最優先：打包、在 Steam 版遊戲裡驗證**（使用者 10-17 00:0x：「你真的做太久了，你是不是大方向錯了啊…偶爾拉出來看看全局」）
  - 全局檢查的結論：動畫的做法沒歪（問題多是各狀態各缺一段雙手動畫；共同的根本＝側身底層，22:3x 已從根本換成正面持槍）；**真正更根本、一直沒做的是打包**：mod 從沒打包、Steam 版遊戲完全讀不到（`docs\findings.md` §13.16），改過的原版動畫圖（`pc_overlay.w2beh`、`pc_gameplay.w2beh`）、DLC 動畫組、腳本打包後能不能生效都沒驗證；REDkit 裡的遊戲本身也有毛病（開久了上不了馬）
  - 步驟：① **REDkit 打包：做好**（00:1x；輸出在專案的 `packed\`；`docs\findings.md` §27）② 裝進遊戲要寫 `<W3_GAME_DIR>\mods\`、`dlc\`（唯讀，`CLAUDE.md` §11）→ 00:1x 問了使用者；**使用者 02:1x：先不要裝，開發完整再裝**（同意讓 Claude 複製，或使用者自己複製；測前先備份存檔 `C:\Users\beyon\OneDrive\Documents\The Witcher 3\gamesaves`，55 個檔 13 MB）③ Steam 版跑基本流程：拿 AK、開槍、換彈、騎馬 ④ **換彈 A 的 6 段：匯入、遊戲裡驗證，做好**（00:5x）；彈匣分離（B）等 Steam 版驗證過再做
  - 打包後同一次開著的 REDkit 按 play game 當掉 → 00:3x 重開 REDkit（主視窗 `0x1809A4`；g.sh 已換；AnimBrowser 要用時重開、更新 `GAB`）
  - 開遊戲前先把編輯器鏡頭移到地面（滑鼠指地面按 J）：00:40 從高處摔死、死亡選單選錯 → 遊戲直接結束

- **第 10 項槍口火光：做好**（10-17 01:2x；上表第 10 項）
  - 打包要重做：這次的改動（槍口火光模板 `dlc\gunforgeralt\data\fx\`、腳本、2.4 秒的換彈動畫組）都在第一次打包（00:1x）之後
- **succesfullyCooked: false 查過**（01:3x）：候選原因＝`.ws` 被當資源 cook 失敗、沒有 Wwise；遊戲執行檔沒有這個欄位名 → 推論不影響遊戲（`docs\findings.md` §27）
- **曳光：先跳過**（01:3x 決定）：原版能連到目標的特效（`drain_energy`、`lightning`）都是魔法光束；箭的軌跡在 715 公尺／秒看不到（之前測過）；不是使用者明確要求的 → 記下來，之後有空再做（想法：另外生成一個慢速、發光的曳光實體）
- **第 8 項 B 彈匣分離：做好**（01:3x～05:0x；見最上面「自主模式」）

0. **之後做這些**（第二批 11～18 都做完了；第一批剩第 8、10、6 項）
   - 第一批第 8 項（換彈動畫）：A、B 都做好（`docs\m3.md`「換彈動畫」兩節）
   - 第 10 項：槍口火光（＋曳光）
   - 第 6 項：長測（30 隻狼，看鎖定解不掉有沒有再出現）
   - 第 13、14 項：沒開槍走跑做好（見上表）；**開槍中側移**（全身側移 6 段）另外量過（22:4x，相對準心，正 = 右）：W 骨盆 65、肩 63（扭 −2）；W+D 91／82（−9）；D 112／81（−31）；A 38／44（6）；W+A 34／49（15）；穩定時槍管對準準心 0～2°，起步 0.5～1 秒偏 40～60°。D 的 −31° 之後有空再改（想法：NPC 十字弩兵側移 `assets\anims\man_npc_bow_strafe_walk_*.re` 已匯出，但速度是 Geralt 的 2 倍 2.4 公尺／秒，要另外處理）
   - 之後：第一批第 8 項（換彈動畫）、第 10 項槍口火光、第 6 項長測、清理暫時紀錄（新增：`ray hit`、`ray miss`、`manual hit`、`coll`、`gfgwolf` 的 3～5 種類、`twist`（`GfgLogTwist`、`GfgLineHeading`））
   - 測試小技巧（21:xx 學到）：`restart_all`（g.sh；點遊戲畫面拿焦點 → F10 → 重載腳本 → 開遊戲，約 1.5 分鐘）；遊戲中用選單熱重載沒反應；`sweep 檔名 dy 次數`＝按住左鍵往上掃；**burst 的前綴要寫完整路徑 `"$P/名稱"`**，不然存到專案資料夾；`gfgwolf` 用 Geralt 身體的朝向，不是鏡頭

1. 第 10 項：
   - **爆頭判定（20:2x 使用者接手時停在這裡）**：原版的爆頭靠 Ragdoll 碰撞的骨頭（`arrowProjectile.ws:91-94`），子彈先撞到角色膠囊（`Character`）就算命中、沒有骨頭 → 不會爆頭
     - 試過、放棄：AK 子彈的碰撞群組拿掉 `Character`（只打 `Ragdoll`）→ 打不到人（20:0x）
     - 現在的程式（20:12 commit、編譯過）：`GfgIsHeadOnLine`：頭部骨頭到子彈直線（`gfgShotFrom` → 碰撞點）的最近距離 < 0.15 公尺 = 爆頭；`head` 骨頭找得到（紀錄 `[GFG] head check`）
     - **20:15 查到的原因**：不管準心瞄頭還是胸口，子彈都打在目標胸口同一點（比頭部骨頭低 0.45 公尺，紀錄 hit 座標完全一樣）；不是硬鎖定（按 Z 才出現鎖定菱形，解除後還是一樣）
       → 推測是原版的自動瞄準：`W3BoltProjectile.ThrowProjectile`（`playerBoltProjectile.ws` 約 250 行起）有目標時用 `ShootProjectileAtBone( 目標, 骨頭 )`，我們的 `ShootProjectileAtBone` 包裝保留了骨頭
     - **d8a67b8（20:17）**：`ShootProjectileAtBone` 包裝：AK 的子彈改呼叫 `ShootProjectileAtPosition( …, gfgAimTarget, … )`（`ThrowProjectile` 包裝裡記下的準心射線點，新欄位 `gfgAimTarget`）
     - **20:2x 測試結果：子彈常穿過人**（準心從靶子腳邊往上掃、一邊連射）
       - 715 公尺／秒：7 發全部沒打中，打在靶子後面的地上（x 45.5 → 42.3）或遠處
       - 60 公尺／秒（`gfgbullet(60)`）：前 3 發打中小腿（z≈5.2、靶子中心前 0.19 公尺），後 5 發一樣穿過去打到後面的地上
       - 算過：其中一發的鏡頭射線在靶子膝蓋高度離靶子中心線只有 0.1 公尺，`GfgAimPoint` 卻回傳後面的地面 → 準心射線（`RayCastSync`，碰撞群組和原版 `CalculateAimPosition` 一樣：`playerAiming.ws:33-49`、`:553-616`）看起來沒打到人（還沒用紀錄證實）
       - 原版十字弩打人不靠這條射線：有目標時一律 `ShootProjectileAtBone` 自動瞄準（`playerBoltProjectile.ws:353-377`）
     - 原版的碰撞規則（20:2x 查）：弩箭的碰撞群組預設 `Ragdoll, Static, Terrain, Water, Character`（`playerBoltProjectile.ws:34-40`）；目標有 `AddRagdollCollision` 標籤時拿掉 `Character`（`:370-373`）；有這個標籤的 NPC 被膠囊（`CMovingAgentComponent`）擋到、玩家又沒有畫面目標時不算命中（`:165-168`）；打到 Ragdoll 時有元件、用 `actorIndex` 查骨頭（`arrowProjectile.ws:85-94`）→ 和 20:0x「Ragdoll 碰撞沒元件」的結論矛盾，要再確認
     - 下一步（擇一，要使用者決定）：
       - 甲：退回 d8a67b8（打人穩定中胸口，沒有爆頭）
       - 乙：先在 `GfgAimPoint` 加紀錄印出射線的每個結果（實體、元件類別、距離、位置），確認為什麼沒打到人
       - 丙：保留原版自動瞄準（`AtBone` 一定打得中），但骨頭改成「準心射線最靠近的骨頭」：射線離頭部骨頭 < 0.15 公尺就打 `head`、算爆頭；射線沒經過目標才用 `AtPosition`
     - 測試時的瞄準：`con` 之後鏡頭上下重設；小的 `rmove`（每次 5 像素以下）常被吃掉；Z＝硬鎖定（目標名字旁出現菱形），子彈改朝鎖定點（`GfgLockPoint`：軀幹＋0.2 公尺，既有設計）
     - 測法：`con "gfgwolf(6,1,31)"`（31 級人類、站著不動）→ `d rmove -10 -30 2 20`、`d rmove -10 -15 1 20`、再 `d rmove 0 -15 1 20` → 點一下左鍵 → 紀錄 `[GFG] head check … hitDist= lineDist=`、`[GFG] ak dmg … head=`
   - 傷害公式已驗證（20:0x）：狼（5 級，165 血）一發倒；1 級人類 41.25 血；31 級人類 2763.75 血、每發 384.87；實際＝基礎＋58（人的血）、基礎×1.25＋58（怪物的精華）
   - 槍口火光（＋曳光）：REDkit Entity Editor 在 AK 的實體模板加特效（找原版粒子，例：`fx\weapons\obstacle_hit\sparks_colision.w2p`、`fx\weapons\trails\sparks\fire_sparks_trail.w2p`、`fx\skills\maiming_shot\maiming_shot_crossbow_fx.w2p`；`r4data\fx` 有 2003 個 `.w2p`），每發 `PlayEffect`；槍口位置要從模型算（CS2 `m_vecMuzzlePos0`）
   - 再來第 8 項（AK 換彈動畫：地面 `reload_lowered`、`reload_front_2` 和騎馬 4 段 `horse_*_reload_lowered` 一起換；事件要留著）
2. 長時間測試：30 隻狼、開槍打完，看第 6 項（鎖定解不掉）有沒有再出現
3. 全部做完拿掉暫時的指令和紀錄：`gfgbullet`、`gfgwolf`、`gfgdmg`、`CNewNPC.OnTakeDamage` 包裝（`[GFG] dmg`）、`[GFG] ak dmg`、`bullet sparks`／`bullet hit` 紀錄、`GfgLogHoldPose`、`GfgLogDiag`、`GfgHorseCamLog`、`gfghorsehere`、`holster for vehicle`、`mount interaction allowed with AK`、`forceHolster`／`rangedForceHolster` 的紀錄；照 §14「結束」收尾
- 騎馬測試（`g.sh`）：`game_start` 之後 `horse_start`（白天、C 收槍、X 叫馬、`instantMount('playerHorse')`、左鍵拿出）；動畫組操作：`import_one plain|local 檔名`、`add_ev 篩選字 事件 秒`、`add_dur 篩選字 事件 起點 長度`、`rm_anim 完整名稱`、`save_gab`（座標和注意事項寫在 g.sh 的註解；AnimBrowser 右鍵選單跟著選取中的項目）
- 測試小技巧（暫存資料夾 `desk\g.sh`，session 結束就沒了）：`game_start`＝開遊戲到拿出 AK（約 1 分鐘：play、死了就復活、`setlevel(31)`＋`additem`＋`god()`、輪盤教學照紀錄按 Space、左鍵拔槍）；`reload_edit`＝REDkit 重新載入腳本；`wolf_test N 秒`＝關無敵、生狼
  - **F10 會結束遊戲**（不是切換）：改了腳本 → F10 → `reload_edit` → `game_start`
  - **REDkit 開久了，空手按 E 也上不了馬**（18:0x：互動輸入完全沒進腳本）→ 重開 REDkit 就好（使用者 18:0x：「如果已經沒拿槍，就是之前遇到的問題又出現了，看你要修還是直接關掉 redkit 重開」）；判斷順序：拿著 AK 不能上下馬＝第 4 項本身（已修好）；空手也不行＝環境問題 → 重開
  - 18:06 重開 REDkit 後主視窗 handle 是 `0x461CEC`（g.sh 已換；AnimBrowser 都關了，要用時重開、更新 `GAB`、`AB`）；`ak_select`＝輪盤選 AK＋左鍵拿出（`game_start` 的主控台步驟跑掉時單獨補做；18:12 發生過：主控台沒打開、按鍵打進右邊 Scene 搜尋框）
  - `additem` 前要先 `setlevel(31)`（14:3x：沒設等級時主控台顯示 `Invalid Item ID: 0`、輪盤沒有 AK）
  - 主控台指令曾打進 REDkit 右邊 Scene 的搜尋框（焦點在那裡）→ 編輯模式下點一下畫面空白處（天空）把焦點移走
  - 原地跳旁邊有高台會變成攀爬（攀爬照原版收槍）→ 到空曠處測
  - 連拍：`desk.ps1 burst <前綴> <張數> <間隔毫秒> rect=… hold=w,shift pre=1500 key=space`
  - **慢動作**：遊戲中按數字鍵盤減號（`d key numminus`）3 次 = 0.125 倍，`numplus` 3 次回到 1 倍；**F10 重開遊戲後不會重設**（右上角紅字 Time scale）
  - 連拍的前綴不要和其他截圖同名（會被 `前綴1.png`… 蓋掉）；遊戲裡改白天：`settime(1, 12)`（`gameTime.ws:182`；重開遊戲會變回深夜）
  - 看衝刺側面：按住 A＋Shift 往左跑（鏡頭直接看到左側）；連拍用工具內建的 `hold=a,shift pre=1500 [key=space|c]`（desk.ps1 每次呼叫要 0.3～0.5 秒，分開下指令時間會對不準）
  - 側面拍左手：衝刺中 `d rmove -150 0 6 15`～`-250` 轉鏡頭（鏡頭在右後方時左手的槍被身體擋住：看起來「槍不見」不一定真的不見）
- 偵測紀錄 `GfgLogDiag`（`[GFG] diag`）：`fullBodyAnimWeight`、`playerSpeedForOverlay`（衝刺 1.5、跑 1.0）、滑動／畫面目標等

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
- 暫時的偵測紀錄 `GfgLogHoldPose`（`GfgCameraTick` 裡呼叫）還在，10 個問題做完後拿掉

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
- 已 commit、但還是暫時的：`gfg_ak47.ws` 的 `GfgLogHoldPose`（雙手持槍量位置用；`GfgCameraTick` 裡呼叫；印 `held=`、`friendly=`）→ 雙手持槍做完後拿掉（「下一步」3）
- REDkit 匯入的產物（不在 git）：`gfg_ak47.w2mesh` 是第 1 步的擺法（`m3_build_ak.py --place …`：`docs\m3.md`）
- `.claude\hooks\`（`context-check.sh`、`statusline.sh`）：使用者自己的設定，2026-10-15 18:35 出現，Claude 沒動過 → 不 commit
- `.gitignore` 排除、不 commit 的：
  - `assets\ak47\` 的 `.blend`、`.fbx`、`.png`：腳本的輸出（材質 XML `gfg_ak47.xml` 有 commit）
  - `workspace\dlc\gunforgeralt\data\items\weapons\gfg_ak47\` 的 `.w2mesh`、`.xbm`：REDkit 匯入的產物（照上表的步驟可以重做）
  - `assets\anims\` 的 `.re`：使用者從 REDkit 匯出的 6 個原檔、`gfg\` 底下 Claude 做的（要匯入我們動畫組的）
  - `workspace\gameplay\behaviors\pc\behaviorgraph\pc_overlay.w2beh`：改過的原版動畫圖（`python -X utf8 tools/overlay_patch.py` 從原檔重做）
  - `workspace\gameplay\behaviors\pc\behaviorgraph\pc_gameplay.w2beh`：改過的原版主動畫圖（`python -X utf8 tools/gameplay_patch.py` 從原檔重做；新建時要重開 REDkit）
  - `assets\anims\` 底下 REDkit 匯出的原版走跑 6 段（`ex_man_geralt_gabriel_aim_run` 等；`tools\move_pose.py` 的輸入）
  - `thumbnails\`：REDkit 的縮圖

## 下一步

1. **雙手持槍**：站著、走路、跑步、換彈、收槍都在遊戲裡通過 → 還沒做的：坡度、衝刺（手會擺）、拔槍沒量、轉彎跑時槍管最多差 19°（見「已知限制」）
2. 箭第一次出現在槍口前 1～2 公尺：箭速 60 公尺／秒 × 每格約 30 毫秒（`docs\m3.md`「箭離槍口一段距離才出現的原因」）
   - Claude 建議留到 M5 用槍口火光、曳光處理；另一個選項是降低箭速；使用者還沒決定
3. 拿掉紀錄的測試（下面「測試方式補充」）：**地面全部通過**（2026-10-16 07:01～07:02，Claude 用 desk.ps1）；騎馬沒測（測試關卡叫不出馬）
   - 剩下的暫時紀錄是雙手持槍的 `GfgLogHoldPose`（含兩腳）：使用者看過雙手持槍的樣子、不再調整時拿掉
4. 輪盤的待驗證項目（`findings.md` §24.9）：使用者下次騎馬時順便目測
5. 之後再做（使用者決定時機）：傷害平衡（CS2 36、爆頭 ×4）、M4 聲音（要先確認 Wwise 版本：`CLAUDE.md` §3）
6. M5 候選：槍口火光、曳光；持槍衝刺／跳躍的動畫（`findings.md` §17.10）；跳躍散布（§16.2）
7. 暫時方案（使用者沒選，雙手做不成時再考慮）：拿著 AK 時鏡頭移到 Geralt 左後方，讓左手的槍看得到

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

- 雙手持槍：站著瞄準、連射、換彈、收槍都好了；還沒好的：
  - 衝刺：主動畫圖衝刺那一支沒有十字弩版本 → 手會擺（沒測）；坡度沒測；拔槍沒量
  - 轉彎跑時槍管和鏡頭最多差 19°（直線 0.8～5.5°）
  - 起步那一下手會離開握把（不到 0.3 秒；`aim_idle`、`aim_slow_run` 換掉後 4 次中 2 次 7、25 公分；推論是主動畫圖的起步動畫）
  - 換彈中槍管和鏡頭差 15～20°（換彈時沒有瞄準差值）
  - 原版十字弩的瞄準、換彈、走跑也變成 AK 的雙手姿勢（同名動畫蓋過原版；主動畫圖改了直線走跑的骨頭表）
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
