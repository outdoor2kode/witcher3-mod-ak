// gunforgeralt：AK-47 的射擊機制（M2）
// 只對帶有 gfg_ak47 標籤的十字弩生效（gunforgeralt_items.xml），其他十字弩維持原版行為。
//
// 檔案（2026-10-20 第 48 項：原本一個 gfg_ak47.ws 3738 行，照「=====」節拆開，內容沒改）
// 找東西：搜尋「===== 標題」或函式名稱（行號會變，不寫）
//   gfg_core.ws        這個檔：是不是 AK、彈匣容量
//   gfg_anim.ws        動畫圖、姿勢：AK 用自己的一套動畫圖／物品欄預覽人物（後面是 R 主動換彈的按鍵：OnCbtAttackWithAlternateHeavy 的包裝）
//                      ／上半身朝哪裡、身體轉向／跳躍、落地時兩手臂維持持槍／衝刺時單手提槍／R 換彈時上半身圖當作瞄準中
//   gfg_fire.ws        開火：全自動（左鍵＝扳機）／兩手握好槍才開火／槍聲（後面：GfgTryFire 開一槍、GfgNoFireHere 掌舵游泳潛水不開槍、GfgMiddleBlocked 中鍵沒有行為）／槍口火光
//   gfg_recoil.ws      後座力／散布／準心（GfgCameraTick：每格的鏡頭；換彈的 GfgMagTick、GfgReloadAimTick 也從這裡叫）
//   gfg_projectile.ws  射程／子彈的樣子／AK 的子彈／傷害／準心射線經過哪個角色
//   gfg_reload.ws      換彈：彈匣真的拿下來（GfgMagTick：抓的點要和 tools/reload_pose.py 印的一致）
//   gfg_controls.ws    操作、狀態：滑動目標／衝刺／跳躍／戰鬥中被打中不收 AK／不准拿劍／戰鬥中閃躲、翻滾
//   gfg_horse.ws       騎馬、船：左鍵開槍／上下馬（船也是）／騎馬瞄準的左右範圍／馬上的法印輪盤
//   gfg_ui.ws          介面：右下角的操作提示（收槍、換彈）／子彈數（左下角道具格）／輪盤的 AK 圖示

// 目前裝備的十字弩是不是 AK
@addMethod(Crossbow)
function GfgIsGun() : bool
{
	var id : SItemUniqueId;

	if ( !ownerPlayerWitcher )
		return false;
	if ( !ownerPlayerWitcher.GetItemEquippedOnSlot( EES_RangedWeapon, id ) )
		return false;
	return ownerPlayerWitcher.inv.ItemHasTag( id, 'gfg_gun' );
}

// 彈匣容量：XML 的 ammo 屬性（inventoryComponent.ws:4165 GetCrossbowAmmo，原版沒有呼叫者）
@addMethod(Crossbow)
function GfgMagazineSize() : int
{
	var id : SItemUniqueId;

	ownerPlayerWitcher.GetItemEquippedOnSlot( EES_RangedWeapon, id );
	return ownerPlayerWitcher.inv.GetCrossbowAmmo( id );
}

// ===== 槍的規格表（第 48 項；2026-10-20）=====
// 每把槍自己的數值、名稱、模板、聲音、後座力表都在 gfg_gun_<物品名稱>.ws 的 GfgSpec…()；其他檔只查表，不寫死哪一把
// 加新槍：
//   1. 照 gfg_gun_ak47.ws 新增 gfg_gun_<名稱>.ws
//   2. 下面 GfgGunIds、GfgGunSpecOf 各加一行
//   3. 物品 XML：槍加 gfg_gun 標籤、子彈加 gfg_gun_ammo 標籤
struct SGfgGunSpec
{
	var id : name;					// 物品名稱（gunforgeralt_items.xml）
	var cycleTime : float;			// 射擊間隔（秒）
	var recoilResetTime : float;	// 停火超過這個時間，下一發從彈道第一發重新開始（秒）
	var range : float;				// 射程：瞄準射線的長度、子彈的飛行距離（公尺）
	var spreadStand : float;		// 散布圓錐的半角（度）：站著不動
	var spreadMove : float;			//   全速移動
	var spreadPerShot : float;		//   每發累積
	var maxMoveSpeed : float;		// 算「移動占多少」的最高速度（公尺/秒）
	var recoveryTime : float;		// 散布恢復時間（秒）：連射第 recoveryStartShot～recoveryEndShot 發之間從 recoveryTime 變成 recoveryTimeFinal
	var recoveryTimeFinal : float;
	var recoveryStartShot : float;
	var recoveryEndShot : float;
	var dmgPerLevel : float;		// 傷害 = dmgPerLevel × 等級 + dmgFlat（銀多 25%）
	var dmgFlat : float;
	var headshotMult : float;		// 爆頭倍率
	var rangeModifier : float;		// 距離衰減：每 12.7 公尺乘一次
	var soundBank : string;			// 槍聲的 SoundBank（workspace\soundbanks\pc\）
	var shotEvent : string;			// 槍聲事件
	var ammoItem : name;			// 子彈物品：地面
	var ammoWaterItem : name;		//   游泳、潛水
	var tmplGun : string;			// 槍的實體模板（衝刺時的替身）
	var tmplMag : string;			// 換彈時手上的彈匣
	var tmplNoMag : string;			// 換彈時沒有彈匣的槍
	var iconInv : string;			// 物品欄圖示的檔名（直）
	var iconRadial : string;		// 輪盤圖示的檔名（橫）
	var muzzle : Vector;			// 槍口：l_weapon 座標（槍口火光）
	var kickRight : array< float >;	// 後座力：第 n 發相對前一發往右幾度（陣列第 n-1 個）
	var kickUp : array< float >;	//   往上幾度
}

// 全部槍的物品名稱
function GfgGunIds() : array< name >
{
	var ids : array< name >;

	ids.PushBack( 'gfg_ak47' );
	return ids;
}

// 物品名稱 → 規格（不認得的名稱給 AK 的：只有拿著我們的槍時才會查）
function GfgGunSpecOf( id : name ) : SGfgGunSpec
{
	switch ( id )
	{
		case 'gfg_ak47':
		default:
			return GfgSpecAk47();
	}
}

@addField(W3PlayerWitcher)
var gfgGunSpec : SGfgGunSpec;		// GfgGun() 的快取

@addField(W3PlayerWitcher)
var gfgGunSpecFor : name;			// 快取的是哪個物品名稱（沒裝我們的槍時是空的）

// 遠程武器格裝的槍的規格；換了槍才重新查表
@addMethod(W3PlayerWitcher)
function GfgGun() : SGfgGunSpec
{
	var item : SItemUniqueId;
	var n : name;

	if ( inv && GetItemEquippedOnSlot( EES_RangedWeapon, item ) && inv.ItemHasTag( item, 'gfg_gun' ) )
		n = inv.GetItemName( item );
	if ( n != gfgGunSpecFor || !IsNameValid( gfgGunSpec.id ) )
	{
		gfgGunSpec = GfgGunSpecOf( n );
		gfgGunSpecFor = n;
	}
	return gfgGunSpec;
}

// 十字弩物件裡用的捷徑：拿著它的玩家裝的槍
@addMethod(Crossbow)
function GfgSpec() : SGfgGunSpec
{
	if ( !ownerPlayerWitcher )
		return GfgGunSpecOf( '' );
	return ownerPlayerWitcher.GfgGun();
}
