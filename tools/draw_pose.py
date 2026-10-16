"""騎馬拔槍的雙手版（使用者回報的第 16 項：「在馬上拿出槍的樣子，槍枝是反過來的」）。

用法（Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/draw_pose.py
        原版拔槍.re 終點.re 輸出.re [--blend 0.45]

- 原版拔槍：REDkit 匯出的 man_geralt_gabriel_horse_{idle,walk,trot,gallop}_aim_start_to_reload_lp.re（樣板：結構、格數、腿照抄）
- 終點：同一個步伐的雙手持槍換彈 assets\\anims\\gfg\\man_geralt_gabriel_horse_{gait}_reload_lowered.re（第 0 格 = 正面持槍、槍朝馬的前方）
- 輸出：檔名 = 原版名稱（同名蓋過原版；動畫事件要在 AnimBrowser 自己加）

原因（2026-10-16 23:3x 量原版，暫存 s18\\draw.py）：
- 騎馬拔槍（pc_rider.w2beh 狀態 'WeaponDraw'）播原版十字弩的 aim_start_to_reload_lp：左手把十字弩從身體左側甩到前面
- AK 掛在 l_weapon，擺法是雙手持槍的 → 甩的途中槍管朝右前方（相對骨盆 −44～−58°，第 12～15 格），從背後看就是「槍口朝自己」
- 雙手持槍的 AK 不適合單手甩 → 改成：上半身每根骨頭從原版第 0 格（騎乘、手在韁繩）平滑轉到正面持槍，
  --blend 秒到位（預設 0.45 = 原版 RaiseWeapon 事件的時間：已裝彈時從這裡漸變到瞄準，#7073），之後停住
  - 區域旋轉：四元數 slerp（走最短的一邊）；區域位置：線性；權重 smoothstep（開始、結束都慢）
  - 只動 torso 和它底下的骨頭（騎馬瞄準的覆蓋節點 #4423 只取 torso 以上，骨盆、腿來自騎乘動畫）
  - 原版第 0 格的 torso 區域旋轉在原版遊戲裡就是蓋在騎乘骨盆上的，終點（換彈）的 torso 也是照騎乘骨盆補正的（move_pose.py --pelvis-from）
- 檢查：每格槍管相對骨盆的方向（左右、上下），最後一格和終點的槍管差幾度
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

ROT = ('rot.x', 'rot.y', 'rot.z', 'rot.w')
POS = ('pos.x', 'pos.y', 'pos.z')


def slerp(q0: np.ndarray, q1: np.ndarray, t: float) -> np.ndarray:
    d = float(np.dot(q0, q1))
    if d < 0:
        q1, d = -q1, -d
    if d > 0.9995:
        q = q0 + (q1 - q0) * t
        return q / np.linalg.norm(q)
    th = math.acos(d)
    return (math.sin((1 - t) * th) * q0 + math.sin(t * th) * q1) / math.sin(th)


def smoothstep(x: float) -> float:
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def heading(v) -> float:
    return math.degrees(math.atan2(-v[0], v[1]))


def hip_heading(w) -> float:
    v = w['l_thigh'][1] - w['r_thigh'][1]
    return heading(np.array([v[1], -v[0], 0.0]))


def barrel_rel(w) -> tuple[float, float]:
    d = w['l_weapon'][0] @ A.BARREL
    d = d / np.linalg.norm(d)
    yaw = (heading(d) - hip_heading(w) + 180) % 360 - 180
    return yaw, math.degrees(math.asin(max(-1.0, min(1.0, d[2]))))


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8')
    p = argparse.ArgumentParser(description='騎馬拔槍的雙手版：上半身從騎乘姿勢平滑轉到正面持槍')
    p.add_argument('orig', type=Path)
    p.add_argument('end', type=Path)
    p.add_argument('out', type=Path)
    p.add_argument('--blend', type=float, default=0.45, help='幾秒轉到終點（預設 0.45 = 原版 RaiseWeapon）')
    a = p.parse_args()

    hier = A.read_skeleton(a.orig)
    if hier != A.read_skeleton(a.end):
        print('兩個檔的骨架不同')
        return 1
    upper = M.upper_body(hier)
    orig = M.read_frames(a.orig)
    end = M.read_frames(a.end)
    n = len(orig['pelvis'])
    times = [i / 30 for i in range(n)]  # .re 每秒 30 格（xformframes 的 time 欄是格數）

    shutil.copyfile(a.orig, a.out)
    with h5py.File(a.out, 'r+') as f:
        clip = f[A.CLIP]
        for b in upper:
            ds = clip[b]['xformframes']
            data = ds[()]
            flat = data.reshape(-1)
            q0 = np.array([float(orig[b][0][c]) for c in ROT])
            q1 = np.array([float(end[b][0][c]) for c in ROT])
            p0 = np.array([float(orig[b][0][c]) for c in POS])
            p1 = np.array([float(end[b][0][c]) for c in POS])
            for i in range(n):
                wgt = smoothstep((times[i] - times[0]) / a.blend)
                q = slerp(q0, q1, wgt)
                pp = p0 + (p1 - p0) * wgt
                for c, v in zip(ROT, q):
                    flat[c][i] = v
                for c, v in zip(POS, pp):
                    flat[c][i] = v
            ds[...] = data

    out = M.read_frames(a.out)
    we = A.fk(hier, {k: M.local(v[0]) for k, v in end.items()})
    print(f'寫好 {a.out}：{n} 格，上半身 {len(upper)} 根從原版第 0 格轉到終點（{a.blend} 秒到位）')
    for i in range(n):
        w = A.fk(hier, {k: M.local(v[i]) for k, v in out.items()})
        # 骨盆換成終點的，量槍管相對騎乘骨盆的方向（遊戲裡骨盆來自騎乘動畫）
        ln = {k: M.local(v[i]) for k, v in out.items()}
        ln['pelvis'] = M.local(end['pelvis'][0])
        for leg in ('l_thigh', 'r_thigh'):
            ln[leg] = M.local(end[leg][0])
        w2 = A.fk(hier, ln)
        yaw, pitch = barrel_rel(w2)
        if i % 3 == 0 or i == n - 1:
            print(f'  第 {i:2d} 格 {times[i] - times[0]:.2f}s：槍管 左右 {yaw:7.1f}°（正 = 左） 上下 {pitch:6.1f}°')
        if i == n - 1:
            diff = A.angle_deg(w2['l_weapon'][0] @ A.BARREL, we['l_weapon'][0] @ A.BARREL)
            print(f'檢查：最後一格的槍管和終點差 {diff:.4f}°')
    return 0


if __name__ == '__main__':
    sys.exit(main())
