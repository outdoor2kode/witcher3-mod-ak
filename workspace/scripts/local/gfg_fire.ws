// ===== 全自動：AK 是選用物品時，左鍵＝扳機（使用者 2026-10-12 選定）=====

@addField(Crossbow)
var gfgTriggerHeld : bool;

// 下一發的預定時間（引擎時間，秒）
@addField(Crossbow)
var gfgNextShotTime : float;

// 上一次檢查能不能開火的時間（引擎時間，秒）
@addField(Crossbow)
var gfgLastCheckTime : float;

// ===== 兩手握好槍才開火（第 26 項；使用者 2026-10-18：按左鍵時槍還在背上、還沒好好拿在手上就開火）=====
// 原版流程：拿出（State_WeaponDraw）→ 動畫圖進瞄準時就到瞄準狀態（OnWeaponAimStart：rangedWeapon.ws:98-103），這時兩手還在把槍拿到前面；
// 衝刺停下時槍從單手提著換回雙手、換彈結束時右手回到握把，也都在瞄準狀態裡。
// 判斷：右手（r_hand）到左手的武器骨頭（l_weapon，AK 掛在這裡）的距離（2026-10-18 遊戲裡量：docs/findings.md §34）
// - 兩手握槍 0.404～0.438 公尺：站、走、側移、騎馬、上下左右瞄準、近距離（2 公尺）、連射中都在這個範圍
// - 拿出途中 0.56～1.2；衝刺單手提槍 0.47～0.88（擺動時偶爾有一格剛好經過 0.43）→ 在範圍內超過一格（0.02 秒）才算握好
// - 地面：握好時槍管已經對準（偏 2～9°，和一直瞄準時一樣）；騎馬拿出：握好後槍還在轉向目標（偏 29° → 0.2 秒後 5°）→ 騎馬時握好後再等 0.2 秒
// 拿著 AK 時每格更新（GfgCameraTick），開火前也更新（中鍵瞄準 AimThrow 的鏡頭更新不呼叫父類別：aimThrow.ws:161）；收起來時清掉
@addField(Crossbow)
var gfgGripSince : float;	// 兩手開始握著槍的時間（引擎時間）；0 = 沒握著

@addMethod(Crossbow)
function GfgGripUpdate( gunDrawn : bool )
{
	var hand, weapon : int;
	var d : float;

	if ( !gunDrawn )
	{
		gfgGripSince = 0.f;
		return;
	}
	hand = ownerPlayer.GetBoneIndex( 'r_hand' );
	weapon = ownerPlayer.GetBoneIndex( 'l_weapon' );
	if ( hand < 0 || weapon < 0 )
		d = 0.42f;	// 找不到骨頭：不擋（不會發生；保險）
	else
		d = VecDistance( MatrixGetTranslation( ownerPlayer.GetBoneWorldMatrixByIndex( hand ) ),
			MatrixGetTranslation( ownerPlayer.GetBoneWorldMatrixByIndex( weapon ) ) );
	if ( d < 0.395 || d > 0.445 )
		gfgGripSince = 0.f;
	else if ( gfgGripSince <= 0.f )
		gfgGripSince = theGame.GetEngineTimeAsSeconds();
}

@addMethod(Crossbow)
function GfgGripReady() : bool
{
	var wait : float;

	GfgGripUpdate( true );
	if ( ownerPlayer.IsUsingVehicle() )
		wait = 0.2f;
	else
		wait = 0.02f;
	return gfgGripSince > 0.f && theGame.GetEngineTimeAsSeconds() - gfgGripSince >= wait;
}

