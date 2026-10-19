// AK-47 的規格（第 48 項：從各檔寫死的值搬來，數值沒改；欄位的意思見 gfg_core.ws 的 SGfgGunSpec）
// 來源：CS2 weapons.vdata 的 weapon_ak47_prefab（data/cs2/weapons.vdata）、docs/ak47_params.md
function GfgSpecAk47() : SGfgGunSpec
{
	var s : SGfgGunSpec;

	s.id = 'gfg_ak47';
	s.cycleTime = 0.1;				// m_flCycleTime
	s.recoilResetTime = 0.368;		// m_flRecoveryTimeStand（推測：停火多久彈道從頭開始）
	s.range = 208.0;				// m_flRange 8192 單位
	s.spreadStand = 0.4016;			// atan(m_flInaccuracyStand 0.00641 + m_flSpread 0.0006)
	s.spreadMove = 10.3188;			// atan(m_flInaccuracyMove 0.17506 + 0.00641 + 0.0006)
	s.spreadPerShot = 0.4469;		// atan(m_flInaccuracyFire 0.0078)
	s.maxMoveSpeed = 5.46;			// m_flMaxSpeed 215 單位/秒
	s.recoveryTime = 0.368;			// m_flRecoveryTimeStand
	s.recoveryTimeFinal = 0.506;	// m_flRecoveryTimeStandFinal
	s.recoveryStartShot = 2;		// m_nRecoveryTransitionStartBullet
	s.recoveryEndShot = 5;			// m_nRecoveryTransitionEndBullet
	s.dmgPerLevel = 10;				// 一發 ≈ 同等級劍輕攻擊的 45%（docs/m3.md「子彈、傷害」）
	s.dmgFlat = 20;
	s.headshotMult = 4;				// m_flHeadshotMultiplier
	s.rangeModifier = 0.98;			// m_flRangeModifier（每 500 單位 = 12.7 公尺）
	s.soundBank = "gfg_ak47.bnk";	// tools/ak_soundbank.py
	s.shotEvent = "gfg_ak47_shot";
	s.ammoItem = 'gfg_ak47_ammo';
	s.ammoWaterItem = 'gfg_ak47_ammo_water';
	s.tmplGun = "dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47.w2ent";
	s.tmplMag = "dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47_mag.w2ent";
	s.tmplNoMag = "dlc\gunforgeralt\data\items\weapons\gfg_ak47\gfg_ak47_nomag.w2ent";
	s.iconInv = "gfg_ak47_64x128.png";
	s.iconRadial = "gfg_ak47_128x64.png";
	s.muzzle = Vector( 0.2368, 0.0409, 0.1710 );	// 槍座標 F 0.669、U 0.096（模型槍管最前端）→ l_weapon 座標
	s.kickRight = GfgAk47KickRight();	// 後座力表：python -X utf8 tools/recoil_pattern.py --ws
	s.kickUp = GfgAk47KickUp();
	return s;
}

// 第 n 發相對前一發的角度（度）：陣列第 n-1 個
function GfgAk47KickRight() : array< float >
{
	var a : array< float >;

	a.PushBack( 0.0000f );
	a.PushBack( -0.0057f );
	a.PushBack( 0.1345f );
	a.PushBack( 0.0568f );
	a.PushBack( -0.6643f );
	a.PushBack( -0.4560f );
	a.PushBack( -0.7079f );
	a.PushBack( 0.9111f );
	a.PushBack( 2.2679f );
	a.PushBack( 1.2503f );
	a.PushBack( -0.7254f );
	a.PushBack( 0.8777f );
	a.PushBack( 1.4474f );
	a.PushBack( 0.1316f );
	a.PushBack( -2.0068f );
	a.PushBack( -1.2548f );
	a.PushBack( -0.7720f );
	a.PushBack( -1.4349f );
	a.PushBack( -1.8820f );
	a.PushBack( 1.0298f );
	a.PushBack( -0.2740f );
	a.PushBack( 0.4636f );
	a.PushBack( 0.4884f );
	a.PushBack( -1.0950f );
	a.PushBack( -0.3705f );
	a.PushBack( 1.1509f );
	a.PushBack( 1.7798f );
	a.PushBack( 2.5425f );
	a.PushBack( 0.7770f );
	return a;
}

// 第 n 發相對前一發的角度（度）：陣列第 n-1 個
function GfgAk47KickUp() : array< float >
{
	var a : array< float >;

	a.PushBack( 0.0000f );
	a.PushBack( 1.4016f );
	a.PushBack( 1.6146f );
	a.PushBack( 1.7194f );
	a.PushBack( 1.7850f );
	a.PushBack( 1.4950f );
	a.PushBack( 1.0682f );
	a.PushBack( 0.8146f );
	a.PushBack( -0.2707f );
	a.PushBack( 0.4928f );
	a.PushBack( 0.4220f );
	a.PushBack( 0.0933f );
	a.PushBack( -0.5133f );
	a.PushBack( 0.2887f );
	a.PushBack( 0.4325f );
	a.PushBack( 0.2915f );
	a.PushBack( 0.3100f );
	a.PushBack( -0.1525f );
	a.PushBack( -0.4638f );
	a.PushBack( 0.3013f );
	a.PushBack( -0.0084f );
	a.PushBack( 0.3190f );
	a.PushBack( 0.1128f );
	a.PushBack( -0.1513f );
	a.PushBack( 0.2904f );
	a.PushBack( 0.0329f );
	a.PushBack( -0.1465f );
	a.PushBack( -1.1404f );
	a.PushBack( 0.0106f );
	return a;
}

