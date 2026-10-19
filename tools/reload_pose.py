"""AK 的換彈動畫（使用者回報的第一批第 8 項：「換彈現在完全沒有動畫 → 做一個真正的 AK-47 換彈動畫」；
第 34 項：「動作太小…可以讓動作明顯點，例如右手也有些動作」→ 上半身往右轉、槍移到身體右前方，
最後右手離開握把、手肘抬高拉槍機：從背後的遊戲鏡頭看得到；
第 39 項：「這個換子姿勢也太怪了吧。右手怎麼會這樣握槍???左手的整個上臂前臂手腕都不自然」→ 手的方向改用解剖角度控制）。

用法（Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/reload_pose.py
        底層.re 輸出.re [--length 2.4] [--pouch-bone pelvis]

- 輸出的檔名要用 gfg_ 開頭（動畫組裡的名稱是 gfg_：docs/findings.md §34.2）；REDkit 同名重匯，那一筆的事件會保留
  - 用 man_ 開頭的檔名匯入會多一筆原版名稱、蓋過原版十字弩的動畫（10-19 01:0x 犯過一次）→ 這個工具會停下來
- 底層：正面持槍，用第 0 格
  - 地面：assets\\anims\\gfg\\square\\man_geralt_gabriel_aim_idle_square.re
    → gfg_geralt_gabriel_reload_lowered.re（gfg_geralt_gabriel_reload_front_2.re 是同一份的複本）
  - 騎馬：assets\\anims\\gfg\\backup_reload_static_2355\\man_geralt_gabriel_horse_{gait}_reload_lowered.re
    （靜止的騎馬換彈，已含騎乘骨盆的補正：move_pose.py --pelvis-from）→ gfg_geralt_gabriel_horse_{gait}_reload_lowered.re
    → 加 --pouch -0.24 0.17 1.20（第 39 項：騎馬時大腿抬高，前腰 POUCH 會讓彈匣穿過大腿、左手搆不到 → 往前、往上到大腿上方）
- 輸出：--length 秒（每秒 30 格）；所有骨頭先複製底層第 0 格，再每格改 torso2、torso3、頭、兩手臂、l_weapon、扭轉骨頭
- 動作（關鍵格在下面的表；時間是秒）：上半身往右轉、前彎，槍以握把為軸往右傾 20°、槍口朝下，左手拿下彈匣 → 左腰換新彈匣
  → 裝上（槍往上一頓）→ 左手回護木、槍往左翻 → 右手離開握把、從上面抓住右邊的拉柄往後拉、放開 → 回到握把、舉槍
  - 上半身（BODY_KEYS）：torso2、torso3 各轉一半；槍、兩手跟著上半身轉（左腰在骨盆上，不跟）
  - 槍：以握把為軸照 GUN_KEYS 走；右手不拉槍機時握著握把（右手 = 槍 · 底層的相對握法）
  - 位置用三次 Hermite 曲線（中間的關鍵格不停頓；停住的關鍵格前後值一樣時速度 0）
  - l_weapon 是 l_hand 的子骨頭：左手離開槍的期間，每格設 l_weapon 的區域變換 = 左手⁻¹ · 槍，槍才會照右手走
  - 兩節手臂 IK：square_pose.two_bone_ik（肩膀、手肘照上半身轉過之後的位置算）
- 手的方向（第 39 項；量法：暫存 s39\\anat.py）
  - 解剖角度：旋前（＋）／旋後（−）＝掌心繞前臂轉（0 = 掌心朝內側；內側 = 手肘鉸鏈軸）；屈腕（＋往掌心）；橈偏（＋往拇指）
    掌心 = 手骨 +Y（拇指根 y +0.014、指節 y −0.008）；拇指那側：左 −Z、右 +Z
  - 原版 Geralt（inventory_*）的範圍：左旋前 −86～+19、右 −35～0；屈腕 −23～+69；底層（瞄準）左 −107、右 −53 → NAT 是檢查用的範圍
  - 第 39 項以前：握彈匣的手勢是「握護木的手勢轉到彈匣上」（固定的轉換）、左腰沿用握彈匣時的世界方向
    → 抓彈匣時左手旋前 +61（從 −107 轉了 168°）、左腰時屈腕 +175、橈偏 +148（手整個折到手背）；
    槍右傾 45°＋槍口上翹 18°：右手旋前到 −92、拉槍機時尺偏 −72
  - 握彈匣、拉槍機：掌心固定貼在彈匣左面（拉柄上面），手的長軸在掌面內對齊前臂（再偏 MAG_DEV／RACK_DEV）
    → IK 之後重算、迭代到收斂（手的長軸一轉，手腕的位置跟著變）；長軸離彈匣前緣最多 ±MAG_SPREAD
  - 左腰：解剖角度 POUCH_ANAT（照 IK 解出的前臂算方向）；進出左腰的兩段：解剖角度內插（加上關鍵格的修正，關鍵格上完全對上）
  - 其他段（都貼在槍上）：槍座標裡 slerp
- 扭轉骨頭照原版 Geralt 動畫的規則烤進去（暫存 s39\\roll_fit.py、roll_fit2.py）：
  forearmRoll1／2、handRoll ＝ 手相對前臂扭轉 ×0.2／0.5／0.2（handRoll 再帶手腕彎的一半）；elbowRoll ＝ 上臂、前臂的正中間；
  shoulderRoll ＝ 鎖骨、上臂的正中間；bicep2 ＝ −0.92（左）／−0.97（右）× 上臂相對鎖骨的扭轉
  - 遊戲裡這些骨頭由動畫圖輸出前的 CBehaviorGraphConstraintNodeRoll 即時算（gfg_gameplay、gfg_overlay 都有）→ 烤進去是讓
    AnimBrowser 的預覽（不跑動畫圖）和遊戲一樣
- 抓彈匣（0.30 秒）、裝上（1.50 秒）時左手相對槍的位置相同；抓的點印在開頭 → 改了要同步 gfg_ak47.ws 的 GfgMagTick
- 量法（docs/handoff.md 第 8 項；暫存 s18\\mag_pos.py）：彈匣底部 F +0.251 U −0.107、彈匣口 F +0.169 U +0.095；
  槍機拉柄 F +0.231 U +0.105 R +0.045；底層左手腕 F +0.261 U +0.045 R −0.046
- 動畫事件（AnimBrowser 加；同名重匯會保留）：OnWeaponReload 1.50 秒（彈匣裝上）、RaiseWeapon 2.15 秒起 0.25 秒
- 離線預覽：暫存 s34\\pv.py（Blender 背景渲染：遊戲鏡頭＝背後偏右、右、前、左）
"""
import argparse
import math
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import aim_delta as A  # noqa: E402  （同時把 h5py 的路徑加進來）
import move_pose as M  # noqa: E402
import square_pose as S  # noqa: E402
import h5py  # noqa: E402

