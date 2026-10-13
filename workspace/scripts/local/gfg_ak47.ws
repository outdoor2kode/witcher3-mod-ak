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

	LogChannel( 'GFG', "AK reload check: shotCount=" + shotCount + " magazine=" + magazine + " ammo=" + previousAmmoItemName + " playReloadAnim=" + shouldPlayAnim );

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

@addMethod(Crossbow)
function GfgLoadedText() : string
{
	if ( deployedEnt )
		return "yes";
	return "no";
}

// 扣下／放開扳機
@addMethod(Crossbow)
function GfgSetTrigger( pressed : bool )
{
	var now : float;

	now = theGame.GetEngineTimeAsSeconds();
	gfgTriggerHeld = pressed;
	LogChannel( 'GFG', "trigger=" + pressed + " t=" + FloatToString( now ) + " state=" + GetCurrentStateName() + " loaded=" + GfgLoadedText() + " shotCount=" + shotCount );

	if ( pressed )
	{
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
		SetBehaviorGraphVariables( 'isAimingWeapon', false );
		SetBehaviorGraphVariables( 'isShootingWeapon', false );
		thePlayer.SetIsAimingCrossbow( false );
	}
}

@addMethod(Crossbow)
timer function GfgAutoFire( dt : float, id : int )
{
	GfgTryFire();
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

	// 連射時不收槍：移除原版的收槍計時器（同 rangedWeapon.ws:1367-1370）
	RemoveTimer( 'HolsterAfterDelay' );
	RemoveTimer( 'HolsterWhenMovingTimer' );
	ownerPlayer.SetBehaviorVariable( 'canHolsterAfterDelay', 0.f );
	ownerPlayer.SetBehaviorVariable( 'canHolsterAfterDelayHorse', 0.f );

	OnProcessThrowEvent( 'ProjectileThrow' );
	LogChannel( 'GFG', "auto fire: t=" + FloatToString( now ) + " shotCount=" + shotCount + " state=" + GetCurrentStateName() + " loaded=" + GfgLoadedText() );

	// 後座力：這一發開完，鏡頭開始轉向下一發的位置（之後每格轉一部分：GfgUpdateRecoil）
	GfgAddRecoil( now );

	// 彈匣打空（PlayOwnerReloadAnim 回傳 true，不會立刻裝箭）：觸發換彈動畫，同 rangedWeapon.ws:1690-1691
	if ( !deployedEnt )
	{
		RaiseOwnerGraphEvents( 'Crossbow_Reload', true );
		LogChannel( 'GFG', "magazine empty: Crossbow_Reload raised" );
	}
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

@addField(Crossbow)
var gfgTicksSinceShot : int;	// 上一發之後過了幾格畫面（寫 log 用）

@addField(Crossbow)
var gfgTicksMoved : int;		// 其中鏡頭有轉動的格數（寫 log 用：兩者相等，表示兩發之間鏡頭沒有停下來）

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

// 射線長度：CS2 m_flRange 8192 單位 ≈ 208 公尺（docs/ak47_params.md §6）
@addMethod(Crossbow)
function GfgRange() : float
{
	return 208.0;
}

// 開完一發：記下這一發的後座力，之後每格畫面轉一部分到鏡頭上（GfgUpdateRecoil）
@addMethod(Crossbow)
function GfgAddRecoil( now : float )
{
	var rot : EulerAngles;

	if ( now - gfgLastShotTime >= GfgRecoilResetTime() )
		gfgBurstShots = 0;
	gfgBurstShots += 1;
	gfgLastShotTime = now;

	// 這一發開火時：鏡頭的角度、後座力已經轉了多少（＝這一發偏離原本瞄準點多少）、上一發還沒轉完的部分、
	// 上一發之後鏡頭轉動的格數（ticks 和 moved 相等＝兩發之間每一格都有轉）
	rot = theGame.GetGameCamera().GetCameraWorldRotation();
	LogChannel( 'GFG', "recoil: burst=" + gfgBurstShots + " camera pitch=" + FloatToString( rot.Pitch ) + " yaw=" + FloatToString( rot.Yaw )
		+ " applied up=" + FloatToString( gfgRecoilUp ) + " right=" + FloatToString( gfgRecoilRight )
		+ " left up=" + FloatToString( gfgKickUp ) + " right=" + FloatToString( gfgKickRight )
		+ " ticks=" + gfgTicksSinceShot + " moved=" + gfgTicksMoved );
	gfgTicksSinceShot = 0;
	gfgTicksMoved = 0;

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
			if ( newMag == 0.f )
				LogChannel( 'GFG', "recoil recovered: " + FloatToString( theGame.GetEngineTimeAsSeconds() - gfgLastShotTime ) + "s after last shot" );
		}
	}

	gfgTicksSinceShot += 1;
	if ( stepUp != 0.f || stepRight != 0.f )
		gfgTicksMoved += 1;
}

// AK 是不是拿在手上（裝備中，而且不是收起、收槍中）
@addMethod(Crossbow)
function GfgIsAkDrawn() : bool
{
	return GfgIsAk() && GetCurrentStateName() != 'State_WeaponWait' && GetCurrentStateName() != 'State_WeaponHolster';
}

// 遊戲鏡頭的位置與視線方向（theGame.GetGameCamera()，r4Game.ws:261；customCamera.ws:110-112）
// - 位置要加上 GetCameraWorldOffset()：原版拍照模式取遊戲鏡頭的位置就是這樣寫（photomodeManager.ws:98-99）
// - 不用 theCamera：2026-10-13 實測，用它的位置與方向投影出的畫面中央不是 (0,0)（docs/findings.md §14.5）
@addMethod(Crossbow)
function GfgEyePosition() : Vector
{
	var cam : CCustomCamera;

	cam = theGame.GetGameCamera();
	return cam.GetCameraWorldPosition() + cam.GetCameraWorldOffset();
}

