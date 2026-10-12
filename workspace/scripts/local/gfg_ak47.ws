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
	now = theGame.GetEngineTimeAsSeconds();
	if ( now < gfgNextShotTime )
		return;
	if ( now - gfgNextShotTime >= GfgCycleTime() )
		gfgNextShotTime = now;	// 剛按下，或中間停過：從現在起算
	gfgNextShotTime += GfgCycleTime();

	// 連射時不收槍：移除原版的收槍計時器（同 rangedWeapon.ws:1367-1370）
	RemoveTimer( 'HolsterAfterDelay' );
	RemoveTimer( 'HolsterWhenMovingTimer' );
	ownerPlayer.SetBehaviorVariable( 'canHolsterAfterDelay', 0.f );
	ownerPlayer.SetBehaviorVariable( 'canHolsterAfterDelayHorse', 0.f );

	OnProcessThrowEvent( 'ProjectileThrow' );
	LogChannel( 'GFG', "auto fire: t=" + FloatToString( now ) + " shotCount=" + shotCount + " state=" + GetCurrentStateName() + " loaded=" + GfgLoadedText() );

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
