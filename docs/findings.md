# M0 盤點結果

> 2026-10-12 盤點。對象：原版十字弩腳本與物品定義、reference 參考 mod、已安裝 mod。
> 標記：✅ 已查證（附出處）／🔶 推論（附理由）／❓ 未查證

---

## 0. 路徑代號與檔案索引

| 代號 | 實際位置 |
|---|---|
| `[S]` | `<W3_VANILLA_SCRIPTS>` = `<W3_GAME_DIR>\content\content0\scripts` |
| `[D]` | `<REDKIT_DEPOT>` = `<REDKIT_DIR>\r4data` |
| `[R]` | `<W3MODS_DIR>\reference` |
| `[M]` | `<W3_GAME_DIR>\mods`（已安裝的 mod） |

**原版腳本（下文只寫檔名）**

| 檔名 | 完整路徑 |
|---|---|
| `rangedWeapon.ws` | `[S] game/gameplay/items/rangedWeapons/rangedWeapon.ws` |
| `playerBoltProjectile.ws` | `[S] game/projectile/playerBoltProjectile.ws` |
| `arrowProjectile.ws` | `[S] game/projectile/arrowProjectile.ws` |
| `advancedProjectile.ws` | `[S] game/projectile/advancedProjectile.ws` |
| `ProjectileTrajectory.ws` | `[S] game/projectile/ProjectileTrajectory.ws` |
| `throwable.ws` | `[S] game/gameplay/items/throwables/throwable.ws` |
| `playerAiming.ws` | `[S] game/player/playerAiming.ws` |
| `aimThrow.ws` | `[S] game/player/states/aimThrow.ws` |
| `r4Player.ws` | `[S] game/player/r4Player.ws` |
| `playerInput.ws` | `[S] game/player/playerInput.ws` |
| `inventoryComponent.ws` | `[S] game/components/inventoryComponent.ws` |
| `definitionsManager.ws` | `[S] game/definitionsManager.ws` |
| `gameParams.ws` | `[S] game/gameParams.ws` |
| `damageManagerProcessor.ws` | `[S] game/gameplay/damage/damageManagerProcessor.ws` |
| `attackAction.ws` | `[S] game/gameplay/actions/attackAction.ws` |
| `r4Game.ws` | `[S] game/r4Game.ws` |
| `inputManager.ws` | `[S] game/inputManager.ws` |
| `world.ws`、`physicsTraceManager.ws`、`camera.ws`、`cameraDirector.ws`、`entity.ws`、`sound.ws`、`game.ws` | `[S] engine/` |
| `customCamera.ws`、`customCameraControllers.ws` | `[S] game/cameras/combat/` |

---

## 1. 環境

- ✅ 遊戲版本：`bin\x64_dx12\witcher3.exe` 檔案版本 5.0.0.1048522
- ✅ `[D]\scripts` 和 `[S]` 完全相同（`diff -rq` 無差異，各 1525 個 `.ws`）
- ✅ 編碼：
  - 5.x 原版 `.ws`：UTF-8
  - 舊版參考 mod（CCO、Firearms、FirearmsNextGen）：**UTF-16 LE**
  - MCME 與已安裝的 5.x mod：UTF-8
- ✅ 專案檔 `gunforgeralt.w3edit`：`"useLooseScripts": false`、`"idSpace": 10000000`
  - 兩個欄位的意義見第 12.2、12.4 節

**已安裝的 mod（`[M]`，共 23 個）與衝突風險**

- ✅ 整檔覆寫原版腳本的只有 `modMoreSkillSlots`：
  - `playerabilitymanager.ws`、`characterMenu.ws`、`charactermenudupe.ws`、`playerwitcher.ws`
  - 它的 `playerwitcher.ws` 和 5.x 原版一樣是 12970 行 → 🔶 已針對 5.x 重做
- ✅ 其他有腳本的 mod 都用 annotation，檔案放在 `content/scripts/local/`
  - 包住的方法：`CR4Player.OnSpawned`（MCME）、`W3PlayerWitcher.AddStartingSchematics`（rationalcrafting）、`W3PlayerWitcher.AddAlchemyRecipe` / `AddCraftingSchematic`（SortEverything）
- ✅ **沒有任何已安裝 mod 碰到十字弩相關類別**（RangedWeapon、Crossbow、W3BoltProjectile、PlayerAiming、AimThrow）
- 結論：我們只要**不整檔覆寫 `playerWitcher.ws`**，就不會和現有 mod 衝突

---

## 2. 原版十字弩的類別

| 類別 | 定義位置 | 角色 |
|---|---|---|
| `RangedWeapon`（statemachine，繼承 `CItemEntity`） | `rangedWeapon.ws:6` | 遠程武器本體 |
| `Crossbow`（繼承 `RangedWeapon`） | `rangedWeapon.ws:689` | 十字弩；控制換彈時機 |
| 狀態 `State_WeaponWait` / `Draw` / `Reload` / `Aim` / `Shoot` / `Holster` | `rangedWeapon.ws:1011` / `1108` / `1215` / `1275` / `1468` / `1621` | 武器狀態機 |
| `W3BoltProjectile` | `playerBoltProjectile.ws:6` | 玩家弩箭 |
| `W3ArrowProjectile` | `arrowProjectile.ws:6` | 箭矢共用邏輯 |
| `W3DeflectableAdvancedProjectile` | `advancedProjectile.ws:127` | 可被彈開的投射物 |
| `W3AdvancedProjectile` | `advancedProjectile.ws:6` | 投射物（`projSpeed`、`projAngle`） |
| `CThrowable`（statemachine） | `throwable.ws:6` | 可投擲物；有 `Aiming` 狀態 |
| `CProjectileTrajectory`（引擎類別） | `ProjectileTrajectory.ws:6` | 彈道與發射 API |
| `PlayerAiming`（statemachine） | `playerAiming.ws:12` | 瞄準射線、慢動作、準心 |
| 狀態 `AimThrow in CR4Player` | `aimThrow.ws:6` | 瞄準時的鏡頭與轉向 |

- ✅ 玩家身上的欄位宣告為 `var rangedWeapon : Crossbow`（`r4Player.ws:17`）

---

## 3. 射擊流程（按鍵 → 傷害）

1. **按鍵**
   - 註冊 `'ThrowItem'` → `OnCbtThrowItem`（`playerInput.ws:163`）
   - 處理函式在 `playerInput.ws:3133–3273`
   - 判斷十字弩：`IsItemCrossbow`（3183）、`IsActionAllowed(EIAB_Crossbow)`（3185）
   - 按下：`SetupCombatAction( EBAT_ItemUse, BS_Pressed )`（3203）
   - 放開：`BS_Released`（3211）
2. **轉給武器**
   - `r4Player.ws:10712`：`rangedWeapon = ( Crossbow )( inv.GetItemEntityUnsafe( selectedItemId ) )`
   - 按下呼叫 `OnRangedWeaponPress()`（10713），放開呼叫 `OnRangedWeaponRelease()`（10741）
3. **設定動畫變數**
   - `OnRangedWeaponPress` / `Release` 設 `isAimingWeapon` / `isShootingWeapon`（`rangedWeapon.ws:44–54`）
   - 由行為圖（`.w2beh`）播放動畫
4. **按住超過 0.2 秒 → 進入瞄準**
   - `CheckGotoAimThrow`（`rangedWeapon.ws:1345–1433`），0.2 秒迴圈在 1352
   - `OnEnableAimingMode( true )`（1400）→ 玩家 `PushState( 'AimThrow' )`（`r4Player.ws:14749–14758`）
   - 箭矢 `StartAiming()`（`rangedWeapon.ws:1404`）
   - 已在瞄準中，就改呼叫 `OnAddAimingSloMo()`（1408）
5. **發射時機由動畫事件決定**
   - 動畫送出 `'ProjectileThrow'` → `RangedWeapon.OnProcessThrowEvent`（`rangedWeapon.ws:124–162`）
   - 再轉給箭矢 `deployedEnt.OnProcessThrowEvent`（128）
6. **決定目標點**
   - 瞄準中：箭矢在 `Aiming` 狀態，用 `ThrowProjectile( playerAiming.GetThrowPosition() )`（`throwable.ws:175–193`，重點在 187）
   - 腰射：用 `GetLookAtPosition()`，上限是 `MAX_THROW_RANGE`（`playerBoltProjectile.ws:128–139`）
     - 這個點來自 `UpdateLookAtTarget()`（`r4Player.ws:2754–2885`），會**自動追蹤鎖定的敵人**
7. **發射投射物**
   - `ThrowProjectile`（`playerBoltProjectile.ws:246–289`）
   - → 計時器 `ReleaseProjectiles`（291）
   - → `ReleaseProjectiles2`（323–414）
   - 鎖定敵人時打骨骼：`ShootProjectileAtBone`（375）
   - 其他情況：`ShootProjectileAtPosition( projAngle, projSpeed, targetPos, attackRange, collisionGroups )`（377）
   - 箭矢會被扣除，除非有 `InfiniteAmmo` 標籤（382–388）
8. **命中與傷害**
   - `OnProjectileCollision`（`playerBoltProjectile.ws:149–204`）→ `ProcessDamageAction`（49–109）
   - 建立 `W3Action_Attack`，攻擊名稱是 `'bolt'`（70–71）
   - 依骨骼名稱判定爆頭（78–82）
   - `theGame.damageMgr.ProcessAction( action )`（84）
9. **換彈**
   - 射擊後呼叫 `ReloadWeaponWithOrWithoutAnimIfNeeded()`（`rangedWeapon.ws:137`、`276–297`）
   - `Crossbow.PlayOwnerReloadAnim()`（830–852）：`shotCountLimit = 1`（694）→ **每射一發就播一次換彈動畫**
     - 有技能 `S_Perk_17` 時可以多射一發（834–836）
   - `ReloadWeapon()`（338–372）在弩的 `'bolt'` slot 生成新箭：
     - `CalcEntitySlotMatrix( 'bolt', mat )`（348）
     - `inv.GetDeploymentItemEntity(...)`（351）
     - `InitializeCrossbow`（353）
     - `CreateAttachment( this, 'bolt' )`（356）
10. **射擊回饋**
    - 在 AimThrow 中射擊時，`GCameraShake( 0.05 )` 或 `GCameraShake( 0.125 )`，依 `recoilLevel` 決定（`rangedWeapon.ws:1540–1546`）

### 對本專案的意義

- **射速被動畫綁住**：原版要等 `'ProjectileThrow'` 動畫事件才發射，而且每發都要換彈
  → 600 RPM 一定要繞過；CCO 的作法見第 8.1 節
- **AK 的實體類別必須繼承 `Crossbow`**
  - `r4Player.ws:10712` 會強制轉型成 `(Crossbow)`，欄位型別也是 `Crossbow`（`r4Player.ws:17`）
- **腰射會自動追蹤鎖定目標**，不是準心瞄準
  → 和 CLAUDE.md §7「準心固定在畫面中央」衝突，腰射也要改成鏡頭射線
- 🔶 每發生成一個箭矢實體加一個物理投射物，600 RPM 等於每秒 10 個
  → 效能未知；M2 要比較「投射物」和「射線即時命中」兩種作法

---

## 4. 瞄準與鏡頭

**瞄準狀態 `AimThrow`**（`aimThrow.ws`）

- 進入時：
  - `theInput.SetContext( 'ThrowHold' )`（35）
  - 切換鏡頭控制器 `'AimThrow'`（36–37）
- `OnGameCameraTick( out moveData : SCameraMovementData, dt : float )`（161–394）：每幀更新鏡頭
  - 越肩偏移量依角度分成 4 種（195–264）
  - `SetDesiredPitch( moveData.pivotRotationValue.Pitch, 3.f )` 維持目前 pitch（361）
  - `SetDesiredHeading( moveData.pivotRotationValue.Yaw, 1.f )`（381）
  - `SetDesiredDistance( 1.f )`（385），`offsetZ = 1.5f`（388）

**瞄準射線 `UpdateThrowPositionBolt()`**（`playerAiming.ws:288–399`）

- **原版已經做了 CLAUDE.md §7 想要的防視差作法**：
  1. 讀取鏡頭方向和位置（316–317）
  2. 第一道射線：從鏡頭前方 0.5 公尺（324）射到 `MAX_THROW_RANGE`（326）
     → `CalculateAimPosition`（365）找出鏡頭中心對到的點
  3. 第二道射線：從玩家位置 +1.6 公尺（380–385）射向那個點（388）
     → 處理角色和目標之間的遮擋
- `CalculateAimPosition`（553–616）：
  - 用 `RayCastSync`（567）
  - 排除自己、自己的武器、死亡或昏迷的角色（583–589）
  - 取最近的命中點（598）
- 射線檢測的碰撞群組有 17 種（33–49）
- ✅ `MAX_THROW_RANGE = 25.0`（`gameParams.ws:105`）
  → 只有 25 公尺；AK 射程約 208 公尺，要用自己的長度

**瞄準慢動作**

- `SloMo()`（`playerAiming.ws:637–673`）：用 `theGame.SetTimeScale` 放慢時間
- `SLOWMO_SPEED = 0.6f`（164、167）
- 由 `OnAddAimingSloMo` 觸發（`rangedWeapon.ws:1408` → `playerAiming.ws:695–698`）
- → AK **要關掉**

