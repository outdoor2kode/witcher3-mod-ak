// 測試用的主控台指令（gfg 開頭）：正本在 tools\test\gfg_debug.ws，平常不放在 workspace
// 用法：tools/test/g.sh 的 dbg_on（複製到 workspace\scripts\local\）→ Reload scripts → 遊戲裡按 ~ 打指令 → 結果在 editor.log 的 [GFG]
// 測完：dbg_off（刪 workspace 的副本）→ Reload scripts；打包前確認 workspace 沒有這個檔
// 2026-10-19 合併：第 39 項的 gfgfree、gfgshots、gfgmag＋第 24～34 項還用得到的檢查（舊檔在 backup\，不進 git）
// 用到 gfg_*.ws 的欄位、函式：那邊改名時這裡跟著改（tools/wcc_compile.py 加這個檔一起編譯檢查）
//
// 目錄
//   鏡頭          gfgfree( 角度, 距離, 高度 [, 關] )
//   彈匣、換彈    gfgshots( [n] )、gfgmag()
//   動畫圖        gfgbv()、gfgstack()、gfggraphs()
//   拿出 AK       gfgdrawlog( [秒] )：每格的兩手距離、槍管角度
//   子彈          gfgammo()、gfgbulletwatch( 秒 [, 放大] )、gfgbulletview( [距離] )
//   AK 的實體     gfgakstate()、gfgakshow( [0 真的／1 替身／2 沒彈匣的] )

// ===== 鏡頭 =====

// gfgfree( 角度, 距離, 高度 )：鏡頭放在槍身（l_weapon）旁邊、朝向槍身；角度 = 從 Geralt 正前方往左轉幾度；gfgfree( 0, 0, 0, true ) 關掉
// 自由鏡頭開著時 OnGameCameraTick 不跑（換彈抓彈匣在裡面）→ 換彈時等彈匣到左手再開
// （原版 theGame.EnableFreeCamera、MoveFreeCamera：game.ws:161、167）
exec function gfgfree( angle : float, dist : float, height : float, optional off : bool )
{
	var target, pos : Vector;
	var rot : EulerAngles;

	if ( off )
	{
		theGame.EnableFreeCamera( false );
		LogChannel( 'GFG', "free cam off" );
		return;
	}
	target = MatrixGetTranslation( thePlayer.GetBoneWorldMatrixByIndex( thePlayer.GetBoneIndex( 'l_weapon' ) ) );
	pos = target + VecFromHeading( thePlayer.GetHeading() + angle ) * dist;
	pos.Z += height;
	pos.W = 1.f;
	rot = VecToRotation( target - pos );
	theGame.EnableFreeCamera( true );
	theGame.MoveFreeCamera( pos, rot );
	LogChannel( 'GFG', "free cam pos " + VecToStringPrec( pos, 3 ) + " target " + VecToStringPrec( target, 3 ) );
}

// ===== 彈匣、換彈 =====

// gfgshots( n )：設定已經射了幾發（shotCount：rangedWeapon.ws:691、708）→ 再射 30 − n 發就換彈；不給 n：只印狀態
exec function gfgshots( optional n : int )
{
	if ( n > 0 )
		thePlayer.rangedWeapon.GfgDbgSetShots( n );
	LogChannel( 'GFG', "shots " + thePlayer.rangedWeapon.GfgDbgShotInfo() + " ctx=" + theInput.GetContext() + " combat=" + thePlayer.IsInCombat() );
}

@addMethod(Crossbow)
function GfgDbgSetShots( n : int )
{
	shotCount = n;
}

@addMethod(Crossbow)
function GfgDbgShots() : int
{
	return shotCount;
}

@addMethod(Crossbow)
function GfgDbgShotInfo() : string
{
	var d : bool;

	if ( deployedEnt )
		d = true;
	return "count=" + shotCount + " state=" + GetCurrentStateName() + " deployed=" + d + " drawn=" + GfgIsGunDrawn();
}

// gfgmag()：彈匣在不在左手上
exec function gfgmag()
{
	LogChannel( 'GFG', "magOut=" + thePlayer.gfgMagOut + " reload=" + thePlayer.rangedWeapon.GetCurrentStateName() );
}

// ===== 動畫圖 =====

