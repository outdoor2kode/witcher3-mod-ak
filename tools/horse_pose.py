"""騎馬瞄準的雙手持槍差值（第 3 項：騎馬的姿勢；docs/handoff.md）

騎馬瞄準（pc_rider.w2beh #4267）：上半身換成 aim_cycle（底層，已用 move_pose.py --full 做好雙手版），
上面再用 AT_Local 疊加：水平 aimpose_horizontal_rp → 垂直 aimpose_vertical_rp_{center,left,right}
→ 別射我 dont_shoot_me_bro{,_left,_right} → 射擊 shoot_additive_{center,left,right}。
原版的差值是單手十字弩的（主要動左手），雙手拿 AK 時槍跟不上準心。這裡照地面的做法（aim_delta.py）：
- 水平、垂直：只轉脊椎（左右 torso、torso2；上下 torso3），手臂和 AK 掛在胸口底下整組跟著轉；疊加方式 local
- 射擊、別射我：全部單位（不動）

量原版（2026-10-16 16:5x，十字弩的軸取站著瞄準 ex_man_geralt_gabriel_aim_idle 第 0 格「朝前」）：
- local 方式套在 aim_cycle 第 0 格：水平第 60 格 0°、45 格 +90°（往左）、75 格 −90°、30／90 格 ±180°，第 0～30 格倒放；
  垂直第 75 格 +42°、90 格 +85°、45 格 −49°、30 格 −79° → 和地面站著瞄準的時間、角度規則一樣（aim_delta.aim_angle）
- ref 方式的結果不合理（左右轉時槍往下 30° 以上）→ 騎馬的差值是 local

用法（Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/horse_pose.py
        assets/anims assets/anims/gfg assets/anims/gfg

- 第 1 個資料夾：REDkit 匯出的原版 48 段 man_geralt_gabriel_horse_*.re（樣板：結構、骨頭、格數照抄）
- 第 2 個資料夾：雙手版 aim_cycle（man_geralt_gabriel_horse_horse_{breathing_slow,walk,trot,gallop}_aim_cycle.re；第 0 格當底層）
- 輸出：同名的 40 段 .re（16 段水平／垂直 + 24 段射擊／別射我）；匯入時用 Import additive animations I (Local)
"""
import argparse
import math
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import aim_delta as A  # noqa: E402
import h5py  # noqa: E402  （aim_delta 已經把 _vendor\pylib 加進路徑）

GAITS = {'idle': 'breathing_slow', 'walk': 'walk', 'trot': 'trot', 'gallop': 'gallop'}  # 差值的名稱 → aim_cycle 的名稱
# 左右轉分給三節脊椎的比例（使用者 2026-10-16 17:4x：騎馬往側面瞄準時腰扭得不自然）：
# 原本 torso、torso2 各一半 → 側面 90° 時腰（torso）一下子轉 45°。人的腰椎幾乎不轉、胸椎轉得多 → 下面少、上面多
# 骨盆不能分：騎馬瞄準的覆蓋節點（pc_rider.w2beh #4423）只取 torso 以上和手臂，差值裡的骨盆不會生效
# torso3 同時有上下的差值也沒關係：local 疊加 = 區域·D左右·D上下 → torso3 的方向 = Rz(左右)·Rx(上下)·底層（先左右、再沿轉過的右邊上下）
H_WEIGHTS = {'torso': 0.15, 'torso2': 0.40, 'torso3': 0.45}
DELTAS = {
    'horizontal': 'aimpose_horizontal_rp',
    'center': 'aimpose_vertical_rp_center',
    'left': 'aimpose_vertical_rp_left',
    'right': 'aimpose_vertical_rp_right',
}
IDENTITY = ('dont_shoot_me_bro', 'dont_shoot_me_bro_left', 'dont_shoot_me_bro_right',
            'shoot_additive_center', 'shoot_additive_left', 'shoot_additive_right')


def write_identity(template: Path, out: Path) -> int:
    """樣板照抄，每根骨頭每格都換成單位（位置 0、旋轉單位、縮放 1）；回傳格數。"""
    shutil.copyfile(template, out)
    count = 0
    with h5py.File(out, 'r+') as f:
        clip = f[A.CLIP]
        for b in clip.keys():
            if not isinstance(clip[b], h5py.Group):
                continue
            ds = clip[b]['xformframes']
            arr = ds[()]
            flat = arr.reshape(-1)
            count = len(flat)
            for c in ('pos.x', 'pos.y', 'pos.z', 'rot.x', 'rot.y', 'rot.z'):
                flat[c] = 0
            flat['rot.w'] = 1
            for c in ('scale.x', 'scale.y', 'scale.z'):
                if c in flat.dtype.names:
                    flat[c] = 1
            ds[...] = flat.reshape(arr.shape)
    return count


def h_deltas(hier, base_world, base_local, deg: float) -> dict:
    """左右 deg 度：每根骨頭在模型座標裡繞自己的原點轉 deg × 比例（同一根 Z 軸，疊起來 = deg）；回傳 local 方式的差值（位置 0）。"""
    parent = dict(hier)
    q_total = A.mat_to_quat(A.total_rotation('horizontal', deg))
    out = {}
    for b, w in H_WEIGHTS.items():
        pr = base_world[parent[b]][0]
        r = pr.T @ A.quat_to_mat(*A.slerp_identity(q_total, w)) @ pr
        rl = base_local[b][0]
        out[b] = (rl.T @ r @ rl, np.zeros(3))
    return out