ROT = ('rot.x', 'rot.y', 'rot.z', 'rot.w')
POS = ('pos.x', 'pos.y', 'pos.z')
FPS = 30
X = np.array([1.0, 0.0, 0.0])
GF = S.unit(A.BARREL)                              # 槍座標的軸（l_weapon 座標）
GU = S.unit(S.GUN_UP - GF * (S.GUN_UP @ GF))
GR = np.cross(GF, GU)

# 槍：(秒, 往右, 往前, 往上（公尺，角色的軸：body_axes）, 往右傾（度，上方往右）, 槍口往上（度）, 槍口往右（度）)；以握把為軸
# 第 34 項：上半身往右轉（BODY_KEYS）、槍移到身體右前方；裝上時往上一頓；拉槍機時往左翻（右邊的拉柄朝上，右手從上面抓）
# 第 39 項：右傾 45° → 20°、槍口上翹 18° → 朝下 10°（右傾越多，握彈匣的掌心越朝下、右手越像從上面抓機匣）；
#   換彈匣時槍往左 8 公分（身體中線：原本在右胸前，左手要橫過身體、手腕往後折 77°）、往前 3 公分、槍口往左 10°（槍托離開胸口）
GUN_KEYS = [
    (0.00, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
    (0.28, -0.08, 0.03, -0.08, 20.0, -10.0, -10.0),
    (0.42, -0.08, 0.03, -0.10, 22.0, -13.0, -10.0),   # 拉出彈匣時往下帶
    (1.30, -0.08, 0.03, -0.08, 20.0, -10.0, -10.0),
    (1.50, -0.08, 0.03, -0.06, 17.0, -7.0, -10.0),    # 裝上：往上一頓
    (1.66, 0.0, -0.03, -0.04, -10.0, 4.0, 0.0),     # 往左翻、收回胸前（右手搆得到拉柄）
    (1.80, 0.0, -0.04, -0.04, -10.0, 4.0, 0.0),
    (1.86, 0.0, -0.03, -0.03, -8.0, 6.0, 0.0),      # 放開：拉柄彈回去
    (2.22, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
]
# 上半身：(秒, 往右轉（度）, 往前彎（度）)；torso2、torso3 各轉一半，槍、兩手跟著（左腰在骨盆上，不跟）
BODY_KEYS = [(0.00, 0.0, 0.0), (0.28, 22.0, 8.0), (1.30, 22.0, 8.0), (1.50, 20.0, 7.0), (1.70, 14.0, 5.0),
             (1.90, 10.0, 4.0), (2.22, 0.0, 0.0)]
# 頭往下看（度；另外跟著上半身）
HEAD_KEYS = [(0.00, 0.0), (0.28, 20.0), (0.50, 24.0), (0.85, 14.0), (1.05, 14.0), (1.35, 22.0), (1.50, 22.0),
             (1.70, 16.0), (1.86, 12.0), (2.22, 0.0)]
# 右手肘抬高（度；手肘繞肩膀 → 手腕的軸轉，手不動；負 = 往下）：拉槍機時手肘往上、往外張；
# 換彈匣時往下夾 25°（第 39 項：槍右傾時右手跟著旋前，到 −99；手肘往下 → −58～−64）
# 拉槍機時抬 15°（第 39 項：原本 45°／30°，手肘抬到和肩膀一樣高）
ELBOW_KEYS = [(0.00, 0.0), (0.28, -25.0), (1.40, -25.0), (1.56, 0.0), (1.70, 15.0), (1.86, 15.0), (2.08, 0.0)]
# 左手肘（第 39 項）：IK 沿用瞄準時的手肘方向（高、在前面）→ 換彈匣時手肘往 LEFT_POLE（角色的 右、前、上；跟著上半身轉）
# 轉到多少：(秒, 比例)；0 = IK 原本的手肘、1 = 手肘盡量往 LEFT_POLE（繞肩膀 → 手腕的軸轉，手不動）
LEFT_POLE = (-0.3, -0.2, -1.0)
LEFT_POLE_KEYS = [(0.00, 0.0), (0.24, 1.0), (1.52, 1.0), (1.66, 0.0)]
# 左手腕：'hg' = 底層的護木位置；'pouch' = 左腰（模型座標 POUCH）；('mag', (F, U, R)) = 握彈匣的手再移 (F, U, R)；
# 其他 = 槍座標 (F, U, R)，方向同護木
LEFT_KEYS = [
    (0.00, 'hg'),
    (0.30, ('mag', (0.0, 0.0, 0.0))),       # 握住彈匣（遊戲裡這一格抓：gfg_ak47.ws GfgMagTick 的抓的點 = 下面印的手腕位置）
    (0.50, ('mag', (0.04, -0.11, -0.02))),  # 往前下拉出
    (0.85, 'pouch'),
    (1.05, 'pouch'),
    (1.35, ('mag', (0.01, -0.07, -0.01))),  # 新彈匣在彈匣口下
    (1.50, ('mag', (0.0, 0.0, 0.0))),       # 裝上
    (1.64, 'hg'),                           # 回護木：右手拉槍機時撐住槍
    (2.40, 'hg'),
]
# 右手（掌心中心）：'grip' = 握把（底層的握法）；('rack', (F, U, R)) = 拉槍機的手勢、掌心中心在拉柄再移 (F, U, R)；
# ('mid', (F, U, R), w) = 掌心中心在槍座標 (F, U, R)、手勢從握把轉到拉槍機的 w（繞到槍的右邊，不穿過機匣）
RIGHT_KEYS = [
    (0.00, 'grip'),
    (1.56, 'grip'),
    (1.63, ('mid', (0.10, 0.10, 0.14), 0.6)),
    (1.70, ('rack', (0.0, 0.0, 0.0))),      # 抓住拉柄
    (1.80, ('rack', (-0.12, 0.0, 0.0))),    # 往後拉到底
    (1.85, ('rack', (-0.13, 0.03, 0.04))),  # 放開
    (1.97, ('mid', (-0.02, 0.06, 0.12), 0.3)),
    (2.08, 'grip'),
    (2.40, 'grip'),
]
CHARGING_HANDLE = (0.231, 0.105, 0.070)  # 拉柄（槍座標；量的點 R +0.045 往外 2.5 公分：拳頭握在拉柄的頭上，不碰機匣）
RACK_PALM = (0.0, -0.7071, -0.7071)     # 拉槍機時掌心朝哪（槍座標 F、U、R）：朝左下，從右上方抓（第 39 項：正下方 → 手肘不抬高時屈腕 +42、尺偏 −45）
RACK_DEV = -5.0                          # 拉槍機的手：長軸對齊前臂再偏幾度（＋往拇指）
PALM_R = np.array([0.061, 0.032, -0.002, 1.0])  # 右掌心，r_hand 座標（two_hand_pose.py）
PALM_L = PALM_R * np.array([1.0, 1.0, -1.0, 1.0])  # 左掌心（左右的手骨 Z 相反：手指根 z 正負相反）
# 握彈匣（第 39 項）：掌心中心貼在彈匣左面（MAG_CONTACT：彈匣中線 U −0.022 那點、往左到左面外 3 公釐），
# 手的長軸在掌面內對齊前臂、偏 MAG_DEV（＋往拇指）；長軸離彈匣前緣的方向最多 ±MAG_SPREAD 度（拇指留在彈匣後緣、卡榫那邊）
# 量法（暫存 s19\hg_slice.py、mag_axis.py）：彈匣中線 上 (F 0.168, U 0.084) → 下 (0.247, −0.108)、厚 ±0.013、前後深 0.08～0.10
MAG_DOWN = (0.383, -0.924)           # 彈匣中線往下（F, U）
MAG_CONTACT = (0.203, -0.022, -0.016)
MAG_DEV = -10.0
MAG_SPREAD = 45.0
# 左腰的手：解剖角度（旋前、屈腕、橈偏；度）：掌心朝身體（原版 Geralt 手臂放鬆時左手 旋前 −30～−15、屈腕 −19～0）、
# 手腕往上翹 25°（彈匣才不會橫著）
POUCH_ANAT = (-20.0, -25.0, -15.0)
# 檢查用的範圍（超出就印出來）：原版 Geralt 的範圍＋人的前臂（旋前到 +60 左右）；底層（瞄準）左手旋前 −107
NAT = {'l': {'旋前': (-120.0, 60.0), '屈腕': (-45.0, 50.0), '橈偏': (-55.0, 25.0)},
       'r': {'旋前': (-80.0, 60.0), '屈腕': (-45.0, 45.0), '橈偏': (-45.0, 20.0)}}
# 左腰：正面持槍底層（--pouch-ref）的模型座標；換成相對骨盆，騎馬的底層用自己的骨盆換回來
# （遊戲裡 torso 以上照這段動畫、骨盆換成騎乘的 → 相對骨盆的位置不變）
POUCH = np.array([-0.24, 0.12, 1.04])   # 第 39 項：(-0.17, 0.08, 1.02) → 往外、往前：掌心朝身體，彈匣在掌心和身體之間
POUCH_REF = Path(__file__).resolve().parent.parent / 'assets' / 'anims' / 'gfg' / 'square' / 'man_geralt_gabriel_aim_idle_square.re'
LEFT_ARM = ('l_bicep', 'l_forearm', 'l_hand')
RIGHT_ARM = ('r_bicep', 'r_forearm', 'r_hand')
ROLLS = [f'{s}_{b}' for s in 'lr' for b in ('forearmRoll1', 'forearmRoll2', 'handRoll', 'elbowRoll', 'shoulderRoll', 'bicep2')]
BICEP2 = {'l': (-0.92, 0.8), 'r': (-0.97, -6.0)}   # bicep2 的扭轉 = a × 上臂相對鎖骨的扭轉 + b（度）


def hermite(keys: list, t: float) -> np.ndarray:
    """keys：[(時間, 值 ndarray)]；中間的關鍵格速度 = 前後兩格的斜率（前後值一樣時 0），頭尾速度 0。"""
    ts = [k[0] for k in keys]
    vs = [np.asarray(k[1], dtype=float) for k in keys]
    if t <= ts[0]:
        return vs[0]
    if t >= ts[-1]:
        return vs[-1]
    i = max(j for j in range(len(ts) - 1) if ts[j] <= t)

    def vel(j):
        if j == 0 or j == len(ts) - 1:
            return np.zeros_like(vs[j])
        if np.allclose(vs[j], vs[j - 1]) or np.allclose(vs[j], vs[j + 1]):
            return np.zeros_like(vs[j])
        return (vs[j + 1] - vs[j - 1]) / (ts[j + 1] - ts[j - 1])

    h = ts[i + 1] - ts[i]
    u = (t - ts[i]) / h
    h00, h10, h01, h11 = 2 * u ** 3 - 3 * u ** 2 + 1, u ** 3 - 2 * u ** 2 + u, -2 * u ** 3 + 3 * u ** 2, u ** 3 - u ** 2
    return h00 * vs[i] + h10 * h * vel(i) + h01 * vs[i + 1] + h11 * h * vel(i + 1)


def segment(keys: list, t: float) -> tuple[int, float]:
    ts = [k[0] for k in keys]
    if t >= ts[-1]:
        return len(ts) - 2, 1.0
    i = max(j for j in range(len(ts) - 1) if ts[j] <= t)
    u = (t - ts[i]) / (ts[i + 1] - ts[i])
    return i, u * u * (3 - 2 * u)


def slerp_rot(r0: np.ndarray, r1: np.ndarray, w: float) -> np.ndarray:
    rel = r0.T @ r1
    return r0 @ M.rot_pow(rel, w)


def twist_x(r: np.ndarray) -> float:
    """旋轉 r 繞自己 X 軸的扭轉角（度；swing-twist 分解 r = swing · twist）。"""
    q = A.mat_to_quat(r)
    if abs(q[0]) < 1e-12 and abs(q[3]) < 1e-12:
        return 180.0
    return (2 * math.degrees(math.atan2(q[0], q[3])) + 180) % 360 - 180


def arm_frame(s: str, shoulder, elbow, wrist, forearm_rot: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """前臂軸 a、內側 med（垂直 a）：內側 = 手肘鉸鏈軸（上臂 × 前臂；左 ＋、右 −）；手肘幾乎伸直時用前臂骨的 Z。"""
    u, a = S.unit(elbow - shoulder), S.unit(wrist - elbow)
    n = np.cross(u, a)
    if np.linalg.norm(n) < 0.15:
        n = forearm_rot @ np.array([0.0, 0.0, 1.0])
    n = S.unit(n - (n @ a) * a)
    return a, (1.0 if s == 'l' else -1.0) * n


def anat(s: str, frame, r_hand: np.ndarray) -> np.ndarray:
    """手的方向 → (旋前, 屈腕, 橈偏)（度）。"""
    sg = 1.0 if s == 'l' else -1.0
    a, med = frame
    pn = r_hand @ np.array([0.0, 1.0, 0.0])
    pn_ = S.unit(pn - (pn @ a) * a)
    pron = sg * math.degrees(math.atan2(np.cross(med, pn_) @ a, med @ pn_))
    hx = r_hand @ X
    th = r_hand @ np.array([0.0, 0.0, -sg])
    th_ = S.unit(th - (th @ a) * a - (th @ pn_) * pn_)
    return np.array([pron, math.degrees(math.atan2(hx @ pn_, hx @ a)), math.degrees(math.atan2(hx @ th_, hx @ a))])


def hand_from_anat(s: str, frame, ang) -> np.ndarray:
    """(旋前, 屈腕, 橈偏) → 手的方向（anat 的反函數；手腕彎的時候有一點點誤差，用關鍵格的修正補）。"""
    sg = 1.0 if s == 'l' else -1.0
    a, med = frame
    pron, wflex, wdev = ang
    pn_ = A.axis_angle(a, sg * pron) @ med
    th_ = sg * np.cross(pn_, a)
    hx = S.unit(a + math.tan(math.radians(wflex)) * pn_ + math.tan(math.radians(wdev)) * th_)
    y = S.unit(pn_ - (pn_ @ hx) * hx)
    return np.column_stack((hx, y, np.cross(hx, y)))


def palm_aligned(s: str, palm: np.ndarray, a: np.ndarray, dev: float, front=None, spread: float = 180.0) -> np.ndarray:
    """掌心朝 palm、手的長軸 = 前臂 a 投影到掌面再往拇指偏 dev 度；front：長軸離這個方向最多 spread 度。"""
    sg = 1.0 if s == 'l' else -1.0
    y = S.unit(palm)
    x0 = a - (a @ y) * y
    x0 = S.unit(x0) if np.linalg.norm(x0) > 1e-6 else S.unit(np.cross(y, [0.0, 0.0, 1.0]))
    x = A.axis_angle(y, sg * dev) @ x0
    if front is not None:
        f = S.unit(front - (front @ y) * y)
        ang = math.degrees(math.atan2(np.cross(f, x) @ y, f @ x))
        if abs(ang) > spread:
            x = A.axis_angle(y, math.copysign(spread, ang)) @ f
    return np.column_stack((x, y, np.cross(x, y)))


def bake_rolls(hier, loc: dict, loc0: dict) -> None:
    """扭轉骨頭照原版 Geralt 動畫的規則設區域旋轉（位置照底層）。"""
    w = S.fk4(hier, loc)
    for s in 'lr':
        fa, hd = w[f'{s}_forearm'][:3, :3], w[f'{s}_hand'][:3, :3]
        rel = fa.T @ hd
        tw = twist_x(rel)
        sw = rel @ A.axis_angle(X, tw).T
        loc[f'{s}_forearmRoll1'] = (A.axis_angle(X, 0.2 * tw), loc0[f'{s}_forearmRoll1'][1])
        loc[f'{s}_forearmRoll2'] = (A.axis_angle(X, 0.5 * tw), loc0[f'{s}_forearmRoll2'][1])
        loc[f'{s}_handRoll'] = (A.axis_angle(X, -0.7 * tw) @ M.rot_pow(sw, 0.5) @ A.axis_angle(X, 0.9 * tw),
                                loc0[f'{s}_handRoll'][1])
        bi, sh = w[f'{s}_bicep'][:3, :3], w[f'{s}_shoulder'][:3, :3]
        loc[f'{s}_elbowRoll'] = (fa.T @ bi @ M.rot_pow(bi.T @ fa, 0.5), loc0[f'{s}_elbowRoll'][1])
        loc[f'{s}_shoulderRoll'] = (M.rot_pow(sh.T @ bi, 0.5), loc0[f'{s}_shoulderRoll'][1])
        k, b = BICEP2[s]
        loc[f'{s}_bicep2'] = (A.axis_angle(X, k * twist_x(sh.T @ bi) + b), loc0[f'{s}_bicep2'][1])


def body_axes(g0: np.ndarray) -> np.ndarray:
    """角色的 右、前、上（行向量）：前 = 底層槍管的水平方向（騎馬 trot 的檔整個模型朝後，不能用模型的軸）。"""
    f = g0[:3, :3] @ GF
    f = S.unit(np.array([f[0], f[1], 0.0]))
    up = np.array([0.0, 0.0, 1.0])
    return np.array([np.cross(f, up), f, up])


def gun_at(t: float, g0: np.ndarray, grip0: np.ndarray, body: np.ndarray) -> np.ndarray:
    v = hermite([(k[0], k[1:]) for k in GUN_KEYS], t)
    d, roll, pitch, yaw = body.T @ v[:3], v[3], v[4], v[5]
    f0, r0 = g0[:3, :3] @ GF, g0[:3, :3] @ GR
    rg = A.axis_angle(body[2], -yaw) @ A.axis_angle(r0, pitch) @ A.axis_angle(f0, roll)
    m = np.eye(4)
    m[:3, :3] = rg @ g0[:3, :3]
    m[:3, 3] = grip0 + d + rg @ (g0[:3, 3] - grip0)
    return m


def elbow_lift(solved: dict, bones: tuple[str, str, str], deg: float) -> None:
    """兩節手臂解好之後，手肘繞「肩膀 → 手腕」的軸轉 deg 度（正 = 手肘往上、負 = 往下）；手的位置、方向不變。"""
    upper, lower, hand = bones
    s, e, w = (solved[b][:3, 3] for b in bones)
    u = S.unit(w - s)
    if (A.axis_angle(u, 1.0) @ (e - s))[2] < (e - s)[2]:
        u = -u
    r = A.axis_angle(u, deg)
    solved[upper] = S.rigid(r @ solved[upper][:3, :3], s)
    solved[lower] = S.rigid(r @ solved[lower][:3, :3], s + r @ (e - s))


def set_pole(solved: dict, bones: tuple[str, str, str], pole: np.ndarray, weight: float) -> None:
    """手肘繞「肩膀 → 手腕」的軸往 pole 的方向轉（weight = 轉到的比例）；手的位置、方向不變。"""
    upper, lower, hand = bones
    s, e, w = (solved[b][:3, 3] for b in bones)
    u = S.unit(w - s)
    eo = (e - s) - ((e - s) @ u) * u
    po = pole - (pole @ u) * u
    if np.linalg.norm(eo) < 1e-6 or np.linalg.norm(po) < 1e-6:
        return
    ang = math.degrees(math.atan2(np.cross(eo, po) @ u, eo @ po)) * weight
    r = A.axis_angle(u, ang)
    solved[upper] = S.rigid(r @ solved[upper][:3, :3], s)
    solved[lower] = S.rigid(r @ solved[lower][:3, :3], s + r @ (e - s))


def seg_dist(p: np.ndarray, a: np.ndarray, b: np.ndarray) -> float:
    """點 p 到線段 ab 的距離。"""
    ab = b - a
    u = min(1.0, max(0.0, float((p - a) @ ab / (ab @ ab))))
    return float(np.linalg.norm(p - (a + u * ab)))


def gun_point(g: np.ndarray, fur) -> np.ndarray:
    f, u, r = fur
    return g[:3, :3] @ (A.GRIP + f * GF + u * GU + r * GR) + g[:3, 3]


def extend(src: Path, dst: Path, n: int) -> None:
    """複製底層、每根骨頭都改成 n 格的第 0 格（同 move_pose.trim 的寫法）。"""
    shutil.copyfile(src, dst)
    with h5py.File(dst, 'r+') as f:
        clip = f[A.CLIP]
        for k in list(clip.keys()):
            if not isinstance(clip[k], h5py.Group):
                continue
            ds = clip[k]['xformframes']
            data = ds[()]
            attrs = dict(ds.attrs)
            kwargs = {'chunks': True} if ds.chunks else {}
            new = np.repeat(data[:1], n, axis=0)
            flat = new.reshape(-1)
            if 'time' in flat.dtype.names:
                flat['time'][:] = np.arange(n, dtype=flat['time'].dtype)
            del clip[k]['xformframes']
            out = clip[k].create_dataset('xformframes', data=new, **kwargs)
            for a, v in attrs.items():
                out.attrs[a] = v
        f[M.ANIM].attrs['.numkeys'] = n
        f[M.ANIM].attrs['.animlength'] = (n - 1) / FPS


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8')
    p = argparse.ArgumentParser(description='AK 的換彈動畫（正面持槍底層，關鍵格＋IK）')
    p.add_argument('base', type=Path)
    p.add_argument('out', type=Path)
    p.add_argument('--length', type=float, default=2.4, help='長度（秒，預設 2.4）')
    p.add_argument('--pouch-ref', type=Path, default=POUCH_REF, help='POUCH 是哪個檔第 0 格的模型座標（預設正面持槍底層）')
    p.add_argument('--pouch-bone', default='pelvis',
                   help='左腰跟著哪根骨頭（預設 pelvis：腰帶在骨盆上；torso = 和地面一樣的上半身相對位置）')
    p.add_argument('--pouch', type=float, nargs=3, default=None, metavar=('X', 'Y', 'Z'),
                   help='左腰（--pouch-ref 第 0 格的模型座標；預設 POUCH）；騎馬：大腿抬高會擋住前腰 → 往側邊、往上')
    a = p.parse_args()
    if a.out.name.startswith('man_'):
        print(f'停止：輸出檔名 {a.out.name} 是 man_ 開頭；動畫組裡的名稱是 gfg_，用 man_ 匯入會多一筆、蓋過原版十字弩（docs/findings.md §34.2）')
        return 1

    hier = A.read_skeleton(a.base)
    par = dict(hier)
    base = M.read_frames(a.base)
    loc0 = {k: M.local(v[0]) for k, v in base.items()}
    w0 = S.fk4(hier, loc0)
    wr = S.fk4(A.read_skeleton(a.pouch_ref), {k: M.local(v[0]) for k, v in M.read_frames(a.pouch_ref).items()})
    pb = a.pouch_bone
    pouch = (w0[pb] @ np.linalg.inv(wr[pb]) @ np.append(POUCH if a.pouch is None else np.array(a.pouch), 1.0))[:3]
    print(f'左腰（跟著 {pb}）：模型 ({pouch[0]:+.3f},{pouch[1]:+.3f},{pouch[2]:+.3f})（{pb} {np.round(w0[pb][:3, 3], 3)}）')
    g0 = w0['l_weapon']
    grip0 = g0[:3, :3] @ A.GRIP + g0[:3, 3]
    rel_r = np.linalg.inv(g0) @ w0['r_hand']
    rel_l = np.linalg.inv(g0) @ w0['l_hand']
    hg_lw = rel_l[:3, 3] - A.GRIP
    hg = (hg_lw @ GF, hg_lw @ GU, hg_lw @ GR)
    body = body_axes(g0)
    ch = A.GRIP + CHARGING_HANDLE[0] * GF + CHARGING_HANDLE[1] * GU + CHARGING_HANDLE[2] * GR
    m_lw = MAG_DOWN[0] * GF + MAG_DOWN[1] * GU          # 彈匣往下（l_weapon 座標）
    n_lw = -MAG_DOWN[1] * GF + MAG_DOWN[0] * GU         # 彈匣前緣的方向
    contact = A.GRIP + MAG_CONTACT[0] * GF + MAG_CONTACT[1] * GU + MAG_CONTACT[2] * GR

    def torso_at(t: float):
        """上半身往右轉、往前彎（torso2、torso3 各轉一半）、頭往下看 → (區域變換, FK, 上半身的剛體變換)。"""
        twist, lean = hermite([(k[0], np.array(k[1:])) for k in BODY_KEYS], t)
        rb = A.axis_angle(body[2], -twist / 2) @ A.axis_angle(body[0], -lean / 2)
        loc = dict(loc0)
        tb = np.eye(4)
        for bone in ('torso2', 'torso3'):
            wcur = S.fk4(hier, loc)
            p_ = wcur[bone][:3, 3]
            loc[bone] = (wcur[par[bone]][:3, :3].T @ rb @ wcur[bone][:3, :3], loc0[bone][1])
            tb = S.rigid(rb, p_ - rb @ p_) @ tb
        wl = S.fk4(hier, loc)
        hdeg = float(hermite([(k[0], np.array([k[1]])) for k in HEAD_KEYS], t)[0])
        hw = A.axis_angle(body[0], -hdeg) @ wl['head'][:3, :3]
        loc['head'] = (wl[par['head']][:3, :3].T @ hw, loc0['head'][1])
        return loc, S.fk4(hier, loc), tb, twist, lean, hdeg

    def lift_at(t: float) -> float:
        return float(hermite([(k[0], np.array([k[1]])) for k in ELBOW_KEYS], t)[0])

    def solve_arm(wl: dict, bones, target: np.ndarray, t: float, tb: np.ndarray) -> dict:
        sol = S.two_bone_ik(wl, bones, target)
        if bones == RIGHT_ARM:
            lift = lift_at(t)
            if abs(lift) > 1e-6:
                elbow_lift(sol, bones, lift)
        else:
            wgt = float(hermite([(k[0], np.array([k[1]])) for k in LEFT_POLE_KEYS], t)[0])
            if wgt > 1e-6:
                set_pole(sol, bones, tb[:3, :3] @ (body.T @ np.array(LEFT_POLE)), wgt)
        return sol

    def frame_of(s: str, sol: dict, bones) -> tuple:
        return arm_frame(s, *(sol[b][:3, 3] for b in bones), sol[bones[1]][:3, :3])

    # 握彈匣（l_weapon 座標）：掌心貼彈匣左面、長軸對齊抓（0.30 秒）和裝上（1.50 秒）兩個時刻的前臂平均
    # → 手腕位置跟著變 → 再解 IK，迭代
    t_mags = [kt for kt, kv in LEFT_KEYS if kv != 'hg' and kv != 'pouch' and kv[0] == 'mag' and not any(kv[1])]
    at_mags = []
    for tm in t_mags:
        _, wl_m, tb_m, *_ = torso_at(tm)
        at_mags.append((tm, wl_m, tb_m, tb_m @ gun_at(tm, g0, grip0, body)))
    a_lw = n_lw.copy()
    for it in range(20):
        rk = palm_aligned('l', GR, a_lw, MAG_DEV, front=n_lw, spread=MAG_SPREAD)
        mag_rel = S.rigid(rk, contact - rk @ PALM_L[:3])
        a_new = np.zeros(3)
        for tm, wl_m, tb_m, g_m in at_mags:
            sol = solve_arm(wl_m, LEFT_ARM, g_m @ mag_rel, tm, tb_m)
            a_new += g_m[:3, :3].T @ frame_of('l', sol, LEFT_ARM)[0]
        a_new = S.unit(a_new)
        if np.linalg.norm(a_new - a_lw) < 1e-5:
            break
        a_lw = a_new
    mg = mag_rel[:3, 3] - A.GRIP
    print(f'握彈匣：手腕 槍座標 F {mg @ GF:+.4f} U {mg @ GU:+.4f} R {mg @ GR:+.4f}（遊戲裡抓的點；迭代 {it + 1} 次）')
    # 拉槍機（l_weapon 座標）：掌心朝 RACK_PALM、長軸對齊抓住拉柄那一格（含手肘抬高）的前臂，同樣迭代
    t_rack = next(kt for kt, kv in RIGHT_KEYS if kv != 'grip' and kv[0] == 'rack')
    _, wl_r, tb_r, *_ = torso_at(t_rack)
    g_rack = tb_r @ gun_at(t_rack, g0, grip0, body)
    palm_rk = RACK_PALM[0] * GF + RACK_PALM[1] * GU + RACK_PALM[2] * GR
    a_lw = GF.copy()
    for it in range(12):
        rk = palm_aligned('r', palm_rk, a_lw, RACK_DEV)
        rack_rel = S.rigid(rk, ch - rk @ PALM_R[:3])
        sol = solve_arm(wl_r, RIGHT_ARM, g_rack @ rack_rel, t_rack, tb_r)
        a_new = g_rack[:3, :3].T @ frame_of('r', sol, RIGHT_ARM)[0]
        if np.linalg.norm(a_new - a_lw) < 1e-5:
            break
        a_lw = a_new
    rack_rot = rack_rel[:3, :3]

    def right_rel(kv) -> np.ndarray:
        """右手的關鍵格 → 右手（r_hand）相對槍的 4×4（l_weapon 座標）。"""
        if kv == 'grip':
            return rel_r
        if kv[0] == 'rack':
            d = kv[1]
            rk, pc = rack_rot, ch + d[0] * GF + d[1] * GU + d[2] * GR
        else:
            fur, wgt = kv[1], kv[2]
            rk, pc = slerp_rot(rel_r[:3, :3], rack_rot, wgt), A.GRIP + fur[0] * GF + fur[1] * GU + fur[2] * GR
        return S.rigid(rk, pc - rk @ PALM_R[:3])

    r_rel = [(kt, right_rel(kv)) for kt, kv in RIGHT_KEYS]

    def kind(kv) -> str:
        return kv if isinstance(kv, str) else kv[0]

    def left_key(kv, g: np.ndarray) -> tuple[np.ndarray, np.ndarray | None]:
        """左手的關鍵格 → (手腕位置, 方向)（模型座標；左腰的方向 None = 照解剖角度算）。"""
        if kv == 'hg':
            return gun_point(g, hg), g[:3, :3] @ rel_l[:3, :3]
        if kv == 'pouch':
            return pouch, None
        if kv[0] == 'mag':
            d = kv[1]
            return (g @ np.append(mag_rel[:3, 3] + d[0] * GF + d[1] * GU + d[2] * GR, 1.0))[:3], g[:3, :3] @ mag_rel[:3, :3]
        return gun_point(g, kv), g[:3, :3] @ rel_l[:3, :3]

    # 每個關鍵格的解剖角度、修正（關鍵格那一刻的 IK）：進出左腰的兩段用
    key_ang, key_fix = [], []
    for kt, kv in LEFT_KEYS:
        _, wl_k, tb_k, *_ = torso_at(kt)
        pos, rot = left_key(kv, tb_k @ gun_at(kt, g0, grip0, body))
        sol = solve_arm(wl_k, LEFT_ARM, S.rigid(np.eye(3), pos), kt, tb_k)
        fr = frame_of('l', sol, LEFT_ARM)
        if rot is None:
            key_ang.append(np.array(POUCH_ANAT))
            key_fix.append(np.eye(3))
        else:
            ang = anat('l', fr, rot)
            key_ang.append(ang)
            key_fix.append(hand_from_anat('l', fr, ang).T @ rot)
    print('左手關鍵格的解剖角度（旋前、屈腕、橈偏）：' + '；'.join(
        f'{kt:.2f}s {kind(kv)} ({an[0]:+.0f},{an[1]:+.0f},{an[2]:+.0f})' for (kt, kv), an in zip(LEFT_KEYS, key_ang)))

    # 彈匣（握住時的相對位置）：手 → 彈匣看得到的那段的中點、上下兩端（檢查有沒有插進身體）
    inv_mag = np.linalg.inv(mag_rel)
    mag_pts = [inv_mag @ np.append(A.GRIP + GF * f + GU * u, 1.0) for f, u in ((0.205, -0.012), (0.175, 0.07), (0.245, -0.10))]

    n = int(round(a.length * FPS)) + 1
    changed = ['torso2', 'torso3', 'head', 'l_weapon'] + list(LEFT_ARM) + list(RIGHT_ARM) + ROLLS
    results, worst, reach, rreach = [], {'右手': 0.0, '左手': 0.0, '槍': 0.0}, [], []
    butt_min, arm_min, mag_min = 1.0, 1.0, (1.0, 0.0)
    nat_rng = {s: {k: [999.0, -999.0, 0.0, 0.0] for k in NAT[s]} for s in 'lr'}
    for i in range(n):
        t = i / FPS
        loc, wl, tb, twist, lean, hdeg = torso_at(t)
        g = tb @ gun_at(t, g0, grip0, body)
        # 左手：位置（Hermite）→ IK → 方向（貼在槍上的段：槍座標 slerp；進出左腰：解剖角度內插）
        keys = [(kt,) + left_key(kv, g) for kt, kv in LEFT_KEYS]
        lpos = hermite([(k[0], k[1]) for k in keys], t)
        si, sw = segment(keys, t)
        lsol = solve_arm(wl, LEFT_ARM, S.rigid(np.eye(3), lpos), t, tb)
        if keys[si][2] is None or keys[si + 1][2] is None:
            fr = frame_of('l', lsol, LEFT_ARM)
            ang = (1 - sw) * key_ang[si] + sw * key_ang[si + 1]
            lrot = hand_from_anat('l', fr, ang) @ slerp_rot(key_fix[si], key_fix[si + 1], sw)
        else:
            lrot = slerp_rot(keys[si][2], keys[si + 1][2], sw)
        lsol['l_hand'] = S.rigid(lrot, lpos)
        # 右手：關鍵格換成這一格的模型座標
        rkeys = [(kt, g @ m) for kt, m in r_rel]
        rpos = hermite([(k[0], k[1][:3, 3]) for k in rkeys], t)
        ri, rw = segment(rkeys, t)
        rt = S.rigid(slerp_rot(rkeys[ri][1][:3, :3], rkeys[ri + 1][1][:3, :3], rw), rpos)
        rsol = solve_arm(wl, RIGHT_ARM, rt, t, tb)
        for bones, sol in ((LEFT_ARM, lsol), (RIGHT_ARM, rsol)):
            parent = wl[par[bones[0]]]
            for name in bones:
                m = np.linalg.inv(parent) @ sol[name]
                loc[name] = (m[:3, :3], loc0[name][1])
                parent = sol[name]
        # l_weapon 用 FK 讀回的左手算（搆不到時 two_bone_ik 回傳的手腕是目標，不是實際位置 → 槍會跟著偏）
        m = np.linalg.inv(S.fk4(hier, loc)['l_hand']) @ g
        loc['l_weapon'] = (m[:3, :3], m[:3, 3])
        bake_rolls(hier, loc, loc0)
        results.append(loc)
        # 檢查：FK 讀回
        wn = S.fk4(hier, loc)
        worst['右手'] = max(worst['右手'], float(np.linalg.norm(wn['r_hand'][:3, 3] - rt[:3, 3])))
        worst['左手'] = max(worst['左手'], float(np.linalg.norm(wn['l_hand'][:3, 3] - lpos)))
        worst['槍'] = max(worst['槍'], float(np.linalg.norm(wn['l_weapon'][:3, 3] - g[:3, 3])))
        s_, e_, w_ = (wn[b][:3, 3] for b in LEFT_ARM)
        reach.append(np.linalg.norm(w_ - s_) / (np.linalg.norm(e_ - s_) + np.linalg.norm(w_ - e_)))
        s_, e_, w_ = (wn[b][:3, 3] for b in RIGHT_ARM)
        rreach.append(np.linalg.norm(w_ - s_) / (np.linalg.norm(e_ - s_) + np.linalg.norm(w_ - e_)))
        # 解剖角度（讀回的姿勢）
        nat = {}
        for s, bones in (('l', LEFT_ARM), ('r', RIGHT_ARM)):
            fr = arm_frame(s, *(wn[b][:3, 3] for b in bones), wn[bones[1]][:3, :3])
            nat[s] = anat(s, fr, wn[bones[2]][:3, :3])
            for k, v in zip(NAT[s], nat[s]):
                r_ = nat_rng[s][k]
                r_[0], r_[1] = min(r_[0], v), max(r_[1], v)
                lo, hi = NAT[s][k]
                if v < lo - 0.5 or v > hi + 0.5:
                    r_[2] += 1
                    r_[3] = max(r_[3], lo - v, v - hi)
        # 槍托後端離脊椎（torso → neck 的折線）多遠：檢查放低、往後收時有沒有插進胸口
        butt = (g @ np.append(S.BUTT, 1.0))[:3]
        spine = [wn[b][:3, 3] for b in ('pelvis', 'torso', 'torso2', 'torso3', 'neck')]
        bd = min(seg_dist(butt, spine[k], spine[k + 1]) for k in range(1, len(spine) - 1))
        butt_min = min(butt_min, bd)
        # 槍托（後端到握把的中點）離右上臂（r_bicep → r_forearm）多遠：槍口往左下時槍托翹到右肩前，不能插進上臂
        stock = [butt, (g @ np.append((S.BUTT + A.GRIP) / 2, 1.0))[:3]]
        ad = min(seg_dist(p, wn['r_bicep'][:3, 3], wn['r_forearm'][:3, 3]) for p in stock)
        arm_min = min(arm_min, ad)
        # 彈匣在手上的期間（抓～裝上）：離身體表面多遠（脊椎的折線半徑 0.14、左大腿半徑 0.08 當身體；負的 = 插進去）
        md = None
        if LEFT_KEYS[1][0] < t < LEFT_KEYS[6][0]:
            pts = [(wn['l_hand'] @ q)[:3] for q in mag_pts]
            md = min(min(seg_dist(q, spine[k], spine[k + 1]) for k in range(len(spine) - 1) for q in pts) - 0.14,
                     min(seg_dist(q, wn['l_thigh'][:3, 3], wn['l_shin'][:3, 3]) for q in pts) - 0.08)
            if md < mag_min[0]:
                mag_min = (md, t)
        if i % 3 == 0 or i == n - 1:
            d, rd, le = wn['l_hand'][:3, 3], wn['r_hand'][:3, 3], wn['l_forearm'][:3, 3] - wn['l_bicep'][:3, 3]
            le_b = body @ le
            nl, nr = nat['l'], nat['r']
            print(f'  {t:4.2f}s：左腕 ({d[0]:+.2f},{d[1]:+.2f},{d[2]:+.2f}) 伸 {reach[-1]:.2f} 肘(右前上) ({le_b[0]:+.2f},{le_b[1]:+.2f},{le_b[2]:+.2f}) '
                  f'旋前 {nl[0]:+4.0f} 屈 {nl[1]:+4.0f} 橈 {nl[2]:+4.0f}｜右腕 ({rd[0]:+.2f},{rd[1]:+.2f},{rd[2]:+.2f}) 伸 {rreach[-1]:.2f} '
                  f'旋前 {nr[0]:+4.0f} 屈 {nr[1]:+4.0f} 橈 {nr[2]:+4.0f}｜槍托離脊椎 {bd:.2f}、離右上臂 {ad:.2f}'
                  + (f'、彈匣離身體 {md:.2f}' if md is not None else '') + f'｜右轉 {twist:.0f}° 前彎 {lean:.0f}° 頭 {hdeg:.0f}°')

    extend(a.base, a.out, n)
    with h5py.File(a.out, 'r+') as f:
        clip = f[A.CLIP]
        for bone in changed:
            ds = clip[bone]['xformframes']
            data = ds[()]
            flat = data.reshape(-1)
            for i in range(n):
                r, tr = results[i][bone]
                for c, v in zip(ROT, A.mat_to_quat(r.T)):  # 區域旋轉 → 檔案的四元數（轉置）
                    flat[c][i] = v
                for c, v in zip(POS, np.asarray(tr) * 100):  # 公尺 → 公分
                    flat[c][i] = v
            ds[...] = data

    # 讀回檢查第 0 格、最後一格和底層一樣（位置；扭轉骨頭照規則重算，旋轉和底層不同）
    out = M.read_frames(a.out)
    wa = S.fk4(hier, {k: M.local(v[0]) for k, v in out.items()})
    wz = S.fk4(hier, {k: M.local(v[n - 1]) for k, v in out.items()})
    d0 = max(float(np.linalg.norm(wa[b][:3, 3] - w0[b][:3, 3])) for b in changed)
    d1 = max(float(np.linalg.norm(wz[b][:3, 3] - w0[b][:3, 3])) for b in changed)
    print(f'寫好 {a.out}：{n} 格（{a.length} 秒）')
    print(f'檢查：右手和目標最多差 {worst["右手"] * 1000:.2f} 公釐、左手 {worst["左手"] * 1000:.2f} 公釐（搆不到時會大）、'
          f'槍 {worst["槍"] * 1000:.3f} 公釐；左臂伸直 {min(reach):.2f}～{max(reach):.2f}、右臂 {min(rreach):.2f}～{max(rreach):.2f}；'
          f'槍托離脊椎最近 {butt_min:.3f}、離右上臂最近 {arm_min:.3f} 公尺；彈匣離身體最近 {mag_min[0]:.3f}（{mag_min[1]:.2f}s）；'
          f'第 0 格和底層差 {d0 * 1000:.3f}、最後一格 {d1 * 1000:.3f} 公釐')
    for s, name in (('l', '左手'), ('r', '右手')):
        print(f'解剖角度 {name}：' + '；'.join(
            f'{k} {v[0]:+.0f}～{v[1]:+.0f}（範圍 {NAT[s][k][0]:+.0f}～{NAT[s][k][1]:+.0f}'
            + (f'，超出 {int(v[2])} 格、最多 {v[3]:.0f}°）' if v[2] else '）') for k, v in nat_rng[s].items()))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
