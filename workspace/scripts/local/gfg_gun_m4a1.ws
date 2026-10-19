// M4A1 的規格（第 49 項，2026-10-20；欄位的意思見 gfg_core.ws 的 SGfgGunSpec；算法同 gfg_gun_ak47.ws）
// 來源：CS2 weapons.vdata 的 weapon_m4a1_prefab（data/cs2/weapons.vdata；遊戲裡叫 M4A4，使用者叫 M4A1）；數值取陣列第一個（CLAUDE.md §8）
function GfgSpecM4a1() : SGfgGunSpec
{
	var s : SGfgGunSpec;

	s.id = 'gfg_m4a1';
	s.cycleTime = 0.09;				// m_flCycleTime
	s.recoilResetTime = 0.338941;	// m_flRecoveryTimeStand
	s.range = 208.0;				// m_flRange 8192 單位
	s.spreadStand = 0.3151;			// atan(m_flInaccuracyStand 0.0049 + m_flSpread 0.0006)
	s.spreadMove = 8.1595;			// atan(m_flInaccuracyMove 0.13788 + 0.0049 + 0.0006)
	s.spreadPerShot = 0.4011;		// atan(m_flInaccuracyFire 0.007)
	s.maxMoveSpeed = 5.715;			// m_flMaxSpeed 225 單位/秒
	s.recoveryTime = 0.338941;		// m_flRecoveryTimeStand
	s.recoveryTimeFinal = 0.466044;	// m_flRecoveryTimeStandFinal
	s.recoveryStartShot = 2;		// m_nRecoveryTransitionStartBullet
	s.recoveryEndShot = 5;			// m_nRecoveryTransitionEndBullet
	s.dmgPerLevel = 9.1667;			// AK 的 10、20 × m_nDamage 33／36
	s.dmgFlat = 18.3333;
	s.headshotMult = 4;				// m_flHeadshotMultiplier
	s.rangeModifier = 0.97;			// m_flRangeModifier（每 500 單位 = 12.7 公尺）
	s.soundBank = "gfg_m4a1.bnk";	// tools/ak_soundbank.py --name gfg_m4a1 --volume -3.8 --pitch 1.1（CS2 Weapon_M4A1.Single）
	s.shotEvent = "gfg_m4a1_shot";
	s.ammoItem = 'gfg_m4a1_ammo';
	s.ammoWaterItem = 'gfg_m4a1_ammo_water';
	s.tmplGun = "dlc\gunforgeralt\data\items\weapons\gfg_m4a1\gfg_m4a1.w2ent";
	s.tmplMag = "dlc\gunforgeralt\data\items\weapons\gfg_m4a1\gfg_m4a1_mag.w2ent";
	s.tmplNoMag = "dlc\gunforgeralt\data\items\weapons\gfg_m4a1\gfg_m4a1_nomag.w2ent";
	s.iconInv = "gfg_m4a1_64x128.png";
	s.iconRadial = "gfg_m4a1_128x64.png";
	s.muzzle = Vector( 0.1446, 0.0009, 0.1118 );	// 槍座標 F 0.5535、U 0.1121（模型槍管最前端；tools/m3_build_ak.py 印的）→ l_weapon 座標
	s.kickRight = GfgM4a1KickRight();	// 後座力表：python -X utf8 tools/recoil_pattern.py data/recoil/m4a4_artanis-rcs.csv --ws --name M4a1
	s.kickUp = GfgM4a1KickUp();
	return s;
}

// 第 n 發相對前一發的角度（度）：陣列第 n-1 個
function GfgM4a1KickRight() : array< float >
{
	var a : array< float >;

	a.PushBack( 0.0000f );
	a.PushBack( -0.0724f );
	a.PushBack( 0.2684f );
	a.PushBack( -0.2788f );
	a.PushBack( 0.4123f );
	a.PushBack( 0.2345f );
	a.PushBack( -0.8782f );
	a.PushBack( -0.5399f );
	a.PushBack( -1.3158f );
	a.PushBack( 0.3748f );
	a.PushBack( 0.9643f );
	a.PushBack( 1.4984f );
	a.PushBack( 1.5201f );
	a.PushBack( 1.3201f );
	a.PushBack( 0.0075f );
	a.PushBack( -0.3795f );
	a.PushBack( 0.6144f );
	a.PushBack( 0.6771f );
	a.PushBack( -0.1915f );
	a.PushBack( -1.6756f );
	a.PushBack( -0.7340f );
	a.PushBack( -1.5166f );
	a.PushBack( -0.4174f );
	a.PushBack( -0.6326f );
	a.PushBack( 0.5974f );
	a.PushBack( -0.3145f );
	a.PushBack( -0.2255f );
	a.PushBack( -0.1378f );
	a.PushBack( -0.2963f );
	return a;
}

// 第 n 發相對前一發的角度（度）：陣列第 n-1 個
function GfgM4a1KickUp() : array< float >
{
	var a : array< float >;

	a.PushBack( 0.0000f );
	a.PushBack( 0.8525f );
	a.PushBack( 0.8676f );
	a.PushBack( 1.2525f );
	a.PushBack( 1.4349f );
	a.PushBack( 1.2634f );
	a.PushBack( 0.7530f );
	a.PushBack( 0.8690f );
	a.PushBack( 0.3092f );
	a.PushBack( 0.4329f );
	a.PushBack( 0.2878f );
	a.PushBack( 0.0268f );
	a.PushBack( -0.1088f );
	a.PushBack( -0.4616f );
	a.PushBack( 0.1747f );
	a.PushBack( 0.5187f );
	a.PushBack( -0.0363f );
	a.PushBack( -0.3344f );
	a.PushBack( 0.0935f );
	a.PushBack( 0.2962f );
	a.PushBack( 0.3263f );
	a.PushBack( -0.0987f );
	a.PushBack( 0.0769f );
	a.PushBack( 0.3201f );
	a.PushBack( 0.1827f );
	a.PushBack( 0.0376f );
	a.PushBack( -0.0569f );
	a.PushBack( 0.2649f );
	a.PushBack( 0.1800f );
	return a;
}