def write_horizontal(template: Path, out: Path, hier, base_world, base_local) -> list[str]:
    """水平差值：樣板照抄、全部骨頭先設單位，再寫 H_WEIGHTS 的三節脊椎；回傳檢查結果（左右＋上下一起套到底層第 0 格）。"""
    write_identity(template, out)
    with h5py.File(out, 'r+') as f:
        clip = f[A.CLIP]
        data = {b: clip[b]['xformframes'][()] for b in H_WEIGHTS}
        count = len(data['torso'].reshape(-1))
        for frame in range(count):
            for b, (r, _t) in h_deltas(hier, base_world, base_local, A.aim_angle('horizontal', frame)).items():
                rec = data[b].reshape(-1)
                q = A.mat_to_quat(r.T)  # 寫進檔案要轉置（讀的時候會再轉置回來）
                rec[frame]['rot.x'], rec[frame]['rot.y'], rec[frame]['rot.z'], rec[frame]['rot.w'] = (float(v) for v in q)
        for b in H_WEIGHTS:
            clip[b]['xformframes'][...] = data[b]
    # 檢查：讀回來的左右差值，加上 aim_delta 的上下差值（torso3 繞底層 torso2 的 X 轉），依序套到底層第 0 格
    with h5py.File(out, 'r') as f:
        clip = f[A.CLIP]
        frames = {b: clip[b]['xformframes'][()].reshape(-1) for b in H_WEIGHTS}
    parent = dict(hier)
    lines = []
    for frame in (90, 75, 60, 45, 30):
        hd = {b: A.file_rot(frames[b][frame]) for b in H_WEIGHTS}
        deg = A.aim_angle('horizontal', frame)
        for pitch in (0.0, 30.0, -20.0):
            pr = base_world[parent['torso3']][0]
            rl3 = base_local['torso3'][0]
            dv = rl3.T @ (pr.T @ A.total_rotation('vertical', pitch) @ pr) @ rl3
            local = dict(base_local)
            for b, d in hd.items():
                lr, lt = base_local[b]
                local[b] = (lr @ d @ (dv if b == 'torso3' else np.eye(3)), lt)
            world = A.fk(hier, local)
            want = A.total_rotation('horizontal', deg) @ A.total_rotation('vertical', pitch) @ (base_world['l_weapon'][0] @ A.BARREL)
            got = world['l_weapon'][0] @ A.BARREL
            waist = A.angle_deg(world['torso'][0] @ [0, 1, 0], base_world['torso'][0] @ [0, 1, 0])
            lines.append(f'  第 {frame:2d} 格 左右 {deg:6.1f}° 上下 {pitch:5.1f}°：槍管差 {A.angle_deg(got, want):.3f}°；'
                         f'掌心離握把 {A.palm_grip_cm(world):.2f} 公分；腰（torso）轉 {waist:.1f}°')
    return lines


def yaw_pitch(d) -> tuple[float, float]:
    """模型座標的方向 → (左右 往左是正, 上下 往上是正) 度。"""
    return math.degrees(math.atan2(-d[0], d[1])), math.degrees(math.asin(max(-1.0, min(1.0, d[2] / np.linalg.norm(d)))))


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8')  # Blender 內建的 Python 不讀 PYTHONUTF8
    ap = argparse.ArgumentParser()
    ap.add_argument('orig_dir', type=Path)
    ap.add_argument('base_dir', type=Path)
    ap.add_argument('out_dir', type=Path)
    a = ap.parse_args()
    a.out_dir.mkdir(parents=True, exist_ok=True)
    for gait, cycle in GAITS.items():
        base = a.base_dir / f'man_geralt_gabriel_horse_horse_{cycle}_aim_cycle.re'
        hier = A.read_skeleton(base)
        base_local = A.read_frame0(base)
        base_world = A.fk(hier, base_local)
        y, p = yaw_pitch(base_world['l_weapon'][0] @ A.BARREL)
        print(f'== {gait}（底層 {base.name} 第 0 格）：槍管 左右 {y:.1f}°、上下 {p:.1f}°；右手掌心離握把 {A.palm_grip_cm(base_world):.2f} 公分')
        for kind, suffix in DELTAS.items():
            name = f'man_geralt_gabriel_horse_{gait}_{suffix}.re'
            if kind == 'horizontal':
                lines = write_horizontal(a.orig_dir / name, a.out_dir / name, hier, base_world, base_local)
                print(f'{name}（左右：' + '、'.join(f'{b} {w:.0%}' for b, w in H_WEIGHTS.items()) + '）')
                print('\n'.join(lines))
                continue
            lines = A.write_delta(a.orig_dir / name, a.out_dir / name, kind, hier, base_world, base_local, 'local')
            print(f'{name}')
            print('\n'.join(lines))
        for suffix in IDENTITY:
            name = f'man_geralt_gabriel_horse_{gait}_{suffix}.re'
            n = write_identity(a.orig_dir / name, a.out_dir / name)
            print(f'{name}：單位 {n} 格')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
