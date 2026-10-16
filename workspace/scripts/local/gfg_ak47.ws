// gunforgeralt：AK-47 的射擊機制（M2）
// 只對帶有 gfg_ak47 標籤的十字弩生效（gunforgeralt_items.xml），其他十字弩維持原版行為。

// 目前裝備的十字弩是不是 AK
@addMethod(Crossbow)
function GfgIsAk() : bool
{
	var id : SItemUniqueId;

	if ( !ownerPlayerWitcher )
		return false;
	if ( !ownerPlayerWitcher.GetItemEquippedOnSlot( EES_RangedWeapon, id ) )
		return false;
	return ownerPlayerWitcher.inv.ItemHasTag( id, 'gfg_ak47' );
}

// 彈匣容量：XML 的 ammo 屬性（inventoryComponent.ws:4165 GetCrossbowAmmo，原版沒有呼叫者）
@addMethod(Crossbow)
function GfgMagazineSize() : int
{
	var id : SItemUniqueId;

	ownerPlayerWitcher.GetItemEquippedOnSlot( EES_RangedWeapon, id );
	return ownerPlayerWitcher.inv.GetCrossbowAmmo( id );
}

// 彈匣：原版射滿 shotCountLimit（預設 1）就播換彈動畫（rangedWeapon.ws:830-852），
// AK 改成射滿彈匣才播；沒播動畫時，原版會立刻裝上下一支箭（rangedWeapon.ws:276-297）。
// 不採用原版 S_Perk_17 多一發的規則。
@wrapMethod(Crossbow)
function PlayOwnerReloadAnim() : bool
{
	var magazine : int;
	var shouldPlayAnim : bool;

	if ( !GfgIsAk() )
		return wrappedMethod();

	magazine = GfgMagazineSize();

	if ( shotCount >= magazine )
		shouldPlayAnim = true;
	// 以下兩個條件照抄原版（rangedWeapon.ws:838-841）：特殊箭用完、第一次裝填
	else if ( previousAmmoItemName != 'Bodkin Bolt' && previousAmmoItemName != 'Harpoon Bolt' && GetSpecialAmmoCount() <= 0 )
		shouldPlayAnim = true;
	else if ( previousAmmoItemName == '' )
		shouldPlayAnim = true;
	else
		shouldPlayAnim = false;

	if ( shouldPlayAnim )
	{
		SetBehaviorGraphVariables( 'isWeaponLoaded', false );
		return true;
	}
	return false;
}

// ===== 全自動：AK 是選用物品時，左鍵＝扳機（使用者 2026-10-12 選定）=====

@addField(Crossbow)
var gfgTriggerHeld : bool;

// 下一發的預定時間（引擎時間，秒）
@addField(Crossbow)
var gfgNextShotTime : float;

// 上一次檢查能不能開火的時間（引擎時間，秒）
@addField(Crossbow)
var gfgLastCheckTime : float;

// 射擊間隔：CS2 m_flCycleTime = 0.1 秒（data/cs2/weapons.vdata:13298）
@addMethod(Crossbow)
function GfgCycleTime() : float
{
	return 0.1;
}

// 扣下／放開扳機
@addMethod(Crossbow)
function GfgSetTrigger( pressed : bool )
{
	var now : float;

	now = theGame.GetEngineTimeAsSeconds();
	gfgTriggerHeld = pressed;

	if ( pressed )
	{
		// 按住時當作「瞄準中」，同原版按下十字弩鍵（rangedWeapon.ws:44-48）：
		// 跑步、衝刺時原本只有拿著跑的動作、沒舉槍，試試動畫會不會換成舉槍跑（使用者 2026-10-13 選定；docs/findings.md §17.7）
		SetBehaviorGraphVariables( 'isAimingWeapon', true );
		SetBehaviorGraphVariables( 'isShootingWeapon', false );
		// 新的一次按下不沿用上次累計的時間，否則快速連點時兩發間隔會小於 0.1 秒
		// （實測最短 0.065 秒：docs/findings.md §13.15）
		if ( gfgNextShotTime < now )
			gfgNextShotTime = now;
		// 按下就檢查第一發，不等第一個計時器週期
		GfgTryFire();
		// 之後每個畫面檢查一次（0.001 秒的重複計時器，同 rangedWeapon.ws:1248 的寫法）
		RemoveTimer( 'GfgAutoFire' );
		AddTimer( 'GfgAutoFire', 0.001f, true );
	}
	else
	{
		RemoveTimer( 'GfgAutoFire' );
		// 放開：瞄準與射擊狀態都設回 false，同原版 Crossbow.ResetOwnerAndWeapon（rangedWeapon.ws:750-758）
		// 例外：換彈中（或還沒裝上箭）先不把瞄準設回 false，等回到瞄準狀態再設（OnWeaponAimStart 的包裝）。
		// 換彈結束時，動畫圖依「瞄準中」寫入 shootWeaponComplete：瞄準中 0（舉槍）、沒瞄準 1（垂手）；
		// AK 開火不經過射擊狀態，這個值會一直保留到下次換彈（docs/findings.md §19）→ 換彈一律走瞄準中那條路（使用者 2026-10-13 選定：一律舉槍）
		if ( GetCurrentStateName() != 'State_WeaponReload' && deployedEnt )
			SetBehaviorGraphVariables( 'isAimingWeapon', false );
		SetBehaviorGraphVariables( 'isShootingWeapon', false );
		thePlayer.SetIsAimingCrossbow( false );
		GfgKeepRiderAiming();
	}
}

// 回到瞄準狀態（動畫圖進入 WeaponAim：r4Player.ws:14738 → rangedWeapon.ws:98-103）：
// 換彈中放開扳機時保留的「瞄準中」，在這裡設回 false（GfgSetTrigger）；寫法同 OnSprintHolster 的包裝
@wrapMethod(RangedWeapon)
function OnWeaponAimStart()
{
	var crossbow : Crossbow;
	var result : bool;

	result = wrappedMethod();
	crossbow = (Crossbow)this;
	if ( crossbow && crossbow.GfgIsAk() )
	{
		if ( !crossbow.gfgTriggerHeld )
		{
			SetBehaviorGraphVariables( 'isAimingWeapon', false );
			crossbow.GfgKeepRiderAiming();
		}
	}
	return result;
}

// 騎馬時拿著 AK 不自動收槍，直到按 C 等收槍動作（使用者 2026-10-14 要求；docs/findings.md §24.6）
// 騎馬的動畫圖 pc_rider.w2beh 的十字弩狀態機：瞄準中（WeaponAim）時 isAimingWeaponRider、isShootingWeaponRider 都是 0 就收槍（#6779 → #6398），
// 換彈動畫結束時沒在瞄準也收槍（#6390；瞄準中則回到 WeaponAim：#7100）。地面的動畫圖沒有這條規則。
// → 騎馬拿著 AK 時，isAimingWeaponRider 一直當作 1（只改動畫圖的變數，十字弩自己的 isAimingWeapon 照扳機）；
//   有人要求收槍（OnForceHolster：C 鍵、換道具、空白鍵等）就放手，讓原版的收槍切換（#6773 → #6398）照常進行

@addField(Crossbow)
var gfgHolsterRequested : bool;	// 收槍中：不再把騎馬動畫圖當作瞄準中；AK 收好（或沒拿著）時清掉

@wrapMethod(Crossbow)
function OnForceHolster( optional forceUpperBodyAnim, instant, dropItem : bool )
{
	var now : float;

	// 被打中的動作（全身）播放中，原版的保險計時器把它當成「攻擊中」收起十字弩（InputLockFailsafe：rangedWeapon.ws:458-466）
	// 2026-10-16 實測被狼咬：failsafe 呼叫 OnForceHolster( true, true )，當時 combatActionType 0、fullBodyAnimWeight 1、不能做戰鬥動作
	// → 拿著 AK、不是真的在攻擊（輕／重攻擊：r4Player.ws:12863-12877）時不收（第 2 項：狼群裡開槍要維持射擊姿勢）
	if ( gfgInFailsafe && GfgIsAkDrawn() && !thePlayer.IsInCombatAction_Attack() )
	{
		now = theGame.GetEngineTimeAsSeconds();
		if ( now - gfgHolsterBlockLogTime > 1.0 )	// 暫時：確認擋到了
		{
			gfgHolsterBlockLogTime = now;
			LogChannel( 'GFG', "forceHolster blocked (failsafe, hit reaction) caType=" + ownerPlayer.GetBehaviorVariable( 'combatActionType' ) );
		}
		return true;
	}
	if ( GfgIsAkDrawn() )	// 暫時：查被狼咬時是誰收槍（第 2 項）
		LogChannel( 'GFG', "forceHolster instant=" + instant + " upper=" + forceUpperBodyAnim + " failsafe=" + gfgInFailsafe
			+ " pstate=" + ownerPlayer.GetCurrentStateName() + " caAllowed=" + ownerPlayer.GetBIsCombatActionAllowed()
			+ " caType=" + ownerPlayer.GetBehaviorVariable( 'combatActionType' ) + " full=" + ownerPlayer.GetBehaviorVariable( 'fullBodyAnimWeight' )
			+ " hitAnim=" + ownerPlayer.IsInHitAnim() + " inHitStart=" + thePlayer.gfgInHitStart + " inCA=" + ownerPlayer.IsInCombatAction() );
	if ( GfgIsAk() && GetCurrentStateName() != 'State_WeaponWait' )
		gfgHolsterRequested = true;
	return wrappedMethod( forceUpperBodyAnim, instant, dropItem );
}

@addField(RangedWeapon)
var gfgInFailsafe : bool;	// InputLockFailsafe 執行中（rangedWeapon.ws:445-487 會直接呼叫 OnForceHolster）

@addField(Crossbow)
var gfgHolsterBlockLogTime : float;	// 暫時：擋下收槍的紀錄一秒最多一筆

@wrapMethod(RangedWeapon)
function InputLockFailsafe( time : float, id : int )
{
	gfgInFailsafe = true;
	wrappedMethod( time, id );
	gfgInFailsafe = false;
}

@addMethod(Crossbow)
function GfgKeepRiderAiming()
{
	if ( !GfgIsAkDrawn() )
	{
		gfgHolsterRequested = false;
		return;
	}
	if ( ownerPlayer.IsUsingVehicle() && !gfgHolsterRequested )
		ownerPlayer.SetBehaviorVariable( 'isAimingWeaponRider', 1.f );
}

@addMethod(Crossbow)
timer function GfgAutoFire( dt : float, id : int )
{
	GfgTryFire();
}

// 移除原版的自動收槍計時器（同 rangedWeapon.ws:1367-1370）
// AK 停火後不自動收槍（docs/findings.md §13.18）；換彈完成後原版會再加上計時器（:1413-1428），
// 一移動或在空中就收槍（:649-671），所以除了每發之外，拿著 AK 時每格畫面也呼叫（使用者 2026-10-13 選定：§17.7）
@addMethod(Crossbow)
function GfgCancelAutoHolster()
{
	RemoveTimer( 'HolsterAfterDelay' );
	RemoveTimer( 'HolsterWhenMovingTimer' );
	ownerPlayer.SetBehaviorVariable( 'canHolsterAfterDelay', 0.f );
	ownerPlayer.SetBehaviorVariable( 'canHolsterAfterDelayHorse', 0.f );
}

// 附近有敵人時也能邊走邊射（使用者 2026-10-14 回報生成怪物後卡住不能動，選「推移動鍵時改上半身」；docs/findings.md §20.4）
// 原版附近有敵人（PCS_AlertNear）時一律全身瞄準（rangedWeapon.ws:916-920），全身瞄準沒有走路的動作，推移動鍵也不動；
// 原版靠放開扳機就收槍脫困（:1417-1418），AK 不自動收槍（GfgCancelAutoHolster）→ 卡死。
// AK 拿著、推著移動鍵時改成上半身瞄準，同原版在探索時推移動鍵（:940-943）；游泳（:931-938）、中鍵瞄準（:963-964）照原版
@wrapMethod(Crossbow)
function ProcessFullBodyAnimWeight( optional forceUpperBodyAnim : bool ) : bool
{
	var result : bool;

	result = wrappedMethod( forceUpperBodyAnim );
	if ( !GfgIsAkDrawn() || ownerPlayer.IsSwimming() || ownerPlayer.GetCurrentStateName() == 'AimThrow' )
		return result;
	// 開槍中又在移動：全身瞄準，腳用側移、後退的動作（使用者 2026-10-16 回報上半身扭轉；GfgAkTurnTick）
	if ( ownerPlayer.gfgFireMoving && !forceUpperBodyAnim )
	{
		setFullWeight = true;
		ownerPlayer.SetBehaviorVariable( 'fullBodyAnimWeight', 1.f );
		return true;
	}
	if ( result && !ownerPlayer.bLAxisReleased )
	{
		setFullWeight = false;
		ownerPlayer.SetBehaviorVariable( 'fullBodyAnimWeight', 0.f );
		result = false;
	}
	return result;
}

// 上半身動畫圖（pc_overlay.w2beh）的瞄準姿勢：「在戰鬥動作中」或「戰鬥姿態（經曲線 #18994）= 1 而且移動類型 ≤ 1（站著、走路）」時強制全身瞄準，
// 否則才看 fullBodyAnimWeight（#18960 → #18956 → #18979、#19002）；這裡的移動類型讀的是 playerMoveTypeForOverlay（#19006 → #17129）。
// 附近有敵人時移動控制器只給走路（locomotionDirectController.ws:1061-1071）→ 強制全身瞄準 → 腿沒有走路的動作，卡住（docs/findings.md §20.10）。
// AK 拿著、推著移動鍵時，給上半身看的移動類型改成跑步。設定的方式同原版（:1094-1095）
// 另外，附近有敵人時原版只能走（:933-941 只有 PCS_Normal、PCS_AlertFar 能跑），走路用的 WalkAlertNear 只有劍、拳頭的動作（§20.6）；
// 拿著 AK 時照野外的規則跑（使用者 2026-10-14 選定），才會用到有十字弩版本的跑步動作（Walk_Run_Cycles：§17.10）
@wrapMethod(CR4LocomotionPlayerControllerScript)
function CalculateMoveSpeed() : float
{
	var speed, inputMag : float;

	speed = wrappedMethod();
	if ( speed <= 0.f || player.playerMoveType > PMT_Walk || !player.rangedWeapon || !player.rangedWeapon.GfgIsAkDrawn()
		|| player.IsSwimming() || player.GetCurrentStateName() == 'AimThrow' )
		return speed;

	// 跑步的條件照原版野外（:933-941）；推的幅度的取法同原版（:805-814）
	if ( _inputLocoEnabled )
		inputMag = _inputMagLastCached;
	else
		inputMag = thePlayer.substateManager.m_InputO.GetModuleF();
	if ( player.GetPlayerCombatStance() == PCS_AlertNear && inputMag > thePlayer.GetInputModuleNeededToRun()
		&& ( thePlayer.IsActionAllowed( EIAB_RunAndSprint ) || thePlayer.IsCombatMusicEnabled() ) && !thePlayer.GetIsWalkToggled() )
	{
		speed = MinF( inputMag, speedRunning );
		player.playerMoveType = PMT_Run;
		// 原版跑步分支結束時設定的值（:1056-1059、:1094-1097）
		player.SetBehaviorVariable( 'forceWalkSpeed', 0 );
		player.SetBehaviorVariable( 'playerMoveType', (int)PMT_Run );
		player.substateManager.SetBehaviorParamBool( 'ikWeight', false );
	}

	player.SetBehaviorVariable( 'playerMoveTypeForOverlay', (int)PMT_Run );
	return speed;
}

// 背後的瞄準點固定往右轉（使用者 2026-10-14 回報：背對怪物跑（S）邊射時，上半身一下往右、一下往左快速切換；要「固定一邊」，後來改成右邊）
// 上半身瞄準（pc_overlay.w2beh #18587 LookAtUsingAnimations）依瞄準點相對身體的水平角度擺姿勢，範圍 ±180°；
// 瞄準點在正後方時角度在 +179°、-179° 之間跳 → 左右切換（docs/findings.md §21）。
// 原版每格在 UpdateLookAtVariables 把瞄準點交給動畫圖（actor.ws:3592-3607；呼叫：r4Player.ws:2884）；
// AK 拿著時：背後的角度最多扭到 GfgBackAimMaxAngle()；瞄準點在另一邊超過 165° 就改到固定的那一邊，回到最大角度以內才放開。
// 最大角度不用 179°：179° 時剛開槍、換完子彈還是會閃幾下（使用者 2026-10-14），推論是節點以肩膀骨頭算角度、超過 180° 停止瞄準（#18587 的 Angle to stop looking=180）

@addField(CR4Player)
var gfgBackAimForced : bool;	// 背後的瞄準點正被改到固定的那一邊

// 背後的瞄準點固定往哪一邊轉：+1 左、-1 右（heading 往左為正：r4Player.ws:16144-16145）
@addMethod(CR4Player)
function GfgBackAimSide() : float
{
	return -1.f;
}

// 背後最多扭幾度（離 180° 留餘裕；可調）
@addMethod(CR4Player)
function GfgBackAimMaxAngle() : float
{
	return 150.f;
}

@addMethod(CR4Player)
function GfgFixBackAim( target : Vector ) : Vector
{
	var pos, result : Vector;
	var diff, side, maxAngle, outAngle : float;

	pos = GetWorldPosition();
	diff = AngleDistance( VecHeading( target - pos ), GetHeading() );	// 同原版 actor.ws:3602（沒有除以 180）
	side = GfgBackAimSide();
	maxAngle = GfgBackAimMaxAngle();
	if ( AbsF( diff ) < maxAngle )
		gfgBackAimForced = false;
	else if ( diff * side < 0.f && AbsF( diff ) > 165.f )
		gfgBackAimForced = true;

	if ( gfgBackAimForced )
		outAngle = side * maxAngle;
	else if ( AbsF( diff ) > maxAngle )
	{
		if ( diff > 0.f )
			outAngle = maxAngle;
		else
			outAngle = -maxAngle;
	}
	else
		return target;

	result = pos + VecFromHeading( GetHeading() + outAngle ) * VecDistance2D( target, pos );
	result.Z = target.Z;
	result.W = target.W;
	return result;
}

@wrapMethod(CActor)
function UpdateLookAtVariables( lookAtTargetActive : float, lookAtTarget : Vector )
{
	var player : CR4Player;

	player = (CR4Player)this;
	if ( player && player.rangedWeapon && player.rangedWeapon.GfgIsAkDrawn() )
	{
		if ( !player.IsUsingVehicle() )
		{
			lookAtTarget = player.GfgAkLookAtPoint();
			lookAtTargetActive = 1.f;
		}
		lookAtTarget = player.GfgFixBackAim( lookAtTarget );
	}
	wrappedMethod( lookAtTargetActive, lookAtTarget );
}

// ===== 上半身朝哪裡、身體轉向（使用者 2026-10-16 回報：往鏡頭方向跑、身體轉向時上半身轉、下半身沒轉 → 扭曲）=====
// 原版上半身瞄準的點由朝向目標決定（UpdateLookAtTarget：r4Player.ws:2752-2876）；電腦版把「朝角色前方」OT_Player 一律換成「朝鏡頭」OT_Camera（r4Player.ws:5238-5246），
// 附近有敵人時是 OT_Actor（朝滑動目標：:2822-2868）→ 拿 AK 移動時上半身一直朝鏡頭或狼，往鏡頭跑時扭到背後（docs/findings.md §21 只限制了角度）。
// AK 改成：
// - 移動、沒在開槍：上半身朝角色前方（同原版 OT_Player：:2766-2784），不扭
// - 站著、或開槍中：上半身朝準心（Z 鎖定時朝鎖定點）；身體轉向準心（GfgAkTurnTick）

// 開槍中（扣著扳機，或最後一發之後還沒過 GfgAimHoldTime() 秒）
// 3 秒：使用者 2026-10-16 20:4x 回報「按一下開槍，一停火就立刻放下槍」（原本 0.5 秒）；第三人稱射擊遊戲停火後一般維持舉槍 2～3 秒
@addMethod(Crossbow)
function GfgAimHoldTime() : float
{
	return 3.0;
}

@addMethod(Crossbow)
function GfgIsFiring() : bool
{
	return gfgTriggerHeld || theGame.GetEngineTimeAsSeconds() - gfgLastShotTime < GfgAimHoldTime();
}

// 準心指的點：Z 鎖定時是鎖定點（GfgLockPoint），否則從鏡頭沿著畫面中央往前 100 公尺（同原版 OT_Camera：r4Player.ws:2786-2807）
@addMethod(CR4Player)
function GfgCrosshairPoint() : Vector
{
	var point : Vector;

	if ( GfgLockPoint( point ) )
		return point;
	return rangedWeapon.GfgEyePosition() + rangedWeapon.GfgViewDirection() * 100.f;
}

