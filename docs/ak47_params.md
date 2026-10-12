# AK-47 參數（CS2 `weapons.vdata`）

> M0 產出。整理 CS2 AK-47 的原始數值，供 M1／M2 轉換成巫師3 的數值。
> 行號都指向 `data/cs2/weapons.vdata`。

---

## 1. 來源

| 項目 | 內容 |
|---|---|
| 檔案 | `data/cs2/weapons.vdata`（17110 行，KV3 文字格式） |
| 下載網址 | `https://raw.githubusercontent.com/SteamTracking/GameTracking-CS2/master/game/csgo/pak01_dir/scripts/weapons.vdata` |
| 下載日期 | 2026-10-12 |
| 來源 commit | `f68ba6aa2473367589e7cb249fc38814c9b90ff0`（2026-10-08，GitHub API 查得，是最後一次改到此檔的 commit） |

CS2 更新後要重新下載，並以新檔案為準。

---

## 2. 檔案結構

**繼承鏈**（每個區塊裡的 `_base` 欄位）

```
weapon_ak47          (13247)  _base = "weapon_ak47_prefab"   (13317)
 └ weapon_ak47_prefab (2076)  _base = "rifle"                (2146)
    └ rifle            (671)
       └ primary       (154)
          └ weapon_base (76)
             └ statted_item_base (4)
```

**這份檔案已經是展開過的格式**

- `weapon_ak47` 自己就列出全部 85 個欄位
- 繼承鏈上層沒有任何 `weapon_ak47` 缺少的欄位（2026-10-12 比對欄位名稱集合）
- `weapon_ak47`（13249–13343）和 `weapon_ak47_prefab`（2078–2171）的數值完全相同
  - 差別只有 `_base`
  - 以及 `weapon_ak47` 多了 `_not_pickable = 1`（13343）

→ 下面的表格一律引用 `weapon_ak47` 區塊的行號。

---

## 3. 兩值陣列 `[a, b]` 的意義

**結論（推論，證據充分）**

- `a`：一般狀態
- `b`：武器的第二模式（開鏡、連發、消音器）
- **AK-47 的所有陣列，兩個值都相同**
  → 對 AK 沒有影響，**一律取第一個值**

**證據**

| 武器 | 欄位 | 值 | 行號 | 說明 |
|---|---|---|---|---|
| AWP | `m_nZoomLevels` | 2 | 13491 | 有開鏡 |
| AWP | `m_flMaxSpeed` | [200, 100] | 13505 | 開鏡時移動變慢 |
| AWP | `m_flInaccuracyStand` | [0.0808, 0.002] | 13508 | 開鏡後變準 |
| SCAR-20 | `m_flMaxSpeed` | [215, 120] | 15993 | 有開鏡，同樣規律 |
| AUG | `m_flMaxSpeed` | [220, 150] | 13399 | 有開鏡，同樣規律 |
| Glock | `m_bHasBurstMode` | true | 13197 | 有連發模式 |
| Glock | `m_flSpread` | [0.002, 0.015] | 13204 | 連發模式散布較大 |
| M4A1-S | `m_eSilencerType` | `WEAPONSILENCER_DETACHABLE` | 14190 | 消音器可拆 |
| M4A1-S | `m_flSpread` | [0.0006, 0.0005] | 14209 | 兩種狀態不同 |

**例外**

- M4A4（`weapon_m4a1`）沒有開鏡（14095）、沒有連發（14103）、沒有消音器（14091）
- 但 `m_flInaccuracyMove` = [0.13788, 0.122]（14117），兩個值不同
- 推論：沒有第二模式的武器，第二個值用不到，只是殘留資料

---

## 4. AK-47 數值

### 4.1 射擊與彈藥

