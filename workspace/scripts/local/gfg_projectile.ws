// ===== 射程：AK 的箭飛到 208 公尺（GfgRange）（M2；使用者 2026-10-13 選定）=====
// 原版弩箭的射程是 MAX_THROW_RANGE 25 公尺（const，炸彈、飛刀也用：gameParams.ws:105），
// 在 ReleaseProjectiles2 傳給 ShootProjectileAtPosition／ShootProjectileAtBone（playerBoltProjectile.ws:341-349、:374-377）。
// 飛到射程時引擎呼叫 OnRangeReached：箭關掉特效，2 秒後刪掉（arrowProjectile.ws:36-45）。
// 這裡只換射程，其他參數照原版；鎖定時打骨骼的那條路（自動瞄準）也換
// （CCO 是整個 ReleaseProjectiles2 覆寫，射程乘上倍率：CCO playerBoltProjectile.ws:589-595）

@addField(W3AdvancedProjectile)
var gfgGunRange : float;		// AK 的箭發射時用的射程（公尺；ThrowProjectile 設定）；0 = 照原版（不是 AK 的箭、在水中）

@addField(W3AdvancedProjectile)
var gfgAimTarget : Vector;		// AK：準心的射線點（ThrowProjectile 包裝設定）
@addField(W3AdvancedProjectile)
var gfgHitActor : CActor;		// AK：準心射線經過的角色（ThrowProjectile 包裝設定；沒有 = NULL）
@addField(W3AdvancedProjectile)
var gfgHitPos : Vector;			// AK：打中的點（射線上離那根骨頭最近的點）
@addField(W3AdvancedProjectile)
var gfgHitNormal : Vector;		// AK：碰撞的法線（射線的反方向）

// 發射時要用的射程
@addMethod(W3AdvancedProjectile)
function GfgShotRange( range : float ) : float
{
	if ( gfgGunRange <= 0.f )
		return range;
	return gfgGunRange;
}

// AK 子彈的速度（公尺／秒；第 9、10 項）：真實 AK 的初速約 715；原版弩箭 projSpeed 60（bodkin_bolt.w2ent）；角度 0 = 直線
// 2026-10-16 19:2x 實測 715：打牆、打 10 公尺外的狼都命中正常
@addMethod(W3AdvancedProjectile)
function GfgBulletSpeed() : float
{
	return 715.f;
}

// 這兩個是 final 函式（advancedProjectile.ws:60-78）；包 final 函式有作用（StateEnter：docs/findings.md §17.8、§17.9）
// AK 的子彈一律 AtPosition（第 11 項）：
// - 準心射線經過角色（GfgFindActorOnRay）→ 射向打中的點，發射後立刻手動觸發碰撞（GfgManualHit）
//   角色身上沒有可靠的碰撞：AtBone 打頭、胸口會碰撞，打腳、小腿、骨盆會穿過去打到後面的地面（2026-10-16 21:1x 實測）
// - 沒有 → 射向射線點（牆、地面）
// 原版有目標時改用 AtBone 自動瞄準 torso2（playerBoltProjectile.ws:353-377；20:1x 實測：瞄頭也打在胸口同一點）→ AK 的子彈改走 AtPosition
@wrapMethod(W3AdvancedProjectile)
function ShootProjectileAtPosition( angle : float, velocity : float, target : Vector, optional range : float, optional collisionGroups : array<name> )
{
	var a, v, r : float;
	var tgt : Vector;

	a = angle;
	v = velocity;
	r = range;
	tgt = target;
	if ( gfgGunRange > 0.f )
	{
		a = 0.f;
		v = GfgBulletSpeed();
		r = GfgShotRange( range );
		if ( gfgHitActor )
			tgt = gfgHitPos;
	}
	wrappedMethod( a, v, tgt, r, collisionGroups );		// 不是 AK 的箭：參數照原版
	if ( gfgGunRange > 0.f && gfgHitActor )
		GfgManualHit();
}

@wrapMethod(W3AdvancedProjectile)
function ShootProjectileAtBone( angle : float, velocity : float, target : CEntity, targetBone : name, optional range : float, optional collisionGroups : array<name> )
{
	if ( gfgGunRange > 0.f )
	{
		ShootProjectileAtPosition( angle, velocity, gfgAimTarget, range, collisionGroups );		// 上面的包裝
		return;
	}
	wrappedMethod( angle, velocity, target, targetBone, range, collisionGroups );		// 不是 AK 的箭：照原版
}