@addMethod(CR4Player)
function GfgAkLookAtPoint() : Vector
{
	var point : Vector;

	if ( !bLAxisReleased && !rangedWeapon.GfgIsFiring() )
	{
		point = GetWorldPosition() + GetHeadingVector() * 30.f;
		point.Z += 1.6f;
		return point;
	}
	return GfgCrosshairPoint();
}

@addField(CR4Player)
var gfgFireMoving : bool;	// 開槍中又在移動：全身瞄準（腳用側移的動作）、身體朝準心

@addField(CR4Player)
var gfgTurning : bool;		// 站著時身體正在轉向準心

@addField(CR4Player)
var gfgWalkInPlace : bool;	// walkInPlace 是我們設的

// 站著時角度差超過幾度才轉身（開槍中小一點）
@addMethod(CR4Player)
function GfgTurnStartAngle( firing : bool ) : float
{
	if ( firing )
		return 30.f;
	return 60.f;
}

// 原地轉身時讓腳踏步：同原版中鍵瞄準（aimThrow.ws:285-289、:295-299、:303）
@addMethod(CR4Player)
function GfgSetWalkInPlace( on : bool )
{
	if ( on )
	{
		SetBehaviorVariable( 'playerSpeedForOverlay', 0.1 );
		SetBehaviorVariable( 'walkInPlace', 1.f );
		gfgWalkInPlace = true;
	}
	else if ( gfgWalkInPlace )
	{
		SetBehaviorVariable( 'walkInPlace', 0.f );
		gfgWalkInPlace = false;
	}
}

// 每格（走路，AK 拿著時）：身體轉向準心
// - 做法同原版中鍵瞄準：角度差超過門檻就用 SetCustomRotation 轉向鏡頭的方向（aimThrow.ws:268-305；SetCustomRotation：r4Player.ws:5086-5105）
// - 開槍中又在移動：一直朝準心，上半身動畫圖改用全身瞄準（ProcessFullBodyAnimWeight 的包裝）→ 腳用側移、後退的動作
//   （上半身動畫圖 #18428 的 DirectionalMovement；原版中鍵瞄準移動時就是全身瞄準：rangedWeapon.ws:968-969）
@addMethod(CR4Player)
function GfgAkTurnTick()
{
	var aimHeading, diff : float;
	var firing, moving, fireMoving : bool;

	aimHeading = VecHeading( GfgCrosshairPoint() - GetWorldPosition() );
	diff = AngleDistance( aimHeading, GetHeading() );
	firing = rangedWeapon.GfgIsFiring();
	moving = !bLAxisReleased;

	fireMoving = firing && moving && !GetIsSprinting() && !IsInAir() && !IsSwimming() && GetCurrentStateName() != 'AimThrow';
	if ( fireMoving != gfgFireMoving )
	{
		gfgFireMoving = fireMoving;
		rangedWeapon.GfgRefreshFullBody();
		// 實驗：上半身動畫圖的全身瞄準狀態機（#18428）從起始狀態直接進入移動的條件要 inAimThrow（#19444、#20031）；原版中鍵瞄準時設定（rangedWeapon.ws:1395-1396）
		SetBehaviorVariable( 'inAimThrowForOverlay', (float)fireMoving );
	}

	if ( fireMoving )
	{
		gfgTurning = false;
		GfgSetWalkInPlace( false );
		SetCustomRotation( 'GfgAkAim', aimHeading, 0.f, 0.25f, false );
		return;
	}
	if ( moving || GetCurrentStateName() == 'AimThrow' )
	{
		gfgTurning = false;
		GfgSetWalkInPlace( false );
		return;
	}
	// 站著：原版門檻是 -50～25 度、回到 -35～5 度以內才停（aimThrow.ws:276-300）；AK 兩手握在身體前方，用左右對稱的值
	if ( AbsF( diff ) > GfgTurnStartAngle( firing ) )
		gfgTurning = true;
	else if ( AbsF( diff ) < 5.f )
		gfgTurning = false;
	if ( gfgTurning )
		SetCustomRotation( 'GfgAkAim', aimHeading, 0.f, 0.4f, false );
	GfgSetWalkInPlace( gfgTurning );
}

// 從玩家這邊要求重算全身／上半身（ProcessFullBodyAnimWeight 是 protected；原版每 0.1 秒由計時器呼叫：rangedWeapon.ws:1285）
@addMethod(Crossbow)
function GfgRefreshFullBody()
{
	ProcessFullBodyAnimWeight();
}

// AK 收起來（或騎馬）時，清掉上面設的狀態
@addMethod(CR4Player)
function GfgAkTurnReset()
{
	if ( gfgFireMoving )
	{
		gfgFireMoving = false;
		if ( rangedWeapon )
			rangedWeapon.GfgRefreshFullBody();
		SetBehaviorVariable( 'inAimThrowForOverlay', 0.f );
	}
	gfgTurning = false;
	GfgSetWalkInPlace( false );
}

// 開槍中又在移動時，上半身動畫圖收到的速度改成要求的速度（同原版中鍵瞄準：locomotionDirectController.ws:316-327）
// 原版平常是實際速度不到 0.5 公尺／秒就給 0（:333-342）：全身瞄準時腳的動作來自上半身動畫圖，速度 0 → 腳不動 → 實際速度一直是 0（docs/findings.md §20 卡住的原因之一）
@wrapMethod(CR4LocomotionPlayerControllerScript)
function UpdateLocomotion()
{
	wrappedMethod();
	if ( player.gfgFireMoving && moveSpeed > 0.f )
		player.SetBehaviorVariable( 'playerSpeedForOverlay', moveSpeed, true );
}

// ===== 跳躍、落地時兩手臂維持持槍（使用者 2026-10-16 回報：跳躍落地後瞬間變回持槍姿勢、不順）=====
// 主動畫圖的衝刺、跳躍、落地沒有十字弩版本（pc_gameplay.w2beh #27906、#19915、#19892：docs/findings.md §17.10）→ 手臂照衝刺、跳躍的動作擺，AK 跟著左手甩；
// 落地後切回有十字弩覆蓋的跑步，手臂一格就跳回持槍。
// 上半身動畫圖的十字弩瞄準區塊有一個手臂覆蓋節點（pc_overlay.w2beh #18505），原本給原版單手十字弩的右手一個姿勢（我們已把它關掉）；
// tools/overlay_patch.py 把它改成「inSlomoForOverlay ≥ 1 時，兩手臂用雙手持槍的姿勢蓋住」（淡入約 0.13 秒、淡出約 0.5 秒）。
// inSlomoForOverlay 是動畫圖宣告了、但原版腳本從不設定、圖裡也沒有節點讀它的變數（docs/m3.md），借來當開關
@addField(CR4Player)
var gfgArmsHold : bool;		// 手臂覆蓋開著（inSlomoForOverlay 是我們設的）

@addMethod(CR4Player)
function GfgArmsHoldTick( akDrawn : bool )
{
	var on : bool;

	on = akDrawn && !IsUsingVehicle() && ( IsInAir() || substateManager.GetStateCur() == 'Land' );	// 衝刺不蓋：手照原版擺（GfgCarryTick）
	if ( on == gfgArmsHold )
		return;
	gfgArmsHold = on;
	SetBehaviorVariable( 'inSlomoForOverlay', (float)on, true );
}

// ===== 衝刺時單手提槍（使用者 2026-10-16：衝刺維持不能開槍、擺手跑步，但擺手時拿槍的姿勢要正確；附圖：AK 直立在背後、槍口朝上）=====
// 衝刺時手臂照原版擺（上面不蓋雙手持槍）。AK 掛在左手 l_weapon；原版擺手時左手從臀部後面甩到胸前，手腕轉一百多度
// （2026-10-16 15:16 遊戲實測），槍跟著手轉就從朝下甩到朝上。
// → 衝刺時把真的 AK 藏起來，改顯示一把「替身」AK，每格掛到左手 slot、帶相對變換（CreateAttachment：entity.ws:342），
//   讓槍「槍口朝前下」（相對玩家），握的點（彈匣前的機匣）在左手掌心。
// 為什麼要替身（2026-10-16 16:1x 遊戲實測）：物品系統把真的 AK 的動畫元件（骨架）直接掛在 l_weapon，
//   AK 實體的 CreateAttachment 只移動實體，模型（蒙皮在 AK 的 handle 骨頭）不動；HasAttachment、HasChildAttachment 都是 false，
//   元件的 SetPosition／SetRotation 也沒作用。自己生成的實體沒有這層掛法，骨架跟著實體走 → 偏移看得到。
// 相對變換的規則（2026-10-16 主控台實驗）：位移在 l_weapon 骨頭座標；角度 = MatrixBuiltRotation 的矩陣，三軸 = AK 的三軸在 l_weapon 座標
// （所以用 MatrixGetRotation 從三軸換角度：math.ws:522）
@addField(CR4Player)
var gfgCarryW : float;		// 0 = 雙手持槍的擺法；1 = 衝刺的提槍（開始、結束時漸變）
@addField(CR4Player)
var gfgCarryOn : bool;		// 現在顯示的是替身
@addField(CR4Player)
var gfgCarryPrevX : Vector;	// 上一格 l_weapon 的三軸（預測下一格的手腕方向用）
@addField(CR4Player)
var gfgCarryPrevY : Vector;
@addField(CR4Player)
var gfgCarryPrevZ : Vector;
@addField(CR4Player)
var gfgCarryPrevOk : bool;
@addField(CR4Player)
var gfgDummy : CEntity;		// 替身 AK（不存檔；換關卡後會不見 → 再生成）
@addField(CR4Player)
var gfgDummyFailed : bool;	// 替身的模板載入失敗：不再每格重試

// 替身：同一個模板（gfg_ak47.w2ent），標籤 gfg_carry_dummy → OnSpawned 不初始化十字弩（下面的包裝）
@addMethod(CR4Player)
function GfgCarrySpawnDummy()
{
	var tmpl : CEntityTemplate;
	var tags : array< name >;

	if ( gfgDummyFailed )
		return;
	tmpl = (CEntityTemplate)LoadResource( "dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47.w2ent", true );
	if ( !tmpl )
	{
		gfgDummyFailed = true;
		LogChannel( 'GFG', "carry dummy template not found" );
		return;
	}
	tags.PushBack( 'gfg_carry_dummy' );
	gfgDummy = theGame.CreateEntity( tmpl, GetWorldPosition(), GetWorldRotation(), true, false, true, PM_DontPersist, tags );
	if ( !gfgDummy )
		return;
	GfgSetMeshVisible( gfgDummy, false );
	gfgDummy.CreateAttachment( this, 'l_weapon' );	// 不帶偏移 = 真的 AK 的位置（換過去時不會跳）
}

// 顯示、藏起 AK（真的 AK、替身）：整個實體，立刻生效（SetHideInGame 的 immediate：entity.ws:241）
// 原本用模型元件的 SetVisible：會淡出、淡入 → 衝刺開始、結束時看得到半透明的槍留在原來的位置約 0.1 秒
// （使用者 2026-10-16 20:4x 回報「衝刺開始和結束都會有個槍的影像殘留」；21:5x 每 35 毫秒連拍確認）
@addMethod(CR4Player)
function GfgSetMeshVisible( ent : CEntity, visible : bool )
{
	ent.SetHideInGame( !visible, true );
}

// 真的 AK：模型和裝好的箭（箭對齊在槍管裡：docs/m3.md；AK 藏起來時箭會露出來）
@addMethod(Crossbow)
function GfgSetCarryShown( shown : bool )
{
	thePlayer.GfgSetMeshVisible( this, shown );
	if ( deployedEnt )
		deployedEnt.SetVisibility( shown );
}

@wrapMethod(RangedWeapon)
function OnSpawned( spawnData : SEntitySpawnData )
{
	if ( HasTag( 'gfg_carry_dummy' ) )
		return true;	// 替身：不初始化（State_WeaponWait 的 OnEnterState 會解除玩家的動作鎖：rangedWeapon.ws）
	return wrappedMethod( spawnData );
}

// 結束：真的 AK 顯示回來，替身藏起來、掛回左手不帶偏移
@addMethod(CR4Player)
function GfgCarryReset()
{
	gfgCarryW = 0.f;
	gfgCarryPrevOk = false;
	if ( gfgCarryOn )
	{
		if ( rangedWeapon )
			rangedWeapon.GfgSetCarryShown( true );
		if ( gfgDummy )
		{
			GfgSetMeshVisible( gfgDummy, false );
			gfgDummy.BreakAttachment();
			gfgDummy.CreateAttachment( this, 'l_weapon' );
		}
	}
	gfgCarryOn = false;
}

@addMethod(CR4Player)
function GfgCarryTick( akDrawn : bool, dt : float )
{
	var want : bool;
	var lw, pm, m : Matrix;
	var lx, ly, lz, px, py, pz, qx, qy, qz : Vector;
	var f0, u0, r0, fw, uw, gf, gu, ft, ut, rt, fl, ul, rl, piv, t : Vector;

	if ( !rangedWeapon || !akDrawn )
	{
		GfgCarryReset();
		return;
	}
	if ( !gfgDummy )
	{
		GfgCarrySpawnDummy();	// 拔槍時先生成（藏著）；這一格不提槍
		return;
	}
	want = !IsUsingVehicle() && GetIsSprinting() && !IsInAir() && substateManager.GetStateCur() != 'Land';
	if ( want )
		gfgCarryW = MinF( 1.f, gfgCarryW + dt / 0.25f );
	else
		gfgCarryW = MaxF( 0.f, gfgCarryW - dt / 0.15f );
	if ( gfgCarryW <= 0.f )
	{
		GfgCarryReset();
		return;
	}

	// 現在的擺法（雙手持槍，l_weapon 座標）：槍管、上方（docs/m3.md「雙手持槍：第 1 步」；tools/aim_delta.py 的 BARREL）
	f0 = VecNormalize( Vector( 0.8033f, 0.2140f, 0.5558f ) );
	u0 = VecNormalize( Vector( 0.02721f, -0.94542f, 0.32472f ) );
	r0 = VecCross( f0, u0 );
	lw = GetBoneWorldMatrixByIndex( GetBoneIndex( 'l_weapon' ) );
	lx = MatrixGetAxisX( lw );
	ly = MatrixGetAxisY( lw );
	lz = MatrixGetAxisZ( lw );
	// 預測下一格的手腕方向：相對變換要到下一格才套到骨頭上，手腕轉得快時槍會落後一格
	// （2026-10-16 15:5x 每格紀錄：不預測時槍管和目標差平均 9.6°、最大 16.6°；預測後平均 2.3°、最大 8.2°）
	// 上一格到這一格的轉動 R = L·L上一格ᵀ，再轉一次
	if ( gfgCarryPrevOk )
	{
		qx = lx * VecDot( gfgCarryPrevX, lx ) + ly * VecDot( gfgCarryPrevY, lx ) + lz * VecDot( gfgCarryPrevZ, lx );
		qy = lx * VecDot( gfgCarryPrevX, ly ) + ly * VecDot( gfgCarryPrevY, ly ) + lz * VecDot( gfgCarryPrevZ, ly );
		qz = lx * VecDot( gfgCarryPrevX, lz ) + ly * VecDot( gfgCarryPrevY, lz ) + lz * VecDot( gfgCarryPrevZ, lz );
	}
	else
	{
		qx = lx;
		qy = ly;
		qz = lz;
	}
	gfgCarryPrevX = lx;
	gfgCarryPrevY = ly;
	gfgCarryPrevZ = lz;
	gfgCarryPrevOk = true;
	lx = qx;
	ly = qy;
	lz = qz;
	// 提槍的方向（玩家座標：x 右、y 前、z 上）：往下 30°、往右 8°（槍托往左後，離開身體）
	pm = GetLocalToWorld();
	px = MatrixGetAxisX( pm );
	py = MatrixGetAxisY( pm );
	pz = MatrixGetAxisZ( pm );
	fw = VecNormalize( px * 0.1205f + py * 0.8576f - pz * 0.5f );
	uw = VecNormalize( pz - fw * VecDot( pz, fw ) );
	// 漸變：從現在跟著手的方向轉到提槍的方向
	gf = lx * f0.X + ly * f0.Y + lz * f0.Z;
	gu = lx * u0.X + ly * u0.Y + lz * u0.Z;
	ft = VecNormalize( gf * ( 1.f - gfgCarryW ) + fw * gfgCarryW );
	ut = gu * ( 1.f - gfgCarryW ) + uw * gfgCarryW;
	ut = VecNormalize( ut - ft * VecDot( ut, ft ) );
	rt = VecCross( ft, ut );
	// 換到 l_weapon 座標
	fl = Vector( VecDot( ft, lx ), VecDot( ft, ly ), VecDot( ft, lz ) );
	ul = Vector( VecDot( ut, lx ), VecDot( ut, ly ), VecDot( ut, lz ) );
	rl = Vector( VecDot( rt, lx ), VecDot( rt, ly ), VecDot( rt, lz ) );
	// 相對旋轉：把 (f0, u0, r0) 轉到 (fl, ul, rl)；每一軸 = 三個方向照 e_i 的分量加起來（= AK 的三軸在 l_weapon 座標）
	m.X = fl * f0.X + ul * u0.X + rl * r0.X;
	m.Y = fl * f0.Y + ul * u0.Y + rl * r0.Y;
	m.Z = fl * f0.Z + ul * u0.Z + rl * r0.Z;
	m.X.W = 0.f;
	m.Y.W = 0.f;
	m.Z.W = 0.f;
	m.W = Vector( 0.f, 0.f, 0.f, 1.f );
	// 握的點：雙手持槍時左掌在護木（l_weapon 原點）；提槍時在彈匣前的機匣（右手握把往前 12、往上 5 公分）→ 漸變
	piv = ( Vector( -0.3032f, -0.0115f, -0.2320f ) + f0 * 0.12f + u0 * 0.05f ) * gfgCarryW;
	t = ( m.X * piv.X + m.Y * piv.Y + m.Z * piv.Z ) * -1.f;
	t.W = 1.f;
	gfgDummy.BreakAttachment();
	gfgDummy.CreateAttachment( this, 'l_weapon', t, MatrixGetRotation( m ) );
	// 每格都藏：原版換彈事件會把箭設回顯示（rangedWeapon.ws:745-748）
	rangedWeapon.GfgSetCarryShown( false );
	if ( !gfgCarryOn )
		GfgSetMeshVisible( gfgDummy, true );
	gfgCarryOn = true;
}

// ===== 滑動目標：死掉的不留著（使用者 2026-10-16 回報：打完狼群有時 Geralt 一直面向最後殺死的狼，血條（血 0）一直顯示，按 Z 也解不掉）=====
// 原版拿著十字弩、沒在中鍵瞄準時，畫面目標（血條）＝滑動目標 slideTarget（r4Player.ws:6749-6753），
// 朝向目標是 OT_Actor 時上半身瞄它（:2822-2868）、身體轉向它（MovAdjRotateToTarget：:2712-2718）。
// 原版的十字弩射完會收起，收起後清掉滑動目標（OnCombatActionEndComplete：r4Player.ws:13380-13385）；AK 一直拿著 → 死掉的目標一直留著。
// Z 只在「有威脅或鎖定中」才有作用（playerInput.ws:3497-3525），這時兩者都不是 → 按 Z 沒反應
@addMethod(CR4Player)
function GfgClearDeadSlideTarget()
{
	var actor : CActor;

	if ( !slideTarget )
		return;
	actor = (CActor)slideTarget;
	if ( actor && ( !actor.IsAlive() || actor.IsKnockedUnconscious() || !actor.GetGameplayVisibility() ) )
		SetSlideTarget( NULL );
}