// 射擊間隔（秒）：槍的規格表（AK：CS2 m_flCycleTime 0.1）
@addMethod(Crossbow)
function GfgCycleTime() : float
{
	var g : SGfgGunSpec;

	g = GfgSpec();
	return g.cycleTime;
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
	if ( crossbow && crossbow.GfgIsGun() )
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
	// 被打中的動作（全身）播放中，原版的保險計時器把它當成「攻擊中」收起十字弩（InputLockFailsafe：rangedWeapon.ws:458-466）
	// 2026-10-16 實測被狼咬：failsafe 呼叫 OnForceHolster( true, true )，當時 combatActionType 0、fullBodyAnimWeight 1、不能做戰鬥動作
	// → 拿著 AK、不是真的在攻擊（輕／重攻擊：r4Player.ws:12863-12877）時不收（第 2 項：狼群裡開槍要維持射擊姿勢）
	if ( gfgInFailsafe && GfgIsGunDrawn() && !thePlayer.IsInCombatAction_Attack() )
		return true;
	if ( GfgIsGun()&& GetCurrentStateName() != 'State_WeaponWait' )
		gfgHolsterRequested = true;
	return wrappedMethod( forceUpperBodyAnim, instant, dropItem );
}

@addField(RangedWeapon)
var gfgInFailsafe : bool;	// InputLockFailsafe 執行中（rangedWeapon.ws:445-487 會直接呼叫 OnForceHolster）

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
	if ( !GfgIsGunDrawn() )
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
	if ( !GfgIsGunDrawn() || ownerPlayer.IsSwimming() || ownerPlayer.GetCurrentStateName() == 'AimThrow' )
		return result;
	// 閃躲、翻滾中（第 29 項：GfgEvadeTick）：上半身
	if ( ownerPlayer.GfgGunEvading() )
	{
		setFullWeight = false;
		ownerPlayer.SetBehaviorVariable( 'fullBodyAnimWeight', 0.f );
		return false;
	}
	// 側移中（開槍中又在移動、戰鬥中朝目標移動）：全身瞄準，腳用側移、後退的動作（使用者 2026-10-16 回報上半身扭轉；GfgGunTurnTick）
	if ( ownerPlayer.gfgStrafing && !forceUpperBodyAnim )
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
	// 閃躲、翻滾中（第 29 項：GfgEvadeTick）：上半身圖一樣當作跑步，才不會選全身瞄準
	if ( player.GfgGunEvading() )
	{
		player.SetBehaviorVariable( 'playerMoveTypeForOverlay', (int)PMT_Run );
		return speed;
	}
	if ( speed <= 0.f || player.playerMoveType > PMT_Walk || !player.rangedWeapon || !player.rangedWeapon.GfgIsGunDrawn()
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
	if ( player && player.rangedWeapon && player.rangedWeapon.GfgIsGunDrawn() )
	{
		if ( !player.IsUsingVehicle() )
		{
			lookAtTarget = player.GfgGunLookAtPoint();
			lookAtTargetActive = 1.f;
		}
		lookAtTarget = player.GfgFixBackAim( lookAtTarget );
	}
	wrappedMethod( lookAtTargetActive, lookAtTarget );
}

// ===== 槍聲（第 22 項；2026-10-18）=====
// AK 自己的 SoundBank：tools/ak_soundbank.py 用 CS2 的槍聲（ak47_01、02、04）做的 gfg_ak47.bnk，事件 gfg_ak47_shot
// （同一時間只播一發，新的蓋掉舊的：同 CS2 的 Weapon_AK47.Single 的 instance_limit 1）
// - 載入：腳本載入 bank 照原版（突變的音效 PlayerAbilityManager.ws:4663-4666、套裝 playerWitcher.ws:11396-11401）；
//   還沒載入就同步載入（第二個參數 false），第一發就有聲音
// - 播放：玩家身上（CEntity.SoundEvent：entity.ws:302）
@addField(Crossbow)
var gfgShotBankLogged : bool;

