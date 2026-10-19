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
	if ( rangedWeapon && rangedWeapon.GfgIsAkDrawn() )
		return true;
	return GfgIsAkSelected( this );
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
	if ( ( weaponType == PW_Steel || weaponType == PW_Silver ) && GfgNoSwordMode()
		&& !( sheatheIfAlreadyEquipped && GetCurrentMeleeWeaponType() == weaponType ) )
		return true;
	return wrappedMethod( weaponType, ignoreActionLock, sheatheIfAlreadyEquipped );
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
			if ( IsInCombat() )
			{
				OnEquipMeleeWeapon( PW_Fists, true );
				GfgRequestAkRaise( false );
			}
			else
				OnEquipMeleeWeapon( PW_None, true );
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

// ===== 戰鬥中閃躲、翻滾（第 29 項；使用者 2026-10-18：「戰鬥時應該要能翻滾，閃避(維持跟持劍時一樣的戰鬥可執行選項)」）=====
// 上半身動畫圖（pc_overlay）的瞄準姿勢：戰鬥動作中（isInCombatActionForOverlay：player.ws:1520）一律全身瞄準（#18960：docs/findings.md §20.10）
// → 閃躲、翻滾（也是戰鬥動作：combat.ws:1134-1146、:1424-1436）被全身瞄準的姿勢蓋掉，人站著不動（10-19 實測；AK 收起來時翻滾正常）
// 拿著 AK 閃躲中：上半身圖改走「上半身」那支（同推移動鍵時）→ 身體照閃躲動畫
// - isInCombatActionForOverlay：原版只在戰鬥動作開始、結束時設（player.ws:1505-1521）→ 閃躲中每格設 0，結束時照原版的值還原
// - playerMoveTypeForOverlay：原版每格設（locomotionDirectController.ws:1095）→ CalculateMoveSpeed 的包裝裡設成跑步
// - fullBodyAnimWeight：原版每 0.1 秒設（rangedWeapon.ws:1285）→ ProcessFullBodyAnimWeight 的包裝裡設 0
// 閃躲動畫快結束時（動畫事件 AllowBlend）有移動、沒在瞄準就收槍（上半身圖 WeaponAim → WeaponHolster：#21321）；
// AK 收好後不會再自動舉起（10-19 實測）→ 閃躲中、結束後 0.3 秒，上半身圖的 isAimingWeapon 當作 1（十字弩自己的值不動，之後照它還原）
@addField(CR4Player)
var gfgEvadeOverlay : bool;	// 上面這幾個值現在是閃躲用的

@addField(CR4Player)
var gfgEvadeUntil : float;		// 閃躲（含結束後一小段）到這個時間

@addMethod(CR4Player)
function GfgAkEvading() : bool
{
	return gfgEvadeOverlay && rangedWeapon && rangedWeapon.GfgIsAkDrawn();
}

@addMethod(Crossbow)
function GfgAimingFlag() : bool
{
	return isAimingWeapon;
}

@addMethod(CR4Player)
function GfgEvadeTick( akDrawn : bool )
{
	var now : float;
	var cat : int;

	now = theGame.GetEngineTimeAsSeconds();
	cat = (int)GetBehaviorVariable( 'combatActionType' );
	// 閃躲、翻滾都是 CAT_Dodge（翻滾另設 isRolling：combat.ws:1424-1427）
	if ( akDrawn && ( IsCurrentlyDodging() || ( IsInCombatAction() && ( cat == (int)CAT_Dodge || cat == (int)CAT_Roll ) ) ) )
		gfgEvadeUntil = now + 0.3f;
	if ( akDrawn && now < gfgEvadeUntil )
	{
		if ( !gfgEvadeOverlay )
		{
			gfgEvadeOverlay = true;
			rangedWeapon.GfgRefreshFullBody();
		}
		SetBehaviorVariable( 'isInCombatActionForOverlay', 0.f );
		SetBehaviorVariable( 'isAimingWeapon', 1.f );
	}
	else if ( gfgEvadeOverlay )
	{
		gfgEvadeOverlay = false;
		SetBehaviorVariable( 'isInCombatActionForOverlay', (float)IsInCombatAction() );
		if ( rangedWeapon )
		{
			SetBehaviorVariable( 'isAimingWeapon', (float)rangedWeapon.GfgAimingFlag() );
			rangedWeapon.GfgRefreshFullBody();
		}
	}
}