**準心**

- `ShowCrosshair()`（`playerAiming.ws:208–219`），使用 `CR4HudModuleCrosshair`
- 原版只在 `PlayerAiming` 進入 `Aiming` 狀態時打開（`playerAiming.ws:187`），結束時由 `AimCleanup` 關掉（`:683-686`）
  - `hud.ws` 沒有其他單獨開關準心模組的程式（只有整個 HUD 的 `ForceShow`）
  - 另有主控台指令 `testcrosshair( true／false )`（`hudModuleCrosshair.ws:15-23`）

---

## 5. 可用 API 清單

只列實際找到的定義。「用例」是原版實際呼叫的位置。

### 5.1 射線檢測

| API | 定義 | 用例 | 說明 |
|---|---|---|---|
| `theGame.GetWorld().GetTraceManager()` | `world.ws:89` | `playerAiming.ws` | 取得 `CScriptBatchQueryAccessor` |
| `RayCastSync( start, end, out result : array<SRaycastHitResult>, groups )` | `physicsTraceManager.ws:34` | `playerAiming.ws:567` | **同步、多重命中、回傳元件** → 能知道打中哪個角色 |
| `RayCastDirSync( start, dir, dist, out result, groups )` | `physicsTraceManager.ws:35` | — | 用方向加距離 |
| `SRaycastHitResult`（position、normal、distance、component） | `physicsTraceManager.ws:10–16` | — | |
| `RayCastAsync` / `GetRayCastState` | `physicsTraceManager.ws:37–40` | — | 非同步版本 |
| `CWorld.StaticTrace( a, b, out pos, out normal, groups )` | `world.ws:18` | — | |
| `CWorld.StaticTraceWithAdditionalInfo(..., out material, out component, ...)` | `world.ws:20` | `r4Player.ws:12522`、`14573` | 回傳材質與元件 |
| `CWorld.SweepTest(...)` | `world.ws:24` | — | 球形掃掠 |

### 5.2 投射物

| API | 定義 | 說明 |
|---|---|---|
| `ShootProjectileAtPosition( angle, velocity, target, range, groups )` | `ProjectileTrajectory.ws:25` | `W3AdvancedProjectile` 包了一層（`advancedProjectile.ws:60–64`） |
| `ShootProjectileAtBone( angle, velocity, target, bone, range, groups )` | `ProjectileTrajectory.ws:31` | |
| `ShootProjectileAtNode(...)` | `ProjectileTrajectory.ws:28` | |
| `Init( caster )`、`StopProjectile()`、`IsStopped()` | `ProjectileTrajectory.ws:22`、`43`、`46` | |
| `projSpeed`、`projAngle`（`editable var`） | `advancedProjectile.ws:8–9`；腳本預設 10 / 5（25–26） | **實際值設在實體模板裡**（見第 6.3 節） |

### 5.3 傷害

| API | 定義 | 說明 |
|---|---|---|
| `W3Action_Attack` | `attackAction.ws:6` | |
| `W3Action_Attack.Init( attacker, victim, causer, weaponId, attackName, ..., optional crossId )` | `attackAction.ws:27` | 弩箭的呼叫方式見 `playerBoltProjectile.ws:70–71` |
| `action.SetHeadShot()` | 用例 `playerBoltProjectile.ws:81` | |
| `theGame.damageMgr.ProcessAction( action )` | 欄位 `r4Game.ws:342`；用例 `playerBoltProjectile.ws:84` | |
| `thePlayer.ApplyItemAbilities( id )` / `RemoveItemAbilities( id )` | 用例 `playerBoltProjectile.ws:64–67`、`91–94` | 傷害計算時暫時套用弩和箭的屬性 |

### 5.4 鏡頭

| API | 定義 | 說明 |
|---|---|---|
| `theGame.GetGameCamera() : CCustomCamera` | `r4Game.ws:261` | |
| `theCamera.GetCameraDirection()` / `GetCameraPosition()` | `cameraDirector.ws:26` / `20` | 用例 `playerAiming.ws:316–317` |
| `theCamera.GetCameraRotation()` / `GetCameraForward()` / `GetCameraHeading()` | `cameraDirector.ws:21`、`22`、`25` | |
| `OnGameCameraTick( out moveData : SCameraMovementData, dt )`（玩家狀態的事件） | 用例 `aimThrow.ws:161` | 🔶 **後座力最可能的注入點** |
| `SCameraMovementData`（`pivotRotationValue`、`pivotRotationController`…） | `customCameraControllers.ws:113–126` | |
| `ICustomCameraPivotRotationController.SetDesiredPitch` / `SetDesiredHeading` | `customCameraControllers.ws:30` / `29` | 用例很多，例如 `r4Player.ws:4448–4449` |
| `RotateHorizontal` / `RotateVertical` / `minPitch` / `maxPitch` | `customCameraControllers.ws:31–32`、`25–26` | |
| `CCustomCamera.GetActivePivotRotationController()` | `customCamera.ws:74` | |
| `CCustomCamera.GetCameraWorldRotation()` / `SetCameraWorldRotation( rot )` | `customCamera.ws:111` / `114` | |
| `CCustomCamera.GetCameraWorldOffset()` | `customCamera.ws:112` | 原版拍照模式取遊戲鏡頭的位置：`GetCameraWorldPosition() + GetCameraWorldOffset()`（`photomodeManager.ws:98-99`） |
| 每格直接改 `moveData.pivotRotationValue` | 用例 `explorationStateClimb.ws:2111-2135` | 爬牆鏡頭在 `OnGameCameraTick` 裡每格平滑後寫回（經 `r4Player.ws:4255`） |
| `CCustomCamera.fov` / `SetFov()` | `customCamera.ws:69`、`124–127` | 開鏡縮放用 |
| `CCamera.Rotate( leftRightDelta, upDownDelta )` | `camera.ws:77` | 🔶 另一個後座力候選；`CCamera` 和遊戲鏡頭的關係未確認 |
| `GCameraShake( strength, ... )`（全域函式） | `camera.ws:287–353` | 播放疊加的鏡頭動畫 `'camera_shake_hit_lvl3_1'`（339） |

### 5.5 計時、輸入、聲音、特效

| API | 定義 | 說明 |
|---|---|---|
| `AddTimer( name, period, optional repeats, ... )` | `entity.ws:19` | 連射計時 |
| `RemoveTimer( name )` / `RemoveTimers()` | `entity.ws:23` / `27` | |
| `timer function X( dt : float, id : int )` | 寫法例 `rangedWeapon.ws:438` | |
| `theGame.GetEngineTimeAsSeconds()` | `game.ws:58` | |
| `theInput.RegisterListener( obj, 'OnEvent', 'Action' )` | `inputManager.ws:39` | 新增按鍵 |
| `theInput.GetActionValue( 'Action' )` | `inputManager.ws:29` | |
| `theInput.SetContext( 'ThrowHold' )` | `inputManager.ws:42` | |
| `IsPressed( action )` / `IsReleased( action )` | `inputManager.ws:293` / `298` | |
| `entity.SoundEvent( "event" )` | `entity.ws:302` | 用例 `playerBoltProjectile.ws:379` |
| `theSound.SoundLoadBank( bank, async )` / `SoundIsBankLoaded( bank )` | `sound.ws:88` / `90` | 載入自訂音效庫（M4） |
| `entity.PlayEffect( 'name' )` | `entity.ws:261` | 槍口火光等（M5） |

### 5.6 物品

| API | 定義 | 說明 |
|---|---|---|
| `IsItemCrossbow( id )` = `category == 'crossbow'` | `inventoryComponent.ws:3882` | |
| `IsItemRangedWeapon( id )` = `IsItemCrossbow( id )` | `inventoryComponent.ws:3885` | |
| `IsItemBolt( id )` = `category == 'bolt'` | `inventoryComponent.ws:3897` | |
| `inv.GetItemAttributeValue( id, 'attr' )` | `inventoryComponent.ws:677` | |
| `GetDefinitionsManager().GetItemAttributeValueNoRandom( itemName, playerItem, attr, out min, out max )` | `definitionsManager.ws:50` | 讀 XML 自訂屬性（CCO 的作法） |
| `inv.GetCrossbowAmmo( id )` | `inventoryComponent.ws:4165–4172` | 讀十字弩的 `ammo` 屬性；✅ **原版腳本沒有任何呼叫者** |

---

## 6. 物品定義與實體模板

### 6.1 檔案位置