// gfgbv()：拿十字弩（AK）相關的動畫圖變數（2026-10-19：R 換彈後跑步變回原版的拿法時用）
exec function gfgbv()
{
	var p : CR4Player;

	p = thePlayer;
	LogChannel( 'GFG', "bv held=" + p.GetBehaviorVariable( 'hasCrossbowHeld' ) + " aim=" + p.GetBehaviorVariable( 'isAimingWeapon' )
		+ " shoot=" + p.GetBehaviorVariable( 'isShootingWeapon' ) + " loaded=" + p.GetBehaviorVariable( 'isWeaponLoaded' )
		+ " full=" + p.GetBehaviorVariable( 'fullBodyAnimWeight' ) + " cat=" + p.GetBehaviorVariable( 'combatActionType' )
		+ " inCA=" + p.GetBehaviorVariable( 'isInCombatActionForOverlay' ) + " canHold=" + p.GetBehaviorVariable( 'canHolsterAfterDelay' )
		+ " throw=" + p.GetBehaviorVariable( 'inAimThrowForOverlay' ) + " rw=" + p.rangedWeapon.GetCurrentStateName() + " ps=" + p.GetCurrentStateName() );
}

// gfgstack()：動畫圖的堆疊（前 8 層）、玩家動畫元件的 slot（第 25 項：AK 用自己的一套圖；docs\findings.md §34）
@addMethod(CAnimatedComponent)
function GfgSlotsInfo() : string
{
	var i : int;
	var s : string;

	s = "slots:";
	for ( i = 0; i < behaviorInstanceSlots.Size(); i += 1 )
	{
		s += " " + behaviorInstanceSlots[i].instanceName;
		if ( behaviorInstanceSlots[i].alwaysOnTopOfStack )
			s += "(top)";
		if ( !behaviorInstanceSlots[i].graph )
			s += "(no graph)";
	}
	s += " | runtime:";
	for ( i = 0; i < runtimeBehaviorInstanceSlots.Size(); i += 1 )
	{
		s += " " + runtimeBehaviorInstanceSlots[i].instanceName;
		if ( runtimeBehaviorInstanceSlots[i].alwaysOnTopOfStack )
			s += "(top)";
		if ( !runtimeBehaviorInstanceSlots[i].graph )
			s += "(no graph)";
	}
	return s;
}

function GfgDbgStack( tag : string )
{
	var i : int;
	var s : string;

	s = "";
	for ( i = 0; i < 8; i += 1 )
		s += " [" + i + "]" + thePlayer.GetBehaviorGraphInstanceName( i );
	LogChannel( 'GFG', tag + " stack:" + s );
	LogChannel( 'GFG', tag + " " + thePlayer.GetRootAnimatedComponent().GfgSlotsInfo() );
}

exec function gfgstack()
{
	GfgDbgStack( "now" );
}

// gfggraphs()：AK 的那套動畫圖現在有沒有換上、應不應該換上
exec function gfggraphs()
{
	LogChannel( 'GFG', "graphs on " + thePlayer.gfgGunGraphsOn + " wanted " + thePlayer.GfgGunGraphsWanted() );
	GfgDbgStack( "graphs" );
}

// ===== 拿出 AK（第 26 項） =====

// gfgdrawlog( 秒 )：每格記下右手 r_hand 和左手 l_weapon 的距離、槍管和鏡頭的夾角、槍管和瞄準點的夾角（預設 4 秒）
@addField(CR4Player)
var gfgDbgDrawStart : float;
@addField(CR4Player)
var gfgDbgDrawLen : float;

@addMethod(CR4Player)
function GfgDbgDrawBegin( sec : float )
{
	gfgDbgDrawLen = sec;
	gfgDbgDrawStart = theGame.GetEngineTimeAsSeconds();
	RemoveTimer( 'GfgDbgDrawTimer' );
	AddTimer( 'GfgDbgDrawTimer', 0.0f, true );
}

