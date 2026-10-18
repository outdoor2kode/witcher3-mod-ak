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
- ✅ `projSpeed` = 60.0；`projAngle` 模板沒覆寫（腳本預設 5）→ 見 §18.2
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
| 3 | `bodkin_bolt.w2ent` 的 `projSpeed` 實際值 | M2 | **已解**：60.0（`tools\cr2w_dump.py` 讀模板，§18.2） |
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
  - 同意紀錄在登錄 `HKCU\Software\CD Projekt RED\Mod Tools\1.0` 的 `DoNotShowEula`（`wcc_lite.exe` 的字串：`Software\CD Projekt RED\Mod Tools\1.0`、`DoNotShowEula`、`Agree`、`Decline`、`wcc_eula.rtf`）
    - 2026-10-15 21:56 又跳出來（當時值是 0；什麼時候、被什麼改回 0，查不到）；使用者按 Agree 後變成 1
    - 卡住時：`tasklist /v` 看 `wcc_lite.exe` 的視窗標題是不是 `EULA`
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
- wcc_lite 編譯通過（第一次就通過）
- 沒有處理（同 §14.4）：戰鬥中鎖定目標時的自動瞄準（`playerBoltProjectile.ws:353-377`）、弩箭飛行距離上限 25 公尺（`:348`）

### 14.7 鏡頭版實測（2026-10-13）

- 使用者回報：除了「看牆上的箭」（沒有牆可以打），其他項目都符合預期
  - 鏡頭連續轉動、不再一頓一頓；準心一直在；壓槍有效；放開後轉回原位；換彈中準心還在
- `editor.log`（REDkit 13:36 重開；13:37:22 開始遊戲；GFG 紀錄 13:42:43～13:44:50）：
  - 按住 3 次，共 360 發、12 個彈匣（`magazine empty` 12 次）
  - `crosshair shown: aiming state=Waiting` 1 次（第一次按左鍵時）；沒有 `crosshair hidden`
    - 收槍、中鍵那兩項是使用者回報，這段 log 裡沒有對應的紀錄
  - **鏡頭轉動**：每輪第 4 發以後共 323 發，其中 304 發 `ticks` = `moved`（兩發之間每一格都在轉）
    - 其餘 19 發都是 `ticks=7 moved=6`：那次間隔剛好 7 格，6 格就轉完，最後 1 格不動
    - 開火時上一發還沒轉完的部分：最大 0.341°、平均 0.015°
    - 每發的鏡頭 pitch 照位移表增加：2.000 → 3.400（+1.400）→ 5.016（+1.616）→ 6.729（+1.713）…（表：1.4016、1.6146、1.7194）
    - yaw：`right` 為負時 yaw 增加、為正時減少 → 「yaw 往左為正」正確
  - **子彈方向**：360 發的目標點投影到畫面，x 在 -0.00001～0.00054、y 在 0～0.00064 → 都在畫面正中央
    - 167 發打到東西（8.6～45.6 公尺），其餘到射線盡頭 208.5 公尺
  - **鏡頭位置**：`GetCameraWorldOffset()` 長度固定 2.511 公尺；加上之後和 `theCamera.GetCameraPosition()` 相差中位數 0、最大 0.314 公尺
    - → §14.5 的修正版只用 `GetCameraWorldPosition()`，會差 2.5 公尺

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

### 15.2 測試指令 `gfgwall()`、`gfgtarget()`（2026-10-13；**已刪除**）

- **使用者 2026-10-13 要求刪除**：測試用的牆、靶子用原版指令（`spawnPath` 等，`CLAUDE.md` §12）就好，不另外寫；`gfg_test.ws` 已刪除
- 實測結果（`editor.log` 17:00～17:05），留給之後做 AK 參考：
  - 牆實際寬 8.0 公尺（外框 X 從 -487.61 到 -479.60）、高 4.75 公尺；朝向推論正確（牆面朝向玩家），寬度推估錯（不是 5 公尺）
  - 打牆時射線距離 10.0～10.3 公尺（射線打到牆），但**箭沒有插在牆上**（使用者回報）；這段 log 沒有腳本錯誤
  - 盜賊生成時 `hostile=true immortal=true`，仍然一發就死；那一發的紀錄：`displayTarget=bandit_lvl2 hardLock=false combatMusic=true` → **原版自動瞄準的條件成立**（`playerBoltProjectile.ws:353-354`），箭射向盜賊的身體、不是準心
    - 同一發的傷害處理記錄 `action deals no damage and gives no buffs - investigate!`，接著計算擊殺經驗、`NoSave lock 'dudeIsDying'`；死因沒有查完
- 以下是當時的做法（保留查證紀錄）
- 檔案：`workspace\scripts\local\gfg_test.ws`；兩個指令都可以指定距離（公尺），不指定是 8 公尺
- 位置：玩家前方（鏡頭的水平方向），用 `StaticTrace` 貼地（同原版 `spawn`：`temp.ws:6895-6902`）；朝向玩家（同 `spawnPath` 的 `Yaw + 180`：`temp.ws:6797-6798`）
- **牆**：`dlc\bob\data\environment\architecture\grey_box_blockout\brick_wall_system\entities\wall_super_wide.w2ent`（關卡打樣用的素面磚牆）
  - 模板內容（CR2W 的 `flatCompiledData` 裡嵌著另一份 CR2W）：三個 `CStaticMeshComponent`
    - `support_big.w2mesh`、`wall_super_wide.w2mesh` 在 x = -0.68；`trim_super_long_01.w2mesh` 在 (-0.68, 0, 4.75) → 牆高約 4.75 公尺
    - 模板裡的 `boundingBox` 沒有存尺寸（Min 是浮點數最大值、Max 是 NaN）
  - 碰撞：三個模型的路徑都在 `<W3_GAME_DIR>\content\content0\collision.cache`（890 MB，檔頭 `CC3W`）的名稱表裡
    - 對照：`engine\meshes\editor\plane.w2mesh` 不在裡面
    - `<REDKIT_DEPOT>\collision.cache` 是 0 bytes；5.x 的 ep1、bob 都併進 `content0`
  - REDkit depot 只有 110 個 `.w2mesh` 散檔，其他模型執行時從遊戲的封存檔載入（uncook 紀錄有 `Extracting ...wall_wide.w2mesh (1.72 KB)`，但 depot 裡沒有這個檔）
  - 🔶 朝向（推論）：模板裡的縮圖（CThumbnail）攝影機在 (-1.73, 5.68, 6.58)、pitch -30°、yaw 210°（往 -Y 拍），縮圖看到的是長的那一面、柱子在近的一端
    - → 牆沿著自己的 X 軸延伸、牆面朝 ±Y，原點在柱子那一端；由縮圖取景推估牆寬約 5 公尺
    - 做法：牆的 +Y 朝向玩家，原點往右移 1.5 公尺
    - 驗證：生成 1 秒後把每個模型的外框寫進 log（`test wall box N: min=… max=…`；`GetBoundingBox()` 是世界座標：`staringPortrait.ws:66-71` 拿它和玩家的世界座標比較）
- **靶子**：`characters\npc_entities\crowd_npc\bandit\bandit_lvl1.w2ent`
  - 敵對：`SetTemporaryAttitudeGroup( 'hostile_to_player', AGP_Default )`（同 `spawnPath`：`temp.ws:6805-6808`）；友善角色打不到（`throwable.ws:126-128`）
  - 鎖定：Z 鍵（`CameraLock`，`input_qwerty.ini:53`）要在玩家「被威脅」時才有作用（`playerInput.ws:3497-3525`）
    - 被威脅：附近有 `IsThreat` 的角色（`r4Player.ws:6040-6085`）；敵對、而且距離小於 `findMoveTargetDist + 5` 就算（`:12728` 起），不必進入戰鬥
    - `findMoveTargetDist` = `findMoveTargetDistMax` = 18（`:337`、`:601`）→ 23 公尺內
  - 不反擊：`new CAIDoNothingAction in npc` → `OnCreated()` → `ForceAIBehavior( tree, BTAP_AboveCombat )`（同原版狗被摸時：`DogNPC.ws:186-195`；`CAIDoNothingAction`：`actionParams.ws:192-195`）
  - 不會死：`SetImmortalityMode( AIM_Immortal, AIC_Default )`（同 `npc.ws:456`）→ 傷害最多扣到剩 1 點血（`damageManagerProcessor.ws:498-504`、`539-543`）
    - 生成時只有帶 `isImmortal` 等旗標的 NPC 才會設定不死模式（`npc.ws:446-467`），不會蓋掉
    - 為什麼要不死：AK 的需求等級 31（§13.12），1 級盜賊很快就會被打倒
- 寫法注意（wcc_lite 實測）：
  - 從外面經由 `thePlayer` 寫入欄位會錯誤 `Left hand side is const` → 改成在 `CR4Player` 自己的方法裡寫
  - 物件不能和 `NULL` 用 `!=` 比較（`Unable to find suitable operator 'OperatorNotEqual'`）→ 用 `if ( 物件 )`
- 同時把 `gfg_ak47.ws` 的 `aim:` 紀錄改成記錄原版自動瞄準的條件（`playerBoltProjectile.ws:353-354`）：`displayTarget=`（鎖定的目標）、`hardLock=`、`combatMusic=`
  - 原本的 `camOffset`、`theCamera-gameCam` 兩欄已經在 §14.7 驗證完，拿掉

---

## 16. M2 散布：現成做法調查（2026-10-13）

- 使用者選定下一步做「M2 散布」；照 `CLAUDE.md` §11 先找現成的做法
- 網路搜尋「CS2 inaccuracy formula」沒有找到官方或逆向的公開公式

### 16.1 CCO（巫師3 mod，`findings.md` §8.1）

- 目標點的 X／Y／Z 各加 `RandRangeF( spread, -spread )`，偏移量依距離放大（CCO `playerBoltProjectile.ws:614-629`）
- 方盒狀分布，散布值固定（XML 屬性 `Spread`），不分站立、移動，也沒有連發累積、停火回復

### 16.2 CSGODOT（Godot 重製 CS2，https://github.com/sidcarrollworks/CSGODOT ，沒有授權條款；2026-10-13 讀 `main`）

- **單位**：vdata 的不準度是「子彈偏離瞄準方向的最大角度的正切值」，角度 = atan(值)
  - `weapon_vdata.gd:131-139`（`_cone`）、`weapon_sheet.gd:83-87`（`cone_degrees`）
  - 佐證（作者寫的）：CS2 武器表的 AK 精準距離——7.01／1000 在 21.74 公尺偏 15.24 公分
- **換算**（`weapon_vdata.gd:86-94`）：都是「總量」
  - 站立 = atan(Stand + Spread)；蹲下 = atan(Crouch + Spread)
  - 移動 = atan(Move + Stand + Spread)；跳躍 = atan(Jump + Stand + Spread)
  - 每發 = atan(Fire)
  - AK（本專案 `data\cs2\weapons.vdata` 的值）：站立 0.4016°、蹲下 0.3100°、移動 10.32°、跳躍 8.41°、每發 0.447°（和 CSGODOT `weapon_data.gd:490-506` 的預設值一致）
- **模型**（`weapon.gd`）：
  - 圓錐半角 = 姿勢的基礎值 + 開火累積量（`current_inaccuracy`，:593-598）
  - 基礎值（`_cone_for`，:603-621）：站立或蹲下；離地加（跳躍 − 站立）；移動加（移動 − 站立）× 比例
    - 比例：速度在最高速的 34%～95% 之間線性 0→1，沒按慢走鍵時再開四次方根（:118-126、:613-619；作者註明是 CS:GO 的 0.34、0.95）
  - 每發：累積量 += 每發值（:738-742）
  - 衰減：累積量 ×= exp(−dt ÷ τ)，τ = 恢復時間 ÷ ln 10（恢復時間＝降到十分之一的時間；`weapon_data.gd` 的 `accuracy_time_constant`）；低於「每發值 × 一個比例」就歸零（`accuracy_reset_threshold`）
    - 恢復時間：連射第 2～5 發之間從 0.368 秒線性變成 0.506 秒（`recovery_time`；作者註明是從欄位名稱和 Valve 2016 年的更新說明推論）
  - 落地：累積量 = max(累積量, 落地 − 站立)（:455-461；落地值取自 CS2 武器表，不是 vdata）
  - 子彈方向（`_spread_direction`，:853-870）：隨機角度 0～360°、隨機半徑 = 均勻亂數 × 圓錐半角（越靠中心越密）
- 套到巫師3 時要注意（原版行為）：
  - Geralt 不能蹲下 → 蹲下的數值用不到
  - 跳躍會強制收起十字弩（`explorationStateJump.ws:408` 呼叫 `OnRangedForceHolster`；§13.18，**未實測**）→ 若屬實，跳躍、落地的數值用不到
  - → 實際只剩「站立／移動」兩種基礎值＋連發累積＋停火回復

### 16.3 實作（2026-10-13，使用者選 CSGODOT 的做法；wcc_lite 編譯通過，**未實測**）

- `gfg_ak47.ws`：
  - `GfgAimPoint`：射線方向 = 鏡頭正前方再偏移「隨機角度、均勻亂數 × 圓錐半角」（`GfgRotateDirection`）
  - `GfgSpreadCone` = 0.4016 +（10.3188 − 0.4016）× 移動比例 + 開火累積量
    - 移動比例：`VecLength2D( GetMovingAgentComponent().GetVelocity() )`（`player.ws:1285` 的取法）和 5.46 公尺/秒比，34%～95% 之間 0→1，再開四次方根
  - 每發開完：累積量 += 0.4469（`GfgTryFire`）；每格畫面：衰減（`GfgDecaySpread`，由 `GfgUpdateRecoil` 呼叫）
  - 每發多一行紀錄：`spread: cone=… penalty=… speed=… moveType=…`
- 遊戲外估算（600 RPM、站著）：各發圓錐 0.40、0.64、0.77、0.87、0.96、1.04 … 第 30 發 1.18°；停火後 1.13 秒累積量歸零
  - 移動：每秒 1.5 公尺 → 0.40°（低於 34%）；3.0 → 7.99°；4.5 → 9.76°；5.46 → 10.32°
- 推測的部分：Geralt 的速度直接和 5.46 公尺/秒比；不分慢走鍵；恢復時間用這一輪連射的發數混合

### 16.4 散布實測（2026-10-13；`editor.log` 17:42～17:53）

- 使用者回報：
  - 站著射、邊走邊射，落點都有散開（散布有作用）
  - **沒辦法邊跑邊射**：一開槍 Geralt 就慢下來變成走路
  - **也不能邊跳邊射**
- log 的 `spread:` 紀錄共 723 發：

| `moveType` | 發數 | 速度（公尺/秒）中位數／最大 | 圓錐半角（度）中位數／最大 |
|---|---|---|---|
| `PMT_Walk` | 620 | 2.00／6.85 | 5.61／11.04 |
| `PMT_Idle` | 74 | 0.00／5.14 | 0.89／10.29 |
| `PMT_Sprint` | 29 | 7.00／7.00 | 10.54／10.68 |

- 邊走邊射的速度約 2.0 公尺/秒，剛好高過門檻 1.86（5.46 × 34%）；四次方根讓它變成移動比例約 0.46 → 圓錐約 5.6°
- 開槍會減速、跳不起來的原因：見 §17
- 腳本已 commit（散布有作用）；移動散布要不要調：使用者 2026-10-13 選「先不調」（能跑射之後，開槍時的速度會變）

---

## 17. M2 跑射、跳射：原因調查（2026-10-13；只查，沒有改程式）

- 使用者選「查跑射、跳射的原因」：查到後說明做法，同意再改
- 資料：§16.4 同一次實測的 `editor.log`（17:42～17:53）；REDkit 重開會覆寫，所以下面直接引用原文

### 17.1 測試時 Geralt 一直在探索狀態

- 17:42:25 `Changed SuperState from : CombatFists to Exploration` 之後，到 17:53 沒有再切換
  - 這行在玩家狀態改變時寫入（`explorationStateManager.ws:428-434` 每次更新先比對，`:804-828` 寫 log）
- 按鍵情境只有 `Exploration` ↔ `JumpClimb`（`INPUT CONTEXT CHANGED`）
- 每發的 `aim:` 紀錄都是 `combatMusic=false`
- 探索狀態一進入就把戰鬥姿態設成 `PCS_Normal`（`exploration.ws:43`）

### 17.2 衝刺：十字弩拿在手上就不能衝刺（原版規則；已確認）

- `W3PlayerWitcher.CanSprint`（`playerWitcher.ws:10695-10718`）：十字弩不在 `State_WeaponWait`（＝拿在手上）時
  - 戰鬥姿態不是 `PCS_AlertNear` → 回傳 false
  - 是 `PCS_AlertNear` 而且按著衝刺 → `OnRangedForceHolster` 收槍
- 不能衝刺之後 0.25 秒取消衝刺（`locomotionDirectController.ws:834-867` 的 `DisableSprintingTimer`）
- log：收著 AK、邊衝刺邊按扳機，都是前 2～3 發 `PMT_Sprint`（7.0 公尺/秒），接著變 `PMT_Walk`，速度約 1 秒內降到 2.0
  - 例：17:42:33（`Sp7.0 Sp7.0 Sp7.0 Wa6.9 Wa6.5 Wa6.0 … Wa2.0`）、17:42:40、17:42:54、17:51:39、17:52:58、17:53:12
- AK 拿在手上、沒在開火時按 Shift：`OnSprintHolster` 收槍（§13.18）
- 參考 mod（Firearms、FirearmsNextGen、CCO）的 `CanSprint`、`OnSprintHolster` 和原版相同；網路搜尋 2 次，沒找到「拿著十字弩衝刺」的 mod

### 17.3 一般跑步：這次沒有任何一發是 `PMT_Run`（原因未確定）

- 723 發：Walk 620、Idle 74、Sprint 29、**Run 0**（§16.4）
- 整份 `editor.log`（13:36～21:06）的跳躍類型也沒有 `EJT_Run`：`EJT_Walk` 5、`EJT_IdleToWalk` 2、`EJT_Sprint` 1、`EJT_Fall` 1
  - `EJT_Walk`：起跳時 `GetIsRunning()` 是 false（`explorationStateJump.ws:923-949`）；`moveSpeed > 0.85` 才算跑（`locomotionDirectController.ws:369`）
- 走路／跑步的判斷：`CalculateMoveSpeed`（`locomotionDirectController.ws:789-1107`），沒在衝刺時
  - 跑步要同時符合（`:933-938`）：
    - 輸入大小 > `GetInputModuleNeededToRun()`：預設 0.7（`bin\config\platform\pc\platformgameplay.ini` 的 `LeftStickSensitivity=0.7`；`player.ws:1764-1775`）；鍵盤 W 是 1（使用者的 `input.settings:1787`）
    - 沒禁止 `EIAB_RunAndSprint`，或有戰鬥音樂
    - 戰鬥姿態 `PCS_Normal` 且**沒開走路切換**，或 `PCS_AlertFar`
  - 不符合 → `PMT_Walk`（`:1061-1065`）
  - 另一條路：禁止了 `EIAB_Sprint`、沒禁止 `EIAB_RunAndSprint`、沒戰鬥音樂 → 沒按衝刺就走路（`:881-912`）
- 十字弩自己的封鎖（`RangedWeapon.Lock`，`rangedWeapon.ws:374-423`）把 `EIAB_RunAndSprint`、`EIAB_Sprint` 列為例外，不會禁止跑步
- 拿著 AK 移動時，十字弩動畫只蓋上半身：`fullBodyAnimWeight` = false（`rangedWeapon.ws:940-944`）
  - log：移動中的連射全是 `setFullWeight : FALSE`（17:42:33～36 共 61 次、17:43:15～19 共 56 次、17:51:27～29 共 50 次）；站著連射是 TRUE（17:43:05～09 共 45 次）
  - → 腿照一般移動，速度由上面的 `CalculateMoveSpeed` 決定
- 走路切換：探索情境的 Alt（使用者的 `input.settings:1539` `IK_Alt=(Action=WalkToggle)`），每按一次切換（`playerInput.ws:676-682`），不寫 log
- **未確定**：拿 AK 時是哪個條件不成立。log 沒有記錄這些值
  - 不改程式的驗證：不拿 AK、只按 W 看是跑還是走；是走的話按一次 Alt；再只按 W 跑著開槍 → 看 log 每發的 `moveType`

### 17.4 跳躍：起跳就收槍（原版規則；已確認）

- `CExplorationStateJump.StateEnterSpecific`（`explorationStateJump.ws:389-408`）：起跳時 `thePlayer.OnRangedForceHolster( true, true )` → 立即收起（`r4Player.ws:14762-14766` → `rangedWeapon.ws:713-727`、`:204-235`）
- 跳躍中禁止 `EIAB_Crossbow`（`explorationStateJump.ws:261-271`）
- 跳躍中的按鍵情境是 `JumpClimb`（`explorationStateJump.ws:255`；`explorationStateManager.ws:1456` 切換），裡面**沒有綁滑鼠左鍵、中鍵**（使用者的 `input.settings:2352-2450`）
- log：8 次跳躍中有 6 次 AK 拿在手上，都在起跳的同一秒內收槍；其中 4 次正在連射，起跳後馬上記到 `trigger=false`（和最後一發相隔 0.02～0.05 秒）
  - 例：17:53:03，`editor.log` 75657 `Jump: StateEnter` → 75663 `NoSave unlock 'RangedWeapon'` → 75668 `trigger=false … state=State_WeaponWait` → 75673 `crosshair hidden`
  - 其他：17:42:57（63225～63241）、17:51:47、17:52:44（73358～73373）、17:52:50、17:53:26
  - `trigger=false` 是使用者放開，還是按鍵情境切換造成的，log 分不出來
- 其他會收槍的：開始墜落（`explorationStateStartFalling.ws:78`）、攀爬（`explorationStateClimb.ws:448`）、翻滾（`explorationStateRoll.ws:105`）
- 參考 mod 沒有改這段；網路搜尋 2 次，沒找到「空中射十字弩」的 mod

### 17.5 對照 CS2

- CS2 拿 AK 的最高移動速度：215 單位/秒 ≈ 5.46 公尺/秒（`m_flMaxSpeed`：`CLAUDE.md` §8、`docs\ak47_params.md` §6）
- Geralt：衝刺 7.0、走路約 2.0 公尺/秒（log）；跑步速度這次沒有量到

### 17.6 實作：衝刺開槍、起跳不收槍（2026-10-13；wcc_lite 編譯通過，**未實測**）