// AK 的子彈打中角色：發射後立刻手動觸發碰撞（群組 Character、元件＝角色的移動元件，和原版子彈撞到角色時一樣：21:1x 紀錄）
// → 原版的處理：傷害（ProcessDamageAction）、打肉的聲音、子彈停下來刪掉（arrowProjectile.ws:225-243、playerBoltProjectile.ws:162-181）
// 不等子彈飛到：子彈一格畫面飛 12 公尺，同一格裡會先撞到人後面的地面（21:2x 實測：射程設成剛好到人，OnRangeReached 也來不及）；
// 715 公尺／秒飛 30 公尺只要 0.04 秒，等於瞬間命中
@addMethod(W3AdvancedProjectile)
function GfgManualHit()
{
	var actor : CActor;
	var groups : array< name >;

	actor = gfgHitActor;
	gfgHitActor = NULL;
	groups.PushBack( 'Character' );
	OnProjectileCollision( gfgHitPos, gfgHitNormal, actor.GetMovingAgentComponent(), groups, 0, 0 );
}

// 碰撞：AK 的子彈打到牆壁、地面時播火花（第 9 項）
// 原版的箭停下來、插著、排 5 秒後刪掉（arrowProjectile.ws:98-114、playerBoltProjectile.ws:182-203）；AK 的子彈照原版刪，
// 碰到東西就藏起模型（第 27 項：子彈不會插在牆上、身上露出來）
// （原本「AK 的箭插在牆上不刪」是使用者 2026-10-13 選的；改成子彈後拿掉）
@wrapMethod(W3BoltProjectile)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	var wasScheduled, result : bool;

	wasScheduled = isScheduledForDestruction;
	result = wrappedMethod( pos, normal, collidingComponent, hitCollisionsGroups, actorIndex, shapeIndex );
	if ( gfgGunRange > 0.f && !wasScheduled && isScheduledForDestruction
		&& ( hitCollisionsGroups.Contains( 'Static' ) || hitCollisionsGroups.Contains( 'Terrain' ) ) )
		PlayEffect( 'sparks' );
	if ( gfgGunRange > 0.f )
		GfgSetBulletMeshVisible( false );
	return result;
}

// ===== 子彈的樣子（第 9 項：使用者 2026-10-16「射出去的還是箭，不是子彈」；第 27 項 2026-10-18 換成子彈的模型）=====
// 原版的箭射出時播軌跡 defaultTrail（arrow_trail）＋破空聲（arrowProjectile.ws:19-34）；特效定義在弩箭共用模板 bolt_base.w2ent
// AK 射出去的是子彈：模板 gfg_ak47_bullet.w2ent（物品 gfg_ak47_ammo 的 hold_template；模型是 CS2 的彈頭，tools/ammo_build.py）
// - 飛行中顯示（原版射出時也會把裝好的箭顯示出來：rangedWeapon.ws:130-134）；碰到東西藏起來（上面的碰撞包裝）
// - 裝在槍上的那顆：原版每發之後立刻裝上的新箭是藏起來的（rangedWeapon.ws:280-286）；換彈動畫裝上的在槍管裡面
// - 萬一射出去的不是子彈（子彈格是別的箭）：照第 9 項藏起箭的模型
// - 只藏 CMeshComponent：藏全部 CDrawableComponent 時，特效（CParticleComponent 也是 CDrawableComponent：CParticleComponent.ws:6）也看不到
// - 原版的軌跡（arrow_trail、_orange、_red、_fire、_mutation_9）在子彈的速度下看不到 → 不當曳光，關掉
@wrapMethod(W3ArrowProjectile)
function OnProjectileShot( targetCurrentPosition : Vector, optional target : CNode )
{
	var result : bool;
	var witcher : W3PlayerWitcher;
	var bolt : SItemUniqueId;

	result = wrappedMethod( targetCurrentPosition, target );
	if ( gfgGunRange > 0.f )
	{
		witcher = (W3PlayerWitcher)GetOwner();
		if ( !witcher || !witcher.GetItemEquippedOnSlot( EES_Bolt, bolt ) || !witcher.inv.ItemHasTag( bolt, 'gfg_ak47_ammo' ) )
			GfgSetBulletMeshVisible( false );
		StopActiveTrail();
	}
	return result;
}

