// ===== AK 用自己的一套動畫圖（第 25 項；2026-10-18）=====
// 原版十字弩要完全照原版（使用者 2026-10-18：AK 的改動不能影響十字弩）：
// AK 的 84 段動畫改名成 gfg_（不再同名蓋過原版），原版的 4 張動畫圖各做一份播 AK 動畫的複本（tools/ak_graphs.py）。
// 裝上 AK 時把玩家這 4 個 slot 的圖換成複本、重新建立實例；換成別的十字弩（或沒有）時換回原版。
// 玩家的 slot 都在 runtimeBehaviorInstanceSlots（geralt_player.w2ent 的 CAnimBehaviorsParam），
// 腳本改了 slot 的圖，實例重新建立時就用新的圖（2026-10-18 遊戲實測：docs/findings.md §34）

// i：0 上半身（一直在堆疊最上面）、1 主動畫圖、2 騎馬、3 游泳
function GfgGunGraphSlot( i : int ) : name
{
	switch ( i )
	{
		case 0: return 'PlayerOverlay';
		case 1: return 'Gameplay';
		case 2: return 'VehicleHorse';
		default: return 'PlayerSwimming';
	}
}

// 同 tools/ak_graphs.py 的 GRAPHS
function GfgGunGraphPath( i : int ) : string
{
	switch ( i )
	{
		case 0: return "dlc\gunforgeralt\data\behaviors\gfg_overlay.w2beh";
		case 1: return "dlc\gunforgeralt\data\behaviors\gfg_gameplay.w2beh";
		case 2: return "dlc\gunforgeralt\data\behaviors\gfg_rider.w2beh";
		default: return "dlc\gunforgeralt\data\behaviors\gfg_swimming.w2beh";
	}
}

// 換掉 slot 的圖，回傳原本的圖（沒有這個 slot 時 NULL）
@addMethod(CAnimatedComponent)
function GfgSwapSlotGraph( slotName : name, graph : CBehaviorGraph ) : CBehaviorGraph
{
	var i : int;
	var old : CBehaviorGraph;

	for ( i = 0; i < runtimeBehaviorInstanceSlots.Size(); i += 1 )
	{
		if ( runtimeBehaviorInstanceSlots[i].instanceName == slotName )
		{
			old = runtimeBehaviorInstanceSlots[i].graph;
			runtimeBehaviorInstanceSlots[i].graph = graph;
			return old;
		}
	}
	return NULL;
}

@addField(CR4Player)
var gfgGunGraphsOn : bool;			// slot 現在是 AK 的圖

@addField(CR4Player)
var gfgGunGraphs : array< CBehaviorGraph >;		// GfgGunGraphPath 的 4 張

@addField(CR4Player)
var gfgVanillaGraphs : array< CBehaviorGraph >;	// 第一次換掉時記下的原版

@addMethod(CR4Player)
function GfgGunGraphsWanted() : bool
{
	var witcher : W3PlayerWitcher;
	var id : SItemUniqueId;

	witcher = (W3PlayerWitcher)this;
	if ( !witcher || !witcher.GetItemEquippedOnSlot( EES_RangedWeapon, id ) )
		return false;
	return inv.ItemHasTag( id, 'gfg_ak47' );
}