- 使用者 2026-10-13 選：讓 AK 能衝刺開槍、做邊跳邊射
- `gfg_ak47.ws`：
  - `@wrapMethod(W3PlayerWitcher) CanSprint`：AK 裝備中時，呼叫原版前暫時把 `rangedWeapon` 設成空的 → 衝刺條件和沒拿十字弩時一樣
    - 原版判斷衝刺時用到 `rangedWeapon` 的只有十字弩那段（`playerWitcher.ws:10701-10710`）和 `IsGuarded`（`r4Player.ws:13949-13952`）；`CR4Player.CanSprint`（`r4Player.ws:5662-5729`）呼叫的其他函式都沒用到
  - `@wrapMethod(RangedWeapon) OnSprintHolster`：AK 按衝刺不收槍
  - `@wrapMethod(Crossbow) RaiseOwnerGraphEvents`：戰鬥中衝刺時 AK 照常拿出（原版擋掉：`rangedWeapon.ws:800-806`）
  - `@wrapMethod(CExplorationStateJump) StateEnterSpecific` ＋ `@wrapMethod(CR4Player) OnRangedForceHolster`：起跳的那段程式執行中不收 AK（log `jump: AK kept (holster skipped)`）；跳進水裡照原版收槍（游泳時十字弩拿著就不能移動：`locomotionDirectController.ws:817-825`）
  - 診斷：`trigger=` 和 `auto fire:` 的紀錄多了 `context=`（按鍵情境）、`inAir=`
- 編譯時查到的規則（已寫進 `CLAUDE.md` §6.12）：
  - 同一個包裝函式寫兩次 `wrappedMethod`：第二次報 `Could not find function 'wrappedMethod'`（只寫一次就通過）
  - `thePlayer.gfgKeepAkOnJump = …` 報 `Left hand side is const` → 改成 `@addMethod(CR4Player)` 的設定函式
  - 包裝函式裡寫 `super.CanSprint( speed )` 編譯會過，但官方 Wiki（頁面 36241598）沒寫 annotation 裡的 `super` 指向哪裡 → 不用
- 預期（未實測）：
  - 衝刺開槍：`moveType=PMT_Sprint`、速度約 7.0；按 Shift 不收槍；圓錐約 10.3°（移動比例 1）
  - 起跳：不再出現 `crosshair hidden`；空中能不能繼續射、扳機會不會被放開，看 `context=`、`inAir=`
  - 不確定：衝刺、跳躍時的上半身動畫；空中彈匣打空時的換彈
- 參考：其他會收槍的動作（開始墜落、攀爬、翻滾：§17.4）這次沒改

### 17.7 實測：衝刺開槍、起跳不收槍（2026-10-13；`editor.log` 21:32～21:37）

- 21:32:01 Reload scripts 後測試；使用者回報「跑步可以射，跳起來不行」
- **衝刺開槍：可以**。`PMT_Sprint` 7.0 公尺/秒連射（21:33:00 26 發、21:33:18 39 發、21:33:32 後半段約 45 發）
- **跑步開槍：可以**。`PMT_Run` 5.1 公尺/秒（21:33:24、21:34:28、21:34:59 前 37 發）
  - 同一次也有走路 2.0 的連射；之前沒有 `PMT_Run` 的原因（§17.3）：使用者有沒有按 Alt 沒有回報，未確認
- **跑步、衝刺時沒有舉起 AK**（使用者回報）：手照跑步姿勢擺動，但箭照常射出；站著、走路時有舉起
  - 動畫圖 `gameplay\behaviors\pc\behaviorgraph\pc_overlay.w2beh`（REDkit depot）的字串：
    - 十字弩的移動狀態有兩個：`CrossbowMovement`、`CrossbowAimMovement`
    - 跑步動畫兩種都有：拿著跑 `ex_man_gabriel_run_cycle_fast_forward_01`；瞄準姿勢跑 `ex_man_geralt_gabriel_aim_run`、`ex_man_geralt_gabriel_run_aimpose_*`
    - 讀取的變數（腳本會設定）：`isAimingWeapon`、`isShootingWeapon`、`inAimThrowForOverlay`、`playerMoveTypeForOverlay`、`playerSpeedForOverlay`、`fullBodyAnimWeight` 等
  - 哪個狀態、哪個動畫由動畫圖的轉換條件決定；檔案是二進位，從字串看不出條件
  - AK 的扳機只有「從收著的狀態按下」那一輪會設 `isAimingWeapon` = 1（`SetupCombatAction` → `OnRangedWeaponPress`：`rangedWeapon.ws:44-48`），之後的連射都是 0
- **跳躍**：
  - 起跳不收槍有作用：`jump: AK kept (holster skipped)` 共 7 次
  - 但**起跳那一格扳機就被放開**：21:33:13 第 7 發 `t=497.64` → `Jump: StateEnter` → `trigger=false t=497.64 … context=JumpClimb inAir=false`（同一個引擎時間）；21:33:10 也是 `context=JumpClimb`
    - → 切換到跳躍用的按鍵情境 `JumpClimb` 時，左鍵被放開（`JumpClimb` 沒有綁左鍵：使用者的 `input.settings:2352-2450`）
  - `JumpClimb` 和 `Exploration` 的差別（使用者的 `input.settings`，不含手把）：`JumpClimb` 少了左鍵、中鍵、R、Q、E（互動）、3～7（選法印）、X（叫馬）、Z（鎖定）、Alt（走路切換）、面板鍵（I、K、M、Enter、F1～F11、Home）；只多了 C（`DiveDown`）
  - **空中換彈完成後被收槍**：21:33:09 打空 → 21:33:10 起跳（換彈中）→ 換彈完成、進入 `State_WeaponAim` → 同一秒 `crosshair hidden` → 21:33:11 收槍完成
    - 換彈後進入 `State_WeaponAim`，0.2 秒後原版加上收槍計時器（`rangedWeapon.ws:1413-1428`）；`HolsterWhenMovingTimer` 在跳躍中就讓它收槍（`:649-671` 的 `stateCur == 'Jump'`）
  - 地上換彈後也收過一次：21:33:50 換彈 → 21:33:52 收槍；時間上和同一組計時器相符（`:656-657`：開始移動時），沒有直接證據
- 其他：21:34:16～17 有兩發不是 `auto fire`（`AK reload check` 由原版流程呼叫）→ 中鍵（原版十字弩）射的；之後 21:34:19 照原版收槍

### 17.8 實作：跑步舉槍（試）、空中扳機、換彈後不收槍（2026-10-13；wcc_lite 編譯通過，**未實測**）

- 使用者選：先試設 `isAimingWeapon`、跳躍時不切換按鍵設定、換彈後也不自動收槍
- `gfg_ak47.ws`：
  - 按下扳機：`isAimingWeapon` = 1、`isShootingWeapon` = 0（同原版按下十字弩鍵：`rangedWeapon.ws:44-48`）；放開照舊兩個都設回 0
  - `@wrapMethod(CExplorationStateAbstract) StateEnter`：狀態是 `Jump`、`Land`、`AirCollision`、`IdleJump` 而且 AK 拿在手上時，`m_InputContextE` 改成 `EGCI_Exploration`；否則設回原版的 `EGCI_JumpClimb`（各狀態的設定：`explorationStateJump.ws:255`、`explorationStateLand.ws:119`、`explorationStateAirCollision.ws:79`、`explorationStateIdleJump.ws:29`）
    - 按鍵情境在狀態進入之後才切換：`ChangeStateTo` 呼叫 `StateEnter`（`explorationStateManager.ws:1398-1422`），之後 `PostStateChange` 依 `m_InputContextE` 切換（`:1448-1464`）
    - `StateEnter` 是 `final function`（`explorationStateAbstract.ws:240-250`）；包它編譯會過，執行時有沒有作用看實測（起跳後不該再出現 `INPUT CONTEXT CHANGED JumpClimb`）
  - `GfgCancelAutoHolster`：移除 `HolsterAfterDelay`、`HolsterWhenMovingTimer`，`canHolsterAfterDelay`／`canHolsterAfterDelayHorse` 設 0；原本每發呼叫，現在拿著 AK 時每格畫面也呼叫（`OnGameCameraTick`）
- 可能的副作用（實測時看）：
  - `isAimingWeapon` = 1 時，原版 `InputLockFailsafe` 不會每格重設面向（`rangedWeapon.ws:480-485`）；面向目標（`GetCombatActionOrientationTarget`：`r4Player.ws:5349-5418`）在連射中不會從「移動方向」換成「鏡頭方向」
  - 跳躍中 E、R、選單鍵等探索情境的鍵也有作用
- 相關：拿著 AK 時有存檔鎖（`RangedWeapon.Lock` 的 `CreateNoSaveLock`：`rangedWeapon.ws:421`；拿出時加：`:1182`），收槍才解除（`:429`）；原版每發射完會解除（`State_WeaponShoot`：`:1585-1586`），AK 不經過這個狀態
  - 現在 Shift、換彈後都不收 AK；手動收起的方法之一：快捷選單選別的道具（`playerWitcher.ws:1872-1876`）

### 17.9 實測與動畫圖分析：衝刺、跳躍沒舉槍（2026-10-13）

- 實測（`editor.log` 21:55～21:58，§17.8 的版本）：
  - 使用者：跑步會舉槍並能射；空中能射；「換成其他道具才收槍」也不錯（→ 維持）
  - 使用者：**衝刺（Shift）沒有舉槍**，是跑步動作；**跳躍時沒有維持舉槍**，是跳躍姿勢
  - log：空中有連射（`auto fire … inAir=true context=Exploration`）；起跳後按鍵情境維持 `Exploration`
- 讀動畫圖的工具：`tools\cr2w_dump.py`（使用者 2026-10-13 同意寫；用法見檔頭）
  - `pc_overlay.w2beh`：25477 個物件全部讀得出屬性串列（只有 2 個 `TagList` 沒解）
- `gameplay\behaviors\pc\behaviorgraph\pc_overlay.w2beh`（上半身動畫圖）：
  - 一層層疊：…→ `HorseSummon` → `Parry` → **`Crossbow`**（#15467，最上層的區塊）→ `CombatActionFriendly` → `Right` →…
  - 十字弩狀態機 #17015：狀態 `WeaponDraw`、`WeaponHolster`、`WeaponToNormalTrans`、`WeaponAim`、`WeaponReload`、`WeaponShoot`、`WeaponWait`，子區塊 `AimAnimation`（#17460）、`CrossbowMovement`（#20524，`man_geralt_gabriel_strafe_*`）
  - 狀態機讀的值：輸入姿勢、`isAimingWeapon`、`isShootingWeapon`、`isWeaponLoaded`、`playerMoveTypeForOverlay`、`playerSpeedForOverlay`（`fullStop` 時改用另一個值）、`fullBodyAnimWeight`、`inAimThrowForOverlay`、`isInCombatActionForOverlay`、`canHolsterAfterDelay`、`isSwimmingForOverlay` 等
  - 狀態之間的切換條件**沒有用到移動類型**（用的是上面這些值和 `Crossbow_Draw`／`Crossbow_AimShoot`／`Crossbow_Reload` 等事件）
  - `WeaponAim` 的輸出：`AimAnimation` 的姿勢上再疊 `swordoverride`（#21346 `BlendOverride`）
  - `AimAnimation` 選姿勢：在戰鬥動作中 → 1；否則「移動類型 ≤ 1（站著、走路）且 …」→ 1；否則用 `fullBodyAnimWeight`（#19002 → #18979 → #18956 → #18960，接到 #18501、#18497 的切換）
    - → 站著、走路和跑步、衝刺走不同分支；**跑步和衝刺在這裡沒有分開**
  - 自訂軌道 `IsInWalkRun`（#5142）用在別的區塊（#4012 一帶），不在十字弩區塊
- `pc_gameplay.w2beh`（主動畫圖，7.7 MB）：工具也讀得出來；裡面沒有名稱含 overlay 的節點類別
- 實作（wcc_lite 編譯通過，**未實測**）：
  - `UpdateLocomotion` 的改寫，條件從「衝刺」擴大成「衝刺或在空中」（空中是同一個做法的實驗）
  - 每發的 `spread:` 紀錄加上 `overlaySpeed=`、`fullBody=`、`inAir=`，比對跑步（有舉槍）和空中（沒舉槍）時的值

### 17.10 衝刺、跳躍沒舉槍的原因（2026-10-13 確定）與處理

- 實測（`editor.log` 22:28 之後，§17.9 的版本）：使用者回報衝刺、跳躍**還是沒舉槍**
  - log：衝刺、空中時上半身動畫讀到的值和跑步一樣（`playerMoveTypeForOverlay` = 2、`playerSpeedForOverlay` = 1、`fullBodyAnimWeight` = 0）→ 改寫有生效，但沒有效果
- 原因（`tools\cr2w_dump.py` 讀動畫圖）：
  - Geralt 的實體 `characters\player_entities\geralt\geralt_player.w2ent`：`runtimeBehaviorInstanceSlots` 有 `Gameplay`（`pc_gameplay.w2beh`）和 `PlayerOverlay`（`pc_overlay.w2beh`，**`alwaysOnTopOfStack = True`**）→ 上半身動畫圖疊在主動畫圖的輸出上
  - 舉槍的手臂姿勢來自**主動畫**：`Gameplay` → `Movement`（#1027）→ 移動狀態機（#15146）→ `WalkAndRun`（#25095）裡，走路、跑步的動畫前面都有 `hasCrossbowHeld` 的切換（9 處，例：#25948 換成 `ex_man_geralt_gabriel_aim_run`）
  - 前進的混合（#27906，`modifiedSpeedBasedOnSlope` 控制，0.8／1.0／1.5）：0.8、1.0 是跑步（有十字弩版本），**1.5 是衝刺（`locomotion_sprint_cycle_*`，沒有十字弩版本）**
  - 移動狀態機的 `Jump`（#19915）、`Land`（#19892）、`IdleJump`（#30988）沒有用到 `hasCrossbowHeld`；原版跳躍會收十字弩（§17.4），沒有持弩跳躍的動畫
  - 上半身動畫圖在跑步／衝刺這一支只是在輸入姿勢上疊加瞄準方向的附加動畫（#18587 `LookAtUsingAnimations`）→ 輸入是衝刺、跳躍姿勢時，手不會舉起來
  - 上半身動畫圖另有「整套瞄準動畫」的路線：#18960 ≥ 1（在戰鬥動作中、站著／走路且…、或 `fullBodyAnimWeight` ≥ 1）→ #18497 → #18493；`pc_gameplay.w2beh` 沒有用到 `fullBodyAnimWeight`（0 處），`pc_overlay.w2beh` 有 26 處
- 使用者選（2026-10-13）：
  - **衝刺**：「改成純衝刺，手為衝刺的動作，然後不會開火」
  - **跳躍**：試空中開火用全身瞄準
- 實作（wcc_lite 編譯通過，**未實測**）：
  - 拿掉 §17.9 的 `UpdateLocomotion` 改寫（沒效果）；`spread:` 紀錄保留 `fullBody=`、`inAir=`
  - `GfgTryFire`：`GetIsSprinting()` 而且不在空中時不開火（扳機狀態保留，衝刺結束還按著就接著射）
  - `@wrapMethod(Crossbow) ProcessFullBodyAnimWeight`：AK 拿著、扣著扳機、在空中時設 `fullBodyAnimWeight` = 1（原版空中一律是 0：`rangedWeapon.ws:949-950`；計時器每 0.1 秒呼叫：`:1285`）；空中每發也呼叫一次，不等計時器
  - 預期：空中開火時整個身體換成瞄準姿勢（腿也是）；落地或放開扳機後 0.1 秒內恢復

### 17.11 跳躍也不開火（2026-10-13）

- 實測（§17.10 的版本）：使用者回報空中全身瞄準「超奇怪」→ 決定：**跳躍也先不射**，之後（或許 M5）再處理持槍跳躍
- `gfg_ak47.ws`：
  - 拿掉 `ProcessFullBodyAnimWeight` 的改寫（空中全身瞄準）；`spread:` 紀錄拿掉 `fullBody=`、`inAir=`
  - `GfgTryFire`：`GetIsSprinting() || IsInAir()` 時不開火；扳機狀態保留，衝刺結束、落地時還按著就接著射
  - 保留：起跳不收 AK（§17.6）；跳躍時維持探索按鍵情境（§17.8）→ 扳機在起跳時不會被放開，落地後能接著射
- 實測（`editor.log` 22:49:27 Reload scripts 之後；使用者回報「OK」）：
  - 749 發，空中 0 發（`auto fire … inAir=true` 0 筆）；5 次跳躍都 `jump: AK kept`
  - `moveType=PMT_Sprint` 的 2 發（22:50:11、22:50:24）都在停火 1.6～1.7 秒後、速度 7.0：放開 Shift、衝刺剛結束那一格就接著射（`GetIsSprinting()` 已是 false，`playerMoveType` 還沒更新），下一發就是跑步速度 → 符合設計
- commit `f8b6756`

---

## 18. 射程：AK 的箭飛到 208 公尺（2026-10-13）

### 18.1 原版的射程限制

- `ReleaseProjectiles2`（`playerBoltProjectile.ws:323-414`）把射程傳給引擎的 `ShootProjectileAtPosition`／`ShootProjectileAtBone`（`:374-377`）
  - 平常是 `MAX_THROW_RANGE`（`:348`），潛水時是 `UNDERWATER_THROW_RANGE`（`:341-345`）
  - `MAX_THROW_RANGE = 25.0`、`UNDERWATER_THROW_RANGE = 5.0`，都是 `const`（`gameParams.ws:101-106`）
  - 炸彈、飛刀、瞄準射線也用 `MAX_THROW_RANGE`（`petard.ws:136`、`throwingKnifeProjectile.ws:97`、`playerAiming.ws:326`）→ 不能、也不該改這個常數
- 類別：`W3BoltProjectile` → `W3ArrowProjectile` → `W3DeflectableAdvancedProjectile` → `W3AdvancedProjectile`
  - `ShootProjectileAtPosition`／`AtBone` 在 `W3AdvancedProjectile` 包了一層 `final function`：呼叫原生函式後再呼叫 `OnProjectileShot`（`advancedProjectile.ws:60-78`）
- 飛到射程：引擎呼叫 `OnRangeReached()`（宣告：`ProjectileTrajectory.ws:96`）
  - 箭（`W3ArrowProjectile`）：`StopAllEffects()`，2 秒後 `TimeDestroy` 刪掉（`arrowProjectile.ws:36-45`）；**沒有**呼叫 `StopProjectile()`
  - 有的投射物會自己呼叫 `StopProjectile()`（例：`advancedProjectile.ws:696`、`leshyProjectile.ws:104`）
  - `W3DeflectableAdvancedProjectile`（`advancedProjectile.ws:127-207`）沒有覆寫 `OnRangeReached`
  - 到射程的那一刻，引擎會不會讓箭停下來：原生程式，腳本看不到 → ✅ 實測不會停（§18.4）
- 現成做法：CCO 整個覆寫 `ReleaseProjectiles2`，射程與速度乘上弩的 `Range` 參數（CCO `playerBoltProjectile.ws:589-595`）

### 18.2 弩箭的速度與角度（`tools\cr2w_dump.py` 讀模板）

- `<REDKIT_DEPOT>\items\weapons\projectiles\witcher_bolts\bodkin_bolt.w2ent`：`W3BoltProjectile` 物件只覆寫 `projSpeed : Float = 60.0`（另有 `projectileName = 'arrow'`）
  - 引用的父模板 `base\bolt_base.w2ent`：87 個物件，是 `CEntity`、元件和特效（`CFXDefinition` 等），沒有 `projSpeed`、`projAngle`
  - → `projAngle` 是腳本預設 5（`advancedProjectile.ws:26`）；進水改 2、出水改回 5（`arrowProjectile.ws:441`、`:430`）
- 速度 60 公尺／秒：25 公尺 0.42 秒、100 公尺 1.7 秒、208 公尺 3.5 秒
- 軌跡（CCO 註解寫是實測的公式；我們沒驗證）：起點到目標的直線，再往上加 `距離 × tan(角度) ÷ π × sin(t·π)`，t 從 0（起點）到 1（目標）（CCO `playerAiming.ws:671-675`）
  - 角度 5° 時，中段最多比直線高：25 公尺 0.7 公尺、100 公尺 2.8 公尺、208 公尺 5.8 公尺
  - t = 1 時到達目標點 → 終點仍是準心指的點

### 18.3 實作（wcc_lite 編譯通過，**未實測**）

- 使用者選「只改射程」；箭速、角度之後再說（屬於 `CLAUDE.md` §7 的「命中方式」）
- `gfg_ak47.ws`：
  - `ThrowProjectile` 包裝（原本就在判斷 AK）：不在水中時，在箭上記下 `gfgAkRange` = `GfgRange()`（208 公尺）
  - `@wrapMethod(W3AdvancedProjectile)` 的 `ShootProjectileAtPosition`、`ShootProjectileAtBone`：`gfgAkRange` > 0 時把射程參數換掉，其他參數照原版
    - 包 `final` 函式的先例：`StateEnter`（§17.8 編譯、§17.9 實測有作用）
    - 自動瞄準（打骨骼）那條路也換成 208 公尺；自動瞄準本身沒動
  - 水中照原版 5 公尺
  - 診斷 log（`[Script_GFG]`）：
    - `bolt shot: range 25 -> 208 target distance=…`：這一發用的射程、離目標點多遠
    - `bolt collision: flown=… t=… entity=… groups=…`：飛行中的碰撞（飛了幾公尺、幾秒、碰到的實體、碰撞群組）
      - 只記 `isActive` 時：箭停下來之後，原版就不處理碰撞（`playerBoltProjectile.ws:159-160`）
    - `bolt range reached: flown=… t=…`：飛到射程時飛了幾公尺、幾秒

### 18.4 實測（2026-10-13；`editor.log` 23:22:02 Reload scripts 之後，GFG 紀錄 23:22:58～23:23:43）

- 166 發都是 `bolt shot: range 25 -> 208` → 射程有換掉
- 打牆（使用者用 `spawnPath` 生成的 `wall_super_wide`，紀錄的實體名稱 `wall_super_wide361`，群組 `Static`）：149 次，距離 12.1～**42.6 公尺**，其中 75 次超過 25 公尺 → 25 公尺外打得到
  - 使用者回報：**牆上會有箭，幾秒後消失**
    - 原版：箭打到有元件的 `Static`（牆）就停下，5 秒後 `TimeDestroy`（`arrowProjectile.ws:98-114`）；沒有元件的 `Terrain`／`Static` 也是 5 秒（`playerBoltProjectile.ws:182-203`）
    - §15.2 當時回報「箭沒有插在牆上」；這次有插上，差別的原因沒查