// 扳機按住時，條件符合、而且到了下一發的時間就開一槍
// 直接觸發射擊，不等動畫事件（CCO 的作法，docs/findings.md §8.1）
@addMethod(Crossbow)
function GfgTryFire()
{
	var now : float;
	var lastCheck : float;

	// 每次檢查都記下時間（包括還不能開火的時候）
	now = theGame.GetEngineTimeAsSeconds();
	lastCheck = gfgLastCheckTime;
	gfgLastCheckTime = now;

	if ( !gfgTriggerHeld )
		return;

	// 還沒拿出來（拿出中由原版流程處理）
	if ( GetCurrentStateName() == 'State_WeaponWait' || GetCurrentStateName() == 'State_WeaponHolster' )
		return;

	// 換彈中不開火：換彈動畫中段就裝上新箭（rangedWeapon.ws:150-152、338-363），
	// 換彈結束才把 shotCount 歸零（rangedWeapon.ws:697-703）；中間開火會打斷換彈
	if ( GetCurrentStateName() == 'State_WeaponReload' )
		return;

	// 沒有裝好的箭：拿出或換彈中
	if ( !deployedEnt )
		return;

	// 衝刺中、在空中（跳躍等）不開火，手維持原本的動作（使用者 2026-10-13 選定；docs/findings.md §17.10、§17.11）：
	// 主動畫的衝刺、跳躍沒有十字弩版本（pc_gameplay.w2beh #27906、#19915），舉不了槍。
	// 扳機狀態保留：衝刺結束、落地時還按著就接著射
	// 騎馬時不看：騎馬用的是另一張動畫圖（pc_rider.w2beh，docs/findings.md §24）
	if ( !ownerPlayer.IsUsingVehicle() && ( ownerPlayer.GetIsSprinting() || ownerPlayer.IsInAir() ) )
		return;

	// 騎馬瞄準超出左右範圍（第 18 項：GfgClampHorseAim）：槍沒對著準心，不開火；扳機狀態保留，回到範圍內還按著就接著射
	if ( ownerPlayer.IsUsingVehicle() && ownerPlayer.gfgHorseAimOut )
		return;

	// 射速：下一發的時間由上一發的預定時間累加，不從實際開火的那一格畫面起算
	// （從實際時間起算，實測只有 540 RPM：docs/findings.md §13.13）
	if ( now < gfgNextShotTime )
		return;
	// 以下情況從現在起算，只補償「對齊畫面」造成的延遲：
	// - 上一次檢查時就到了預定時間，卻不能開火（換彈、拿出中）；不重算的話下一發會提早（實測 0.066 秒：docs/findings.md §13.17）
	// - 落後超過一個間隔（中間停過）
	if ( gfgNextShotTime <= lastCheck || now - gfgNextShotTime >= GfgCycleTime() )
		gfgNextShotTime = now;
	gfgNextShotTime += GfgCycleTime();

	// 連射時不收槍
	GfgCancelAutoHolster();

	OnProcessThrowEvent( 'ProjectileThrow' );

	// 槍口火光（第 10 項）
	thePlayer.GfgMuzzleFlash();

	// 後座力：這一發開完，鏡頭開始轉向下一發的位置（之後每格轉一部分：GfgUpdateRecoil）
	GfgAddRecoil( now );

	// 散布：這一發開完，開火累積量增加（之後每格衰減：GfgDecaySpread）；先算散布再累積，同 CSGODOT weapon.gd:703、:738-742
	gfgSpreadPenalty += GfgSpreadPerShot();

	// 彈匣打空（PlayOwnerReloadAnim 回傳 true，不會立刻裝箭）：觸發換彈動畫，同 rangedWeapon.ws:1690-1691
	if ( !deployedEnt )
		RaiseOwnerGraphEvents( 'Crossbow_Reload', true );
}

// 目前選用的物品若是 AK，回傳它的物件（同 r4Player.ws:10712 的取法）
@addMethod(CPlayerInput)
function GfgSelectedAk() : Crossbow
{
	var id : SItemUniqueId;

	id = thePlayer.GetSelectedItemId();
	if ( !thePlayer.inv.IsIdValid( id ) || !thePlayer.inv.ItemHasTag( id, 'gfg_ak47' ) )
		return NULL;
	return (Crossbow)thePlayer.inv.GetItemEntityUnsafe( id );
}

// 左鍵（輕攻擊，input_qwerty.ini:656）：AK 選用時改成扳機
@wrapMethod(CPlayerInput)
function OnCbtAttackWithAlternateLight( action : SInputAction )
{
	var ak : Crossbow;

	ak = GfgSelectedAk();
	if ( !ak )
		return wrappedMethod( action );

	if ( IsPressed( action ) )
	{
		thePlayer.GfgSetTriggerWanted( true );
		// 手上有劍：先收劍、收好再拿出 AK（GfgNoSwordTick）；直接拿出會變成單手拿 AK（第 19 項）
		if ( thePlayer.GfgSwordInHand() && !thePlayer.IsCrossbowHeld() )
		{
			thePlayer.GfgRequestAkRaise( true );
			return true;
		}
		// 還沒拿出來：照原版中鍵按下的流程拿出十字弩（playerInput.ws:3185-3204）
		if ( !thePlayer.IsCrossbowHeld() && IsActionAllowed( EIAB_Crossbow ) )
		{
			thePlayer.SetIsAimingCrossbow( true );
			thePlayer.SetupCombatAction( EBAT_ItemUse, BS_Pressed );
		}
		ak.GfgSetTrigger( true );
	}
	else if ( IsReleased( action ) )
	{
		thePlayer.GfgSetTriggerWanted( false );
		ak.GfgSetTrigger( false );
	}
	return true;
}

// 按住左鍵 0.2 秒的特殊攻擊（input_qwerty.ini:674）：AK 選用時不放劍招
@wrapMethod(CPlayerInput)
function OnCbtSpecialAttackWithAlternateLight( action : SInputAction )
{
	if ( GfgSelectedAk() )
		return true;
	return wrappedMethod( action );
}

// 主動收槍：C 鍵（原版「收武器」SwordSheathe：legacy\base\input_qwerty.ini:709-715；處理：playerInput.ws:1197-1220）（使用者 2026-10-14 選定）
// 拿著 AK 時先收起 AK，走原版收十字弩的流程（同原版潛水時：playerInput.ws:1823、:1837 → r4Player.ws:14764-14765 → Crossbow.OnForceHolster：rangedWeapon.ws:713-727）；
// 之後照原版處理收劍。按住 1／2 收劍（OnCommSheatheSteel／Silver）也會呼叫到這裡（playerInput.ws:1240、:1263）
@wrapMethod(CPlayerInput)
function OnCommSheatheAny( action : SInputAction )
{
	if ( IsPressed( action ) && thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsAkDrawn() )
		thePlayer.OnRangedForceHolster( true, false );
	return wrappedMethod( action );
}

// ===== 衝刺：拿著 AK 可以衝刺、邊衝刺邊開槍（使用者 2026-10-13 選定；docs/findings.md §17.2）=====

// 原版規定十字弩拿在手上就不能衝刺，戰鬥中按衝刺會收槍（playerWitcher.ws:10701-10710）
// AK 的衝刺條件改成和沒拿十字弩時一樣：呼叫原版時暫時把 rangedWeapon 設成空的。
// 原版判斷衝刺時用到 rangedWeapon 的只有上面那段和 IsGuarded（r4Player.ws:13949-13952）
// （不用 super.CanSprint：官方文件沒寫 annotation 裡能不能用 super，Wiki 頁面 36241598）
// （wrappedMethod 在同一個函式裡只能寫一次，第二次會編譯錯誤：docs/findings.md §17.6）
@wrapMethod(W3PlayerWitcher)
function CanSprint( speed : float ) : bool
{
	var weapon : Crossbow;
	var isAk, result : bool;

	weapon = rangedWeapon;
	isAk = weapon && weapon.GfgIsAk();
	if ( isAk )
		rangedWeapon = NULL;
	result = wrappedMethod( speed );
	if ( isAk )
		rangedWeapon = weapon;
	return result;
}

// 按衝刺鍵時，原版在探索狀態會收起十字弩（rangedWeapon.ws:491-507；呼叫處 playerInput.ws:607-610、:629-630）；AK 不收
@wrapMethod(RangedWeapon)
function OnSprintHolster()
{
	var crossbow : Crossbow;

	crossbow = (Crossbow)this;
	if ( crossbow && crossbow.GfgIsAk() )
		return;
	wrappedMethod();
}

// 戰鬥中衝刺時，原版不拿出十字弩（rangedWeapon.ws:800-806）；AK 照常拿出
// 只處理沒騎乘的情況（騎乘時原版會換成載具用的事件名稱：:808-823）；送出事件的寫法同 rangedWeapon.ws:328-334
@wrapMethod(Crossbow)
function RaiseOwnerGraphEvents( eventName : name, force : bool ) : bool
{
	if ( eventName == 'Crossbow_Draw' && GfgIsAk() && !ownerPlayer.IsUsingVehicle() )
	{
		if ( force )
			return ownerPlayer.RaiseForceEvent( eventName );
		return ownerPlayer.RaiseEvent( eventName );
	}
	return wrappedMethod( eventName, force );
}

// ===== 跳躍：起跳時不收 AK，扳機狀態保留到落地（使用者 2026-10-13 選定；docs/findings.md §17.4、§17.7、§17.11）=====
// 空中不開火（GfgTryFire）；按鍵情境不切換，扳機才不會在起跳時被放開，落地時還按著就接著射

// 跳躍的這幾個狀態原版會把按鍵情境切到 JumpClimb：沒有左鍵，切換的那一格扳機就被放開（§17.7）。
// 拿著 AK 時改成維持平常的探索情境，空中也能按、放左鍵（扳機狀態跟著變）；副作用：E、R 等探索情境的鍵在空中也有作用。
// 按鍵情境在狀態進入之後才切換（explorationStateManager.ws:1398-1422 → :1448-1464），所以在進入時改
@wrapMethod(CExplorationStateAbstract)
function StateEnter( prevStateName : name )
{
	var stateName : name;

	stateName = GetStateName();
	if ( stateName == 'Jump' || stateName == 'Land' || stateName == 'AirCollision' || stateName == 'IdleJump' )
	{
		if ( thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsAkDrawn() )
			m_InputContextE = EGCI_Exploration;
		else
			// 原版的設定：explorationStateJump.ws:255、explorationStateLand.ws:119、explorationStateAirCollision.ws:79、explorationStateIdleJump.ws:29
			m_InputContextE = EGCI_JumpClimb;
	}
	wrappedMethod( prevStateName );
}

@addField(CR4Player)
var gfgKeepAkOnJump : bool;		// 起跳的這段程式執行中為 true：OnRangedForceHolster 不收 AK

// 從其他類別不能直接寫入這個欄位（wcc_lite：Left hand side is const），所以用函式設定
@addMethod(CR4Player)
function GfgSetKeepAkOnJump( keep : bool )
{
	gfgKeepAkOnJump = keep;
}

// 起跳時原版強制收起十字弩（explorationStateJump.ws:408）
// 跳進水裡照原版收槍（:822-842）：游泳時十字弩拿在手上就不能移動（locomotionDirectController.ws:817-825）
@wrapMethod(CExplorationStateJump)
function StateEnterSpecific( prevStateName : name )
{
	thePlayer.GfgSetKeepAkOnJump( thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsAkDrawn() );
	wrappedMethod( prevStateName );
	thePlayer.GfgSetKeepAkOnJump( false );

	if ( m_JumpParmsS.m_JumpTypeE == EJT_ToWater && thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsAkDrawn() )
		thePlayer.OnRangedForceHolster( true, true );
}

@wrapMethod(CR4Player)
function OnRangedForceHolster( optional forceUpperBodyAnim, instant, dropItem : bool )
{
	if ( rangedWeapon && rangedWeapon.GfgIsAkDrawn() )	// 暫時：查被狼咬時是誰收槍（第 2 項）
		LogChannel( 'GFG', "rangedForceHolster instant=" + instant + " upper=" + forceUpperBodyAnim + " inHitStart=" + gfgInHitStart
			+ " pstate=" + GetCurrentStateName() + " hitAnim=" + IsInHitAnim() );
	if ( gfgKeepAkOnJump )
		return true;
	// 被打中時不收 AK（下面「戰鬥中被打中」那一段）
	if ( gfgInHitStart && rangedWeapon && rangedWeapon.GfgIsAkDrawn() )
		return true;
	return wrappedMethod( forceUpperBodyAnim, instant, dropItem );
}

// ===== 戰鬥中被打中不收 AK（使用者 2026-10-16 回報：狼群裡開槍時變成戰鬥準備的姿勢，不是射擊的姿勢）=====
// 2026-10-16 實測（關掉無敵、被狼咬）：被打中後 AK 被收起又拔出
// 被打中的動作開始：OnHitStart → WhenCombatActionIsFinished → 強制收起十字弩（r4Player.ws:13202-13209、:12843-12858）→ OnRangedForceHolster 的包裝不收
// （自動拔劍：下一段）

@addField(CR4Player)
var gfgInHitStart : bool;		// 被打中的動作開始的程式執行中

@wrapMethod(CR4Player)
function OnHitStart()
{
	var result : bool;

	gfgInHitStart = true;
	result = wrappedMethod();
	gfgInHitStart = false;
	return result;
}

// ===== AK 是選用物品時不准拿劍；原版要自動拔劍的時候，改成舉 AK（第 19 項，使用者 2026-10-17）=====
// 使用者回報：spawn('wolf', 30, 30, true)，還沒拿出 AK 就走進狼群 → 原版自動拔劍；拿著劍按射擊 → 變成單手拿 AK、AK 可能看不到、不能射擊
//   「強制裝上 AK 的情況下，不准拿劍，進到狼群或戰鬥，要自動做的事情是舉槍」
// 原版自動拔劍的地方都先問「最適合的劍」（WeaponHolster.GetMostConvenientMeleeWeapon：playerWeaponHolster.ws:175-283）：
// - 進入戰鬥、目標有敵意（OnCombatStart：r4Player.ws:2156-2162）；騎馬時另外經騎馬戰鬥管理拔劍（horseRiding.ws:201-242 → useVehicle.ws:786-823）
// - 被目前的目標打中（OnReactToBeingHit：r4Player.ws:2234-2239）
// - 附近有敵人、進入戰鬥模式（playerMode.ws:211-220 → GoToCombatIfNeeded：r4Player.ws:3300-3335 → GoToCombat → CombatSteel 狀態一進入就拔劍：combatSteel.ws:31-33）
// - 拿出十字弩時（State_WeaponDraw：rangedWeapon.ws:1140 → GoToCombatIfNeeded）；下馬時（dismountHorse.ws:217-218）
// → 不准拿劍的模式（GfgNoSwordMode）回答「空手」（PW_Fists：戰鬥狀態是 CombatFists，同第 2 項實測時拿著 AK 的狀態），並記下「要舉 AK」（GfgNoSwordTick 找時機拿出）
// 直接拔劍（1／2 鍵：r4Player.ws:10829-10883、騎馬戰鬥管理：useVehicle.ws:801-821、任務等）：OnEquipMeleeWeapon 的包裝擋掉；收劍照原版
// 手上已經有劍（選 AK 之前就拔了）：每格檢查，先收劍（戰鬥中換成空手，同原版收劍：playerWeaponHolster.ws:572-583），收好才拿出 AK
//   拿著劍直接拿出十字弩：十字弩在左手、劍留在右手（原版的單手十字弩）→ 雙手持槍的動畫對不上（使用者看到的單手拿 AK）

@addField(CR4Player)
var gfgAkRaiseWanted : bool;	// 要舉 AK：原版想拔劍、或拿著劍時按了左鍵
@addField(CR4Player)
var gfgAkRaiseTime : float;		// 要舉 AK 的時間（引擎時間，秒）：5 秒內舉不起來就算了
@addField(CR4Player)
var gfgAkRaiseManual : bool;	// 是按左鍵要的：不在戰鬥中也舉
@addField(CR4Player)
var gfgTriggerWanted : bool;	// 地面的左鍵按著（OnCbtAttackWithAlternateLight）：拿著劍時按下，收好劍、拿出 AK 後接著扣扳機

// 不准拿劍的模式：AK 是選用物品（左鍵＝扳機），或 AK 拿在手上
@addMethod(CR4Player)
function GfgNoSwordMode() : bool
{
	var id : SItemUniqueId;

	if ( rangedWeapon && rangedWeapon.GfgIsAkDrawn() )
		return true;
	id = GetSelectedItemId();
	return inv.IsIdValid( id ) && inv.ItemHasTag( id, 'gfg_ak47' );
}

// 手上有劍：目前的武器（拔劍一開始就設好：playerWeaponHolster.ws:601），或劍還在手上（收劍到收好才離手）
@addMethod(CR4Player)
function GfgSwordInHand() : bool
{
	var weapon : EPlayerWeapon;

	weapon = GetCurrentMeleeWeaponType();
	return weapon == PW_Steel || weapon == PW_Silver || IsWeaponHeld( 'steelsword' ) || IsWeaponHeld( 'silversword' );
}

@addMethod(CR4Player)
function GfgRequestAkRaise( manual : bool )
{
	if ( !gfgAkRaiseWanted )
		gfgAkRaiseManual = false;
	gfgAkRaiseWanted = true;
	gfgAkRaiseManual = gfgAkRaiseManual || manual;
	gfgAkRaiseTime = theGame.GetEngineTimeAsSeconds();
}

@addMethod(CR4Player)
function GfgSetTriggerWanted( pressed : bool )
{
	gfgTriggerWanted = pressed;
}

@wrapMethod(WeaponHolster)
function GetMostConvenientMeleeWeapon( targetToDrawAgainst : CActor, optional ignoreActionLock : bool ) : EPlayerWeapon
{
	var ret : EPlayerWeapon;

	ret = wrappedMethod( targetToDrawAgainst, ignoreActionLock );
	if ( ( ret == PW_Steel || ret == PW_Silver ) && thePlayer.GfgNoSwordMode() )
	{
		thePlayer.GfgRequestAkRaise( false );
		return PW_Fists;
	}
	return ret;
}

@wrapMethod(CR4Player)
function OnEquipMeleeWeapon( weaponType : EPlayerWeapon, ignoreActionLock : bool, optional sheatheIfAlreadyEquipped : bool )
{
	// 拿著同一把時再要一次＝收劍（sheatheIfAlreadyEquipped：playerWeaponHolster.ws:568-583），照原版
	if ( ( weaponType == PW_Steel || weaponType == PW_Silver ) && GfgNoSwordMode() && !gfgSwordTestBypass
		&& !( sheatheIfAlreadyEquipped && GetCurrentMeleeWeaponType() == weaponType ) )
	{
		LogChannel( 'GFG', "sword draw blocked weapon=" + (int)weaponType + " ignoreLock=" + ignoreActionLock + " pstate=" + GetCurrentStateName() );	// 暫時（第 19 項）
		return true;
	}
	return wrappedMethod( weaponType, ignoreActionLock, sheatheIfAlreadyEquipped );
}

// 暫時（第 19 項的測試）：不管 AK，直接拔鋼劍 → 測「手上有劍時」：每格收劍、戰鬥中接著舉 AK；拔劍中按左鍵
@addField(CR4Player)
var gfgSwordTestBypass : bool;

@addField(CR4Player)
var gfgSwordDiagTime : float;	// 暫時

@addMethod(CR4Player)
function GfgDrawSwordForTest()
{
	gfgSwordTestBypass = true;
	OnEquipMeleeWeapon( PW_Steel, true );
	gfgSwordTestBypass = false;
}

exec function gfgsword()
{
	thePlayer.GfgDrawSwordForTest();
}

// 每格（GfgCameraTick）：手上有劍就收；要舉 AK 時找時機拿出
@addMethod(CR4Player)
function GfgNoSwordTick()
{
	var weapon : EPlayerWeapon;
	var now : float;

	if ( !GfgNoSwordMode() )
	{
		gfgAkRaiseWanted = false;
		return;
	}

	// 手上有劍：收劍。拔劍、收劍的動作還沒做完、戰鬥動作中、不能拔收劍時先等（同原版自動收劍的條件：r4Player.ws:3195）；對話中不動（playerWeaponHolster.ws:551-554）
	weapon = GetCurrentMeleeWeaponType();
	if ( weapon == PW_Steel || weapon == PW_Silver )
	{
		if ( GetWeaponHolster().IsMeleeWeaponReady() && !IsInCombatAction() && IsActionAllowed( EIAB_DrawWeapon ) && GetCurrentStateName() != 'PlayerDialogScene' )
		{
			LogChannel( 'GFG', "sheathe sword for AK weapon=" + (int)weapon + " combat=" + IsInCombat() );	// 暫時（第 19 項）
			if ( IsInCombat() )
			{
				OnEquipMeleeWeapon( PW_Fists, true );
				GfgRequestAkRaise( false );
			}
			else
				OnEquipMeleeWeapon( PW_None, true );
		}
		else if ( theGame.GetEngineTimeAsSeconds() - gfgSwordDiagTime > 1.f )	// 暫時（第 19 項）：收不了劍的原因
		{
			gfgSwordDiagTime = theGame.GetEngineTimeAsSeconds();
			LogChannel( 'GFG', "sword wait ready=" + GetWeaponHolster().IsMeleeWeaponReady() + " inCA=" + IsInCombatAction()
				+ " drawAllowed=" + IsActionAllowed( EIAB_DrawWeapon ) + " held=" + IsWeaponHeld( 'steelsword' ) + " pstate=" + GetCurrentStateName()
				+ " holsterState=" + GetWeaponHolster().GetCurrentStateName() );
		}
		return;
	}

	if ( !gfgAkRaiseWanted )
		return;
	now = theGame.GetEngineTimeAsSeconds();
	// 已經拿著（或拿出中）、5 秒內舉不起來、不在戰鬥中（按左鍵要的除外）：不舉
	// （戰鬥中按 C 收起 AK，原版要拔劍的程式一呼叫就會再舉起來：同原版戰鬥中收劍會馬上再拔，r4Player.ws:3178-3189、playerWeaponHolster.ws:531-534）
	if ( IsCrossbowHeld() || now - gfgAkRaiseTime > 5.f || ( !gfgAkRaiseManual && !IsInCombat() ) )
	{
		gfgAkRaiseWanted = false;
		return;
	}
	if ( now - gfgSwordDiagTime > 0.5f )	// 暫時（第 19 項）：舉不起來的原因
	{
		gfgSwordDiagTime = now;
		LogChannel( 'GFG', "raise wait ready=" + GetWeaponHolster().IsMeleeWeaponReady() + " xbowAllowed=" + IsActionAllowed( EIAB_Crossbow )
			+ " air=" + IsInAir() + " pstate=" + GetCurrentStateName() + " vehicle=" + IsUsingVehicle() + " caAllowed=" + GetBIsCombatActionAllowed()
			+ " mgr=" + GfgHorseMgrState() );
	}
	// 劍還沒收好、不能用十字弩、在空中、游泳、在船上：等
	if ( !GetWeaponHolster().IsMeleeWeaponReady() || IsWeaponHeld( 'steelsword' ) || IsWeaponHeld( 'silversword' ) )
		return;
	if ( !IsActionAllowed( EIAB_Crossbow ) || IsInAir() || IsSwimming() || IsUsingBoat() )
		return;
	// 只在一般的走路、戰鬥、騎馬狀態舉（上下馬、互動、對話等狀態中不舉）；騎馬時騎馬戰鬥管理要在閒置（同騎馬按左鍵拿出：StartAttackAction 的包裝）
	// 騎馬的戰鬥管理是 W3HorseCombatManager，閒置狀態叫 HorseNull（繼承 Null：horseRiding.ws:886-889）
	if ( IsUsingVehicle() )
	{
		if ( GetCurrentStateName() != 'HorseRiding' || ( GfgHorseMgrState() != 'HorseNull' && GfgHorseMgrState() != 'Null' ) )
			return;
	}
	else
	{
		if ( GetCurrentStateName() != 'Exploration' && GetCurrentStateName() != 'CombatFists' && GetCurrentStateName() != 'CombatSteel' && GetCurrentStateName() != 'CombatSilver' )
			return;
		if ( !GetBIsCombatActionAllowed() )
			return;
	}
	// 上一次試過還不到 1 秒：等（拿不出來時不要每格一直送）
	if ( now - gfgAkRaiseTryTime < 1.f )
		return;
	gfgAkRaiseTryTime = now;
	GfgRaiseAk();
}

