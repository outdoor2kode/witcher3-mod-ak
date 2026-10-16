"""AK 的換彈動畫（使用者回報的第一批第 8 項：「換彈現在完全沒有動畫 → 做一個真正的 AK-47 換彈動畫」）。

用法（Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/reload_pose.py
        底層.re 輸出.re [--length 2.4]

- 底層：正面持槍，用第 0 格
  - 地面：assets\\anims\\gfg\\square\\man_geralt_gabriel_aim_idle_square.re（輸出 man_geralt_gabriel_reload_lowered、…_reload_front_2）
  - 騎馬：同步伐現在的 assets\\anims\\gfg\\man_geralt_gabriel_horse_{gait}_reload_lowered.re（已含騎乘骨盆的補正，move_pose.py --pelvis-from）
- 輸出：--length 秒（每秒 30 格）；所有骨頭先複製底層第 0 格，再每格改頭、兩手臂、l_weapon
- 動作（關鍵格在下面的表；時間是秒）：槍以握把為軸往身體收、往右傾，左手拿下彈匣 → 左腰換新彈匣 → 裝上 → 繞到右邊拉槍機 → 回到護木
  - 槍：右手一直握著握把（右手 = 槍 · 底層的相對握法）
  - 左手：關鍵格用槍座標（原點 = 握把 ag1_hand_r、F 槍管、U 上、R 右，公尺）或模型座標（左腰）；方向維持底層相對槍的方向（掌心朝上）
  - 位置用三次 Hermite 曲線（中間的關鍵格不停頓；停住的關鍵格前後值一樣時速度 0）；方向 slerp
  - l_weapon 是 l_hand 的子骨頭：左手離開槍的期間，每格設 l_weapon 的區域變換 = 左手⁻¹ · 槍，槍才會照右手走
  - 兩節手臂 IK：square_pose.two_bone_ik
- 量法（docs/handoff.md 第 8 項；暫存 s18\\mag_pos.py）：彈匣底部 F +0.251 U −0.107、彈匣口 F +0.169 U +0.095；
  槍機拉柄 F +0.231 U +0.105 R +0.045；底層左手腕 F +0.261 U +0.045 R −0.046
- 動畫事件（AnimBrowser 加）：OnWeaponReload 1.50 秒（彈匣裝上）、RaiseWeapon 2.15 秒起 0.25 秒
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
GF = S.unit(A.BARREL)                              # 槍座標的軸（l_weapon 座標）
GU = S.unit(S.GUN_UP - GF * (S.GUN_UP @ GF))
GR = np.cross(GF, GU)

# 槍：(秒, 往右, 往前, 往上（公尺，角色的軸：body_axes）, 往右傾（度，上方往右）, 槍口往上（度）)；以握把為軸
GUN_KEYS = [
    (0.00, 0.0, 0.0, 0.0, 0.0, 0.0),
    (0.30, -0.03, -0.06, -0.07, 30.0, 8.0),
    (1.50, -0.03, -0.06, -0.07, 30.0, 8.0),
    (1.70, -0.02, -0.04, -0.05, 12.0, 4.0),
    (1.90, -0.02, -0.04, -0.05, 12.0, 4.0),
    (2.20, 0.0, 0.0, 0.0, 0.0, 0.0),
]
# 頭往下看（度）
HEAD_KEYS = [(0.00, 0.0), (0.30, 15.0), (0.50, 20.0), (0.85, 12.0), (1.05, 12.0), (1.35, 18.0), (1.50, 18.0),
             (1.70, 10.0), (1.90, 10.0), (2.20, 0.0)]
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
    (1.60, (0.24, -0.04, 0.09)),    # 繞到彈匣右邊
    (1.68, (0.23, 0.05, 0.05)),     # 拉柄下方
    (1.80, (0.11, 0.05, 0.05)),     # 往後拉
    (1.88, (0.12, 0.00, 0.02)),     # 放開
    (2.20, 'hg'),
]
# 握彈匣（10-17 04:3x：原本手勢一律同握護木＝掌心朝上，彈匣浮在手掌上方 10 公分）：把握護木的手勢轉到彈匣上
# → 掌心貼彈匣左面、四指繞到前緣、拇指在後緣（彈匣卡榫）；轉換：槍管 → 彈匣往上、上 → 右、右 → 彈匣前方
# 量法（暫存 s19\hg_slice.py、mag_axis.py）：護木截面（F 0.29～0.35）U 0.066～0.12、R ±0.019；
# 彈匣中線 上 (F 0.168, U 0.084) → 下 (0.247, −0.108)、厚 ±0.013、前後深 0.08～0.10
HG_CENTER_UR = (0.095, 0.0)          # 護木截面中心（U, R）
HG_CENTER_DF = 0.07                  # 「握的中心」在手腕往前幾公尺（沿槍管）
MAG_DOWN = (0.383, -0.924)           # 彈匣中線往下（F, U）
MAG_CENTER = (0.203, -0.022, 0.012)  # 握的中心：彈匣中線 U −0.022 那點、往右 1.2 公分（護木比彈匣寬，掌心才貼到彈匣左面）
# 左腰：正面持槍底層（--pouch-ref）的模型座標；換成相對骨盆，騎馬的底層用自己的骨盆換回來
# （遊戲裡 torso 以上照這段動畫、骨盆換成騎乘的 → 相對骨盆的位置不變）
POUCH = np.array([-0.17, 0.08, 1.02])
POUCH_REF = Path(__file__).resolve().parent.parent / 'assets' / 'anims' / 'gfg' / 'square' / 'man_geralt_gabriel_aim_idle_square.re'
LEFT_ARM = ('l_bicep', 'l_forearm', 'l_hand')
RIGHT_ARM = ('r_bicep', 'r_forearm', 'r_hand')


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


def body_axes(g0: np.ndarray) -> np.ndarray:
    """角色的 右、前、上（行向量）：前 = 底層槍管的水平方向（騎馬 trot 的檔整個模型朝後，不能用模型的軸）。"""
    f = g0[:3, :3] @ GF
    f = S.unit(np.array([f[0], f[1], 0.0]))
    up = np.array([0.0, 0.0, 1.0])
    return np.array([np.cross(f, up), f, up])


def gun_at(t: float, g0: np.ndarray, grip0: np.ndarray, body: np.ndarray) -> np.ndarray:
    v = hermite([(k[0], k[1:]) for k in GUN_KEYS], t)
    d, roll, pitch = body.T @ v[:3], v[3], v[4]
    f0, r0 = g0[:3, :3] @ GF, g0[:3, :3] @ GR
    rg = A.axis_angle(r0, pitch) @ A.axis_angle(f0, roll)
    m = np.eye(4)
    m[:3, :3] = rg @ g0[:3, :3]
    m[:3, 3] = grip0 + d + rg @ (g0[:3, 3] - grip0)
    return m


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
    a = p.parse_args()

    hier = A.read_skeleton(a.base)
    par = dict(hier)
    base = M.read_frames(a.base)
    loc0 = {k: M.local(v[0]) for k, v in base.items()}
    w0 = S.fk4(hier, loc0)
    wr = S.fk4(A.read_skeleton(a.pouch_ref), {k: M.local(v[0]) for k, v in M.read_frames(a.pouch_ref).items()})
    pb = a.pouch_bone
    pouch = (w0[pb] @ np.linalg.inv(wr[pb]) @ np.append(POUCH, 1.0))[:3]
    print(f'左腰（跟著 {pb}）：模型 ({pouch[0]:+.3f},{pouch[1]:+.3f},{pouch[2]:+.3f})（{pb} {np.round(w0[pb][:3, 3], 3)}）')
    g0 = w0['l_weapon']
    grip0 = g0[:3, :3] @ A.GRIP + g0[:3, 3]
    rel_r = np.linalg.inv(g0) @ w0['r_hand']
    rel_l = np.linalg.inv(g0) @ w0['l_hand']
    hg_lw = rel_l[:3, 3] - A.GRIP
    hg = (hg_lw @ GF, hg_lw @ GU, hg_lw @ GR)
    body = body_axes(g0)
    g_hold = gun_at(0.5, g0, grip0, body)
    # 握彈匣的手（l_weapon 座標）：轉換 q 把 槍管 → 彈匣往上、上 → 右、右 → 彈匣前方
    m_lw = MAG_DOWN[0] * GF + MAG_DOWN[1] * GU
    n_lw = -MAG_DOWN[1] * GF + MAG_DOWN[0] * GU
    q = np.column_stack((-m_lw, GR, n_lw)) @ np.column_stack((GF, GU, GR)).T
    c_hg = A.GRIP + GF * (hg[0] + HG_CENTER_DF) + GU * HG_CENTER_UR[0] + GR * HG_CENTER_UR[1]
    c_mag = A.GRIP + GF * MAG_CENTER[0] + GU * MAG_CENTER[1] + GR * MAG_CENTER[2]
    mag_rel = np.eye(4)
    mag_rel[:3, :3] = q @ rel_l[:3, :3]
    mag_rel[:3, 3] = c_mag + q @ (rel_l[:3, 3] - c_hg)
    mg = mag_rel[:3, 3] - A.GRIP
    print(f'握彈匣：手腕 槍座標 F {mg @ GF:+.4f} U {mg @ GU:+.4f} R {mg @ GR:+.4f}（遊戲裡抓的點）')
    pouch_rot = g_hold[:3, :3] @ mag_rel[:3, :3]
    # 彈匣（握住時的相對位置）在左腰時的位置：檢查有沒有插進身體
    mag_mid = A.GRIP + GF * 0.205 + GU * (-0.012)    # 彈匣看得到的那段的中點（槍座標）
    mag_off = np.linalg.inv(mag_rel) @ np.append(mag_mid, 1.0)
    pr = S.rigid(pouch_rot, pouch)
    pm = (pr @ mag_off)[:3]
    print(f'左腰時彈匣中點：模型 ({pm[0]:+.3f},{pm[1]:+.3f},{pm[2]:+.3f})')

    n = int(round(a.length * FPS)) + 1
    changed = ['head', 'l_weapon'] + list(LEFT_ARM) + list(RIGHT_ARM)
    results, worst, reach = [], {'右手': 0.0, '左手': 0.0, '槍': 0.0}, []
    for i in range(n):
        t = i / FPS
        g = gun_at(t, g0, grip0, body)
        # 左手的關鍵格換成這一格的模型座標
        keys = []
        for kt, kv in LEFT_KEYS:
            if kv == 'hg':
                keys.append((kt, gun_point(g, hg), g[:3, :3] @ rel_l[:3, :3]))
            elif kv == 'pouch':
                keys.append((kt, pouch, pouch_rot))
            elif kv[0] == 'mag':
                d = kv[1]
                keys.append((kt, (g @ np.append(mag_rel[:3, 3] + d[0] * GF + d[1] * GU + d[2] * GR, 1.0))[:3],
                             g[:3, :3] @ mag_rel[:3, :3]))
            else:
                keys.append((kt, gun_point(g, kv), g[:3, :3] @ rel_l[:3, :3]))
        lpos = hermite([(k[0], k[1]) for k in keys], t)
        si, sw = segment(keys, t)
        lrot = slerp_rot(keys[si][2], keys[si + 1][2], sw)
        lt = S.rigid(lrot, lpos)
        rt = g @ rel_r
        loc = dict(loc0)
        # 頭往下看：繞角色的右方
        hdeg = float(hermite([(k[0], np.array([k[1]])) for k in HEAD_KEYS], t)[0])
        hw = A.axis_angle(body[0], -hdeg) @ w0['head'][:3, :3]
        loc['head'] = (w0[par['head']][:3, :3].T @ hw, loc0['head'][1])
        solved = {}
        solved.update(S.two_bone_ik(w0, LEFT_ARM, lt))
        solved.update(S.two_bone_ik(w0, RIGHT_ARM, rt))
        for bones in (LEFT_ARM, RIGHT_ARM):
            parent = w0[par[bones[0]]]
            for name in bones:
                m = np.linalg.inv(parent) @ solved[name]
                loc[name] = (m[:3, :3], loc0[name][1])
                parent = solved[name]
        # l_weapon 用 FK 讀回的左手算（搆不到時 two_bone_ik 回傳的手腕是目標，不是實際位置 → 槍會跟著偏）
        m = np.linalg.inv(S.fk4(hier, loc)['l_hand']) @ g
        loc['l_weapon'] = (m[:3, :3], m[:3, 3])
        results.append(loc)
        # 檢查：FK 讀回
        wn = S.fk4(hier, loc)
        worst['右手'] = max(worst['右手'], float(np.linalg.norm(wn['r_hand'][:3, 3] - rt[:3, 3])))
        worst['左手'] = max(worst['左手'], float(np.linalg.norm(wn['l_hand'][:3, 3] - lpos)))
        worst['槍'] = max(worst['槍'], float(np.linalg.norm(wn['l_weapon'][:3, 3] - g[:3, 3])))
        s_, e_, w_ = (wn[b][:3, 3] for b in LEFT_ARM)
        reach.append(np.linalg.norm(w_ - s_) / (np.linalg.norm(e_ - s_) + np.linalg.norm(w_ - e_)))
        if i % 6 == 0 or i == n - 1:
            d = wn['l_hand'][:3, 3]
            print(f'  {t:4.2f}s：左手腕 模型 ({d[0]:+.2f},{d[1]:+.2f},{d[2]:+.2f})；左臂伸直 {reach[-1]:.2f}；'
                  f'槍管 {np.round(g[:3, :3] @ GF, 2)}；頭往下 {hdeg:.0f}°')

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

    # 讀回檢查第 0 格、最後一格和底層一樣
    out = M.read_frames(a.out)
    wa = S.fk4(hier, {k: M.local(v[0]) for k, v in out.items()})
    wz = S.fk4(hier, {k: M.local(v[n - 1]) for k, v in out.items()})
    d0 = max(float(np.linalg.norm(wa[b][:3, 3] - w0[b][:3, 3])) for b in changed)
    d1 = max(float(np.linalg.norm(wz[b][:3, 3] - w0[b][:3, 3])) for b in changed)
    print(f'寫好 {a.out}：{n} 格（{a.length} 秒）')
    print(f'檢查：右手和目標最多差 {worst["右手"] * 1000:.2f} 公釐、左手 {worst["左手"] * 1000:.2f} 公釐（搆不到時會大）、'
          f'槍 {worst["槍"] * 1000:.3f} 公釐；左臂伸直 {min(reach):.2f}～{max(reach):.2f}；第 0 格和底層差 {d0 * 1000:.3f}、最後一格 {d1 * 1000:.3f} 公釐')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