@addMethod(W3AdvancedProjectile)
function GfgSetBulletMeshVisible( visible : bool )
{
	var comps : array< CComponent >;
	var i : int;

	comps = GetComponentsByClassName( 'CMeshComponent' );
	for ( i = 0; i < comps.Size(); i += 1 )
		((CDrawableComponent)comps[i]).SetVisible( visible );
}

// ===== AK 的子彈（第 27 項：使用者 2026-10-18「子彈還是箭的模樣（物品欄看到的）→ 改成子彈：物品欄、射出去的樣子；
//       不要影響到原本的箭矢；如果任何地方都會用到這子彈，都要做」）=====
// 原版：裝上十字弩類時自動裝一種無限的箭（AddAndEquipInfiniteBolt：playerWitcher.ws:5679-5717）：
//   地面 Bodkin Bolt、游泳或潛水 Harpoon Bolt（GetCurrentInfiniteBoltName：:5663-5676）
// AK：換成自己的子彈（gunforgeralt_items.xml 的 gfg_ak47_ammo、水中 gfg_ak47_ammo_water；兩個都有 gfg_ak47_ammo 標籤）
// - 物品欄的子彈格、左下角道具格的名稱（hudModuleItemInfo.ws:482-498）跟著物品：圖示 gfg_ak47_ammo_64x128.png（tools/ammo_build.py）、名稱 7.62mm（第 37 項改短）
// - 裝在槍上、射出去的：物品的 hold_template = gfg_ak47_bullet.w2ent（上面「子彈的樣子」）
// - 原版其他用到箭的地方（2026-10-18 查過所有 'Bodkin Bolt'、InfiniteAmmo 的用法）：
//   - 用 InfiniteAmmo 標籤判斷的：子彈也有這個標籤 → 和原版的無限箭一樣（不扣數量：playerBoltProjectile.ws:386；不能卸下：inventoryMenu.ws:2562-2565 等）
//   - 用名稱判斷的：換彈（rangedWeapon.ws:838 → 上面 PlayOwnerReloadAnim 的包裝）、新物品清單（r4guimanager.ws:1636）、
//     物品欄子彈格的「卸下」按鈕（inventoryContext.ws:646、661）→ 下面補上
//   - 屬性視窗的十字弩傷害（CharacterStatsPopup.ws:919-920）照原版讀 Bodkin Bolt：AK 的傷害由腳本算（GfgSetGunDamage），和子彈物品無關
// - AK 只用自己的子彈：輪盤不列出原版的箭（UpdateCrossbowItemData 的包裝）、物品欄不能把箭裝上去；
//   換回十字弩時照原版裝 Bodkin Bolt（裝 AK 前選的特殊箭留在物品欄）

function GfgIsGunAmmoName( n : name ) : bool
{
	return n == 'gfg_ak47_ammo' || n == 'gfg_ak47_ammo_water';
}

// 遠程武器格裝的是不是 AK（同 Crossbow.GfgIsGun，但不用十字弩的物件：裝備的過程中它可能還沒生成，playerWitcher.ws:6382-6384）
@addMethod(W3PlayerWitcher)
function GfgGunEquipped() : bool
{
	var id : SItemUniqueId;

	if ( !inv || !GetItemEquippedOnSlot( EES_RangedWeapon, id ) )
		return false;
	return inv.ItemHasTag( id, 'gfg_ak47' );
}

// 該用哪一種無限的箭：裝 AK 時換成子彈（游泳、潛水時照原版換成水中用的那種）
@wrapMethod(W3PlayerWitcher)
function GetCurrentInfiniteBoltName( optional forceBodkin : bool, optional forceHarpoon : bool ) : name
{
	var n : name;

	n = wrappedMethod( forceBodkin, forceHarpoon );
	if ( !GfgGunEquipped() )
		return n;
	if ( n == 'Harpoon Bolt' )
		return 'gfg_ak47_ammo_water';
	return 'gfg_ak47_ammo';
}