- 速度：第一次 `range reached` 在 207.1 公尺、3.467 秒 → 約 59.7 公尺／秒，和模板的 `projSpeed` 60 一致
- ✅ **箭到射程後不會停**（§18.1 的 ❓）：
  - 13 發射向天空，`bolt range reached` 卻有 1570 筆：到射程之後**每一格都觸發一次**，每筆的 `flown` 多約 1 公尺
  - 最後一筆 327.5 公尺、5.466 秒 → 到射程後照原速再飛 2 秒，才被 `TimeDestroy` 刪掉（`arrowProjectile.ws:40-44`）
  - `OnRangeReached` 沒有改 `isActive`，所以那 2 秒內還會處理碰撞（這次紀錄到的碰撞最遠 328.5 公尺，`Water`）
  - 🔶 推論：原版射程 25 公尺時是同一套機制 → 箭飛過 25 公尺後尾跡消失，但還會再飛約 120 公尺，途中仍可能打到東西（沒有用 25 公尺實測）
- 其他碰撞：`Water` 141 筆（箭飛過水面；原版碰到水只播聲音、不停下：`arrowProjectile.ws:115-127`）；`Terrain` 4 筆（8.0～18.7 公尺）

### 18.5 牆壁、地面上的箭：不限時間、最多 100 支（2026-10-13；wcc_lite 編譯通過，**未實測**）

- 使用者要求箭留久一點，選「不限時間、最多 100 支」（像 CS2 的彈孔）；打在角色身上的照原版
- 原版：箭打到牆壁、地面停下後排 5 秒刪除（`arrowProjectile.ws:98-114` 的 `Static`；`playerBoltProjectile.ws:182-203` 的沒有元件的 `Terrain`／`Static`），兩處都把 `isScheduledForDestruction` 設成 true
  - 弩箭的碰撞群組只有 `Ragdoll`、`Static`、`Terrain`、`Water`、`Character`（`playerBoltProjectile.ws:32-42`）
- `gfg_ak47.ws`：
  - `OnProjectileCollision` 包裝：原版處理後，AK 的箭的 `isScheduledForDestruction` 從 false 變 true、而且群組有 `Static` 或 `Terrain` → `RemoveTimer('TimeDestroy')`，交給玩家身上的清單
  - `CR4Player.GfgAddStuckBolt`：先移掉已經不在的，加到最後；超過 `GfgMaxStuckBolts()`（100）就 `Destroy()` 最舊的（寫法照 `RemoveDroppedItem`：`actor.ws:4758-4779`）
  - 紀錄：`bolt stuck: kept=… removed=…`
- `bolt range reached` 改成只記第一次（原版第一次就把 `isScheduledForDestruction` 設成 true：`arrowProjectile.ws:40-44`）

---

## 19. 換彈後的姿勢鎖住（2026-10-13）

### 19.1 現象（使用者回報）

- 換彈結束時**沒按**左鍵 → 手垂下，之後開槍也不舉槍（箭照樣射出）
- 換彈結束時**按著** → 一直舉著
- 兩種都持續到下次換彈

### 19.2 原因（`pc_overlay.w2beh` 十字弩狀態機 #17015，`tools\cr2w_dump.py --tree 17015`）

- `editor.log`（23:23～23:29）：換彈後腳本一律是 `State_WeaponAim`
  - 腳本只有一個地方會切到這個狀態：動畫圖進入 `WeaponAim` 時的 `OnWeaponAimStart`（`rangedWeapon.ws:98-103`；動畫圖狀態節點的 `becomesCurrentStateScriptEvent`，由玩家轉給十字弩：`r4Player.ws:14734-14745`）
- 換彈 → `WeaponAim` 的轉換會寫內部變數 `shootWeaponComplete`：
  - 瞄準中（`ANIMEVENT RaiseWeapon AND isAimingWeapon = 1` 等，#17346、#17304、#17318、#17332、#17384）：寫 0（檔案省略＝預設值）
  - 沒瞄準（`isShootingWeapon = 0 AND isAimingWeapon = 0 AND isWeaponLoaded = 1 AND …`，#17422、#17436）：寫 1.0
- `AimAnimation`（#17460）讀它決定姿勢（#18663 數學節點、#18907 比較節點）
- 其他會改寫它的：`WeaponShoot`、`WeaponDraw`、`WeaponHolster` 進入時（#17764、#22169、#21838 有 `setValueOnActivationAsWell`）
- 原版十字弩每一發都經過 `WeaponShoot` → 值一直被重寫；**AK 直接觸發射擊，不經過 `WeaponShoot`** → 值保留到下次換彈
- 條件裡省略的比較方式、比較值當作 `CF_Equal`、0：整個狀態機裡明寫的只有 `CF_NotEqual`、`CF_Greater`、`CF_GreaterEqual`、`CF_LessEqual`，比較值只明寫 1、2、3，和「預設值不寫入檔案」一致（🔶 推論）
- 動畫圖的其他切換（`*`＝省略）：`WeaponHolster` 只有 `Crossbow_AimShoot` 事件能回 `WeaponAim`（#21502）；`WeaponWait` 在 `isAimingWeapon = 1` 時進 `WeaponDraw`（#21587）；`WeaponAim` 在兩個變數都是 0 時進 `WeaponHolster`（#21310），但實測放開扳機大多沒有收槍，原因沒查

### 19.3 修法（使用者選「一律舉槍」；wcc_lite 編譯通過，**未實測**）

- 「放開就放下」不採用：動畫圖要讓手放下只能經過 `WeaponHolster`，而腳本一進收槍狀態就會真的收起十字弩（`rangedWeapon.ws:1654-1677`）
- `GfgSetTrigger` 放開時：換彈中（`State_WeaponReload`）或還沒裝上箭（`deployedEnt` 是空的）→ 先不把 `isAimingWeapon` 設回 false
  - → 換彈結束時一律走「瞄準中」的轉換，寫入 0 → 舉槍
- `@wrapMethod(RangedWeapon) OnWeaponAimStart`：回到瞄準狀態後，AK 的扳機沒按著 → `isAimingWeapon` 設回 false；紀錄 `aim start: trigger=…`

---

## 20. 生成怪物後 Geralt 不能動（2026-10-13，調查中）

### 20.1 現象（使用者回報）

- 生成怪物時，有時 Geralt 完全不能動，直到殺死怪物，或被攻擊（不確定）才恢復

### 20.2 已查到的（都還沒證實是原因）

- `editor.log` 看不出卡住的時間點：主控台指令不會寫進紀錄；這次的狼在 23:46～23:50（`aim:` 紀錄的 `displayTarget`）
  - 戰鬥中（`context=Combat`）AK 常被收起又拔出（`crosshair hidden` → `State_WeaponWait`，例：23:47:41、23:48:20、23:48:35）
- 原版會鎖「移動」的只有三處：`CombatActionFriendly`（`r4Player.ws:13189`）、摸馬（`:16199`）、游泳踉蹌（`swimming.ws:936`）
  - `CombatActionFriendly`：`OnCombatActionFriendlyStart` 鎖、`OnCombatActionFriendlyEnd`／`OnCombatActionEnd` 解（`r4Player.ws:13128-13200`）
- 戰鬥動作開始時 `SetBIsInputAllowed(false, 'OnCombatActionStart')`（`r4Player.ws:13045-13056`），`OnCombatActionEnd` 才恢復（`:13154`）
  - 十字弩的戰鬥動作由 `ExitCombatAction` 結束（`combatActionType` 是 `CAT_Crossbow` 時送 `ForceAlertToNormalTransition`／`ForceBlendOut`：`rangedWeapon.ws:987-1003`）
  - 原版每射完一發、玩家在推移動鍵時會呼叫它（`OnWeaponShootEnd`：`rangedWeapon.ws:164-172`）；AK 不經過射擊狀態
  - AK 第一次按左鍵會 `SetupCombatAction( EBAT_ItemUse, BS_Pressed )`（`gfg_ak47.ws` 的 `OnCbtAttackWithAlternateLight`），沒有對應的 `BS_Released`
- 原版沒有現成的主控台指令能印出或解除動作鎖

### 20.3 偵測紀錄（使用者同意；wcc_lite 編譯通過，**未實測**）

- `CR4Player.GfgCheckStuck`，每格由 `OnGameCameraTick` 包裝呼叫；不管有沒有拿 AK 都偵測；只寫紀錄、不改行為
- 「推著移動鍵」：移動軸 `GI_AxisLeftX／Y` 不是 0（同原版 `HandleMovement`：`player.ws:588-589`），或 `bLAxisReleased` 是 false（`:631-684`）
- 推著移動鍵、速度不到 0.1 公尺／秒超過 1 秒 → 記一次 `stuck: …`；恢復時記 `stuck end: …s`
  - 內容：移動軸、`movementAllowed`、移動鎖的來源（`GetActionLocks`：`player.ws:360`）、`inputAllowed`、`combatActionAllowed`、`inCombatAction`、`friendly`、`combatActionType`、玩家狀態、探索子狀態、按鍵情境、戰鬥姿態、十字弩狀態、`fullBodyAnimWeight`
- 推著牆走也會記（不是真的卡住），看內容判斷

### 20.4 偵測結果（2026-10-14；`editor.log` 00:03:48～00:07:11）

- 使用者回報：又卡住；前進後退都不能動；**按著 Shift 就能前進，但不是衝刺**
- `stuck:` 18 次，內容全部一樣（只有移動軸、`combatActionType` 0 或 2 不同）：
  - `movementAllowed=true`、`locks=`（空）、`inputAllowed=true`、`combatActionAllowed=true`、`inCombatAction=false`、`friendly=false`
  - `state=CombatSteel`、`substate=CombatExploration`、`context=Combat`、`stance=PCS_AlertNear`、`weapon=State_WeaponAim`、**`fullBody=1`**
  - → §20.2 的兩個猜測（移動鎖、戰鬥動作沒結束）都不是
- 原版 `ProcessFullBodyAnimWeight`（`rangedWeapon.ws:903-985`；拿著十字弩時每 0.1 秒呼叫：`:1285`）：
  - `PCS_AlertNear`（附近有敵人）→ `fullBodyAnimWeight` = 1（`:916-917`、`:919-920`）
  - 改回 0 的條件只有：在 `PCS_Normal` 推移動鍵（`:940-943`）、衝刺（`:945-946`、`:960-961`）、收槍中、空中、丟東西、`PMT_Run`／`PMT_Sprint`（`:957-958`）等
  - → 附近有敵人時，除非已經在跑或衝刺，一律全身瞄準
- 🔶 推論：全身瞄準的動畫（§17.9 的 #18497 → #18493 那條路）連腿都換掉，沒有走路的動作 → 推移動鍵也不會動；要跑起來才會變回 0，但動不了就跑不起來 → 卡死
  - 證據：18 次都是 `fullBody=1` 而且速度 0；使用者按 Shift（衝刺 → `:945-946` 設成 0）就能動
- 原版的脫困方式：射完或放開瞄準後自動收槍
  - 計時器：`HolsterAfterDelay`（`:640-646`）、`HolsterWhenMovingTimer`（推移動鍵就收：`:649-671`）
  - 加上的地方：`State_WeaponAim` 進入時（`:1300-1311`）、放開瞄準時（`:1413-1428`，**戰鬥中 0 秒就收**：`:1417-1418`）、射擊狀態（`:1497-1578`）
  - AK 每格都移除這兩個計時器、把 `canHolsterAfterDelay` 設 0（`GfgCancelAutoHolster`，使用者選「只有換成其他道具才收」：§13.18、§17.8）→ 原版的脫困方式沒了
  - 殺死怪物 → 不再是 `PCS_AlertNear` → 恢復；被攻擊為什麼會恢復沒查

### 20.5 修法：推移動鍵時改上半身瞄準（使用者 2026-10-14 選；wcc_lite 編譯通過，**未實測**）

- 不採用「恢復原版：移動就收槍」：和「只有換成其他道具才收」衝突
- `@wrapMethod(Crossbow) ProcessFullBodyAnimWeight`：原版算出 1、AK 拿著、推著移動鍵（`bLAxisReleased` 是 false）→ 改成 0
  - 同原版在探索時推移動鍵的處理（`rangedWeapon.ws:940-943`）
  - 游泳（`:931-938`）、中鍵瞄準 `AimThrow`（`:963-964`）照原版
  - 站著不動時照原版（附近有敵人就全身瞄準）
- 卡住偵測（§20.3）先留著，用來確認修好

### 20.6 實測：改上半身後還是卡住（2026-10-14；`editor.log` 00:56:57～00:57:58）

- `stuck:` 7 次，`fullBody=0`（修正有生效），其餘欄位和 §20.4 一樣 → 全身瞄準不是唯一原因
- 主動畫圖 `pc_gameplay.w2beh` 的移動狀態機 #15146（`tools\cr2w_dump.py --tree 15146`）：
  - 附近有敵人時走路的狀態是 `WalkAlertNear`（#17975），底下的 `Walk with weapon` 只有劍、拳頭版本
  - `Idle` 出去的每一條轉換都要 `moveSpeed > 0`（例：`Idle → WalkAlertNear`：`moveSpeed > 0 AND playerMoveType <= 1 AND playerCombatStance != 3 AND != 0`）
- `moveSpeed` 不是腳本設的變數（腳本沒有 `SetBehaviorVariable('moveSpeed'…)`）；移動控制器 `CR4LocomotionPlayerControllerScript.UpdateLocomotion`（`locomotionDirectController.ws:103-`）：
  - `IsUITakeInput()` 時整個跳過（`:122`；只有快捷輪盤會設：`hudModuleRadialMenu.ws:393`、`:468`）
  - `GetIsMovable()`（`isMovable` 而且移動沒被鎖：`player.ws:1476-1479`）不成立時速度設 0（`:168`、`:260-266`）
  - 速度：`CalculateMoveSpeed()`（`:789-1107`）；附近有敵人、沒衝刺時是走路速度 `speedWalkingMax`、`PMT_Walk`（`:1061-1071`）；衝刺時 `speedSprinting`、`PMT_Sprint`（`:928-932`）
- 原因還沒找到 → 偵測紀錄加一行 `stuck detail:`：`GetIsMovable()`、`IsUITakeInput()`、`playerMoveType`、`rawPlayerSpeed`、`GetRelativeMoveSpeed()`、動畫圖變數 `playerMoveType`、`inputDirectionIsNotReady`、衝刺中、戰鬥中（wcc_lite 編譯通過，**未實測**）

### 20.7 卡住時按 Z 不能鎖定（使用者 2026-10-14 回報）：原因是十字弩瞄準時的動作鎖

- 按 Z（`OnCbtCameraLock`：`playerInput.ws:3497-3525`）要 `EIAB_CameraLock`（`:3503`）、`EIAB_HardLock`（`:3510`）都被允許
- `State_WeaponAim` 進入時，如果正在瞄準或射擊就呼叫 `Lock()`（`rangedWeapon.ws:1300-1313`），離開這個狀態才 `Unlock()`（`:1318-1320`）
- `Lock()`（`rangedWeapon.ws:374-423`）：`BlockAllActions('RangedWeapon', true, 例外)` ＋ 存檔鎖
  - `BlockAllActions`（`playerInput.ws:378-390`）對每個動作各登記一個鎖（`:388`），但一律跳過 `EIAB_CameraLock`、`EIAB_NonPatternAlternatives`（`:385`）
  - `EInputActionBlock`（`playerTypes.ws`）51 個裡，例外 31 個，再扣掉上面兩個，被鎖的 18 個：
    - `EIAB_CallHorse`、`EIAB_Counter`、`EIAB_DismountVehicle`、`EIAB_DrawWeapon`、`EIAB_Explorations`、`EIAB_FastTravel`、`EIAB_FastTravelGlobal`、**`EIAB_HardLock`**、`EIAB_HighlightObjective`、`EIAB_MountVehicle`、`EIAB_Noticeboards`、`EIAB_OpenGwint`、`EIAB_OpenMeditation`、`EIAB_SpecialAttackHeavy`、`EIAB_SpecialAttackLight`、`EIAB_ThrowBomb`、`EIAB_Undefined`、`EIAB_UsableItem`
  - → 擋住 Z 的是 `EIAB_HardLock`（`EIAB_CameraLock` 沒被鎖，所以 `OnCbtCameraLock` 會走到 `HardLockToTarget( false )`：`playerInput.ws:3517-3520`）
  - 移動相關的（`EIAB_Movement`、`EIAB_RunAndSprint`、`EIAB_Sprint`、`EIAB_Jump`、`EIAB_Dodge`、`EIAB_Roll`）都在例外裡 → 不是移動卡住的原因
- 原版瞄準很快就結束（射出後離開 `State_WeaponAim`）；AK 一直待在 `State_WeaponAim` → 鎖一直在
  - 換彈後一律舉槍（§19.3）讓換彈結束時一律是「瞄準中」→ 每次都會 `Lock()`
- 使用者選「先不處理」（2026-10-14）

### 20.8 `stuck detail:` 實測（2026-10-14；`editor.log` 01:06:43 Reload scripts 之後，01:07:33～01:08:53）

- 使用者回報：生成 30 隻狼，走過去**被包圍**後就不能動
- 4 次卡住，`stuck detail:` 全部一樣：
  - `movable=true`、`uiTakesInput=false`、`moveType=PMT_Walk`、`rawSpeed=0.8`、**`relSpeed=0.6`**、`behMoveType=1`、`inputNotReady=0`、`sprinting=false`、`inCombat=true`
  - → 移動控制器有在要求移動（`GetRelativeMoveSpeed()` 0.6），輸入也就緒；實際速度卻是 0
- 這次 `state=CombatFists`（之前是 `CombatSteel`）；`fullBody=0`
- 卡住期間紀錄裡有大量「狼的咬擊判定撞到別隻狼」（`Script_ItemCollision`，例：`wolf_lvl38`、`41`、`42`、`57`、`86`、`91`、`111`、`112`、`114`、`116`）→ 很多隻狼擠在附近
- 🔶 推論：被狼的身體擋住（要求移動正常，實際沒有位移）；還沒證實，也還沒確認原版（不拿 AK）會不會一樣
- 偵測再加一行 `stuck around:`：5 公尺內、1.5 公尺內活著的角色數、最近的距離（`GetActorsInRange`：`actorsStorage.ws:44`；`VecDistance2D`：`math.ws:368`）；wcc_lite 編譯通過，**未實測**
- 驗證方法（請使用者做）：
  - 不拿 AK（拔劍）被一樣多的狼包圍 → 能不能走
  - 拿著 AK、附近有敵人但沒被包圍（狼在遠處）→ 能不能走

### 20.9 對照測試結果與新線索（2026-10-14）

- 使用者回報（這次沒有重新載入腳本，`stuck around:` 沒有紀錄）：
  - **不拿 AK 被包圍：可以走、可以鎖定** → 不是單純被狼擋住，§20.8 的推論不成立
  - **拿 AK、只有兩隻狼**：靠近時先慢慢走（原版遇到怪物會慢走），一陣子後就不能動（`editor.log` 01:15:38，8.9 秒，內容和 §20.8 一樣）
  - 慢走時，血條出現在「大概畫面對到」的那隻狼頭上，轉動畫面會換；**進入不能走的階段後，血條固定在同一隻，牠死了也不換**；此時也不能瞄準
- 原版：十字弩拿著（不是 `State_WeaponWait`）、沒有中鍵瞄準時，畫面目標（血條）＝**滑動目標** `slideTarget`（`r4Player.ws:6749-6753`）
  - 十字弩流程裡設定滑動目標的地方在射擊狀態（`rangedWeapon.ws:1536`、`:1598`），AK 不經過；其他地方：拿出時的 `ProcessCombatActionBuffer`（`r4Player.ws:10597-10605`）、格擋（`:1968`、`:9390`）、戰鬥動作的目標選擇（`:9596`、`:11148`、`:11179`）、近戰（`combat.ws:2063`、`:2489`）等
  - → 推論：滑動目標一被設定（例如被狼攻擊時），AK 又一直在瞄準狀態，它就不再更新 → 血條卡住
- 可疑的機制：動畫事件 `RotateToTarget`（`r4Player.ws:3913-3971`）建立移動調整請求，**`DontUseSourceAnimation`（不用動畫的位移）**、`ReplaceRotation`，`OT_Actor` 時轉向滑動目標（`:2712-2729`）；持續型的請求綁在動畫事件上
  - 如果這個請求一直有效 → 只轉向、不前進；還沒證實
- 排除：`IsActorLockedToTarget`／`LockToTarget`（只用在法印：`playerWitcher.ws:7085-7119`）；`DelayedDisableFindTarget`（腳本裡沒有地方加這個計時器）；`hasCrossbowHeld` 在移動狀態機只用在跑步急轉（`RunQuickTurn`）；`GetIsAimingCrossbow`（只用在放開按鍵、騎馬、NPC 同步動畫）
- 偵測再加一行 `stuck adjust:`：移動調整器有沒有有效的請求（全部／轉向／位移／`RotateToTarget`：`movementAdjustor.ws:4-21`）、滑動目標（死了標 `(dead)`）、畫面目標、朝向目標；wcc_lite 編譯通過，**未實測**

### 20.10 原因找到：上半身動畫圖在「附近有敵人＋走路」時強制全身瞄準（2026-10-14）

- 實測（`editor.log` 01:24:30 Reload scripts 之後，01:24:45～01:26:34，8 次卡住）：
  - `stuck adjust:` 全部 `any=false rotation=false translation=false rotateToTarget=false` → 移動調整請求**不是**原因（§20.9 的懷疑不成立）
  - `stuck around:` 1.5 公尺內 0 隻、最近 1.8～5 公尺 → 不是被擋住
  - 滑動目標大多 `none`，偶爾是狼；朝向大多 `OT_Actor`
- 主動畫圖（`pc_gameplay.w2beh`，整份 568414 行）：
  - 不認得 `Crossbow_*` 事件；最上層狀態機 `Gameplay`（#2）有 `Movement`（#1027）、`CombatAction`（#1045）等；`CombatAction` 會靠 `ForceBlendOut`（#3569）、`ForceAlertToNormalTransition`（#1892）等離開
  - `Movement` 成為目前狀態時呼叫 `OnCombatActionEndComplete` → `SetBIsInCombatAction(false)`（`r4Player.ws:13357-13372`）；卡住時 `inCombatAction=false` → 主動畫圖在 `Movement`
  - `combatActionType` 的值：從 `editor.exe` 讀出的列舉字串順序 `CAT_Attack`、`CAT_SpecialAttack`、`CAT_Dodge`、`CAT_Roll`、`CAT_ItemThrow`、`CAT_LayItem`、`CAT_CastSign`、`CAT_Pirouette`、`CAT_PreAttack`、`CAT_Parry`、`CAT_Crossbow`…；`combat.ws:1999` 用數字 8 做「攻擊前接近」（`PreAttack_Rotation`）→ 從 0 數起吻合 → **2 = `CAT_Dodge`**（卡住時的 2 只是最後一次的戰鬥動作）
