"""物品欄預覽的 AK 展示動畫（使用者 10-18 回報的第 24 項：「物品欄打開時，預覽人物握槍的方式有誤」：AK 掛在左手、槍口朝下）。

用法（Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/inv_pose.py
        [--only unsheathe idle check1 to_noequipment sheathe] [--grip 右 前 上] [--barrel 右 前 上] [--roll 度]

- 原版：物品欄裡裝上十字弩類時，預覽人物的動畫圖（pc_inventory.w2beh）播 5 段十字弩展示動畫，左手單手拿著
  （docs/handoff.md「#24 查到的」）；AK 的模型擺法是雙手持槍的 → 單手拿時槍口朝下、槍托穿過前臂
- 輸入：REDkit 匯出的原版 assets\\anims\\inventory_*.re（5 段）
- 輸出：assets\\anims\\gfg\\gfg_akinv_*.re（名稱：inventory_ 換成同長度的 gfg_akinv_；格數、長度、其他骨頭照原版）
- 每一格只換兩手臂（上臂、前臂、手）和 l_weapon；身體（腿、骨盆、脊椎、頭）照原版
  - 展示姿勢：低持（槍托在右肩前、槍口往前下約 30°、略往左），位置跟著 torso3（呼吸、身體的小動作照原版）
    - 擺法用 idle 第 0 格的胸口軸算（右 = 兩肩關節連線的水平方向、上 = Z、前 = 上 × 右）：
      --grip 握把在右肩關節（r_bicep）的哪裡、--barrel 槍管方向、--roll 槍繞槍管轉（正 = 槍的上方往前）
    - --palm-back：左手沿槍管往後移幾公尺（底層握在握把往前 0.375，下護木 0.30～0.45：docs/m3.md「第 1 步」）
    - 預設值（10-18 23:xx 在 idle 第 0 格試幾千組，暫存 s30\\inv_search*.py）：兩手搆得到（差 < 1 公分）、
      槍托在胸前 → 兩手腕比底層多彎 右 21°、左 9°（check1 翻看時 28°、30°）；左臂伸直 0.95
      - 斜放胸前（槍口往左上）的手腕一定多彎 130° 左右：握法是瞄準時的握法，槍管要大致朝前才自然
      - 預覽人物沒有瞄準時側身：槍托頂在肩關節前、左手握 0.375 的話左手差 10 公分搆不到
  - 兩手的握法照正面持槍底層（square 第 0 格：右手握把、左手護木；同 tools/reload_pose.py）
  - 原版單手拿十字弩的段落（拿出、收回時甩的那段）：AK 跟著原版的左手（左手握護木 = 槍 · 握法⁻¹），右手照原版
  - 兩者之間用權重混（smoothstep）：槍的位置線性、方向 slerp；右手的目標同；左手一律握在槍的護木
  - check1：展示姿勢再繞握把轉（CHECK_KEYS：翻過來看側面、再翻到另一邊）
  - to_noequipment：原版送這個事件前已經卸下道具（inventoryMenu.ws:2645-2657）→ 沒有槍，兩手從握槍的位置回到原版
  - 兩節手臂 IK：square_pose.two_bone_ik；l_weapon = FK 讀回的左手⁻¹ · 槍
- 物品事件（AnimBrowser 加）：照原版的時間（unsheathe 1.58054 秒 CExtAnimItemEvent：crossbow 換到左手；sheathe 約 2.0 秒）
- 檢查（印出）：手和目標的差、左臂伸直的程度、手腕相對前臂比底層多彎幾度、槍管方向、槍托和槍口離身體多遠
"""
import argparse
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import aim_delta as A  # noqa: E402  （同時把 h5py 的路徑加進來）
import move_pose as M  # noqa: E402
import reload_pose as R  # noqa: E402
import square_pose as S  # noqa: E402
import h5py  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
ANIMS = ROOT / 'assets' / 'anims'
OUT = ANIMS / 'gfg'
FPS = 30
LEFT_ARM = ('l_bicep', 'l_forearm', 'l_hand')
RIGHT_ARM = ('r_bicep', 'r_forearm', 'r_hand')
CHANGED = list(LEFT_ARM) + list(RIGHT_ARM) + ['l_weapon']
MUZZLE = np.array([0.2368, 0.0409, 0.1710])  # l_weapon 座標（gfg_ak47.ws「槍口火光」）

