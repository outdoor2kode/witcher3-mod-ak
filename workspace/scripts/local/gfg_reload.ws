// ===== 換彈：彈匣真的拿下來（第一批第 8 項 B；2026-10-17）=====
// 換彈動畫（tools/reload_pose.py；docs/m3.md「換彈動畫」）：左手 0.30 秒握住彈匣 → 拉出 → 左腰 → 1.50 秒裝上（動畫事件 OnWeaponReload）
// - 抓：換彈開始 0.9 秒內，左手腕到了握彈匣的位置（槍座標 F 0.1447、U −0.0401、R −0.0480：reload_pose.py 印的；第 39 項握法改了，原本 F 0.1875、U −0.1042、R −0.0378）3 公分內、而且不再變近 →
//   真的槍藏起來、改顯示沒彈匣的替身（規格表的 tmplNoMag，AK 是 gfg_ak47_nomag.w2ent：掛 l_weapon 不帶偏移 = 真的槍的位置，同衝刺的替身）；
//   彈匣（規格表的 tmplMag，AK 是 gfg_ak47_mag.w2ent：模型在槍上的位置）用現在的世界姿勢掛到左手（CreateAttachmentAtBoneWS：原版插在敵人身上的箭也這樣掛，arrowProjectile.ws:554）
// - 換了槍：上一把的替身、彈匣刪掉，照新的槍重生（GfgMagUseGun）
// - 裝上：OnWeaponReload 換回真的 AK；換彈中斷（離開換彈狀態、衝刺提槍、收槍）也換回
// - 動畫裡左手相對槍的方向不變、裝上時的位置和抓的時候相同 → 彈匣回到彈匣口時剛好對上
// - 槍座標：原點 = 握把（l_weapon 座標 (-0.3032, -0.0115, -0.2320)）、F 槍管、U 上、R = F×U（同 GfgCarryTick 的 f0、u0）
@addField(CR4Player)
var gfgMagNoMag : CEntity;	// 沒彈匣的槍（不存檔；換關卡後會不見 → 再生成）
@addField(CR4Player)
var gfgMagEnt : CEntity;	// 彈匣
@addField(CR4Player)
var gfgMagFor : name;		// 上面兩個是哪把槍的（物品名稱）
@addField(CR4Player)
var gfgMagOut : bool;		// 彈匣在左手上（真的 AK 藏著）
@addField(CR4Player)
var gfgMagReloading : bool;	// 上一格在換彈
@addField(CR4Player)
var gfgMagStart : float;	// 這次換彈開始的時間（引擎時間；慢動作時跟著變慢）
@addField(CR4Player)
var gfgMagDone : bool;		// 這次換彈抓過了
@addField(CR4Player)
var gfgMagFailed : bool;	// 模板載入失敗：不再重試
@addField(CR4Player)
var gfgMagPrevDist : float;	// 上一格左手腕離抓的點多遠

@addMethod(CR4Player)
function GfgMagSpawn( path : string ) : CEntity
{
	var tmpl : CEntityTemplate;
	var tags : array< name >;
	var ent : CEntity;

	tmpl = (CEntityTemplate)LoadResource( path, true );
	if ( !tmpl )
	{
		gfgMagFailed = true;
		LogChannel( 'GFG', "mag template not found: " + path );
		return NULL;
	}
	tags.PushBack( 'gfg_carry_dummy' );	// 同衝刺的替身：RangedWeapon.OnSpawned 不初始化十字弩
	ent = theGame.CreateEntity( tmpl, GetWorldPosition(), GetWorldRotation(), true, false, true, PM_DontPersist, tags );
	if ( ent )
	{
		GfgSetMeshVisible( ent, false );
		ent.CreateAttachment( this, 'l_weapon' );
	}
	return ent;
}

// 換了槍：刪掉上一把的沒彈匣替身、彈匣（GfgMagTick 接著照這把的模板重生）
@addMethod(CR4Player)
function GfgMagUseGun( id : name )
{
	if ( id == gfgMagFor )
		return;
	GfgMagRestore();
	if ( gfgMagNoMag )
		gfgMagNoMag.Destroy();
	if ( gfgMagEnt )
		gfgMagEnt.Destroy();
	gfgMagNoMag = NULL;
	gfgMagEnt = NULL;
	gfgMagFailed = false;
	gfgMagReloading = false;
	gfgMagFor = id;
}

