"""「持槍衝鋒」的底層姿勢（使用者第 30 項：「持槍但沒有進入戰鬥狀態時…按下AD往左往右跑時，上半身太挺直了，
整體看起來很滑稽，可以參考拿劍然後未進入戰鬥狀態時的左右前進(跑，走)姿態，應該要更加持槍衝鋒的姿態」）。

用法（Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/charge_pose.py
        底層.re 輸出.re [--lean 16] [--down 8] [--head 16] [--gun 0 0 0]

- 底層：正面持槍 assets\\anims\\gfg\\square\\man_geralt_gabriel_aim_idle_square.re，用第 0 格；輸出每格都一樣
  （結構照底層）→ 給 tools/move_pose.py 當「第 1 步」（--full 只用第 0 格）重做沒開槍時的走跑
- 上半身往前彎 --lean 度：torso、torso2、torso3 各三分之一，繞角色的右方（reload_pose.body_axes）；槍、兩手跟著
- 槍以槍托後端（square_pose.BUTT）為軸、槍口往下 --down 度（低持：槍托留在肩窩、槍口朝前下）；--gun 再移（往右、往前、往上，公尺）
- 兩手照底層的握法（右手握把、左手護木）用兩節 IK 解（square_pose.two_bone_ik）；l_weapon 用 FK 讀回的左手算
- 頭抬回 --head 度（往前彎時眼睛看前方）
"""
import argparse
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import aim_delta as A  # noqa: E402  （同時把 h5py 的路徑加進來）
import move_pose as M  # noqa: E402
import reload_pose as R  # noqa: E402
import square_pose as S  # noqa: E402
import h5py  # noqa: E402

LEFT_ARM = ('l_bicep', 'l_forearm', 'l_hand')
RIGHT_ARM = ('r_bicep', 'r_forearm', 'r_hand')
SPINE = ('torso', 'torso2', 'torso3')


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8')
    p = argparse.ArgumentParser(description='持槍衝鋒的底層姿勢（前彎、低持）')
    p.add_argument('base', type=Path)
    p.add_argument('out', type=Path)
    p.add_argument('--lean', type=float, default=16.0, help='上半身往前彎（度）')
    p.add_argument('--down', type=float, default=8.0, help='槍口往下（度，以槍托後端為軸）')
    p.add_argument('--head', type=float, default=16.0, help='頭抬回（度）')
    p.add_argument('--gun', type=float, nargs=3, default=(0.0, 0.0, 0.0), metavar=('右', '前', '上'), help='槍再移（公尺）')
    a = p.parse_args()

    hier = A.read_skeleton(a.base)
    par = dict(hier)
    base = M.read_frames(a.base)
    n = len(next(iter(base.values())))
    loc0 = {k: M.local(v[0]) for k, v in base.items()}
    w0 = S.fk4(hier, loc0)
    g0 = w0['l_weapon']
    rel_r = np.linalg.inv(g0) @ w0['r_hand']
    rel_l = np.linalg.inv(g0) @ w0['l_hand']
    body = R.body_axes(g0)

    # 上半身往前彎：三節脊椎各轉三分之一（世界座標、以各自的關節為軸）
    loc = dict(loc0)
    rb = A.axis_angle(body[0], -a.lean / len(SPINE))
    tb = np.eye(4)
    for bone in SPINE:
        wcur = S.fk4(hier, loc)
        pj = wcur[bone][:3, 3]
        loc[bone] = (wcur[par[bone]][:3, :3].T @ rb @ wcur[bone][:3, :3], loc0[bone][1])
        tb = S.rigid(rb, pj - rb @ pj) @ tb
    # 槍：以槍托後端為軸、槍口往下，再移 --gun，最後跟著上半身
    butt = (g0 @ np.append(S.BUTT, 1.0))[:3]
    rd = A.axis_angle(g0[:3, :3] @ R.GR, -a.down)
    move = np.eye(4)
    move[:3, 3] = body.T @ np.asarray(a.gun)
    g = tb @ move @ S.rigid(rd, butt - rd @ butt) @ g0

    wl = S.fk4(hier, loc)
    hw = A.axis_angle(body[0], a.head) @ wl['head'][:3, :3]
    loc['head'] = (wl[par['head']][:3, :3].T @ hw, loc0['head'][1])
    solved = {}
    solved.update(S.two_bone_ik(wl, LEFT_ARM, g @ rel_l))
    solved.update(S.two_bone_ik(wl, RIGHT_ARM, g @ rel_r))
    for bones in (LEFT_ARM, RIGHT_ARM):
        parent = wl[par[bones[0]]]
        for name in bones:
            m = np.linalg.inv(parent) @ solved[name]
            loc[name] = (m[:3, :3], loc0[name][1])
            parent = solved[name]
    m = np.linalg.inv(S.fk4(hier, loc)['l_hand']) @ g
    loc['l_weapon'] = (m[:3, :3], m[:3, 3])

    # 檢查：FK 讀回
    wn = S.fk4(hier, loc)
    dr = np.linalg.norm(wn['r_hand'][:3, 3] - (g @ rel_r)[:3, 3])
    dl = np.linalg.norm(wn['l_hand'][:3, 3] - (g @ rel_l)[:3, 3])
    dg = np.linalg.norm(wn['l_weapon'][:3, 3] - g[:3, 3])
    reach = []
    for bones in (LEFT_ARM, RIGHT_ARM):
        s_, e_, w_ = (wn[b][:3, 3] for b in bones)
        reach.append(np.linalg.norm(w_ - s_) / (np.linalg.norm(e_ - s_) + np.linalg.norm(w_ - e_)))
    barrel = wn['l_weapon'][:3, :3] @ R.GF
    nb = (wn['l_weapon'] @ np.append(S.BUTT, 1.0))[:3]
    sh = wn['r_bicep'][:3, 3]
    print(f'槍管（模型座標）{np.round(barrel, 3)}；槍托後端離右肩關節 {np.round(nb - sh, 3)}（右、前、上）')
    print(f'檢查：右手和目標差 {dr * 1000:.2f}、左手 {dl * 1000:.2f}、槍 {dg * 1000:.3f} 公釐；伸直 左 {reach[0]:.2f}、右 {reach[1]:.2f}')

    changed = list(SPINE) + ['head', 'l_weapon'] + list(LEFT_ARM) + list(RIGHT_ARM)
    R.extend(a.base, a.out, n)
    with h5py.File(a.out, 'r+') as f:
        clip = f[A.CLIP]
        for bone in changed:
            ds = clip[bone]['xformframes']
            data = ds[()]
            flat = data.reshape(-1)
            r, tr = loc[bone]
            q = A.mat_to_quat(r.T)  # 區域旋轉 → 檔案的四元數（轉置）
            for i in range(n):
                for c, v in zip(R.ROT, q):
                    flat[c][i] = v
                for c, v in zip(R.POS, np.asarray(tr) * 100):  # 公尺 → 公分
                    flat[c][i] = v
            ds[...] = data
    print(f'寫好 {a.out}：{n} 格（每格一樣）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