# 每段：原版名稱、槍在手上的時間（起, 迄；None = 沒有槍）、槍的權重、右手的權重、左手的權重（沒有槍時才用）
# 權重的關鍵格 (秒, 值)：1 = 展示姿勢（兩手握槍）、0 = 原版（左手單手、右手垂下）；關鍵格之間 smoothstep
CLIPS = {
    'unsheathe': ('inventory_unsheathe_crossbow', (1.58054, None), [(1.9, 0.0), (2.6, 1.0)], [(2.0, 0.0), (2.6, 1.0)], None),
    'idle': ('inventory_crossbow_idle', (0.0, None), [(0.0, 1.0)], [(0.0, 1.0)], None),
    'check1': ('inventory_crossbow_check1', (0.0, None), [(0.0, 1.0)], [(0.0, 1.0)], None),
    'to_noequipment': ('inventory_crossbow_to_noequipment', None, [(0.0, 1.0)], [(0.0, 1.0), (0.9, 0.0)],
                       [(0.0, 1.0), (1.0, 0.0)]),
    'sheathe': ('inventory_sheathe_crossbow', (0.0, 2.0), [(0.0, 1.0), (0.7, 0.0)], [(0.0, 1.0), (0.6, 0.0)], None),
}
# check1 的翻看：(秒, 繞槍管轉（度，正 = 槍的上方往前）, 槍口往上（度）, 往上（公尺）)，以握把為軸、胸口的軸
CHECK_KEYS = [(0.0, 0.0, 0.0, 0.0), (0.9, -30.0, 15.0, 0.03), (2.3, -30.0, 15.0, 0.03),
              (3.1, 25.0, 10.0, 0.02), (4.3, 25.0, 10.0, 0.02), (5.2, 0.0, 0.0, 0.0)]


def wkey(keys: list, t: float) -> float:
    """權重關鍵格：之間 smoothstep，頭尾之外照頭尾的值。"""
    if t <= keys[0][0]:
        return keys[0][1]
    if t >= keys[-1][0]:
        return keys[-1][1]
    i = max(j for j in range(len(keys) - 1) if keys[j][0] <= t)
    (t0, v0), (t1, v1) = keys[i], keys[i + 1]
    u = (t - t0) / (t1 - t0)
    return v0 + (v1 - v0) * u * u * (3 - 2 * u)


def blend(m0: np.ndarray, m1: np.ndarray, w: float) -> np.ndarray:
    """兩個 4×4 剛體：位置線性、方向 slerp。"""
    if w <= 0.0:
        return m0.copy()
    if w >= 1.0:
        return m1.copy()
    return S.rigid(R.slerp_rot(m0[:3, :3], m1[:3, :3], w), (1 - w) * m0[:3, 3] + w * m1[:3, 3])


def chest_axes(w: dict) -> np.ndarray:
    """胸口的 右、前、上（行向量）：右 = 兩肩關節連線的水平方向。"""
    r = w['r_bicep'][:3, 3] - w['l_bicep'][:3, 3]
    r = S.unit(np.array([r[0], r[1], 0.0]))
    up = np.array([0.0, 0.0, 1.0])
    return np.array([r, np.cross(up, r), up])


def display_gun(w: dict, a) -> np.ndarray:
    """展示姿勢的槍（l_weapon 的世界矩陣）：握把、槍管方向照參數（胸口的軸）。"""
    ax = chest_axes(w)
    grip = w['r_bicep'][:3, 3] + ax.T @ np.array(a.grip)
    b = S.unit(ax.T @ np.array(a.barrel))
    u = S.unit(ax[2] - (ax[2] @ b) * b)
    u = A.axis_angle(b, -a.roll) @ u  # 正 = 槍的上方往前（繞槍管，右手定則的反向）
    rot = np.column_stack((b, u, np.cross(b, u))) @ np.column_stack((R.GF, R.GU, R.GR)).T
    return S.rigid(rot, grip - rot @ A.GRIP)


