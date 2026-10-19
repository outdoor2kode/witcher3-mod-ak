// ===== 右下角的操作提示：拿著 AK 時加「收槍」「換彈」（第 32、33 項；使用者 2026-10-18：「增加持有槍枝時可執行指令說明，
//       目前持有槍枝後畫面右下角可執行動作為衝刺跳躍和專注。增加一個 C 收槍」；換彈的鍵「也記得加入畫面右下角」）=====
// 原版 CR4HudModuleControlsFeedback.SendInputContextActions（hudModuleControlsFeedback.ws:216-769）依按鍵情境列出動作，
// 每項一個 KeyBindingData（:540-560）→ SetFlashArray（:764）；值存放區讀不回來 → AK 拿在手上時，原版列完後整份重做蓋掉：
// - 探索：原版那幾項（衝刺、跳躍、獵魔感官：:277-299；條件用原版剛設好的欄位）＋換彈（R）＋收槍（C：SwordSheathe）＋叫馬（有空格才列）
// - 戰鬥：射擊（左鍵）、換彈、閃躲、法印、收槍（原版的輕擊、重擊：:372-386，拿 AK 時不對）
// 拿出、收起 AK 時重做（GfgHudTick，每格）
@wrapMethod(CR4HudModuleControlsFeedback)
function SendInputContextActions( inputContextName : name, optional isForced : bool )
{
	var rebuilt : bool;

	// 原版只在強制或情境變了才重做（:249-252）
	rebuilt = GetEnabled() && ( isForced || !( m_previousInputContext == m_currentInputContext
		|| ( m_previousInputContext == 'JumpClimb' && m_currentInputContext == 'Exploration' )
		|| ( m_previousInputContext == 'Exploration' && m_currentInputContext == 'JumpClimb' ) ) );
	wrappedMethod( inputContextName, isForced );
	if ( rebuilt && !m_altSignCasting && thePlayer.GfgHudGunShown() && ( inputContextName == 'Exploration' || inputContextName == 'Combat' ) )
		GfgSendGunActions( inputContextName );
}

// Flash 那邊只有 5 格（HudModuleControlsFeedback.as 的 mcBtn1～5），多的不顯示
@addMethod(CR4HudModuleControlsFeedback)
function GfgSendGunActions( inputContextName : name )
{
	var arr : CScriptedFlashArray;
	var act : name;
	var pcSprint : bool;

	arr = m_flashValueStorage.CreateTempFlashArray();
	if ( inputContextName == 'Combat' )
	{
		// 原版：輕擊、重擊、閃躲、法印（:372-386）→ 射擊、換彈（R＝原版重擊的鍵）、閃躲、法印、收槍
		GfgPushBinding( arr, 'AttackLight', 'AttackWithAlternateLight', GetLocStringByKeyExt( "gfg_hud_shoot" ) );
		GfgPushBinding( arr, 'AttackHeavy', 'AttackWithAlternateHeavy', GetLocStringByKeyExt( "gfg_hud_reload" ) );
		GfgPushBinding( arr, 'Dodge', 'Dodge', GetLocStringByKeyExt( "panel_input_action_dodge" ) );
		GfgPushBinding( arr, 'CastSign', 'CastSign', GetLocStringByKeyExt( "panel_input_action_castsign" ) );
		GfgPushBinding( arr, 'SwordSheathe', 'SwordSheathe', GetLocStringByKeyExt( "gfg_hud_holster" ) );
	}
	else
	{
		// 衝刺照原版：用哪個動作（:282-286）、鎖住移動時換成「跑」（:575-581）、前綴（:594-614）
		if ( m_displaySprint && !theGame.IsFocusModeActive() )
		{
			pcSprint = m_lastUsedPCInput || !thePlayer.GetLeftStickSprint();
			act = 'SprintToggle';
			if ( pcSprint )
				act = 'Sprint';
			if ( m_movementLockType != PMLT_Free )
				GfgPushBinding( arr, act, act, GetLocStringByKeyExt( "panel_input_action_run" ), GfgPrefix( !pcSprint ) );
			else if ( theInput.IsToggleSprintBound() )
				GfgPushBinding( arr, act, act, GetLocStringByKeyExt( "panel_input_action_sprint" ) );
			else
				GfgPushBinding( arr, act, act, GetLocStringByKeyExt( "panel_input_action_sprint" ), GfgPrefix( act == 'SprintToggle' ) );
		}
		if ( m_displayJump )
			GfgPushBinding( arr, 'Jump', 'Jump', GetLocStringByKeyExt( "panel_button_common_jump" ) );
		if ( m_displayFocus )
			GfgPushBinding( arr, 'Focus', 'Focus', GetLocStringByKeyExt( "panel_input_action_focus" ), GfgPrefix( false ) );
		GfgPushBinding( arr, 'AttackHeavy', 'AttackWithAlternateHeavy', GetLocStringByKeyExt( "gfg_hud_reload" ) );
		GfgPushBinding( arr, 'SwordSheathe', 'SwordSheathe', GetLocStringByKeyExt( "gfg_hud_holster" ) );
		// 叫馬放最後：5 格滿了就不列（使用者要的是收槍、換彈）
		if ( m_displayCallHorse && arr.GetLength() < 5 )
			GfgPushBinding( arr, 'SpawnHorse', 'SpawnHorse', GetLocStringByKeyExt( "ControlLayout_SummonHorse" ) );
	}
	m_flashValueStorage.SetFlashArray( KEY_CONTROLS_FEEDBACK_LIST, arr );
}