@addField(CR4Player)
var gfgAkRaiseTryTime : float;	// 上一次試著舉 AK 的時間（引擎時間，秒）

// 騎馬戰鬥管理的狀態（沒騎馬：none）
@addMethod(CR4Player)
function GfgHorseMgrState() : name
{
	if ( !GetUsedHorseComponent() || !GetUsedHorseComponent().GetUserCombatManager() )
		return 'none';
	return GetUsedHorseComponent().GetUserCombatManager().GetCurrentStateName();
}

// 拿出 AK（不開火；左鍵還按著就接著扣扳機）
@addMethod(CR4Player)
function GfgRaiseAk()
{
	var ak : Crossbow;

	gfgAkRaiseWanted = false;
	ak = (Crossbow)inv.GetItemEntityUnsafe( GetSelectedItemId() );
	if ( !ak )
		return;
	LogChannel( 'GFG', "raise AK manual=" + gfgAkRaiseManual + " trigger=" + gfgTriggerWanted + " combat=" + IsInCombat()
		+ " vehicle=" + IsUsingVehicle() + " pstate=" + GetCurrentStateName() );	// 暫時（第 19 項）
	if ( IsUsingVehicle() )
	{
		// 騎馬：同騎馬按左鍵拿出（W3VehicleCombatManagerStateNull.StartAttackAction 的包裝）；扳機由 GfgHorseTick 每格跟著左鍵
		SetBehaviorVariable( 'actionType', (int)EHCA_ShootCrossbow );
		rangedWeapon = ak;
		ak.OnRangedWeaponPress();
		return;
	}
	// 地面：同按下左鍵（OnCbtAttackWithAlternateLight 的包裝）；左鍵沒按著就當作立刻放開（只拿出、不開火）
	SetIsAimingCrossbow( true );
	SetupCombatAction( EBAT_ItemUse, BS_Pressed );
	ak.GfgSetTrigger( gfgTriggerWanted );
}

// ===== 後座力：鏡頭照 AK-47 的彈道轉動，準心固定在畫面中央，子彈飛向準心，停火後鏡頭轉回原位（M2）=====
// 使用者 2026-10-13 改定：鏡頭要動（像 GTA5），但不能一頓一頓的；準心要一直在，不能因為射擊而消失（CLAUDE.md §7）
// 彈道數據：data/recoil/ak47_artanis-rcs.csv（Artanis-RCS，MIT），換算見 data/recoil/README.md、docs/findings.md §14.3
// 標「推測」的數值，是使用者 2026-10-13 同意可以推測的部分（CLAUDE.md §9），遊戲裡再調

@addField(Crossbow)
var gfgBurstShots : int;		// 這一輪連射已經開了幾發

@addField(Crossbow)
var gfgLastShotTime : float;	// 上一發的時間（引擎時間，秒）

@addField(Crossbow)
var gfgRecoilUp : float;		// 後座力目前讓鏡頭往上轉了幾度（已經轉到鏡頭上的部分）

@addField(Crossbow)
var gfgRecoilRight : float;		// 後座力目前讓鏡頭往右轉了幾度

@addField(Crossbow)
var gfgKickUp : float;			// 開火的後座力還沒轉完的部分：往上（度）

@addField(Crossbow)
var gfgKickRight : float;		// 開火的後座力還沒轉完的部分：往右（度）

@addField(Crossbow)
var gfgKickTimeLeft : float;	// 還有幾秒要轉完 gfgKickUp／gfgKickRight

// 整體大小的倍率：1 = 往上最多 11.7°（Artanis-RCS 的換算）；CSGODOT 假設的 16° 約為 1.36（推測）
@addMethod(Crossbow)
function GfgRecoilScale() : float
{
	return 1.0;
}

// 停火超過這個時間，下一發從彈道第一發重新開始：借用 CS2 的 m_flRecoveryTimeStand（data/cs2/weapons.vdata:13271）（推測）
@addMethod(Crossbow)
function GfgRecoilResetTime() : float
{
	return 0.368;
}

// 每發的後座力花幾秒轉完（可調）
// - 在開火那一格一次轉完，兩發之間鏡頭完全不動，看起來一頓一頓的（docs/findings.md §14.4）
// - 等於射擊間隔：連射時上一發剛轉完、下一發接著轉，鏡頭不會停下來（遊戲外模擬：docs/findings.md §14.6）
@addMethod(Crossbow)
function GfgKickTime() : float
{
	return GfgCycleTime();
}

// 射程：瞄準射線的長度，也是箭的飛行距離；CS2 m_flRange 8192 單位 ≈ 208 公尺（docs/ak47_params.md §6）
@addMethod(Crossbow)
function GfgRange() : float
{
	return 208.0;
}

// 開完一發：記下這一發的後座力，之後每格畫面轉一部分到鏡頭上（GfgUpdateRecoil）
@addMethod(Crossbow)
function GfgAddRecoil( now : float )
{
	if ( now - gfgLastShotTime >= GfgRecoilResetTime() )
		gfgBurstShots = 0;
	gfgBurstShots += 1;
	gfgLastShotTime = now;

	// 上一發還沒轉完的部分一起轉，重新計時
	gfgKickUp += GfgRecoilKickUp( gfgBurstShots ) * GfgRecoilScale();
	gfgKickRight += GfgRecoilKickRight( gfgBurstShots ) * GfgRecoilScale();
	gfgKickTimeLeft = GfgKickTime();
}

// 每格畫面（由玩家的鏡頭更新呼叫）：算出這一格鏡頭要往上、往右轉幾度
@addMethod(Crossbow)
function GfgUpdateRecoil( dt : float, out stepUp : float, out stepRight : float )
{
	var frac, mag, newMag, keep : float;

	stepUp = 0.f;
	stepRight = 0.f;

	// 開火的後座力：在剩下的時間內等速轉完（每格轉「dt ÷ 剩下的時間」的比例）
	if ( gfgKickTimeLeft > 0.f )
	{
		frac = MinF( 1.f, dt / gfgKickTimeLeft );
		stepUp = gfgKickUp * frac;
		stepRight = gfgKickRight * frac;
		gfgKickUp -= stepUp;
		gfgKickRight -= stepRight;
		gfgKickTimeLeft -= dt;
		gfgRecoilUp += stepUp;
		gfgRecoilRight += stepRight;
	}

	// 停火後轉回原位：CS:GO 的 weapon_recoil_decay2_exp 8、weapon_recoil_decay2_lin 18（totalcsgo.com）。
	// 公式沒有公開；推測為「先按比例衰減，再每秒減 18°」
	if ( !gfgTriggerHeld || theGame.GetEngineTimeAsSeconds() - gfgLastShotTime > GfgCycleTime() * 1.5 )
	{
		mag = SqrtF( gfgRecoilUp * gfgRecoilUp + gfgRecoilRight * gfgRecoilRight );
		if ( mag > 0.f )
		{
			newMag = MaxF( 0.f, mag * ExpF( -8.f * dt ) - 18.f * dt );
			keep = newMag / mag;
			stepUp -= gfgRecoilUp * ( 1.f - keep );
			stepRight -= gfgRecoilRight * ( 1.f - keep );
			gfgRecoilUp *= keep;
			gfgRecoilRight *= keep;
		}
	}

	GfgDecaySpread( dt );
}

// AK 是不是拿在手上（裝備中，而且不是收起、收槍中）
@addMethod(Crossbow)
function GfgIsAkDrawn() : bool
{
	return GfgIsAk() && GetCurrentStateName() != 'State_WeaponWait' && GetCurrentStateName() != 'State_WeaponHolster';
}

// 畫面上正在用的鏡頭：取法同原版拍照模式（photomodeManager.ws:96-99：GetTopmostCamera，位置加上 GetCameraWorldOffset；customCamera.ws:110-112）
// - 騎馬時用的是另一台鏡頭（r4Game.ws:83 ActivateHorseCamera）；theGame.GetGameCamera()（r4Game.ws:261，走路用的那台）騎馬時停住不動，
//   用它算的子彈會飛到畫面外（docs/findings.md §24.6）
// - 不用 theCamera 的 GetCameraPosition／Direction：2026-10-13 實測，用它的位置與方向投影出的畫面中央不是 (0,0)（docs/findings.md §14.5）
@addMethod(Crossbow)
function GfgCamera() : CCustomCamera
{
	var cam : CCustomCamera;

	// 暫時：gfgview 看的時候畫面是拍照模式的鏡頭，瞄準照樣用遊戲鏡頭
	if ( ownerPlayer && ownerPlayer.gfgViewOn && ownerPlayer.gfgViewPrevCam )
		return ownerPlayer.gfgViewPrevCam;
	cam = theGame.GetWorld().GetCameraDirector().GetTopmostCamera();
	if ( !cam )
		cam = theGame.GetGameCamera();
	return cam;
}

@addMethod(Crossbow)
function GfgEyePosition() : Vector
{
	var cam : CCustomCamera;

	cam = GfgCamera();
	return cam.GetCameraWorldPosition() + cam.GetCameraWorldOffset();
}

@addMethod(Crossbow)
function GfgViewDirection() : Vector
{
	return VecNormalize( RotForward( GfgCamera().GetCameraWorldRotation() ) );
}

// ===== 散布：子彈在以準心為中心的圓錐內隨機偏移（M2）=====
// 做法照 CSGODOT（Godot 重製的 CS2：https://github.com/sidcarrollworks/CSGODOT，使用者 2026-10-13 選定；docs/findings.md §16.2）
// - 圓錐半角 = 姿勢的基礎值 + 開火累積量；每發累積，停火後指數衰減；子彈方向在圓錐內隨機
// - vdata 的不準度是正切值，角度 = atan(值)（CSGODOT weapon_vdata.gd:131-139）
// - Geralt 不能蹲，所以只分站立／移動（跳躍：docs/findings.md §16.2）

@addField(Crossbow)
var gfgSpreadPenalty : float;	// 開火累積的不準度（度）

// 站著不動：atan(m_flInaccuracyStand 0.00641 + m_flSpread 0.0006)（weapon_vdata.gd:88）
@addMethod(Crossbow)
function GfgSpreadStand() : float
{
	return 0.4016;
}

// 全速移動：atan(m_flInaccuracyMove 0.17506 + Stand 0.00641 + Spread 0.0006)（weapon_vdata.gd:90）
@addMethod(Crossbow)
function GfgSpreadMove() : float
{
	return 10.3188;
}

// 每發累積：atan(m_flInaccuracyFire 0.0078)（weapon_vdata.gd:92）
@addMethod(Crossbow)
function GfgSpreadPerShot() : float
{
	return 0.4469;
}

// AK 的最高移動速度：m_flMaxSpeed 215 單位/秒 ≈ 5.46 公尺/秒（docs/ak47_params.md §6）
// Geralt 的速度直接和它比（推測，之後可調）
@addMethod(Crossbow)
function GfgMaxMoveSpeed() : float
{
	return 5.46;
}

// 移動占多少：速度在最高速的 34%～95% 之間從 0 到 1，再開四次方根（CSGODOT weapon.gd:118-126、:613-619，註明是 CS:GO 的 0.34、0.95）
// CS 按住慢走鍵時改成線性；這裡不分（推測）
@addMethod(Crossbow)
function GfgMoveShare() : float
{
	var speed, from, full : float;

	speed = VecLength2D( ownerPlayer.GetMovingAgentComponent().GetVelocity() );
	from = GfgMaxMoveSpeed() * 0.34;
	full = GfgMaxMoveSpeed() * 0.95;
	if ( speed <= from )
		return 0.f;
	return PowF( MinF( 1.f, ( speed - from ) / ( full - from ) ), 0.25 );
}

// 目前的圓錐半角（度）：站立值 + 移動多出來的部分 × 移動比例 + 開火累積量（weapon.gd:593-621）
@addMethod(Crossbow)
function GfgSpreadCone() : float
{
	return GfgSpreadStand() + ( GfgSpreadMove() - GfgSpreadStand() ) * GfgMoveShare() + gfgSpreadPenalty;
}

// 恢復時間（秒，降到十分之一的時間）：連射第 2～5 發之間從 0.368 變成 0.506
// （m_flRecoveryTimeStand／StandFinal、m_nRecoveryTransitionStartBullet／EndBullet：docs/ak47_params.md §4.2；混合方式照 weapon_data.gd 的 recovery_time）
// CSGODOT 用的是 recoil index，這裡用這一輪連射的發數（推測）
@addMethod(Crossbow)
function GfgSpreadRecoveryTime() : float
{
	return 0.368 + ( 0.506 - 0.368 ) * ClampF( ( gfgBurstShots - 2.f ) / ( 5.f - 2.f ), 0.f, 1.f );
}

// 每格畫面：開火累積量指數衰減，時間常數 = 恢復時間 ÷ ln 10；低於每發值的 1% 就歸零
// （weapon.gd:535-540；weapon_data.gd 的 accuracy_time_constant、accuracy_reset_threshold、SETTLE_FRACTION 0.01）
@addMethod(Crossbow)
function GfgDecaySpread( dt : float )
{
	if ( gfgSpreadPenalty <= 0.f )
		return;
	gfgSpreadPenalty *= ExpF( -dt * 2.302585 / GfgSpreadRecoveryTime() );
	if ( gfgSpreadPenalty < GfgSpreadPerShot() * 0.01 )
		gfgSpreadPenalty = 0.f;
}

// 把方向往上轉 up 度、往右轉 right 度（heading 變小是往右：r4Player.ws:16144-16145）
@addMethod(Crossbow)
function GfgRotateDirection( dir : Vector, up : float, right : float ) : Vector
{
	var pitch : float;
	var result : Vector;

	pitch = Deg2Rad( Rad2Deg( AsinF( dir.Z ) ) + up );
	result = VecFromHeading( VecHeading( dir ) - right ) * CosF( pitch );
	result.Z = SinF( pitch );
	result.W = 0.f;
	return result;
}

// 子彈的目標點：從鏡頭沿著準心的方向（平常是畫面中央；鎖定時是鎖定目標身上）加上散布打射線，取最近的命中點；後座力已經轉到鏡頭上
// 寫法照原版 CalculateAimPosition（playerAiming.ws:553-616，碰撞群組 :33-49）；原版那個是 private，不能直接呼叫
// 這條射線只會打到牆、地面等；角色打不到（第 11 項：2026-10-16 實測）→ 角色另外判斷（W3BoltProjectile.GfgFindActorOnRay）
// rayStart、rayDir：射線的起點、方向（含散布）
@addMethod(Crossbow)
function GfgAimPoint( out rayStart : Vector, out rayDir : Vector ) : Vector
{
	var dir, start, end, hit, lockPoint, aimDir : Vector;
	var results : array<SRaycastHitResult>;
	var groups : array<name>;
	var i : int;
	var best : float;
	var found : bool;
	var ent : CEntity;
	var actor : CActor;
	var item : CItemEntity;
	var angle, radius : float;
	var vehicle : CGameplayEntity;

	// 散布：隨機方向，偏離角度 = 均勻亂數 × 圓錐半角，越靠中心越密（CSGODOT weapon.gd:853-870）
	angle = RandF() * 2.f * Pi();
	radius = RandF() * GfgSpreadCone();
	// 準心的方向：平常是畫面中央；鎖定（Z）時準心在鎖定目標身上，改朝那一點（GfgLockPoint、GfgUpdateCrosshair）
	if ( thePlayer.GfgLockPoint( lockPoint ) )
		aimDir = VecNormalize( lockPoint - GfgEyePosition() );
	else
		aimDir = GfgViewDirection();
	dir = GfgRotateDirection( aimDir, radius * SinF( angle ), radius * CosF( angle ) );
	start = GfgEyePosition() + dir * 0.5;	// 原版也從鏡頭前 0.5 公尺開始（playerAiming.ws:324）
	end = start + dir * GfgRange();
	rayStart = start;
	rayDir = dir;
	hit = end;

	groups.PushBack( 'RigidBody' );
	groups.PushBack( 'Character' );
	groups.PushBack( 'Static' );
	groups.PushBack( 'Debris' );
	groups.PushBack( 'Ragdoll' );
	groups.PushBack( 'Destructible' );
	groups.PushBack( 'Terrain' );
	groups.PushBack( 'Phantom' );
	groups.PushBack( 'Dangles' );
	groups.PushBack( 'Weapon' );
	groups.PushBack( 'Water' );
	groups.PushBack( 'Foliage' );
	groups.PushBack( 'CommunityCollidables' );
	groups.PushBack( 'Boat' );
	groups.PushBack( 'Door' );
	groups.PushBack( 'Platforms' );
	groups.PushBack( 'Corpse' );

	vehicle = thePlayer.GetUsedVehicle();
	if ( theGame.GetWorld().GetTraceManager().RayCastSync( start, end, results, groups ) )
	{
		for ( i = 0; i < results.Size(); i += 1 )
		{
			// 排除自己、自己的武器與箭、死亡或昏迷的角色（同 playerAiming.ws:583-585）
			// 騎馬時也排除自己的馬：原版的箭會穿過自己的馬（throwable.ws:117-118）
			// 打到地形等沒有元件的東西時 component 是空的（原版 playerAiming.ws:337 也有檢查）
			if ( results[i].component )
				ent = results[i].component.GetEntity();
			else
				ent = NULL;
			if ( ent == thePlayer || ( vehicle && ent == vehicle ) || ent == this || ent == deployedEnt || (W3BoltProjectile)ent )
				continue;
			item = (CItemEntity)ent;
			if ( item && item.GetParentEntity() == thePlayer )
				continue;
			actor = (CActor)ent;
			if ( actor && ( !actor.IsAlive() || actor.IsKnockedUnconscious() ) )
				continue;

			if ( !found || results[i].distance < best )
			{
				best = results[i].distance;
				hit = results[i].position;
				found = true;
			}
		}
	}
	return hit;
}

// 暫時（第 11 項）：元件的說明（實體名稱、是不是移動元件＝膠囊、元件名稱）
function GfgCompDesc( comp : CComponent ) : string
{
	var ent : CEntity;
	var isAgent : bool;

	if ( !comp )
		return "comp=none";
	ent = comp.GetEntity();
	if ( (CMovingAgentComponent)comp )
		isAgent = true;
	return "ent=" + ent.GetName() + " agent=" + isAgent + " comp=" + comp.GetName();
}

// ===== 準心：拿著 AK 時一直顯示，固定在原本的位置（畫面中央）=====

@addField(CR4Player)
var gfgCrosshairShown : bool;	// 準心是不是我們打開的

@addField(CR4Player)
var gfgAimingState : name;		// 上一格畫面 playerAiming 的狀態（'Waiting'／'Aiming'）

@addField(CR4Player)
var gfgCrosshairOnLock : bool;	// 準心是不是被移到鎖定目標身上（GfgUpdateCrosshair）

