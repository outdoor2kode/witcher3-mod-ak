"""走路、跑步時蓋在上半身的姿勢（雙手持槍）：第 1 步的姿勢，torso 補正成走跑時骨盆的方向。

用法（要有 h5py、numpy：用 Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/move_pose.py
        第1步.re 原版走跑.re 輸出.re 格數

- 第 1 步：assets\\anims\\gfg\\man_geralt_gabriel_aim_idle_rp.re（雙手持槍的底層姿勢；docs/m3.md「雙手持槍：第 1 步」）
- 原版走跑：REDkit 匯出的原版十字弩走跑動畫（例：ex_man_geralt_gabriel_aim_run.re）；只用它的骨盆方向（整段平均）
- 輸出：第 1 步的前 N 格（結構照第 1 步），只換掉 torso 的旋轉；檔名 = 要蓋過的原版動畫名稱
- 原因（docs/m3.md「雙手持槍：直線走路、跑步的右手」）：
  - 主動畫圖拿十字弩走跑時，用 BlendOverride 把這段動畫的脊椎、頭、兩手臂（70 根）蓋在一般走跑動畫上（tools/gameplay_patch.py 之後直線也是）
  - 骨盆來自一般走跑動畫；第 1 步的姿勢是 NPC 的瞄準站姿，骨盆側身 → 直接蓋上去，上半身跟著往左轉約 60°（2026-10-16 06:15 遊戲實測 57～62°）
- 補正：torso 的區域旋轉 T' = Pm⁻¹·P1·T1（P1、T1：第 1 步該格的骨盆、torso；Pm：原版走跑的平均骨盆）
  → 走跑時 torso 在模型座標的方向 = Pb·T' ≈ P1·T1（Pb ≈ Pm）＝站著的方向；torso 以下（脊椎、手臂、AK）的區域變換照第 1 步
  → 站著、走跑的槍、手一樣；走跑瞄準差值（局部疊加）也照樣適用
- 模型座標不含 Root（同 tools/aim_delta.py 的 fk）；.re 的四元數照 Hamilton 轉矩陣後轉置才是區域旋轉
- 檢查：輸出的每一格，骨盆換成 Pm 做 FK → torso3 的方向、槍管方向和第 1 步該格差幾度（應該 0）；
  原版骨盆每一格和平均差多少（= 走跑時槍會晃的量，估計）
- --full（2026-10-16 06:3x）：以原版動畫為底（腿、骨盆、位移、IK 照原版），torso 以下整串換成第 1 步第 0 格，
  torso 每格 T' = Pr(f)⁻¹·P1·T1（Pr(f)：原版該格的骨盆）→ 上半身在模型座標的方向固定、跟著骨盆上下起伏
  - --mean：torso 改用原版的平均骨盆補正（同預設模式）；跑步用：aim_run 在主動畫圖是疊在一般跑步上，兩者步伐相位不一定對齊，
    逐格補正時槍管和鏡頭差 0.4～11.6°、平均補正 1.6～5.9°（06:21、06:40 實測）；走路逐格補正 0.1～0.5°（上半身圖整段播走路那段）
  - 原因：上半身動畫圖的十字弩區塊（#18428 的 ExplorationMoveInitial，docs/m3.md）把走路兩段、aim_run 整個人拿來播
    → 腿要真的在走；用靜止的姿勢時，走路模式下腳不動、身體被位移拖著走（06:35 實測）
- --motion [原版.re]：Trajectory 軌（動畫的位移）照抄原版（不給檔名 = 第 2 個參數；格數要一樣；坡度的兩段用自己的位移、平地跑步的骨盆）
  - 原因：拿著 AK 開走路模式時人不會動（2026-10-16 06:23、06:29 遊戲實測；原版動畫圖也一樣）；
    第 1 步的姿勢是站著的，Trajectory 不動；原版十字弩走跑動畫的 Trajectory 會往前（慢走 1.4 公尺／1.23 秒、快走 2 公尺／秒、跑 3.4 公尺／0.67 秒）
    → 推論：走路時的位移取自覆蓋動畫的位移（沒驗證；跑步時用靜止的姿勢也會動）
- --spread a1 a2 a3（2026-10-16 22:xx，第 13、14 項）：補正分給 torso、torso2、torso3（預設 1 0 0 = 全部在 torso，同之前）
  - 原因：走跑時骨盆朝前、上半身側身，差的角度全部擠在 torso 一節 → 看起來腰被折一個角（使用者回報「腰扭過多」）
  - 做法（模型座標）：誤差 E = Pr·P1⁻¹（原版骨盆相對第 1 步骨盆）；torso 的世界方向 = E^(1−a1)·(第 1 步的 torso)、
    torso2 = E^(1−a1−a2)·(第 1 步的 torso2)、torso3 = E^(1−a1−a2−a3)·(第 1 步的 torso3) = 第 1 步的（a 的和要是 1）；
    E^s 用軸角（角度乘 s）；區域旋轉 = 父骨頭世界方向⁻¹·世界方向；區域位置不變
  - torso3 以下（胸口、手臂、AK、頭）的世界方向和之前一樣 → 槍、手不變
- --pelvis-from 檔.re（2026-10-16 22:4x，第 17 項）：--full 的補正改用另一個檔的平均骨盆（不用底的動畫自己的骨盆）
  - 原因：騎馬換彈 `horse_trot_reload_lowered`、`horse_gallop_reload_lowered` 的原版骨盆在模型座標朝後（179°、121°，Root 轉回來），
    遊戲裡騎馬的骨盆來自騎乘動畫（覆蓋節點只取 torso 以上）→ 用換彈自己的骨盆補正，上半身被轉到後面（使用者回報「換彈 180° 往後看」）
  - 用法：給同一個步伐的 aim_cycle 原版（例：`A/man_geralt_gabriel_horse_horse_trot_aim_cycle.re`）
"""
import argparse
import math
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import aim_delta as A  # noqa: E402  （同時把 h5py 的路徑加進來）
import h5py  # noqa: E402