// 原版先刪光 Bodkin、Harpoon 再加新的（:5686-5693）→ 子彈也先刪光（換回十字弩、出入水時不留下舊的）
@wrapMethod(W3PlayerWitcher)
function AddAndEquipInfiniteBolt( optional forceBodkin : bool, optional forceHarpoon : bool )
{
	var ids : array< SItemUniqueId >;
	var i : int;

	ids = inv.GetItemsByTag( 'gfg_ak47_ammo' );
	for ( i = ids.Size() - 1; i >= 0; i -= 1 )
		inv.RemoveItem( ids[i], inv.GetItemQuantity( ids[i] ) );
	wrappedMethod( forceBodkin, forceHarpoon );
}

// 換武器：原版只在子彈格空著時補無限的箭（:6386-6406）；卸下十字弩類時刪掉格子裡的無限箭（:6720-6727）
// → 十字弩換 AK、AK 換十字弩大多照原版就對了；補上：
// - 裝 AK 時格子裡是特殊箭（原版不動）或原版的無限箭（例：出水時沒拿十字弩也會裝 Bodkin：swimming.ws:135-139）→ 換成子彈
// - 裝十字弩時格子裡是子彈 → 換成原版的箭
@wrapMethod(W3PlayerWitcher)
function EquipItemInGivenSlot( item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool ) : bool
{
	var ret : bool;

	ret = wrappedMethod( item, slot, ignoreMounting, toHand );
	if ( ret && slot == EES_RangedWeapon )
		GfgFixAmmo();
	return ret;
}

@addMethod(W3PlayerWitcher)
function GfgFixAmmo()
{
	var ranged, bolt : SItemUniqueId;

	if ( !GetItemEquippedOnSlot( EES_RangedWeapon, ranged ) || !inv.IsItemCrossbow( ranged ) )
		return;
	if ( !GetItemEquippedOnSlot( EES_Bolt, bolt ) )
		return;		// 空著的話原版已經補了（:6403-6406）
	if ( inv.GetItemName( bolt ) == GetCurrentInfiniteBoltName() )
		return;
	if ( GfgGunEquipped() || inv.ItemHasTag( bolt, 'gfg_ak47_ammo' ) )
		AddAndEquipInfiniteBolt();
}

// 物品欄：裝 AK 時不能把箭裝到子彈格（同原版水中不能換掉 Harpoon Bolt：inventoryMenu.ws:2275-2283）
// 只擋「裝備」：商店買賣、箱子拿放照原版（:2213-2242）
@wrapMethod(CR4InventoryMenu)
function OnEquipItem( item : SItemUniqueId, slot : int, quantity : int )
{
	if ( _currentInv != _containerInv && !_shopNpc && !_containerInv
		&& _inv.IsIdValid( item ) && _inv.IsItemBolt( item ) && !_inv.ItemHasTag( item, 'gfg_ak47_ammo' )
		&& GetWitcherPlayer() && GetWitcherPlayer().GfgGunEquipped() )
	{
		showNotification( GetLocStringByKeyExt( "menu_cannot_perform_action_now" ) );
		OnPlaySoundEvent( "gui_global_denied" );
		return false;
	}
	return wrappedMethod( item, slot, quantity );
}

// 物品欄的子彈格：原版的 Bodkin Bolt 沒有「卸下」（inventoryContext.ws:646、661）→ 子彈也拿掉（按了也卸不下來：inventoryMenu.ws:2562-2565）
@wrapMethod(W3InventoryPaperdollContext)
function updateInputFeedback()
{
	var i : int;
	var removed : bool;

	wrappedMethod();
	if ( !invComponentRef || !invComponentRef.IsIdValid( currentItemId ) || !invComponentRef.ItemHasTag( currentItemId, 'gfg_ak47_ammo' ) )
		return;
	for ( i = m_inputBindings.Size() - 1; i >= 0; i -= 1 )
	{
		if ( m_inputBindings[i].LocalizationKey == "panel_button_inventory_unequip" )
		{
			m_inputBindings.Erase( i );
			removed = true;
		}
	}
	for ( i = m_contextBindings.Size() - 1; i >= 0; i -= 1 )
	{
		if ( m_contextBindings[i].LocalizationKey == "panel_button_inventory_unequip" )
			m_contextBindings.Erase( i );
	}
	if ( removed )
		m_managerRef.updateInputFeedback();
}

