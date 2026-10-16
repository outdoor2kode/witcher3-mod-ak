# 交接：進行中的狀態

> 新 session 開始時讀這份，接著做。
> 只放「還在變動」的東西：已定案的決策在 `CLAUDE.md`，查證過的事實在 `docs\findings.md`。
> 每次 commit 時一起更新（`CLAUDE.md` §11）。內容是「現在」的快照：過時的直接改掉，不累積。

最後更新：2026-10-16 19:0x（**自主模式**；第 1、2、3、4、5、7 項做好；第 6 項待長測；8、9、10 項還沒開始）

---

## 自主模式（2026-10-16 12:3x 起）

- 使用者：「假設我要離開電腦一年才回來接手，你要一直 RUN 下去獨立操控電腦解決任務」
  - 規則（使用者 2026-10-16）：使用者說「恢復自主模式」才開；任務做完就結束；沒說就是互動模式
- 不問使用者；決定和理由寫進這份檔案；範圍照舊：只做 AK 本身、只改專案資料夾（`CLAUDE.md` §7、§11）
- **等待一次最多 15 秒**（使用者 2026-10-16 從 30 秒改成 15 秒）：到時間先截圖檢查狀態再決定，不是直接關程式
- 保持清醒：背景 `desk.ps1 awake 2147483`（12:3x 起，約 24.8 天；PowerShell 的 `Start-Sleep` 最多 2147483 秒）
- 續做排程：CronCreate 每小時 :13（job `9924783b`；7 天後自動消失 → 2026-10-22 之後被叫醒時重排）
- **context 到 45%**（使用者 16:2x 從 38% 改成 45%）：更新交接檔、commit → 背景跑 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/claude_compact.ps1 <對話紀錄.jsonl>`（Bash 的 run_in_background）→ 結束這一輪；它會在終端機打 `/compact`、等壓縮完、再打「讀交接檔接著做」（`CLAUDE.md` §3、§14）
  - 14:22 實測成功：/compact 送出、壓縮完、接著做的訊息送出（使用者剛好在輸入框打字 → 兩段接在一起送出）
- **不准停超過 10 秒**（使用者 14:2x 加的規則，`CLAUDE.md` §14）：看門狗背景 `claude_compact.ps1 <紀錄> watch`（14:29 起，背景工作 bnz44l1oq）；收到 `[gfg-watchdog]` 訊息就查原因、排除、接著做
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
| 6 | 打完狼群有時解除不了鎖定 | **改了**（commit 2729ec3）：原因（推論）＝拿十字弩時血條目標＝滑動目標（`r4Player.ws:6749-6753`），原版收槍時才清（`:13380-13385`）；`GfgClearDeadSlideTarget` 每格清掉死掉的。13:1x 狼群測試的偵測紀錄沒有出現死掉的滑動目標；原問題不是每次都會出現，長時間測試時再看 |
| 7 | 跳躍落地後瞬間變回持槍姿勢、不順 | **做好、遊戲裡看過**（14:42）：站立跳、衝刺跳各連拍 14～18 張（每 0.1 秒，`desk.ps1 burst`）：起跳、空中、落地、再跑，兩手一直在槍上，沒有從擺手突然跳成持槍 |
| 8 | 換彈現在完全沒有動畫 → 做一個真正的 AK-47 換彈動畫 | 未開始 |
| 9 | 射出去的還是箭，不是子彈 → 要做 | 未開始 |
| 10 | 槍口火光、子彈速度；傷害由 Claude 設計一個符合這遊戲的 | 未開始 |

### 接續的步驟（2026-10-16 18:2x）

1. 第 9、10 項（子彈、槍口火光、彈速、傷害）→ 第 8 項（AK 換彈動畫：地面 `reload_lowered`、`reload_front_2` 和騎馬 4 段 `horse_*_reload_lowered` 一起換；事件要留著）
   - 18:5x 查到的（還沒動手）：
     - 現在的發射：原版弩箭 `Bodkin Bolt`（`items\weapons\projectiles\witcher_bolts\bodkin_bolt.w2ent`：`projSpeed` 60 公尺／秒、模型元件 `bolt` = `witcher_bolt_01.w2mesh`）；我們包了 `ThrowProjectile`（飛向準心）、`ShootProjectileAtPosition/AtBone`（射程 208 公尺）、`OnProjectileCollision`（插在牆上不刪，`GfgAddStuckBolt`）
     - 弩箭共用模板 `witcher_bolts\base\bolt_base.w2ent` 有特效（實體上直接 `PlayEffect`）：`arrow_trail`（`fx\weapons\trails\arrow\bold_trail.w2p`）、`arrow_trail_orange`、`arrow_trail_red`、`arrow_trail_fire`、`arrow_trail_underwater`、`sparks`（`fx\weapons\block\kontra\counterattack_fx1.w2p`）、`arrow_trail_mutation_9`、`red_arrow_trail_mutation_9`
     - Firearms（參考 mod）的槍口煙火在 DLC 打包檔裡，腳本沒有特效，不能照抄
   - 計畫（自己決定）：AK 的箭 → 藏起 `bolt` 模型、播 `arrow_trail_orange` 當曳光（照 CS2 `m_nTracerFrequency` 3：每 3 發一發曳光，其他只有很淡的或沒有）、速度改快（`ShootProjectileAtPosition` 包裝裡換 velocity，例 350 公尺／秒，角度 0）；打到牆壁地面播 `sparks`、不再插著（原本「插在牆上的箭不刪」是箭的設計，換子彈後沒有意義 → 播完火花刪掉）
   - 實作步驟（19:0x：1～3 已寫好、編譯過，**還沒進遊戲測** → 下一步做第 4 步；子彈速度 `GfgBulletSpeed` 350、曳光計數 `GfgNextShotIsTracer`）：
     1. 包 `W3BoltProjectile.OnProjectileShot`（原版 `arrowProjectile.ws:19-34`：沒有軌跡時 `ActivateTrail( defaultTrail )` ＝ `arrow_trail`＋破空聲 `cmb_arrow_swoosh`）：AK 的箭（`gfgAkRange > 0`，`ThrowProjectile` 包裝裡先設好）→ 呼叫原版後把 `CDrawableComponent` 都 `SetVisible(false)`（同 `arrowProjectile.ws:395-402` `SmartDestroy` 的寫法）；每 3 發 `ActivateTrail('arrow_trail_orange')`，其他 `StopEffect( activeTrail )`（或換很淡的）
     2. `ShootProjectileAtPosition/AtBone` 的包裝：AK 的箭把 velocity 換成子彈速度（先試 350 公尺／秒）、angle 換 0（直線）
     3. `OnProjectileCollision` 的包裝：打到 Static／Terrain → `PlayEffect('sparks')`，短時間後刪掉（取代 `GfgAddStuckBolt`；`gfgStuckBolts` 相關的程式拿掉）
     4. 測：站著連射打牆（截圖看曳光、火花、牆上沒有箭）、打狼（命中、傷害照舊）、騎馬開槍
   - 槍口火光：再找原版粒子（`D:\depot\fx\...`，例：`fx\fire`、`fx\signs\igni` 的小火花），做法二選一：AK 的實體模板加特效（REDkit Entity Editor）或在槍口生成一個帶特效的實體
   - 傷害：先查弩箭的傷害怎麼算（箭的物品屬性＋十字弩），再設計（CS2 36／爆頭 ×4 換算成巫師 3 的數值）
2. 長時間測試：30 隻狼、開槍打完，看第 6 項（鎖定解不掉）有沒有再出現
3. 全部做完拿掉暫時偵測紀錄 `GfgLogHoldPose`、`GfgLogDiag`、`GfgHorseCamLog`、`gfghorsehere`、`holster for vehicle`、`mount interaction allowed with AK`、`forceHolster`／`rangedForceHolster` 的紀錄；照 §14「結束」收尾
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
