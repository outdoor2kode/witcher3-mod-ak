"""移動時的正面持槍姿勢（使用者 2026-10-16 回報的第 13、14 項：走跑時腰扭太多）。

第 1 步的雙手持槍是 NPC 十字弩兵的側身瞄準：肩膀朝右約 60°（骨盆 56°）。站著時骨盆一起側身，沒問題；
走跑時腿和骨盆照一般走跑朝前，上半身維持側身 → 腰扭約 61°（2026-10-16 22:1x 遊戲裡量：`[GFG] twist`）。
這裡把第 1 步改成「肩膀轉正 δ 度」的版本，給走跑的上半身動畫用（tools/move_pose.py 的第 1 個參數）。

用法（要有 h5py、numpy：用 Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/square_pose.py
        第1步.re 輸出.re [--deg 35] [--split 0.2 0.4 0.4] [--anchor chest|world] [--gun 0 0 0]
        [--protract 0] [--palm-back 0]

- 第 1 步：assets\\anims\\gfg\\man_geralt_gabriel_aim_idle_rp.re
- 輸出：結構、格數照第 1 步，只換脊椎、脖子、左鎖骨、兩手臂（上臂、前臂、手）、l_weapon 的區域變換

做法（每一格；模型座標 X 右、Y 前、Z 上，不含 Root，同 tools/aim_delta.py 的 fk）：
1. 脊椎：torso、torso2、torso3 在模型座標繞 Z 往左轉 δ×--split 的比例（累加；各自的原點）→ 胸口往左轉 δ（肩膀轉正）
2. 頭：neck 轉回去，頭在模型座標的方向不變（照樣看前方）
3. 左鎖骨（--protract）：l_shoulder 在模型座標繞 Z 往前轉幾度（肩胛前推、左肩關節往前）
   - 原因：第 1 步的左手已經伸到 78%（側身時左肩在前）；肩膀轉正後左肩往後退，手搆不到槍（δ 25° 就差 6 公分）
4. 槍（= l_weapon）：方向不變（槍管照樣朝前），位置跟著右肩關節（r_bicep 的原點）→ 槍托留在右肩前面；--gun 再加位移（公尺）
   - --anchor chest（預設）：右肩關節到槍托後端的位移跟著胸口轉 δ（槍托貼在轉正後的胸口前面）；world：位移的方向不變
   - 槍托後端（l_weapon 座標）＝ 握把 GRIP 往後 0.278 公尺（槍管方向）、往上 0.045（AK 模型：槍托後端 s −0.278、高度 −0.008～+0.098；
     docs/m3.md「第 1 步」）；槍的上方 (0.0272, −0.9454, 0.3247)（同一節）
5. 兩手：手和槍的相對位置、方向照第 1 步（右手握握把；左手握護木）
   - --palm-back：左手沿槍管往後移幾公尺（第 1 步握在握把往前 0.375 公尺，下護木 0.30～0.45：docs/m3.md「第 1 步」）
     AK 掛在 l_weapon（左手的子骨頭）→ 改 l_weapon 的區域變換，讓槍留在 4. 的位置
     （走跑的覆蓋動畫有 l_weapon：pc_gameplay.w2beh 的 70 根骨頭表，docs/m3.md「直線走路、跑步的右手」）
   → 兩節手臂的 IK（同 tools/two_hand_pose.py 的 two_bone_ik：手肘當鉸鏈，整隻手臂繞肩膀轉、手肘盡量留在原本的方向）
   - 扭轉骨頭（*Roll*、*bicep2）、手指是這三根的子骨頭，區域變換不變
檢查（讀回輸出檔做 FK）：每一格 l_weapon、右手和目標的差、頭的方向、槍管方向、肩膀和骨盆的朝向、手臂伸直的程度
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
import h5py  # noqa: E402

SPINE = ('torso', 'torso2', 'torso3')
ARMS = {'左手': ('l_bicep', 'l_forearm', 'l_hand'), '右手': ('r_bicep', 'r_forearm', 'r_hand')}
ROT = ('rot.x', 'rot.y', 'rot.z', 'rot.w')
Z = np.array([0.0, 0.0, 1.0])
GUN_UP = np.array([0.0272, -0.9454, 0.3247])  # l_weapon 座標（docs/m3.md「第 1 步」）
BUTT = A.GRIP - 0.278 * A.BARREL / np.linalg.norm(A.BARREL) + 0.045 * GUN_UP  # 槍托後端，l_weapon 座標


def unit(v: np.ndarray) -> np.ndarray:
    return v / np.linalg.norm(v)


def rigid(r: np.ndarray, t) -> np.ndarray:
    m = np.eye(4)
    m[:3, :3] = r
    m[:3, 3] = t
    return m


def rotation_between(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """把方向 a 轉到 b 的最小旋轉（3×3）。"""
    a, b = unit(a), unit(b)
    axis = np.cross(a, b)
    s = np.linalg.norm(axis)
    if s < 1e-12:
        return np.eye(3)
    return A.axis_angle(axis, math.degrees(math.atan2(s, float(a @ b))))


def two_bone_ik(world: dict, bones: tuple[str, str, str], target: np.ndarray) -> dict[str, np.ndarray]:
    """兩節手臂的 IK（照抄 tools/two_hand_pose.py，axis_angle 改成度）：回傳三根骨頭的新世界矩陣（4×4）。"""
    upper, lower, hand = bones
    s, e, w = (world[b][:3, 3] for b in bones)
    goal = target[:3, 3]
    a, b = np.linalg.norm(e - s), np.linalg.norm(w - e)
    d = min(max(np.linalg.norm(goal - s), abs(a - b) + 1e-6), a + b - 1e-6)

    def inner(dist):  # 手肘的內角
        return math.acos(max(-1.0, min(1.0, (a * a + b * b - dist * dist) / (2 * a * b))))

    bend = A.axis_angle(np.cross(e - s, w - e), math.degrees(inner(np.linalg.norm(w - s)) - inner(d)))
    w1 = e + bend @ (w - e)
    swing = rotation_between(w1 - s, goal - s)
    u = unit(goal - s)
    e1 = swing @ (e - s)
    p_new, p_old = e1 - (e1 @ u) * u, (e - s) - ((e - s) @ u) * u
    turn = math.atan2(float(u @ np.cross(p_new, p_old)), float(p_new @ p_old))
    r = A.axis_angle(u, math.degrees(turn)) @ swing
    return {
        upper: rigid(r @ world[upper][:3, :3], s),
        lower: rigid(r @ bend @ world[lower][:3, :3], s + r @ (e - s)),
        hand: target.copy(),
    }


def fk4(hier, loc: dict) -> dict[str, np.ndarray]:
    return {k: rigid(r, p) for k, (r, p) in A.fk(hier, loc).items()}


def yaw(l: np.ndarray, r: np.ndarray) -> float:
    """右 → 左兩點連線的朝向（度，0 = 正前、正 = 往右）。"""
    v = l - r
    return math.degrees(math.atan2(v[1], -v[0]))


def wrap(a: float) -> float:
    return (a + 180) % 360 - 180


def set_world_rot(new: dict, loc: dict, bone: str, parent_world: np.ndarray, world_rot: np.ndarray) -> None:
    new[bone] = (parent_world[:3, :3].T @ world_rot, loc[bone][1])


def square_frame(hier, par: dict, loc: dict, a) -> tuple[dict, dict]:
    """一格：回傳（新的區域變換 {骨頭: (旋轉, 位置)}、要檢查的目標）。"""
    w0 = fk4(hier, loc)
    new = dict(loc)
    # 1. 脊椎：模型座標繞 Z 往左轉（累加）
    acc = 0.0
    wr = {}
    for bone, f in zip(SPINE, a.split):
        acc += a.deg * f
        wr[bone] = A.axis_angle(Z, acc) @ w0[bone][:3, :3]
    for bone in SPINE:
        new[bone] = (wr.get(par[bone], w0[par[bone]][:3, :3]).T @ wr[bone], loc[bone][1])
    # 2. 頭：neck 的模型座標方向不變
    new['neck'] = (wr['torso3'].T @ w0['neck'][:3, :3], loc['neck'][1])
    # 3. 左鎖骨往前（左邊的點繞 Z 往前 = 從上面看順時針 = 負角）
    if a.protract:
        r = A.axis_angle(Z, -a.protract) @ A.axis_angle(Z, a.deg) @ w0['l_shoulder'][:3, :3]
        new['l_shoulder'] = (wr['torso3'].T @ r, loc['l_shoulder'][1])
    w1 = fk4(hier, new)
    # 4. 槍：方向不變、跟著右肩關節
    g0 = w0['l_weapon']
    butt0 = g0[:3, :3] @ BUTT + g0[:3, 3]
    off = butt0 - w0['r_bicep'][:3, 3]
    if a.anchor == 'chest':
        off = A.axis_angle(Z, a.deg) @ off
    g1 = g0.copy()
    g1[:3, 3] = w1['r_bicep'][:3, 3] + off + np.array(a.gun) - g0[:3, :3] @ BUTT
    move = g1 @ np.linalg.inv(g0)
    barrel = unit(g0[:3, :3] @ A.BARREL)
    lh = move @ w0['l_hand']
    lh[:3, 3] -= barrel * a.palm_back
    targets = {'左手': lh, '右手': move @ w0['r_hand']}
    # 5. 兩手 IK
    solved = {}
    for side, bones in ARMS.items():
        solved.update(two_bone_ik(w1, bones, targets[side]))
    for side, bones in ARMS.items():
        parent = w1[par[bones[0]]]
        for name in bones:
            m = np.linalg.inv(parent) @ solved[name]
            new[name] = (m[:3, :3], loc[name][1])
            parent = solved[name]
    m = np.linalg.inv(solved['l_hand']) @ g1  # l_weapon：槍留在 g1
    new['l_weapon'] = (m[:3, :3], m[:3, 3])
    return new, {'l_weapon': g1, 'r_hand': targets['右手'], 'l_hand': lh}


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8')
    p = argparse.ArgumentParser(description='移動時的正面持槍姿勢（肩膀轉正、兩手 IK）')
    p.add_argument('step1', type=Path)
    p.add_argument('out', type=Path)
    p.add_argument('--deg', type=float, default=35.0, help='肩膀往左轉正幾度（預設 35）')
    p.add_argument('--split', type=float, nargs=3, default=[0.2, 0.4, 0.4], metavar=('TORSO', 'TORSO2', 'TORSO3'),
                   help='三節脊椎分到的比例（預設 0.2 0.4 0.4）')
    p.add_argument('--anchor', choices=('chest', 'world'), default='chest', help='槍跟著右肩的位移：跟著胸口轉（預設）或不轉')
    p.add_argument('--gun', type=float, nargs=3, default=[0.0, 0.0, 0.0], metavar=('X', 'Y', 'Z'),
                   help='槍再加的位移（公尺，模型座標：X 右、Y 前、Z 上）')
    p.add_argument('--protract', type=float, default=0.0, help='左鎖骨往前轉幾度（預設 0）')
    p.add_argument('--palm-back', type=float, default=0.0, help='左手沿槍管往後移幾公尺（預設 0）')
    a = p.parse_args()
    if abs(sum(a.split) - 1) > 1e-6:
        print('--split 的和要是 1')
        return 1

    hier = A.read_skeleton(a.step1)
    par = dict(hier)
    fr = M.read_frames(a.step1)
    n = len(fr['pelvis'])
    changed = list(SPINE) + ['neck', 'l_shoulder', 'l_weapon'] + [b for bones in ARMS.values() for b in bones]

    results, checks = [], []
    for i in range(n):
        loc = {k: M.local(v[i]) for k, v in fr.items()}
        new, chk = square_frame(hier, par, loc, a)
        results.append(new)
        checks.append(chk)

    shutil.copyfile(a.step1, a.out)
    with h5py.File(a.out, 'r+') as f:
        clip = f[A.CLIP]
        for bone in changed:
            ds = clip[bone]['xformframes']
            data = ds[()]
            flat = data.reshape(-1)
            for i in range(n):
                r, t = results[i][bone]
                q = A.mat_to_quat(r.T)  # 區域旋轉 → 檔案的四元數（轉置）
                for c, v in zip(ROT, q):
                    flat[c][i] = v
                for c, v in zip(('pos.x', 'pos.y', 'pos.z'), t * 100):  # 公尺 → 公分
                    flat[c][i] = v
            ds[...] = data

    # 檢查：讀回輸出檔
    out = M.read_frames(a.out)
    worst = {'l_weapon': 0.0, 'r_hand': 0.0, 'l_hand': 0.0, 'rot': 0.0, 'head': 0.0, 'barrel': 0.0, 'pos': 0.0}
    sh0 = sh1 = hip = 0.0
    reach = {s: [] for s in ARMS}
    elbow = {s: [] for s in ARMS}
    for i in range(n):
        w0 = fk4(hier, {k: M.local(v[i]) for k, v in fr.items()})
        w1 = fk4(hier, {k: M.local(v[i]) for k, v in out.items()})
        for k in ('l_weapon', 'r_hand', 'l_hand'):
            worst[k] = max(worst[k], float(np.linalg.norm(w1[k][:3, 3] - checks[i][k][:3, 3])))
            worst['rot'] = max(worst['rot'], M.angle(w1[k][:3, :3].T @ checks[i][k][:3, :3]))
        worst['head'] = max(worst['head'], M.angle(w1['head'][:3, :3].T @ w0['head'][:3, :3]))
        worst['barrel'] = max(worst['barrel'], A.angle_deg(w0['l_weapon'][:3, :3] @ A.BARREL, w1['l_weapon'][:3, :3] @ A.BARREL))
        for bone in changed:  # 骨頭的區域位置不變（骨頭長度；l_weapon 除外）
            if bone != 'l_weapon':
                worst['pos'] = max(worst['pos'], float(np.linalg.norm(M.local(out[bone][i])[1] - M.local(fr[bone][i])[1])))
        sh0 += wrap(yaw(w0['l_shoulder'][:3, 3], w0['r_shoulder'][:3, 3])) / n
        sh1 += wrap(yaw(w1['l_shoulder'][:3, 3], w1['r_shoulder'][:3, 3])) / n
        hip += wrap(yaw(w1['l_thigh'][:3, 3], w1['r_thigh'][:3, 3])) / n
        for side, (up, lo, hd) in ARMS.items():
            s, e, w = (w1[b][:3, 3] for b in (up, lo, hd))
            reach[side].append(np.linalg.norm(w - s) / (np.linalg.norm(e - s) + np.linalg.norm(w - e)))
            s0, e0, x0 = (w0[b][:3, 3] for b in (up, lo, hd))
            elbow[side].append(A.angle_deg(s - e, w - e) - A.angle_deg(s0 - e0, x0 - e0))
        if i == 0:
            w0r, w1r = w0, w1
    print(f'寫好 {a.out}：{n} 格；肩膀往左轉 {a.deg}°（torso {a.split[0]}、torso2 {a.split[1]}、torso3 {a.split[2]}）；'
          f'槍 {a.anchor}＋{a.gun}；左鎖骨往前 {a.protract}°；左手往後 {a.palm_back} 公尺')
    print(f'朝向（平均，正 = 往右）：骨盆 {hip:.1f}°；肩膀 {sh0:.1f}° → {sh1:.1f}°')
    print(f'檢查：槍和目標差 {worst["l_weapon"] * 1000:.3f} 公釐、右手 {worst["r_hand"] * 1000:.3f}、左手 {worst["l_hand"] * 1000:.3f} 公釐、'
          f'方向 {worst["rot"]:.4f}°；頭的方向 {worst["head"]:.4f}°；槍管方向 {worst["barrel"]:.4f}°；骨頭區域位置 {worst["pos"] * 1000:.3f} 公釐')
    for side in ARMS:
        print(f'  {side}：伸直程度（肩到手腕 ÷ 兩節長）{min(reach[side]):.3f}～{max(reach[side]):.3f}；手肘內角變化 {min(elbow[side]):+.1f}～{max(elbow[side]):+.1f}°')
    for k in ('r_bicep', 'l_bicep', 'l_hand', 'r_hand', 'l_weapon', 'head'):
        d = w1r[k][:3, 3] - w0r[k][:3, 3]
        print(f'  第 0 格 {k:9s} 移動 右 {d[0] * 100:+.1f}、前 {d[1] * 100:+.1f}、上 {d[2] * 100:+.1f} 公分')
    for tag, w in (('原本', w0r), ('新的', w1r)):
        b = w['l_weapon'][:3, :3] @ BUTT + w['l_weapon'][:3, 3] - w['r_bicep'][:3, 3]
        print(f'  {tag}：槍托後端在右肩關節 右 {b[0] * 100:+.1f}、前 {b[1] * 100:+.1f}、上 {b[2] * 100:+.1f} 公分')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