@addMethod(Crossbow)
function GfgShotSound()
{
	if ( !theSound.SoundIsBankLoaded( "gfg_ak47.bnk" ) )
	{
		theSound.SoundLoadBank( "gfg_ak47.bnk", false );
		if ( !gfgShotBankLogged )
		{
			gfgShotBankLogged = true;
			LogChannel( 'GFG', "shot bank loaded: " + theSound.SoundIsBankLoaded( "gfg_ak47.bnk" ) );
		}
	}
	ownerPlayer.SoundEvent( "gfg_ak47_shot" );
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

	// 只有瞄準、射擊狀態才開火：
	// - 還沒拿出來、收槍中（Wait、Holster）
	// - 拿出中（Draw；第 26 項，使用者 2026-10-18：槍還在背上就開火）：AK 收在背上時箭（deployedEnt）一直裝著，
	//   拿出的流程是 State_WeaponDraw（rangedWeapon.ws:1108-1213）→ 動畫圖進瞄準時 OnWeaponAimStart（:98-103）→ State_WeaponAim
	// - 換彈中（Reload）：換彈動畫中段就裝上新箭（rangedWeapon.ws:150-152、338-363），
	//   換彈結束才把 shotCount 歸零（rangedWeapon.ws:697-703）；中間開火會打斷換彈
	if ( GetCurrentStateName() != 'State_WeaponAim' && GetCurrentStateName() != 'State_WeaponShoot' )
		return;

	// 兩手還沒握好槍：拿出、衝刺停下、換彈結束的過程（GfgGripUpdate）
	if ( !GfgGripReady() )
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

	// 船上、水裡不開槍（第 38 項）：扳機在上船、下水前就按著的情況
	if ( GfgNoFireHere( ownerPlayer ) )
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

	// 槍聲（第 22 項）
	GfgShotSound();

	// 後座力：這一發開完，鏡頭開始轉向下一發的位置（之後每格轉一部分：GfgUpdateRecoil）
	GfgAddRecoil( now );

	// 散布：這一發開完，開火累積量增加（之後每格衰減：GfgDecaySpread）；先算散布再累積，同 CSGODOT weapon.gd:703、:738-742
	gfgSpreadPenalty += GfgSpreadPerShot();

	// 彈匣打空（PlayOwnerReloadAnim 回傳 true，不會立刻裝箭）：觸發換彈動畫，同 rangedWeapon.ws:1690-1691
	if ( !deployedEnt )
		RaiseOwnerGraphEvents( 'Crossbow_Reload', true );
}

// 選用的物品是 AK，而且就是裝在遠程武器格的那把
// 主控台、物品欄換成別的十字弩時，選用物品可能還指著背包裡的 AK（10-19 實測）：
// 這時原版的中鍵用裝著的十字弩瞄準（playerInput.ws:3184），劍也照常 → 不能當成 AK
function GfgIsGunSelected( p : CR4Player ) : bool
{
	var w : W3PlayerWitcher;
	var id, equipped : SItemUniqueId;

	w = (W3PlayerWitcher)p;
	if ( !w )
		return false;
	id = p.GetSelectedItemId();
	if ( !p.inv.IsIdValid( id ) || !p.inv.ItemHasTag( id, 'gfg_gun' ) )
		return false;
	if ( !w.GetItemEquippedOnSlot( EES_RangedWeapon, equipped ) )
		return false;
	return equipped == id;
}

// 船上、水裡：拿 AK 時不開槍，左鍵、中鍵都沒有行為（第 38 項；使用者 2026-10-19：「在船上把滑鼠滾輪觸發射擊禁止，也禁止左鍵開槍。
//   在水裡也是禁止滾輪點擊射擊。也不准左鍵開槍」）
// 船上＝駕船、坐船（IsUsingBoat：actor.ws:6455-6462）；水裡＝游泳、潛水
// 只是站在船上（IsOnBoat：OnBoatTrigger，boat.ws:39-42）照陸地（第 40 項；使用者 2026-10-19：「沒有駕駛，只是站在船上，這要跟站在陸地上一樣行為」）
function GfgNoFireHere( p : CR4Player ) : bool
{
	return p.IsUsingBoat() || p.IsSwimming() || p.IsDiving();
}