| 欄位 | 值 | 行號 | 說明 |
|---|---|---|---|
| `m_nDamage` | 36 | 13250 | 基礎傷害 |
| `m_nNumBullets` | 1 | 13258 | 每次射擊發射的子彈數 |
| `m_bIsFullAuto` | true | 13257 | 全自動 |
| `m_flCycleTime` | 0.1 | 13298 | 射擊間隔（秒）→ **600 RPM** |
| `m_iMaxClip1` | 30 | 13251 | 彈匣容量 |
| `m_nPrimaryReserveAmmoMax` | 3 | 13262 | 備彈；和下一列一起看 |
| `m_bReserveAmmoAsClips` | true | 13328 | 備彈以「彈匣數」計 → 推論為 3 個彈匣 = 90 發 |
| `m_flDeployDuration` | 1.0 | 13267 | 拔槍時間（秒） |
| `m_flDisallowAttackAfterReloadStartDuration` | 2.466667 | 13268 | 換彈開始後禁止射擊的時間（秒），可當換彈時長參考 |
| `m_flAttackMovespeedFactor` | 1.0 | 13284 | 射擊時的移動速度倍率（推論：1.0 = 射擊不減速） |
| `m_flHeadshotMultiplier` | 4.0 | 13276 | 爆頭倍率 |
| `m_flArmorRatio` | 1.55 | 13277 | 護甲穿透比例；巫師3 護甲系統不同，暫不使用 |
| `m_flPenetration` | 2.0 | 13278 | 穿牆能力；暫不使用 |
| `m_flRange` | 8192.0 | 13281 | 射程（Source 單位） |
| `m_flRangeModifier` | 0.98 | 13282 | 距離傷害衰減係數；套用公式**待查證** |
| `m_nTracerFrequency` | 3 | 13314 | 每 3 發一道曳光 |
| `m_vecMuzzlePos0` | [37.422, -4.938, -3.394] | 13342 | 槍口位置（模型空間；軸向在 M3 用 Blender 確認） |

### 4.2 散布（Inaccuracy／Spread）

| 欄位 | 值 | 行號 | 說明 |
|---|---|---|---|
| `m_flSpread` | 0.0006 | 13302 | 基礎散布 |
| `m_flInaccuracyStand` | 0.00641 | 13304 | 站立 |
| `m_flInaccuracyCrouch` | 0.00481 | 13303 | 蹲下 |
| `m_flInaccuracyMove` | 0.17506 | 13309 | 移動 |
| `m_flInaccuracyJump` | 0.14076 | 13305 | 跳躍 |
| `m_flInaccuracyJumpInitial` | 0.10094 | 13264 | 起跳瞬間 |
| `m_flInaccuracyJumpApex` | 0.0 | 13265 | 跳躍最高點 |
| `m_flInaccuracyLand` | 0.000242 | 13306 | 落地 |
| `m_flInaccuracyLadder` | 0.14 | 13307 | 爬梯子；巫師3 用不到 |
| `m_flInaccuracyFire` | 0.0078 | 13308 | 每發增加的散布 |
| `m_flInaccuracyReload` | 0.0 | 13266 | 換彈 |
| `m_nSpreadSeed` | 0 | 13269 | 散布種子 |

**散布回復**

| 欄位 | 值 | 行號 |
|---|---|---|
| `m_flRecoveryTimeStand` | 0.368 | 13271 |
| `m_flRecoveryTimeStandFinal` | 0.506 | 13273 |
| `m_flRecoveryTimeCrouch` | 0.305257 | 13270 |
| `m_flRecoveryTimeCrouchFinal` | 0.419728 | 13272 |
| `m_nRecoveryTransitionStartBullet` | 2 | 13274 |
| `m_nRecoveryTransitionEndBullet` | 5 | 13275 |

- 推論（從欄位名稱）：連射第 2～5 發之間，回復時間從一般值過渡到 Final 值
- **散布值的單位**檔案裡沒有說明（可能是弧度或正切值）→ M2 前要查證

### 4.3 後座力

| 欄位 | 值 | 行號 | 說明 |
|---|---|---|---|
| `m_flRecoilAngle` | 0.0 | 13310 | 後座力基準角度 |
| `m_flRecoilAngleVariance` | 70.0 | 13311 | 角度變化量 |
| `m_flRecoilMagnitude` | 30.0 | 13312 | 後座力大小 |
| `m_flRecoilMagnitudeVariance` | 0.0 | 13313 | 大小變化量 |
| `m_nRecoilSeed` | 223 | 13340 | 後座力種子 |

- 這些只是**產生彈道的參數**，不是每發的座標
- 彈道演算法依 CLAUDE.md §9，在 M2 實作並在遊戲外驗證