// 新物品清單（選單裡的「新物品」）：原版跳過 Bodkin、Harpoon（r4guimanager.ws:1636）→ 子彈也跳過（每次裝 AK 都重新加一次）
@wrapMethod(CR4GuiManager)
function RegisterNewItem( item : SItemUniqueId )
{
	var inv : CInventoryComponent;

	if ( GetWitcherPlayer() )
	{
		inv = GetWitcherPlayer().GetInventory();
		if ( inv && inv.IsIdValid( item ) && inv.ItemHasTag( item, 'gfg_ak47_ammo' ) )
			return;
	}
	wrappedMethod( item );
}

// 物品的提示框：類別原本照物品類別寫「Crossbow bolt」（item_category_bolt：guiTooltipComponent.ws:434）→ 子彈改成自己的字串（彈藥）
// 物品欄的提示框顯示的是 ItemType（不是護甲時＝類別：guiTooltipComponent.ws:502、:641；TooltipInventory.as:282）；ItemCategory（:646）一起改
// 數值照原版（Bodkin Bolt 的穿刺傷害）：AK 的傷害由腳本算（GfgSetGunDamage），和子彈物品無關
@wrapMethod(W3TooltipComponent)
function GetBaseItemData( item : SItemUniqueId, itemInvComponent : CInventoryComponent, optional isShopItem : bool, optional compareWithItem : SItemUniqueId, optional compareItemInv : CInventoryComponent ) : CScriptedFlashObject
{
	var data : CScriptedFlashObject;
	var label : string;

	data = wrappedMethod( item, itemInvComponent, isShopItem, compareWithItem, compareItemInv );
	if ( data && itemInvComponent && itemInvComponent.IsIdValid( item ) && itemInvComponent.ItemHasTag( item, 'gfg_ak47_ammo' ) )
	{
		label = GetLocStringByKeyExt( "gfg_item_category_ammo" );
		data.SetMemberFlashString( "ItemType", label );
		data.SetMemberFlashString( "ItemCategory", label );
	}
	return data;
}

// ===== 傷害（第 10 項：使用者 2026-10-16「傷害由 Claude 設計一個符合這遊戲的」）=====
// 原版的箭：箭（Bodkin Bolt：穿刺 5、銀 4：def_item_bolts.xml）＋十字弩的屬性，經過攻擊力、抗性（playerBoltProjectile.ws:57-77、damageManagerProcessor.ws:2692）
// 原版武器的傷害只看裝備、不隨等級變（2026-10-16 實測：AK 打 5 級的狼，Geralt 10 級、31 級都是 73.1）
// AK：每發的基礎傷害隨 Geralt 的等級增加（敵人的血量也隨等級增加 → 打同等級的敵人要幾發大致固定）；
// 爆頭 ×4（CS2 m_flHeadshotMultiplier）；距離衰減 ×0.98^(距離 / 12.7 公尺)（CS2 m_flRangeModifier：每 500 單位 ×0.98，1 單位 = 1 英吋）
// 攻擊名還是 'bolt'：原版弩的技能（解剖知識、爆頭的暴擊等）照樣有效；抗性照原版
@addField(W3BoltProjectile)
var gfgHeadHit : bool;		// 這發打在頭上（OnProjectileCollision 包裝裡判斷）