@addMethod(CR4Player)
timer function GfgDbgDrawTimer( dt : float, id : int )
{
	var t : float;
	var a, b, barrel, muzzle, aim, rs, rd : Vector;
	var m : Matrix;
	var ang, ang2 : float;
	var st : name;

	t = theGame.GetEngineTimeAsSeconds() - gfgDbgDrawStart;
	if ( t > gfgDbgDrawLen )
	{
		RemoveTimer( 'GfgDbgDrawTimer' );
		return;
	}
	a = MatrixGetTranslation( GetBoneWorldMatrixByIndex( GetBoneIndex( 'r_hand' ) ) );
	m = GetBoneWorldMatrixByIndex( GetBoneIndex( 'l_weapon' ) );
	b = MatrixGetTranslation( m );
	// 槍管方向（l_weapon 座標：握把 (-0.3032,-0.0115,-0.2320) → 槍口 (0.2368,0.0409,0.1710)）和鏡頭正前方的夾角
	barrel = VecNormalize( m.X * 0.54 + m.Y * 0.0524 + m.Z * 0.403 );
	ang = Rad2Deg( AcosF( ClampF( VecDot( barrel, theCamera.GetCameraDirection() ), -1.f, 1.f ) ) );
	// 槍管和「槍口 → 子彈的目標點（射線打到的點）」的夾角
	muzzle = b + m.X * 0.2368 + m.Y * 0.0409 + m.Z * 0.1710;
	if ( rangedWeapon )
		aim = rangedWeapon.GfgAimPoint( rs, rd );
	ang2 = Rad2Deg( AcosF( ClampF( VecDot( barrel, VecNormalize( aim - muzzle ) ), -1.f, 1.f ) ) );
	if ( rangedWeapon )
		st = rangedWeapon.GetCurrentStateName();
	LogChannel( 'GFG', "draw t=" + FloatToStringPrec( t, 3 ) + " ak=" + st + " ang=" + FloatToStringPrec( ang, 1 ) + " a2=" + FloatToStringPrec( ang2, 1 ) + " dist=" + FloatToStringPrec( VecDistance( aim, muzzle ), 1 ) + " d=" + FloatToStringPrec( VecDistance( a, b ), 3 ) + " trig=" + rangedWeapon.gfgTriggerHeld + " sh=" + rangedWeapon.GfgDbgShots() + " spr=" + GetIsSprinting() + " grip=" + FloatToStringPrec( theGame.GetEngineTimeAsSeconds() - rangedWeapon.gfgGripSince, 3 ) );
}

exec function gfgdrawlog( optional sec : float )
{
	if ( sec <= 0.f )
		sec = 4.f;
	thePlayer.GfgDbgDrawBegin( sec );
}

// ===== 子彈（第 27 項） =====

// gfgammo()：子彈格、遠程武器格、裝好的箭
exec function gfgammo()
{
	var w : W3PlayerWitcher;
	var bolt, ranged : SItemUniqueId;
	var ids : array< SItemUniqueId >;
	var i : int;
	var s : string;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot( EES_Bolt, bolt );
	w.GetItemEquippedOnSlot( EES_RangedWeapon, ranged );
	s = "ammo: ranged=" + w.inv.GetItemName( ranged ) + " bolt=" + w.inv.GetItemName( bolt ) + " qty=" + w.inv.GetItemQuantity( bolt )
		+ " want=" + w.GetCurrentInfiniteBoltName() + " | bolts in inv:";
	ids = w.inv.GetItemsByCategory( 'bolt' );
	for ( i = 0; i < ids.Size(); i += 1 )
		s += " " + w.inv.GetItemName( ids[i] ) + "x" + w.inv.GetItemQuantity( ids[i] );
	if ( w.rangedWeapon )
		s += " | loaded=" + w.rangedWeapon.GfgDbgLoaded();
	LogChannel( 'GFG', s );
}

@addMethod(Crossbow)
function GfgDbgLoaded() : string
{
	if ( !deployedEnt )
		return "none";
	return deployedEnt.GetReadableName();
}

// gfgbulletwatch( 秒, 放大 )：每格記下所有弩箭（標籤 bodkinbolt）：離鏡頭、畫面位置（0～1）、模型顯示；放大 > 0：飛行中的 AK 子彈放大（看得清楚）
@addField(CR4Player)
var gfgDbgWatchEnd : float;
@addField(CR4Player)
var gfgDbgBulletScale : float;

@addMethod(CR4Player)
function GfgDbgWatchBegin( sec : float, scale : float )
{
	gfgDbgWatchEnd = theGame.GetEngineTimeAsSeconds() + sec;
	gfgDbgBulletScale = scale;
	RemoveTimer( 'GfgDbgWatchTimer' );
	AddTimer( 'GfgDbgWatchTimer', 0.0f, true );
}