// 「按住」「按一下」的前綴（原版 :594-624）
@addMethod(CR4HudModuleControlsFeedback)
function GfgPrefix( press : bool ) : string
{
	var open, close, s : string;

	GetBracketSymbols( open, close );
	if ( press )
		s = StrReplace( GetLocStringByKeyExt( "ControlLayout_press" ), " -", "" );
	else
		s = GetLocStringByKeyExt( "ControlLayout_hold" );
	return "<font color=\"#FCAD36\">" + open + s + close + "</font>";
}

// 一項提示：鍵照原版的查法（:425-431 手把、:500 鍵盤），標籤照 :754-757
@addMethod(CR4HudModuleControlsFeedback)
function GfgPushBinding( arr : CScriptedFlashArray, padAction : name, pcAction : name, label : string, optional prefix : string )
{
	var tmp, data : CScriptedFlashObject;
	var pad, pc : array< EInputKey >;

	theInput.GetPadKeysForAction( padAction, pad );
	if ( m_lastUsedPCInput )
		theInput.GetPCKeysForAction( pcAction, pc );
	tmp = m_flashValueStorage.CreateTempFlashObject();
	data = tmp.CreateFlashObject( "red.game.witcher3.data.KeyBindingData" );
	if ( pad.Size() > 0 )
		data.SetMemberFlashInt( "gamepad_keyCode", pad[0] );
	else
		data.SetMemberFlashInt( "gamepad_keyCode", 0 );
	if ( pc.Size() > 0 )
		data.SetMemberFlashInt( "keyboard_keyCode", pc[0] );
	else
		data.SetMemberFlashInt( "keyboard_keyCode", 0 );
	if ( theGame.IsLanguageArabic() )
		data.SetMemberFlashString( "label", prefix + " <font color=\"#FFFFFF\">" + label + "</font>" );
	else
		data.SetMemberFlashString( "label", " <font color=\"#FFFFFF\">" + label + "</font> " + prefix );
	arr.PushBackFlashObject( data );
}

@addField(CR4Player)
var gfgHudGun : bool;	// 右下角的提示現在是 AK 版

@addMethod(CR4Player)
function GfgHudGunShown() : bool
{
	return rangedWeapon && rangedWeapon.GfgIsGunDrawn();
}