@addMethod(CR4Player)
function GfgMagTick( gunDrawn : bool )
{
	var reloading : bool;
	var lw : Matrix;
	var lx, ly, lz, d, g, f0, u0, r0 : Vector;
	var dist, now, prev : float;
	var gun : SGfgGunSpec;

	if ( gunDrawn )
	{
		gun = rangedWeapon.GfgSpec();
		GfgMagUseGun( gun.id );
	}
	if ( !gunDrawn || gfgMagFailed )
	{
		GfgMagRestore();
		gfgMagReloading = false;
		return;
	}
	// 拿出槍時先生成（藏著），第一次換彈時模型已經載入
	if ( !gfgMagNoMag )
	{
		gfgMagNoMag = GfgMagSpawn( gun.tmplNoMag );
		return;	// 彈匣下一格才生成：同一格生成兩個時，後生成的彈匣之後顯示不出來（03:5x 實測；原因是推論）
	}
	if ( !gfgMagEnt && !gfgMagFailed )
		gfgMagEnt = GfgMagSpawn( gun.tmplMag );
	if ( !gfgMagNoMag || !gfgMagEnt )
		return;

	reloading = rangedWeapon.GetCurrentStateName() == 'State_WeaponReload' && !gfgCarryOn;
	now = theGame.GetEngineTimeAsSeconds();
	if ( !reloading )
	{
		GfgMagRestore();
		gfgMagReloading = false;
		return;
	}
	if ( !gfgMagReloading )
	{
		gfgMagReloading = true;
		gfgMagStart = now;
		gfgMagDone = false;
		gfgMagPrevDist = 99.f;
	}
	if ( gfgMagOut || gfgMagDone )
		return;
	if ( now - gfgMagStart > 0.9f )
	{
		gfgMagDone = true;
		return;
	}
	// 左手腕在槍座標的位置
	lw = GetBoneWorldMatrixByIndex( GetBoneIndex( 'l_weapon' ) );
	lx = MatrixGetAxisX( lw );
	ly = MatrixGetAxisY( lw );
	lz = MatrixGetAxisZ( lw );
	d = GetBoneWorldPositionByIndex( GetBoneIndex( 'l_hand' ) ) - MatrixGetTranslation( lw );
	g = Vector( VecDot( d, lx ), VecDot( d, ly ), VecDot( d, lz ) ) - Vector( -0.3032f, -0.0115f, -0.2320f );
	f0 = VecNormalize( Vector( 0.8033f, 0.2140f, 0.5558f ) );
	u0 = VecNormalize( Vector( 0.02721f, -0.94542f, 0.32472f ) );
	r0 = VecCross( f0, u0 );
	dist = VecLength( Vector( VecDot( g, f0 ) - 0.1447f, VecDot( g, u0 ) + 0.0401f, VecDot( g, r0 ) + 0.0480f ) );
	// 上一格在 3 公分內、這一格不再變近才抓（= 最接近的那一刻剛過）：01:4x 一進 3 公分就抓，兩次都是 2.9 公分（剛好在門檻邊）
	prev = gfgMagPrevDist;
	gfgMagPrevDist = dist;
	if ( prev > 0.03f || dist < prev )
		return;
	// 抓：真的 AK → 沒彈匣的替身；彈匣用現在的世界姿勢（= l_weapon）掛到左手
	GfgSetMeshVisible( gfgMagNoMag, true );
	rangedWeapon.GfgSetCarryShown( false );
	gfgMagEnt.BreakAttachment();
	gfgMagEnt.CreateAttachmentAtBoneWS( this, 'l_hand', MatrixGetTranslation( lw ), MatrixGetRotation( lw ) );
	GfgSetMeshVisible( gfgMagEnt, true );
	gfgMagOut = true;
	gfgMagDone = true;
}



// 裝上（或換彈中斷）：換回真的 AK；彈匣藏起來、掛回 l_weapon
@addMethod(CR4Player)
function GfgMagRestore()
{
	if ( !gfgMagOut )
		return;
	gfgMagOut = false;
	if ( rangedWeapon && !gfgCarryOn )
		rangedWeapon.GfgSetCarryShown( true );
	if ( gfgMagNoMag )
		GfgSetMeshVisible( gfgMagNoMag, false );
	if ( gfgMagEnt )
	{
		GfgSetMeshVisible( gfgMagEnt, false );
		gfgMagEnt.BreakAttachment();
		gfgMagEnt.CreateAttachment( this, 'l_weapon' );
	}
}

// 裝上新彈匣：換彈動畫的事件 OnWeaponReload（1.5 秒：rangedWeapon.ws:150-152）
// 每發之後不播動畫的裝箭（rangedWeapon.ws:276-297）也會呼叫，這時彈匣不在手上，GfgMagRestore 不做事
@wrapMethod(RangedWeapon)
function OnWeaponReload()
{
	if ( ownerPlayer == thePlayer )
		thePlayer.GfgMagRestore();
	return wrappedMethod();
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