@addMethod(CR4Player)
timer function GfgDbgWatchTimer( dt : float, id : int )
{
	var ents : array< CEntity >;
	var comps : array< CComponent >;
	var bolt : W3BoltProjectile;
	var i, j : int;
	var s : string;
	var pos, cam : Vector;
	var x, y : float;
	var onScreen : bool;
	var bb : Box;

	if ( theGame.GetEngineTimeAsSeconds() > gfgDbgWatchEnd )
	{
		RemoveTimer( 'GfgDbgWatchTimer' );
		return;
	}
	theGame.GetEntitiesByTag( 'bodkinbolt', ents );
	cam = theCamera.GetCameraPosition();
	s = "bw n=" + ents.Size();
	for ( i = 0; i < ents.Size(); i += 1 )
	{
		bolt = (W3BoltProjectile)ents[i];
		pos = ents[i].GetWorldPosition();
		onScreen = theCamera.WorldVectorToViewRatio( pos, x, y );
		s += " | " + ents[i].GetReadableName() + " ak=" + FloatToStringPrec( bolt.gfgGunRange, 0 ) + " d=" + FloatToStringPrec( VecDistance( pos, cam ), 2 )
			+ " scr=" + onScreen + "(" + FloatToStringPrec( ( x + 1 ) / 2, 3 ) + "," + FloatToStringPrec( ( y + 1 ) / 2, 3 ) + ")";
		comps = ents[i].GetComponentsByClassName( 'CMeshComponent' );
		for ( j = 0; j < comps.Size(); j += 1 )
		{
			bb = ((CBoundedComponent)comps[j]).GetBoundingBox();
			s += " m" + j + "=" + comps[j].GetName() + ":" + ((CDrawableComponent)comps[j]).IsVisible() + ":" + FloatToStringPrec( VecLength( bb.Max - bb.Min ), 3 )
				+ ( comps[j].GetEntity() == ents[i] );
			if ( gfgDbgBulletScale > 0.f && bolt.gfgGunRange > 0.f )
				comps[j].SetScale( Vector( gfgDbgBulletScale, gfgDbgBulletScale, gfgDbgBulletScale ) );
		}
	}
	LogChannel( 'GFG', s );
}

exec function gfgbulletwatch( sec : float, optional scale : float )
{
	thePlayer.GfgDbgWatchBegin( sec, scale );
}

// gfgbulletview( 距離 )：把子彈模板生成在鏡頭前（側面朝鏡頭；預設 0.3 公尺），看模型本身
exec function gfgbulletview( optional dist : float )
{
	var tmpl : CEntityTemplate;
	var ent : CEntity;
	var pos : Vector;
	var rot : EulerAngles;

	if ( dist <= 0.f )
		dist = 0.3f;
	tmpl = (CEntityTemplate)LoadResource( "dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47_bullet.w2ent", true );
	pos = theCamera.GetCameraPosition() + theCamera.GetCameraDirection() * dist;
	rot = theCamera.GetCameraRotation();
	rot.Yaw += 90.f;
	rot.Pitch = 0.f;
	ent = theGame.CreateEntity( tmpl, pos, rot );
	LogChannel( 'GFG', "bulletview tmpl=" + tmpl + " ent=" + ent + " pos=" + VecToString( pos ) );
}

// ===== AK 的實體（第 24 項：物品欄換過武器後 AK 看不到） =====

// gfgakstate()：遠程武器格的物品實體、掛在哪、彈匣、替身
exec function gfgakstate()
{
	var w : W3PlayerWitcher;
	var id : SItemUniqueId;
	var ent : CItemEntity;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot( EES_RangedWeapon, id );
	ent = w.inv.GetItemEntityUnsafe( id );
	LogChannel( 'GFG', "akstate rw=" + w.rangedWeapon + " ent=" + ent + " same=" + ( (CEntity)ent == (CEntity)w.rangedWeapon ) + " mounted=" + w.inv.IsItemMounted( id ) + " held=" + w.inv.IsItemHeld( id ) + " slot=" + w.inv.GetItemHoldSlot( id )
		+ " entpos=" + VecToString( ent.GetWorldPosition() ) + " me=" + VecToString( w.GetWorldPosition() ) + " magOut=" + w.gfgMagOut + " carry=" + w.gfgCarryOn + " dummy=" + w.gfgDummy + " nomag=" + w.gfgMagNoMag );
}

// gfgakshow( 0 真的／1 替身／2 沒彈匣的 )：強制顯示那一把的模型
exec function gfgakshow( optional which : int )
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if ( which == 0 )
		w.GfgSetMeshVisible( w.rangedWeapon, true );
	else if ( which == 1 )
		w.GfgSetMeshVisible( w.gfgDummy, true );
	else
		w.GfgSetMeshVisible( w.gfgMagNoMag, true );
	LogChannel( 'GFG', "akshow " + which );
}