- **上半身動畫圖選姿勢的邏輯**（`pc_overlay.w2beh` #18960，§17.9 的「站著／走路且…」）：
  - 全身瞄準 ＝ `isInCombatAction` ≥ 1（#18971）
  - 或（曲線 #18994 換算的 `playerCombatStance` = 1（#18983、#18987）**而且** 移動類型 ≤ 1（站著、走路：#19002））
  - 否則才用 `fullBodyAnimWeight`（#18949）
  - 移動類型那個輸入（#19006）接的是變數節點 #17129 **`playerMoveTypeForOverlay`**；上半身動畫圖裡沒有叫 `playerMoveType` 的變數（8 個變數節點都是 `playerMoveTypeForOverlay`）
  - 曲線 #18994 的點存在自訂資料，工具解不出來；卡住時一律是 `PCS_AlertNear`
- → 附近有敵人時，移動控制器只給「走路」（`locomotionDirectController.ws:1061-1071`），移動類型 = 1 → 強制全身瞄準 → 腿沒有走路的動作 → 卡住
  - §20.5 改 `fullBodyAnimWeight` 沒用：這條路根本不看它
  - 衝刺時移動類型 3 → 條件不成立 → 能動（使用者觀察）
- 修法（延續使用者選的「推移動鍵時改上半身」；wcc_lite 編譯通過，**未實測**）：
  - `@wrapMethod(CR4LocomotionPlayerControllerScript) CalculateMoveSpeed`：原版算完後，速度 > 0、移動類型 ≤ 走路、AK 拿著、不在游泳、不在中鍵瞄準 → `playerMoveTypeForOverlay` 設成 `PMT_Run`（設定方式同原版 `:1094-1095`）
  - 只改給上半身看的值，實際移動照原版（戰鬥中慢走）
  - §20.5 的 `ProcessFullBodyAnimWeight` 包裝保留（上半身改看 `fullBodyAnimWeight` 時要是 0）
  - `stuck detail:` 加 `overlayMoveType=`

### 20.11 實測：能動了，但走路姿勢是拳頭的防禦姿勢 → 改成照野外的規則跑（2026-10-14）

- 使用者回報：**解決了**（能走）；但按 W 邊走邊射時是防禦姿勢（截圖：雙手護在胸前），不是野外邊走邊射的姿勢
- 原因（§20.6 的移動狀態機）：附近有敵人時走路的狀態 `WalkAlertNear` 底下只有劍、拳頭版本；沒拔劍時 Geralt 是 `CombatFists` → 拳頭的戰鬥走路，上半身瞄準疊在上面
  - 有十字弩版本的走路／跑步動畫在 `Walk_Run_Cycles`（#25090，直接在移動狀態機 #15146 底下）→ `WalkAndRun`（§17.10）
  - 附近有敵人時要跑：`DirectionalStart → DirectionalStartRun → Run`（例：`runInputPressed ≥ 1`，或 `latchedWalkOrRun ≥ 1`）；`WalkAlertNear → DirectionalStart` 在 `playerCombatStance ≠ 0 AND playerMoveType ≥ 2`
  - 原版附近有敵人只能走：`CalculateMoveSpeed` 的跑步條件只有 `PCS_Normal`、`PCS_AlertFar`（`locomotionDirectController.ws:933-941`）
- 使用者選「照野外的規則跑」（速度會變快；CS2 也是全速移動、靠散布懲罰）
- 實作（wcc_lite 編譯通過，**未實測**）：`CalculateMoveSpeed` 包裝改成
  - 原版算完是走路、AK 拿著、不在游泳或中鍵瞄準時：
    - 附近有敵人（`PCS_AlertNear`）而且照原版野外的條件可以跑（推的幅度 > `GetInputModuleNeededToRun()`、允許跑步或有戰鬥音樂、沒切換成慢走）→ 改成 `PMT_Run`、速度 `MinF( 推的幅度, speedRunning )`，並照原版跑步分支設 `forceWalkSpeed` 0、`playerMoveType`、`ikWeight`（`:1056-1059`、`:1094-1097`）
    - 推的幅度照原版取（`:805-814`：`_inputMagLastCached` 或 `m_InputO.GetModuleF()`）
  - 不論走或跑，`playerMoveTypeForOverlay` 設成跑步（§20.10）
  - 包裝裡讀寫移動控制器的私有欄位（`_inputLocoEnabled`、`_inputMagLastCached`）、寫 `player.playerMoveType`：wcc_lite 編譯通過

### 20.12 實測：戰鬥中照野外規則跑 OK；Z 鎖定改成可用（2026-10-14）

- 使用者回報：**完美解決，現在就是我要的**（附近有敵人時跑步、舉槍姿勢和野外一樣）
- 使用者回報：血條已經會跟著準心對到的怪物（§20.9 的「血條卡住」這次沒有出現；原因沒查）
- 使用者回報：Z 還是不能鎖定 → 選「只解除 Z 鎖定」（其他 17 個動作和存檔鎖維持原版）
- 實作（wcc_lite 編譯通過，**未實測**）：`OnGameCameraTick` 包裝裡，AK 拿著時每格 `UnblockAction( EIAB_HardLock, 'RangedWeapon' )`（`player.ws:327`；沒有這個鎖時直接返回：`playerInput.ws:251-254`）
  - 可能的交互作用（未驗證）：硬鎖定時鏡頭由鎖定控制，後座力轉鏡頭、子彈飛向準心的效果可能不同；原版「鎖定敵人且有戰鬥音樂時箭射向敵人身體」（`playerBoltProjectile.ws:353-377`）也會發生

### 20.13 鎖定時準心移到被鎖定的怪物身上（2026-10-14）

- 使用者實測：**Z 可以鎖定了**；後座力晃鏡頭還在（算正常）；子彈打到準心；但鎖定時滑鼠不能轉鏡頭，準心固定在畫面中央，**不在鎖定的怪物身上**
- `editor.log`（01:50～01:54，鎖定時的射擊多數 `hardLock=true combatMusic=true`）：箭大多打在準心射線碰到的地面（`Terrain`，距離和 `aim: distance` 一致）
  - 原版「鎖定時箭飛向敵人身體」對狼沒有作用：原版沒有虛擬控制器目標時找 `torso2` 骨頭（`playerBoltProjectile.ws:364-367`），狼可能沒有這根骨頭（未查證），骨頭索引 < 0 就改用位置（`:374-377`）
- 使用者要的：**準心鎖定被鎖定的怪物，其他照舊**
- 參考的原版寫法：
  - 目標身上的點：`ProcessLookAtTargetPosition`（`r4Player.ws:2887-2963`）：虛擬控制器骨頭 → 拿著十字弩時用軀幹骨頭 `GetTorsoBoneIndex()`（`actor.ws:712`）→ 碰撞膠囊一半高度（`movingAgentComponent.ws:275`）；之後 +0.2 公尺（`:2875-2876`）
    - `GetLookAtPosition()` 不能直接用：沒有滑動目標時會改成玩家前方 100 公尺（`:2867-2873`）
  - 世界座標 → HUD：`GetBaseScreenPosition`（`hud.ws:1737-`）的 `theCamera.WorldVectorToViewRatio` → `(x+1)/2`、`(y+1)/2` → `hud.GetScaleformPoint`（`:1864-1878`、`:306-312`）
  - 原版敵人標記直接用這個座標定位（`hudModuleEnemyFocus.ws:396-422`）；模組的 Flash 根節點用 `GetModuleFlash()`（`CHudModule`，`flashScriptImports.ws:16-20`）
- 實作（wcc_lite 編譯通過，**未實測**）：
  - `CR4Player.GfgLockPoint`：硬鎖定、目標活著時，取軀幹骨頭（沒有就膠囊一半高度）+0.2 公尺；不取虛擬控制器骨頭（原版那個函式會改玩家的狀態）
  - `GfgUpdateCrosshair`：AK 拿著而且鎖定時，每格把準心模組設到那一點的 HUD 座標；解除鎖定時 `SnapToAnchorPosition()` 放回錨點；紀錄 `crosshair on lock target`／`crosshair back to anchor`
  - `GfgAimPoint`：鎖定時，射線的基準方向改成「鏡頭 → 那一點」，散布照算
  - 後座力照舊轉鏡頭；鎖定時準心每格跟著目標，所以後座力只晃鏡頭、不會把子彈推離目標
- 實測（2026-10-14）：使用者回報「完美」→ commit `5ccbcb3`（§18～§20 的改動一起）

---

## 21. 背對怪物跑時上半身左右快速切換（2026-10-14）

### 21.1 現象（使用者回報）

- 按 S 往鏡頭方向跑（背對怪物）同時射擊：上半身轉身射擊，有時往右、有時往左，**在兩者間快速切換**，看起來不順

### 21.2 原因

- 上半身瞄準：`pc_overlay.w2beh` #18587 `CBehaviorGraphLookAtUsingAnimationsNode`（§17.10 的 `LookAtUsingAnimations`）
  - 骨頭 `l_shoulderRoll`；`Angle limit` X=180、Y=90；`Animation angle range` X=180、Y=90；`Angle to stop looking` 180
  - 瞄準點讀父輸入 `lookAtTarget`（#18654）；姿勢動畫 `man_geralt_gabriel_walk_aimpose_horizontal`（#18640，`playbackSpeed=0`）
- 原版每格在 `UpdateLookAtVariables`（`actor.ws:3592-3607`）設 `lookAtTarget`、`lookAtTarget2`、`lookatToHeadingDiffYaw`（角度差 ÷180：`:3602`）；呼叫的地方：`UpdateLookAtTarget`（`r4Player.ws:2883-2884`）
- 背對怪物跑時，瞄準點在身體正後方，水平角度在 +179°、-179° 之間跳 → 姿勢在「往左扭到底」和「往右扭到底」之間切換
  - 沒有讀 `editor.log` 證實角度的數值；是由節點設定與現象對應出來的（🔶 推論）

### 21.3 修法（使用者選「固定往左轉」；wcc_lite 編譯通過，**未實測**）

- `@wrapMethod(CActor) UpdateLookAtVariables`：是玩家、AK 拿著時，先用 `CR4Player.GfgFixBackAim` 改瞄準點，再交給原版
- `GfgFixBackAim`：角度差（同原版 `:3602` 的算法，沒除以 180）落在右邊、而且超過 165° → 改成左邊 179°（距離、高度不變）；回到 150° 以內或落在左邊就放開
  - `GfgBackAimSide()` = +1（左）；heading 往左為正（`r4Player.ws:16144-16145`）
  - 紀錄：`back aim: forced to side 1 (diff=…)`（開始強制時記一次）
- 只影響上半身的姿勢和頭的朝向；子彈照舊飛向準心
- 代價：瞄準點從右後方繞回前方時，身體會在約 150° 那裡扭回右邊一次

### 21.4 實測與修正（2026-10-14；`editor.log` 02:16:42 Reload scripts 之後）

- 使用者回報：其實想要**往右**；目前 90% 都固定往左，但**剛開始射擊或換完子彈時**會右、左、右、左閃幾下才固定
- 紀錄：`back aim: forced to side 1` 47 筆，`diff` 全部在 -177.6°～-179.996°（右後方）；扳機按下、`aim start`（換彈後回到瞄準）之後也一樣
  - 我們算出來的結果一直是左邊；頻繁出現是因為角度在 ±180° 之間跳、跳回左邊時先放開再重新強制
  - → 閃動來自動畫圖那端。🔶 推論：#18587 以肩膀骨頭 `l_shoulderRoll` 算角度、`Angle to stop looking=180`；給 179° 太接近 180°，剛拿出槍、換完子彈姿勢還在轉換時可能超過 180° → 停止瞄準 → 回正 → 又開始瞄準
- 修正（wcc_lite 編譯通過，**未實測**）：
  - 固定邊改成右邊（`GfgBackAimSide()` = -1）
  - 背後最多扭到 `GfgBackAimMaxAngle()` = 150°（兩邊都限制），留 30° 餘裕
  - 強制只在角度回到 150° 以內時放開（不再因為跳回固定邊而放開）→ 紀錄只在真正開始強制時寫一次
- 實測（2026-10-14）：使用者回報「固定往右邊了，完美」

---

## 22. 不能下馬（2026-10-14，調查中）

### 22.1 現象與紀錄

- 使用者回報：出現了無法下馬的狀況
- `editor.log`（02:09～02:11）：
  - 02:09:34 上馬（`Changed SuperState from : Exploration to MountHorse`，按鍵情境 `Horse`）
  - 02:09:42 在馬上拿出 AK（存檔鎖 `RangedWeapon`；`aim start: trigger=false`）；02:09:43 射一發（`shotCount=1`，沒換彈）；02:09:44 收起（`Couldn't find item 'holster' anim action`）
  - **02:10:13～16 使用者在馬上重新載入腳本**（`State machine 'RangedWeapon' has no autostate` 等編譯警告、`Goto target state … is already current`）
  - 02:10:18 `IsDynamicDismountPositionValid(): Index 0 is out of array bounds`（`horse/states/exploration.ws:3130`，是畫除錯球的陣列，不是失敗原因）
  - 02:10:38 開過快捷輪盤

### 22.2 原版會擋下馬的地方

- `DismountHorse`（`horse/states/exploration.ws:3044-3053`）的條件：`EIAB_DismountVehicle` 允許、沒有對話或過場、按鍵情境不是 `Scene`、沒在淡出或黑畫面、騎手不在戰鬥動作、不在跳躍、沒有已發出的下馬請求、`canDismount`、不在騎馬動作
- 鎖 `EIAB_DismountVehicle` 的地方：
  - 騎馬按十字弩鍵：`ShootingCrossbow`（`useVehicle.ws:744-758`）→ 放開時 `WaitForShootingComplete`（`:2049-2052`、`:2113-2130`：等 `WeaponShootDeact` 節點、再等十字弩回 `State_WeaponWait` 才解鎖；這是 entry function）
  - 十字弩拿出時在馬上：`ShootingCrossbow`（`rangedWeapon.ws:1145`）；`OnWeaponWait` 解（`:56-61`）
  - 十字弩瞄準時的 `Lock()`（來源 `RangedWeapon`，§20.7）
- 可能的原因（都沒證實）：重載腳本中斷了等待解鎖的流程；AK 改過的流程（30 發彈匣、不自動收槍）讓解鎖沒發生；其他條件不成立

### 22.3 偵測紀錄（使用者同意；wcc_lite 編譯通過，**未實測**）

- `@wrapMethod(W3HorseComponentStateExploration) OnHorseDismountKeyboard`：記 `dismount key: pressed=… released=…`（有沒有收到按鍵）
- `@wrapMethod(W3HorseComponentStateExploration) DismountHorse`：在原版判斷**之前**記 `dismount check:`：`allowed`、鎖的來源、`riderInCombatAction`、`jumpAnim`、`dismountRequest`、`canDismount`、`horseAction`、對話、按鍵情境、淡出、黑畫面、十字弩狀態
- 包 state 的 private 函式、讀 state 的 private 欄位（`dismountRequest`、`isInJumpAnim`）：wcc_lite 編譯通過

### 22.4 實測：可以正常上下馬（2026-10-14）

- 使用者回報：可以正常上下馬（這次在地面上重載、騎馬時沒有重載）
- 紀錄：
  - 02:26:25 `dismount check: allowed=true locks= … weapon=State_WeaponWait` → 下馬
  - 02:28:45 AK 正在收（`weapon=State_WeaponHolster`）：`allowed=false locks=ShootingCrossbow riderInCombatAction=true` → 不能下；02:28:46 收好（`State_WeaponWait`）→ `allowed=true` → 下馬
  - → 原版行為：騎馬用十字弩時，收好之前不能下馬（§22.2）；收好約 1 秒內就解鎖
- 🔶 推論：§22.1 那次下不了馬，是在馬上重新載入腳本、中斷了等待解鎖的流程（`useVehicle.ws:2113-2130` 是 entry function）；沒有重現
- 下馬偵測（`dismount key:`、`dismount check:`）先留著

---

## 23. 主動收槍：C 鍵（2026-10-14）

- 使用者回報：好像沒有辦法主動按鍵收槍
  - 原因：照使用者的選擇，Shift、換彈、起跳都不收 AK，只有換成其他道具才收（§17.8）；原版沒有專門收十字弩的鍵（平常會自動收）
- 原版的「收武器」：`SwordSheathe`，鍵盤 **C**（`bin\config\r4game\legacy\base\input_qwerty.ini:709-715`，`BASE_DRAW_SWORDS_KEYBOARD`）；按住 1／2 0.3 秒是收鋼劍／銀劍
  - 在 `Exploration`、`JumpClimb`、`Combat`、`Horse`、`ThrowHold`、`ThrowHoldChain` 情境都有（`DERIVED_FROM=BASE_DRAW_SWORDS`：`:31`、`:112`、`:180`、`:266`、`:470`、`:492`）
  - 處理：`OnCommSheatheAny`（`playerInput.ws:1197-1220`）只收劍；按住 1／2 的 `OnCommSheatheSteel`／`Silver` 也會呼叫它（`:1240`、`:1263`）
- 使用者選「C 鍵」（其他鍵要新增按鍵設定，5.x 的合併方式還沒查：§11 #6）
- 實作：`@wrapMethod(CPlayerInput) OnCommSheatheAny`：按下、AK 拿著 → `thePlayer.OnRangedForceHolster( true, false )`（原版潛水時收十字弩也是這樣呼叫：`playerInput.ws:1823`、`:1837`）→ 再照原版處理收劍；紀錄 `sheathe key: holster AK`
- 實測（2026-10-14）：使用者回報全部通過（按 C 收起、再按左鍵拿出、附近有敵人、騎馬）

---

## 24. 騎馬時左鍵開槍（2026-10-14）

- 使用者回報：騎在馬上時，拿著 AK 按左鍵不會開槍，和沒騎馬時不一樣；**要讓騎馬時的行為和沒騎馬時一樣**

### 24.1 原因（2026-10-14 查證）

- 騎馬的按鍵情境 `[Horse]`（`bin\config\r4game\legacy\base\input_qwerty.ini:261-327`）沒有 `BASE_ATTACK_LIGHT`（`:654-656`，左鍵 = `AttackWithAlternateLight`，我們的扳機）
  - 左鍵是 **`VehicleAttack`**（`:313`）；中鍵是 `VehicleItemAction`／`VehicleItemActionHold`（`:277-278`）；空白鍵同時是 `VehicleItemActionAbort` 和 `HorseJump`（`:279`、`:319`）
- `VehicleAttack` 由騎馬戰鬥管理 `W3VehicleCombatManager` 接收（`useVehicle.ws:503-507`），只有閒置狀態 `Null` 和 `SwordAttack` 有 `OnAttack`（`:706`、`:1123`）
  - 閒置時：`StartAttackAction`（`:766-779`）→ 拿著劍就揮砍，沒拿就拔劍（`DrawWeapon`：`:786-823`）
  - 紀錄（`editor.log` 2026-10-14 02:34:09）：騎馬按左鍵 → 拔出鋼劍（`Adding abilities of item Long Steel Sword`）
- 騎馬時鏡頭的每格更新是 `HorseRiding` 自己的版本（`horseRiding.ws:361-426`），**不呼叫** `CR4Player` 的 `OnGameCameraTick`
  - → 我們每格做的後座力、準心、取消自動收槍、Z 鎖定解鎖，騎馬時都沒做；騎馬時 AK 會自動收起就是這個原因
  - 紀錄：02:34:12 騎馬拿出 AK（中鍵）時沒有 `crosshair shown`
- 騎馬時玩家的動畫事件只交給戰鬥管理（`horseRiding.ws:792-795`）；只有 `ShootCrossbow` 狀態會再交給十字弩（`useVehicle.ws:1757-1763`、`:2132-2134`），閒置狀態不處理（`:525`）
  - 地面是只要左手拿著遠程武器就交給十字弩（`playerWitcher.ws:8094-8098`）

### 24.2 原版騎馬射十字弩（中鍵）與騎馬規則

- 中鍵按下：`StartItemAction`（`useVehicle.ws:744-758`）→ `actionType` 設成 `EHCA_ShootCrossbow`、`OnRangedWeaponPress`（拿出）、鎖下馬與上馬（`ShootingCrossbow`）→ 戰鬥管理進入 `ShootCrossbow`
- `ShootCrossbow`（繼承 `RangedAttack`）每格設手臂瞄準（`:1674-1755`）：
  - 沒按住中鍵瞄準、畫面上有目標（不是自己的馬）：朝目標（`GetLookAtPosition`），`OT_Actor`
  - 否則朝鏡頭的方向（`pivotRotationValue`），`OT_Camera`；另外呼叫 `ProcessCanAttackWhenNotInCombat`
  - 寫入 `aimHorizontal`、`aimVertical`
- 中鍵放開：`OnRangedWeaponRelease` → 射擊動畫 → `ProjectileThrow` → 發射；`WaitForShootingComplete`（`:2113-2130`）等十字弩回 `State_WeaponWait`（收好）才解鎖、回到閒置
  - 原版射完會自動收（`HolsterAfterDelay`：戰鬥中 0.5 秒、其他 5 秒：`rangedWeapon.ws:1556-1561`）
- **戰鬥管理不在閒置狀態時（＝騎手在戰鬥動作中：`useVehicle.ws:511-514`、`:580-583`；`horse/states/exploration.ws:3295-3298`）**：
  - 馬每格被鎖住速度（`exploration.ws:970-971` → `OnCombatAction`：`:519-537`；鎖住時不能用方向鍵加減速：`:881`，也不會自然減速：`:2278`；最高只到 gallop）
  - 不能跳（`:3007`）、不能下馬（`:3047`）、停下時不能人立（`:2957`）
  - 回到閒置時解鎖（`HorseNull.OnEnterState` → `OnCombatActionEnd`：`horseRiding.ws:891-897`、`exploration.ws:539-543`）
- 騎馬的動畫圖 `gameplay\behaviors\pc\behaviorgraph\pc_rider.w2beh`（`tools\cr2w_dump.py` 讀）：
  - `Horse Combat Action`（#2）裡的 `CBehaviorGraphAnimationEnumSwitchNode`（#2643）用 `actionType`（`EVehicleCombatAction`）選 `Crossbow`（#2639）、`Petard`、`Axii`、`SwordAttack`
  - `Crossbow` 裡的十字弩狀態機（#4247：`WeaponWait`、`WeaponDraw`、`WeaponAim`、`WeaponReload`、`WeaponShoot`、`WeaponHolster`）
  - `aimHorizontal`、`aimVertical` 在這張圖用了很多處