@addMethod(CR4Player)
function GfgApplyGunGraphs( on : bool )
{
	var comp : CAnimatedComponent;
	var i : int;
	var old, want : CBehaviorGraph;
	var base : name;
	var rebuildBase : bool;

	comp = GetRootAnimatedComponent();
	if ( !comp )
		return;
	if ( gfgGunGraphs.Size() == 0 )
	{
		for ( i = 0; i < 4; i += 1 )
		{
			gfgGunGraphs.PushBack( (CBehaviorGraph)LoadResource( GfgGunGraphPath( i ), true ) );
			gfgVanillaGraphs.PushBack( NULL );
			if ( !gfgGunGraphs[i] )
				LogChannel( 'GFG', "AK graph not found: " + GfgGunGraphPath( i ) );
		}
	}
	base = GetBehaviorGraphInstanceName( 0 );
	rebuildBase = false;
	for ( i = 0; i < 4; i += 1 )
	{
		if ( !gfgGunGraphs[i] )
			continue;
		if ( on )
			want = gfgGunGraphs[i];
		else
			want = gfgVanillaGraphs[i];
		if ( !want )
			continue;
		old = comp.GfgSwapSlotGraph( GfgGunGraphSlot( i ), want );
		if ( on && old && old != gfgGunGraphs[i] )
			gfgVanillaGraphs[i] = old;
		if ( i > 0 && old != want && base == GfgGunGraphSlot( i ) )
			rebuildBase = true;
	}
	gfgGunGraphsOn = on;

	// 重新建立用到的實例：上半身一直都在；底層是主動畫圖、騎馬、游泳的其中一個時也重建（劇情等其他圖不動）。
	// 同名的實例已經在堆疊裡時，ActivateBehaviorsSync 不會重建（實測）→ 先拆再掛；底層先掛、上半身後掛，順序同原本
	DetachBehavior( 'PlayerOverlay' );
	if ( rebuildBase )
	{
		DetachBehavior( base );
		AttachBehaviorSync( base );
	}
	AttachBehaviorSync( 'PlayerOverlay' );
	LogChannel( 'GFG', "AK graphs " + on + ": rebuilt base " + rebuildBase + ", stack " + GetBehaviorGraphInstanceName( 0 ) + " " + GetBehaviorGraphInstanceName( 1 ) + " " + GetBehaviorGraphInstanceName( 2 ) );
}

// 每 0.1 秒檢查裝的是不是 AK（物品欄換裝備時遊戲暫停，關掉後第一次檢查就換）
@addMethod(CR4Player)
timer function GfgGunGraphTimer( dt : float, id : int )
{
	if ( gfgGunGraphsOn != GfgGunGraphsWanted() )
		GfgApplyGunGraphs( !gfgGunGraphsOn );
}

@wrapMethod(W3PlayerWitcher)
function OnSpawned( spawnData : SEntitySpawnData )
{
	AddTimer( 'GfgGunGraphTimer', 0.1f, true );
	return wrappedMethod( spawnData );
}

// ===== 物品欄預覽人物：AK 用自己的展示動畫（第 24 項；2026-10-18）=====
// 原版：物品欄裡裝上十字弩類時送 DrawCrossbow_Inv（inventoryMenu.ws:2441-2442；外觀選單 transmogMenu.ws:311-312），
// 預覽人物 Inventory slot 的圖（pc_inventory.w2beh）播左手單手拿十字弩的 5 段展示動畫 → AK 的擺法是雙手持槍的：槍口朝下、槍托穿過前臂。
// AK：Inventory slot 換成 gfg_inventory.w2beh（tools/ak_graphs.py：同一張圖，5 段換成 tools/inv_pose.py 做的雙手低持）。
// 預覽人物生成時（實例建立前：inventoryMenu.ws:399-409）和送十字弩的事件前，照玩家遠程武器格是不是 AK 換圖；送事件前換了圖就重建實例。

// 讀 slot 的圖（不換）
@addMethod(CAnimatedComponent)
function GfgSlotGraph( slotName : name ) : CBehaviorGraph
{
	var i : int;

	for ( i = 0; i < runtimeBehaviorInstanceSlots.Size(); i += 1 )
	{
		if ( runtimeBehaviorInstanceSlots[i].instanceName == slotName )
			return runtimeBehaviorInstanceSlots[i].graph;
	}
	return NULL;
}

@addField(CR4Player)
var gfgInvGraphs : array< CBehaviorGraph >;	// 0 原版 pc_inventory（看到時記下）、1 AK 的 gfg_inventory