def inspect(g: np.ndarray, ax: np.ndarray, t: float) -> np.ndarray:
    """check1：以握把為軸翻看（CHECK_KEYS）。"""
    v = R.hermite([(k[0], np.array(k[1:])) for k in CHECK_KEYS], t)
    roll, pitch, lift = float(v[0]), float(v[1]), float(v[2])
    grip = g[:3, :3] @ A.GRIP + g[:3, 3]
    b = g[:3, :3] @ R.GF
    rot = A.axis_angle(ax[0], pitch) @ A.axis_angle(b, -roll)
    m = np.eye(4)
    m[:3, :3] = rot @ g[:3, :3]
    m[:3, 3] = grip + ax[2] * lift + rot @ (g[:3, 3] - grip)
    return m


def wrist_bend(w: dict, side: tuple, base_rel: np.ndarray) -> float:
    """手相對前臂的方向，和底層（正面持槍）差幾度。"""
    rel = w[side[1]][:3, :3].T @ w[side[2]][:3, :3]
    return M.angle(base_rel.T @ rel)


def arm_ik(w0: dict, bones: tuple, target: np.ndarray, base_rel: np.ndarray, prev: float | None) -> tuple[dict, float]:
    """兩節手臂 IK，再整隻手臂繞「肩關節 → 手腕」轉（手肘的朝向）：選手腕相對前臂最接近底層的角度。
    two_bone_ik 讓手肘盡量留在原本的方向；原版手臂垂下、目標在胸前時，前臂的方向跟不上手 → 手腕扭很多。
    代價 = 手腕多彎的度數 + 0.1 × 轉的角度（偏好原本的手肘方向）+ 手肘高過肩膀的懲罰 + 0.5 × 和上一格差的角度（不跳動）。"""
    solved = S.two_bone_ik(w0, bones, target)
    s = w0[bones[0]][:3, 3]
    u = S.unit(target[:3, 3] - s)
    elbow0 = solved[bones[1]][:3, 3] - s
    best = None
    for deg in range(-180, 180, 2):
        rr = A.axis_angle(u, deg)
        bend = M.angle(base_rel.T @ ((rr @ solved[bones[1]][:3, :3]).T @ target[:3, :3]))
        cost = bend + 0.1 * abs(deg) + 300 * max(0.0, float((rr @ elbow0)[2]))
        if prev is not None:
            cost += 0.5 * abs(S.wrap(deg - prev))
        if best is None or cost < best[0]:
            best = (cost, deg)
    rr = A.axis_angle(u, best[1])
    return {
        bones[0]: S.rigid(rr @ solved[bones[0]][:3, :3], s),
        bones[1]: S.rigid(rr @ solved[bones[1]][:3, :3], s + rr @ elbow0),
        bones[2]: target.copy(),
    }, best[1]