// 鎖定（Z）的目標身上要瞄準的點；沒有鎖定、目標不在或死了回傳 false
// 取法同原版拿著十字弩時的 ProcessLookAtTargetPosition（r4Player.ws:2887-2963、:2875-2876）：軀幹骨頭，沒有就用碰撞膠囊一半高度，再往上 0.2 公尺；
// 不取原版先找的虛擬控制器骨頭（:2909，那個函式會改到玩家的狀態）
@addMethod(CR4Player)
function GfgLockPoint( out point : Vector ) : bool
{
	var target : CActor;
	var boneIdx : int;
	var mac : CMovingPhysicalAgentComponent;

	if ( !IsHardLockEnabled() )
		return false;
	target = GetTarget();
	if ( !target || !target.IsAlive() )
		return false;

	point = target.GetWorldPosition();
	boneIdx = target.GetTorsoBoneIndex();
	if ( boneIdx >= 0 )
		point = MatrixGetTranslation( target.GetBoneWorldMatrixByIndex( boneIdx ) );
	else
	{
		mac = (CMovingPhysicalAgentComponent)target.GetMovingAgentComponent();
		if ( mac )
			point.Z += mac.GetCapsuleHeight() * 0.5;
	}
	point.Z += 0.2f;
	return true;
}

// 原版的準心只在中鍵瞄準時顯示（playerAiming.ws:187 打開、:683-686 AimCleanup 關掉）；
// 左鍵扳機不會進入瞄準（CheckGotoAimThrow 只看中鍵 ThrowItem：rangedWeapon.ws:1362），所以要自己打開
// 鎖定（Z）時準心移到被鎖定的目標身上（使用者 2026-10-14 選定；docs/findings.md §20.13）
@addMethod(CR4Player)
function GfgUpdateCrosshair( drawn : bool )
{
	var hud : CR4ScriptedHud;
	var module : CR4HudModuleCrosshair;
	var aimingState : name;
	var lockPoint, screen : Vector;
	var x, y : float;

	// 取得準心模組的方式同原版 playerAiming.ws:213-215
	hud = (CR4ScriptedHud)theGame.GetHud();
	if ( !hud )
		return;
	module = (CR4HudModuleCrosshair)hud.GetHudModule( "CrosshairModule" );
	if ( !module )
		return;

	aimingState = playerAiming.GetCurrentStateName();
	if ( drawn )
	{
		// 原版關準心只有一個地方：中鍵瞄準結束時的 AimCleanup，之後回到 'Waiting'。
		// 所以 playerAiming 的狀態一變就再打開一次，否則用中鍵射完一發，準心會跟著消失
		if ( !gfgCrosshairShown || aimingState != gfgAimingState )
		{
			module.SnapToAnchorPosition();	// 放回原本的錨點（hudModuleBase.ws:72-112）；上一版會移動準心
			module.ShowElement( true, false );
		}
	}
	else if ( gfgCrosshairShown )
	{
		// 只關我們打開的，不影響原版丟炸彈、十字弩瞄準時的準心
		module.ShowElement( false, false );
	}
	gfgCrosshairShown = drawn;
	gfgAimingState = aimingState;

	// 鎖定時：每格把準心移到鎖定目標的瞄準點；換算同原版 GetBaseScreenPosition（hud.ws:1864-1878），
	// 位置直接設給模組（原版敵人標記也是直接用這個座標：hudModuleEnemyFocus.ws:396-422）
	if ( drawn && GfgLockPoint( lockPoint ) && theCamera.WorldVectorToViewRatio( lockPoint, x, y ) )
	{
		screen = hud.GetScaleformPoint( ( x + 1 ) / 2, ( y + 1 ) / 2 );
		module.GetModuleFlash().SetX( screen.X );
		module.GetModuleFlash().SetY( screen.Y );
		gfgCrosshairOnLock = true;
	}
	else if ( gfgCrosshairOnLock )
	{
		module.SnapToAnchorPosition();	// 解除鎖定：放回原本的錨點（hudModuleBase.ws:72-112）
		gfgCrosshairOnLock = false;
	}
}

// 每格（走路、騎馬共用）：把後座力轉到鏡頭上、不自動收槍、解除 Z 鎖定的鎖、更新準心
// - 直接改 moveData.pivotRotationValue：原版爬牆的鏡頭也是每格改這個值（explorationStateClimb.ws:2111-2135）；
//   2026-10-13 實測（走路），改過的角度會保留，不會被拉回（docs/findings.md §14.4）
//   騎馬時馬的鏡頭每格會把上下角度拉向地形（horseRiding.ws:497、:525），未實測
// - 方向：pitch 往上為正（swimming.ws:1401-1406：pitch < 0 是往下）；yaw 往左為正（r4Player.ws:16144-16145：右邊的點是 heading - 90）
@addMethod(CR4Player)
function GfgCameraTick( out moveData : SCameraMovementData, dt : float )
{
	var akDrawn : bool;
	var up, right : float;

	akDrawn = false;
	if ( rangedWeapon )
	{
		rangedWeapon.GfgUpdateRecoil( dt, up, right );
		moveData.pivotRotationValue.Pitch += up;
		moveData.pivotRotationValue.Yaw -= right;
		akDrawn = rangedWeapon.GfgIsAkDrawn();
		if ( akDrawn )
		{
			GfgLogHoldPose();	// 暫時：量雙手持槍的實際位置（量完就拿掉）
			GfgLogTwist();		// 暫時（第 13、14 項）
			rangedWeapon.GfgCancelAutoHolster();
			// Z 鎖定（硬鎖定）：十字弩瞄準狀態的 Lock() 會鎖住 EIAB_HardLock（rangedWeapon.ws:374-423；按 Z 時檢查：playerInput.ws:3510），
			// AK 一直待在瞄準狀態 → 一直鎖著。只解除這一個（使用者 2026-10-14 選定；docs/findings.md §20.7）；沒有這個鎖時直接返回（playerInput.ws:251-254）
			UnblockAction( EIAB_HardLock, 'RangedWeapon' );
			// 叫馬、上下馬：拿著 AK 也可以（第 4 項，使用者 2026-10-16：要先按 C 收槍才能叫馬、才出現長按 E 下馬 → 順一點）
			// 原版拿著十字弩時：瞄準狀態的 Lock() 擋掉例外以外的所有動作（rangedWeapon.ws:401-422），拿出時另外鎖上下馬（:1145-1146，收好才解：:56-61）
			// 叫馬：左手沒拿可用物品（火把等）時直接叫（playerInput.ws:748-758）；上下馬開始時立刻收槍（下面 MountTheVehicle／DismountTheVehicle 的包裝）
			UnblockAction( EIAB_CallHorse, 'RangedWeapon' );
			UnblockAction( EIAB_MountVehicle, 'RangedWeapon' );
			UnblockAction( EIAB_MountVehicle, 'ShootingCrossbow' );
			UnblockAction( EIAB_DismountVehicle, 'RangedWeapon' );
			UnblockAction( EIAB_DismountVehicle, 'ShootingCrossbow' );
			GfgClearDeadSlideTarget();
		}
	}
	if ( akDrawn && !IsUsingVehicle() )
		GfgAkTurnTick();
	else
		GfgAkTurnReset();
	GfgArmsHoldTick( akDrawn );
	GfgCarryTick( akDrawn, dt );
	GfgMagTick( akDrawn );		// 換彈時彈匣拿下來（第 8 項 B）
	GfgNoSwordTick();			// 不准拿劍、自動舉 AK（第 19 項）
	GfgUpdateCrosshair( akDrawn && !( IsUsingVehicle() && gfgHorseAimOut ) );		// 騎馬瞄準超出左右範圍時藏起來（第 18 項）
}

// ===== 槍口火光（第 10 項；2026-10-17）=====
// 照原版刀砍到東西的火花（btTaskAttack.ws:339-357）：生成特效實體（W3VisualFx）、播特效、播完自己刪掉（visual_fx.ws:36-49）
// 掛在 l_weapon 的槍口位置：特效實體是自己生成的，跟著掛的骨頭走（CLAUDE.md §6.18 的限制只針對物品系統掛的物品）
// 槍口：槍座標 F 0.669、U 0.096（AK 模型槍管最前端）→ l_weapon 座標 (0.2368, 0.0409, 0.1710)
@addField(CR4Player)
var gfgMuzzleTmpl : CEntityTemplate;

@addMethod(CR4Player)
function GfgMuzzleFlash()
{
	var fx : W3VisualFx;

	// 模板：原版刀劍火花 sword_colision_fx（gameplay.xml:131）的複本，改成槍口用：拿掉刀劍碰撞聲、光 0.06 秒半徑 3、粒子只噴 0.1 秒、整段 0.8 秒
	// 路徑寫法照 signEntity.ws:708（第二個參數 true = 路徑，不是別名）
	if ( !gfgMuzzleTmpl )
		gfgMuzzleTmpl = (CEntityTemplate)LoadResource( "dlc\gunforgeralt\data\fx\gfg_muzzle_flash.w2ent", true );
	if ( !gfgMuzzleTmpl )
		return;
	fx = (W3VisualFx)theGame.CreateEntity( gfgMuzzleTmpl, GetWorldPosition(), GetWorldRotation() );
	if ( !fx )
		return;
	fx.CreateAttachment( this, 'l_weapon', Vector( 0.2368, 0.0409, 0.1710 ) );
	fx.PlayEffect( 'sparks' );
	fx.DestroyOnFxEnd( 'sparks' );
}

// ===== 換彈：彈匣真的拿下來（第一批第 8 項 B；2026-10-17）=====
// 換彈動畫（tools/reload_pose.py；docs/m3.md「換彈動畫」）：左手 0.30 秒到彈匣底下 → 拉出 → 左腰 → 1.50 秒裝上（動畫事件 OnWeaponReload）
// - 抓：換彈開始 0.9 秒內，左手腕到了彈匣底下（槍座標 F 0.25、U −0.15、R −0.03）3 公分內、而且不再變近 →
//   真的 AK 藏起來、改顯示沒彈匣的替身（gfg_ak47_nomag.w2ent：掛 l_weapon 不帶偏移 = 真的 AK 的位置，同衝刺的替身）；
//   彈匣（gfg_ak47_mag.w2ent：模型在槍上的位置）用現在的世界姿勢掛到左手（CreateAttachmentAtBoneWS：原版插在敵人身上的箭也這樣掛，arrowProjectile.ws:554）
// - 裝上：OnWeaponReload 換回真的 AK；換彈中斷（離開換彈狀態、衝刺提槍、收槍）也換回
// - 動畫裡左手相對槍的方向不變、裝上時的位置和抓的時候相同 → 彈匣回到彈匣口時剛好對上
// - 槍座標：原點 = 握把（l_weapon 座標 (-0.3032, -0.0115, -0.2320)）、F 槍管、U 上、R = F×U（同 GfgCarryTick 的 f0、u0）
@addField(CR4Player)
var gfgMagNoMag : CEntity;	// 沒彈匣的 AK（不存檔；換關卡後會不見 → 再生成）
@addField(CR4Player)
var gfgMagEnt : CEntity;	// 彈匣
@addField(CR4Player)
var gfgMagOut : bool;		// 彈匣在左手上（真的 AK 藏著）
@addField(CR4Player)
var gfgMagReloading : bool;	// 上一格在換彈
@addField(CR4Player)
var gfgMagStart : float;	// 這次換彈開始的時間（引擎時間；慢動作時跟著變慢）
@addField(CR4Player)
var gfgMagDone : bool;		// 這次換彈抓過了
@addField(CR4Player)
var gfgMagMinDist : float;	// 暫時：這次換彈左手腕離抓的點最近多少（沒抓到時印出來）
@addField(CR4Player)
var gfgMagFailed : bool;	// 模板載入失敗：不再重試
@addField(CR4Player)
var gfgMagPrevDist : float;	// 上一格左手腕離抓的點多遠

@addMethod(CR4Player)
function GfgMagSpawn( path : string ) : CEntity
{
	var tmpl : CEntityTemplate;
	var tags : array< name >;
	var ent : CEntity;

	tmpl = (CEntityTemplate)LoadResource( path, true );
	if ( !tmpl )
	{
		gfgMagFailed = true;
		LogChannel( 'GFG', "mag template not found: " + path );
		return NULL;
	}
	tags.PushBack( 'gfg_carry_dummy' );	// 同衝刺的替身：RangedWeapon.OnSpawned 不初始化十字弩
	ent = theGame.CreateEntity( tmpl, GetWorldPosition(), GetWorldRotation(), true, false, true, PM_DontPersist, tags );
	if ( ent )
	{
		GfgSetMeshVisible( ent, false );
		ent.CreateAttachment( this, 'l_weapon' );
	}
	return ent;
}

@addMethod(CR4Player)
function GfgMagTick( akDrawn : bool )
{
	var reloading : bool;
	var lw : Matrix;
	var lx, ly, lz, d, g, f0, u0, r0 : Vector;
	var dist, now, prev : float;

	if ( !akDrawn || gfgMagFailed )
	{
		GfgMagRestore();
		gfgMagReloading = false;
		return;
	}
	// 拿出 AK 時先生成（藏著），第一次換彈時模型已經載入
	if ( !gfgMagNoMag )
		gfgMagNoMag = GfgMagSpawn( "dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47_nomag.w2ent" );
	if ( !gfgMagEnt && !gfgMagFailed )
		gfgMagEnt = GfgMagSpawn( "dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47_mag.w2ent" );
	if ( !gfgMagNoMag || !gfgMagEnt )
		return;

	reloading = rangedWeapon.GetCurrentStateName() == 'State_WeaponReload' && !gfgCarryOn;
	now = theGame.GetEngineTimeAsSeconds();
	if ( !reloading )
	{
		GfgMagRestore();
		gfgMagReloading = false;
		return;
	}
	if ( !gfgMagReloading )
	{
		gfgMagReloading = true;
		gfgMagStart = now;
		gfgMagDone = false;
		gfgMagMinDist = 99.f;
		gfgMagPrevDist = 99.f;
	}
	if ( gfgMagOut || gfgMagDone )
		return;
	if ( now - gfgMagStart > 0.9f )
	{
		gfgMagDone = true;
		LogChannel( 'GFG', "mag no grab: min dist " + FloatToString( gfgMagMinDist ) );
		return;
	}
	// 左手腕在槍座標的位置
	lw = GetBoneWorldMatrixByIndex( GetBoneIndex( 'l_weapon' ) );
	lx = MatrixGetAxisX( lw );
	ly = MatrixGetAxisY( lw );
	lz = MatrixGetAxisZ( lw );
	d = GetBoneWorldPositionByIndex( GetBoneIndex( 'l_hand' ) ) - MatrixGetTranslation( lw );
	g = Vector( VecDot( d, lx ), VecDot( d, ly ), VecDot( d, lz ) ) - Vector( -0.3032f, -0.0115f, -0.2320f );
	f0 = VecNormalize( Vector( 0.8033f, 0.2140f, 0.5558f ) );
	u0 = VecNormalize( Vector( 0.02721f, -0.94542f, 0.32472f ) );
	r0 = VecCross( f0, u0 );
	dist = VecLength( Vector( VecDot( g, f0 ) - 0.25f, VecDot( g, u0 ) + 0.15f, VecDot( g, r0 ) + 0.03f ) );
	gfgMagMinDist = MinF( gfgMagMinDist, dist );
	// 上一格在 3 公分內、這一格不再變近才抓（= 最接近的那一刻剛過）：01:4x 一進 3 公分就抓，兩次都是 2.9 公分（剛好在門檻邊）
	prev = gfgMagPrevDist;
	gfgMagPrevDist = dist;
	if ( prev > 0.03f || dist < prev )
		return;
	// 抓：真的 AK → 沒彈匣的替身；彈匣用現在的世界姿勢（= l_weapon）掛到左手
	GfgSetMeshVisible( gfgMagNoMag, true );
	rangedWeapon.GfgSetCarryShown( false );
	gfgMagEnt.BreakAttachment();
	gfgMagEnt.CreateAttachmentAtBoneWS( this, 'l_hand', MatrixGetTranslation( lw ), MatrixGetRotation( lw ) );
	GfgSetMeshVisible( gfgMagEnt, true );
	gfgMagOut = true;
	gfgMagDone = true;
	LogChannel( 'GFG', "mag out t=" + FloatToString( now - gfgMagStart ) + " dist=" + FloatToString( dist ) );
}

// ===== 暫時（測試用，2026-10-17）：從指定角度看 Geralt（換彈等動作從背後的遊戲鏡頭看不到）=====
// 02:5x 試過原版固定鏡頭（gameplay\camera\static_camera.w2ent）：方向一直不對（俯仰 0 時往下看地、朝向差 90°）→ 不用
// 改用拍照模式的鏡頭（CCustomCamera：r4Game.ws:303），作法照 photomodeManager.ws:96-111：Activate → SetCameraWorldPosition／Rotation → UpdateWithoutInput；
// 回復：原本的鏡頭 Activate( 0, false )（:137）
// 瞄準、轉身、子彈照樣用遊戲鏡頭（GfgCamera：看這個鏡頭時回傳遊戲鏡頭）
// 搭配 slow( 0.01 ) 放慢時間（temp.ws:8210）：換彈 2.4 秒變成 4 分鐘，可以換角度慢慢看
// gfgview( 角度, 距離, 高度, 俯仰 )：角度相對 Geralt 的朝向（0 = 正前方、90 = 左邊、-90 = 右邊）；gfgviewoff() 回到遊戲鏡頭
@addField(CR4Player)
var gfgViewPrevCam : CCustomCamera;
@addField(CR4Player)
var gfgViewOn : bool;

@addMethod(CR4Player)
function GfgView( angle : float, dist : float, height : float, pitch : float )
{
	var cam, top : CCustomCamera;
	var pos : Vector;
	var rot : EulerAngles;

	cam = theGame.GetPhotomodeCamera();
	if ( !cam )
	{
		LogChannel( 'GFG', "view: no photomode camera" );
		return;
	}
	top = (CCustomCamera)theGame.GetWorld().GetCameraDirector().GetTopmostCamera();
	if ( !gfgViewOn )
		gfgViewPrevCam = top;
	pos = GetWorldPosition() + VecFromHeading( GetHeading() + angle ) * dist;
	pos.Z += height;
	pos.W = 1.f;
	rot = EulerAngles( pitch, VecHeading( GetWorldPosition() - pos ), 0.f );
	cam.Activate( 0.f, false );
	cam.SetCameraWorldPosition( pos );
	cam.SetCameraWorldRotation( rot );
	cam.UpdateWithoutInput( true );
	gfgViewOn = true;
	LogChannel( 'GFG', "view pos " + VecToString( pos ) + " rot " + FloatToString( rot.Pitch ) + " " + FloatToString( rot.Yaw )
		+ " prevTop " + ( gfgViewPrevCam == theGame.GetGameCamera() ) );
}

@addMethod(CR4Player)
function GfgViewOff()
{
	if ( gfgViewPrevCam )
		gfgViewPrevCam.Activate( 0.f, false );
	else
		theGame.GetGameCamera().Activate( 0.f, false );
	gfgViewPrevCam = NULL;
	gfgViewOn = false;
}

exec function gfgview( angle : float, dist : float, height : float, optional pitch : float )
{
	thePlayer.GfgView( angle, dist, height, pitch );
}

exec function gfgviewoff()
{
	thePlayer.GfgViewOff();
}

// 裝上（或換彈中斷）：換回真的 AK；彈匣藏起來、掛回 l_weapon
@addMethod(CR4Player)
function GfgMagRestore()
{
	if ( !gfgMagOut )
		return;
	gfgMagOut = false;
	if ( rangedWeapon && !gfgCarryOn )
		rangedWeapon.GfgSetCarryShown( true );
	if ( gfgMagNoMag )
		GfgSetMeshVisible( gfgMagNoMag, false );
	if ( gfgMagEnt )
	{
		GfgSetMeshVisible( gfgMagEnt, false );
		gfgMagEnt.BreakAttachment();
		gfgMagEnt.CreateAttachment( this, 'l_weapon' );
	}
	LogChannel( 'GFG', "mag in t=" + FloatToString( theGame.GetEngineTimeAsSeconds() - gfgMagStart ) );
}

// 裝上新彈匣：換彈動畫的事件 OnWeaponReload（1.5 秒：rangedWeapon.ws:150-152）
// 每發之後不播動畫的裝箭（rangedWeapon.ws:276-297）也會呼叫，這時彈匣不在手上，GfgMagRestore 不做事
@wrapMethod(RangedWeapon)
function OnWeaponReload()
{
	if ( ownerPlayer == thePlayer )
		thePlayer.GfgMagRestore();
	return wrappedMethod();
}

