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
function GfgIsGunDrawn() : bool
{
	return GfgIsGun() && GetCurrentStateName() != 'State_WeaponWait' && GetCurrentStateName() != 'State_WeaponHolster';
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
	var gunDrawn : bool;
	var up, right : float;

	GfgHudTick();
	gunDrawn = false;
	if ( rangedWeapon )
	{
		rangedWeapon.GfgUpdateRecoil( dt, up, right );
		moveData.pivotRotationValue.Pitch += up;
		moveData.pivotRotationValue.Yaw -= right;
		gunDrawn = rangedWeapon.GfgIsGunDrawn();
		if ( gunDrawn )
		{
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
	if ( rangedWeapon )
		rangedWeapon.GfgGripUpdate( gunDrawn );	// 兩手握好槍才開火（第 26 項）
	if ( gunDrawn && !IsUsingVehicle() )
		GfgGunTurnTick();
	else
		GfgGunTurnReset();
	GfgArmsHoldTick( gunDrawn );
	GfgCarryTick( gunDrawn, dt );
	GfgMagTick( gunDrawn );		// 換彈時彈匣拿下來（第 8 項 B）
	GfgNoSwordTick();			// 不准拿劍、自動舉 AK（第 19 項）
	GfgUpdateCrosshair( gunDrawn && !( IsUsingVehicle() && gfgHorseAimOut ) );		// 騎馬瞄準超出左右範圍時藏起來（第 18 項）
	GfgEvadeTick( gunDrawn );	// 戰鬥中閃躲、翻滾（第 29 項）
	GfgReloadAimTick( gunDrawn );	// R 換彈時上半身圖當作瞄準中（第 33 項的修正）
}