// ===== 準心射線經過哪個角色（第 11 項：使用者 2026-10-16「打不中是個大問題」）=====
// 角色對射線、子彈都沒有碰撞（2026-10-16 實測：RayCastSync 只回傳地面和牆；715、60 公尺／秒的子彈都從人身上穿過去，只有幾發打到小腿）；
// 原版的箭打得到人，是因為有目標時用 ShootProjectileAtBone 追著骨頭飛（playerBoltProjectile.ws:353-377）
// → 自己判斷：射線（鏡頭 → 打到的牆或地面）離角色最近的骨頭（FindNearestBoneToEdgeWS：components.ws:325；原版劍砍到哪根骨頭也這樣找：attackAction.ws:421）
//   在 GfgBodyRadius 內就算打中；發射後立刻手動觸發碰撞（GfgManualHit）
// 爆頭：射線離頭部骨頭（GetHeadBoneIndex：actor.ws:711，各種骨架都有）GfgHeadRadius 內
@addMethod(W3BoltProjectile)
function GfgFindActorOnRay( start, dir : Vector, maxDist : float )
{
	var ents : array< CGameplayEntity >;
	var actor : CActor;
	var anim : CAnimatedComponent;
	var a, b : Vector;
	var i, idx : int;
	var t, d, r, bestT : float;

	gfgHitActor = NULL;
	gfgHeadHit = false;
	a = start;
	b = start + dir * maxDist;
	bestT = maxDist + 1.f;
	// 先粗選：鏡頭前方水平 120° 內、射線長度內的活著的角色（actorsStorage.ws:118）
	FindGameplayEntitiesInCone( ents, start, VecHeading( dir ), 120.f, maxDist + 2.f, 100, '', FLAG_OnlyAliveActors + FLAG_ExcludePlayer );
	for ( i = 0; i < ents.Size(); i += 1 )
	{
		actor = (CActor)ents[i];
		// 自己的馬、死掉、昏迷、友善的打不到（原版的規則：throwable.ws:110-131）
		if ( !actor || actor == GetOwner() || !CanCollideWithVictim( actor ) )
			continue;
		anim = actor.GetRootAnimatedComponent();
		if ( !anim )
			continue;
		idx = anim.FindNearestBoneToEdgeWS( a, b );
		if ( idx < 0 )
			continue;
		d = GfgRayBoneDist( actor, idx, a, dir, maxDist, t );
		r = GfgBodyRadius( actor );
		// 頭在最上面：射線從頭上方、旁邊經過時最近的骨頭是頭 → 用頭的大小判斷（2026-10-16 21:2x 實測：離頭 0.23 公尺被算成打中身體）
		if ( idx == actor.GetHeadBoneIndex() )
			r = GfgHeadRadius( actor );
		if ( d < r && t < bestT )
		{
			gfgHitActor = actor;
			bestT = t;
		}
	}
	if ( !gfgHitActor )
		return;
	gfgHitPos = a + dir * bestT;
	gfgHitNormal = -dir;
	idx = gfgHitActor.GetHeadBoneIndex();
	if ( idx >= 0 )
		gfgHeadHit = GfgRayBoneDist( gfgHitActor, idx, a, dir, maxDist, t ) < GfgHeadRadius( gfgHitActor );
}

// 骨頭到射線（a 起、方向 dir、長 maxDist 的線段）的距離；t 傳回沿射線的位置
@addMethod(W3BoltProjectile)
function GfgRayBoneDist( actor : CActor, idx : int, a, dir : Vector, maxDist : float, out t : float ) : float
{
	var p : Vector;

	p = actor.GetBoneWorldPositionByIndex( idx );
	t = ClampF( VecDot( p - a, dir ), 0.f, maxDist );
	return VecDistance( p, a + dir * t );
}

// 身體的半徑：射線離最近的骨頭這麼近就算打中（骨頭是關節的位置，關節之間的身體也要算到）
// 人類 0.25 公尺（2026-10-16 21:2x 實測：腳到頭掃射都判斷正確）；大型怪物跟著碰撞膠囊放大（人類的膠囊半徑 0.35）
@addMethod(W3BoltProjectile)
function GfgBodyRadius( actor : CActor ) : float
{
	return 0.25f * MaxF( 1.f, GfgCapsuleRadius( actor ) / 0.35f );
}