// ===== 暫時：量雙手持槍的實際位置（使用者 2026-10-15 同意；docs/m3.md「擺法 A 進遊戲：錯誤」；量完就拿掉）=====
// 拿著 AK 時每 0.5 秒印一次引擎的矩陣（世界座標）：位置、x／y／z 軸
// - 取法同原版 actor.ws:6775-6810（GetBoneIndex、GetBoneWorldMatrixByIndex）；軸用 MatrixGetAxisX／Y／Z（math.ws:528-534），不經過歐拉角
@addField(CR4Player)
var gfgPoseLogTime : float;

@addMethod(CR4Player)
function GfgLogMatrix( label : string, m : Matrix )
{
	LogChannel( 'GFG', "pose " + label + " pos " + VecToStringPrec( MatrixGetTranslation( m ), 4 )
		+ " x " + VecToStringPrec( MatrixGetAxisX( m ), 4 ) + " y " + VecToStringPrec( MatrixGetAxisY( m ), 4 ) + " z " + VecToStringPrec( MatrixGetAxisZ( m ), 4 ) );
}

@addMethod(CR4Player)
function GfgLogBone( ent : CEntity, label : string, bone : name )
{
	var idx : int;

	idx = ent.GetBoneIndex( bone );
	if ( idx == -1 )
		LogChannel( 'GFG', "pose " + label + " bone not found" );
	else
		GfgLogMatrix( label, ent.GetBoneWorldMatrixByIndex( idx ) );
}

@addField(CR4Player)
var gfgTwistLogTime : float;

// 暫時（第 13、14 項）：兩點連線（右 → 左）的朝向：左邊的點減右邊的點，轉 -90°（Z 朝上）
function GfgLineHeading( l, r : Vector ) : float
{
	var v, f : Vector;

	v = l - r;
	f.X = v.Y;
	f.Y = -v.X;
	return VecHeading( f );
}

// 暫時（第 13、14 項）：骨盆（兩大腿）、肩膀的朝向和腰扭，每 0.1 秒
@addMethod(CR4Player)
function GfgLogTwist()
{
	var now, hip, sh, velHead : float;
	var vel : Vector;

	now = theGame.GetEngineTimeAsSeconds();
	if ( now - gfgTwistLogTime < 0.1 )
		return;
	gfgTwistLogTime = now;
	hip = GfgLineHeading( GetBoneWorldPosition( 'l_thigh' ), GetBoneWorldPosition( 'r_thigh' ) );
	sh = GfgLineHeading( GetBoneWorldPosition( 'l_shoulder' ), GetBoneWorldPosition( 'r_shoulder' ) );
	vel = GetMovingAgentComponent().GetVelocity();
	velHead = -999.f;
	if ( VecLength2D( vel ) > 0.2 )
		velHead = VecHeading( vel );
	LogChannel( 'GFG', "twist t=" + FloatToString( now ) + " head=" + FloatToString( GetHeading() ) + " cam=" + FloatToString( theCamera.GetCameraHeading() )
		+ " hip=" + FloatToString( AngleDistance( hip, GetHeading() ) ) + " sh=" + FloatToString( AngleDistance( sh, GetHeading() ) )
		+ " tw=" + FloatToString( AngleDistance( sh, hip ) ) + " vel=" + FloatToString( VecLength2D( vel ) )
		+ " velDir=" + FloatToString( AngleDistance( velHead, GetHeading() ) ) + " fire=" + rangedWeapon.GfgIsFiring() + " fireMove=" + gfgFireMoving
		+ " full=" + FloatToString( GetBehaviorVariable( 'fullBodyAnimWeight' ) ) + " ovl=" + GetRootAnimatedComponent().GetCurrentBehaviorState( 'PlayerOverlay' )
		+ " gp=" + GetRootAnimatedComponent().GetCurrentBehaviorState( 'Gameplay' )
		+ " aimH=" + FloatToString( GetBehaviorVariable( 'aimHorizontal' ) ) + " out=" + gfgHorseAimOut + " veh=" + IsUsingVehicle() );
}

@addMethod(CR4Player)
function GfgLogHoldPose()
{
	var now : float;

	now = theGame.GetEngineTimeAsSeconds();
	if ( now - gfgPoseLogTime < 0.5 )
		return;
	gfgPoseLogTime = now;
	LogChannel( 'GFG', "pose t=" + FloatToString( now ) + " player=" + GetCurrentStateName() + " ak=" + rangedWeapon.GetCurrentStateName()
		+ " held=" + FloatToString( GetBehaviorVariable( 'hasCrossbowHeld' ) )	// 主動畫圖走路、跑步時兩手用 aim_run 的開關（rangedWeapon.ws:1293）
		+ " friendly=" + FloatToString( GetBehaviorVariable( 'isShootingFriendlyForOverlay' ) ) );	// 上半身 #18575：移動中而且 ≥ 1 → 換成一般跑步的手（rangedWeapon.ws:566-580）
	GfgLogDiag();
	GfgLogMatrix( "player", GetLocalToWorld() );
	GfgLogBone( this, "l_weapon", 'l_weapon' );
	GfgLogBone( this, "l_hand", 'l_hand' );
	GfgLogBone( this, "r_hand", 'r_hand' );
	GfgLogBone( this, "r_weapon", 'r_weapon' );
	GfgLogBone( this, "l_foot", 'l_foot' );	// 跑步、走路時腿有沒有在動
	GfgLogBone( this, "r_foot", 'r_foot' );
	GfgLogMatrix( "ak", rangedWeapon.GetLocalToWorld() );
	GfgLogBone( rangedWeapon, "ak_handle", 'handle' );
	if ( gfgDummy )
	{
		GfgLogMatrix( "dummy", gfgDummy.GetLocalToWorld() );
		GfgLogBone( gfgDummy, "dummy_handle", 'handle' );
	}
	LogChannel( 'GFG', "pose camera eye " + VecToStringPrec( rangedWeapon.GfgEyePosition(), 4 ) + " dir " + VecToStringPrec( rangedWeapon.GfgViewDirection(), 4 ) );
}

// 暫時：查使用者 2026-10-16 回報的 10 個問題用（動畫圖的狀態、變數、目標）；做完就拿掉
@addMethod(CR4Player)
function GfgEntName( ent : CEntity ) : string
{
	var actor : CActor;

	if ( !ent )
		return "none";
	actor = (CActor)ent;
	if ( actor && !actor.IsAlive() )
		return ent.GetName() + "(dead)";
	return ent.GetName();
}

@addMethod(CR4Player)
function GfgLogDiag()
{
	var ac : CAnimatedComponent;

	ac = GetRootAnimatedComponent();
	LogChannel( 'GFG', "diag gp=" + ac.GetCurrentBehaviorState( 'Gameplay' ) + " ovl=" + ac.GetCurrentBehaviorState( 'PlayerOverlay' )
		+ " stance=" + IntToString( (int)GetPlayerCombatStance() ) + " ot=" + IntToString( (int)GetOrientationTarget() )
		+ " full=" + FloatToString( GetBehaviorVariable( 'fullBodyAnimWeight' ) ) + " mtOvl=" + FloatToString( GetBehaviorVariable( 'playerMoveTypeForOverlay' ) )
		+ " spdOvl=" + FloatToString( GetBehaviorVariable( 'playerSpeedForOverlay' ) ) + " aimW=" + FloatToString( GetBehaviorVariable( 'isAimingWeapon' ) )
		+ " cbtStOvl=" + FloatToString( GetBehaviorVariable( 'CombatStanceForOverlay' ) ) + " pcsOvl=" + FloatToString( GetBehaviorVariable( 'playerCombatStanceForOverlay' ) )
		+ " wpnOvl=" + FloatToString( GetBehaviorVariable( 'playerWeaponForOverlay' ) ) + " inCA=" + FloatToString( GetBehaviorVariable( 'isInCombatActionForOverlay' ) )
		+ " caType=" + FloatToString( GetBehaviorVariable( 'combatActionType' ) ) + " walkInPlace=" + FloatToString( GetBehaviorVariable( 'walkInPlace' ) )
		+ " aimThrowOvl=" + FloatToString( GetBehaviorVariable( 'inAimThrowForOverlay' ) )
		+ " reqMove=" + FloatToString( GetBehaviorVariable( 'requestedMovementDirectionForOverlay' ) ) + " reqFace=" + FloatToString( GetBehaviorVariable( 'requestedFacingDirectionForOverlay' ) )
		+ " slide=" + GfgEntName( slideTarget ) + " disp=" + GfgEntName( GetDisplayTarget() ) + " target=" + GfgEntName( GetTarget() )
		+ " hard=" + IsHardLockEnabled() + " actorLock=" + IsActorLockedToTarget() + " threat=" + IsThreatened()
		+ " trig=" + rangedWeapon.gfgTriggerHeld + " fireMove=" + gfgFireMoving + " turning=" + gfgTurning + " sprint=" + GetIsSprinting() + " air=" + IsInAir() + " carry=" + FloatToString( gfgCarryW )
		+ " head=" + FloatToString( GetHeading() ) + " camHead=" + FloatToString( theCamera.GetCameraHeading() )
		+ " vel=" + FloatToString( VecLength2D( GetMovingAgentComponent().GetVelocity() ) ) + " moveType=" + IntToString( (int)playerMoveType ) );
}

// 玩家鏡頭的每格更新（走路）
// - 腰射時玩家在 Exploration／Combat 狀態，都會經 extendedMovable.ws:123 呼叫到這裡
//   中鍵瞄準（AimThrow 狀態）不會：aimThrow.ws:161-394 沒有呼叫上層；那時左鍵也不是扳機（input_qwerty.ini:466-484 沒有 BASE_ATTACK_LIGHT）
// - 騎馬時也不會：HorseRiding 有自己的版本（horseRiding.ws:361-426），另外包（下面「騎馬」那一段）
@wrapMethod(CR4Player)
function OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	result = wrappedMethod( moveData, dt );
	GfgCameraTick( moveData, dt );
	return result;
}

// ===== 騎馬：左鍵開槍，行為和沒騎馬時一樣（使用者 2026-10-14 指定；docs/findings.md §24）=====
// 騎馬時左鍵是 VehicleAttack（legacy\base\input_qwerty.ini:313），由騎馬戰鬥管理處理：沒拿劍就拔劍、拿劍就揮砍（useVehicle.ws:706-779）。
// 原版騎馬射十字弩（中鍵）會讓戰鬥管理進入 ShootCrossbow 狀態（:744-758）；戰鬥管理不在閒置狀態時，
// 馬每格被鎖住速度，也不能跳、不能下馬（horse/states/exploration.ws:519-537、:970-971、:3007、:3047）。
// 使用者選「拿著 AK 時馬照常操作」（下馬還是要先收槍）：左鍵不進入 ShootCrossbow，戰鬥管理留在閒置狀態；
// 原本由 ShootCrossbow 做的兩件事改成自己做：手臂瞄準的方向（GfgHorseAimPose）、把動畫事件交給十字弩（OnAnimEvent_Throwable 的包裝）。
// 騎馬的動畫圖 pc_rider.w2beh：actionType（EVehicleCombatAction）選擇十字弩、炸彈、法印、揮劍哪一組動畫（#2643 → #2639 'Crossbow'），
// 十字弩那一組用 aimHorizontal、aimVertical 決定瞄準方向

// 閒置時按左鍵（OnAttack：useVehicle.ws:706-718；回到閒置時還按著：ShouldEnterNextState :601-604）：
// AK 選用時改成扳機，不拔劍、不揮劍（同地面的 OnCbtAttackWithAlternateLight）。船照原版
@wrapMethod(W3VehicleCombatManagerStateNull)
function StartAttackAction()
{
	var itemId : SItemUniqueId;
	var ak : Crossbow;

	itemId = rider.GetSelectedItemId();
	if ( !horseComp || !rider.inv.IsIdValid( itemId ) || !rider.inv.ItemHasTag( itemId, 'gfg_ak47' ) )
	{
		wrappedMethod();
		return;
	}

	ak = (Crossbow)rider.inv.GetItemEntityUnsafe( itemId );
	if ( !ak )
		return;
	// 手上有劍：先收劍、收好再拿出 AK（GfgNoSwordTick；第 19 項）
	if ( rider.GfgSwordInHand() && !rider.IsCrossbowHeld() )
	{
		rider.GfgRequestAkRaise( true );
		return;
	}
	// 還沒拿出來：照原版 StartItemAction 的十字弩分支拿出（:750-756），但不進入 ShootCrossbow、不另外鎖下馬
	// （拿出時十字弩自己會鎖下馬、上馬，收好才解：rangedWeapon.ws:1145-1146、:56-61）
	if ( !rider.IsCrossbowHeld() && rider.IsActionAllowed( EIAB_Crossbow ) )
	{
		rider.SetBehaviorVariable( 'actionType', (int)EHCA_ShootCrossbow );
		rider.rangedWeapon = ak;
		ak.OnRangedWeaponPress();
	}
	ak.GfgSetTrigger( true );
}

// 騎馬時鏡頭的每格更新（horseRiding.ws:361-426；不會呼叫 CR4Player 的 OnGameCameraTick）
// 用原版瞄準鏡頭時回傳 true，同原版按住中鍵瞄準時（useVehicle.ws:1754，經 horseRiding.ws:425 傳回）
@wrapMethod(CR4PlayerStateHorseRiding)
function OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	result = wrappedMethod( moveData, dt );
	parent.GfgCameraTick( moveData, dt );
	if ( parent.GfgHorseTick( vehicleCombatMgr, moveData, dt ) )
	{
		parent.GfgHorseCamLog( vehicleCombatMgr, true );
		return true;
	}
	parent.GfgHorseCamLog( vehicleCombatMgr, false );
	return result;
}

// ===== 上下馬（船也是）：開始時拿著 AK 就立刻收到背上（第 4 項）=====
// 原版拿著十字弩不能上下馬（rangedWeapon.ws:1145-1146）；左手的可用物品（火把等）上馬時也是直接收（mountHorse.ws:21 HideUsableItem）
// 上馬、上船都經過 MountTheVehicle.OnEnterState（mountHorse.ws:19、mountBoat.ws 的 super.OnEnterState）；下馬、下船都經過 DismountTheVehicle.OnEnterState（dismountHorse.ws:24）
// 收法同跳進水裡（CExplorationStateJump 的包裝）
@addMethod(CR4Player)
function GfgHolsterForVehicle()
{
	if ( rangedWeapon && rangedWeapon.GfgIsAkDrawn() )
	{
		LogChannel( 'GFG', "holster for vehicle: state=" + GetCurrentStateName() );	// 暫時
		OnRangedForceHolster( true, true );
	}
}

// 上馬的互動（第 4 項）：原版拿著十字弩時有兩個地方擋上馬，AK 一直是拿著瞄準的狀態，兩個都會碰到
// 1. 不在戰鬥中時，互動元件看到拿著十字弩就把互動吃掉（components.ws:139-157 IsCrossbowHeld → 回傳 true，馬收不到 OnInteraction）
//    （2026-10-16 18:09 實測：空手按 E → CanProcessInteractionInput true → 馬的 OnInteraction；拿著 AK 時到 CanProcessInteractionInput 就停了）
// 2. 玩家在戰鬥動作中時，"MountHorse" 被列入封鎖（interactionsManager.ws:111-114）
// → 上馬這一個互動：AK 拿著、不是真的攻擊時放行；戰鬥中照原版（看互動元件的 isEnabledInCombat）
@wrapMethod(CInteractionComponent)
function OnInteraction( actionName : string, activator : CEntity )
{
	if ( GetActionName() == "MountHorse" && theGame.GetInteractionsManager().GetActiveInteraction() == this
		&& thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsAkDrawn() && !thePlayer.IsInCombatAction_Attack()
		&& !( thePlayer.IsInCombat() && !thePlayer.IsSwimming() ) )
	{
		LogChannel( 'GFG', "mount interaction allowed with AK" );	// 暫時
		return false;
	}
	return wrappedMethod( actionName, activator );
}

@wrapMethod(CInteractionsManager)
function GetBlockedActions( out blockedActions : array< string > )
{
	wrappedMethod( blockedActions );
	if ( thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsAkDrawn() && !thePlayer.IsInCombatAction_Attack() )
		blockedActions.Remove( "MountHorse" );
}

@wrapMethod(CR4PlayerStateMountTheVehicle)
function OnEnterState( prevStateName : name )
{
	parent.GfgHolsterForVehicle();
	return wrappedMethod( prevStateName );
}

@wrapMethod(CPlayerStateDismountTheVehicle)
function OnEnterState( prevStateName : name )
{
	thePlayer.GfgHolsterForVehicle();
	return wrappedMethod( prevStateName );
}

// 暫時的偵測紀錄（第 3 項：騎馬換彈時瞄準鏡頭被關掉，查原因）：用不用瞄準鏡頭、相關狀態改變時記一行
@addField(CR4Player)
var gfgHorseCamLogged : string;

@addMethod(CR4Player)
function GfgHorseCamLog( mgr : W3VehicleCombatManager, aimCam : bool )
{
	var s : string;

	s = "aimCam=" + aimCam + " mgr=" + mgr.GetCurrentStateName() + " locked=" + IsCameraLockedToTarget() + " cbtAiming=" + vehicleCbtMgrAiming;
	if ( rangedWeapon )
		s += " ak=" + rangedWeapon.GetCurrentStateName() + " isAk=" + rangedWeapon.GfgIsAk();
	else
		s += " ak=none";
	if ( s != gfgHorseCamLogged )
	{
		LogChannel( 'GFG', "horseCam " + s );
		gfgHorseCamLogged = s;
	}
}

// 騎馬時拿著 AK、用原版瞄準鏡頭時（GfgSetHorseAimCam）：上下、左右的目標角度都設成現在的角度，後座力轉的角度才不會被拉回（docs/findings.md §24.6、§24.7）
// - 第一次實測：上下被拉回「地形角度 - 10」（horseRiding.ws:482-498、:514-526）；用原版瞄準鏡頭時這段整段跳過（useVehicle.ws:431-433 → horseRiding.ws:460-472）
// - 第二次實測：左右一直停在同一個角度，原因沒查到（🔶推測是自動轉回馬後方：horseRiding.ws:417-422；原版瞄準鏡頭會關掉它：:400-402）
// - 做法同原版走路時用十字弩瞄準：每格把目標角度設成現在的角度（aimThrow.ws:361、:371）
// 鎖定目標（Z）時不用瞄準鏡頭，照原版把鏡頭轉向目標（useVehicle.ws:435-466）
@wrapMethod(CR4PlayerStateHorseRiding)
function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	result = wrappedMethod( moveData, dt );
	if ( parent.gfgHorseAimCam )
	{
		moveData.pivotRotationController.SetDesiredHeading( moveData.pivotRotationValue.Yaw );
		moveData.pivotRotationController.SetDesiredPitch( moveData.pivotRotationValue.Pitch );
	}
	return result;
}

// 地面戰鬥中拿著 AK：上下、左右的目標角度也設成現在的角度（第 11 項）
// 原版的戰鬥鏡頭（選項 GetCmbtCamera：r4Player.ws:16259）每格把上下角度拉回 -12°＋高低差（combat.ws:571-595；沒有硬鎖定時）
// → 抬鏡頭瞄頭後，鏡頭 1 秒內自己掉回目標的腳邊，子彈跟著打低（2026-10-16 21:3x 實測，慢動作也一樣）
// 做法同上面的騎馬、原版按住中鍵瞄準（aimThrow.ws:361、:371）；硬鎖定（Z）時照原版
@wrapMethod(CR4PlayerStateCombat)
function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	result = wrappedMethod( moveData, dt );
	if ( parent.rangedWeapon && parent.rangedWeapon.GfgIsAkDrawn() && !parent.IsHardLockEnabled() )
	{
		moveData.pivotRotationController.SetDesiredHeading( moveData.pivotRotationValue.Yaw );
		moveData.pivotRotationController.SetDesiredPitch( moveData.pivotRotationValue.Pitch );
	}
	return result;
}

// 騎馬拿著 AK 時用原版按住中鍵瞄準的鏡頭（使用者 2026-10-14 選定；docs/findings.md §24.7）
// - 原版：按住中鍵時 aiming = true（useVehicle.ws:1660-1671），每格設給 vehicleCbtMgrAiming（:1734）、鏡頭往右 1.4、往上 0.15 公尺（:1749-1752）
// - vehicleCbtMgrAiming 為 true 時：馬的鏡頭不自動轉回馬的後方（horseRiding.ws:400-402），每格的後段只把距離設成 2.2 公尺就結束
//   （useVehicle.ws:431-433 → horseRiding.ws:460-472），不拉回上下角度、不跟著馬轉、不把左右偏移拉回 0（:583）
@addField(CR4Player)
var gfgHorseAimCam : bool;	// 這一格用原版瞄準鏡頭（vehicleCbtMgrAiming 是我們設的）

// 開的時候每格設（回到閒置時原版會清掉：useVehicle.ws:563）；關的時候只清自己設的。
// keepVanilla：原版射十字弩、丟炸彈時每格自己設 vehicleCbtMgrAiming（:1734），不去動它
@addMethod(CR4Player)
function GfgSetHorseAimCam( on : bool, optional keepVanilla : bool )
{
	if ( on )
		vehicleCbtMgrAiming = true;
	else if ( gfgHorseAimCam && !keepVanilla )
		vehicleCbtMgrAiming = false;
	gfgHorseAimCam = on;
}

