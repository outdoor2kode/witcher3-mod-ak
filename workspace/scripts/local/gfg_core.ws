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