// 預覽人物 Inventory slot 的圖照遠程武器格換；換了回傳 true
@addMethod(CR4Player)
function GfgPreviewGraph( preview : CEntity ) : bool
{
	var comp : CAnimatedComponent;
	var cur, want : CBehaviorGraph;

	if ( !preview )
		return false;
	comp = preview.GetRootAnimatedComponent();
	if ( !comp )
		return false;
	cur = comp.GfgSlotGraph( 'Inventory' );
	if ( !cur )
		return false;
	if ( gfgInvGraphs.Size() == 0 )
	{
		gfgInvGraphs.PushBack( NULL );
		gfgInvGraphs.PushBack( (CBehaviorGraph)LoadResource( "dlc\gunforgeralt\data\behaviors\gfg_inventory.w2beh", true ) );
		if ( !gfgInvGraphs[1] )
			LogChannel( 'GFG', "inventory graph not found" );
	}
	if ( !gfgInvGraphs[1] )
		return false;
	if ( cur != gfgInvGraphs[1] )
		gfgInvGraphs[0] = cur;
	if ( GfgGunGraphsWanted() )
		want = gfgInvGraphs[1];
	else
		want = gfgInvGraphs[0];
	if ( !want || want == cur )
		return false;
	comp.GfgSwapSlotGraph( 'Inventory', want );
	LogChannel( 'GFG', "preview graph AK " + ( want == gfgInvGraphs[1] ) );
	return true;
}

// 送十字弩的事件前：換了圖就重建 Inventory 的實例（同 OnGuiSceneEntitySpawned 的寫法）
function GfgRebuildPreview( preview : CEntity )
{
	var arr : array< name >;

	if ( !thePlayer.GfgPreviewGraph( preview ) )
		return;
	preview.DetachBehavior( 'Inventory' );
	arr.PushBack( 'Inventory' );
	preview.ActivateBehaviorsSync( arr );
	((CActor)preview).SetBehaviorMimicVariable( 'gameplayMimicsMode', (float)(int)PGMM_Inventory );
}

@wrapMethod(CR4InventoryMenu)
function OnGuiSceneEntitySpawned( entity : CEntity )
{
	thePlayer.GfgPreviewGraph( entity );
	return wrappedMethod( entity );
}

@wrapMethod(CR4InventoryMenu)
function PlayPaperdollAnimation( category : name )
{
	if ( category == 'crossbow' )
		GfgRebuildPreview( m_player );
	wrappedMethod( category );
}

@wrapMethod(CR4TransmogMenu)
function OnGuiSceneEntitySpawned( entity : CEntity )
{
	thePlayer.GfgPreviewGraph( entity );
	return wrappedMethod( entity );
}

@wrapMethod(CR4TransmogMenu)
function PlayPaperdollAnimation( category : name )
{
	if ( category == 'crossbow' )
		GfgRebuildPreview( m_player );
	wrappedMethod( category );
}

