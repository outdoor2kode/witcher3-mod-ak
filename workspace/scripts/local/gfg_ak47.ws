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
	if ( GfgIsAk() && GetCurrentStateName() != 'State_WeaponWait' )
		gfgHolsterRequested = true;
	return wrappedMethod( forceUpperBodyAnim, instant, dropItem );
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
	if ( result && GfgIsAkDrawn() && !ownerPlayer.bLAxisReleased
		&& !ownerPlayer.IsSwimming() && ownerPlayer.GetCurrentStateName() != 'AimThrow' )
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
		lookAtTarget = player.GfgFixBackAim( lookAtTarget );
	wrappedMethod( lookAtTargetActive, lookAtTarget );
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
	if ( gfgKeepAkOnJump )
		return true;
	return wrappedMethod( forceUpperBodyAnim, instant, dropItem );
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
@addMethod(Crossbow)
function GfgAimPoint() : Vector
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
			rangedWeapon.GfgCancelAutoHolster();
			// Z 鎖定（硬鎖定）：十字弩瞄準狀態的 Lock() 會鎖住 EIAB_HardLock（rangedWeapon.ws:374-423；按 Z 時檢查：playerInput.ws:3510），
			// AK 一直待在瞄準狀態 → 一直鎖著。只解除這一個（使用者 2026-10-14 選定；docs/findings.md §20.7）；沒有這個鎖時直接返回（playerInput.ws:251-254）
			UnblockAction( EIAB_HardLock, 'RangedWeapon' );
		}
	}
	GfgUpdateCrosshair( akDrawn );
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
	GfgLogMatrix( "player", GetLocalToWorld() );
	GfgLogBone( this, "l_weapon", 'l_weapon' );
	GfgLogBone( this, "l_hand", 'l_hand' );
	GfgLogBone( this, "r_hand", 'r_hand' );
	GfgLogBone( this, "r_weapon", 'r_weapon' );
	GfgLogBone( this, "l_foot", 'l_foot' );	// 跑步、走路時腿有沒有在動
	GfgLogBone( this, "r_foot", 'r_foot' );
	GfgLogMatrix( "ak", rangedWeapon.GetLocalToWorld() );
	GfgLogBone( rangedWeapon, "ak_handle", 'handle' );
	LogChannel( 'GFG', "pose camera eye " + VecToStringPrec( rangedWeapon.GfgEyePosition(), 4 ) + " dir " + VecToStringPrec( rangedWeapon.GfgViewDirection(), 4 ) );
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
		return true;
	return result;
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
		GfgSetHorseAimCam( false, true );
		return false;
	}
	if ( mgrState == 'CastSign' || mgrState == 'SwordAttack' )
	{
		GfgSetHorseAimCam( false );
		return false;
	}

	GfgHorseAimPose( moveData );

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
// 畫面上有目標（不是自己的馬）時朝目標，否則朝鏡頭的方向；actionType 設成十字弩那一組動畫（原版拿出時設定：:752）
@addMethod(CR4Player)
function GfgHorseAimPose( moveData : SCameraMovementData )
{
	var rot : EulerAngles;
	var headBoneIdx : int;
	var headPos : Vector;
	var horizontalVal, verticalVal : float;

	SetBehaviorVariable( 'actionType', (int)EHCA_ShootCrossbow );
	if ( GetDisplayTarget() && GetDisplayTarget() != GetUsedVehicle() )
	{
		SetOrientationTarget( OT_Actor );
		headBoneIdx = GetHeadBoneIndex();
		if ( headBoneIdx >= 0 )
			headPos = MatrixGetTranslation( GetBoneWorldMatrixByIndex( headBoneIdx ) );
		rot = VecToRotation( GetLookAtPosition() - headPos );
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
	SetBehaviorVariable( 'aimHorizontal', horizontalVal );
	SetBehaviorVariable( 'aimVertical', verticalVal );
	theGame.GetGameCamera().EnableScreenSpaceCorrection( true );
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
	var target : Vector;

	target = targetPosIn;
	player = (CR4Player)GetOwner();
	if ( player && player.rangedWeapon && player.rangedWeapon.GfgIsAk() )
	{
		target = player.rangedWeapon.GfgAimPoint();
		// 射程：發射時換成 AK 的射程（下面 ShootProjectileAtPosition／AtBone 的包裝）；水中照原版 5 公尺（playerBoltProjectile.ws:341-345）
		if ( !player.IsDiving() )
			gfgAkRange = player.rangedWeapon.GfgRange();
		// 原版自動瞄準的條件：鎖定的目標是 NPC、有戰鬥音樂、沒在中鍵瞄準（playerBoltProjectile.ws:353-354），成立時箭會改射向那個 NPC 的身體
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

// 發射時要用的射程
@addMethod(W3AdvancedProjectile)
function GfgShotRange( range : float ) : float
{
	if ( gfgAkRange <= 0.f )
		return range;
	return gfgAkRange;
}

// 這兩個是 final 函式（advancedProjectile.ws:60-78）；包 final 函式有作用（StateEnter：docs/findings.md §17.8、§17.9）
@wrapMethod(W3AdvancedProjectile)
function ShootProjectileAtPosition( angle : float, velocity : float, target : Vector, optional range : float, optional collisionGroups : array<name> )
{
	wrappedMethod( angle, velocity, target, GfgShotRange( range ), collisionGroups );
}

@wrapMethod(W3AdvancedProjectile)
function ShootProjectileAtBone( angle : float, velocity : float, target : CEntity, targetBone : name, optional range : float, optional collisionGroups : array<name> )
{
	wrappedMethod( angle, velocity, target, targetBone, GfgShotRange( range ), collisionGroups );
}

// 碰撞：AK 的箭插在牆壁、地面上時改成不限時間（GfgAddStuckBolt）
@wrapMethod(W3BoltProjectile)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	var wasScheduled, result : bool;
	var player : CR4Player;

	wasScheduled = isScheduledForDestruction;
	result = wrappedMethod( pos, normal, collidingComponent, hitCollisionsGroups, actorIndex, shapeIndex );

	// 插在牆壁、地面上：原版停下來、排 5 秒後刪掉（arrowProjectile.ws:98-114、playerBoltProjectile.ws:182-203）；
	// AK 的箭取消這個刪除，交給玩家身上的清單管數量（使用者 2026-10-13 選定）；打在角色身上的照原版
	if ( gfgAkRange > 0.f && !wasScheduled && isScheduledForDestruction
		&& ( hitCollisionsGroups.Contains( 'Static' ) || hitCollisionsGroups.Contains( 'Terrain' ) ) )
	{
		player = (CR4Player)GetOwner();
		if ( player )
		{
			RemoveTimer( 'TimeDestroy' );
			player.GfgAddStuckBolt( this );
		}
	}
	return result;
}

// ===== 插在牆壁、地面上的 AK 箭：不限時間，最多 GfgMaxStuckBolts() 支，超過就從最舊的開始刪（使用者 2026-10-13 選定）=====

@addField(CR4Player)
var gfgStuckBolts : array<W3BoltProjectile>;	// 插在牆壁、地面上的 AK 箭，舊的在前面

// 最多幾支（可調）
@addMethod(CR4Player)
function GfgMaxStuckBolts() : int
{
	return 100;
}

// 寫法照原版 RemoveDroppedItem（actor.ws:4758-4779）：邊走訪邊 Erase，刪實體前先確認還在
@addMethod(CR4Player)
function GfgAddStuckBolt( bolt : W3BoltProjectile )
{
	var i : int;

	// 已經不在的先移出清單
	i = 0;
	while ( i < gfgStuckBolts.Size() )
	{
		if ( gfgStuckBolts[i] )
			i += 1;
		else
			gfgStuckBolts.Erase( i );
	}

	gfgStuckBolts.PushBack( bolt );
	while ( gfgStuckBolts.Size() > GfgMaxStuckBolts() )
	{
		gfgStuckBolts[0].Destroy();
		gfgStuckBolts.Erase( 0 );
	}
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