- ✅ `[D]\gameplay\items\def_item_weapons_crossbow.xml`（十字弩）
- ✅ `[D]\gameplay\items\def_item_bolts.xml`（弩箭）
- ✅ `[D]\gameplay\items_plus\` 裡的同名檔案**內容完全相同**
  - `items_plus` 多一個 `_ng_plus_item_extensions.xml`
  - ❓ `items_plus` 的用途：腳本和 `gameplay\globals` 都沒有引用；🔶 推測和 NG+ 有關

### 6.2 十字弩（以 `Crossbow 1` 為例，`def_item_weapons_crossbow.xml:103–127`）

| 欄位 | 值 | 行號 |
|---|---|---|
| `category` | `crossbow` | 105 |
| `hold_slot` | `l_weapon` | 111 |
| `equip_template` | `witcher_crossbow_lvl1` | 112 |
| `equip_slot` | `crossbow_back_slot` | 113 |
| `tags` | `Weapon, crossbow, mod_weapon` | 118 |
| `base_abilities` | `Default weapon _Stats`、`Crossbow 1 _Stats` | 120–122 |

- 能力 `Crossbow 1 _Stats`（9–12）：`attack_power`（mult 1.01）、`ammo`（add 3）
- **十字弩本身沒有傷害值**，只有 `attack_power` 倍率

### 6.3 弩箭（`Bodkin Bolt`，`def_item_bolts.xml:124–141`）

- `category="bolt"`、`stackable="1"`、`hold_template="bodkin_bolt"`（131）
- 標籤含 `InfiniteAmmo`（136）→ 無限彈藥
- 能力 `bodkin_bolt _Stats`（8–12）：`PiercingDamage` 5、`SilverDamage` 4

### 6.4 實體模板（`.w2ent`，CR2W 二進位，以字串搜尋取得證據）

| 檔案 | 找到的字串 | 結論 |
|---|---|---|
| `[D]\items\weapons\ranged\witcher_crossbow\witcher_crossbow_lvl1.w2ent` | `Crossbow`、`CBehaviorGraph`、`CAnimatedComponent`、`witcher_crossbow_base`、`bolt` | ✅ 類別是 `Crossbow`；有 `bolt` slot |
| `[D]\items\weapons\projectiles\witcher_bolts\bodkin_bolt.w2ent` | `W3BoltProjectile`、`projSpeed`、`bolt_base` | ✅ 類別是 `W3BoltProjectile`；模板裡覆寫了 `projSpeed` |

- 相關資源：
  - 行為圖 `[D]\gameplay\behaviors\items\crossbow\witcher_crossbow_lvl1.w2beh`
  - 動畫 `[D]\animations\items\weapon\witcher_crossbow_lvl1.w2anims`
- ❓ `projSpeed` 的實際數值（要在 REDkit 裡打開模板看）
- ❓ `equip_template` 名稱怎麼對應到檔案路徑（🔶 推測是用檔名）

---

## 7. 傷害系統重點

- 傷害來自**弩箭的傷害屬性**，再乘上**十字弩的 `attack_power`**
  - 計算時暫時套用兩者的屬性（`playerBoltProjectile.ws:61–68`、`88–95`）
- 攻擊名稱 `'bolt'` 會觸發十字弩技能：
  - `S_Sword_s26`（`damageManagerProcessor.ws:2075–2084`）
  - `S_Sword_s32` 爆頭加成（2086–2093、2439–2445、694）
- **原版爆頭沒有固定倍率**
  - 只增加暴擊率 `HEAD_SHOT_CRIT_CHANCE_BONUS`（`damageManagerProcessor.ws:847–851`），加上技能 `S_Sword_s32` 的加成
  - → CS2 的 4 倍爆頭倍率要自己實作
- 爆頭判定靠骨骼名稱：`head`、`neck`、`hroll`，人類的 `pelvis` 也算（`playerBoltProjectile.ws:78–82`）
- 敵人閃避訊號 `'Time2DodgeProjectile'`，依飛行時間發送（`playerBoltProjectile.ws:390–397`）

---

## 8. 參考 mod

| mod | 目標版本 | 腳本修改方式 | 覆寫原版檔數 | 編碼 |
|---|---|---|---|---|
| CompleteCrossbowOverhaul（CCO） | 舊版（2017） | 整檔覆寫 | 12 | UTF-16 LE |
| CCO base_game_steering | 舊版 | 整檔覆寫 | 1 | UTF-16 LE |
| Firearms（Roenaxx v1.1，2020） | 舊版 | 整檔覆寫 | 5 | UTF-16 LE |
| FirearmsNextGen（RickThedope） | 4.x | 整檔覆寫 | 5 | UTF-16 LE |
| MCME_Remastered | **5.x** | **新檔案 + annotation** | **0** | UTF-8 |
| Required_for_MCME_Remastered | — | 不是遊戲 mod | — | — |

- 舊版 mod 的覆寫檔已經過時，**不能直接拿來用**
  - 例如 CCO 的 `damageManagerProcessor.ws` 是 3038 行，5.x 原版是 4372 行

### 8.1 CompleteCrossbowOverhaul（`[R]\CompleteCrossbowOverhaul\modCrossbowRework\`）

覆寫的 12 個檔：`actor.ws`、`inventoryComponent.ws`、`gameParams.ws`、`damageManagerProcessor.ws`、`rangedWeapon.ws`、`petard.ws`、`signProjectiles.ws`、`hudModuleItemInfo.ws`、`characterMenu.ws`、`guiTooltipComponent.ws`、`playerAiming.ws`、`playerBoltProjectile.ws`。

下面行號都指 CCO 自己的檔案（路徑在 `content\scripts\game\...` 底下）。

**全自動（最重要）**

- `ToggleAutoFire()`（`rangedWeapon.ws:135–149`）
- `fire()`（151–169）：**直接從腳本呼叫 `OnProcessThrowEvent( 'ProjectileThrow' )`**（162），不等動畫事件
- `timer function AutoFire`（171–181）：按住時用 `AddTimer( 'AutoFire', Fire_rate )` 重新排程自己（176）
- 按鍵處理 `OnFireCrossbow`（46–69）：按下時開始連射，放開時停止

**彈匣與換彈**

- 欄位 `shotCount`、`maxAmmo`（27–29）
- 能不能射看 `maxAmmo - shotCount > 0`（161）
- 手動換彈 `OnManualReload`（70–76）→ `OnProcessThrowEvent( ..., force = true )` 把 `shotCount` 設成 `maxAmmo`（280–286）

**數值放在物品 XML**

- `GetCrossbowParam( param )`（518–529）
  - 用 `GetDefinitionsManager().GetItemAttributeValueNoRandom(...)` 讀十字弩的自訂屬性
- 用到的屬性：`Fire_rate`、`Range`、`Spread`、`Scope`、`Split`、`Reload`、`Special`
- ❓ XML 本體在 `blob0.bundle`（二進位）裡，沒有讀到

**散布**

- `playerBoltProjectile.ws:614–629`：在目標點的 X/Y/Z 各加 `RandRangeF( spread, -spread )`，偏移量依距離放大
- → 是方盒狀的隨機分布，**不是 CS 的圓錐散布**

**後座力**

- `recoil()`（`rangedWeapon.ws:121–133`）：只有 `GCameraShake` 震動，**沒有改變準心方向**

**開鏡**

- `Scope()`（531–549）：改 FOV（`SetFov( 60 / scope )`）
- 並透過 `CInGameConfigWrapper` 改滑鼠靈敏度

**按鍵**

- `RegisterListener` 註冊 `ManualReload`、`ScopeToggle`、`FireCrossbow` 等新動作（416–420）
- 綁定寫在 `Copy this to input.settings.txt`（UTF-16），分成多個情境
  - 例如 `[Combat]` 和 `[ThrowHold]` 都有 `IK_LeftMouse=(Action=FireCrossbow)`

**作者註明的已知問題**（41–45 行）

- 用原版操作方式時，自動十字弩在瞄準時會一直射
- 用新操作方式時，陶森特射擊比賽的靶子無效

### 8.2 CCO base_game_steering（`[R]\CompleteCrossbowOverhaul_base_game_steering\`）

- ✅ 和 CCO 主版本的 `rangedWeapon.ws` **只差第 40 行**：`default defaultSteering = true`
- 依作者註解（第 40 行）：
  - `true`：原版操作方式，放開「使用物品」鍵（預設滑鼠中鍵）時發射
  - `false`（主版本預設，作者推薦）：按下左鍵發射
- → **CLAUDE.md §4 原本寫「改成按住連射」不正確**，已更正

### 8.3 Firearms / FirearmsNextGen

- 槍 = `crossbow` 類別加上 `firearm` 標籤；子彈 = `bolt` 類別加上 `bullet` 標籤
  - `TAG_FIREARM` / `TAG_BULLET`（NextGen `gameParams.ws:279–280`、`317–318`）
- 以下行號指 NextGen 的 `rangedWeapon.ws`：
  - 彈藥種類檢查（51–89）；不相符時用 `ShowNotification` 提示（85）
  - **載入自訂音效庫**：`theSound.SoundLoadBank( "gun_sounds.bnk", true )`（67–70）
  - 換彈特效 `PlayEffect( 'reload' )`（123）
  - 射擊時：
    - `GCameraShake( 0.45, true, GetWorldPosition(), 2.0f )`（196）
    - 在武器實體上 `PlayEffect( 'sfx' )`、`'sfx2'`、`'cone'` / `'conel'`（197–212）
    - 🔶 這些特效定義在槍的 `.w2ent` 裡
- NextGen 和舊版比較：
  - `rangedWeapon.ws` 完全相同
  - 其他檔案只是把 mod 的修改重新合併到 4.x 的原版檔
  - → 4.x 的更新方式**仍然是整檔覆寫**
- 素材在 `DLC\DLCFirearms\content\*.bundle`（二進位）

### 8.4 MCME_Remastered（`[R]\MCME_Remastered\`）

**資料夾結構**

- `Mods\modMCME_Remastered\content\scripts\game\...`：41 個新 `.ws`，**沒有一個和原版同路徑**
- `Mods\modMCME_Remastered\content\scripts\local\`：2 個 annotation hook 檔
- `Mods\modMCME_Remastered\MCME.input.settings`：按鍵綁定（UTF-8）
- `DLC\DLCmod_spawn_companions\content\`：`blob0.bundle` 和 `metadata.store`
- `bin\config\r4game\user_config_matrix\pc\modMCMEBanterDelay.xml`：遊戲內選單設定

**annotation 寫法**（`local\MCME_RemasteredPlayerHooks.ws`）

- 檔頭註解（2–3 行）：「Replaces the legacy full r4Player.ws override with annotations.」
- `@addField(CR4Player)`：新增欄位，可以是 `saved var`（6–13）
- `@addMethod(CR4Player)`：新增方法（15–63），包括 `timer function`（65–87）
- `@wrapMethod(CR4Player)` 包住 `OnSpawned`，用 `wrappedMethod( spawnData )` 呼叫原本的邏輯（89–129）
  - 原版的 `OnSpawned` 是 `event`（`r4Player.ws:489`），但這裡寫成 `function`
  - `CActor.OnTakeDamage` 也是 `event`（`[S] game/actor.ws:2508`），同樣寫成 `function` 來包
  - 🔶 5.x 用 `@wrapMethod` 包 `event` 時，要寫成 `function`（MCME 已確認可在 5.x 運作）
- `@wrapMethod(CActor)` 包住 `OnTakeDamage`，再用 `(CR4Player)this` 縮小範圍（138–160）
- `NPCHooks.ws`：
  - `@addMethod` 加 `event`（79–87）
  - `@wrapMethod(CBTTaskRidingManagerHorseDismount)` 包住 `Main()`（217–218）

**其他**

- 按鍵：`theInput.RegisterListener( parent, 'OnKey_A', 'MCM_K_A' )`（`game\menu\MultiCompanionModMenuManager.ws:165` 起）
- ❓ 所有參考 mod 和已安裝 mod 都**沒有用到 `@replaceMethod`**，5.x 能不能用未確認

### 8.5 Required_for_MCME_Remastered

- ✅ 是 **Relapse's Mod Manager Redux（RMMR）2.4**，支援 5.x 的 mod 管理器（見 `Readme.md`）
  - 用 Python 3.12 + Qt 打包成 exe
- 功能：安裝與啟用 mod、調整載入順序、管理 `bin` 和 INI 設定、開啟 Script Merger
- 不是遊戲內容；這次沒有執行它

---

## 9. 舊版和 5.x 寫法的差異

| 項目 | 舊版（CCO、Firearms） | 4.x（FirearmsNextGen） | 5.x（MCME、已安裝 mod） |
|---|---|---|---|
| 改原版邏輯 | 整檔覆寫 | 整檔覆寫，重新合併到 4.x 原版 | `@wrapMethod` / `@addMethod` / `@addField` |
| 新增邏輯 | 寫在覆寫檔裡 | 同左 | 新檔案（不和原版同路徑） |
| annotation 檔位置 | — | — | `content\scripts\local\`（MCME、rationalcrafting、SortEverything、sharedutils 都這樣放） |
| `.ws` 編碼 | UTF-16 LE | UTF-16 LE | UTF-8 |
| 按鍵 | 叫玩家手動複製到 `input.settings` | 同左 | mod 資料夾放 `.input.settings` |
| 素材 | DLC 資料夾的 bundle | 同左 | DLC 資料夾的 bundle |

- 🔶 annotation 只包住需要的方法 → 比整檔覆寫更不容易和其他 mod 衝突
- ❓ `local` 資料夾名稱是不是必要
- ❓ 5.x 的 `.input.settings` 怎麼合併（遊戲自動處理，還是由 RMMR 處理）

---

## 10. 對 M1／M2 的建議

### M1（佔位 AK）

1. **物品定義**：新增一個物品
   - `category="crossbow"`
   - `equip_template="witcher_crossbow_lvl1"`：先借用十字弩的模型和實體
   - `tags`：`Weapon, crossbow`
2. **數值放在 XML 屬性**
   - 傷害倍率用 `attack_power`
   - 彈匣用 `ammo = 30`：`GetCrossbowAmmo()` 會讀它，原版又沒有人呼叫，不會影響原版
   - 射速等 CS2 數值可以用自訂屬性，用 `GetItemAttributeValueNoRandom` 讀（CCO 的作法）
3. **彈藥**：先借用 `Bodkin Bolt`（無限彈藥）
4. **放置位置**：見第 12 節
   - 物品 XML 放在自訂 DLC 資料夾，並由 `.reddlc` 掛載（`.reddlc` 要在 REDkit 建立）
   - 腳本 🔶 放在 `workspace\scripts\local\`，待實測

### M2（射擊機制）

- **腳本一律用 annotation**，不整檔覆寫原版
- **AK 的實體類別繼承 `Crossbow`**
  - 需要一個新的實體模板，在 REDkit 複製 `witcher_crossbow_lvl1.w2ent` 再改類別（使用者操作）
- **連射**：參考 CCO，用計時器加上直接觸發射擊，繞過動畫事件
- **命中方式要比較兩種**：
  - (a) 每發生成投射物（CCO 的方式）
  - (b) `RayCastSync` 即時命中，再直接建立 `W3Action_Attack`
  - 先測 600 RPM 下的效能
- **瞄準**：
  - 關掉慢動作
  - 射線長度改用 AK 射程（約 208 公尺），不用 `MAX_THROW_RANGE`（25 公尺）
  - 腰射也改用鏡頭射線，不要自動追蹤鎖定目標
- **後座力注入點候選**（都要實測）：
  1. 包住 `AimThrow` 的 `OnGameCameraTick`，修改 `moveData` 的 pitch / yaw
  2. `ICustomCameraPivotRotationController.SetDesiredPitch` / `SetDesiredHeading`
  3. `CCamera.Rotate`
- **爆頭 4 倍**要自己實作，原版沒有固定倍率

---

## 11. 未解問題

| # | 問題 | 影響 | 狀態 |
|---|---|---|---|
| 1 | REDkit 專案中，物品 XML 與腳本要放在哪裡；`useLooseScripts` 的意義 | M1 | **大部分已解**，見第 12 節；腳本的確切子資料夾仍待實測 |
| 2 | `equip_template` 名稱怎麼對應到檔案 | M1 | **部分已解**：模板目錄由 `CR4DefinitionsEntitieTemplatesDLCMounter` 掛載（第 12.3 節）；名稱比對規則仍 🔶 推測是檔名 |
| 3 | `bodkin_bolt.w2ent` 的 `projSpeed` 實際值 | M2 | 未解；在 REDkit 打開模板 |
| 4 | `theCamera` 的實際型別：原版呼叫了 `CCameraDirector` 才有的方法（`aimThrow.ws:32` 的 `GetTopmostCameraObject`，`cameraDirector.ws:30`），但 `<REDKIT_DIR>\bin\redscripts.ini` 寫 `theCamera=CCamera` | M2 | 未解；🔶 依原版用法應為 `CCameraDirector` |
| 5 | `@replaceMethod` 在 5.x 能不能用；`local` 資料夾是否必要 | M1 | **`@replaceMethod` 已用 wcc_lite 編譯通過**（第 12.5 節）；遊戲實際載入時 `local` 是否必要，M1 實測 |
| 6 | `.input.settings` 在 5.x 的合併方式 | M2 | 未解 |
| 7 | 每秒 10 個投射物的效能 | M2 | 未解；實測 |
| 8 | `items_plus` 的用途 | 低 | **已解**：NG+ 用的定義，由 `CR4DefinitionsNGPlusDLCMounter` 掛載（第 12.3 節） |
| 9 | CCO、Firearms 的 XML 內容（在 bundle 裡） | 低 | 未解；需要解包工具 |

---

## 12. REDkit 專案資料夾配置（2026-10-12 查證）

### 12.1 來源

- REDkit 官方 Wiki，用 Confluence 公開 REST API（`https://cdprojektred.atlassian.net/wiki/rest/api/content/<頁面ID>?expand=body.storage`）取得原文
  - 一般網頁在匿名存取時，內文會被截斷