ANIM = '.re_asset_node/.re_animation_container/.re_animation'
ROT = ('rot.x', 'rot.y', 'rot.z', 'rot.w')


def angle(r: np.ndarray) -> float:
    return math.degrees(math.acos(max(-1.0, min(1.0, (np.trace(r) - 1) / 2))))


def read_frames(path: Path) -> dict[str, np.ndarray]:
    with h5py.File(path, 'r') as f:
        clip = f[A.CLIP]
        return {k: clip[k]['xformframes'][()].reshape(-1) for k in clip.keys() if isinstance(clip[k], h5py.Group)}


def local(d) -> tuple[np.ndarray, np.ndarray]:
    return A.file_rot(d), np.array([float(d['pos.x']), float(d['pos.y']), float(d['pos.z'])]) * 0.01


def mean_rotation(rs: list[np.ndarray]) -> np.ndarray:
    u, _s, vt = np.linalg.svd(sum(rs) / len(rs))
    m = u @ vt
    if np.linalg.det(m) < 0:
        u[:, -1] *= -1
        m = u @ vt
    return m


def trim(src: Path, dst: Path, n: int) -> None:
    """複製第 1 步、截成前 n 格（同暫存的 re_trim：每根骨頭的 xformframes 重建、numkeys、animlength）。"""
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
            del clip[k]['xformframes']
            new = clip[k].create_dataset('xformframes', data=data[:n], **kwargs)
            for a, v in attrs.items():
                new.attrs[a] = v
        f[ANIM].attrs['.numkeys'] = n
        f[ANIM].attrs['.animlength'] = (n - 1) / 30.0


SPINE = ('torso', 'torso2', 'torso3')


def rot_pow(r: np.ndarray, s: float) -> np.ndarray:
    """旋轉的 s 倍（軸角：角度乘 s）。"""
    ang = math.acos(max(-1.0, min(1.0, (np.trace(r) - 1) / 2)))
    if ang < 1e-9:
        return np.eye(3)
    axis = np.array([r[2, 1] - r[1, 2], r[0, 2] - r[2, 0], r[1, 0] - r[0, 1]]) / (2 * math.sin(ang))
    return A.axis_angle(axis, math.degrees(ang) * s)


def spine_locals(pr: np.ndarray, p1: np.ndarray, t1: tuple, spread) -> dict[str, np.ndarray]:
    """--spread：骨盆 pr（區域 = 世界）上，torso、torso2、torso3 的區域旋轉。t1 = 第 1 步的三節區域旋轉，p1 = 第 1 步的骨盆。"""
    e = pr @ p1.T
    w1 = p1
    left = 1.0
    out, parent = {}, pr
    for bone, r1, a in zip(SPINE, t1, spread):
        w1 = w1 @ r1                    # 第 1 步的世界方向
        left -= a
        w = rot_pow(e, max(left, 0.0)) @ w1
        out[bone] = parent.T @ w
        parent = w
    return out