// 拿出、收起 AK 時重做提示（UpdateInputContextActions：:164-187，戰鬥情境用 'Combat'）
@addMethod(CR4Player)
function GfgHudTick()
{
	var hud : CR4ScriptedHud;
	var module : CR4HudModuleControlsFeedback;

	if ( GfgHudGunShown() == gfgHudGun )
		return;
	gfgHudGun = !gfgHudGun;
	hud = (CR4ScriptedHud)theGame.GetHud();
	if ( hud )
		module = (CR4HudModuleControlsFeedback)hud.GetHudModule( "ControlsFeedbackModule" );
	if ( module )
		module.UpdateInputContextActions();
}

// R（重擊 AttackWithAlternateHeavy：使用者 input.settings 的 [Exploration]、[Combat]；處理：playerInput.ws:2054-2057）：AK 選用時＝主動換彈
// （第 33 項；使用者 2026-10-18：「增加主動換子彈功能，你來選擇一個適合的按鍵」）
// 選 R：CS2 換彈也是 R；拿 AK 時不准用劍（第 19 項），重擊沒有用；不用改按鍵設定。騎馬、游泳、潛水的情境沒有綁 R → 照舊打空才換
@wrapMethod(CPlayerInput)
function OnCbtAttackWithAlternateHeavy( action : SInputAction )
{
	var ak : Crossbow;

	ak = GfgSelectedGun();
	if ( !ak )
		return wrappedMethod( action );
	if ( IsPressed( action ) )
		ak.GfgManualReload();
	return true;
}

// 按住 R 0.2 秒的特殊攻擊（:2284）：AK 選用時不放劍招（同左鍵）
@wrapMethod(CPlayerInput)
function OnCbtSpecialAttackWithAlternateHeavy( action : SInputAction )
{
	if ( GfgSelectedGun() )
		return true;
	return wrappedMethod( action );
}

// 主動收槍：C 鍵（原版「收武器」SwordSheathe：legacy\base\input_qwerty.ini:709-715；處理：playerInput.ws:1197-1220）（使用者 2026-10-14 選定）
// 拿著 AK 時先收起 AK，走原版收十字弩的流程（同原版潛水時：playerInput.ws:1823、:1837 → r4Player.ws:14764-14765 → Crossbow.OnForceHolster：rangedWeapon.ws:713-727）；
// 之後照原版處理收劍。按住 1／2 收劍（OnCommSheatheSteel／Silver）也會呼叫到這裡（playerInput.ws:1240、:1263）
@wrapMethod(CPlayerInput)
function OnCommSheatheAny( action : SInputAction )
{
	if ( IsPressed( action ) && thePlayer.rangedWeapon && thePlayer.rangedWeapon.GfgIsGunDrawn() )
		thePlayer.OnRangedForceHolster( true, false );
	return wrappedMethod( action );
}

// ===== 子彈數：左下角道具格顯示彈匣剩幾發（第 35 項；使用者 2026-10-19：「在畫面中尋找合適的地方顯示子彈剩餘數量。呈現方式符合遊戲的設計脈絡」）=====
// 原版：選用物品是十字弩類時，左下角道具格（CR4HudModuleItemInfo 的 item1）顯示裝好的箭的數量＋名稱，無限的箭顯示 ∞（hudModuleItemInfo.ws:482-500）
// AK：數量改成彈匣剩幾發；打空（換彈中）照原版箭用完的寫法標紅（:494-497）
// 原版只在選用物品、箭的數量、箭的種類變了才更新這格（UpdateItem：:306-384）→ 每次 OnTick 比對剩幾發，變了就更新
// 送給 Flash 的 setItemInfo 會讓這個模組亮起、計時後淡出（HudModuleItemInfo.as:221-300 的 GameEvent.UPDATE）：開槍時看得到；戰鬥中一直顯示（hudModuleItemInfo.ws:261-264）

// 這格目前顯示的剩餘發數（-1：不是 AK）
@addField(CR4HudModuleItemInfo)
var gfgAmmoShown : int;