- 引用的頁面：

| 頁面 | ID | 最後更新 |
|---|---|---|
| Starting the Editor | 6324341 | 2024-06-05 |
| Virtual depot and source control | 39190599 | 2024-06-17 |
| HOW-TO: Add items and attributes | 136445979 | 2024-11-22 |
| DLC Mods | 6328346 | 2024-04-19 |
| Publishing mods | 6328254 | 2024-04-16 |
| HOW-TO: Use ID spaces for localization modding | 6328202 | 2024-05-14 |
| WS: Create your first script mod | 36241465 | 2024-06-05 |
| WS: Script Compilation Errors overrides | 36241598 | 2024-06-05 |
| Changelog | 12058625 | **2026-10-01**（含 REDkit 5.0） |

- 本機證據：`<REDKIT_DIR>` 的程式檔字串、原版 DLC 範例 `[D]\dlc\dlc5\`
- 本機 REDkit 編輯器版本：`bin\x64_RedKit\editor.exe` = **5.0.0.1048625**

### 12.2 專案資料夾

- ✅ 新專案底下會有（Starting the Editor）：
  - `/workspace`：存放正在編輯的資產
  - `/publish`：最終輸出的 mod
  - 加上其他中繼和暫存資料夾
- ✅ 打包（cook）的輸出放在專案的 `\packed` 資料夾（Publishing mods）
- ✅ **虛擬 depot** 由三個實體資料夾合併而成，優先順序 `workspace > uncook > r4data`（Virtual depot）
  - Wiki 的例子：depot 路徑 `gameplay\abilities\witch\` 對應到 `Z:\myModProject\workspace\gameplay\abilities\witch\`
  - 只存在 workspace 的檔案，狀態是 **added**（使用者新增）
  - check out 會把 r4data 的檔案複製到 workspace 的相同路徑
- 本專案目前**還沒有** `workspace\`
  - 🔶 推測第一次在 Asset Browser 新增或 check out 檔案時才會建立
- ✅ `idSpace: 10000000`（`.w3edit`）是專案字串 ID 的起點，官方規定最小 1000 萬（ID spaces 頁）
- ✅ `LocalEditorStringDataBaseW3_UTF8_mod.db` 是專案的字串資料庫
  - 匯出的 CSV 會放在它旁邊，檔名是 `LocalEditorStringDataBaseW3_UTF8_mod_export.csv`

### 12.3 物品 XML：要放在自訂 DLC 裡，並用 `.reddlc` 掛載

- ✅ 建議**新建自己的 XML**，不要改原版的 `def_item_*.xml`（Add items 頁）
- ✅ 原文：「You need to mount every new .xml file so that it can be visible to the engine … create new .reddlc file」
- ✅ 在 Asset Browser 的 `dlc` 底下建立子資料夾（名稱不能是 bob、ep1、dlc1–16），REDkit 會自動把它打包成 DLC（DLC Mods 頁）
  - 本專案 `.w3edit` 的 `excludedDlc` 列了 `dlc1`–`dlc20`、`ep1`、`bob`
- ✅ `.reddlc` 是 **CR2W 二進位檔**，類別是 `CDLCDefinition`
  - → **只能在 REDkit 編輯器裡建立**
- ✅ 原版範例 `[D]\dlc\dlc5\dlc5.reddlc`（以字串搜尋取得）：

| mounter | 參數 | 值 |
|---|---|---|
| `CR4DefinitionsDLCMounter` | `definitionXmlFilePath` | `dlc\dlc5\data\gameplay\items\dlc5_items.xml` 等 |
| `CR4DefinitionsNGPlusDLCMounter` | — | `dlc\dlc5\data\gameplay\items_plus\...` |
| `CR4DefinitionsEntitieTemplatesDLCMounter` | `entitieTemplatesDirectoryPath` | `dlc\dlc5\data\horse_items\`、`dlc\dlc5\data\items\bodyparts\geralt_items\` |
| `CR4ScaleformContentDLCMounter` | `scaleformDirectoryPath` | `dlc\dlc5\data\gameplay\gui_new\`（圖示） |

- ✅ dlc5 的資料夾結構：

```
dlc\dlc5\
  dlc5.reddlc
  data\gameplay\items\dlc5_items.xml
  data\gameplay\items_plus\dlc5_items.xml
  data\items\...（實體模板 .w2ent）
  data\gameplay\gui_new\icons\...（圖示）
```

- ✅ REDkit 5.0 新增 **XML 細部覆寫**：XML 條目可加 `onConflict` 屬性，值為 `default`（重複定義就報錯）、`replace`、`extend`（Changelog）

### 12.4 腳本

- ✅ 原文：「To use annotation, create a new .ws file for your mod or workspace with your annotated code」（Script Compilation Errors overrides 頁）
- ✅ 官方文件列出的 annotation：`@wrapMethod`、`@addMethod`、`@replaceMethod`（也能取代全域函式）、`@addField`
- ✅ REDkit 5.0 的腳本更新（Changelog）：
  - **scope-based overrides**：新檔案只要指定範圍（例如類別），就能新增或覆寫函式
  - **script blobs**：腳本 mod 可以編譯成小型 blob，在遊戲啟動時載入
    - 🔶 `.w3edit` 的 `useLooseScripts: false` 應該就是指這個
  - 原生函式可以包（wrap）；**`event` 和 state 可以正式加 annotation**
  - 「Now scripts are part of REDKit, please make sure that no vanilla scripts are part of the depot.」
- ✅ 不經過 REDkit、手動做的腳本 mod 放在 `<遊戲>\mods\modXXXX\content\scripts\local\*.ws`（Create your first script mod 頁）
- 🔶 **REDkit 專案裡的腳本應該放在 `workspace\scripts\...`**
  - 理由：原版腳本在 depot 的 `scripts\` 底下（`[D]\scripts\`），而 workspace 會照 depot 路徑存放檔案
  - 建議用 `workspace\scripts\local\`，和 5.x mod 的慣例一致
  - **尚未實測**；Wiki 沒有寫出確切子資料夾
- ✅ Script Studio 也有自己的「Workspace」設定（`bin\x64_RedKit\scriptStudio.exe` 的字串）：
  - 「Workspace: Location on your computer where you would like the mod to reside. This should be away from the installation folder of your game」
  - 編譯選項：
    - `Use existing scripts`
    - `Install Mod`（編譯前先把 mod 腳本安裝到遊戲）
    - `Use Workspace scripts`（強制遊戲只用 workspace 的腳本）

### 12.5 命令列編譯腳本（wcc_lite）

- ✅ REDkit 5.0 新增「compile scripts」指令（Changelog）
- ✅ 用法（`bin\x64_RedKit\wcc_lite.exe` 內的說明字串）：

```
compilescripts <source_dir> <options>
  -out=<outputpath>             - Output path
  -patch=<patch_source_dir>     - Blob source scripts (output will be a .rsblob)
```

- 輸出檔名：完整編譯是 `cooked-<CRC>.redscripts`，patch 是 `blob.rsblob`
- 🔶 可以用來在遊戲外檢查 mod 腳本能不能編譯：
  - `<source_dir>` 指向原版腳本，`-patch` 指向我們的腳本

**2026-10-12 試跑結果（只編譯原版，沒有 `-patch`）**

- 指令（PowerShell）：

```
Start-Process "<REDKIT_DIR>\bin\x64_RedKit\wcc_lite.exe" `
  -ArgumentList 'compilescripts "<REDKIT_DEPOT>\scripts" -out=<輸出資料夾>' `
  -WorkingDirectory "<REDKIT_DIR>\bin\x64_RedKit"