@addMethod(W3BoltProjectile)
function GfgCapsuleRadius( actor : CActor ) : float
{
	var mac : CMovingPhysicalAgentComponent;

	mac = (CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent();
	if ( !mac )
		return 0.35f;
	return mac.GetCapsuleRadius();
}

// 頭的半徑：射線離頭部骨頭這麼近就算爆頭（大型怪物一樣跟著碰撞膠囊放大）
@addMethod(W3BoltProjectile)
function GfgHeadRadius( actor : CActor ) : float
{
	return 0.17f * MaxF( 1.f, GfgCapsuleRadius( actor ) / 0.35f );
}

@addMethod(W3BoltProjectile)
function GfgHeadHit() : bool
{
	return gfgHeadHit;
}

@addMethod(W3BoltProjectile)
function GfgIsGunBullet() : bool
{
	return gfgGunRange > 0.f;
}

@wrapMethod(W3DamageManager)
function ProcessAction( act : W3DamageAction )
{
	var bolt : W3BoltProjectile;

	bolt = (W3BoltProjectile)act.causer;
	if ( bolt && bolt.GfgIsGunBullet() && (W3Action_Attack)act )
		GfgSetGunDamage( act, bolt );
	wrappedMethod( act );
}

@addMethod(W3DamageManager)
function GfgSetGunDamage( act : W3DamageAction, bolt : W3BoltProjectile )
{
	var dmg, dist, perLevel, flat : float;

	// 一發 ≈ 同等級裝備的劍輕攻擊的 45%（2026-10-16 19:5x 定，推算寫在 docs/m3.md「子彈、傷害」）
	// 經過原版流程後實際傷害 = 這個值 + 58（Geralt 本身的加成，不隨等級變：19:5x 實測 188.99 → 246.99）
	// 銀（打怪物的精華）多 25%：同等級的銀劍比鋼劍高；怪物每級 +270 精華、人類每級 +55 血（monster_base_abl_new.xml:44-47、opp_base_abl.xml:283-286）
	perLevel = 10.f;
	flat = 20.f;
	dmg =perLevel * GetWitcherPlayer().GetLevel() + flat;
	if ( act.GetIsHeadShot() || bolt.GfgHeadHit() )
	{
		dmg *= 4.f;
		act.SetHeadShot();		// 原版爆頭的暴擊加成、Headshot 事件（damageManagerProcessor.ws:847-851）
	}
	if ( act.attacker && act.victim )
	{
		dist = VecDistance( act.attacker.GetWorldPosition(), act.victim.GetWorldPosition() );
		dmg *= PowF( 0.98f, dist / 12.7f );
	}
	act.ClearDamage();
	act.AddDamage( theGame.params.DAMAGE_NAME_PIERCING, dmg );
	act.AddDamage( theGame.params.DAMAGE_NAME_SILVER, dmg * 1.25f );
}

// 以下兩個表由 python -X utf8 tools/recoil_pattern.py --ws 產生
// 第 shot 發相對前一發往右幾度（shot 從 1 起算，超過資料長度回傳 0）
@addMethod(Crossbow)
function GfgRecoilKickRight( shot : int ) : float
{
	switch ( shot )
	{
		case 1: return 0.0000f;
		case 2: return -0.0057f;
		case 3: return 0.1345f;
		case 4: return 0.0568f;
		case 5: return -0.6643f;
		case 6: return -0.4560f;
		case 7: return -0.7079f;
		case 8: return 0.9111f;
		case 9: return 2.2679f;
		case 10: return 1.2503f;
		case 11: return -0.7254f;
		case 12: return 0.8777f;
		case 13: return 1.4474f;
		case 14: return 0.1316f;
		case 15: return -2.0068f;
		case 16: return -1.2548f;
		case 17: return -0.7720f;
		case 18: return -1.4349f;
		case 19: return -1.8820f;
		case 20: return 1.0298f;
		case 21: return -0.2740f;
		case 22: return 0.4636f;
		case 23: return 0.4884f;
		case 24: return -1.0950f;
		case 25: return -0.3705f;
		case 26: return 1.1509f;
		case 27: return 1.7798f;
		case 28: return 2.5425f;
		case 29: return 0.7770f;
	}
	return 0.f;
}

// 第 shot 發相對前一發往上幾度（shot 從 1 起算，超過資料長度回傳 0）
@addMethod(Crossbow)
function GfgRecoilKickUp( shot : int ) : float
{
	switch ( shot )
	{
		case 1: return 0.0000f;
		case 2: return 1.4016f;
		case 3: return 1.6146f;
		case 4: return 1.7194f;
		case 5: return 1.7850f;
		case 6: return 1.4950f;
		case 7: return 1.0682f;
		case 8: return 0.8146f;
		case 9: return -0.2707f;
		case 10: return 0.4928f;
		case 11: return 0.4220f;
		case 12: return 0.0933f;
		case 13: return -0.5133f;
		case 14: return 0.2887f;
		case 15: return 0.4325f;
		case 16: return 0.2915f;
		case 17: return 0.3100f;
		case 18: return -0.1525f;
		case 19: return -0.4638f;
		case 20: return 0.3013f;
		case 21: return -0.0084f;
		case 22: return 0.3190f;
		case 23: return 0.1128f;
		case 24: return -0.1513f;
		case 25: return 0.2904f;
		case 26: return 0.0329f;
		case 27: return -0.1465f;
		case 28: return -1.1404f;
		case 29: return 0.0106f;
	}
	return 0.f;
}