// 彈匣剩幾發：射一發 shotCount 加 1，換彈結束歸零（rangedWeapon.ws:697-703）
@addMethod(Crossbow)
function GfgRoundsLeft() : int
{
	return Max( 0, GfgMagazineSize() - shotCount );
}

// 選用物品是 AK → 彈匣剩幾發；不是 → -1
function GfgHudGunRounds( item : SItemUniqueId ) : int
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if ( !witcher || !witcher.inv.IsIdValid( item ) || !witcher.inv.ItemHasTag( item, 'gfg_ak47' ) )
		return -1;
	// AK 的實體還沒生成（剛裝上）：當作滿的
	if ( !witcher.rangedWeapon || !witcher.rangedWeapon.GfgIsGun() )
		return witcher.inv.GetCrossbowAmmo( item );
	return witcher.rangedWeapon.GfgRoundsLeft();
}

// 原版算完、送完這格之後，AK 的數量換成剩幾發（圖示、名稱、按鍵照原版剛算好的：m_previousSetItemInfo）
@wrapMethod(CR4HudModuleItemInfo)
function UpdateItemData( item : SItemUniqueId, bindingID : HudItemInfoBinding )
{
	var rounds : int;
	var ammoStr : string;

	wrappedMethod( item, bindingID );
	if ( bindingID != HudItemInfoBinding_item1 )
		return;
	rounds = GfgHudGunRounds( item );
	gfgAmmoShown = rounds;
	if ( rounds < 0 )
		return;
	if ( rounds == 0 )
		ammoStr = "<font color=\"#FF0000\">0</font>";
	else
		ammoStr = "<font color=\"#FFFFFF\">" + rounds + "</font>";
	if ( m_previousSetItemInfo[ bindingID ].m_ammoStr == ammoStr )
		return;
	m_previousSetItemInfo[ bindingID ].m_ammoStr = ammoStr;
	m_fxSetItemInfo.InvokeSelfSevenArgs( FlashArgInt( bindingID ), FlashArgString( m_previousSetItemInfo[ bindingID ].m_icon ),
		FlashArgString( m_previousSetItemInfo[ bindingID ].m_category ), FlashArgString( m_previousSetItemInfo[ bindingID ].m_itemName ),
		FlashArgString( ammoStr ), FlashArgInt( m_previousSetItemInfo[ bindingID ].m_btn ), FlashArgInt( m_previousSetItemInfo[ bindingID ].m_pcBtn ) );
}

@wrapMethod(CR4HudModuleItemInfo)
function OnTick( timeDelta : float )
{
	var result : bool;
	var item : SItemUniqueId;

	result = wrappedMethod( timeDelta );
	if ( !thePlayer.IsCiri() )
	{
		item = thePlayer.GetSelectedItemId();
		if ( GfgHudGunRounds( item ) != gfgAmmoShown )
			UpdateItemData( item, HudItemInfoBinding_item1 );
	}
	return result;
}