```

- ✅ 成功：`Success! Scripts cooked to '...\cooked-000000007b8d4486.redscripts'`（7,973,538 bytes）
  - 實際編譯約 **21 秒**；原版本身有 362 個警告
  - 17 個 Error 都是環境訊息（缺設定檔、port 37000 被開著的 REDkit 編輯器占用等），不是腳本錯誤
- ⚠️ **第一次執行會跳出 EULA 視窗**，要使用者本人在畫面上確認，否則會一直等待
  - EULA 內文：`<REDKIT_DIR>\bin\x64_RedKit\wcc_eula.rtf`
  - ❓ 同意紀錄會不會保存，下次執行還會不會再跳，尚未確認
- ⚠️ **工作目錄一定要設成 `bin\x64_RedKit`**
  - 紀錄檔寫在相對路徑 `..\wcc.log`
  - 從專案資料夾執行時，紀錄檔寫到了 `D:\OneDrive\Desktop\wcc.log`（已刪除），而且 EULA 內文讀不到
- ⚠️ **副作用**（依修改時間判斷，只算這次執行期間）：

| 檔案 | 變化 |
|---|---|
| `<REDKIT_DIR>\bin\wcc.log` | 新建（紀錄檔） |
| `<REDKIT_DIR>\bin\LocalEditorStringDataBaseW3_UTF8_mod.db` | 新建，32 KB 的空字串資料庫（0 筆字串）；**已刪除** |
| `<REDKIT_DEPOT>\x64.release.redscripts` | **被覆寫**（腳本編譯快取，說明見下方） |

**`x64.release.redscripts` 是什麼**

- 1525 個原版 `.ws` 編譯後的快取
- 依 `wcc.log` 的時間順序，寫入發生在**引擎啟動階段**，不是 `compilescripts` 指令本身造成的：
  - 19:17:18 Loading scripts（解析 `r4data\scripts`）
  - 19:17:25 Rebuilding script data caches
  - **19:17:26.200 檔案寫入**
  - 19:17:26 之後才開始執行 `compilescripts`
- 其他引擎啟動也有同一步「Rebuilding script data caches」：
  - REDkit 首次設定時的 uncook（`uncook 2026-10-12 15-24-20.log`）
    - 15:24:32 在「Parsing 0 script files」的狀態下執行，檔案正好在這一秒建立
  - REDkit 編輯器啟動時（`editor.log` 15:46:20）
- 🔶 結論：這是**每次啟動引擎都會重建的快取**，這次覆寫的影響和平常開一次 REDkit 一樣
- 這次是從**沒有變動過**的 `r4data\scripts` 重建的
  - 執行期間，`r4data\scripts` 裡沒有任何檔案被修改（用時間標記檔搜尋確認）
- 覆寫後的檔頭和我們的輸出完全相同（含 REDkit 版號 `1048625` 與同一組時間戳記）

**加上 `-patch` 的實測（2026-10-12，共 5 次）**

- ✅ **快取不受影響**：
  - 每次執行，快取的修改時間都會更新，但 **SHA256 都一樣**（`3DE856E6…`）
    → 從同一份原版腳本重建，每次產出完全相同
  - 每次都在快取裡搜尋測試腳本的識別字（`gfg_test` 等），**都找不到**
  - 對照組：成功時輸出的 `blob.rsblob`（642 bytes）裡**找得到**這些識別字
- ✅ 第二次之後**不再跳出 EULA**（同意紀錄有被保存）
- 每次約 **20 秒**
- `-patch` 資料夾會**遞迴**找 `.ws`，所以放在 `local\` 子資料夾裡也找得到

**已驗證的 annotation 寫法（REDkit 5.0 編譯器）**

| # | 寫法 | 結果 | 錯誤訊息（寫錯時） |
|---|---|---|---|
| 1 | `@wrapMethod(CR4Player) function OnSpawned(...)`：用 `function` 包 `event` | ✅ | — |
| 2 | `@wrapMethod(...) event OnEnableAimingMode(...)`：用 `event` 關鍵字 | ❌ 語法錯誤 | `unexpected TOKEN_EVENT, expecting TOKEN_FUNCTION` |
| 3 | `@wrapMethod(CR4PlayerStateAimThrow) function OnGameCameraTick(out moveData : SCameraMovementData, dt : float)`，內容 `return wrappedMethod(moveData, dt);` | ✅ **state 的方法可以包** | — |
| 4 | 同上，但加上 `: bool` | ❌ | `Event function ... should not have an explicit return type. It is implicitly always bool.` |
| 5 | `@addField(Crossbow) var ...`、`@addMethod(Crossbow) public function ...` | ✅ | — |
| 6 | `@replaceMethod(Crossbow) function ResetShotCount()` | ✅ | — |
| 7 | `@replaceMethod(Crossbow) protected function ...`（加存取修飾詞） | ❌ 語法錯誤 | `unexpected TOKEN_PROTECTED, expecting TOKEN_FUNCTION` |
| 8 | `exec function gfg_test()`（主控台指令） | ✅ | — |
| 9 | UTF-8（無 BOM）檔案、含繁體中文註解與字串 | ✅ 編譯器接受；但 **REDkit 專案要求加 BOM**，見 §12.7 | — |
| 10 | 包住不存在的方法 | ❌（預期中） | `@wrapMethod cannot wrap 'CR4Player::...' because it is not defined.` |
| 11 | 使用未宣告的變數 | ❌（預期中） | `I dont know any '...'` |

- state 的類別名稱 = 父類別 + `State` + 狀態名，例如 `state AimThrow in CR4Player` → `CR4PlayerStateAimThrow`

**錯誤訊息的特性**

- 只有行號 `[N]`，**沒有檔名**
- 編譯分階段（語法 → annotation → 函式內容），**前一階段失敗，後面的錯誤就不會顯示**
  - 例：同一次編譯裡同時有第 10、11 項的錯誤，只會報出第 10 項

**工具**：`tools/wcc_compile.py`

- 用法：`python -X utf8 tools/wcc_compile.py [patch 資料夾]`，預設 `workspace/scripts`
- 失敗時會列出每個檔案的第 N 行，方便找出錯的位置
- 回傳值：0 成功、1 編譯失敗、2 找不到 `.ws`、3 逾時（第一次執行時可能是卡在 EULA）

### 12.6 其他：Wwise 版本

- ⚠️ Changelog（REDkit 5.0）原文：「REDkit now requires Wwise 2023 with the Mastering Suite and Motion plugins installed.」
- → CLAUDE.md §3 原本寫的「Wwise 2021.1.7.7796（必須剛好這版）」對 REDkit 5.0 已經過時
- 確切的 2023 版號仍待查（Wiki 的 Wwise 頁面可能還沒更新）

### 12.7 專案檔案的編碼：一律 UTF-8 加 BOM

- ✅ 2026-10-12 重開 REDkit 專案時跳出：
  - 「Your mod project contains files with invalid encoding. Do you want your script and xml files in your mod project to be converted to utf-8 now?」
- 當時專案裡的檔案：
  - `workspace\scripts\local\gfg_m1_test.ws`：UTF-8、**無 BOM**、含中文、LF 換行
  - `workspace\dlc\gunforgeralt\data\gameplay\items\gunforgeralt_items.xml`：UTF-8、**有 BOM**、純 ASCII、CRLF 換行
- 使用者按下「Yes」，前後比對結果：
  - `.ws`：**只加上 UTF-8 BOM**（239 → 242 bytes）；6 行內容完全不變，中文沒有變亂碼；換行還是 LF
  - `.xml`：完全沒動
- → **結論：REDkit 要求專案裡的 `.ws` 和 `.xml` 是 UTF-8 加 BOM**；換行方式不影響
  - wcc_lite 編譯時，有沒有 BOM 都可以（§12.5）
  - 原版 `r4data\scripts` 的 1525 個 `.ws` **全部沒有 BOM**（2026-10-12 統計），但它們不在專案裡，不受這個檢查
- `tools/wcc_compile.py` 編譯前會檢查並警告缺 BOM 的檔案

---

## 13. M1 第一步實測（2026-10-12）

### 13.1 結果

- ✅ `additem('gfg_ak47', 1, true)` 成功，裝備後能正常射擊
  - 紀錄：`Item gfg_ak47 attached to ... player433 with item entity spawned`
- ✅ `workspace\scripts\local\gfg_m1_test.ws` 的 `gfg_hello()` 可以執行，HUD 有顯示訊息（測試完已刪除，commit `31503ec`）
  - → **REDkit 專案的腳本放在 `workspace\scripts\local\` 會被遊戲載入**（§12.4 的推測已確認）
  - 紀錄裡會出現 `StringKeyMiss: '<訊息文字>'`：`DisplayHudMessage` 會先把文字當成翻譯鍵值去查，查不到才直接顯示

### 13.2 DLC 定義檔（`.reddlc`）一定要有 `id`

- `CDLCDefinition` 的 `id` 欄位（型別 `CName`）沒填時，紀錄出現：
  - `[Error][Game] [DLC] DLC definition from 'dlc\gunforgeralt\test.reddlc' has empty DLC ID`
  - 整個 DLC 被拒絕，mounter 不會掛載
- 原版範例：`dlc5.reddlc` 的 `id` = `dlc_005_001`，`dlc1.reddlc` = `dlc_001_001`
- 本專案：`id` = `gunforgeralt`

### 13.3 新 DLC 要「之後的啟動」才會掛載

| 時間 | 紀錄 |
|---|---|
| 21:18:07 | `Found new DLC '' (id: 'gunforgeralt', ...)`、`Set initial state of DLC 'gunforgeralt' to ENABLED`、`Mounted 163 DLC mounter(s).` |
| 21:22:16 | `Mounted 163` |
| 21:26:01 | **`Mounted 164`**，並 `Reading defs from file: 'dlc\gunforgeralt\data\gameplay\items\gunforgeralt_items.xml'` |

- → 第一次掃描到新 DLC 時只登記並啟用，**之後再啟動遊戲才會真正掛載**
- 啟用狀態會被記住，之後每次啟動都會掛載

### 13.4 從 REDkit 啟動的遊戲

- 讀存檔（`load a saved game`）時，會播放存檔的前情提要影片（storybook，例：`cutscenes\storybook\st_4.usm`，約 32 秒），同時讀取存檔；整個過程約 36 秒
- 讀存檔後，存檔所在的世界會留在編輯器裡；**不要儲存對原版世界的任何變更**
- 不會載入平常裝的 mod（含 mod.io 的 mod），存檔用過 mod 時，左上角會顯示 `PLAYING FROM A SAVE GAME THAT USED MODS`
- 畫面上的除錯資訊：FPS、`F8 key opens Debug Windows`、`SAVE LOCKS ACTIVE NOW` 等
  - `SAVE LOCKS` 是原版十字弩的禁止存檔鎖：`RangedWeapon`（`rangedWeapon.ws:421`）、`AimThrow`（`aimThrow.ws:25`），不是錯誤
- Print Screen 綁定 `ScreenshotRequested`（`bin\config\r4game\legacy\base\input_qwerty.ini`），由引擎處理
  - 按下後，物品欄 3D 預覽出現 `Broken parrent attachment in '...PreviewEntity::witcher_crossbow_lvl1'`
  - 🔶 只影響預覽模型；紀錄沒有物品被移除
  - 測試時截圖改用 Win + Shift + S
- 調時間：遊戲內冥想，或主控台 `TM(60)`（`temp.ws:1027`），用完 `TM(0.25)` 恢復預設（`r4Game.ws:682`）

### 13.5 原版的已知訊息（不是我們造成的）

- 用 `additem(..., true)` 換掉身上的十字弩時：
  - `hudModuleDamagedItems.ws(103)`：`damagedItems[ slot - 1 ]` 陣列越界（`Index 16 is out of bounds`）
  - `rangedweapon.ws(536)`：銷毀舊十字弩上的箭
  - `Custom orientation cannot be removed, stack is already empty`
- 物品說明的重量 = `0.01 + 重量 × 數量 × 0.5`（`inventoryComponent.ws:4123`）
  - 例：`Crossbow 1`（1.53）顯示 0.77；`gfg_ak47`（3.5）顯示 **1.76**（實測確認）

### 13.6 REDkit 在 workspace 建立的空資料夾

- 第一次用 `load a saved game` 啟動時（21:07:58），REDkit 在 `workspace\levels\novigrad\` 建了 `source_foliage\`、`streaming\temp\` 等**空資料夾**
- 裡面沒有任何檔案；git 不追蹤空資料夾
- 🔶 應該是世界的工作或暫存資料夾；之後若出現暫存檔，再加進 `.gitignore`

### 13.7 改動後要怎麼重新載入（`editor.log` 證據）

| 時間 | 動作 | 讀存檔 | 讀我們的 XML（`Reading defs from file: 'dlc\gunforgeralt\...'`） | 到 `OnGameStarted` |
|---|---|---|---|---|
| 21:29:41 | 編輯器啟動（`OnEditorStarted`） | — | ✅ | — |
| 21:31:38 | 啟動遊戲 | ✅ `Loaded QuestLoadingVideo ... from save` | ✅ | 21:32:13（約 35 秒） |
| 21:32:55 | 回到編輯器（`OnEditorStarted`） | — | ✅ | — |
| 21:33:01 | 啟動遊戲 | ❌ | ✅（21:33:05） | 21:33:12（約 11 秒） |
| 21:53:57 | 啟動遊戲 | ❌ | ✅ | 21:54:05（約 8 秒） |

- → **每次啟動遊戲、回到編輯器都會重新掛載 DLC、重新讀 XML**；改 XML 後不需要讀存檔，用 `play game` / `Fast` 重新啟動即可
- 同一場遊戲中重新載入物品定義：
  - 原版腳本沒有相關的 exec 指令（只有 `ForceHudScaleRefresh`、`debugRefreshModioMutedUsersList`）
  - REDkit 5.0 Changelog 只提到「Gwent definitions are reloadable now」
  - **但 REDkit 編輯器有選單「Reload Game Definitions」**（`bin\x64_RedKit\editor.exe` 內的介面設定字串）：
    - 說明文字：「Reload definitions (items, abilities, etc.)」，內部名稱 `menuReloadDefinitions`
    - 位置：主編輯器 **Tools → Loot Editor...** 打開的 Loot Editor 視窗裡的 **Tools** 選單
    - Wiki「TOOL: Loot Editor」（頁面 6328941）沒有提到這個選單
    - ❓ 遊戲進行中使用是否生效，**尚未實測**
- 腳本：Script Studio 可熱重載（Wiki「WS: Script Studio basics」：「you can change the code while the game is running in the Editor」）
- 不讀存檔、直接開世界：Wiki「Load an existing world」（頁面 6324517）
  - **File → Open World**，選 `.w2w`（例：`levels\novigrad\novigrad.w2w`）
  - 編輯器預設只顯示地形與植被；Scene Explorer 對最上層的世界資料夾按右鍵 → **Load all in group** 才會載入所有圖層
  - `play game`：依串流資料載入圖層，Geralt 出生在 0,0,0；`Fast`：只用目前已載入的圖層，Geralt 出生在鏡頭位置（Wiki「Start the game from the editor」）
- ❓ REDkit 重開時會不會自動打開上次的世界，未確認

### 13.8 M1 完成（2026-10-12）

- `gfg_ak47` 的 `attack_power` 改為 2.02 後，物品說明顯示 **+202%**（原本 +101%），使用者實測確認
- M1 四個完成條件：主控台可取得 ✅、可裝備 ✅、可射擊 ✅、數值有變 ✅
- 尚未改的部分：顯示名稱仍借用原版 `item_name_crossbow_1`，外觀仍是原版十字弩

### 13.9 測試用世界的選擇（2026-10-12 實查）

- Wiki「Learn from the reference level」（頁面 6325117）：REDkit 提供**專門的參考關卡**
  - 原文：「you can first use try them out on a dedicated reference level」「Take advantage of them as examples to be studied and tested!」
  - 路徑：`engine\reference_level\world\reference_level.w2w`（depot 實際存在）
  - 開啟後看不到區域或物件時，Wiki 指向「HOW-TO: Change display settings」
- Wiki「Load an existing world」：「The larger the level, the more time it can take to load.」
- `<REDKIT_DEPOT>` 內各世界資料夾的資料量：

| 世界 | 總大小 MB | 檔案數 | 圖層 `.w2l` | 地形格 `.w2ter` |
|---|---|---|---|---|
| `engine\reference_level` | 1526 | 1754 | 48 | 100 |
| `levels\island_of_mist` | 209 | 1312 | 73 | 16 |
| `levels\wyzima_castle` | 252 | 1535 | 189 | 81 |
| `levels\prolog_village_winter` | 1596 | 3680 | 640 | 256 |
| `levels\prolog_village` | 1689 | 4648 | 1534 | 256 |
| `levels\kaer_morhen` | 3014 | 4554 | 1142 | 256 |
| `levels\skellige` | 3975 | 15734 | 6578 | 1024 |
| `dlc\bob\data\levels\bob` | 4208 | 18610 | 8305 | 1024 |
| `levels\the_spiral` | 5238 | 3733 | 197 | 576 |
| `levels\novigrad` | 6907 | 31150 | 13754 | 2116 |

- 實測載入時間（`editor.log` 的 `World loaded in`）：

| 世界 | `World loaded in` | 紀錄時間 |
|---|---|---|
| `levels\novigrad` | 2.95 秒、2.91 秒、1.97 秒 | 21:31:38、21:54:51、22:34:30 |
| `levels\kaer_morhen` | 1.10 秒 | 21:53:57 |
| `engine\reference_level` | **0.20 秒** | 22:33:47 |

  - reference_level 開好後啟動遊戲：22:33:56 `OnEditorStopped` → 22:33:57 `OnGameStarted`

### 13.10 腳本什麼時候被編譯（`editor.log` 證據）

| 時間 | 紀錄 |
|---|---|
| 21:29:22 | REDkit 啟動：`Parsing 1525 script files...`（原版） |
| 21:29:29 | `Parsing 1 script files...`（workspace 裡的 `gfg_m1_test.ws`，另外編譯） |
| 21:45:25 | 刪除 `gfg_m1_test.ws`（commit `31503ec`） |
| 21:54～22:34 | 啟動遊戲 6 次，**都沒有** `Parsing ... script files` |

- → 新增、刪除或修改腳本檔後，**只重開遊戲不會重新編譯**；重開 REDkit 會（23:49 重開後的紀錄也確認）
- ⚠️ **更正（2026-10-13）**：原本寫「要重開 REDkit 才會被編譯」是錯的——只觀察到「重開遊戲不會編譯」，沒有去找重新載入的功能
  - REDkit 與 Script Studio 都有「Reload scripts」選單，見 §13.14

### 13.11 M2 第一步：彈匣 30 發（實作，待遊戲內測試）

- `gunforgeralt_items.xml`：物品標籤加上 `gfg_ak47`
- `workspace/scripts/local/gfg_ak47.ws`：
  - `@addMethod(Crossbow) GfgIsAk()`：裝備欄的十字弩（`GetItemEquippedOnSlot(EES_RangedWeapon, ...)`，`playerWitcher.ws:5963`）是否有 `gfg_ak47` 標籤（`ItemHasTag`，`inventoryComponent.ws:636`）
  - `@addMethod(Crossbow) GfgMagazineSize()`：讀 XML 的 `ammo`（`GetCrossbowAmmo`，`inventoryComponent.ws:4165`）
    - `Default weapon _Stats` 是空的（`def_item_weapons.xml:9`），所以讀到的就是 `gfg_ak47 _Stats` 的 30
  - `@wrapMethod(Crossbow) PlayOwnerReloadAnim() : bool`：AK 射滿彈匣才播換彈動畫，其餘條件照抄原版（`rangedWeapon.ws:830-852`）；每次判斷用 `LogChannel('GFG', ...)` 寫入 `editor.log`（格式 `[Info][Script_GFG]`，對照 `guiPaperdollInventoryComponent.ws:18`）
- wcc_lite 編譯通過（第一次就通過）；新驗證的寫法：
  - `@wrapMethod` 可包帶回傳型別的 protected 函式（`function PlayOwnerReloadAnim() : bool`）
  - 新增與包裝的方法可存取原版 protected 成員（`shotCount`、`previousAmmoItemName`、`ownerPlayerWitcher`、`SetBehaviorGraphVariables`、`GetSpecialAmmoCount`）

### 13.12 十字弩的需求等級由 `attack_power` 決定

- 物品等級：十字弩只看 `attack_power`（`inventoryComponent.ws:359-361`）
- 換算表（`gameParams.ws:998-1016`，最後再減 1，最小 1）：

| `attack_power`（mult） | 表內等級 | 需求等級（減 1） |
|---|---|---|
| ≤ 1.01 | 1 | 1 |
| > 1.01 | 2 | 1 |
| > 1.1 | 4 | 3 |
| > 1.2 | 8 | 7 |
| > 1.3 | 11 | 10 |
| > 1.4 | 15 | 14 |
| > 1.5 | 19 | 18 |
| > 1.6 | 22 | 21 |
| > 1.7 | 25 | 24 |
| > 1.8 | 27 | 26 |
| > 1.9 | 32 | **31** |

- 裝備檢查：物品等級 > 玩家等級就不能裝備（`r4Player.ws:11727-11745` `HasRequiredLevelToEquipItem`；有 `EET_WolfHour` 時放寬 2 級）
- 目前 `gfg_ak47` 的 `attack_power` = 2.02 → **需求等級 31**；`Fast` 啟動的 Geralt 等級不夠（2026-10-12 使用者回報無法裝備）
- 測試時可用主控台 `setlevel(31)`（`playerCheats.ws:162-182`：加經驗值直到目標等級，只升不降）
- → M2 設計傷害時要考慮：`attack_power` 會同時改變需求等級

### 13.13 M2 全自動：第一次實測（`editor.log` 2026-10-12 23:53～23:55）

- 實作（commit `0ba8bd7`）：AK 是選用物品時，左鍵＝扳機；按住時每 0.1 秒（`AddTimer`）呼叫一次 `OnProcessThrowEvent('ProjectileThrow')`；打空時觸發 `Crossbow_Reload`
- 結果：
  - 每次按下都有 `trigger=true`、放開都有 `trigger=false`；只在按住時開火
  - 連射到第 30 發 → `playReloadAnim=true` → `magazine empty: Crossbow_Reload raised`；換彈後 `shotCount=0`，可以再連射
  - 點放：23:55:37、23:55:38 各按一次，各開 1 發
- **射速只有 540 RPM**（目標 600）：
  - 94 發、81 個連射間隔，平均 **0.1111 秒**
  - 間隔只有兩種：0.100 秒（29 次）、約 0.117 秒（51 次），另有 1 次 0.145
  - 0.100 = 6/60、0.117 ≈ 7/60 → 計時器在**畫面邊界**觸發，而且**超過的時間不會累計到下一次**（否則平均應為 0.100）
- **打空後繼續按住會打斷換彈**（第 31～34 發，每 0.78 秒一發，狀態 `State_WeaponReload`）：
  - 換彈動畫中段的動畫事件 `'OnWeaponReload'` 就會裝上新箭（`rangedWeapon.ws:150-152` → `81-88` → `ReloadWeapon` `338-363`；log `Equipped bullet item Bodkin Bolt`）
  - `shotCount` 要等 `OnWeaponReloadEnd` 才歸零（`r4Player.ws:14737` → `rangedWeapon.ws:697-703`）
  - 我們的計時器一看到箭就開火 → `shotCount` 31 ≥ 30 → 又觸發換彈，循環到放開為止
- 收槍中按左鍵（23:55:41，`State_WeaponHolster`）：不開火；收完（`State_WeaponWait`）也不會自己拿出來，要放開再按（**未修**）
- `Couldn't find item 'draw' anim action for item 'gfg_ak47'`：原版 `Crossbow 1`（23:27:53）、`Geralt fists`（23:55:25）也有 → 不是我們造成的
- 判讀注意：`editor.log` **不是依時間排列**
  - 23:49 重開 REDkit 後：第 1～385 行是 23:13 的內容，接著才是本次（23:49～），本次之後還殘留 23:23～23:48 的舊內容
  - → 要用時間戳切出本次的範圍再分析

