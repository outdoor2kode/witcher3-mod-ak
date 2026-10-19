// ===== 騎馬：左鍵開槍，行為和沒騎馬時一樣（使用者 2026-10-14 指定；docs/findings.md §24）=====
// 騎馬時左鍵是 VehicleAttack（legacy\base\input_qwerty.ini:313），由騎馬戰鬥管理處理：沒拿劍就拔劍、拿劍就揮砍（useVehicle.ws:706-779）。
// 原版騎馬射十字弩（中鍵）會讓戰鬥管理進入 ShootCrossbow 狀態（:744-758）；戰鬥管理不在閒置狀態時，
// 馬每格被鎖住速度，也不能跳、不能下馬（horse/states/exploration.ws:519-537、:970-971、:3007、:3047）。
// 使用者選「拿著 AK 時馬照常操作」（下馬還是要先收槍）：左鍵不進入 ShootCrossbow，戰鬥管理留在閒置狀態；
// 原本由 ShootCrossbow 做的兩件事改成自己做：手臂瞄準的方向（GfgHorseAimPose）、把動畫事件交給十字弩（OnAnimEvent_Throwable 的包裝）。
// 騎馬的動畫圖 pc_rider.w2beh：actionType（EVehicleCombatAction）選擇十字弩、炸彈、法印、揮劍哪一組動畫（#2643 → #2639 'Crossbow'），
// 十字弩那一組用 aimHorizontal、aimVertical 決定瞄準方向

// 閒置時按左鍵（OnAttack：useVehicle.ws:706-718；回到閒置時還按著：ShouldEnterNextState :601-604）：
// AK 選用時改成扳機，不拔劍、不揮劍（同地面的 OnCbtAttackWithAlternateLight）。船上：AK 選用時沒有行為（第 38 項），其他照原版
@wrapMethod(W3VehicleCombatManagerStateNull)
function StartAttackAction()
{
	var itemId : SItemUniqueId;
	var ak : Crossbow;

	itemId = rider.GetSelectedItemId();
	if ( !GfgIsGunSelected( rider ) )
	{
		wrappedMethod();
		return;
	}
	if ( !horseComp )
		return;

	ak = (Crossbow)rider.inv.GetItemEntityUnsafe( itemId );
	if ( !ak )
		return;
	// 手上有劍：先收劍、收好再拿出 AK（GfgNoSwordTick；第 19 項）
	if ( rider.GfgSwordInHand() && !rider.IsCrossbowHeld() )
	{
		rider.GfgRequestGunRaise( true );
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

// 閒置時按中鍵（OnItemAction：useVehicle.ws:615-689；回到閒置時還按著：ShouldEnterNextState :605-608）：
// 騎馬、AK 選用時沒有行為（第 31 項；左鍵開火：上面 StartAttackAction 的包裝）。原版會拿出十字弩、進入 ShootCrossbow，放開射一發（:744-758）
// 駕船也一樣（第 38 項；船上的中鍵 VehicleItemAction 也走這裡：OnItemAction :615-689）；炸彈照原版
@wrapMethod(W3VehicleCombatManagerStateNull)
function StartItemAction()
{
	if ( GfgIsGunSelected( rider ) )
		return;
	wrappedMethod();
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

// ===== 上下馬（船也是）：開始時拿著 AK 就立刻收到背上（第 4 項）=====
// 原版拿著十字弩不能上下馬（rangedWeapon.ws:1145-1146）；左手的可用物品（火把等）上馬時也是直接收（mountHorse.ws:21 HideUsableItem）
// 上馬、上船都經過 MountTheVehicle.OnEnterState（mountHorse.ws:19、mountBoat.ws 的 super.OnEnterState）；下馬、下船都經過 DismountTheVehicle.OnEnterState（dismountHorse.ws:24）
// 收法同跳進水裡（CExplorationStateJump 的包裝）
@addMethod(CR4Player)
function GfgHolsterForVehicle()
{
	if ( rangedWeapon && rangedWeapon.GfgIsGunDrawn() )
		OnRangedForceHolster( true, true );
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
		&& thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsGunDrawn() && !thePlayer.IsInCombatAction_Attack()
		&& !( thePlayer.IsInCombat() && !thePlayer.IsSwimming() ) )
		return false;
	return wrappedMethod( actionName, activator );
}

@wrapMethod(CInteractionsManager)
function GetBlockedActions( out blockedActions : array< string > )
{
	wrappedMethod( blockedActions );
	if ( thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsGunDrawn() && !thePlayer.IsInCombatAction_Attack() )
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
	if ( parent.rangedWeapon && parent.rangedWeapon.GfgIsGunDrawn() && !parent.IsHardLockEnabled() )
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

	if ( !rangedWeapon || !rangedWeapon.GfgIsGun() )
	{
		gfgHorseAimOut = false;
		GfgSetHorseAimCam( false );
		return false;
	}

	// 扳機：閒置以外的狀態收不到左鍵的事件（只有 Null、SwordAttack 有 OnAttack：useVehicle.ws:706、:1123），
	// 所以每格直接讀左鍵（原版也這樣讀：:601）。放開一律放開扳機；按著時要 AK 拿在手上才扣（還沒拿出來時由 StartAttackAction 的包裝拿出）
	pressed = theInput.IsActionPressed( 'VehicleAttack' ) && GfgIsGunSelected( this );
	if ( rangedWeapon.gfgTriggerHeld && !pressed )
		rangedWeapon.GfgSetTrigger( false );
	else if ( !rangedWeapon.gfgTriggerHeld && pressed && rangedWeapon.GfgIsGunDrawn() )
		rangedWeapon.GfgSetTrigger( true );

	// 騎馬動畫圖一直當作瞄準中，不自動收槍（GfgKeepRiderAiming；原版射擊等也會把它設成 0，所以每格設）
	rangedWeapon.GfgKeepRiderAiming();

	if ( !rangedWeapon.GfgIsGunDrawn() )
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
		&& rider.rangedWeapon && rider.rangedWeapon.GfgIsGun() )
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
	if ( vehicleCombatMgr.GetCurrentStateName() != 'ShootCrossbow' && parent.rangedWeapon && parent.rangedWeapon.GfgIsGun()
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