def upper_body(hier) -> list[str]:
    """torso 和它底下所有的骨頭。"""
    children: dict = {}
    for name, parent in hier:
        children.setdefault(parent, []).append(name)
    out, stack = [], ['torso']
    while stack:
        b = stack.pop()
        out.append(b)
        stack += children.get(b, [])
    return out


def full_mode(a, s1: dict, ref: dict) -> int:
    """--full：原版動畫為底，torso 以下換成第 1 步第 0 格；torso 每格依原版骨盆補正（上半身的模型座標方向固定）。"""
    hier = A.read_skeleton(a.ref)
    if hier != A.read_skeleton(a.step1):
        print('兩個檔的骨架不同')
        return 1
    upper = upper_body(hier)
    n = len(ref['pelvis'])
    p1 = local(s1['pelvis'][0])[0]
    t1s = tuple(local(s1[b][0])[0] for b in SPINE)
    pm = mean_rotation([local(x)[0] for x in ref['pelvis']])
    if a.pelvis_from:
        pm = mean_rotation([local(x)[0] for x in read_frames(Path(a.pelvis_from))['pelvis']])
    shutil.copyfile(a.ref, a.out)
    with h5py.File(a.out, 'r+') as f:
        clip = f[A.CLIP]
        for b in upper:
            ds = clip[b]['xformframes']
            data = ds[()]
            flat = data.reshape(-1)
            for c in flat.dtype.names:
                if c != 'time':
                    flat[c][:] = s1[b][0][c]
            if b in SPINE:
                for i in range(n):
                    pr = pm if a.mean or a.pelvis_from else local(ref['pelvis'][i])[0]
                    q = A.mat_to_quat(spine_locals(pr, p1, t1s, a.spread)[b].T)
                    for c, v in zip(ROT, q):
                        flat[c][i] = v
            ds[...] = data

    out = read_frames(a.out)
    w1 = A.fk(hier, {k: local(v[0]) for k, v in s1.items()})
    b1 = w1['l_weapon'][0] @ A.BARREL
    worst_t3 = worst_barrel = 0.0
    for i in range(n):
        wn = A.fk(hier, {k: local(v[i]) for k, v in out.items()})
        if a.mean or a.pelvis_from:
            ln = {k: local(v[i]) for k, v in out.items()}
            ln['pelvis'] = (pm, ln['pelvis'][1])
            wn = A.fk(hier, ln)
        worst_t3 = max(worst_t3, angle(wn['torso3'][0].T @ w1['torso3'][0]))
        worst_barrel = max(worst_barrel, A.angle_deg(b1, wn['l_weapon'][0] @ A.BARREL))
        changed = [k for k in out if k not in upper and not np.array_equal(out[k][i].tolist(), ref[k][i].tolist())]
        if changed:
            print(f'第 {i} 格上半身以外的骨頭變了：{changed[:5]}')
            return 1
    sway = max(angle(local(ref['pelvis'][0])[0].T @ local(x)[0]) for x in ref['pelvis'])
    how = '用平均骨盆補正' if a.mean else '每格補正'
    print(f'寫好 {a.out}：{n} 格（原版的）；上半身 {len(upper)} 根換成第 1 步，torso {how}（原版骨盆最多轉 {sway:.1f}°）')
    print(f'檢查' + ('（骨盆 = 原版平均）' if a.mean else '') + f'：每格的 torso3 方向和第 1 步最多差 {worst_t3:.4f}°；槍管方向最多差 {worst_barrel:.4f}°；腿、骨盆、位移和原版一樣')
    return 0


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8')
    p = argparse.ArgumentParser(description='走跑時上半身的雙手持槍姿勢（torso 補正）')
    p.add_argument('step1', type=Path)
    p.add_argument('ref', type=Path)
    p.add_argument('out', type=Path)
    p.add_argument('frames', type=int, nargs='?', help='輸出的格數（--full 時不用：照原版）')
    p.add_argument('--motion', nargs='?', const='', default=None, metavar='原版.re',
                   help='Trajectory 軌照抄原版（不給檔名 = 第 2 個參數的原版；格數要一樣）')
    p.add_argument('--full', action='store_true', help='原版動畫為底（腿、骨盆、位移照原版），只換上半身')
    p.add_argument('--mean', action='store_true', help='--full 時 torso 用原版的平均骨盆補正（不逐格）')
    p.add_argument('--pelvis-from', metavar='檔.re', help='--full 的補正改用這個檔的平均骨盆（騎馬換彈用騎乘的骨盆）')
    p.add_argument('--spread', type=float, nargs=3, default=[1.0, 0.0, 0.0], metavar=('A1', 'A2', 'A3'),
                   help='補正分給 torso、torso2、torso3 的比例（預設 1 0 0：全部在 torso）')
    a = p.parse_args()
    if abs(sum(a.spread) - 1) > 1e-6:
        print('--spread 的和要是 1')
        return 1

    s1 = read_frames(a.step1)
    if a.full:
        return full_mode(a, s1, read_frames(a.ref))
    if a.frames is None:
        print('要給格數')
        return 1
    n1 = len(s1['pelvis'])
    if not 2 <= a.frames <= n1:
        print(f'格數要在 2～{n1}')
        return 1
    ref = read_frames(a.ref)
    pm = mean_rotation([local(x)[0] for x in ref['pelvis']])
    sway = max(angle(pm.T @ local(x)[0]) for x in ref['pelvis'])
    p1_0 = local(s1['pelvis'][0])[0]
    print(f'原版 {a.ref.name}：{len(ref["pelvis"])} 格；平均骨盆和第 1 步差 {angle(pm.T @ p1_0):.1f}°；每格和平均最多差 {sway:.1f}°（走跑時上半身晃的量）')

    trim(a.step1, a.out, a.frames)
    with h5py.File(a.out, 'r+') as f:
        for b in SPINE:
            ds = f[A.CLIP][b]['xformframes']
            data = ds[()]
            flat = data.reshape(-1)
            for i in range(a.frames):
                p1 = local(s1['pelvis'][i])[0]
                t1s = tuple(local(s1[x][i])[0] for x in SPINE)
                q = A.mat_to_quat(spine_locals(pm, p1, t1s, a.spread)[b].T)  # 檔案的四元數 → 矩陣後轉置 = 區域旋轉
                for c, v in zip(ROT, q):
                    flat[c][i] = v
            ds[...] = data
        if a.motion is not None:
            mref = read_frames(Path(a.motion)) if a.motion else ref
            if len(mref['Trajectory']) != a.frames:
                print(f'--motion：原版 {len(mref["Trajectory"])} 格，和輸出的 {a.frames} 格不同')
                return 1
            tds = f[A.CLIP]['Trajectory']['xformframes']
            tdata = tds[()]
            tflat = tdata.reshape(-1)
            for c in tflat.dtype.names:
                if c != 'time':
                    tflat[c][:] = mref['Trajectory'][c]
            tds[...] = tdata

    # 檢查：骨盆換成 Pm 做 FK，torso3、槍管和第 1 步該格比
    hier = A.read_skeleton(a.step1)
    out = read_frames(a.out)
    worst_t3 = worst_barrel = 0.0
    for i in range(a.frames):
        l1 = {k: local(v[i]) for k, v in s1.items()}
        ln = {k: local(v[i]) for k, v in out.items()}
        ln['pelvis'] = (pm, ln['pelvis'][1])
        w1 = A.fk(hier, l1)
        wn = A.fk(hier, ln)
        worst_t3 = max(worst_t3, angle(wn['torso3'][0].T @ w1['torso3'][0]))
        b1 = w1['l_weapon'][0] @ A.BARREL
        bn = wn['l_weapon'][0] @ A.BARREL
        worst_barrel = max(worst_barrel, A.angle_deg(b1, bn))
        allowed = set(SPINE) | ({'Trajectory'} if a.motion is not None else set())
        changed = [k for k in out if k not in allowed and not np.array_equal(out[k][i].tolist(), s1[k][i].tolist())]
        if changed:
            print(f'第 {i} 格 torso 以外的骨頭變了：{changed[:5]}')
            return 1
    print(f'寫好 {a.out}：{a.frames} 格、{(a.frames - 1) / 30:.4f} 秒；換了 torso 的旋轉' + ('、Trajectory（照抄原版）' if a.motion is not None else ''))
    if a.motion is not None:
        t = out['Trajectory']
        print(f'  Trajectory：第 0 格 ({float(t[0]["pos.x"]):.1f}, {float(t[0]["pos.y"]):.1f})、最後 ({float(t[-1]["pos.x"]):.1f}, {float(t[-1]["pos.y"]):.1f}) 公分')
    print(f'檢查（骨盆 = 原版平均）：torso3 方向和第 1 步最多差 {worst_t3:.4f}°；槍管方向最多差 {worst_barrel:.4f}°')
    return 0


if __name__ == '__main__':
    sys.exit(main())