// 騎馬時每格：扳機跟著左鍵、AK 拿著時不自動收槍、中鍵射完回到閒置、手臂瞄準、原版瞄準鏡頭
// 回傳 true：這一格用原版瞄準鏡頭
@addMethod(CR4Player)
function GfgHorseTick( mgr : W3VehicleCombatManager, out moveData : SCameraMovementData, dt : float ) : bool
{
	var mgrState : name;
	var pressed : bool;
	var localOffset : Vector;

	if ( !rangedWeapon || !rangedWeapon.GfgIsAk() )
	{
		gfgHorseAimOut = false;
		GfgSetHorseAimCam( false );
		return false;
	}

	// 扳機：閒置以外的狀態收不到左鍵的事件（只有 Null、SwordAttack 有 OnAttack：useVehicle.ws:706、:1123），
	// 所以每格直接讀左鍵（原版也這樣讀：:601）。放開一律放開扳機；按著時要 AK 拿在手上才扣（還沒拿出來時由 StartAttackAction 的包裝拿出）
	pressed = theInput.IsActionPressed( 'VehicleAttack' ) && inv.ItemHasTag( GetSelectedItemId(), 'gfg_ak47' );
	if ( rangedWeapon.gfgTriggerHeld && !pressed )
		rangedWeapon.GfgSetTrigger( false );
	else if ( !rangedWeapon.gfgTriggerHeld && pressed && rangedWeapon.GfgIsAkDrawn() )
		rangedWeapon.GfgSetTrigger( true );

	// 騎馬動畫圖一直當作瞄準中，不自動收槍（GfgKeepRiderAiming；原版射擊等也會把它設成 0，所以每格設）
	rangedWeapon.GfgKeepRiderAiming();

	if ( !rangedWeapon.GfgIsAkDrawn() )
	{
		gfgHorseAimOut = false;
		GfgSetHorseAimCam( false );
		return false;
	}

	mgrState = mgr.GetCurrentStateName();

	// 中鍵（原版）射完：原版要等十字弩收好才回到閒置（WaitForShootingComplete：useVehicle.ws:2113-2130），AK 不自動收，馬就會一直鎖著。
	// 射完、沒在用（同原版可以中止的條件：:1784-1788）、中鍵也放開了，就回到閒置（同 :2129）；AK 還拿著，下馬的鎖由十字弩收好時自己解（rangedWeapon.ws:56-61）
	if ( mgrState == 'ShootCrossbow' )
	{
		GfgSetHorseAimCam( false, true );
		if ( !rangedWeapon.IsWeaponBeingUsed() && !theInput.IsActionPressed( 'VehicleItemAction' ) )
			mgr.PopState( true );
		return false;
	}

	// 丟炸彈、施法、揮劍時用它們自己的那一組動畫（pc_rider.w2beh #2643）和鏡頭（丟炸彈的鏡頭同十字弩由原版設定：useVehicle.ws:1815、:2013、:1734）
	if ( mgrState == 'ThrowBomb' )
	{
		gfgHorseAimOut = false;
		GfgSetHorseAimCam( false, true );
		return false;
	}
	if ( mgrState == 'CastSign' || mgrState == 'SwordAttack' )
	{
		gfgHorseAimOut = false;
		GfgSetHorseAimCam( false );
		return false;
	}

	GfgHorseAimPose( moveData, dt );

	// 原版瞄準鏡頭：往右 1.4、往上 0.15 公尺（照抄 useVehicle.ws:1749-1752）
	GfgSetHorseAimCam( !IsCameraLockedToTarget() );
	if ( gfgHorseAimCam )
	{
		localOffset = Vector( 1.4, 0, 0.15f );
		DampVectorConst( moveData.cameraLocalSpaceOffset, localOffset, 4.f, dt );
	}
	return gfgHorseAimCam;
}

// 手臂瞄準的方向：照抄原版 ShootCrossbow 每格做的（RangedAttack.OnGameCameraTick 沒有按住中鍵瞄準的那一支：useVehicle.ws:1686-1739；
// 除錯球 :1698、船的 SailingPassive :1702、:1721、炸彈 :1712-1713 不抄）。
// 朝子彈飛的方向（GfgAimPoint）：Z 鎖定時朝鎖定點（GfgLockPoint），否則朝鏡頭的方向；actionType 設成十字弩那一組動畫（原版拿出時設定：:752）
// 原版沒按住中鍵時，畫面上有目標（GetDisplayTarget）就朝目標（:1686-1707），十字弩的箭也自動瞄準它；
// AK 的子彈一律飛向準心 → 2026-10-16 23:1x 實測：鏡頭朝正前方，附近有角色時槍朝左 48°，子彈卻往前飛 → 改成只在 Z 鎖定時朝目標
@addMethod(CR4Player)
function GfgHorseAimPose( moveData : SCameraMovementData, dt : float )
{
	var rot : EulerAngles;
	var headBoneIdx : int;
	var headPos, lockPoint : Vector;
	var horizontalVal, verticalVal : float;

	SetBehaviorVariable( 'actionType', (int)EHCA_ShootCrossbow );
	if ( GfgLockPoint( lockPoint ) )
	{
		SetOrientationTarget( OT_Actor );
		headBoneIdx = GetHeadBoneIndex();
		if ( headBoneIdx >= 0 )
			headPos = MatrixGetTranslation( GetBoneWorldMatrixByIndex( headBoneIdx ) );
		rot = VecToRotation( lockPoint - headPos );
		horizontalVal = AngleDistance( GetHeading(), rot.Yaw ) / 180.f;
		verticalVal = ClampF( rot.Pitch, -90.f, 90.f ) / -90.f;
	}
	else
	{
		rangedWeapon.ProcessCanAttackWhenNotInCombat();
		SetOrientationTarget( OT_Camera );
		horizontalVal = AngleDistance( GetHeading(), moveData.pivotRotationValue.Yaw ) / 180.f;
		verticalVal = ClampF( moveData.pivotRotationValue.Pitch, -90.f, 90.f ) / 90.f;
	}
	SetBehaviorVariable( 'aimHorizontal', GfgClampHorseAim( horizontalVal, dt ) );
	SetBehaviorVariable( 'aimVertical', verticalVal );
	theGame.GetGameCamera().EnableScreenSpaceCorrection( true );
}

// ===== 騎馬瞄準的左右範圍（第 18 項）=====
// 使用者 2026-10-16 20:4x：騎馬往後射「上半身轉 180、下半身不轉，不符合人體工學」
// 騎馬時骨盆跟著馬（覆蓋節點 pc_rider.w2beh #4423 只取 torso 以上），往後瞄準只能靠脊椎轉；坐在馬上肩膀最多轉約 80～90°
// 底層換成正面持槍後（瞄正前方時肩膀朝右 23.5°），往右 60°、往左 110° 時腰扭約 85°（tools/horse_pose.py 的差值，離線算）
// 超出範圍：姿勢停在邊界、不開火（GfgTryFire）、準心藏起來（GfgCameraTick）；回到範圍內恢復
// aimHorizontal = AngleDistance( 馬的朝向, 瞄準的方向 ) / 180（useVehicle.ws:1722）；負 = 左（水平差值第 45 格 = 往左 90°、對應 -0.5：tools/horse_pose.py）
// 鏡頭從背後繞到另一邊時，限制後的值會一格從左邊界跳到右邊界（170°）→ 上半身經過前方轉過去（每秒 360°），轉的期間也算超出範圍
@addField(CR4Player)
var gfgHorseAimOut : bool;		// 這一格騎馬瞄準超出左右範圍（或正在轉過去）

@addField(CR4Player)
var gfgHorseAimH : float;		// 上一格設給動畫的 aimHorizontal

@addField(CR4Player)
var gfgHorseAimSwing : bool;	// 正在從一邊轉到另一邊

@addMethod(CR4Player)
function GfgHorseAimLeft() : float
{
	return 110.f;
}

@addMethod(CR4Player)
function GfgHorseAimRight() : float
{
	return 60.f;
}

@addMethod(CR4Player)
function GfgClampHorseAim( horizontalVal : float, dt : float ) : float
{
	var target, step : float;

	target = ClampF( horizontalVal, -GfgHorseAimLeft() / 180.f, GfgHorseAimRight() / 180.f );
	if ( AbsF( target - gfgHorseAimH ) > 0.25f )		// 一格跳超過 45°：不是滑鼠轉的，是換邊
		gfgHorseAimSwing = true;
	if ( gfgHorseAimSwing )
	{
		step = 2.f * dt;
		if ( AbsF( target - gfgHorseAimH ) <= step )
		{
			gfgHorseAimH = target;
			gfgHorseAimSwing = false;
		}
		else if ( target > gfgHorseAimH )
			gfgHorseAimH += step;
		else
			gfgHorseAimH -= step;
	}
	else
		gfgHorseAimH = target;
	gfgHorseAimOut = target != horizontalVal || gfgHorseAimSwing;
	return gfgHorseAimH;
}

// 原版中鍵瞄準（ShootCrossbow 沿用 RangedAttack 的鏡頭更新，每格設 aimHorizontal：useVehicle.ws:1672-1740）拿著 AK 時：左右範圍同上
// 船（SailingPassive）、丟炸彈照原版
@wrapMethod(W3VehicleCombatManagerStateRangedAttack)
function OnGameCameraTick( out moveData : SCameraMovementData, timeDelta : float )
{
	var result : bool;

	result = wrappedMethod( moveData, timeDelta );
	if ( parent.GetCurrentStateName() == 'ShootCrossbow' && rider.GetCurrentStateName() == 'HorseRiding'
		&& rider.rangedWeapon && rider.rangedWeapon.GfgIsAk() )
	{
		horizontalVal = rider.GfgClampHorseAim( horizontalVal, timeDelta );
		rider.SetBehaviorVariable( 'aimHorizontal', horizontalVal );
	}
	return result;
}

// 騎馬時的動畫事件只交給戰鬥管理（horseRiding.ws:792-795），只有 ShootCrossbow 會再交給十字弩（useVehicle.ws:1757-1763、:2132-2134），閒置狀態不處理（:525）。
// AK 拿在左手時，其他狀態也交給十字弩，同地面（playerWitcher.ws:8094-8098）：換彈動畫中段的事件才會裝上新箭（rangedWeapon.ws:150-152）
@wrapMethod(CR4PlayerStateHorseRiding)
function OnAnimEvent_Throwable( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
{
	var result : bool;

	result = wrappedMethod( animEventName, animEventType, animInfo );
	if ( vehicleCombatMgr.GetCurrentStateName() != 'ShootCrossbow' && parent.rangedWeapon && parent.rangedWeapon.GfgIsAk()
		&& parent.inv.IsItemCrossbow( parent.inv.GetItemFromSlot( 'l_weapon' ) ) )
		parent.rangedWeapon.OnProcessThrowEvent( animEventName );
	return result;
}

// 離開騎馬時放開扳機：騎馬時扳機是每格讀左鍵（GfgHorseTick），離開後就不讀了，扣著的話下馬後拿出 AK 會自己開火
// 原版瞄準鏡頭也關掉（正常下馬前 AK 已經收好、已經關了；這裡是被打下馬等其他離開方式）
@wrapMethod(CR4PlayerStateHorseRiding)
function OnLeaveState( nextStateName : name )
{
	if ( parent.rangedWeapon && parent.rangedWeapon.gfgTriggerHeld )
		parent.rangedWeapon.GfgSetTrigger( false );
	parent.GfgSetHorseAimCam( false );
	return wrappedMethod( nextStateName );
}

// ===== 修正：馬上沒拿 AK 時法印輪盤一開就關（使用者 2026-10-14 選「開輪盤時清掉」；docs/findings.md §24.8、§24.9）=====
// 原版 Flash 的「按住」模擬：用 E 下馬時下馬提示先關掉、HUD 不再收按鍵，E 的放開收不到，E 一直被記成按著
// （HudModuleInteractions.as:138-145 不清；只有 InputManager.reset() 會清：InputManager.as:631-643）。
// 之後在馬上、下馬提示開著時，Flash 一直重送「E 按住」（:422-468），輪盤收到 E 就選定並關閉（HudModuleRadialMenu.as:845-849）。
// 開輪盤前用原版的 resetInput 清掉被記成按著的鍵（CoreComponent.as:61-64；HUD 模組也有：CoreHudModule.as:15）；
// 腳本的呼叫方式同原版 tutorialPopup.ws:42、:163。HUD 的模組共用同一個 InputManager（每次讀檔只建兩個：選單、HUD）
@wrapMethod(CR4HudModuleRadialMenu)
function ShowRadialMenu()
{
	var fxResetInput : CScriptedFlashFunction;

	if ( !m_shown )
	{
		fxResetInput = GetModuleFlash().GetMemberFlashFunction( "resetInput" );
		if ( fxResetInput )
			fxResetInput.InvokeSelf();
	}
	wrappedMethod();
}

// 弩箭發射：AK 的子彈改成飛向準心（畫面中央）指的點（原版是 GetLookAtPosition，最遠 25 公尺：playerBoltProjectile.ws:128-142）
@wrapMethod(W3BoltProjectile)
function ThrowProjectile( targetPosIn : Vector )
{
	var player : CR4Player;
	var target, rayStart, rayDir : Vector;

	target = targetPosIn;
	player = (CR4Player)GetOwner();
	if ( player && player.rangedWeapon && player.rangedWeapon.GfgIsAk() )
	{
		target = player.rangedWeapon.GfgAimPoint( rayStart, rayDir );
		gfgAimTarget = target;
		// 射程：發射時換成 AK 的射程（下面 ShootProjectileAtPosition／AtBone 的包裝）；水中照原版 5 公尺（playerBoltProjectile.ws:341-345）
		if ( !player.IsDiving() )
		{
			gfgAkRange = player.rangedWeapon.GfgRange();
			// 準心射線經過的角色（第 11 項）：有的話子彈用 AtBone 打那個角色（下面的包裝）
			GfgFindActorOnRay( rayStart, rayDir, VecDistance( rayStart, target ) );
		}
	}
	wrappedMethod( target );
}

// ===== 射程：AK 的箭飛到 208 公尺（GfgRange）（M2；使用者 2026-10-13 選定）=====
// 原版弩箭的射程是 MAX_THROW_RANGE 25 公尺（const，炸彈、飛刀也用：gameParams.ws:105），
// 在 ReleaseProjectiles2 傳給 ShootProjectileAtPosition／ShootProjectileAtBone（playerBoltProjectile.ws:341-349、:374-377）。
// 飛到射程時引擎呼叫 OnRangeReached：箭關掉特效，2 秒後刪掉（arrowProjectile.ws:36-45）。
// 這裡只換射程，其他參數照原版；鎖定時打骨骼的那條路（自動瞄準）也換
// （CCO 是整個 ReleaseProjectiles2 覆寫，射程乘上倍率：CCO playerBoltProjectile.ws:589-595）

@addField(W3AdvancedProjectile)
var gfgAkRange : float;		// AK 的箭發射時用的射程（公尺；ThrowProjectile 設定）；0 = 照原版（不是 AK 的箭、在水中）

@addField(W3AdvancedProjectile)
var gfgAimTarget : Vector;		// AK：準心的射線點（ThrowProjectile 包裝設定）
@addField(W3AdvancedProjectile)
var gfgHitActor : CActor;		// AK：準心射線經過的角色（ThrowProjectile 包裝設定；沒有 = NULL）
@addField(W3AdvancedProjectile)
var gfgHitPos : Vector;			// AK：打中的點（射線上離那根骨頭最近的點）
@addField(W3AdvancedProjectile)
var gfgHitNormal : Vector;		// AK：碰撞的法線（射線的反方向）

// 發射時要用的射程
@addMethod(W3AdvancedProjectile)
function GfgShotRange( range : float ) : float
{
	if ( gfgAkRange <= 0.f )
		return range;
	return gfgAkRange;
}

// AK 子彈的速度（公尺／秒；第 9、10 項）：真實 AK 的初速約 715；原版弩箭 projSpeed 60（bodkin_bolt.w2ent）；角度 0 = 直線
// 2026-10-16 19:2x 實測 715：打牆、打 10 公尺外的狼都命中正常
@addMethod(W3AdvancedProjectile)
function GfgBulletSpeed() : float
{
	if ( thePlayer.GfgDbgBulletSpeed() > 0.f )
		return thePlayer.GfgDbgBulletSpeed();
	return 715.f;
}

// 這兩個是 final 函式（advancedProjectile.ws:60-78）；包 final 函式有作用（StateEnter：docs/findings.md §17.8、§17.9）
// AK 的子彈一律 AtPosition（第 11 項）：
// - 準心射線經過角色（GfgFindActorOnRay）→ 射向打中的點，發射後立刻手動觸發碰撞（GfgManualHit）
//   角色身上沒有可靠的碰撞：AtBone 打頭、胸口會碰撞，打腳、小腿、骨盆會穿過去打到後面的地面（2026-10-16 21:1x 實測）
// - 沒有 → 射向射線點（牆、地面）
// 原版有目標時改用 AtBone 自動瞄準 torso2（playerBoltProjectile.ws:353-377；20:1x 實測：瞄頭也打在胸口同一點）→ AK 的子彈改走 AtPosition
@wrapMethod(W3AdvancedProjectile)
function ShootProjectileAtPosition( angle : float, velocity : float, target : Vector, optional range : float, optional collisionGroups : array<name> )
{
	var a, v, r : float;
	var tgt : Vector;

	a = angle;
	v = velocity;
	r = range;
	tgt = target;
	if ( gfgAkRange > 0.f )
	{
		a = 0.f;
		v = GfgBulletSpeed();
		r = GfgShotRange( range );
		if ( gfgHitActor )
			tgt = gfgHitPos;
	}
	wrappedMethod( a, v, tgt, r, collisionGroups );		// 不是 AK 的箭：參數照原版
	if ( gfgAkRange > 0.f && gfgHitActor )
		GfgManualHit();
}

@wrapMethod(W3AdvancedProjectile)
function ShootProjectileAtBone( angle : float, velocity : float, target : CEntity, targetBone : name, optional range : float, optional collisionGroups : array<name> )
{
	if ( gfgAkRange > 0.f )
	{
		ShootProjectileAtPosition( angle, velocity, gfgAimTarget, range, collisionGroups );		// 上面的包裝
		return;
	}
	wrappedMethod( angle, velocity, target, targetBone, range, collisionGroups );		// 不是 AK 的箭：照原版
}

// AK 的子彈打中角色：發射後立刻手動觸發碰撞（群組 Character、元件＝角色的移動元件，和原版子彈撞到角色時一樣：21:1x 紀錄）
// → 原版的處理：傷害（ProcessDamageAction）、打肉的聲音、子彈停下來刪掉（arrowProjectile.ws:225-243、playerBoltProjectile.ws:162-181）
// 不等子彈飛到：子彈一格畫面飛 12 公尺，同一格裡會先撞到人後面的地面（21:2x 實測：射程設成剛好到人，OnRangeReached 也來不及）；
// 715 公尺／秒飛 30 公尺只要 0.04 秒，等於瞬間命中
@addMethod(W3AdvancedProjectile)
function GfgManualHit()
{
	var actor : CActor;
	var groups : array< name >;

	actor = gfgHitActor;
	gfgHitActor = NULL;
	groups.PushBack( 'Character' );
	LogChannel( 'GFG', "manual hit " + actor.GetName() + " pos=" + VecToString( gfgHitPos ) + " active=" + isActive );		// 暫時（第 11 項）
	OnProjectileCollision( gfgHitPos, gfgHitNormal, actor.GetMovingAgentComponent(), groups, 0, 0 );
	LogChannel( 'GFG', "manual hit done active=" + isActive );		// 暫時（第 11 項）
}

// 暫時（第 11 項）
function GfgNamesDesc( names : array< name > ) : string
{
	var s : string;
	var i : int;

	for ( i = 0; i < names.Size(); i += 1 )
		s += NameToString( names[i] ) + ",";
	return s;
}

// 碰撞：AK 的子彈打到牆壁、地面時播火花（第 9 項）
// 原版的箭停下來、插著、排 5 秒後刪掉（arrowProjectile.ws:98-114、playerBoltProjectile.ws:182-203）；AK 的子彈看不見（OnProjectileShot 藏起模型），照原版刪
// （原本「AK 的箭插在牆上不刪」是使用者 2026-10-13 選的；改成子彈後插著的也看不見，拿掉）
@wrapMethod(W3BoltProjectile)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	var wasScheduled, result, hasComp : bool;
	var victimActor : CActor;

	wasScheduled = isScheduledForDestruction;
	if ( gfgAkRange > 0.f )
		LogChannel( 'GFG', "coll " + GfgCompDesc( collidingComponent ) + " groups=" + GfgNamesDesc( hitCollisionsGroups ) + " idx=" + actorIndex + " pos=" + VecToString( pos ) + " active=" + isActive );		// 暫時（第 11 項）
	result = wrappedMethod( pos, normal, collidingComponent, hitCollisionsGroups, actorIndex, shapeIndex );
	if ( gfgAkRange > 0.f && !wasScheduled && isScheduledForDestruction
		&& ( hitCollisionsGroups.Contains( 'Static' ) || hitCollisionsGroups.Contains( 'Terrain' ) ) )
	{
		PlayEffect( 'sparks' );
		LogChannel( 'GFG', "bullet sparks " + VecToString( pos ) );		// 暫時（第 9 項）
	}
	else if ( gfgAkRange > 0.f )
	{
		if ( collidingComponent )
		{
			hasComp = true;
			victimActor = (CActor)collidingComponent.GetEntity();
		}
		if ( victimActor )
			LogChannel( 'GFG', "bullet hit actor " + victimActor.GetName() + " hp=" + victimActor.GetHealth() + "/" + victimActor.GetMaxHealth() );		// 暫時（第 9、10 項）
		else
			LogChannel( 'GFG', "bullet hit comp=" + hasComp + " static=" + hitCollisionsGroups.Contains( 'Static' )
				+ " terrain=" + hitCollisionsGroups.Contains( 'Terrain' ) + " groups=" + hitCollisionsGroups.Size() + " was=" + wasScheduled + " now=" + isScheduledForDestruction );		// 暫時（第 9 項）
	}
	return result;
}

