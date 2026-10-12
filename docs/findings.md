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
| 5 | `@replaceMethod` 在 5.x 能不能用；`local` 資料夾是否必要 | M1 | **`@replaceMethod` 有官方文件**（第 12.4 節）；`local` 是否必要仍待實測 |
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

**加上 `-patch` 時**

- 🔶 快取是在引擎啟動時、從 `r4data\scripts` 重建，比 patch 編譯還早
  → 應該不會把 mod 腳本寫進快取
- 執行時仍要先備份快取，跑完比對雜湊確認

### 12.6 其他：Wwise 版本

- ⚠️ Changelog（REDkit 5.0）原文：「REDkit now requires Wwise 2023 with the Mastering Suite and Motion plugins installed.」
- → CLAUDE.md §3 原本寫的「Wwise 2021.1.7.7796（必須剛好這版）」對 REDkit 5.0 已經過時
- 確切的 2023 版號仍待查（Wiki 的 Wwise 頁面可能還沒更新）