// 彈匣：原版射滿 shotCountLimit（預設 1）就播換彈動畫（rangedWeapon.ws:830-852），
// AK 改成射滿彈匣才播；沒播動畫時，原版會立刻裝上下一支箭（rangedWeapon.ws:276-297）。
// 不採用原版 S_Perk_17 多一發的規則。
@wrapMethod(Crossbow)
function PlayOwnerReloadAnim() : bool
{
	var magazine : int;
	var shouldPlayAnim : bool;

	if ( !GfgIsGun() )
		return wrappedMethod();

	magazine = GfgMagazineSize();

	if ( shotCount >= magazine )
		shouldPlayAnim = true;
	// 以下兩個條件照抄原版（rangedWeapon.ws:838-841）：特殊箭用完、第一次裝填
	// AK 的子彈（第 27 項）和原版的無限箭一樣不算特殊箭；不加的話每發都換彈（GetSpecialAmmoCount 不算無限的：rangedWeapon.ws:854-869）
	else if ( previousAmmoItemName != 'Bodkin Bolt' && previousAmmoItemName != 'Harpoon Bolt' && !GfgIsGunAmmoName( previousAmmoItemName ) && GetSpecialAmmoCount() <= 0 )
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

// 主動換彈（第 33 項；R：CPlayerInput.OnCbtAttackWithAlternateHeavy 的包裝）：彈匣沒滿、拿在手上（瞄準、射擊狀態）、兩手握好、
// 沒衝刺、不在空中 → 丟掉槍上裝好的那發，走打空時同一條路（GfgTryFire 最後：isWeaponLoaded = false、Crossbow_Reload）：
// 原版接著 OnWeaponReloadStart → State_WeaponReload（rangedWeapon.ws:75-79），換彈動畫中段 OnWeaponReload 裝上新的一發（:81-94、:338-363），
// 結束時 shotCount 歸零（:697-703）＝滿 30 發。原版的 ClearDeployedEntity 只刪停下來的箭（:532-539）→ 自己刪
@addMethod(Crossbow)
function GfgManualReload() : bool
{
	if ( !GfgIsGun() || !deployedEnt || shotCount <= 0 )
		return false;
	if ( GetCurrentStateName() != 'State_WeaponAim' && GetCurrentStateName() != 'State_WeaponShoot' )
		return false;
	if ( !GfgGripReady() )
		return false;
	if ( ownerPlayer.IsUsingVehicle() || ownerPlayer.GetIsSprinting() || ownerPlayer.IsInAir() )
		return false;
	deployedEnt.Destroy();
	deployedEnt = NULL;
	ownerPlayer.GfgReloadAimStart();
	SetBehaviorGraphVariables( 'isWeaponLoaded', false );
	RaiseOwnerGraphEvents( 'Crossbow_Reload', true );
	return true;
}

// ===== 上半身朝哪裡、身體轉向（使用者 2026-10-16 回報：往鏡頭方向跑、身體轉向時上半身轉、下半身沒轉 → 扭曲）=====
// 原版上半身瞄準的點由朝向目標決定（UpdateLookAtTarget：r4Player.ws:2752-2876）；電腦版把「朝角色前方」OT_Player 一律換成「朝鏡頭」OT_Camera（r4Player.ws:5238-5246），
// 附近有敵人時是 OT_Actor（朝滑動目標：:2822-2868）→ 拿 AK 移動時上半身一直朝鏡頭或狼，往鏡頭跑時扭到背後（docs/findings.md §21 只限制了角度）。
// AK 改成：
// - 移動、沒在開槍：上半身朝角色前方（同原版 OT_Player：:2766-2784），不扭
// - 站著、或開槍中：上半身朝準心（Z 鎖定時朝鎖定點）；身體轉向準心（GfgGunTurnTick）

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
function GfgGunLookAtPoint() : Vector
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
var gfgStrafing : bool;		// 側移中：開槍中又在移動（身體朝準心），或戰鬥中朝目標移動（同持劍）；全身瞄準，腳用側移、後退的動作

@addField(CR4Player)
var gfgStrafeHeading : float;	// 側移時身體朝的方向（UpdateRequestedDirectionVariables 的包裝也用）

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

// 戰鬥中移動時朝哪裡（第 20 項，使用者 2026-10-18：「持劍走入怪物群，即便按下 S 後退時，不會整個人往後走，而是一直面對怪物。我認為持槍時也該仿照這樣」）
// 照原版持劍：移動控制器在朝向目標是 OT_Actor 時，把動畫圖的面向設成「朝目標」（locomotionDirectController.ws:1166-1213）；
// 只有附近有敵人（PCS_AlertNear）、格擋中目標夠近、或法印鎖定時才朝目標，否則朝角色自己的方向。
// 遊戲裡量（2026-10-18，[GFG] face 紀錄）：持劍戰鬥中（CombatSteel、AlertNear）8 個方向都朝著狼走（約 2.4 公尺／秒）；衝刺、不在戰鬥中則朝移動方向
// 不看朝向目標本身：拿十字弩時十字弩會自己加一個朝向目標（rangedWeapon.ws:878-891：開槍時準心附近沒有目標就是 OT_Camera），
// 移動中不更新、一直留著（:479-485 只在站著時更新）→ 2026-10-18 實測開槍後一直是 OT_Camera。所以直接照原版 OT_Actor 那一支的條件判斷
// 另外：目標死了不朝它（原版沒有這個條件；原版目標死了會換目標）
@addMethod(CR4Player)
function GfgCombatFaceHeading( out heading : float ) : bool
{
	var target : CGameplayEntity;
	var actor : CActor;
	var targetPos, toTarget : Vector;
	var boneIndex : int;
	var stance : EPlayerCombatStance;

	target = GetTarget();
	if ( !target )
		target = moveTarget;
	if ( !target )
		return false;
	actor = (CActor)target;
	if ( actor )
	{
		if ( !actor.IsAlive() )
			return false;
		GetNearestTargetablePositionToPlayer( actor, targetPos, boneIndex );
		toTarget = targetPos - GetWorldPosition();
	}
	else
		toTarget = target.GetWorldPosition() - GetWorldPosition();
	stance = GetPlayerCombatStance();
	if ( stance == PCS_AlertNear
		|| ( stance == PCS_Guarded && VecLength( toTarget ) < findMoveTargetDist )
		|| ( IsActorLockedToTarget() && !IsHardLockEnabled() ) )
	{
		heading = VecHeading( toTarget );
		return true;
	}
	return false;
}

// 每格（走路，AK 拿著時）：身體轉向準心
// - 做法同原版中鍵瞄準：角度差超過門檻就用 SetCustomRotation 轉向鏡頭的方向（aimThrow.ws:268-305；SetCustomRotation：r4Player.ws:5086-5105）
// - 側移（開槍中又在移動：一直朝準心；戰鬥中沒開槍：一直朝目標，同持劍）：上半身動畫圖改用全身瞄準（ProcessFullBodyAnimWeight 的包裝）→ 腳用側移、後退的動作
//   （上半身動畫圖 #18428 的 DirectionalMovement；原版中鍵瞄準移動時就是全身瞄準：rangedWeapon.ws:968-969）
//   衝刺、不在戰鬥中（沒開槍）照原版朝移動方向（同持劍）
@addMethod(CR4Player)
function GfgGunTurnTick()
{
	var aimHeading, diff, strafeHeading : float;
	var firing, moving, strafe : bool;

	aimHeading = VecHeading( GfgCrosshairPoint() - GetWorldPosition() );
	diff = AngleDistance( aimHeading, GetHeading() );
	firing = rangedWeapon.GfgIsFiring();
	moving = !bLAxisReleased;

	strafe = false;
	if ( moving && !GetIsSprinting() && !IsInAir() && !IsSwimming() && GetCurrentStateName() != 'AimThrow' )
	{
		if ( firing )
		{
			strafe = true;
			strafeHeading = aimHeading;
		}
		else
			strafe = GfgCombatFaceHeading( strafeHeading );
	}
	if ( strafe != gfgStrafing )
	{
		gfgStrafing = strafe;
		rangedWeapon.GfgRefreshFullBody();
		// 實驗：上半身動畫圖的全身瞄準狀態機（#18428）從起始狀態直接進入移動的條件要 inAimThrow（#19444、#20031）；原版中鍵瞄準時設定（rangedWeapon.ws:1395-1396）
		SetBehaviorVariable( 'inAimThrowForOverlay', (float)strafe );
	}

	if ( strafe )
	{
		gfgStrafeHeading = strafeHeading;
		gfgTurning = false;
		GfgSetWalkInPlace( false );
		SetCustomRotation( 'GfgGunAim', strafeHeading, 0.f, 0.25f, false );
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
		SetCustomRotation( 'GfgGunAim', aimHeading, 0.f, 0.4f, false );
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
function GfgGunTurnReset()
{
	if ( gfgStrafing )
	{
		gfgStrafing = false;
		if ( rangedWeapon )
			rangedWeapon.GfgRefreshFullBody();
		SetBehaviorVariable( 'inAimThrowForOverlay', 0.f );
	}
	gfgTurning = false;
	GfgSetWalkInPlace( false );
}

// 側移中，上半身動畫圖收到的速度改成要求的速度（同原版中鍵瞄準：locomotionDirectController.ws:316-327）
// 原版平常是實際速度不到 0.5 公尺／秒就給 0（:333-342）：全身瞄準時腳的動作來自上半身動畫圖，速度 0 → 腳不動 → 實際速度一直是 0（docs/findings.md §20 卡住的原因之一）
@wrapMethod(CR4LocomotionPlayerControllerScript)
function UpdateLocomotion()
{
	wrappedMethod();
	if ( player.gfgStrafing && moveSpeed > 0.f )
		player.SetBehaviorVariable( 'playerSpeedForOverlay', moveSpeed, true );
}

// 側移中，動畫圖的「面向」改成身體實際朝的方向（GfgGunTurnTick 轉過去的方向）
// 側移的動作依「移動方向 − 面向」挑（上半身動畫圖 DirectionalMovement 的輸入 requestedMovementDirectionForOverlay、requestedFacingDirectionForOverlay：docs/m3.md「開槍中側移」）；
// 原版的面向：戰鬥中朝目標、平常朝鏡頭（locomotionDirectController.ws:1142-1225 → actor.ws:3580-3587）→ 戰鬥中開槍時身體朝準心、面向卻是目標，挑錯動作
@wrapMethod(CActor)
function UpdateRequestedDirectionVariables( headingYawWS : float, orientationYawWS : float )
{
	var player : CR4Player;

	player = (CR4Player)this;
	if ( player && player.gfgStrafing )
		orientationYawWS = player.gfgStrafeHeading;
	wrappedMethod( headingYawWS, orientationYawWS );
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
function GfgArmsHoldTick( gunDrawn : bool )
{
	var on : bool;

	on = gunDrawn && !IsUsingVehicle() && ( IsInAir() || substateManager.GetStateCur() == 'Land' );	// 衝刺不蓋：手照原版擺（GfgCarryTick）
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
function GfgCarryTick( gunDrawn : bool, dt : float )
{
	var want : bool;
	var lw, pm, m : Matrix;
	var lx, ly, lz, px, py, pz, qx, qy, qz : Vector;
	var f0, u0, r0, fw, uw, gf, gu, ft, ut, rt, fl, ul, rl, piv, t : Vector;

	if ( !rangedWeapon || !gunDrawn )
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

// ===== R 換彈時上半身圖當作瞄準中（第 33 項的修正；2026-10-19 收尾測試發現）=====
// 現象：按 R 換完彈後，跑步時上半身變回原版十字弩的拿法（左手提著、槍口朝下）；收槍再拿出就好；打空自動換彈沒有這個問題
// 原因（docs/findings.md §36.2）：上半身圖（pc_overlay）瞄準 → 換彈的轉移要「彈匣空了」而且 isAimingWeapon 或 isShootingWeapon 是 1
// （#17296、#21254）；打空時扳機按著（isShootingWeapon 1）會轉過去，按 R 時兩個都是 0 → 上半身圖沒進換彈，只有腳本和全身那張圖換
// → 按 R 起到換彈狀態結束後 0.3 秒，上半身圖的 isAimingWeapon 當作 1（同閃躲：GfgEvadeTick），之後照十字弩自己的值還原
@addField(CR4Player)
var gfgReloadAim : bool;

@addField(CR4Player)
var gfgReloadAimUntil : float;

@addMethod(CR4Player)
function GfgReloadAimStart()
{
	gfgReloadAim = true;
	gfgReloadAimUntil = theGame.GetEngineTimeAsSeconds() + 1.0f;	// 換彈狀態還沒開始時最多等 1 秒
	SetBehaviorVariable( 'isAimingWeapon', 1.f );
}

@addMethod(CR4Player)
function GfgReloadAimTick( gunDrawn : bool )
{
	var now : float;

	if ( !gfgReloadAim )
		return;
	now = theGame.GetEngineTimeAsSeconds();
	if ( gunDrawn && rangedWeapon && rangedWeapon.GetCurrentStateName() == 'State_WeaponReload' )
		gfgReloadAimUntil = now + 0.3f;
	if ( gunDrawn && now < gfgReloadAimUntil )
	{
		SetBehaviorVariable( 'isAimingWeapon', 1.f );
		return;
	}
	gfgReloadAim = false;
	if ( rangedWeapon )
		SetBehaviorVariable( 'isAimingWeapon', (float)rangedWeapon.GfgAimingFlag() );
}