- 同一個來源重複鎖同一個動作不會疊加，解一次就解開（`playerInput.ws:233-234`、`:253-256`）
- 騎手的 `OnCombatActionEnd`（`r4Player.ws:13128-13182`）不會動到十字弩

### 24.3 做法（使用者 2026-10-14 選「馬照常操作」）

- 選項：照原版鎖住（拿著 AK 時馬鎖速度、不能跳）／**馬照常操作**／照原版自動收
- 使用者選：**拿著 AK 時馬照常操作（加減速、跳），下馬還是要先收槍**
  - → 左鍵不進入 `ShootCrossbow`，戰鬥管理留在閒置；手臂瞄準、把動畫事件交給十字弩，改成自己做（照抄原版）

### 24.4 實作（wcc_lite 編譯通過，**未實測**）

- `@wrapMethod(W3VehicleCombatManagerStateNull) StartAttackAction`：騎馬（`horseComp` 不是空的）、AK 選用時：
  - 還沒拿出來：照 `StartItemAction` 的十字弩分支拿出（`actionType`、`rider.rangedWeapon`、`OnRangedWeaponPress`），但不進入 `ShootCrossbow`、不另外鎖下馬（拿出時十字弩自己會鎖：`rangedWeapon.ws:1145-1146`）
  - 扣扳機（`GfgSetTrigger(true)`）；不拔劍、不揮劍
  - 其他情況（船、沒選 AK）照原版
- `@wrapMethod(CR4PlayerStateHorseRiding) OnGameCameraTick`：照原版之後呼叫
  - `GfgCameraTick`（新的共用函式：後座力、取消自動收槍、Z 鎖定解鎖、準心；走路的 `OnGameCameraTick` 包裝也改成呼叫它）
  - `GfgHorseTick`：
    - 扳機：每格讀 `theInput.IsActionPressed('VehicleAttack')`（原版也這樣讀：`useVehicle.ws:601`）；放開一律放開扳機，按著時要 AK 拿在手上才扣
    - 戰鬥管理在 `ShootCrossbow`（用過中鍵）：AK 拿著、沒在用（`IsWeaponBeingUsed` = false）、中鍵也放開了 → `PopState(true)` 回到閒置（原版要等收好：AK 不自動收，馬會一直鎖著）
    - 戰鬥管理在 `ThrowBomb`、`CastSign`、`SwordAttack`：不動（用它們自己的動畫）
    - 其他：`GfgHorseAimPose`（照抄 `useVehicle.ws:1686-1739`，不抄除錯球、船、炸彈的分支；另外每格設 `actionType` = `EHCA_ShootCrossbow`）
- `@wrapMethod(CR4PlayerStateHorseRiding) OnAnimEvent_Throwable`：戰鬥管理不在 `ShootCrossbow`、左手拿著 AK 時，把動畫事件交給 AK（換彈動畫中段的 `OnWeaponReload` 才裝得上新箭：`rangedWeapon.ws:150-152`）
- `@wrapMethod(CR4PlayerStateHorseRiding) OnLeaveState`：離開騎馬時扣著扳機就放開（騎馬時是每格讀左鍵，離開後就不讀了）
- `GfgTryFire`：騎馬時不看「衝刺、空中不開火」（那是地面動畫圖的限制）
- `GfgAimPoint`：瞄準射線略過自己的馬（原版的箭會穿過自己的馬：`throwable.ws:117-118`）
- 散布照地面的規則：用玩家（＝馬）的速度算移動
- 紀錄：`horse: draw AK`、`horse: ShootCrossbow -> idle (AK still drawn)`、`horse: anim event … -> AK`；扳機、開火照舊（`trigger=`、`auto fire:`）

### 24.5 沒驗證過、可能有問題的地方

- 馬的鏡頭每格把上下角度拉向地形（`horseRiding.ws:497`、`:525`，`SetDesiredPitch`）→ 往上的後座力可能被拉回
- 騎馬跳躍（戰鬥管理進入 `HorseAction`）時手上拿著 AK 的動作
- 拿著 AK 施法（Q）：`actionType` 換成法印，之後才換回十字弩，十字弩動畫狀態機可能重新開始（原版拿著十字弩時不能施法：`ShootCrossbow` 沒有 `OnCastSign`）
- 原版馬的追尾鏡頭（`cameraMode == 1`）在馬移動時會把鏡頭轉回馬的方向（`horseRiding.ws:585-628`），橫向射擊時可能被拉回

### 24.6 第一次實測（2026-10-14；`editor.log` 16:34～16:38）與修正

- 使用者回報：都如預期，只是
  1. 後座力整體比地面小很多
  2. 要「按左鍵拿出槍，直到按 C 才收」，現在沒開槍就自動收
  3. 在馬上按 Tab 開法印輪盤會「閃退」，地面不會 → 使用者確認：是**輪盤一開就關**，遊戲沒關
- 其他照預期：左鍵拿出、連射、換彈（紀錄有 `horse: anim event OnWeaponReload -> AK`）、上下馬
- **第 2 點的原因**：騎馬動畫圖 `pc_rider.w2beh` 的十字弩狀態機（#4247，`tools\cr2w_dump.py --tree 4247`）
  - 讀的變數是 `isAimingWeaponRider`、`isShootingWeaponRider`、`isWeaponLoadedRider`（#2639 底下的變數節點 #5686、#5691 等）
  - `WeaponAim` 時瞄準、射擊都是 0 → `WaitForBlendablePose`（#6779）→ `ResetValueState` → `WeaponHolster`（#6398：射擊 0、瞄準 0、已裝填）
  - 換彈動畫結束（`AnimEndAUX`）時沒在瞄準 → `WeaponHolster`（#6390）；瞄準中 → `WeaponAim`（#7100）
  - 我們放開扳機時把瞄準設成 0 → 一放開就收；紀錄：16:34:54、16:35:27、16:35:30 放開扳機的同一秒 `crosshair hidden`
  - 地面的動畫圖沒有這條規則
- **第 1 點的原因 A**：騎馬時畫面用的是另一台鏡頭（`ActivateHorseCamera`：`r4Game.ws:83`），`theGame.GetGameCamera()` 拿到的走路鏡頭停住不動
  - 紀錄：16:34:39～16:34:50 每發的 `recoil: … camera pitch=-24.8033 yaw=21.9199` 完全沒變（使用者在騎馬、轉視角）
  - → 子彈沒打向準心：`aim:` 的目標點投影 `screen=(-1.79,0.07)`、`(-2.51,0.18)`、`(0.64,0.28)`（畫面範圍是 -1～1；走路時接近 (0,0)）
- **第 1 點的原因 B**（🔶 推論：程式碼如此，效果沒有量到，因為上面的鏡頭紀錄是錯的那台）：馬的鏡頭每格把上下角度拉向「地形角度 - 10」（`horseRiding.ws:482-498`、`:514-526`）→ 後座力往上的轉動被拉回
  - 原版按住中鍵瞄準時整段跳過（`useVehicle.ws:431-433` → `horseRiding.ws:460-473`）
- **第 3 點**：
  - 16:34～16:44 沒有遊戲結束或重開（`OnGameEnding` 沒出現；16:44:13 自動存檔）
  - 在馬上：輪盤打開（`SetTimeScale … 'RadialMenu'`）後、還沒有任何一格的畫面紀錄就關掉（`RemoveTimeScale`），16:36:27～16:36:44 共 13 次；地面上（16:36:35）開著約 1 秒
  - 昨晚 02:28:40、02:28:43 在馬上也是同樣一開就關（騎馬左鍵的程式還沒寫）；02:10:38、02:14:50、02:15:04 則開著約 1 秒 → 不是 §24.4 的改動造成的，原因未知
  - 使用者的按鍵設定（`Documents\The Witcher 3\input.settings`）：`[Horse]`、`[RadialMenu]` 的 Tab 都只綁 `RadialMenu`
  - 原版關輪盤都經過 `HideRadialMenu`（`hudModuleRadialMenu.ws:455-497`）；紀錄看不出是誰呼叫的
- 另外：每輪連射第 30 發有 `GfgRecoilKickUp(): Value '30' not handled by 'Int32' switch case` 的錯誤紀錄（彈道表只有 1～29 發，回傳 0，不影響；地面也有）
- **修正**（使用者 2026-10-14 同意；wcc_lite 編譯通過，**未實測**）：
  - 第 2 點：`GfgKeepRiderAiming`：騎馬拿著 AK 時，`isAimingWeaponRider` 一直設成 1（只改動畫圖的變數，十字弩自己的 `isAimingWeapon` 照扳機）
    - 每格（`GfgHorseTick`）、放開扳機時、回到瞄準時（`OnWeaponAimStart` 的包裝）都設
    - 要收槍時放手：`@wrapMethod(Crossbow) OnForceHolster` 記下「收槍中」（C 鍵、空白鍵、換道具等都經過這裡：`r4Player.ws:14762-14766`），讓原版的收槍切換（#6773 → #6398）照常進行；AK 收好（不是拿著）時清掉
  - 第 1 點 A：子彈的鏡頭改用畫面上正在用的鏡頭：`GfgCamera()` = `theGame.GetWorld().GetCameraDirector().GetTopmostCamera()`，同原版拍照模式（`photomodeManager.ws:96-99`）；走路時預期是同一台
    - `recoil:` 紀錄的鏡頭角度也改用它
  - 第 1 點 B（使用者選「不拉回上下角度」）：`@wrapMethod(CR4PlayerStateHorseRiding) OnGameCameraPostTick`：照原版之後，AK 拿著、沒有鎖定目標時，`SetDesiredPitch` 改成現在的角度
    - 鏡頭距離、左右自動跟隨（追尾鏡頭）照原版；收槍後恢復原版
  - 第 3 點（使用者同意加偵測紀錄，只記錄、不改行為）：`radial: key …`（`OnRadialMenu`）、`radial: close requested by Flash …`（`OnRequestCloseRadial`）、`radial: CloseRadialMenu …`、`radial: ConfirmRadialMenuSelection …`、`radial: OpenMeditation …`、`radial: hide …`（`HideRadialMenu`）
    - 每行附 `shown`、`tabHeld`（`IsActionPressed('RadialMenu')`）、按鍵情境、是否騎乘、時間
- 預期紀錄：
  - 騎馬開槍時 `aim: … screen=` 接近 (0,0)
  - 騎馬連射時 `recoil: … camera pitch=` 逐發往上（和 `applied up` 差不多），像地面一樣
  - 放開左鍵後沒有 `crosshair hidden`；按 C 才有

### 24.7 第二次實測（2026-10-14；`editor.log` 20:35～20:40）與修正

- 使用者回報：
  1. 騎馬時準心直接壓在 Geralt 身上（截圖），希望像地面一樣「中間偏左」
  2. 後座力的晃動還是比地面小
  3. 輪盤：地面上變成「按一下開、再按一下關」（使用者以為原版是按著開、放開關）；馬上拿著 AK 時也一樣；沒拿 AK 時（按 C 收槍後、剛上馬）一開就關
  4. 放開左鍵就收槍：修好了（紀錄：`crosshair hidden` 只出現在 `sheathe key: holster AK` 之後，20:38:23、20:38:35）
- 子彈方向（§24.6 的原因 A）修好了：騎馬時 `aim: … screen=` 在 ±0.1 以內（例：20:37:05 `(-0.0019,0.0038)`、`(0.034,-0.028)`）
- **第 2 點：上下有作用，左右沒有**
  - 上下和地面一樣：20:36:18 第 5→9 發，`camera pitch` -8.26005 → -3.09725（+5.16°），`applied up` 4.7356 → 9.8984（+5.16°）
  - 左右沒有作用：20:36:26～27 第 12→24 發，`camera yaw` 一直是 -21.4903～-21.4905，`applied right` 卻在 2.06 → 4.52 → … → -2.83 之間變
    - 20:36:22 第 11→23 發（yaw 一直 -12.8728）、20:36:29～30 第 9→17 發（yaw 一直 3.91525）也一樣
  - 地面左右有作用：20:35:32 第 9→10 發，yaw -224.936 → -227.201（-2.265），`applied right` -0.733 → 1.532（+2.265）
  - 原因：🔶 推論，沒有驗證。馬的鏡頭每格依設定 AutoCameraCenter 開「自動轉回馬的後方」（`horseRiding.ws:417-422`；設定預設開：`bin\config\base\gameplay.ini:8`，使用者的設定檔沒有改）
    - 原版按住中鍵瞄準時會關掉（`horseRiding.ws:400-402`）
    - 走路的探索狀態也用同一個設定（`extendedMovable.ws:116-121`），但地面左右有作用，所以不一定是它
  - 視角（FOV）一樣是 60：馬 `horseRiding.ws:17-19`；走路 `r4Player.ws:16264`
- **第 1 點：馬的鏡頭沒有左右偏移**
  - 走路的探索鏡頭往右 0.74、往後 0.38、往上 0.345 公尺（`exploration.ws:20` `geraltIdleV`）→ Geralt 在畫面左邊
  - 馬的鏡頭每格把偏移拉回 0（`horseRiding.ws:583`）→ Geralt 在正中間；距離：停 3.5、小跑 4.9、快跑 4.1 公尺（`horseRiding.ws:13-15`）
  - 原版騎馬按住中鍵瞄準（`aiming`：`useVehicle.ws:1660-1671`）的鏡頭：
    - 往右 1.4、往上 0.15 公尺（`useVehicle.ws:1749-1752`）
    - `vehicleCbtMgrAiming`（`:1734`）為 true 時：
      - 不自動轉回馬的後方（`horseRiding.ws:400-402`）
      - 每格的後段只把距離設成 2.2 公尺（鎖定目標時 3.5）就結束（`useVehicle.ws:431-433` → `horseRiding.ws:460-472`）：不拉回上下角度、不跟著馬轉、不把偏移拉回 0
    - 鏡頭更新回傳 true（`useVehicle.ws:1754`）
    - `vehicleCbtMgrAiming` 只有這三處用到（`r4Player.ws:67` 宣告；`useVehicle.ws:563` 回到閒置時清掉、`:1734` 射擊狀態每格設定）
- **第 3 點：輪盤**
  - 原版的 Flash 介面原始碼在 REDkit：`<REDKIT_DEPOT>\gameplay\gui_new\actionscript\red\game\witcher3\hud\modules\HudModuleRadialMenu.as`
    - 和遊戲用的是同一版：紀錄裡 Scaleform 錯誤的行號（`SetDesaturated` :1454、`SetSelectionDesaturated` :1474）和這份檔案對得上
  - **地面上「點一下開著、再點一下才關」是原版的設計**
    - 打開時開始計時 400 毫秒（`HudModuleRadialMenu.as:139`、`:1209-1211`）
    - 放開 Tab 時（`:738-750`）：時間到了才放開 → 選定並關閉；400 毫秒內放開 → `OnRadialPauseGame`（腳本是空的：`hudModuleRadialMenu.ws:347`），選單留著
    - 留著的選單再按一下 Tab，放開時時間早就到了 → 關閉
    - 紀錄相符：輪盤開著時遊戲時間變成 0.1 倍（`hudModuleRadialMenu.ws:392`），紀錄的 `t=` 要乘 10 才是實際秒數
      - 例：20:38:31 → 20:38:32 實際約 1 秒，`t=` 只從 4170.60 走到 4170.67
      - 按住 0.4 秒（`t=` 4201.02→4201.06）、0.8 秒（4203.50→4203.58）的放開就關
      - 0.1～0.3 秒的（4201.47、4201.96、4204.74、4205.98）都留著，再按一下才關（`PCConfirm=false`）
    - 馬上拿著 AK 時也一樣（20:38:31～34）
  - **馬上沒拿 AK 時一開就關**
    - 都是 Flash 要求「選定並關閉」：`close requested by Flash PCConfirm=true`，Tab 還按著
      - 20:38:25～28 共 6 次、20:38:37～39 共 4 次、20:39:08～09 共 2 次、20:39:27 共 1 次
    - Flash 只在這三種情況送 `PCConfirm=true`：
      - E、Enter 鍵（`:845-849`；按下、按住、放開都算）
      - 左鍵點選格子（`:603-611`）
      - 雙擊（`:619-629`）
      - 送出前都會先選定格子（`activateSelectedSlot(false)`：`:653-682`）
    - 輸入事件的線索：輪盤關著時收到輸入事件會寫一行 `GFX RAD bCheckStick false`（`:708-711`）
      - 只在「騎馬、AK 不在手上」時出現，約每秒 120 行
        - 20:36:14～16、20:37:02～04、20:38:25～28、20:38:37～42、20:39:09～11、20:39:27～34
        - 16:38～17:26 一直有（約每秒 29 行，遊戲停在馬上沒人操作）
      - 地面上、拿著 AK 時都沒有
      - 整份紀錄最早一次在 02:09（第一次騎馬）
      - 收槍或上馬約 2 秒後開始，拿出 AK 就停
    - 🔶 推論，沒有驗證：時間和「可以下馬」一致
      - 拿著 AK 時不能下馬 → 下馬的按住提示關掉（`playerInput.ws:351-358` → `r4guimanager.ws:1507-1519` → `hudModuleInteractions.ws:456-468`）
    - Flash 的「按住」模擬：收到按下、沒收到放開的鍵，0.5 秒後開始每隔一段時間（最短 30 毫秒）送一次「按住」（`InputManager.as:40-43`、`:367-402`、`:422-468`）
      - 可能是串流的來源，沒有驗證
    - 昨晚（騎馬程式還沒寫）02:28:37 上馬，02:28:40、02:28:43 一開就關
      - 02:28:44 接著 `aim start`、02:28:45 下馬檢查 `locks=ShootingCrossbow`
      - 🔶 可能是關閉前選定了十字弩那一格（`OnActivateSlot` → `OnRadialMenuItemChoose`：`hudModuleRadialMenu.ws:221-237`）
    - 還不知道：是哪個鍵或點擊、原版遊戲會不會這樣
- **修正**（wcc_lite 編譯通過，**未實測**）：
  - 第 1、2 點（使用者選「原版騎馬瞄準鏡頭」）：騎馬拿著 AK、在閒置狀態、沒鎖定目標時，用原版按住中鍵瞄準的鏡頭（`GfgSetHorseAimCam`）
    - 每格把 `vehicleCbtMgrAiming` 設成 true；關的時候只清自己設的
      - 原版射十字弩（中鍵）、丟炸彈時由原版每格設定，不去動它
      - 施法、揮劍、收槍、鎖定目標、離開騎馬時關掉
    - 鏡頭偏移：照抄 `useVehicle.ws:1749-1752`（往右 1.4、往上 0.15 公尺）
    - 鏡頭更新回傳 true，同原版
    - 每格後段把左右、上下的目標角度都設成現在的角度（同原版走路十字弩瞄準：`aimThrow.ws:361`、`:371`）
      - 取代 §24.6 只設上下的做法
    - 拿著 AK 時鏡頭不會自動轉回馬的後方，也不跟著馬轉（同原版按住中鍵瞄準）；收槍後恢復
  - 第 3 點（使用者選「只加偵測紀錄」，只記錄、不改行為）：
    - `radial: activate slot=… tab=…`、`radial: activate ranged slot=…`：`OnActivateSlot`、`OnActivateSlotRanged` 的包裝
      - `tab=false` 是 E、Enter、點選、雙擊；`tab=true` 是放開 Tab 關閉（`:738-744`）
    - `radial: hold indicator on/off`：`CR4HudModuleInteractions` 的 `EnableHoldIndicator`、`DisableHoldIndicator` 的包裝（下馬按住提示開關的時間）
  - 紀錄：`horse aim camera: true/false locked=…`
- 預期紀錄：
  - 騎馬拿出 AK：`horse aim camera: true`；收槍（C）：`horse aim camera: false`
  - 騎馬連射時 `recoil: … yaw=` 跟著 `applied right` 變（像地面 20:35:32 那樣）
  - 輪盤一開就關時：`hold indicator on` 在前面；`close requested … PCConfirm=true` 之前有沒有 `activate slot=… tab=false`

### 24.8 第三次實測（2026-10-14；`editor.log` 21:17～21:20）：騎馬開槍通過；輪盤一開就關的原因

- 使用者回報：「測完，完美」；輪盤只剩「在馬上、沒拿 AK」時一按 Tab 出現一下就消失，拿著 AK 時沒問題
- 紀錄確認：
  - 拿出、收槍、鎖定都照預期：`horse aim camera: true`（拿出 AK）、`false locked=true`（Z 鎖定）、`false`（C 收槍）
  - 左右後座力有作用：21:18:46 第 5→8 發，`yaw` -31.0354 → -30.3743 → -29.9212 → -29.2094，`applied right` 0.1856 → -0.4756 → -0.9286 → -1.6405，每發的變化量一樣（往左為正）
- **輪盤一開就關：和「按住 E 下馬」的提示同時出現、同時消失**
  - 21:19:24 提示打開（`hold indicator on` t=4352.85）
    - 打開前的那一次（t=4352.78）正常：按住、放開才關（`PCConfirm=false`）
    - 之後 8 次都一開就關（`PCConfirm=true`，Tab 還按著；t=4353.39～4357.53）
  - 21:19:31 拿出 AK、提示關掉（t=4360.15）→ 之後 3 次正常（t=4360.71、4361.97、4362.43）
  - 21:19:37 收槍、提示打開（t=4364.66）→ 之後 8 次都一開就關（t=4365.45～4369.89）
  - 一開就關之前都**沒有** `activate slot`
    - 左鍵點選要先選定格子成功（會寫 `activate slot`）才關閉（`HudModuleRadialMenu.as:605-610`），所以不是點選
    - 剩下 E、Enter 鍵（`:845-849`）或雙擊（`:619-629`）