@addMethod(Crossbow)
function GfgViewDirection() : Vector
{
	return VecNormalize( RotForward( theGame.GetGameCamera().GetCameraWorldRotation() ) );
}

// 子彈的目標點：從鏡頭沿著視線方向（畫面中央＝準心）打射線，取最近的命中點；後座力已經轉到鏡頭上
// 寫法照原版 CalculateAimPosition（playerAiming.ws:553-616，碰撞群組 :33-49）；原版那個是 private，不能直接呼叫
@addMethod(Crossbow)
function GfgAimPoint() : Vector
{
	var dir, start, end, hit : Vector;
	var results : array<SRaycastHitResult>;
	var groups : array<name>;
	var i : int;
	var best : float;
	var found : bool;
	var ent : CEntity;
	var actor : CActor;
	var item : CItemEntity;

	dir = GfgViewDirection();
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

	if ( theGame.GetWorld().GetTraceManager().RayCastSync( start, end, results, groups ) )
	{
		for ( i = 0; i < results.Size(); i += 1 )
		{
			// 排除自己、自己的武器與箭、死亡或昏迷的角色（同 playerAiming.ws:583-585）
			// 打到地形等沒有元件的東西時 component 是空的（原版 playerAiming.ws:337 也有檢查）
			if ( results[i].component )
				ent = results[i].component.GetEntity();
			else
				ent = NULL;
			if ( ent == thePlayer || ent == this || ent == deployedEnt || (W3BoltProjectile)ent )
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

// 原版的準心只在中鍵瞄準時顯示（playerAiming.ws:187 打開、:683-686 AimCleanup 關掉）；
// 左鍵扳機不會進入瞄準（CheckGotoAimThrow 只看中鍵 ThrowItem：rangedWeapon.ws:1362），所以要自己打開
@addMethod(CR4Player)
function GfgUpdateCrosshair( drawn : bool )
{
	var hud : CR4ScriptedHud;
	var module : CR4HudModuleCrosshair;
	var aimingState : name;

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
			LogChannel( 'GFG', "crosshair shown: aiming state=" + aimingState );
		}
	}
	else if ( gfgCrosshairShown )
	{
		// 只關我們打開的，不影響原版丟炸彈、十字弩瞄準時的準心
		module.ShowElement( false, false );
		LogChannel( 'GFG', "crosshair hidden" );
	}
	gfgCrosshairShown = drawn;
	gfgAimingState = aimingState;
}

// 玩家鏡頭的每格更新：把後座力轉到鏡頭上、更新準心
// - 腰射時玩家在 Exploration／Combat 狀態，都會經 extendedMovable.ws:123 呼叫到這裡
//   中鍵瞄準（AimThrow 狀態）不會：aimThrow.ws:161-394 沒有呼叫上層；那時左鍵也不是扳機（input_qwerty.ini:466-484 沒有 BASE_ATTACK_LIGHT）
// - 直接改 moveData.pivotRotationValue：原版爬牆的鏡頭也是每格改這個值（explorationStateClimb.ws:2111-2135）；
//   2026-10-13 實測，改過的角度會保留，不會被拉回（docs/findings.md §14.4）
// - 方向：pitch 往上為正（swimming.ws:1401-1406：pitch < 0 是往下）；yaw 往左為正（r4Player.ws:16144-16145：右邊的點是 heading - 90）
@wrapMethod(CR4Player)
function OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
{
	var result, akDrawn : bool;
	var up, right : float;

	result = wrappedMethod( moveData, dt );
	akDrawn = false;
	if ( rangedWeapon )
	{
		rangedWeapon.GfgUpdateRecoil( dt, up, right );
		moveData.pivotRotationValue.Pitch += up;
		moveData.pivotRotationValue.Yaw -= right;
		akDrawn = rangedWeapon.GfgIsAkDrawn();
	}
	GfgUpdateCrosshair( akDrawn );
	return result;
}

// 弩箭發射：AK 的子彈改成飛向準心（畫面中央）指的點（原版是 GetLookAtPosition，最遠 25 公尺：playerBoltProjectile.ws:128-142）
@wrapMethod(W3BoltProjectile)
function ThrowProjectile( targetPosIn : Vector )
{
	var player : CR4Player;
	var target : Vector;
	var rx, ry : float;

	target = targetPosIn;
	player = (CR4Player)GetOwner();
	if ( player && player.rangedWeapon && player.rangedWeapon.GfgIsAk() )
	{
		target = player.rangedWeapon.GfgAimPoint();
		// 診斷：目標點投影到畫面的位置（畫面中央是 0,0：hud.ws:1864-1874）、鏡頭的位移長度、theCamera 和遊戲鏡頭的位置相差多遠
		theCamera.WorldVectorToViewRatio( target, rx, ry );
		LogChannel( 'GFG', "aim: distance=" + FloatToString( VecDistance( player.rangedWeapon.GfgEyePosition(), target ) )
			+ " screen=(" + FloatToString( rx ) + "," + FloatToString( ry ) + ")"
			+ " camOffset=" + FloatToString( VecLength( theGame.GetGameCamera().GetCameraWorldOffset() ) )
			+ " theCamera-gameCam=" + FloatToString( VecDistance( theCamera.GetCameraPosition(), player.rangedWeapon.GfgEyePosition() ) ) );
	}
	wrappedMethod( target );
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