// ===== 子彈的樣子（第 9 項：使用者 2026-10-16「射出去的還是箭，不是子彈」）=====
// 原版的箭射出時播軌跡 defaultTrail（arrow_trail）＋破空聲（arrowProjectile.ws:19-34）；特效定義在弩箭共用模板 bolt_base.w2ent
// AK 的子彈：藏起箭的模型、關掉軌跡（2026-10-16 19:2x 實測）
// - 只藏 CMeshComponent：藏全部 CDrawableComponent 時，特效（CParticleComponent 也是 CDrawableComponent：CParticleComponent.ws:6）也看不到
// - 原版的軌跡（arrow_trail、_orange、_red、_fire、_mutation_9）在子彈的速度下看不到 → 不當曳光，關掉
@wrapMethod(W3ArrowProjectile)
function OnProjectileShot( targetCurrentPosition : Vector, optional target : CNode )
{
	var result : bool;
	var comps : array< CComponent >;
	var i : int;

	result = wrappedMethod( targetCurrentPosition, target );
	if ( gfgAkRange > 0.f )
	{
		comps = GetComponentsByClassName( 'CMeshComponent' );
		for ( i = 0; i < comps.Size(); i += 1 )
			((CDrawableComponent)comps[i]).SetVisible( false );
		StopActiveTrail();
	}
	return result;
}

// ===== 傷害（第 10 項：使用者 2026-10-16「傷害由 Claude 設計一個符合這遊戲的」）=====
// 原版的箭：箭（Bodkin Bolt：穿刺 5、銀 4：def_item_bolts.xml）＋十字弩的屬性，經過攻擊力、抗性（playerBoltProjectile.ws:57-77、damageManagerProcessor.ws:2692）
// 原版武器的傷害只看裝備、不隨等級變（2026-10-16 實測：AK 打 5 級的狼，Geralt 10 級、31 級都是 73.1）
// AK：每發的基礎傷害隨 Geralt 的等級增加（敵人的血量也隨等級增加 → 打同等級的敵人要幾發大致固定）；
// 爆頭 ×4（CS2 m_flHeadshotMultiplier）；距離衰減 ×0.98^(距離 / 12.7 公尺)（CS2 m_flRangeModifier：每 500 單位 ×0.98，1 單位 = 1 英吋）
// 攻擊名還是 'bolt'：原版弩的技能（解剖知識、爆頭的暴擊等）照樣有效；抗性照原版
@addField(W3BoltProjectile)
var gfgHeadHit : bool;		// 這發打在頭上（OnProjectileCollision 包裝裡判斷）

// ===== 準心射線經過哪個角色（第 11 項：使用者 2026-10-16「打不中是個大問題」）=====
// 角色對射線、子彈都沒有碰撞（2026-10-16 實測：RayCastSync 只回傳地面和牆；715、60 公尺／秒的子彈都從人身上穿過去，只有幾發打到小腿）；
// 原版的箭打得到人，是因為有目標時用 ShootProjectileAtBone 追著骨頭飛（playerBoltProjectile.ws:353-377）
// → 自己判斷：射線（鏡頭 → 打到的牆或地面）離角色最近的骨頭（FindNearestBoneToEdgeWS：components.ws:325；原版劍砍到哪根骨頭也這樣找：attackAction.ws:421）
//   在 GfgBodyRadius 內就算打中；發射後立刻手動觸發碰撞（GfgManualHit）
// 爆頭：射線離頭部骨頭（GetHeadBoneIndex：actor.ws:711，各種骨架都有）GfgHeadRadius 內
@addMethod(W3BoltProjectile)
function GfgFindActorOnRay( start, dir : Vector, maxDist : float )
{
	var ents : array< CGameplayEntity >;
	var actor : CActor;
	var anim : CAnimatedComponent;
	var a, b : Vector;
	var i, idx, bestIdx : int;
	var t, d, r, bestT, bestD, missD : float;
	var missActor : CActor;

	gfgHitActor = NULL;
	missD = 1000.f;
	gfgHeadHit = false;
	a = start;
	b = start + dir * maxDist;
	bestT = maxDist + 1.f;
	// 先粗選：鏡頭前方水平 120° 內、射線長度內的活著的角色（actorsStorage.ws:118）
	FindGameplayEntitiesInCone( ents, start, VecHeading( dir ), 120.f, maxDist + 2.f, 100, '', FLAG_OnlyAliveActors + FLAG_ExcludePlayer );
	for ( i = 0; i < ents.Size(); i += 1 )
	{
		actor = (CActor)ents[i];
		// 自己的馬、死掉、昏迷、友善的打不到（原版的規則：throwable.ws:110-131）
		if ( !actor || actor == GetOwner() || !CanCollideWithVictim( actor ) )
			continue;
		anim = actor.GetRootAnimatedComponent();
		if ( !anim )
			continue;
		idx = anim.FindNearestBoneToEdgeWS( a, b );
		if ( idx < 0 )
			continue;
		d = GfgRayBoneDist( actor, idx, a, dir, maxDist, t );
		r = GfgBodyRadius( actor );
		// 頭在最上面：射線從頭上方、旁邊經過時最近的骨頭是頭 → 用頭的大小判斷（2026-10-16 21:2x 實測：離頭 0.23 公尺被算成打中身體）
		if ( idx == actor.GetHeadBoneIndex() )
			r = GfgHeadRadius( actor );
		if ( d >= r && d < missD )
		{
			missD = d;
			missActor = actor;
		}
		if ( d < r && t < bestT )
		{
			gfgHitActor = actor;
			bestT = t;
			bestIdx = idx;
			bestD = d;
		}
	}
	if ( !gfgHitActor )
	{
		if ( missD < 2.f )
			LogChannel( 'GFG', "ray miss " + missActor.GetName() + " d=" + missD + " r=" + GfgBodyRadius( missActor ) + " capsule=" + GfgCapsuleRadius( missActor ) );		// 暫時（第 11 項）
		return;
	}
	gfgHitPos = a + dir * bestT;
	gfgHitNormal = -dir;
	idx = gfgHitActor.GetHeadBoneIndex();
	if ( idx >= 0 )
		gfgHeadHit = GfgRayBoneDist( gfgHitActor, idx, a, dir, maxDist, t ) < GfgHeadRadius( gfgHitActor );
	LogChannel( 'GFG', "ray hit " + gfgHitActor.GetName() + " idx=" + bestIdx + " d=" + bestD + " r=" + GfgBodyRadius( gfgHitActor ) + " t=" + bestT + " head=" + gfgHeadHit
		+ " headD=" + GfgRayBoneDist( gfgHitActor, gfgHitActor.GetHeadBoneIndex(), a, dir, maxDist, t ) );		// 暫時（第 11 項）
}

// 骨頭到射線（a 起、方向 dir、長 maxDist 的線段）的距離；t 傳回沿射線的位置
@addMethod(W3BoltProjectile)
function GfgRayBoneDist( actor : CActor, idx : int, a, dir : Vector, maxDist : float, out t : float ) : float
{
	var p : Vector;

	p = actor.GetBoneWorldPositionByIndex( idx );
	t = ClampF( VecDot( p - a, dir ), 0.f, maxDist );
	return VecDistance( p, a + dir * t );
}

// 身體的半徑：射線離最近的骨頭這麼近就算打中（骨頭是關節的位置，關節之間的身體也要算到）
// 人類 0.25 公尺（2026-10-16 21:2x 實測：腳到頭掃射都判斷正確）；大型怪物跟著碰撞膠囊放大（人類的膠囊半徑 0.35）
@addMethod(W3BoltProjectile)
function GfgBodyRadius( actor : CActor ) : float
{
	return 0.25f * MaxF( 1.f, GfgCapsuleRadius( actor ) / 0.35f );
}

@addMethod(W3BoltProjectile)
function GfgCapsuleRadius( actor : CActor ) : float
{
	var mac : CMovingPhysicalAgentComponent;

	mac = (CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent();
	if ( !mac )
		return 0.35f;
	return mac.GetCapsuleRadius();
}

// 頭的半徑：射線離頭部骨頭這麼近就算爆頭（大型怪物一樣跟著碰撞膠囊放大）
@addMethod(W3BoltProjectile)
function GfgHeadRadius( actor : CActor ) : float
{
	return 0.17f * MaxF( 1.f, GfgCapsuleRadius( actor ) / 0.35f );
}

@addMethod(W3BoltProjectile)
function GfgHeadHit() : bool
{
	return gfgHeadHit;
}

@addMethod(W3BoltProjectile)
function GfgIsAkBullet() : bool
{
	return gfgAkRange > 0.f;
}

@wrapMethod(W3DamageManager)
function ProcessAction( act : W3DamageAction )
{
	var bolt : W3BoltProjectile;

	bolt = (W3BoltProjectile)act.causer;
	if ( bolt && bolt.GfgIsAkBullet() && (W3Action_Attack)act )
		GfgSetAkDamage( act, bolt );
	wrappedMethod( act );
}

@addMethod(W3DamageManager)
function GfgSetAkDamage( act : W3DamageAction, bolt : W3BoltProjectile )
{
	var dmg, dist, perLevel, flat, dbgPer, dbgFlat : float;

	// 一發 ≈ 同等級裝備的劍輕攻擊的 45%（2026-10-16 19:5x 定，推算寫在 docs/m3.md「子彈、傷害」）
	// 經過原版流程後實際傷害 = 這個值 + 58（Geralt 本身的加成，不隨等級變：19:5x 實測 188.99 → 246.99）
	// 銀（打怪物的精華）多 25%：同等級的銀劍比鋼劍高；怪物每級 +270 精華、人類每級 +55 血（monster_base_abl_new.xml:44-47、opp_base_abl.xml:283-286）
	perLevel = 10.f;
	flat = 20.f;
	if ( thePlayer.GfgDbgDmg( dbgPer, dbgFlat ) )		// 暫時：主控台 gfgdmg 設的值
	{
		perLevel = dbgPer;
		flat = dbgFlat;
	}
	dmg = perLevel * GetWitcherPlayer().GetLevel() + flat;
	if ( act.GetIsHeadShot() || bolt.GfgHeadHit() )
	{
		dmg *= 4.f;
		act.SetHeadShot();		// 原版爆頭的暴擊加成、Headshot 事件（damageManagerProcessor.ws:847-851）
	}
	if ( act.attacker && act.victim )
	{
		dist = VecDistance( act.attacker.GetWorldPosition(), act.victim.GetWorldPosition() );
		dmg *= PowF( 0.98f, dist / 12.7f );
	}
	act.ClearDamage();
	act.AddDamage( theGame.params.DAMAGE_NAME_PIERCING, dmg );
	act.AddDamage( theGame.params.DAMAGE_NAME_SILVER, dmg * 1.25f );
	LogChannel( 'GFG', "ak dmg base=" + dmg + " head=" + act.GetIsHeadShot() + " dist=" + dist );		// 暫時（第 10 項）
}

// ===== 暫時（第 9 項調整用，做完拿掉）：主控台 gfgbullet(速度)：AK 子彈的速度（公尺／秒；0 = 用 GfgBulletSpeed 的預設）=====
@addField(CR4Player)
var gfgDbgSpeed : float;

@addMethod(CR4Player)
function GfgSetBulletDbg( speed : float )
{
	gfgDbgSpeed = speed;
	LogChannel( 'GFG', "bullet dbg speed=" + speed );
}

@addMethod(CR4Player)
function GfgDbgBulletSpeed() : float
{
	return gfgDbgSpeed;
}

exec function gfgbullet( speed : float )
{
	thePlayer.GfgSetBulletDbg( speed );
}

// 暫時（第 10 項設計傷害用，做完拿掉）：NPC 受到玩家攻擊時記下傷害（劍、子彈都記，拿來比較）
@wrapMethod(CNewNPC)
function OnTakeDamage( action : W3DamageAction )
{
	var attack : W3Action_Attack;
	var result : bool;
	var attackName : name;

	result = wrappedMethod( action );
	if ( action.attacker == thePlayer )
	{
		attack = (W3Action_Attack)action;
		if ( attack )
			attackName = attack.GetAttackName();
		LogChannel( 'GFG', "dmg " + GetName() + " lvl=" + GetLevel() + " vit=" + action.processedDmg.vitalityDamage + " ess=" + action.processedDmg.essenceDamage
			+ " attack=" + attackName + " head=" + action.GetIsHeadShot() + " crit=" + action.IsCriticalHit() + " hp=" + GetHealth() + "/" + GetMaxHealth() );
	}
	return result;
}

// 暫時（第 9、10 項測試用，做完拿掉）：玩家正前方 dist 公尺（預設 8）生一隻敵對、不會動的狼當靶子
// 不會動：CAIDoNothingAction 蓋過戰鬥 AI（同 DogNPC.ws:192-194）；敵對：同主控台 spawn（temp.ws:6932-6935）
// kind 1：人類、2：怪物；level > 0 時設等級（同主控台 spawn：temp.ws:6937-6940）
exec function gfgwolf( optional dist : float, optional kind : int, optional level : int )
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var pos, posTemp, normal : Vector;
	var rot : EulerAngles;
	var tree : IAIActionTree;

	if ( dist <= 0.f )
		dist = 8.f;
	if ( kind == 1 )
		template = (CEntityTemplate)LoadResource( 'fists' );		// 測試用的人類敵人（gameplay.xml：enemy_fists_easy.w2ent）
	else if ( kind == 2 )
		template = (CEntityTemplate)LoadResource( 'nekker' );		// 怪物（打精華、銀）
	else if ( kind == 3 )
		template = (CEntityTemplate)LoadResource( 'troll' );		// 大型怪物（第 11 項：骨頭間距大）
	else if ( kind == 4 )
		template = (CEntityTemplate)LoadResource( 'bies' );
	else if ( kind == 5 )
		template = (CEntityTemplate)LoadResource( 'golem' );
	else
		template = (CEntityTemplate)LoadResource( 'wolf' );
	pos = thePlayer.GetWorldPosition() + VecFromHeading( thePlayer.GetHeading() ) * dist;
	if ( theGame.GetWorld().StaticTrace( pos + Vector( 0, 0, 5 ), pos - Vector( 0, 0, 5 ), posTemp, normal ) )
		pos = posTemp;
	rot = thePlayer.GetWorldRotation();
	rot.Yaw += 180.f;
	npc = (CNewNPC)theGame.CreateEntity( template, pos, rot );
	if ( !npc )
	{
		LogChannel( 'GFG', "gfgwolf: spawn failed" );
		return;
	}
	npc.SetTemporaryAttitudeGroup( 'hostile_to_player', AGP_Default );
	if ( level > 0 )
		npc.SetLevel( level );
	tree = new CAIDoNothingAction in npc;
	tree.OnCreated();
	npc.ForceAIBehavior( tree, BTAP_AboveCombat );
	LogChannel( 'GFG', "gfgwolf at " + VecToString( pos ) + " lvl=" + npc.GetLevel() + " hp=" + npc.GetHealth() + "/" + npc.GetMaxHealth() );
}

// 暫時（第 10 項調整用，做完拿掉）：主控台 gfgdmg(每級, 固定)：AK 每發基礎傷害 = 每級 × Geralt 等級 + 固定（兩個都 0 = 用預設）
@addField(CR4Player)
var gfgDbgDmgPerLevel : float;
@addField(CR4Player)
var gfgDbgDmgFlat : float;

@addMethod(CR4Player)
function GfgSetDmgDbg( perLevel, flat : float )
{
	gfgDbgDmgPerLevel = perLevel;
	gfgDbgDmgFlat = flat;
	LogChannel( 'GFG', "dmg dbg perLevel=" + perLevel + " flat=" + flat );
}

@addMethod(CR4Player)
function GfgDbgDmg( out perLevel : float, out flat : float ) : bool
{
	perLevel = gfgDbgDmgPerLevel;
	flat = gfgDbgDmgFlat;
	return perLevel != 0.f || flat != 0.f;
}

exec function gfgdmg( perLevel, flat : float )
{
	thePlayer.GfgSetDmgDbg( perLevel, flat );
}

// 以下兩個表由 python -X utf8 tools/recoil_pattern.py --ws 產生
// 第 shot 發相對前一發往右幾度（shot 從 1 起算，超過資料長度回傳 0）
@addMethod(Crossbow)
function GfgRecoilKickRight( shot : int ) : float
{
	switch ( shot )
	{
		case 1: return 0.0000f;
		case 2: return -0.0057f;
		case 3: return 0.1345f;
		case 4: return 0.0568f;
		case 5: return -0.6643f;
		case 6: return -0.4560f;
		case 7: return -0.7079f;
		case 8: return 0.9111f;
		case 9: return 2.2679f;
		case 10: return 1.2503f;
		case 11: return -0.7254f;
		case 12: return 0.8777f;
		case 13: return 1.4474f;
		case 14: return 0.1316f;
		case 15: return -2.0068f;
		case 16: return -1.2548f;
		case 17: return -0.7720f;
		case 18: return -1.4349f;
		case 19: return -1.8820f;
		case 20: return 1.0298f;
		case 21: return -0.2740f;
		case 22: return 0.4636f;
		case 23: return 0.4884f;
		case 24: return -1.0950f;
		case 25: return -0.3705f;
		case 26: return 1.1509f;
		case 27: return 1.7798f;
		case 28: return 2.5425f;
		case 29: return 0.7770f;
	}
	return 0.f;
}

// 第 shot 發相對前一發往上幾度（shot 從 1 起算，超過資料長度回傳 0）
@addMethod(Crossbow)
function GfgRecoilKickUp( shot : int ) : float
{
	switch ( shot )
	{
		case 1: return 0.0000f;
		case 2: return 1.4016f;
		case 3: return 1.6146f;
		case 4: return 1.7194f;
		case 5: return 1.7850f;
		case 6: return 1.4950f;
		case 7: return 1.0682f;
		case 8: return 0.8146f;
		case 9: return -0.2707f;
		case 10: return 0.4928f;
		case 11: return 0.4220f;
		case 12: return 0.0933f;
		case 13: return -0.5133f;
		case 14: return 0.2887f;
		case 15: return 0.4325f;
		case 16: return 0.2915f;
		case 17: return 0.3100f;
		case 18: return -0.1525f;
		case 19: return -0.4638f;
		case 20: return 0.3013f;
		case 21: return -0.0084f;
		case 22: return 0.3190f;
		case 23: return 0.1128f;
		case 24: return -0.1513f;
		case 25: return 0.2904f;
		case 26: return 0.0329f;
		case 27: return -0.1465f;
		case 28: return -1.1404f;
		case 29: return 0.0106f;
	}
	return 0.f;
}

// 暫時（第 4 項的測試用；做完和其他暫時紀錄一起拿掉）：把玩家的馬傳送到面前 3 公尺、側面朝玩家
// reference_level 按 X 叫馬，馬生成了（editor.log：player_horse）卻跑不過來
exec function gfghorsehere()
{
	var horse : CEntity;
	var pos : Vector;

	horse = theGame.GetEntityByTag( 'playerHorse' );
	if ( !horse )
	{
		LogChannel( 'GFG', "gfghorsehere: no playerHorse" );
		return;
	}
	pos = thePlayer.GetWorldPosition() + VecFromHeading( thePlayer.GetHeading() ) * 3.f;
	horse.TeleportWithRotation( pos, EulerAngles( 0.f, thePlayer.GetHeading() + 90.f, 0.f ) );
	LogChannel( 'GFG', "gfghorsehere: " + VecToString( pos ) );
}