- **原版 Flash 介面的機制**（REDkit 附的原始碼，`<REDKIT_DEPOT>\gameplay\gui_new\actionscript\red\`）：
  - 下馬提示打開時（`hud\modules\HudModuleInteractions.as:125-136`）：開啟「按住」模擬，並讓整個 HUD 開始收按鍵（`addInputBlocker(false, …)` → `managers\InputManager.as:125-152`）
  - 「按住」模擬（`InputManager.as`）：
    - 按下時把那個鍵記成「按著」，放開時刪掉（`:367-402`）
    - 記成「按著」的鍵，0.5 秒後開始一直重送「按住」，最快每 30 毫秒一次（`:40-43`、`:422-468`）
  - 提示關掉時（`HudModuleInteractions.as:138-145`）：關掉模擬、HUD 不再收按鍵，但**不清掉「按著」的鍵**
    - 只有 `reset()` 會清（`InputManager.as:631-643`）：`CoreComponent.resetInput()`（`core\CoreComponent.as:61-64`）、放開畫面上提示的按鍵時（`ModuleInputFeedback.as:983-990`）
  - 輪盤開著時收到 E 或 Enter 的任何事件（按下、按住、放開）→ 選定並關閉（`:845-849`）
- **🔶 推論**：用 E 下馬時，Flash 把 E 記成「按著」，之後再也收不到放開
  - 紀錄：21:17:50 `dismount key: pressed=true` 之後 3 行就是 `hold indicator off`（下馬開始、提示關掉）；E 在 21:17:52 才放開，那時 HUD 已經不收按鍵
  - 之後每次在馬上、提示打開，Flash 就一直重送「E 按住」→ 輪盤一打開就被當成按 E 而關掉
  - 拿著 AK 時不能下馬 → 提示關掉 → 不重送 → 輪盤正常（下馬鎖 → 提示：`playerInput.ws:351-358` → `r4guimanager.ws:1507-1519`）
  - 昨晚也符合：
    - 02:09:34 上馬後一直在馬上（中間沒有下馬）：02:10:38、02:14:50、02:15:04 輪盤正常
    - 02:24:50 起多次用 E 下馬、上馬：02:25 開始一直有 `GFX RAD` 串流，02:28:40、02:28:43 一開就關
  - `GFX RAD bCheckStick false` 的串流就是這些重送的事件（輪盤關著時收到才會寫：`HudModuleRadialMenu.as:708-711`）
  - 全部是原版的程式（Flash 與腳本），AK 只是在拿著時讓下馬提示關掉
  - 沒驗證：重送的確定是 E（也可能是 Enter，但沒按過 Enter）；原版遊戲（沒有 mod）是否也會這樣
- 原版腳本有現成的方法清掉 Flash 的「按著」：`GetMemberFlashFunction( "resetInput" )` 再 `InvokeSelf()`
  - 例：`tutorialPopup.ws:42`、`:163`；`characterMenu.ws:97`、`:225`
  - HUD 模組也有這個方法：`HudModuleBase` → `CoreHudModule`（`core\CoreHudModule.as:15`）→ `CoreComponent`

### 24.9 修正：開輪盤前清掉被記成「按著」的鍵（使用者 2026-10-14 選；wcc_lite 編譯通過，**未實測**）

- `@wrapMethod(CR4HudModuleRadialMenu) ShowRadialMenu`：輪盤還沒開時，先呼叫輪盤 Flash 的 `resetInput`，再照原版打開
  - 呼叫方式同原版 `tutorialPopup.ws:42`、`:163`
  - 紀錄：`radial: flash input reset …`
- 清的是 HUD 共用的那一個 `InputManager`：
  - 每次讀檔，紀錄的 `Initializing InputManager` 只出現兩次（例：16:33:52 的 794 屬於 `CommonMenu`，另一個是 994）
  - HUD 的十幾個模組沒有各建一個，所以輪盤和下馬提示（`HudModuleInteractions`）用的是同一個
- 清掉後的影響：被記成「按著」的鍵全部清掉，「按住」模擬的計時器停掉
  - 下一次按下任何鍵時計時器重新開始（`InputManager.as:372-379`）
  - 輪盤自己的 400 毫秒規則用的是它自己的計時器（`HudModuleRadialMenu.as:1209-1211`），不受影響
- 預期：馬上沒拿 AK 時按 Tab，輪盤照原版規則（按住再放開就關、點一下開著）；紀錄有 `radial: flash input reset`，沒有一打開就 `PCConfirm=true`
- **實測（2026-10-14；`editor.log` 21:38:06～21:38:31）**：使用者回報「完美」
  - 馬上、沒拿 AK、下馬提示開著（21:38:13 起）：Tab 4 次都照原版規則關閉（`PCConfirm=false`）
    - 拿出 AK 後 2 次、收槍後 2 次也一樣
    - 21:38:06 起整段沒有任何 `PCConfirm=true`；每次開輪盤前都有 `radial: flash input reset`
  - **沒有直接重現卡住的情況**：這次上馬（21:38:12）之前，沒有「用 E 下馬 → 再上馬」就直接在馬上按 Tab
    - 上一次用 E 下馬是 21:20:19；之後 21:38:06 在地面開了輪盤，那時的 `resetInput` 就已經清掉了
    - 上馬、提示打開後沒有 `GFX RAD` 串流（上一輪 21:19:24 提示打開後、下一次按 Tab 前有 22 行）
    - 間接證據：用 E 下馬、再上馬後原本都會出現串流；這次中間清過一次就沒有
  - 待驗證：用 E 下馬 → 再上馬 → 中間不在地面開輪盤 → 直接在馬上按 Tab
    - 輪盤的偵測紀錄已經拿掉（§25），改成目測：輪盤要照原版規則（點一下開著），不會一開就關

## 25. 拿掉偵測紀錄（2026-10-14）

- 使用者 2026-10-14：「可以拿掉沒有用的紀錄程式碼」
- `gfg_ak47.ws` 的 `LogChannel( 'GFG', … )` 42 行全部拿掉（wcc_lite 編譯通過，**未實測**）
  - 追的問題都解決了：卡住（§20）、下馬（§22）、輪盤（§24.8、§24.9）、射程（§18）等
  - 只為記錄而寫的包裝一起拿掉：卡住偵測 `GfgCheckStuck`、下馬偵測（`OnHorseDismountKeyboard`、`DismountHorse`）、輪盤偵測（`OnRadialMenu` 等 10 個）、`OnRangeReached`
  - 只給紀錄用的欄位、函式也拿掉：`gfgTicksSinceShot`、`gfgTicksMoved`、`gfgShotFrom`、`gfgShotTime`、`GfgLoadedText`、`GfgRadialState`
  - 其他功能裡的紀錄只刪那一行，功能不動
- §13～§24 提到的 `GFG` 紀錄（`trigger=`、`auto fire`、`recoil:`、`stuck*`、`bolt*`、`radial: …` 等）之後不會再出現
- 還會出現、不是 `GFG` 頻道的兩行：第 30 發的 `Value '30' not handled`（§24.6）、`UpdateLookAtVariables` 的 `Accessing invalid handle`

## 26. 拿在手上的物品：畫面上的模型跟著「物品系統掛在 slot 的動畫元件」（2026-10-16 遊戲實測）

查第 5 項（衝刺時擺手、槍要拿正）時發現；腳本在 `workspace\scripts\local\gfg_ak47.ws`（`GfgCarryTick`、`GfgCarrySpawnDummy`）。

### 26.1 現象

- 衝刺時每格對 AK 實體呼叫 `BreakAttachment()`＋`CreateAttachment( thePlayer, 'l_weapon', 位移, 角度 )`（`entity.ws:342-343`）：
  - `rangedWeapon.GetLocalToWorld()`（實體）照設的偏移走（紀錄每格都對）
  - AK 自己骨架的 `handle` 骨頭（`GetBoneWorldMatrixByIndex`）相對左手 `l_weapon` 的擺法**完全不變**（和不偏移時差 0～0.7°）
  - 模型蒙皮在 `handle` 骨頭上（`CLAUDE.md` §6.14）→ 畫面上的槍照原版跟著手轉（左手甩到後面時直立、槍口朝上：使用者附圖的樣子）
- 拔槍時：`rangedWeapon.HasAttachment()` false、`thePlayer.HasChildAttachment( AK 的動畫元件 )` false、`HasChildAttachment( AK 實體 )` false（`entity.ws:344`、`:352`）
- AK 動畫元件 `SetPosition`／`SetRotation`（`components.ws:22-25`）設成 0：紀錄、畫面都沒變
- 結論（推論，證據一致）：物品系統把物品的動畫元件直接掛在 slot 骨頭上，腳本的實體掛載碰不到它；之前用實體矩陣「驗證」過的提槍其實沒有出現在畫面上
  - 以後量物品在畫面上的擺法：看物品骨架的骨頭（例：AK 的 `handle`），不要看實體矩陣

### 26.2 做法：替身

- 用同一個模板 `dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47.w2ent` 自己生成一把（`theGame.CreateEntity`，`game.ws:129`；帶標籤 `gfg_carry_dummy`、`PM_DontPersist`）
  - `RangedWeapon.OnSpawned` 會 `Initialize( 父實體 )` → `State_WeaponWait` 的 `OnEnterState` 解除玩家的動作鎖（`rangedWeapon.ws:31-35`、State_WeaponWait）→ 包裝 `OnSpawned`：有這個標籤就不初始化
- 自己生成的實體：骨架跟著實體走 → `CreateAttachment` 的偏移看得到（實測：替身掛在手上方 1 公尺，畫面上就浮在那裡；`handle` 相對替身實體的擺法和真的 AK 一樣：原點 (0, 0, −0.072)、軸互換）
- 衝刺時：真的 AK 的模型元件 `witcher_crossbow_lvl1` 和裝好的箭（`deployedEnt`，對齊在槍管裡）藏起來（`CDrawableComponent.SetVisible`：`components.ws:473`；`SetVisibility`：`rangedWeapon.ws:563`），替身顯示並每格帶偏移掛到 `l_weapon`；結束時反過來，替身掛回 `l_weapon` 不帶偏移（下次換過去不會跳）
- 預測下一格的手腕方向：相對變換要到下一格才套上（每格紀錄：不預測時槍管和目標差平均 9.6°、最大 16.6°；預測後平均 2.3°、最大 8.2°）
- 實測（替身的 `handle`）：槍管和目標（玩家座標往下 30°、往右 8°）差平均 2.3～2.6°、最大 8.7～11.3°；槍管一直朝下 25°～38°；正常速度側面連拍：左手握在機匣、槍口朝前下、槍托朝後上（像單手提著步槍跑）
- 也測過：衝刺中跳躍（淡出 → 空中、落地雙手持槍 → 淡入）、衝刺中按 C 收槍（槍回背上、手上沒有殘留）、收槍再拔再衝刺（替身照常）；替身沒有造成腳本錯誤

### 26.3 紀錄的讀取時機

- `GfgLogHoldPose` 在 `GfgCameraTick` 裡、提槍計算之前寫 → 紀錄裡實體的位置是上一格的；跑步 5 公尺／秒時實體和 `l_weapon` 差約 9 公分（不偏移時也一樣）→ 是紀錄的時機，不是畫面落後

## 27. 打包（REDkit 的 Publish；2026-10-17 第一次）

- 操作：主視窗菜單 **Publish → Save and publish mod project**（菜單在螢幕 (185, 32)，第 3 區最後一項）→ 精靈 3 步
  1. Basic information：Mod's name、Version、Description（都必填；這版沒有縮圖欄）
  2. Cook：按 **Start cooking** → 開著世界時問「Cannot publish mod while a world is open. Do you want to close the world first?」→ Yes（世界被關掉）→ 11 個步驟（Clean、Analyze、CompileShaders、Cook、CompileSounds、CompileSpeech、CompileScripts、CollisionCache、TextureCache、CreateBundles、CreateMetadataStores），約 1.5 分鐘
  3. 同一頁下方：Content folder（`<專案>\packed\`）、**Install mod to game (optional)** 的 Install 按鈕（會寫進遊戲資料夾）；再 Next 是 Save and publish（匯出 zip、發布到 Steam 工作坊：**不用**）
- 紀錄：`<專案>\logs\publish <日期時間>.log`；另外產生 `cooked\`、`cookeddlc\`、`packed\`、`publish\`（都在 `.gitignore`）
- 輸出（`packed\`）：
  - `dlc\gunforgeralt\content\`：`blob0.bundle`（`test.reddlc`、物品 XML、AK 模板、模型、貼圖、動畫組 `gfg_ak47_geralt.w2anims`）、`buffers0.bundle`（模型的 buffer）、`texture.cache`、`metadata.store`
  - `mods\modgunforgeralt\content\`：`blob0.bundle`（改過的原版 `pc_overlay.w2beh`、`pc_gameplay.w2beh`）、`precompiled.rsblob`（腳本編譯好的 blob，46 KB；查得到 `GfgTryFire` 等函式名）、`en.w3strings`、`info.json`
  - 安裝方式（推論，**未驗證**）：`packed\mods\modgunforgeralt` → `<W3_GAME_DIR>\mods\`、`packed\dlc\gunforgeralt` → `<W3_GAME_DIR>\dlc\`（遊戲的 `dlc\` 已有其他 mod 的 DLC：`DLCmod_spawn_companions` 等）
- 紀錄裡的錯誤（不影響輸出）：`SoundModCooker Fatal Error: Wwise installation not found`（沒有聲音，跳過）；`Dynamic class resolve for resource 'scripts\local\gfg_ak47.ws' failed`
- 第一次打包（10-17 00:06）`info.json` 的 `"succesfullyCooked": false`（11 步都寫 finished）
  - 其他用 REDkit 打包、裝在遊戲裡的 mod（`modBetterIcons2025_Remastered`、`modMoreSkillSlots`、`modSortEverything`…）都是 `true`
  - 原因的候選（10-17 01:3x 讀紀錄）：① 種子清單把 `scripts\local\gfg_ak47.ws` 當資源去 cook → `Dynamic class resolve … failed`、`Failed to cook`（這次 cook 唯一失敗的檔；腳本另外在 CompileScripts 編進 `precompiled.rsblob`）② CompileSounds 的 `Fatal Error: Wwise installation not found`
  - **第二次打包（10-17 05:44）是 `true`**：紀錄裡一樣有 ① ② 兩個錯誤 → 這兩個不是 `false` 的原因；第一次為什麼是 `false` 沒查到
  - **遊戲執行檔 `witcher3.exe` 裡沒有 `succesfullyCooked`、`useLooseScripts` 字串**（ASCII、UTF-16 都沒有；`info.json`、`gameVersion`、`modName`、`dependencies` 有，旁邊是 `modioModsConfig.json`）；REDkit 的 `editor.exe` 有 3 處 → 推論只有 REDkit 用（例：Install、發布），遊戲載入 mod 不看它（**未實測**）
- ⚠️ 打包後（重建了虛擬 depot），同一次開著的 REDkit 重開世界、按 play game **當掉**（`EXCEPTION_ACCESS_VIOLATION`，堆疊在 Scaleform；紀錄停在 `World loaded` 之後）→ 打包完要重開 REDkit 再測
- **第二次打包**（10-17 05:44～05:46，版本 0.2；紀錄 `logs\publish 2026-10-17 05-44-58.log`）
  - 精靈的 Basic information 會帶出上次填的值（名稱、版本、說明）
  - `dlc\…\blob0.bundle` 13 個檔：第一次的內容，加上槍口火光 `data\fx\gfg_muzzle_flash.w2ent`、彈匣替身 `gfg_ak47_mag.w2ent`／`.w2mesh`、沒彈匣的 AK `gfg_ak47_nomag.w2ent`／`.w2mesh`；`buffers0.bundle` 3 個模型的 buffer → workspace 裡腳本以外的 14 個檔都包進去了
  - `mods\…\precompiled.rsblob` 40,473 bytes（＝清理後 `wcc_compile.py` 編出來的大小）
  - 打包完關 REDkit：紀錄寫 `Main window closed`，程序卻沒結束（視窗都變成停用、選單點不開）→ `taskkill` 後重開（同 `docs\handoff.md`「操作備忘」的重開步驟）→ 開遊戲、拿 AK、連射、換彈都正常
- **第三次打包**（10-18 21:03、21:09，版本 0.3；紀錄 `logs\publish 2026-10-18 21-09-47.log`）
  - **REDkit 開好專案就打包 → 每次當掉**（10-18 20:2x～20:5x 共 7 次）
    - `EXCEPTION_ACCESS_VIOLATION`，讀 -1，位址固定 `editor.exe+0x2C41F59`
    - 在 DLC 那一輪 cook `dlc\gunforgeralt\test.reddlc` 時：重讀物品定義、掃角色模板（arachas → bear → bies）之後 3～7 秒；紀錄每次停在同一處
    - 換掉任一項都一樣當：AK 的 4 張動畫圖、動畫組（換 10-17 版）、`test.reddlc`（換 10-17 版）、字串庫的一筆、#27 的子彈（物品 XML、模板、模型、貼圖）、腳本、槍聲 bank、打包前有沒有開世界
  - **先開世界、按 play game 進一次遊戲、F10 結束，再打包 → 過了**（連續 2 次）
    - 10-17 成功的那次也是測過遊戲才打包：紀錄裡 GC 的物件數約 32.5 萬（當掉的幾次約 10 萬）
    - 為什麼進過遊戲就不當：沒查到
  - 輸出：`dlc\…\blob0.bundle` 19 個檔、`texture.cache` 含 3 張圖示 → workspace 裡腳本、槍聲以外的檔都包進去了
  - `mods\…` 沒有 `blob0.bundle`：AK 的動畫圖改成 DLC 裡的複本，不再改原版的檔（§34）；`precompiled.rsblob` 49,566 bytes
  - **`zh.w3strings` 只放有中文的字串**：字串庫 `LANGUAGES` 表 ZH 的 FALLBACK 是 EN，打包卻不拿英文代替
    - AK 名稱補中文前 3 個 key、補後 4 個 → 中文遊戲要每個字串都有 ZH
  - 打包完關 REDkit（File → Exit）：這次程序正常結束
  - 裝進 Steam 版（10-18 21:1x）：`packed\mods\modgunforgeralt`、`packed\dlc\gunforgeralt` 複製到 `<W3_GAME_DIR>\mods\`、`dlc\`；槍聲另外用 `tools\sound_cache.py` 包進 `mods\…\content\soundspc.cache`；遊戲裡能不能用：使用者試玩中

## 28. 特效模板：複製原版、在 Entity Editor 改特效（2026-10-17 槍口火光實測）

- **複製原版資源到 workspace**：Asset Browser 對檔案按右鍵 → **Save as...** → Windows 的存檔視窗（起點是專案資料夾）→ 檔名欄打完整路徑（例 `D:\OneDrive\Desktop\gunforgeralt\workspace\dlc\gunforgeralt\data\fx\gfg_muzzle_flash.w2ent`）→ Enter
  - 目的資料夾要先存在（存檔視窗不會自己建）；在 REDkit 外面建的資料夾，Asset Browser 空白處右鍵 → **Refresh all** 之後才看得到
  - Asset Browser 右上的 Search 找得到原版檔，找不到剛存的新檔 → 用路徑列（點 `virtualdepot` 回根目錄）一層層雙擊進去
  - 存出來的檔有 `+` 圖示（加進專案）
- **Entity Editor 的特效**：下方分頁 **Effects** → 右邊清單點特效名稱 → 清單上方第 2 個按鈕 **Edit effect**（雙擊、右鍵都沒反應）→ 上方多一個分頁 `Effect [名稱]`：時間軸（群組、軌道、項目）、曲線、屬性
  - 時間軸縮放：一般滾輪只縮放一點點；**Shift＋滾輪以游標為中心縮放**（快）
  - 一開始 0 秒附近被左邊的軌道名稱欄蓋住、看不到項目 → 游標放在時間軸最右邊 Shift＋滾輪往下（縮小）→ 0 秒露出來 → 游標放在 1 秒附近 Shift＋滾輪往上放大
  - 點項目 → 下方屬性：`timeBegin`、`timeDuration`，加上各類別的欄位（光：`color`、`radius`、`brightness`、`attenuation`、`lightChannels`…；粒子：`particleSystem`、`spawner`）；點數值格 → 打字 → Enter
  - 點時間軸空白處 → 特效本身（`CFXDefinition`）：`length`、`loopStart`、`loopEnd`、`showDistance`、`isLooped`…；`length` 改短時 `loopEnd` 會跟著變
  - 群組名稱按右鍵：Append track、Insert／Append track group、Rename item、**Remove item**（刪整個群組）；軌道空白處按右鍵：Add track item
  - 存檔：左上 **Save** 按鈕（寫進硬碟；`cr2w_dump.py` 讀回確認）
  - 時間軸上方的播放鍵：預覽視窗沒有顯示粒子（`Particle emitters: 0`）→ 沒用，直接進遊戲看
- 光的 `lightChannels` 預設 `LC_Characters`（原版刀劍火花、弩箭的光都沒存這個欄位 = 預設），遊戲裡晚上連射時地面也被照亮
- 腳本載入自己的模板：`LoadResource( "dlc\…\xxx.w2ent", true )`（第二個參數 true = 路徑，不是別名：`signEntity.ws:708`）
- 在 REDkit 裡存的新模板，同一次開著的 REDkit 開遊戲就讀得到（不用重開；和 §6.16 腳本產生的 workspace 檔不同）

## 29. 原版自動拔劍的路線、擋法（2026-10-17 第 19 項；遊戲實測）

- **原版自動拔劍都先問「最適合的劍」**：`WeaponHolster.GetMostConvenientMeleeWeapon`（`playerWeaponHolster.ws:175-283`；目標用 vitality → 鋼劍、essence → 銀劍；沒目標、徒手的人、Accessibility 的 `DisableAutomaticSwordSheathe` → 空手 `PW_Fists`）
  - 進入戰鬥、目標有敵意：`OnCombatStart`（`r4Player.ws:2156-2162`）
  - 被目前的目標打中：`OnReactToBeingHit`（`r4Player.ws:2234-2239`）
  - 戰鬥中收劍（變成 `PW_None`）→ 0 秒計時器 `DelayedTryToReequipWeapon` 馬上再拔（`playerWeaponHolster.ws:531-534` → `r4Player.ws:3178-3189`）
  - 附近有敵人、進入戰鬥模式：`playerMode.ws:211-220` → `GoToCombatIfNeeded`（`r4Player.ws:3300-3335`）→ `GoToCombat( 劍 )` → `CombatSteel`／`CombatSilver` 狀態一進入就拔（`combatSteel.ws:31-33`）；`PW_Fists`、`PW_None` 都進 `CombatFists`（`r4Player.ws:3491-3511`）
  - **拿出十字弩時也會**：`State_WeaponDraw.OnEnterState` → `GoToCombatIfNeeded`（`rangedWeapon.ws:1140`）
  - 騎馬：戰鬥開始 → 0 秒計時器 `DrawWeaponIfNeeded`（`horseRiding.ws:201-242`）→ 騎馬戰鬥管理 `DrawWeapon`（`useVehicle.ws:786-823`：問完最適合的劍，沒有鋼劍以外的答案時**直接拔鋼劍**）
  - 下馬：`dismountHorse.ws:217-218`
- 手動：1／2 鍵 → `EBAT_Draw_Steel`／`Silver` → `OnEquipMeleeWeapon( 劍, false, true )`（`playerInput.ws:1116-1195` → `r4Player.ws:10829-10883`）；第三個參數 true = 拿著同一把時改成收劍（`playerWeaponHolster.ws:568-583`；戰鬥中收成空手）
  - 拿著十字弩（瞄準狀態的 `Lock()`）時 `EIAB_DrawWeapon` 被鎖，1／2 鍵本來就沒反應；收起十字弩時才會走到 `OnEquipMeleeWeapon`
- **拿著劍時拿出十字弩**：十字弩在左手、劍留在右手（原版的單手十字弩）→ 我們的雙手持槍動畫對不上（使用者看到的「單手拿 AK、AK 看不到、不能射擊」）
- 擋法（`gfg_ak47.ws`「AK 是選用物品時不准拿劍」）：包 `WeaponHolster.GetMostConvenientMeleeWeapon`（劍 → `PW_Fists`、記下要舉 AK）＋包 `CR4Player.OnEquipMeleeWeapon`（擋鋼劍、銀劍，收劍照原版）＋每格收掉手上的劍、找時機舉 AK
  - 實測：沒拿 AK 走進 30 隻狼 → `Enter CombatFists`、自動舉 AK；按 1 → 擋掉；手上有劍 → 0.3 秒內收回背上（戰鬥中收完接著舉 AK）；拿著劍按住左鍵 → 收劍 → 舉 AK → 接著連射；騎馬戰鬥開始 → 騎馬舉 AK、可以開槍、馬照常走
- **騎馬的戰鬥管理**是 `W3HorseCombatManager`，閒置狀態叫 **`HorseNull`**（繼承 `Null`：`horseRiding.ws:886-889`）；`GetCurrentStateName()` 回傳 `HorseNull`，不是 `Null`
- 測試小事：遊戲被教學視窗暫停時（畫面角落 `Game Paused By`），F10 結束不了遊戲 → 先點一下遊戲畫面讓它繼續，再按 F10；**點遊戲畫面＝左鍵＝AK 的扳機**：AK 是選用物品時一點就拿出 AK（要測「AK 收著」時，點完再按 C 收）

## 30. 移動時朝哪裡：持劍和持槍（2026-10-18 第 20 項；遊戲實測）

量法：暫時紀錄 `[GFG] face`（每 0.1 秒：狀態、戰鬥姿態、朝向目標、移動類型、角色朝向、鏡頭、速度方向、移動目標方向）＋暫時指令 `gfgwolf`（不會動的敵對狼）；每個方向按住 2 秒，取後 60% 的中位數。量完都拿掉了

**持劍**（`reference_level`；角度＝角色朝向減移動方向）

| 情況 | 走（Alt） | 跑 | 衝刺（Shift） |
|---|---|---|---|
| 不在戰鬥中（`Exploration`、`PCS_Normal`） | 8 方向朝移動方向（差 1° 內），1.9 公尺／秒 | 8 方向朝移動方向，5.0～5.1 | 8 方向朝移動方向（差 6° 內），5.9～7.0 |
| 戰鬥中、附近有敵人（`CombatSteel`、`PCS_AlertNear`） | （沒量；原版一樣只給走：下面） | **只能走**（2.3～2.6）；8 方向都**朝著狼**（按 S 後退、A／D 側移） | 朝移動方向（轉身跑），7.0 |

- 野外拔劍：狀態還是 `Exploration`（`GetCurrentMeleeWeaponType()` = `PW_Steel`）；連拍 `sw_s`：按 S 轉身往鏡頭跑
- 戰鬥中按 S 的連拍 `sw_cs`：背對鏡頭、朝著狼後退
- 原版的機制：
  - 移動控制器每格把「移動方向」「面向」交給動畫圖（`requestedMovementDirection`、`requestedFacingDirection`；`locomotionDirectController.ws:351`、`:1142-1225` → `actor.ws:3580-3587`）
  - 面向：朝向目標是 `OT_Actor` 時，`PCS_AlertNear`（或格擋中目標夠近、法印鎖定）→ 朝目標（`GetTarget()`，沒有就 `moveTarget`；`:1166-1213`）；否則朝角色自己的方向
  - 戰鬥姿態：移動目標在 `findMoveTargetDist` 內 → `PCS_AlertNear`（進入 10 公尺、大型 15 公尺；已經是 AlertNear 時放寬到 18 公尺：`combat.ws:897-902`、`:913-931`、`r4Player.ws:337`）；更遠 `PCS_AlertFar`
  - `PCS_AlertNear` 時不能跑（`locomotionDirectController.ws:933-938` 的跑步條件只有 `PCS_Normal`、`PCS_AlertFar`）→ 戰鬥走路 `WalkAlertNear`（§20.6）
- **拿十字弩時朝向目標會被十字弩自己蓋掉**：`SetOwnerOrientation`（`rangedWeapon.ws:878-891`）加一個自訂朝向目標 `RangedWeapon`，值是 `GetCombatActionOrientationTarget( CAT_Crossbow )`（`r4Player.ws:5349-5418`：畫面上沒有目標時 `OT_Camera` 等）；移動中不更新（`rangedWeapon.ws:479-485` 只在站著、沒瞄準時更新）→ 實測 AK 開槍後一直是 `OT_Camera`

**持槍（改之前）**
- 不在戰鬥中：跑、衝刺 8 方向朝移動方向（同持劍）；開槍中又在移動：朝準心、側移（§21 之後的做法）
- 戰鬥中（沒開槍）：照野外規則跑（§20.11），5.1 公尺／秒、**朝移動方向**（按 S 轉身往回跑）← 和持劍不同

**改法**（`gfg_ak47.ws`「戰鬥中移動時朝哪裡」）
- 戰鬥中、附近有敵人、有活著的目標、沒衝刺、沒開槍：身體一直朝目標，用開槍中移動那一套側移、後退的腳步（上半身動畫圖的全身瞄準 `DirectionalMovement`）
  - 條件照原版 `OT_Actor` 那一支（不看朝向目標本身，原因見上）；目標死了不朝它
- 開槍中又在移動：照舊朝準心（槍要對準準心）
- 側移時，動畫圖的「面向」改成身體實際朝的方向（包 `CActor.UpdateRequestedDirectionVariables`）：原版戰鬥中的面向是目標，開槍時身體朝準心 → 側移挑的動作會不對
- 衝刺、AlertFar、不在戰鬥中：照舊朝移動方向（同持劍）

**改之後**（戰鬥中、不會動的狼）
- 8 方向都朝著狼（差 5° 內），1.75～2.1 公尺／秒（持劍的戰鬥走路 2.3～2.6）；連拍 `ak_cs`（S）、`ak_ca`（A）：兩手持槍朝狼，腳往後、往左踏
- 衝刺：朝移動方向；開槍中移動（鏡頭轉開狼 50～70°）：朝準心（差 1° 內）；停火 3 秒後再移動：朝狼（差 3° 內）
- 離狼 18 公尺以上（AlertFar）：轉身跑（同持劍）

## 31. 物品圖示：物品欄、輪盤（2026-10-18 第 21 項；遊戲實測）

**圖從哪裡來**
- CS2 的 VPK：`panorama/images/econ/weapons/base_weapons/weapon_ak47_png.vtex_c`（CS2 物品欄的 AK 圖，512×384、透明背景）
  - `tools\vpk_extract.py` 取出（只讀 VPK）→ Source 2 Viewer 命令列版 20.1（GitHub 官方 release `cli-windows-x64.zip`；放 `tools\_vendor\s2v_cli\`，不進 git）：`-i <資料夾> --recursive -o <輸出> -d` 轉成 PNG
- `tools\ak_icon.ps1`：轉、裁、縮、加淡陰影
  - 物品欄：64×128 直的（順時針 88.2°；擺法照原版十字弩圖示）
  - 輪盤：128×64 水平（`-Angle:-8.4 -Width 128 -Height 64`：槍管水平）；負的角度要寫成 `-Angle:值`，不然被當成參數名稱
- 輸出：`workspace\dlc\gunforgeralt\data\gameplay\gui_new\icons\inventory\weapons\gfg_ak47_64x128.png`、`gfg_ak47_128x64.png`（.png 不進 git；用上面兩支工具重做）

**介面怎麼找圖**
- 物品 XML 的 `icon_path`（相對於 `gameplay\gui_new\`）；介面用 `img://` 加上這個路徑載入
- 找的順序：`gameplay\gui_new\` → 有 `CR4ScaleformContentDLCMounter`、而且啟用的 DLC 的 `scaleformDirectoryPath`（原版：bob、dlc1、dlc5、dlc10、dlc12～15、dlc18、ep1；dlc8 也有這個掛載器，但 `initiallyEnabled = False`，不在裡面）
  - `editor.log` 的 `Failed to convert path '…' to a depot path.` 只列**找不到**的路徑；找到的那個不寫 → 只看這幾行會以為沒去找我們的 DLC
  - 同一張圖第二次以後只寫第一個路徑（推論：有快取）
- **`.reddlc` 加了 `CR4ScaleformContentDLCMounter` 後，要重開 REDkit 才生效**
  - 同一次開著的 REDkit：掛載器的數字有增加（167 → 168），但輪盤還是載入失敗、顯示備用圖（一隻橘色蜘蛛：`RadialMenuItemEquipped.as:733`）
  - 重開 REDkit 後：輪盤、物品欄都顯示我們的圖（紀錄寫 `gameplay\gui_new\` 和原版 DLC 都找不到 → 圖是從我們的 DLC 來的）
  - REDkit 開著時在 `workspace` 新建的圖檔，也要重開才讀得到（同 `CLAUDE.md` §6 第 16 項）

**輪盤的十字弩格子**（`RadialMenuItemEquipped.as`）
- 格子的圖示框：類別 `crossbow` 固定 64×128（直的：`:764-770`）；其他類別 60×60（`:771-777`）
- 資料有 `multiplyX`、`multiplyY` 時，框的寬、高、位置各乘上它（`:626-633`、`:779-782`；原版腳本沒用到）
- 選到這格時，中間的大圖照圖的原尺寸顯示（`RadialMenuSubItemView.as:110-118`）
- 資料來自 `hudModuleRadialMenu.ws:998-1194` 的 `UpdateCrossbowItemData`，放在 `dataList` 的最後一筆：
  - 格子本身的 `itemIconPath`（沒有 `img://`）
  - `itemsList`：中間的大圖用；裝備中的那把沒有 `img://`、弩箭有
  - `itemsRangedList`：換遠程武器用；有 `img://`