// ===== 輪盤的 AK 圖示：水平（第 21 項；使用者 2026-10-18「輪盤的圖示不要是垂直，要是水平。物品欄維持垂直」）=====
// 物品欄、左下角道具格照物品 XML 的 icon_path（直的 gfg_ak47_64x128.png）；只有輪盤換成水平的 gfg_ak47_128x64.png（tools/ak_icon.ps1 產生）
// 輪盤的十字弩格子：圖示框固定 64×128，資料有 multiplyX、multiplyY 時寬高各乘上它（RadialMenuItemEquipped.as:626-633、:764-782）→ 128×64
// 選到這格時中間的大圖照圖的原尺寸顯示（RadialMenuSubItemView.as:110-118）
// 資料在 dataList 的最後一筆（hudModuleRadialMenu.ws:1045-1193）：格子本身、itemsList（中間的大圖）、itemsRangedList（換遠程武器）各有圖示路徑
@wrapMethod(CR4HudModuleRadialMenu)
function UpdateCrossbowItemData( radialSlotId : int, out dataList : CScriptedFlashArray ) : void
{
	var slot : CScriptedFlashObject;

	wrappedMethod( radialSlotId, dataList );
	if ( dataList.GetLength() < 1 )
		return;
	slot = dataList.GetElementFlashObject( dataList.GetLength() - 1 );
	if ( !slot )
		return;
	if ( GfgRadialGunIcon( slot ) )
	{
		slot.SetMemberFlashNumber( "multiplyX", 2.f );
		slot.SetMemberFlashNumber( "multiplyY", 0.5f );
	}
	GfgRadialGunIcons( slot.GetMemberFlashArray( "itemsList" ) );
	GfgRadialGunIcons( slot.GetMemberFlashArray( "itemsRangedList" ) );
	// 第 27 項：AK 只用自己的子彈 → 拿掉中間清單裡的箭（原版列出 bolt 類、跳過目前的無限箭：hudModuleRadialMenu.ws:1109-1151）
	if ( GetWitcherPlayer() && GetWitcherPlayer().GfgGunEquipped() )
		GfgRadialRemoveBolts( slot.GetMemberFlashArray( "itemsList" ) );
}

@addMethod(CR4HudModuleRadialMenu)
function GfgRadialRemoveBolts( list : CScriptedFlashArray )
{
	var i : int;
	var obj : CScriptedFlashObject;

	if ( !list )
		return;
	for ( i = list.GetLength() - 1; i >= 0; i -= 1 )
	{
		obj = list.GetElementFlashObject( i );
		if ( obj && obj.GetMemberFlashString( "category" ) == "bolt" )
			list.RemoveElement( i );
	}
}

// 圖示路徑是 AK 的直式圖示（有沒有 img:// 都算）就換成水平的；有換回傳 true
@addMethod(CR4HudModuleRadialMenu)
function GfgRadialGunIcon( obj : CScriptedFlashObject ) : bool
{
	var path : string;

	if ( !obj )
		return false;
	path = obj.GetMemberFlashString( "itemIconPath" );
	if ( !StrContains( path, "gfg_ak47_64x128.png" ) )
		return false;
	obj.SetMemberFlashString( "itemIconPath", StrReplace( path, "gfg_ak47_64x128.png", "gfg_ak47_128x64.png" ) );
	return true;
}

@addMethod(CR4HudModuleRadialMenu)
function GfgRadialGunIcons( list : CScriptedFlashArray )
{
	var i : int;

	if ( !list )
		return;
	for ( i = 0; i < list.GetLength(); i += 1 )
		GfgRadialGunIcon( list.GetElementFlashObject( i ) );
}

// 弩箭發射：AK 的子彈改成飛向準心（畫面中央）指的點（原版是 GetLookAtPosition，最遠 25 公尺：playerBoltProjectile.ws:128-142）
@wrapMethod(W3BoltProjectile)
function ThrowProjectile( targetPosIn : Vector )
{
	var player : CR4Player;
	var target, rayStart, rayDir : Vector;

	target = targetPosIn;
	player = (CR4Player)GetOwner();
	if ( player && player.rangedWeapon && player.rangedWeapon.GfgIsGun() )
	{
		target = player.rangedWeapon.GfgAimPoint( rayStart, rayDir );
		gfgAimTarget = target;
		// 射程：發射時換成 AK 的射程（下面 ShootProjectileAtPosition／AtBone 的包裝）；水中照原版 5 公尺（playerBoltProjectile.ws:341-345）
		if ( !player.IsDiving() )
		{
			gfgGunRange = player.rangedWeapon.GfgRange();
			// 準心射線經過的角色（第 11 項）：有的話子彈用 AtBone 打那個角色（下面的包裝）
			GfgFindActorOnRay( rayStart, rayDir, VecDistance( rayStart, target ) );
		}
	}
	wrappedMethod( target );
}