**修正（2026-10-13，wcc_lite 編譯通過，未進遊戲測試）**

- 換彈中（`State_WeaponReload`）不開火
- 射速：下一發時間 = 上一發的預定時間 + 0.1 秒（`theGame.GetEngineTimeAsSeconds()`，`game.ws:58`）；停過火才從現在起算
- 計時器改成每個畫面檢查（`AddTimer(..., 0.001f, true)`，寫法同 `rangedWeapon.ws:1248`）
- 按下時立刻檢查第一發（原本要等 0.1 秒，按放短於 0.1 秒會一發都沒有）

### 13.14 重新編譯腳本的方法（2026-10-13 查證；REDkit 選單已實測）

- **REDkit：Tools → Debuggers → Reload scripts**（✅ **遊戲進行中可用**，實測見本節最後）
  - 證據：`bin\x64_RedKit\editor.exe` 內嵌的 wxWidgets 選單定義（XRC）
    - `UniversalFrameMenuBar` → `toolsMenu`（`_Tools`）→ `debugMenu`（`Debuggers`）→ `reloadScripts`
    - 標籤 `Reload scripts`；說明 `Reload and recompile scripts`；沒有預設快捷鍵（`<accel/>` 空白）
  - 同一個子選單還有：
    - `Reload resource definitions`（說明 `Reload resource definitions (xml files)`）
    - `Reload game definitions`（說明 `Reload definitions (items, abilities, etc.)`）——§13.7 記的 Loot Editor 視窗裡也有一個
- **Script Studio：Debug → Reload scripts，快捷鍵 F7**
  - 程式：`bin\x64_RedKit\scriptStudio.exe`（REDkit 的 Tools → Script Studio... 開啟）
  - 證據：`scriptStudio.exe` 內嵌選單 `MainMenu` → `debugMenu`（`_Debug`）→ `debugReloadScripts`，標籤 `_Reload scripts\tF7`
  - 工具列也有 `Reload` 按鈕（提示文字 `Reload scripts`）
  - 同選單還有 `Forget compilation action choice`
- Wiki「WS: Script Studio basics」（頁面 36864027，第 3 版，2024-06-06）原文：
  - 「Script Studio allows you to place breakpoints in your code and hot reloads your code - which means you can change the code while the game is running in the Editor.」
  - 「Script Studio connects to the game automatically.」
- 引擎支援執行中重新載入：`editor.exe` 有實體事件 `OnScriptReloading`、`OnScriptReloaded`；REDkit 啟動時 log 有 `Notifying 14 scriptables of reload.`、`Scriptables reloaded.`
- ✅ **實測（2026-10-13，使用者在遊戲進行中按 Reload scripts，沒有結束遊戲）**，`editor.log`：
  - 00:08:17 `Parsing 1525 script files...` → 00:08:21 `Parsing 1 script files...`（我們的腳本）→ 00:08:25 `Parsed scripts unit compiled and loaded in 0.02s`
  - 00:08:25 `Unable to restore property 'gfgReloadRequested' from snapshot of object 'Unnamed CDynamicLayer::witcher_crossbow_lvl118cee330'`
    - 這次刪掉了 `gfgReloadRequested` 欄位；訊息字面意思是「無法從物件的快照還原這個欄位」→ 刪欄位時會出現，不影響運作
  - 00:08:25 `Notifying 146176 scriptables of reload.`、`Scriptables reloaded.`
  - 00:08:32 第一次按左鍵就是新版的 log 格式（`trigger=true t=187.927 ...`）→ 新腳本在**同一場遊戲中**生效
  - 重新編譯**沒有寫檔**：`<REDKIT_DEPOT>\x64.release.redscripts` 的修改時間停在 00:03:20，那是 wcc_lite 的編譯（`wcc.log` 00:03:11～00:03:20 `Parsing 1525 script files`）
- ❓ Script Studio 的 F7 未實測

### 13.15 M2 全自動：第二次實測（commit `dfc81e0`；`editor.log` 2026-10-13 00:08～00:09）

- 按住 7.93 秒，共 64 發：
  - 30 發 → 換彈 0.884 秒（期間不開火）→ 30 發 → 換彈 0.884 秒 → 4 發
  - 開火時的狀態：`State_WeaponAim` 75 次、`State_WeaponDraw` 4 次，**沒有** `State_WeaponReload`
  - 換彈後第一發是 `shotCount=1` → `OnWeaponReloadEnd` 有把發數歸零
- 射速：
  - 第一個彈匣 30 發用 2.915 秒（平均間隔 0.1005 秒，約 597 RPM）
  - 第二個彈匣 30 發用 2.900 秒（平均間隔 0.1000 秒，600 RPM）
  - 個別間隔 0.083～0.117 秒（對齊畫面），平均回到 0.1 秒
- 點放（10 次，每次按住 0.05～0.10 秒）：
  - 按下的那一格畫面就開火（延遲 0）
  - 距離上一發不到 0.1 秒時，會等到 0.1 秒才開（延遲 0.034～0.05 秒）
- **發現**：快速連點時，一次按下可能開 2 發，間隔只有 0.065～0.083 秒
  - 例：197.662 開一發（預定下一發 197.762）→ 197.812 按下時只超過預定時間 0.05 秒，沒有重新起算 → 197.812 開一發、預定 197.862 → 197.877 又開一發
  - 原因：新的一次按下沿用了上一次按住時累計的預定時間
  - 修正：按下時若預定時間已過，就從現在起算（commit `9b0bdc3`，實測通過，見 §13.17）

### 13.16 mod 的檔案怎麼被載入（2026-10-13 查證）

- **目前的測試，遊戲跑在 REDkit 的 `editor.exe` 裡，不是 `witcher3.exe`**
  - `tasklist`：只有 `editor.exe`（PID 30256），沒有 `witcher3.exe`
  - `editor.log`：`Creating editor game session`