**做法**（`gfg_ak47.ws`「輪盤的 AK 圖示：水平」）
- 包 `UpdateCrossbowItemData`：原版做完後，圖示路徑含 `gfg_ak47_64x128.png` 的換成 `gfg_ak47_128x64.png`；格子本身再加 `multiplyX` = 2、`multiplyY` = 0.5 → 框變成 128×64
- 物品欄、其他地方照物品 XML（直的）

**結果**（重開 REDkit 後）
- 輪盤：AK 水平、在圓框內
- 物品欄的 Ranged weapon 格：AK 直的、槍口朝上偏右

**開物品欄**
- **拿著 AK 時開不了**：十字弩的 `Lock()` 擋住所有動作，只留例外清單；物品欄只有在船上才是例外（`rangedWeapon.ws:374-395`）
  - 按 I 沒反應；按 Enter 開的面板裡，物品欄分頁是暗的
  - 主控台 `r4inventory()`（`temp.ws:889-892`）：面板開了馬上關（原因沒查）
- 先按 C 收槍，再按 I：物品欄打開

## 32. AK 的材質：高光太強，看不出顏色（2026-10-18 第 23 項；遊戲實測）

**現象**（改之前；`reference_level` 中午晴天，暫時的自由鏡頭指令近拍）
- 從右邊看：整把像鍍鉻的銀白色，木頭的棕色完全看不到
- 從左邊看：整把映出地面的藍綠色

**原因**
- AK 的材質（`pbr_std.w2mg`）用的是十字弩**金屬部分**（`Material3`）的數值：`SpecularColor` 130、`RSpecScale` 1.5、`RSpecBase` -0.4（`docs\m3.md`「`assets\ak47\gfg_ak47.xml`」）；十字弩的木頭部分（`Material0`）是 `RSpecScale` 0.2、`RSpecBase` -0.05，幾乎沒有高光
- `pbr_std` 的高光（`tools\cr2w_dump.py` 讀材質圖、整理連線）：
  - `SpecularColor` → 轉線性 → ×（(1 − `Normal`.a) × `RSpecScale` + `RSpecBase`）→ saturate → 轉回 gamma → 濕度 → 輸出 `Specularity`
  - `Normal`.a 是粗糙度
- CS2 貼圖的數據（Blender 讀 4096 的顏色圖、ORM 圖，縮成 1024 統計）：

| 區域（照顏色分） | 佔比 | 顏色（sRGB） | 粗糙度平均 | 金屬度平均 |
|---|---|---|---|---|
| 木頭（飽和、偏橘） | 14.7% | 0.41, 0.32, 0.26 | **0.31**（整把最光滑） | 0.03 |
| 灰（不飽和） | 79.0% | 0.33, 0.33, 0.32 | 0.44 | 0.085 |
| 金屬度 > 0.5 | 6.2% | 0.51, 0.51, 0.49 | 0.47 | 0.78 |

- → 舊數值下木頭的 F0（線性）≈ 0.22 ×（0.69 × 1.5 − 0.4）≈ **0.14**、灰色部分 ≈ 0.10；一般非金屬是 0.04 → 木頭反而最亮，整把像金屬
- CS2 把整把幾乎都當非金屬（金屬度 ≈ 0）→ F0 應該是 0.04

**改法**
- `SpecularColor` 59、`RSpecScale` 0、`RSpecBase` 1 → 高光固定 0.04（59／255 轉線性：sRGB 曲線 0.044、2.2 次方 0.040）
- 三個模型檔（`gfg_ak47`、`gfg_ak47_nomag`、`gfg_ak47_mag`.w2mesh）用新工具 `tools\mesh_material_patch.py` 原地改：
  - 材質參數在 `CMaterialInstance` 物件屬性串列之後的自訂資料：u32 數量；每筆 u32 大小（含自己）、u16 名稱、u16 型別、值；`Color` 的值是結構（1 個 0、Red／Green／Blue／Alpha 各一筆 Uint8 屬性、結束的 u16 0）
  - 每個檔只變 21 bytes（3 個顏色、2 個 float、3 層校驗碼）
  - 改完重開 REDkit 後，遊戲裡生效（沒試過不重開）
- 匯入用的材質 XML（`assets\ak47\gfg_ak47*.xml`）改成同樣的數值（以後重新匯入時一致）
- 沒做：金屬度高的 6.2%（亮灰色的小零件）現在也是非金屬的 0.04；要更像金屬得換成有高光貼圖的 `pbr_spec.w2mg`（`SpecularTexture` 直接當高光；說明方塊寫「Use it only if you need specular control over parts of the material」）＋重做顏色圖、匯入兩張新貼圖

**結果**（改之後）
- `reference_level`（同一個角度比較）：從右邊看，下護木是棕色，不再是整把銀白
- White Orchard（`levels\prolog_village\prolog_village.w2w`）下午 1 點晴天：上下護木橘棕色、機匣有光澤的灰色鋼、彈匣深色；左、右、前左三個角度都看得到顏色
- `reference_level` 的地板、反射都是藍綠色，看顏色要用正式的世界（Asset Browser 搜尋 `prolog_village.w2w`，雙擊開；`play game`）

## 33. AK 的槍聲：不用 Wwise 授權，自己做 SoundBank（2026-10-18 第 22 項；遊戲實測）

使用者：「應該有不走這種要申請授權這麼麻煩的方式就可以拿到。你去取得並且實作。一定有」

### 33.1 官方路線要 Wwise＋授權

- REDkit 的 **Publish → Cook Mod Sounds** 會叫 `WwiseConsole.exe`（`-GenerateSoundBanks`、`convert-external-source`），版本要 2023.1；沒有授權碼時寫「license key not found in the Wwise audio project …」（`editor.exe`、`wcc_lite.exe` 的字串）
- REDkit 附了官方的 Wwise 專案：`<REDKIT_DIR>\assets\w3_audio\w3_audio.wproj`（事件、階層的 `.wwu` 是 XML，可以直接讀）

### 33.2 遊戲怎麼讀聲音

- 遊戲：`<W3_GAME_DIR>\content\content0\soundspc.cache`（CS3W 第 2 版，4.6 GB；740 個 `.bnk`、1434 個串流 `.wem`）
  - mod 可以自己帶 `mods\<mod>\content\soundspc.cache`（`CSoundCacheResolver: attaching '%s'`、`Failed to add sound cache '%s'. Reached chain length limit %u`：`wcc_lite.exe` 的字串）
  - 格式（`tools\sound_cache.py` 的說明）：檔頭 64 bytes、資料從第 64 byte 起不對齊、名稱表、檔案表（每筆 24 bytes）
  - **校驗碼 = FNV-1a 64 位元，算「名稱表＋檔案表」**（WolvenKit-7 `WolvenKit.Wwise/SoundCache/Sound_Cache.cs` 的 `CalculateChecksum`；用原版的檔算出來相符 `0x9dd2f32351ecfd84`）；遊戲會檢查（字串「Sound cache index file is corrupted: CRC error」）
  - 檔頭第 48 byte = 最大的檔案大小進位到 4096 的倍數（原版 43264934 → 43266048）；第 8 byte 的 u64、第 44 byte 的 u32（原版 186）意思不明