// 目前選用的物品若是 AK，回傳它的物件（同 r4Player.ws:10712 的取法）
@addMethod(CPlayerInput)
function GfgSelectedGun() : Crossbow
{
	if ( !GfgIsGunSelected( thePlayer ) )
		return NULL;
	return (Crossbow)thePlayer.inv.GetItemEntityUnsafe( thePlayer.GetSelectedItemId() );
}

// 左鍵（輕攻擊，input_qwerty.ini:656）：AK 選用時改成扳機
@wrapMethod(CPlayerInput)
function OnCbtAttackWithAlternateLight( action : SInputAction )
{
	var ak : Crossbow;

	ak = GfgSelectedGun();
	if ( !ak )
		return wrappedMethod( action );

	// 船上、水裡：不拿出、不開槍（第 38 項）；放開照常清掉扳機
	if ( IsPressed( action ) && GfgNoFireHere( thePlayer ) )
		return true;

	if ( IsPressed( action ) )
	{
		thePlayer.GfgSetTriggerWanted( true );
		// 手上有劍：先收劍、收好再拿出 AK（GfgNoSwordTick）；直接拿出會變成單手拿 AK（第 19 項）
		if ( thePlayer.GfgSwordInHand() && !thePlayer.IsCrossbowHeld() )
		{
			thePlayer.GfgRequestGunRaise( true );
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
	if ( GfgSelectedGun() )
		return true;
	return wrappedMethod( action );
}

// 中鍵（使用物品 ThrowItem：legacy\base\input_qwerty.ini:225、:481-482；處理：playerInput.ws:3133-3328）：AK 選用時沒有行為
// （第 31 項；使用者 2026-10-18：「持槍射擊時，按下滑鼠滾輪，行為會是拿弩的行為，也就是單發射出箭矢……使按下滾輪沒有行為。
//   不要影響到原本持有弩的所有原有行為，這更改僅限於 AK47」）
// - 原版：按下 → 拿出、瞄準十字弩，放開 → 射一發（:3185-3214）；拿出時中鍵還按著 → 中鍵瞄準 AimThrow（CheckGotoAimThrow：rangedWeapon.ws:1362-1400）
//   → 按下、放開都擋掉；按下時把中鍵設成放開（同原版強制收十字弩：rangedWeapon.ws:208-209），CheckGotoAimThrow 讀到的就是沒按
// - 水中（游泳、潛水的中鍵也是 ThrowItem：input.settings 的 [Swimming]、[Diving]）也擋（第 38 項；原本照原版射一發：docs/findings.md §35.2）
// - 騎馬、駕船：中鍵是 VehicleItemAction，走下面 W3VehicleCombatManagerStateNull.StartItemAction 的包裝
// - 舒適操作模式按住替代施法鍵再按中鍵（施放亞克席法印：:3139-3146）照原版
@addMethod(CPlayerInput)
function GfgMiddleBlocked( action : SInputAction ) : bool
{
	if ( thePlayer.IsUsingVehicle() )
		return false;
	if ( GetIsAltSignCastingPressed() && theInput.GetMouserControllerScheme() == MouserControllerScheme_Comfort )
		return false;
	if ( !GfgSelectedGun() )
		return false;
	if ( IsPressed( action ) )
	{
		theInput.ForceDeactivateAction( 'ThrowItem' );
		theInput.ForceDeactivateAction( 'ThrowItemHold' );
	}
	return true;
}

@wrapMethod(CPlayerInput)
function OnCbtThrowItem( action : SInputAction )
{
	if ( GfgMiddleBlocked( action ) )
		return false;
	return wrappedMethod( action );
}

@wrapMethod(CPlayerInput)
function OnCbtThrowItemHold( action : SInputAction )
{
	if ( GfgMiddleBlocked( action ) )
		return false;
	return wrappedMethod( action );
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