def make(name: str, a, grip_r: np.ndarray, grip_l: np.ndarray, disp_rel: np.ndarray, base_rel: dict,
         sq_loc: dict) -> None:
    src_name, hold, gun_w, right_w, left_w = CLIPS[name]
    src = ANIMS / f'{src_name}.re'
    dst = OUT / f'{src_name.replace("inventory_", "gfg_akinv_")}.re'
    assert len(dst.stem) == len(src_name)
    hier = A.read_skeleton(src)
    par = dict(hier)
    frames = M.read_frames(src)
    n = len(frames['pelvis'])
    assert all(len(v) == n for v in frames.values()), '每根骨頭都要有完整的軌'
    results, worst = [], {'右手': 0.0, '左手': 0.0, '右腕': 0.0, '左腕': 0.0}
    reach, near = [], []
    prev = {'l': None, 'r': None}
    for i in range(n):
        t = i / FPS
        loc0 = {k: M.local(v[i]) for k, v in frames.items()}
        w0 = S.fk4(hier, loc0)
        ax = chest_axes(w0)
        g_disp = w0['torso3'] @ disp_rel
        if name == 'check1':
            g_disp = inspect(g_disp, ax, t)
        holding = hold is not None and t >= hold[0] - 1e-6 and (hold[1] is None or t < hold[1])
        wr = wkey(right_w, t)
        if holding:
            g_hand = w0['l_hand'] @ np.linalg.inv(grip_l)  # 原版的左手握著護木
            wl = wkey(gun_w, t)
            g = blend(g_hand, g_disp, wl)
            lt = g @ grip_l
        else:
            g = g_disp
            wl = wkey(left_w, t) if left_w else 0.0
            lt = blend(w0['l_hand'], g_disp @ grip_l, wl)
        rt = blend(w0['r_hand'], g @ grip_r, wr)
        loc = dict(loc0)
        moved = False
        for side, bones, target, ws in (('l', LEFT_ARM, lt, wl), ('r', RIGHT_ARM, rt, wr)):
            if ws <= 0.0 and np.allclose(target, w0[bones[2]], atol=1e-7):
                prev[side] = None
                continue
            moved = True
            # IK 的起點：原版的手臂和正面持槍底層的手臂照權重混（前臂的扭轉才跟得上握槍的手）
            loc_s = dict(loc0)
            for b in bones:
                loc_s[b] = (R.slerp_rot(loc0[b][0], sq_loc[b][0], ws), loc0[b][1])
            w_s = S.fk4(hier, loc_s)
            solved, prev[side] = arm_ik(w_s, bones, target, base_rel[side], prev[side])
            parent = w_s[par[bones[0]]]
            for b in bones:
                m = np.linalg.inv(parent) @ solved[b]
                loc[b] = (m[:3, :3], loc0[b][1])
                parent = solved[b]
        if holding:
            m = np.linalg.inv(S.fk4(hier, loc)['l_hand']) @ g
            loc['l_weapon'] = (m[:3, :3], m[:3, 3])
        results.append(loc)
        wn = S.fk4(hier, loc)
        if moved:
            worst['右手'] = max(worst['右手'], float(np.linalg.norm(wn['r_hand'][:3, 3] - rt[:3, 3])))
            worst['左手'] = max(worst['左手'], float(np.linalg.norm(wn['l_hand'][:3, 3] - lt[:3, 3])))
        if wr >= 0.5:  # 只算握槍的格（原版的段落是原版的手腕）
            worst['右腕'] = max(worst['右腕'], wrist_bend(wn, RIGHT_ARM, base_rel['r']))
        if wl >= 0.5:
            worst['左腕'] = max(worst['左腕'], wrist_bend(wn, LEFT_ARM, base_rel['l']))
        s_, e_, w_ = (wn[b][:3, 3] for b in LEFT_ARM)
        reach.append(np.linalg.norm(w_ - s_) / (np.linalg.norm(e_ - s_) + np.linalg.norm(w_ - e_)))
        if holding:
            gw = wn['l_weapon']
            pts = {'槍托': gw[:3, :3] @ S.BUTT + gw[:3, 3], '槍口': gw[:3, :3] @ MUZZLE + gw[:3, 3]}
            # 離身體：到 pelvis–torso3–head 這條中線的水平距離（粗略；身體半徑約 0.15）
            c0, c1 = wn['pelvis'][:3, 3], wn['head'][:3, 3]
            for k, p in pts.items():
                u = np.clip((p - c0) @ (c1 - c0) / ((c1 - c0) @ (c1 - c0)), 0, 1)
                near.append((float(np.linalg.norm(p - (c0 + u * (c1 - c0)))), k, t))
        if i % 15 == 0 or i == n - 1:
            bar = wn['l_weapon'][:3, :3] @ R.GF if holding else np.zeros(3)
            bl = ax @ bar  # 胸口的軸：右、前、上
            print(f'  {t:4.2f}s {"握" if holding else "  "} 槍{wkey(gun_w, t):.2f} 右{wr:.2f}：'
                  f'槍管（右 {bl[0]:+.2f} 前 {bl[1]:+.2f} 上 {bl[2]:+.2f}）左臂伸直 {reach[-1]:.2f}')

    shutil.copyfile(src, dst)
    with h5py.File(dst, 'r+') as f:
        clip = f[A.CLIP]
        for bone in CHANGED:
            ds = clip[bone]['xformframes']
            data = ds[()]
            flat = data.reshape(-1)
            for i in range(n):
                r, tr = results[i][bone]
                for c, v in zip(R.ROT, A.mat_to_quat(r.T)):  # 區域旋轉 → 檔案的四元數（轉置）
                    flat[c][i] = v
                for c, v in zip(R.POS, np.asarray(tr) * 100):  # 公尺 → 公分
                    flat[c][i] = v
            ds[...] = data
    # 讀回檢查：沒換的骨頭和原版一樣
    out = M.read_frames(dst)
    same = all(np.array_equal(out[k], frames[k]) for k in frames if k not in CHANGED)
    near.sort()
    print(f'寫好 {dst.name}：{n} 格（{(n - 1) / FPS:.3f} 秒）；其他骨頭和原版一樣：{same}')
    print(f'  檢查：右手和目標最多差 {worst["右手"] * 1000:.1f} 公釐、左手 {worst["左手"] * 1000:.1f}；'
          f'手腕比底層多彎：右 {worst["右腕"]:.0f}°、左 {worst["左腕"]:.0f}°；左臂伸直 {min(reach):.2f}～{max(reach):.2f}'
          + (f'；離身體中線最近：{near[0][1]} {near[0][0]:.2f} 公尺（{near[0][2]:.2f} 秒）' if near else ''))


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8')
    p = argparse.ArgumentParser(description='物品欄預覽的 AK 展示動畫（原版 5 段的身體＋雙手握槍）')
    p.add_argument('--only', nargs='+', choices=list(CLIPS), default=list(CLIPS))
    p.add_argument('--grip', type=float, nargs=3, default=(-0.18, 0.32, -0.18), metavar=('右', '前', '上'),
                   help='握把在右肩關節的哪裡（公尺，胸口的軸）')
    p.add_argument('--barrel', type=float, nargs=3, default=(-0.45, 0.8, -0.45), metavar=('右', '前', '上'),
                   help='槍管方向（胸口的軸）')
    p.add_argument('--roll', type=float, default=-15.0, help='槍繞槍管轉幾度（正 = 槍的上方往前）')
    p.add_argument('--palm-back', type=float, default=0.07, help='左手沿槍管往後移幾公尺')
    a = p.parse_args()

    # 握法：正面持槍底層第 0 格的兩手相對槍（左手再沿槍管往後 --palm-back）
    sq = R.POUCH_REF
    sq_all = {k: M.local(v[0]) for k, v in M.read_frames(sq).items()}
    sq_loc = {b: sq_all[b] for b in LEFT_ARM + RIGHT_ARM}
    w_sq = S.fk4(A.read_skeleton(sq), sq_all)
    g0 = w_sq['l_weapon']
    grip_r = np.linalg.inv(g0) @ w_sq['r_hand']
    grip_l = np.linalg.inv(g0) @ w_sq['l_hand']
    grip_l[:3, 3] -= R.GF * a.palm_back
    base_rel = {'r': w_sq['r_forearm'][:3, :3].T @ w_sq['r_hand'][:3, :3],
                'l': w_sq['l_forearm'][:3, :3].T @ w_sq['l_hand'][:3, :3]}
    # 展示姿勢：idle 第 0 格算，換成相對 torso3
    idle = ANIMS / f'{CLIPS["idle"][0]}.re'
    w_idle = S.fk4(A.read_skeleton(idle), {k: M.local(v[0]) for k, v in M.read_frames(idle).items()})
    g_disp = display_gun(w_idle, a)
    disp_rel = np.linalg.inv(w_idle['torso3']) @ g_disp
    gp = g_disp[:3, :3] @ A.GRIP + g_disp[:3, 3]
    print(f'展示姿勢（idle 第 0 格，模型座標）：握把 ({gp[0]:+.2f},{gp[1]:+.2f},{gp[2]:+.2f})、'
          f'槍管 {np.round(g_disp[:3, :3] @ R.GF, 2)}、槍的上方 {np.round(g_disp[:3, :3] @ R.GU, 2)}')
    OUT.mkdir(parents=True, exist_ok=True)
    for name in a.only:
        print(f'== {name}')
        make(name, a, grip_r, grip_l, disp_rel, base_rel, sq_loc)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