- **REDkit 開的遊戲：不讀 cache，讀 depot 的散檔 `soundbanks\pc\*.bnk`**（`<REDKIT_DEPOT>\soundbanks\Pc\`：739 個 `.bnk`＋`Media\`；`combat.bnk` 和遊戲 cache 裡的一樣大）
  - **workspace 的同路徑也算**：加了 `workspace\soundbanks\pc\gfg_ak47.bnk`、重開 REDkit 後，`editor.log` 的 `CSoundBanksWhileInitTask - Started processing bank names - count [N]` 從 738 變 739
  - 開機自動載入的：`<REDKIT_DEPOT>\gameplay\globals\soundbanks_always_load.csv`（320 個）；其他的用腳本 `theSound.SoundLoadBank( 檔名, async )`（`sound.ws:88`；原版例：`playerWitcher.ws:11396-11401` 套裝的音效）
  - REDkit 的遊戲結束（F10）再開，腳本載入的 bank 還在（`SoundIsBankLoaded` 是 true）；`SoundUnloadBank` 再 `SoundLoadBank` 會重讀硬碟上的檔（換了 bank 的內容不用重開 REDkit）
- 事件的 ID 是 Wwise 的 FNV-1 32 位元（小寫名稱）：`combat` → 2764240573，和 `combat.bnk` 的 bank ID 相同

### 33.3 原版十字弩射擊的聲音

- Geralt：`weapon_gabriel_shot`，寫在動畫事件檔 `<REDKIT_DEPOT>\sounds\characters\man\combat\man_geralt_gabriel_sounds.w2animev`，掛在 `man_geralt_gabriel_*shoot_additive_*` 這些射擊動畫上；NPC 的十字弩是 `weapon_crossbow_shot`（`man_crossbow_sounds.w2animev`）
- AK 開火是腳本直接觸發、不播射擊動畫（§8.1、§19）→ 原版的射擊聲不會播；AK 的槍聲由腳本自己播
- `combat.bnk`：bank 第 150 版（Wwise 2023.1）；十字弩射擊的 5 個 Sound 是 Vorbis、媒體放在 bank 裡；隨機容器 615266803 → actor-mixer 850914486（−5 dB、匯流排 2525614280）→ 最上層的 actor-mixer 16956895
- 解析用 wwiser（bnnm/wwiser v20260808，`tools\_vendor\wwiser\wwiser.pyz`，不進 git）：`python -X utf8 tools/_vendor/wwiser/wwiser.pyz -d xml -dn <輸出> <bank>`，每個欄位都有位置

### 33.4 做法

- 聲音：CS2 的 `Weapon_AK47.Single`（`soundevents\game_sounds_weapons.vsndevts:20502-20595`）用 `ak47_02`、`ak47_01`、`ak47_04` 三個檔（沒用 `ak47_03`），`instance_limit = 1`
- **`tools\ak_soundbank.py`**：WAV → PCM 的 WEM → `workspace\soundbanks\pc\gfg_ak47.bnk`（不用 Wwise）
  - WEM：fmt 0x18 bytes（格式 0xFFFE、cbSize 6、第 0x14 byte 聲道設定 0x3102／0x4101：vgmstream `wwise.c`；遊戲 WEM 的值相同）、hash、junk、data（樣本從第 96 byte 開始，同遊戲 `fx_haptic.bnk` 的 WEM）
  - bank：BKHD（照 `combat.bnk`，換 ID）、DIDX、DATA（每個媒體 16 對齊）、HIRC；物件從 `combat.bnk` 的十字弩射擊複製再改欄位（改之前先檢查範本的值）
  - 事件 `gfg_ak47_shot` → 播放 → 隨機容器（不連續播同一個；同時最多 1 個、新的蓋掉舊的：CS2 的 instance_limit）→ 3 個 Sound（PCM，plugin 0x00010001）
  - **隨機容器掛在十字弩的 actor-mixer 850914486 底下**：匯流排、3D 定位、遊戲的環境殘響跟著十字弩；不掛在十字弩的隨機容器底下（會被混進原版十字弩的隨機清單）
  - 新的 ID 和原版 739 個 bank 比對過，沒有撞到（`--check`）
- 腳本（`gfg_ak47.ws` 的 `GfgShotSound`）：每開一槍（`GfgTryFire`）→ bank 還沒載入就同步載入 → `ownerPlayer.SoundEvent( "gfg_ak47_shot" )`

### 33.5 驗證：Claude 聽不到 → 錄電腦播的聲音

- `tools\audio_rec.py`（WASAPI loopback；soundcard 0.4.6 裝在 `tools\_vendor\pylib314`，不進 git）
- **測試音**：bank 暫時換成 1000／1500／2000 Hz 的 0.6 秒正弦波 → 遊戲裡錄到 2000.0 Hz、0.6 秒（能量 94% 在這個頻率）→ bank 載入、PCM 解碼、取樣率（44.1 kHz）都對
- **槍聲**：各頻帶（30 Hz～16 kHz，9 個八度）的音量和 CS2 原檔的差距一致（−10～−12 dB，−6 dB 版本）→ 沒有被濾波；逐樣本的相關只有 0.5 左右（遊戲的環境殘響等；CS2 的三個檔彼此的相關就有 0.68～0.89）
- **全自動**：按住約 1.5 秒錄到 16 發，間隔 0.084～0.118 秒（600 RPM）
- **音量**（`SoundEvent` 掛在玩家身上，原版十字弩射擊 `weapon_gabriel_shot`：峰值 0.51、100 毫秒音量最大 −18.0 dBFS）：
  - 0 dB：峰值 0.985（頂到上限，快破音）、−13.3 dBFS
  - −6 dB：峰值 0.51、−19.2 dBFS（和十字弩差不多）
  - **−3 dB（採用）**：峰值 0.67～0.74、−14.7～−15.1 dBFS（比十字弩大聲約 3 dB）
- 注意：
  - 主控台的 `SoundEvent(…)`（`theSound` 的全域物件）有時候錄不到聲音 → 測試掛在玩家身上
  - 主控台沒打開時打字，字母會變成遊戲按鍵（10-18 進了拍照模式，遊戲暫停、錄到全 0）

### 33.6 裝進遊戲時

- REDkit 的 Publish 不會把 `workspace\soundbanks` 包進去（`packed\` 裡沒有 `soundspc.cache`）
- → `python -X utf8 tools/sound_cache.py packed/mods/modgunforgeralt/content/soundspc.cache --pack workspace/soundbanks/pc/gfg_ak47.bnk`（寫完讀回來檢查校驗碼、內容）
- 兩個意思不明的檔頭欄位照抄原版；**還沒在 Steam 版的遊戲測過**（使用者 2026-10-17：開發完整再裝）

### 33.7 wcc_lite 的 EULA

- 10-18 03:34 直接跑 `wcc_lite.exe cooksounds`（想看用法）之後，`tools\wcc_compile.py` 再跑時又跳出 EULA 視窗
- 沒有替使用者按 Agree（`tools\wcc_compile.py` 的說明：要使用者本人確認）→ 改用 REDkit 的 Reload scripts 確認編譯（`Scriptables reloaded.`）

---

## 34. AK 用自己的一套動畫圖、兩手握好才開火（2026-10-18 第 25、26 項；遊戲實測）

### 34.1 玩家的動畫圖堆疊、slot

- 堆疊：`GetBehaviorGraphInstanceName(i)`，0 在最下面；平常 `[0]Gameplay [1]PlayerOverlay`，騎馬 `[0]VehicleHorse [1]PlayerOverlay`；`PlayerOverlay` 是 alwaysOnTop
- 玩家的 8 個 slot 都在 `CAnimatedComponent.runtimeBehaviorInstanceSlots`（`behaviorInstanceSlots` 是空的）：Cutscene、PlayerOverlay(top)、StoryScene、VehicleHorse、PlayerSwimming、PlayerSailing、Gameplay、Inventory
  - 來源：`geralt_player.w2ent` 的 `CAnimBehaviorsParam`（componentName `man_base`）
- **腳本可以換 slot 的圖**：`@addMethod(CAnimatedComponent)` 改 `runtimeBehaviorInstanceSlots[i].graph`（`(CBehaviorGraph)LoadResource( 路徑, true )`）
  - 實例重新建立時才用新的圖：`DetachBehavior( 名稱 )` + `AttachBehaviorSync( 名稱 )`
  - `ActivateBehaviorsSync([已經在用的名稱])` 不會重建
  - 實測順序（`gfg_ak47.ws` 的 `GfgApplyAkGraphs`）：拆 overlay → 拆、掛底層 → 掛 overlay → 堆疊照舊 `[底層, PlayerOverlay]`；騎馬中也可以（`stack VehicleHorse PlayerOverlay`）
  - 也能加新的 runtime slot 再 `ActivateBehaviorsSync`（overlay 自動留在上面）；本專案沒用到
- 新的 workspace 檔（4 張圖）要重開 REDkit 才讀得到（`CLAUDE.md` §6.16）

### 34.2 動畫圖、動畫組改名（`tools\ak_graphs.py`）

- 原因：我們的動畫組用原版的名稱蓋過原版 → 原版十字弩也變成 AK 的姿勢（雙手、扭腰）；改過的 `pc_overlay`、`pc_gameplay` 也套在十字弩
- 做法：原版 4 張圖（`pc_overlay`、`pc_gameplay`、`pc_rider`、`pc_swimming`）各做一份複本，84 段動畫名稱 `man_` → `gfg_`（第一個出現的）；動畫組同樣改名
  - 同長度改名：只改字串表、名稱表的雜湊（FNV-1a 32，對 UTF-8 加結尾 0；空名稱是 0）、表 0／1 的 CRC、檔頭的 CRC；物件用名稱的索引，資料不變
  - 動畫組裡每個名稱第二次出現的是 `importFile`（字串，只是紀錄）→ 不改
  - 之後在 REDkit 匯入、重匯動畫：檔名要用 `gfg_*.re`（用 `man_` 開頭會多一筆原版名稱；工具會擋）
- 84 段只在這 4 張圖用到（5 段也在 `pc_combat_sword.w2beh`，玩家沒有這張圖的 slot）
- 結果（遊戲實測）：
  - 原版十字弩：瞄準單手（右手）、射完收回；騎馬單手瞄準、左手拉韁繩
  - AK：裝上時紀錄 `AK graphs true: rebuilt base true, stack Gameplay PlayerOverlay`；開火、側移、騎馬雙手持槍照舊
  - 兩把互換（地面、騎馬中）：每次都換對

### 34.3 兩手握好槍才開火（第 26 項）

- 原版：拿出（`State_WeaponDraw`）→ 動畫圖進瞄準就到 `State_WeaponAim`（`rangedWeapon.ws:98-103`），這時兩手還在把槍拿到前面
- 量法：右手 `r_hand` 到左手武器骨頭 `l_weapon`（AK 掛在這裡）的距離 d；槍管方向（`l_weapon` 座標：握把 (-0.3032,-0.0115,-0.2320) → 槍口 (0.2368,0.0409,0.1710)）和鏡頭正前方的夾角
- 地面拿出：Draw 0.38 秒 → Aim；進 Aim 後 0.19 秒 d 穩定在 0.426、槍管對準
- d 的範圍（開火中、瞄準中）：
  - 兩手握槍 0.404～0.438：站、走、側移、換彈中、騎馬、往上／側面／近距離（2 公尺）瞄準、連射
  - 拿出途中 0.36～1.2；衝刺單手提槍 0.47～0.88（擺動時偶爾一格 0.43）
  - **騎馬、槍收著（兩手拉韁繩）也是 0.40～0.44** → 只看 d 分不出有沒有拿槍；但這時不是瞄準狀態
- 修正前的問題（紀錄）：
  - 拿出途中就開火（使用者回報）
  - 衝刺停下時槍還單手提著：槍管偏 80°、30° 各開一槍，第三發才對準
  - 騎馬拿出：第一發槍管偏 29°（兩手已握著，槍還在轉向目標，約 0.2 秒後 5°）
- 槍管夾角不能當條件：近距離（2 公尺）一直瞄準時「槍管 vs 槍口→目標點」12～14°、連射到 26°；騎馬時「槍管 vs 鏡頭」隨鏡頭俯仰 3～25°
- 做法：d 在 0.395～0.445 超過 0.02 秒（騎馬 0.2 秒）才開火（`GfgGripUpdate`、`GfgGripReady`）
  - 結果：地面拿出第一發在進 Aim 後 0.21 秒（偏 9°）；衝刺停下等到 d 0.409（偏 2°）才開；騎馬拿出第一發偏 11°（穩定值約 10°）；換彈後馬上接著射；連射間隔照舊 0.1 秒
  - 連拍（`desk.ps1 burst … mouse=left`）：0.34 秒槍從背上拔出、0.64 秒舉好、0.70 秒第一個火光

### 34.4 操作上學到的

- REDkit 裡玩遊戲時，滑鼠被鎖在遊戲畫面裡 → REDkit 的選單點不到（游標停在畫面上緣）
  - 要重載腳本：**F10 結束遊戲**、回到編輯器 → Tools → Debuggers → Reload scripts → 再開遊戲
  - F10 是結束遊戲（不是暫停切換）
- 村子裡太擠（衝刺、叫馬會卡）：`xy(100, -40)`（`playerCheats.ws:325`，傳送到地面）→ White Orchard 村外的空地
- `spawn('wolf', …)` 生在鏡頭方向；被房子擋住時看不到

---

## 35. AK 的子彈（2026-10-18 第 27 項；遊戲實測）

### 35.1 原版的無限箭 → AK 換成自己的子彈

- 原版：裝上十字弩類、子彈格空著時自動加一種無限的箭（`AddAndEquipInfiniteBolt`：`playerWitcher.ws:5679-5717`；`:6386-6406`）
  - 地面 `Bodkin Bolt`、游泳或潛水 `Harpoon Bolt`（`GetCurrentInfiniteBoltName`：`:5663-5676`）；入水、出水時換（`swimming.ws:137`、`:267`）
  - 卸下十字弩類時刪掉格子裡的無限箭（`:6720-6727`）
- AK：物品 `gfg_ak47_ammo`（照 Bodkin）、`gfg_ak47_ammo_water`（照 Harpoon），`hold_template` = `gfg_ak47_bullet.w2ent`（裝在槍上的那顆、射出去的都是它）；腳本見 `gfg_ak47.ws`「AK 的子彈」
- 遊戲實測（`gfg_debug.ws` 的暫時指令 `gfgammo()`）：
  - 拿 AK：`bolt=gfg_ak47_ammo`、裝好的是 `gfg_ak47_bullet…`
  - 物品欄裡把 AK 換成原版十字弩（選取格子 → Space）：`bolt=Bodkin Bolt`、裝好的是 `bodkin_bolt…`、子彈從物品欄消失；換回 AK：子彈格又是子彈（圖示 3 顆子彈）；主控台 `equipitem('gfg_ak47')` 也一樣
  - 裝著 AK 時把爆炸箭裝到子彈格：擋下、左下角「You cannot do that now.」；子彈格選取時下方按鍵提示沒有「卸下」
  - 輪盤：物品欄有鈍頭箭、爆炸箭時，AK 那格沒有「Change Bolt」（滾輪）提示；原版十字弩那格有
  - 游泳：`bolt=gfg_ak47_ammo_water`、裝好的還是 `gfg_ak47_bullet…`；上岸：`gfg_ak47_ammo`
- 輪盤下方沒有文字的「W」：原版 `hud_radial_change_ranged`（物品欄有兩把以上遠程武器時出現：`HudModuleRadialMenu.as:1086-1100`）；REDkit 裡這個字串是空的（原版的事）

### 35.2 射出去的子彈

- 彈頭模型 直徑 0.67 公分、長 1.85 公分（`tools\ammo_build.py`）；1 公尺外約 12 像素長（1920 寬的畫面）；715 公尺／秒時一格飛 12 公尺 → 正常速度看不到（真的子彈也看不到）
  - 先前「放慢到 3 公尺／秒、瞄天空連拍沒看到」：太小，截圖又是半解析度
- 證據（暫時指令：每格記下所有標籤 `bodkinbolt` 的實體、飛行中把子彈放大）：
  - 飛行中模型元件 `IsVisible()` = true；碰到樹後 false、停在原地（碰撞包裝藏起來）
  - 放大 10 倍、3 公尺／秒：槍口到準心一排黃銅色的彈頭
  - 原尺寸生成在鏡頭前 1 公尺：銅色尖頭的彈頭
- 水中：潛水時左鍵是 `Finish`／`Finisher`，中鍵是 `ThrowItem`（使用者的 `input.settings` 的 `[Diving]`）→ 按住中鍵、放開：AK 照原版十字弩射一發，射出去的是 `gfg_ak47_bullet…`（射程、速度照原版的水中）
- 中鍵（原版十字弩的瞄準）放開時照原版射一發（§17.7 也看過）；按住中鍵時短按左鍵（0.06、0.12 秒）沒有開火：沒有再查

### 35.3 提示框

- 物品欄的提示框顯示的是 `ItemType`（`TooltipInventory.as:269-290`）；不是護甲時 `ItemType` = 類別（`guiTooltipComponent.ws:502`、`:641`）；`ItemCategory`（`:646`）這裡沒顯示
- 子彈改成自己的字串 `gfg_item_category_ammo`（10000010：EN Ammunition、ZH 彈藥）→ 提示框「7.62X39MM／AMMUNITION／4-6 PIERCING DAMAGE」（EN 實測；ZH 沒切語言看）
- 數值照原版 Bodkin（穿刺 4-6、銀 +4）：AK 的傷害由腳本算，和子彈物品無關

### 35.4 學到的

- **`GetComponentsByClassName` 的結果指定給迴圈裡同一個陣列變數時，會接在舊的後面**：第 2 個實體拿到 [第 1 個的元件, 自己的]（`comps[j].GetEntity() == ents[i]` 只有最後一個是 true）→ 迴圈裡每次用新的變數或先 `Clear()`（`gfg_ak47.ws` 的用法是每次呼叫的區域變數，沒問題）
- 物品欄：Space 作用在「選取中」的格子；遊戲游標移過去（`desk.ps1 rmove`）只顯示提示框、不會選取 → 先點一下再按 Space（10-18 第一次在格子上按 Space 換成了第一格的十字弩）
- 鏡頭前生成實體：`theCamera.GetCameraPosition() + theCamera.GetCameraDirection() * 距離`；畫面位置：`theCamera.WorldVectorToViewRatio( 位置, x, y )`，(x+1)/2、(y+1)/2 = 遊戲畫面的 0～1（`hud.ws:1864-1874`）
- 元件放大：`CComponent.SetScale( Vector )`（`components.ws:28`）

### 35.5 子彈的物品欄圖示（2026-10-19 第 28 項）

- 使用者 10-18：3 顆子彈直立並排「很醜沒質感」→「一顆子彈就夠，然後不要死死的垂直呈現」
- 原版的箭：格子都是 1×2（`grid_size` 2：`def_item_bolts.xml:130` 等）；圖示 Bodkin `weapons\bodkin_bolt_64x128.png` 4 支直立、魚叉箭 `arrows\harpoon_bolt_64x128.png` 1 支斜放（尖朝右上）、其他 `arrows\*_64x64.png` 1 支斜放
- 做法：`tools\ammo_build.py` 加 `--tilt`、`--shadow`、`--margin`，預設改成 1 顆、往右斜 25°（尖朝右上）、後面墊一層往右下偏的柔和暗影（不透明度 0.6）、留白 10% → 覆蓋同名的 `gfg_ak47_ammo_64x128.png`（兩個子彈物品共用）
  - 試了 20、25、30、35°（暫存 `s28b\sheet_v1.png`：放大 3 倍、深色底和原版並排）：35° 寬度卡住、子彈變小；25° 最大又看得出斜放
- 遊戲裡（REDkit、reference_level；C 收槍 → I）：裝備欄的子彈格（Bolts）是一顆斜放的子彈，和劍的格子一樣斜；提示框照舊（原版物品的提示框沒有圖示）
- **遊戲開著時覆蓋同名的圖檔：關掉、再打開物品欄就是新的**（換成 35° 的版本 → 重開物品欄變成 35°，換回 25° 也一樣；REDkit、遊戲都沒重開）
- 測試時注意：點一下遊戲畫面（左鍵）會把 AK 拿出來 → 物品欄打不開；Esc 在物品欄外按是遊戲選單

## 36. 中鍵、主動換彈、右下角提示、戰鬥中閃躲（2026-10-19 第 29、31～33 項；遊戲實測）

### 36.1 中鍵沒有行為（第 31 項）

- 原版：地面 `CPlayerInput.OnCbtThrowItem`／`OnCbtThrowItemHold`（`playerInput.ws:3133-3273`）；拿出時中鍵還按著就進中鍵瞄準（`rangedWeapon.ws:1345` `CheckGotoAimThrow`）
- 騎馬：`W3VehicleCombatManagerStateNull.StartItemAction`（`useVehicle.ws:744-758`；`OnItemAction`、`ShouldEnterNextState` 都走它）
- 做法：AK 是選用物品時兩個輸入事件都擋；按下時 `ForceDeactivateAction('ThrowItem'／'ThrowItemHold')`（同原版強制收弩：`rangedWeapon.ws:208-209`）；騎馬的 `StartItemAction` 不做事
- 實測：AK 在背上、拿在手上、連射中按住中鍵：都不拿出、不瞄準、不開火；原版十字弩（輪盤選好）：中鍵瞄準、放開射一發（`Thrown <<Bodkin Bolt>>`）
- **選用物品可能指著背包裡的 AK**：主控台 `additem('Crossbow 1', 1, true)` 換掉 AK 後，選用物品還是 AK（已經沒裝備）
  - 只看標籤的話，原版十字弩的中鍵、拔劍都被擋掉 → `GfgIsAkSelected`：選用的 AK 要就是遠程武器格裝的那把（`GetItemEquippedOnSlot( EES_RangedWeapon )`）
  - 修好後這情況可以拔劍；中鍵沒反應是原版自己的行為（射擊流程用選用物品的實體：`r4Player.ws:10712`）

### 36.2 主動換彈（第 33 項）

- R＝使用者 `input.settings` 的 `AttackWithAlternateHeavy`（`[Exploration]`、`[Combat]`；按住 0.2 秒是 `SpecialAttackWithAlternateHeavy`）；處理：`playerInput.ws:2054`、`:2284`
- 換彈同打空時：刪掉膛內那發（`ClearDeployedEntity` 只刪停下來的：`rangedWeapon.ws:532-539`）→ `isWeaponLoaded` false → `Crossbow_Reload` 事件；之後照原版：中段 `OnWeaponReload` 裝新的一發、結束時 `ResetShotCount`（`:75-94`、`:338-363`、`:697-703`）
- 實測：射 11 發 → R → `GfgManualReload(): Destroying entity …`、2 秒後 `Equipped bullet item gfg_ak47_ammo`、射擊數歸零；彈匣滿時按 R 沒有紀錄；AK 在背上按 R：不重擊、不拔劍

### 36.3 右下角的操作提示（第 32 項）

- 原版：`CR4HudModuleControlsFeedback.SendInputContextActions`（`hudModuleControlsFeedback.ws:216-769`，private）依按鍵情境列動作 → `SetFlashArray( "hud.module.controlsfeedback", … )`
  - 重做的時機：情境變了（`UpdateInputContext`：`:84-93`）；OnTick 發現輸入裝置、允許的動作變了（`:95-162`）
- **Flash 只有 5 格**：`HudModuleControlsFeedback.as` 的 `mcBtn1`～`mcBtn5`，第 6 項以後不顯示
- 做法：包 `SendInputContextActions`：原版做完之後，AK 拿在手上、情境是探索／戰鬥 → 自己整份重做；拿出、收起時（`GfgHudTick`）呼叫 `UpdateInputContextActions`
- 字串（原版沒有）：`gfg_hud_holster` 10000011（Holster／收槍）、`gfg_hud_reload` 10000012（Reload／換彈）、`gfg_hud_shoot` 10000013（Shoot／射擊）
- REDkit 剛開遊戲時，原版的提示鍵名顯示 `None`：還沒用過鍵盤滑鼠（`m_lastUsedPCInput` false 時不查鍵盤的鍵）；用過之後正常
- 實測（EN）：
  - 探索：Sprint（Left Shift）、Jump（Space）、Witcher Senses [Hold]、Reload（R）、Holster（C）
  - 戰鬥：Shoot（滑鼠）、Reload（R）、Dodge（Left Control）、Cast Sign（Q）、Holster（C）
  - 收起 AK：原版 4 項（含 Call Horse）

### 36.4 戰鬥中閃躲、翻滾（第 29 項）

- 原版流程：`OnCbtDodge`／`OnCbtRoll`（`playerInput.ws:2649`、`:2714`）→ `EvadePressed`（`playerWitcher.ws:3715`）→ `OnPerformEvade`（戰鬥狀態：`combat.ws:1134`；其他狀態是空的：`r4Player.ws:13448`）→ `PerformEvade`：設 `combatActionType` = `CAT_Dodge`、`isRolling` → `RaiseForceEvent( 'CombatAction' )`（`combat.ws:1424-1436`）
- 拿 AK 戰鬥時玩家在 `CombatFists`；條件都過（可閃躲、可輸入；`OnPerformEvade`、`OnCombatActionStart` 都有跑），但**人站著不動**；AK 收起來時翻滾正常
- 原因：上半身動畫圖的瞄準姿勢在**戰鬥動作中**（`isInCombatActionForOverlay`：`player.ws:1505-1521`）一律選全身瞄準（#18960：§20.10）→ 閃躲動畫（連位移）被全身瞄準的姿勢整個蓋掉
  - 原版十字弩通常在持劍戰鬥時用；這是「空手戰鬥＋兩手 AK」的新組合
- 做法（`GfgEvadeTick`）：AK 拿在手上、閃躲中（`IsCurrentlyDodging()` 或戰鬥動作是 `CAT_Dodge`／`CAT_Roll`）到結束後 0.3 秒：
  - `isInCombatActionForOverlay` 設 0：原版只在開始、結束時設 → 結束時照 `IsInCombatAction()` 還原
  - `playerMoveTypeForOverlay` 設跑步：原版每格設（`locomotionDirectController.ws:1095`）→ 在 `CalculateMoveSpeed` 的包裝裡設
  - `fullBodyAnimWeight` 設 0：原版每 0.1 秒設 → 在 `ProcessFullBodyAnimWeight` 的包裝裡設
  - → 上半身圖走「上半身」那支（同推移動鍵時），身體照閃躲動畫
- 第二個問題：閃躲快結束時 AK 被收到背上，之後不會自動舉起（沒有 `OnForceHolster` 的呼叫，十字弩直接進 `State_WeaponHolster`）
  - 上半身圖 WeaponAim → WeaponHolster（#21321）：動畫事件 `AllowBlend`＋沒在射擊、沒在瞄準＋有移動速度
  - → 閃躲期間上半身圖的 `isAimingWeapon` 當作 1（只改玩家的動畫變數；十字弩自己的欄位不動，結束時照它還原）
- 實測：Ctrl＋D 閃躲、空白鍵翻滾、A＋空白鍵往左翻滾：都有動作、AK 單手跟著身體、翻完回到兩手持槍（`State_WeaponAim`）；翻完馬上射正常
  - 連射中翻滾：翻滾時停火（兩手沒握好：§34.3）、翻完接著射；換彈中翻滾：照樣換完、歸零
- 查法：暫時包 `W3PlayerWitcher.EvadePressed`、`CR4PlayerStateCombat.OnPerformEvade` 記下條件（`gfg_debug.ws`）；連拍用 `desk.ps1 burst … hold=a key=space`、主控台 `slow(0.25)` 放慢