### 4.4 移動

| 欄位 | 值 | 行號 | 說明 |
|---|---|---|---|
| `m_flMaxSpeed` | 215.0 | 13301 | 持槍移動速度（Source 單位/秒） |
| `m_iWeight` | 25 | 13260 | 武器權重；用途未查證，巫師3 不使用 |

### 4.5 素材參照

| 欄位 | 值 | 行號 |
|---|---|---|
| `m_szWorldModel` | `weapons/models/ak47/weapon_rif_ak47.vmdl` | 13331 |
| `m_szTracerParticle` | `particles/weapons/cs_weapon_fx/weapon_tracers_assrifle.vpcf` | 13332 |
| `WEAPON_SOUND_SINGLE` | `Weapon_AK47.Single` | 13335 |
| `WEAPON_SOUND_NEARLYEMPTY` | `Default.nearlyempty` | 13336 |
| `m_szAnimSkeleton` | `animation/skeletons/weapons/ak47.vnmskel` | 13341 |
| `m_nPrimaryAmmoType` | `BULLET_PLAYER_762MM` | 13338 |

- 粒子特效（`.vpcf`）無法移植（CLAUDE.md §7）
- 動畫骨架是 CS2 的，不能套用到 Geralt（CLAUDE.md §6-4）

---

## 5. 與 CLAUDE.md §8 比對

- §8 表格的 **26 列（含 Final、EndBullet 等共 31 個欄位）全部和檔案一致**，沒有差異
- §8 沒有列、但這次補上的欄位：
  - `m_nNumBullets`、`m_nPrimaryReserveAmmoMax`、`m_bReserveAmmoAsClips`
  - `m_flInaccuracyJumpApex`、`m_flInaccuracyLadder`、`m_flInaccuracyReload`、`m_nSpreadSeed`
  - `m_flAttackMovespeedFactor`、`m_flArmorRatio`、`m_flPenetration`
- §8 寫「陣列的兩個值需查證」→ 已有結論，見本文第 3 節

---

## 6. 單位換算

採用 Source 引擎的慣例：**1 單位 ≈ 1 英寸 = 2.54 公分**。
這只是慣例，不是檔案裡寫的；模型尺寸在 M3 用 Blender 實測確認。

| 項目 | 原始值 | 換算 |
|---|---|---|
| 射程 `m_flRange` | 8192 | ≈ 208 公尺 |
| 移動速度 `m_flMaxSpeed` | 215 /秒 | ≈ 5.46 公尺/秒 |
| 槍口位置 `m_vecMuzzlePos0` | [37.422, -4.938, -3.394] | ≈ [95.1, -12.5, -8.6] 公分 |
| 射擊間隔 `m_flCycleTime` | 0.1 秒 | 每分鐘 600 發 |

---

## 7. 全域 convar（M2 參考）

來源：GameTracking-CS2 的 `DumpSource2/convars.txt`，commit `f68ba6a`（2026-10-08）。
這個檔案沒有放進專案，只記錄行號。

| convar | 預設值 | 行號 | 說明（原文） |
|---|---|---|---|
| `view_punch_decay` | 18 | 12693 | Decay factor exponent for view punch |
| `weapon_air_spread_scale` | 1 | 12921 | Scale factor for jumping inaccuracy |
| `weapon_accuracy_nospread` | false | 12909 | Disable weapon inaccuracy spread |
| `cl_crosshair_recoil` | true | 1027 | Crosshair follows the weapon's predicted recoil (aim punch) |

- CS:GO 時代的 `weapon_recoil_*` 系列 convar，在這份 dump 裡**搜尋不到**
  → 彈道演算法的常數要靠社群逆向研究，引用時註明來源（CLAUDE.md §9）

---

## 8. 轉換到巫師3 時要決定的事（M1／M2）

- **傷害尺度**：CS2 是 100 血制，巫師3 怪物血量尺度不同 → 36 要換算成多少，M1 決定
- **射速 600 RPM**：用腳本計時器控制（API 待 findings.md 確認）
- **彈匣與換彈**：30 發，換彈約 2.47 秒
- **散布與後座力**：先查清單位，再轉換成鏡頭角度（M2）
- **射程**：約 208 公尺 → 決定射線檢測的長度
