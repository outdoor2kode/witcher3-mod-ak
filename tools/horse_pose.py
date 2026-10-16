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