- REDkit 直接讀 `workspace` 裡的原始檔（log 裡的路徑是去掉 `workspace\` 的 depot 相對路徑）：

| 專案檔案 | 格式／語言 | 被讀取的證據（`editor.log`） | 內容 |
|---|---|---|---|
| `workspace\scripts\local\gfg_ak47.ws` | WitcherScript 原始碼（文字，UTF-8＋BOM） | `Missing dependency file entry for 'scripts\local\gfg_ak47.ws'`、`Parsing 1 script files...` | 射擊、彈匣、換彈的程式 |
| `workspace\dlc\gunforgeralt\test.reddlc` | REDengine 二進位資源（CR2W），只能在 REDkit 建立 | `[DLC] Found new DLC '' (id: 'gunforgeralt', file: 'dlc\gunforgeralt\test.reddlc')` | 宣告 DLC，指定要掛載的 XML |
| `workspace\dlc\gunforgeralt\data\gameplay\items\gunforgeralt_items.xml` | XML（根元素 `<redxml>`） | `Reading defs from file: 'dlc\gunforgeralt\data\gameplay\items\gunforgeralt_items.xml'` | 物品 `gfg_ak47`、能力 `gfg_ak47 _Stats` |
| `LocalEditorStringDataBaseW3_UTF8_mod.db` | SQLite 資料庫（檔頭 `SQLite format 3`） | 沒有 log 行；遊戲中顯示「AK-47」（2026-10-12 使用者實測） | 物品名稱字串 |

- 腳本在記憶體中編譯，不寫檔（§13.14）
- 還在借用原版的部分（我們沒有自己的檔案）：
  - 外觀：`equip_template="witcher_crossbow_lvl1"`
  - 圖示：`icons/inventory/weapons/crossbow/witcher_crossbow_lvl1_64x128.png`
  - 說明文字：`item_desc_crossbow_1`
  - 子彈：原版 `Bodkin Bolt`（log：`Equipped bullet item Bodkin Bolt`）
- **`witcher3.exe`（從 Steam 啟動）目前完全讀不到我們的 mod**
  - `<W3_GAME_DIR>\mods\` 裡沒有我們的資料夾
  - 專案的 `packed\`、`publish\` 不存在 → 從沒打包過
- 已安裝的 5.x mod（`<W3_GAME_DIR>\mods\mod*\content\`）裡出現的檔案類型：
  - `scripts\local\*.ws`：腳本原始碼（例：`modBetterIcons2025_Remastered`、`modArkkanisGwentQuickBets`）
  - `precompiled.rsblob`：編譯好的腳本 blob
    - Changelog 原文：「Script blobs: new way to compile script mods to small "script blobs" which the engine loads at game-start」
  - `*.w3strings`：各語言的字串
  - `blob0.bundle`、`metadata.store`、`texture.cache`、`info.json`
- 原版編譯好的腳本：`<W3_GAME_DIR>\content\content0\x64.final.redscripts`（修改時間 2026-10-12 02:57:52）、`cookedfinal.redscripts`（2026-10-09）
- ❓ 未驗證：
  - REDkit 打包後，我們的檔案會變成哪些檔案
  - `witcher3.exe` 是編譯 `.ws`，還是讀 `precompiled.rsblob`
  - 驗證方法：用 REDkit 打包一次，看輸出資料夾的內容

### 13.17 M2 點射：實測（commit `9b0bdc3`；`editor.log` 2026-10-13 00:22～00:24）

- 套用：腳本 00:13:39 修改 → 00:22:50 遊戲中 Reload scripts（`Parsing 1525` → `Parsing 1` → 00:22:58 `Scriptables reloaded.`）
- 點放（按住不到 0.1 秒）42 次：
  - 38 次各 **1 發**，按下的那一格畫面就開火
  - 4 次 0 發：都在 `State_WeaponReload`（262.452～262.918，彈匣剛打空）→ 換彈中不開火，正常
  - 相鄰兩次點放的兩發，間隔最短 0.133 秒
- 連射：5 個完整彈匣，平均間隔 0.1000～0.1006 秒（596～600 RPM），個別間隔 0.083～0.117 秒
- 311.066 按住 1.27 秒但 0 發：**不是 bug**
  - 按下時槍已收起、彈匣是空的（`state=State_WeaponWait loaded=no shotCount=30`）
  - 拿出後要先換彈；放開時（312.332）還在 `State_WeaponReload`
  - 312.549 再按，換彈約 0.05 秒後結束，就開始連射
- **剩下的問題**：槍「剛變成能開火」時，第二發會提早
  - 換彈中按住（312.549）：換彈結束開第一發，第二發只隔 **0.066 秒**
  - 收槍時按下（257.252）：拿出中（`State_WeaponDraw`）開第一發，第二發只隔 **0.084 秒**
  - 原因：補償時間的邏輯把「等換彈、等拿出」的延遲也補了，本來只該補「對齊畫面」的延遲
- 修正：
  - 每次檢查都記下時間（`gfgLastCheckTime`），包括還不能開火的時候
  - 上一次檢查時就到了預定時間卻不能開火 → 從現在起算
  - 遊戲外模擬（60 FPS，暫存腳本，未納入專案）與實測（`editor.log` 00:39～00:41；腳本 00:27:31 修改 → 00:38:53 遊戲中 Reload scripts）：

| 情境 | 修正前（實測） | 修正後（模擬） | 修正後（實測） |
|---|---|---|---|
| 換彈中按住，換彈結束後第 1→2 發 | 0.066 秒 | 0.100 秒 | 0.100、0.101、0.101、0.100 秒 |
| 收槍時按下，拿出後第 1→2 發 | 0.084 秒 | 0.101 秒 | 0.116、0.102、0.100、0.101、0.102 秒（5 次） |
| 連續按住 3 秒 | — | 30 發，平均 0.1004 秒 | — |
| 點放 20 次 | — | 20 發，最短間隔 0.133 秒 | — |

### 13.18 收槍（2026-10-13 查證）

- 原版自動收槍：計時器 `HolsterAfterDelay` 只把行為變數 `canHolsterAfterDelay` 設成 1（`rangedWeapon.ws:640-646`）
  - 射擊動畫狀態 `State_WeaponShoot` 每發之後加：戰鬥中 0.5 秒、非戰鬥 5 秒（`rangedWeapon.ws:1548-1562`）
  - 進入 `State_WeaponAim` 0.2 秒後（`CheckGotoAimThrow`）沒按住中鍵：瞄準中 0.75 秒、戰鬥中 0 秒、非戰鬥 4.9 秒（`rangedWeapon.ws:1413-1427`）
- **AK 停火後不會自動收槍**（使用者 2026-10-13 實測：等 5 秒仍拿著）
  - 我們在 `State_WeaponAim`／`State_WeaponDraw` 直接開火（log：開火狀態只有這兩種），不經過 `State_WeaponShoot`
  - 每發都移除 `HolsterAfterDelay`（`gfg_ak47.ws`，照 `rangedWeapon.ws:1367-1370`）→ 停火後沒有計時器
- **衝刺會收槍**（使用者實測：按 Shift 就收）
  - 按衝刺 → `thePlayer.rangedWeapon.OnSprintHolster()`（`playerInput.ws:607-610`；切換式衝刺 `:629-630`）
  - `OnSprintHolster`（`rangedWeapon.ws:491-507`）：玩家在 `Exploration`／`Swimming`、行為變數 `isShootingWeapon` 與 `isAimingWeapon` 都是 0、武器在 `State_WeaponAim` → `OnForceHolster( true, false )`
  - 我們放開扳機時把這兩個變數設成 false（`GfgSetTrigger`）
- 其他會強制收槍的（腳本呼叫 `OnRangedForceHolster`，**未實測**）：翻滾（`explorationStateRoll.ws:105`）、跳躍（`explorationStateJump.ws:408`）、開始墜落（`explorationStateStartFalling.ws:78`）、擊倒（`knockdown.ws:65`）等
- 決定（2026-10-13）：**維持現狀**，停火後不自動收槍

---

## 14. M2 後座力：彈道資料的來源（2026-10-13 調查）

### 14.1 不能從參數自己推演算法

- `weapons.vdata` 只有參數（種子、角度、大小、變化量），不是每發的座標（`docs\ak47_params.md` §4.3）
- CS2 的 convar dump 沒有 CS:GO 時代的 `weapon_recoil_*`（`docs\ak47_params.md` §7）
- 網路搜尋（2026-10-13）**找不到** Valve 後座力產生演算法的公開文件或逆向研究
  - 唯一相關的是 Godot 重製專案 CSGODOT 的 PR #111（https://github.com/sidcarrollworks/CSGODOT/pull/111）
    - 作者把「`m_nRecoilSeed` 造成左右偏移」標為**推測**，並計畫改用 demo 錄影實測取代
  - csdb.gg 彈道頁（https://csdb.gg/recoil-patterns/）2026-10-13 回應 HTTP 429，沒有取得內容
- → 用參數自己湊演算法就是臆測，不採用

### 14.2 改用實測：CS2 demo ＋ demoparser2

- **demoparser2**（LaihoE，MIT 授權，https://github.com/LaihoE/demoparser）
  - README 的欄位表：`aim_punch_angle` = `CCSPlayerPawn.m_aimPunchAngle`、`aim_punch_angle_vel` = `CCSPlayerPawn.m_aimPunchAngleVel`
  - 用法：`DemoParser(路徑).parse_ticks([欄位...])` 逐 tick 讀取
  - PyPI 0.42.0 有 `cp314-win_amd64` 版本（2026-08-08 上傳），不用自己編譯
  - 相依套件：pandas、numpy、polars、pyarrow、tqdm（下載至少 57 MB）
- **CS2 的指令**（GameTracking-CS2 `DumpSource2/commands.txt`、`convars.txt`，2026-10-13 下載，未放進專案）：

| 指令／convar | 出處 | 旗標 | 用途 |
|---|---|---|---|
| `record` | commands.txt:2718 | `cheat dontrecord release` | 開始錄 demo（要 `sv_cheats 1`） |
| `stop` | commands.txt:3484 | `release` | 停止錄影 |
| `map` | commands.txt:2039 | `release` | 開本機地圖 |
| `give` | commands.txt:1713 | `gamedll ... client_can_execute` | 給武器 |
| `bot_kick` | commands.txt:269 | `gamedll release` | 踢掉電腦玩家 |
| `sv_cheats` | convars.txt:10908 | — | 允許作弊指令 |
| `weapon_accuracy_nospread` | convars.txt:12909 | 不是 cheat | 關掉散布，只留後座力 |
| `sv_showimpacts` | convars.txt:11751 | 不是 cheat | 顯示彈孔 |
| `view_punch_decay` | convars.txt:12693 | `cheat`，預設 18 | 「Decay factor exponent for view punch」 |

- CS2 已安裝的地圖（`game\csgo\maps\*.vpk`）：`de_dust2`、`de_mirage`、`de_inferno`、`cs_office`、`ar_shoots` 等
- ❓ 待確認：
  - `record` 的 demo 存在哪裡（`game\csgo\` 第二層內目前沒有 `.dem`）
  - aim punch 角度和子彈實際方向的比例：CS:GO 時代 `weapon_recoil_scale` 預設 2（https://totalcsgo.com/command/weaponrecoilscale），CS2 的 dump 裡沒有這個 convar

### 14.3 採用的數據（2026-10-13；使用者同意 AK 的數據可以推測、任何來源都可以）

- 使用者覺得錄 CS2 demo 太麻煩 → 改用網路上現成的彈道數據
- **CSGODOT** 的 `reference/spray_patterns/README.md`（https://github.com/sidcarrollworks/CSGODOT ，沒有標授權）說明兩份 AK 數據：
  - `ak47.csv`：從 CS2 彈道圖讀出，**形狀是量的，大小是假設的**（假設往上爬 16°）
  - `weapon_ak47.csv`：來自 Artanis-RCS，換算方式「2.45 × 0.022° 一個單位」，再乘 1.3577 對齊前者
- **採用原始來源 Artanis-RCS**（MIT）：`data/recoil/ak47_artanis-rcs.csv`，來源、授權、換算依據見 `data/recoil/README.md`
- 工具 `tools/recoil_pattern.py` 的驗證：
  - 和 CSGODOT 的 `weapon_ak47.csv` 比對：乘 1.3577 後誤差 **0.000°** → 單位與方向的理解和他們一致
  - 和 CS2 彈道圖的 `ak47.csv` 比對：最合適倍率 1.3577，誤差 **0.670°**（CSGODOT 寫的是 1.358、0.67°）
- 結果（工具的換算）：
  - 最高點：第 26 發，往上 **11.73°**；左右範圍 -2.83° ～ +4.52°
  - 形狀：第 0～7 發往左（到 -1.64°）→ 第 7～14 發往右（到 +4.52°）→ 第 14～19 發往左（到 -2.83°）→ 第 19～29 發往右（到 +3.66°）（忽略 1.5° 以下的來回）
  - CS2 彈道圖那份的整體形狀相同；17～25 發多了幾段小來回，CSGODOT 說那幾發的順序在圖上分不出來
  - 圖：`docs/ak47_recoil_pattern.svg`
- 不確定、需要遊戲裡調整的：
  - **大小**：11.7°（工具換算）或 16°（CSGODOT 的假設）都沒有實測 → 遊戲裡留一個整體倍率
  - 第 1 發：這份數據和第 0 發同一點；CS2 彈道圖那份高 0.5°

### 14.4 遊戲內後座力：鏡頭版實測，改成準心版（2026-10-13）

- **鏡頭版**（未 commit）：包裝 `CR4Player.OnGameCameraTick`，每發把位移加到 `moveData.pivotRotationValue`
  - 方向：pitch 往上為正（`swimming.ws:1406`）；yaw 往左為正（`r4Player.ws:16144-16145`：右邊的點是 heading - 90）
  - `editor.log` 01:09:22 起：每發 pitch 的變化等於位移表（例：第 2 發 -14.2219 → -12.8203，+1.4016）；下一發開火前的角度等於上一發之後的角度 → 寫入的角度會保留，不會被原版拉回
  - 停火後偏移歸零：`recoil recovered: 0.216431s after last shot`
  - 使用者回報：鏡頭有動、一頓一頓的、放開後有回原位；**要求改成「準心動就好」，並且要有準心**
- **準心版**（wcc_lite 編譯通過，未進遊戲測試）：
  - 準心模組：`hud.GetHudModule("CrosshairModule")`，開關用 `ShowElement`（同 `playerAiming.ws:208-219`）
  - 移動準心：`GetModuleFlash().SetX／SetY`（HUD 模組定位的方式，`hudModuleBase.ws:114-126`）；回原位用 `SnapToAnchorPosition()`（`:72-112`，public）
  - 角度換成像素：沿著帶偏移的方向取一點 → `theCamera.WorldVectorToViewRatio`（`cameraDirector.ws:15`）→ `(x+1)/2`、`(y+1)/2` → `hud.GetScaleformPoint`（`hud.ws:306-312`，線性換算），和畫面中央相減（換算同 `hud.ws:1864-1874`）
  - 方向：`VecNormalize( GetCameraForward + GetCameraRight·tan(右) + GetCameraUp·tan(上) )`（`cameraDirector.ws` 的 `GetCameraForward／Right／Up`）
  - 準心平滑：時間常數 0.03 秒（推測）
  - 子彈：包裝 `W3BoltProjectile.ThrowProjectile`，AK 的目標點改成「從鏡頭沿準心方向打射線的最近命中點」
    - 原版目標是 `GetLookAtPosition()`，最遠 25 公尺（`playerBoltProjectile.ws:128-142`）
    - 射線寫法照原版 `CalculateAimPosition`（`playerAiming.ws:553-616`，private 不能直接呼叫）；長度 208 公尺（CS2 `m_flRange`）
  - ⚠️ 尚未處理：戰鬥中有鎖定目標時，原版會改成直接射向敵人骨架（自動瞄準，`playerBoltProjectile.ws:353-377`）；弩箭的飛行距離上限仍是 25 公尺（`:348`）

### 14.5 準心版第二次實測：`theCamera` 的位置不是畫面上的鏡頭（2026-10-13）

- 使用者回報：準心移動幅度非常小；一開槍準心就跑到不相干的地方
- `editor.log` 01:28～01:29：
  - 用 `theCamera.GetCameraPosition()` 加 `GetCameraDirection()` 取 10 公尺外的點投影，「畫面中央」的比例是 (-1.245,-0.186)、(-0.707,0.205)、(-0.784,-0.070)，應該要接近 (0,0)
  - 準心位移忽大忽小：往上 1.37° 時 (-678,+110) 像素；往上 11.6° 時只有 (5,24) 像素
  - 射線大多打到 208.5 公尺（＝射線全長，什麼都沒打到）
  - → `theCamera` 給的位置不是畫面上的鏡頭（在 REDkit 裡）。起點錯了，準心就會跳走；起點離真正的鏡頭很遠，10 公尺的方向差投影到畫面上就只剩幾個像素
- 修正（wcc_lite 編譯通過，**未進遊戲測試**）：
  - 位置與方向改取遊戲鏡頭本身：`theGame.GetGameCamera().GetCameraWorldPosition()／GetCameraWorldRotation()`（`r4Game.ws:261`、`customCamera.ws:110-111`），方向用 `RotForward`（`math.ws:459`）
  - 投影改取 1000 公尺外的點，準心位移 = 帶偏移的點 − 不帶偏移的點
  - 診斷 log：`crosshair check` 同時記錄兩種鏡頭位置離 Geralt 的距離、兩種方向的內積
- 這個修正版有沒有進遊戲測試，沒有紀錄：`editor.log` 在 2026-10-13 12:47 REDkit 重開時被覆寫，現在的內容（12:47～12:51）沒有 `GFG` 的行

### 14.6 回到鏡頭版：修正一頓一頓、準心一直顯示（2026-10-13）

- 使用者決定：「還是要螢幕動，像是 GTA5 那樣」；之前「一頓一頓的要修正」；「準心還是要存在，不要因為射擊就消失」
- **一頓一頓的原因**（§14.4 的 log）：
  - 每發的位移在開火那一格整個加到 `pivotRotationValue`（例：第 2 發 -14.2219 → -12.8203）
  - 下一發開火前的角度等於上一發之後的角度 → 兩發之間鏡頭完全不動
- **修正**：每發的位移在 0.1 秒（＝射擊間隔，`GfgKickTime`）內等速轉完；下一發開火時還沒轉完的部分，併入下一發一起轉
  - 遊戲外模擬（暫存腳本，未納入專案；射擊時機照 `GfgTryFire`，位移表照 `tools/recoil_pattern.py`，30 發）：

| 做法 | 畫面更新率 | 連射中鏡頭完全不動的格數 | 單格最大轉動 | 子彈方向和彈道的誤差 |
|---|---|---|---|---|
| 舊：開火那一格一次轉完 | 60 FPS | 135／162（83.3%） | 2.787° | 0 |
| 新：0.1 秒內等速轉完 | 30 FPS | 1／81（1.2%） | 0.929° | 最大 0.521°、平均 0.017° |
| 新 | 60 FPS | 1／162（0.6%） | 0.464° | 最大 0.260°、平均 0.009° |
| 新 | 144 FPS | 0／389 | 0.197° | 最大 0.063°、平均 0.018° |
| 新（每格時間 ±30% 隨機） | 60 FPS | 1／163 | 0.550° | 最大 0.257°、平均 0.042° |

  - 「開火」和「鏡頭更新」在同一格的先後順序互換，結果相同
  - 60 FPS 時第 3 發起每格轉動：舊 `1.62 0 0 0 0 0 1.72 0 0 0 0 0 1.90 …`；新 `0.27 ×6 → 0.29 ×6 → 0.32 ×6 …`
- 改鏡頭角度的方式同 §14.4：包 `CR4Player.OnGameCameraTick`，改 `moveData.pivotRotationValue`
  - 原版先例：爬牆鏡頭每格改 `pivotRotationValue`（`explorationStateClimb.ws:2111-2135`）
  - 中鍵瞄準（`AimThrow`）的鏡頭更新不會呼叫到這裡：`aimThrow.ws:161-394` 沒有呼叫上層，直接 `return true`
  - 那時左鍵也不是扳機：`[ThrowHold]` 情境沒有 `BASE_ATTACK_LIGHT`（`input_qwerty.ini:466-484`）→ 這次不處理 `AimThrow`
- 停火後轉回原位：沿用 §14.4 的衰減（推測的公式），沒有改
- **準心**：
  - 左鍵扳機不會進入原版瞄準：`CheckGotoAimThrow` 只看中鍵 `ThrowItem`（`rangedWeapon.ws:1362`）→ 原版不會打開準心；§14.4 鏡頭版沒有準心就是這個原因
  - 做法：AK 拿在手上（不是 `State_WeaponWait`／`State_WeaponHolster`）就打開，固定在原本的錨點（`SnapToAnchorPosition`），不移動
  - `playerAiming` 的狀態一變就再打開一次：原版唯一會關準心的地方是中鍵瞄準結束時的 `AimCleanup`（`playerAiming.ws:683-686`）；不重開的話，用中鍵射完一發，準心會跟著消失
  - 收起 AK 時，只關我們打開的準心（不影響原版丟炸彈、其他十字弩瞄準時的準心）
  - 開關的狀態記在玩家身上（`@addField(CR4Player)`），換十字弩時也能關掉
  - 弩箭在 `Aiming` 狀態開火時只呼叫 `RemoveAimingSloMo`，不會呼叫 `StopAiming`（`throwable.ws:175-193`）
  - 準心錨點的位置寫在 Flash 裡，腳本看不到；原版瞄準模式也是「準心在錨點、箭沿鏡頭正前方的射線飛」（`playerAiming.ws:316-326`）
- **子彈**：從鏡頭沿鏡頭正前方打射線（後座力已經轉到鏡頭上，所以就是畫面中央的準心）
  - 鏡頭位置改成 `GetCameraWorldPosition() + GetCameraWorldOffset()`：原版拍照模式取遊戲鏡頭的位置就是這樣寫（`photomodeManager.ws:98-99`）
- 診斷 log（`editor.log` 的 `[Script_GFG]`）：
  - `recoil: burst=… camera pitch=… applied up=… ticks=… moved=…`：每發開火時鏡頭的角度、後座力已經轉了多少；`ticks`＝上一發之後經過幾格、`moved`＝其中鏡頭有轉的格數
  - `aim: distance=… screen=(x,y) camOffset=… theCamera-gameCam=…`：目標點投影到畫面的位置（畫面中央是 0,0，`hud.ws:1864-1874`）、鏡頭位移的長度、`theCamera` 和遊戲鏡頭位置的距離
  - `crosshair shown: aiming state=…`／`crosshair hidden`
- wcc_lite 編譯通過（第一次就通過），**未進遊戲測試**
- 沒有處理（同 §14.4）：戰鬥中鎖定目標時的自動瞄準（`playerBoltProjectile.ws:353-377`）、弩箭飛行距離上限 25 公尺（`:348`）

---

## 15. 測試用靶子：生成怪物、人物，敵我關係與血量（2026-10-13 查證，未實測）

- **主控台指令**（原版 `temp.ws`）：
  - `spawn( 名稱, 數量, 距離, 是否敵對, 等級 )`（`:6815-6942`）
    - 名稱用 `LoadResource` 找資源別名（`:6857`）；找不到時拼成 `characters\npc_entities\monsters` + 名稱 + `.w2ent`（`:6862-6868`，中間少一個反斜線，拼出來的路徑不對）
    - 「是否敵對」為 true 時設成 `hostile_to_player`（`:6933-6936`）；false 時**不改**，怪物照樣會攻擊
    - 等級：`SetLevel`（`:6938-6941`）
  - `spawnPath( 實體模板路徑, 是否敵對 )`（`:6790-6813`）：任何 `.w2ent` 都可以；敵對時 `hostile_to_player`，否則 **`friendly_to_player`**
  - `attitude( 標籤, 是否敵對 )`（`:8548-8559`）、`SetHostile( 標籤 )`（`:503-509`）：用標籤找角色改態度（`spawn` 生出來的沒有標籤）
  - `freeze` 不是凍住：只會讓 NPC 踉蹌或進入戰鬥專注（`:7007-7024`）
  - `HPM` 是遊戲時間流速（`SetHoursPerMinute`，`:7347`），跟血量無關
  - `stats( 標籤 )`、`statstarget()` 印出數值（`:6154-6177`）；`killall( 範圍 )` 清敵人（`playerCheats.ws:9`）
- ⚠️ **友善的角色打不到**：玩家投射物的碰撞判定 `CanCollideWithVictim`，對 `AIA_Friendly` 回傳 false（`throwable.ws:110-131`）
- 血量：原版沒有給 NPC 用的指令；API 有 `SetHealthPerc`、`SetHealth`（`actor.ws:947`、`964`）、`ForceSetStat`（`npc.ws:1447`）、`SetImmortalityMode`（`actor.ws:415`）
- 模板（`<REDKIT_DEPOT>`）：
  - 怪物 `characters\npc_entities\monsters\`：`wolf_lvl1.w2ent`、`nekker_lvl1.w2ent`、`drowner_lvl1.w2ent`、`ghoul_lvl1.w2ent`、`bear_lvl1__black.w2ent` 等
  - 人物 `characters\npc_entities\main_npc\`：`ciri.w2ent`、`yennefer.w2ent`、`triss.w2ent`、`vesemir.w2ent`、`dandelion.w2ent`、`zoltan.w2ent` 等
- **REDkit 編輯器**（Wiki）：
  - 「HOW-TO: Create a monster encounter」（頁面 6326170）：在世界的圖層放 Encounter Area、Spawn Point、Guard Area，用 spawn tree 生成怪物
    - 原文：「Enemies will only engage in combat, when you are in close range of (4m) or inside the guard area.」
  - 「TOOL: Attitude Editor」（頁面 6328884，Tools → Attitude Editor...）：改群體之間的敵我關係，「can also be used to test out how different entities are acting when their attitudes are edited (even during gameplay)」

### 15.1 內建的靶子（2026-10-13 調查：沒有「有血量、不反擊」的現成靶子）

- depot 裡名稱含 dummy／target／training 的 `.w2ent` 有 43 個；從二進位檔讀出類別：
  - 物件（`CGameplayEntity`／靜態模型，沒有血量）：序章假人 `items\quest_items\q001\q001_dummy_for_geralt.w2ent`、石之心十字弩靶 `dlc\ep1\data\quests\quest_files\q603_bank\entities\q603_crossbow_npc_target.w2ent`、血與酒射擊靶 `dlc\bob\data\quests\main_quests\quest_files\q704_truth\entities\q704_shooting_target.w2ent`、比武大會靶 `dlc\bob\data\environment\architecture\tournament\entities\target.w2ent`
  - 會被打壞的物件：`sq701_target_01.w2ent`（`W3DestroyableClue`）
  - **角色**：尾聲的訓練木樁 `quests\epilogues\quest_files\q505_ciri_free\entities\q505_training_dummy.w2ent`
    - `entityClass` = `CActor`；標籤含 `softLock_Bolt` 等鎖定標籤；有 `CAttackableArea`；模型 `environment\decorations\battleground\trainer\trainer.w2mesh`
    - 沒有看到能力或數值設定 → 多半沒有血量；原版腳本沒有引用它
    - 用 `spawnPath` 生成時要加 `true`（敵對），否則會被設成友善、子彈打不到（`temp.ws:6809-6812`、`throwable.ws:126-128`）
- REDkit 參考關卡 `engine\reference_level\world\test_cases\`：
  - `friendly_dummies\dummies.w2l`：**空的圖層**（只有 `CLayer`、`CLayerInfo`）
  - `attack_changes_demo\attack_changes_demo.w2l`：一個 `CNewNPC`、圖層引用 `characters\npc_entities\monsters\fogling_lvl1.w2ent`、三條移動路徑 `combat_dummy_*_wp`（繞圈、直線、慢速直線）、Quen／Igni／Aard 的測試物件 → 次世代版攻擊改動的示範區；NPC 的敵我與 AI 設定從字串看不出來
  - `skills_demo\skills_demo.w2l`：只有觸發區域 `skills_demo_trigger`
  - `quest\`：只有開場與功能測試圖層，沒有生成 NPC
