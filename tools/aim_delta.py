"""雙手持槍第 2 步：瞄準差值（docs/m3.md「雙手持槍：第 2 步：瞄準差值」）

原版的 4 段瞄準差值 man_geralt_gabriel_aimpose_*（上半身動畫圖的 LookAt 節點 #18435 用）主要動左手和頭，
雙手拿 AK 時槍跟不上準心。這裡做新的 4 段：只轉脊椎（torso、torso2、torso3），手臂和 AK 掛在胸口底下，整組跟著轉。

用法（要有 h5py、numpy：用 Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/aim_delta.py
        原版差值的資料夾 底層姿勢.re 輸出資料夾

- 原版差值的資料夾：REDkit 匯出的 4 個 man_geralt_gabriel_aimpose_*.re（當樣板：結構、骨頭、格數照抄，只換數字）
- 底層姿勢：第 1 步的 man_geralt_gabriel_aim_idle_rp.re（用第 0 格的骨頭方向換算差值、檢查結果）
- 輸出：同名的 4 個 .re，放進輸出資料夾（REDkit 匯入我們的動畫組，同名蓋過原版）

根據（docs/m3.md「.re 的內容與 Blender 來回測試」）：
- 原版匯出的是差值：第 0 格全部是單位；差值 D = A·A₀⁻¹（父骨頭座標），位置 = t − R·t（t = 骨頭的區域位置）
  → 套用（推論）：區域變換 = D·底層 → 位置不變、旋轉在父骨頭座標裡先轉 R
- .re 的四元數照 Hamilton 轉矩陣後轉置才是區域旋轉；位置是公分；30 fps，91 格（3.0 秒）
- 時間和角度：第 60 格（2.0 秒）＝ 不偏；左右 時間 = 2.0 − 角度/180（往左是正）、上下 時間 = 2.0 + 角度/90（往上是正）；
  0 → 30 格是 30 → 60 的倒放（節點設定 Animation angle range (180, 90)）
做法：
- 模型座標（X 右、Y 前、Z 上）的總旋轉 Q：左右 = 繞 Z 轉 θ；上下 = 繞 X 轉 φ（3 段 left／center／right 都一樣）
- 平均分給 torso、torso2、torso3：每根在模型座標裡繞自己的原點轉 Q 的 1/3（四元數 slerp），3 根疊起來 = Q
  → 每根的差值 = 父骨頭在底層姿勢（第 0 格）的方向把 Q^(1/3) 換到父骨頭座標
- 其他骨頭全部是單位（不動）：手臂、手、AK 都跟著胸口轉，兩手握槍的關係不變
檢查（把差值套到底層姿勢的第 0 格再做 FK）：槍管方向和該瞄的方向差幾度、右手掌心離握把多遠
"""
import argparse
import math
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent / '_vendor' / 'pylib'))
import h5py  # noqa: E402

SKEL = '.re_asset_node/.re_asset_description_node/.re_skeleton'
CLIP = '.re_asset_node/.re_animation_container/.re_animation/.re_anim_clip'
SPINE = ('torso', 'torso2', 'torso3')
NAMES = {
    'horizontal': 'man_geralt_gabriel_aimpose_horizontal_rp',
    'left': 'man_geralt_gabriel_aimpose_vertical_rp_left',
    'center': 'man_geralt_gabriel_aimpose_vertical_rp_center',
    'right': 'man_geralt_gabriel_aimpose_vertical_rp_right',
}
CENTER = 60  # 第 60 格 = 不偏
# 第 1 步的 AK 擺法（l_weapon 座標；docs/m3.md「雙手持槍：第 1 步：底層姿勢」）
GRIP = np.array([-0.3032, -0.0115, -0.2320])
BARREL = np.array([0.8033, 0.2140, 0.5558])
PALM_R = np.array([0.061, 0.032, -0.002])


def quat_to_mat(x, y, z, w) -> np.ndarray:
    n = math.sqrt(x * x + y * y + z * z + w * w)
    x, y, z, w = x / n, y / n, z / n, w / n
    return np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])


def mat_to_quat(m: np.ndarray) -> np.ndarray:
    """旋轉矩陣 → Hamilton 四元數 (x, y, z, w)。"""
    t = np.trace(m)
    if t > 0:
        s = math.sqrt(t + 1.0) * 2
        q = [(m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s, 0.25 * s]
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = math.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
        q = [0.25 * s, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s, (m[2, 1] - m[1, 2]) / s]
    elif m[1, 1] > m[2, 2]:
        s = math.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
        q = [(m[0, 1] + m[1, 0]) / s, 0.25 * s, (m[1, 2] + m[2, 1]) / s, (m[0, 2] - m[2, 0]) / s]
    else:
        s = math.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
        q = [(m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, 0.25 * s, (m[1, 0] - m[0, 1]) / s]
    q = np.array(q)
    return q / np.linalg.norm(q)


def file_rot(d) -> np.ndarray:
    """.re 的四元數 → 區域旋轉（轉置）。"""
    return quat_to_mat(*(float(d[c]) for c in ('rot.x', 'rot.y', 'rot.z', 'rot.w'))).T


def axis_angle(axis, deg: float) -> np.ndarray:
    a = np.asarray(axis, float) / np.linalg.norm(axis)
    r = math.radians(deg)
    k = np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])
    return np.eye(3) + math.sin(r) * k + (1 - math.cos(r)) * (k @ k)


def angle_deg(a, b) -> float:
    return math.degrees(math.acos(max(-1.0, min(1.0, float(np.dot(a, b) / np.linalg.norm(a) / np.linalg.norm(b))))))


def read_skeleton(path: Path) -> list[tuple[str, str | None]]:
    hier = []
    with h5py.File(path, 'r') as f:
        def walk(g, parent):
            for k in g.keys():
                if isinstance(g[k], h5py.Group):
                    hier.append((k, parent))
                    walk(g[k], k)
        walk(f[SKEL], None)
    return hier


def read_frame0(path: Path) -> dict[str, tuple[np.ndarray, np.ndarray]]:
    """每根骨頭第 0 格的區域（旋轉, 位置 公尺）。"""
    out = {}
    with h5py.File(path, 'r') as f:
        clip = f[CLIP]
        for k in clip.keys():
            if isinstance(clip[k], h5py.Group):
                d = clip[k]['xformframes'][()].reshape(-1)[0]
                out[k] = (file_rot(d), np.array([float(d['pos.x']), float(d['pos.y']), float(d['pos.z'])]) * 0.01)
    return out


def fk(hier, local: dict[str, tuple[np.ndarray, np.ndarray]]) -> dict[str, tuple[np.ndarray, np.ndarray]]:
    """模型座標（Root 不套）：{骨頭: (旋轉, 位置)}。"""
    world = {}
    for name, parent in hier:
        if parent is None:
            world[name] = (np.eye(3), np.zeros(3))
            continue
        pr, pp = world[parent]
        r, t = local[name]
        world[name] = (pr @ r, pp + pr @ t)
    return world


def slerp_identity(q: np.ndarray, s: float) -> np.ndarray:
    """單位四元數到 q 的 s 倍（q 的 w ≥ 0 取短路徑）。"""
    if q[3] < 0:
        q = -q
    ang = 2 * math.acos(max(-1.0, min(1.0, q[3])))
    if ang < 1e-9:
        return np.array([0.0, 0.0, 0.0, 1.0])
    axis = q[:3] / math.sin(ang / 2)
    h = ang * s / 2
    return np.concatenate([axis * math.sin(h), [math.cos(h)]])


def aim_angle(kind: str, frame: int) -> float:
    """這一格要瞄的角度（度）：左右往左是正、上下往上是正；0 → 30 格是 30 → 60 的倒放。"""
    f = frame if frame >= 30 else 60 - frame
    sec = f / 30.0
    return (2.0 - sec) * 180.0 if kind == 'horizontal' else (sec - 2.0) * 90.0


def total_rotation(kind: str, deg: float) -> np.ndarray:
    return axis_angle([0, 0, 1], deg) if kind == 'horizontal' else axis_angle([1, 0, 0], deg)


def spine_deltas(hier, base_world, base_local, q_model: np.ndarray) -> dict[str, tuple[np.ndarray, np.ndarray]]:
    """每根脊椎骨的差值（父骨頭座標的旋轉, 位置 公尺）：模型座標裡繞自己的原點轉 q_model（3 根各一份）。"""
    parent = dict(hier)
    out = {}
    for b in SPINE:
        pr = base_world[parent[b]][0]
        r = pr.T @ q_model @ pr
        t = base_local[b][1]
        out[b] = (r, t - r @ t)
    return out


def apply(hier, base_local, deltas) -> dict:
    local = dict(base_local)
    for b, (r, t) in deltas.items():
        lr, lt = base_local[b]
        local[b] = (r @ lr, r @ lt + t)
    return fk(hier, local)


def palm_grip_cm(world) -> float:
    lw_r, lw_p = world['l_weapon']
    rh_r, rh_p = world['r_hand']
    palm = rh_p + rh_r @ PALM_R
    return float(np.linalg.norm(lw_r.T @ (palm - lw_p) - GRIP)) * 100


def write_delta(template: Path, out: Path, kind: str, hier, base_world, base_local) -> list[str]:
    shutil.copyfile(template, out)
    lines = []
    with h5py.File(out, 'r+') as f:
        clip = f[CLIP]
        bones = [k for k in clip.keys() if isinstance(clip[k], h5py.Group)]
        missing = [b for b in SPINE if b not in bones]
        if missing:
            raise SystemExit(f'{template.name} 沒有骨頭 {missing}')
        count = None
        for b in bones:
            ds = clip[b]['xformframes']
            arr = ds[()]
            flat = arr.reshape(-1)
            count = len(flat) if count is None else count
            for c in ('pos.x', 'pos.y', 'pos.z', 'rot.x', 'rot.y', 'rot.z'):
                flat[c] = 0
            flat['rot.w'] = 1
            for c in ('scale.x', 'scale.y', 'scale.z'):
                if c in flat.dtype.names:
                    flat[c] = 1
            ds[...] = flat.reshape(arr.shape)
        spine_data = {b: clip[b]['xformframes'][()] for b in SPINE}
        for frame in range(count):
            deg = aim_angle(kind, frame)
            q_total = mat_to_quat(total_rotation(kind, deg))
            q_part = quat_to_mat(*slerp_identity(q_total, 1.0 / len(SPINE)))
            deltas = spine_deltas(hier, base_world, base_local, q_part)
            for b in SPINE:
                r, t = deltas[b]
                q = mat_to_quat(r.T)  # 寫進檔案要轉置（讀的時候會再轉置回來）
                rec = spine_data[b].reshape(-1)
                rec[frame]['rot.x'], rec[frame]['rot.y'], rec[frame]['rot.z'], rec[frame]['rot.w'] = (float(v) for v in q)
                rec[frame]['pos.x'], rec[frame]['pos.y'], rec[frame]['pos.z'] = (float(v) * 100 for v in t)
        for b in SPINE:
            clip[b]['xformframes'][...] = spine_data[b]
    # 檢查：讀回來的差值套到底層姿勢的第 0 格
    with h5py.File(out, 'r') as f:
        clip = f[CLIP]
        frames = {b: clip[b]['xformframes'][()].reshape(-1) for b in SPINE}
    for frame in (0, 15, 30, 45, 60, 75, 90):
        deltas = {}
        for b in SPINE:
            d = frames[b][frame]
            deltas[b] = (file_rot(d), np.array([float(d['pos.x']), float(d['pos.y']), float(d['pos.z'])]) * 0.01)
        world = apply(hier, base_local, deltas)
        deg = aim_angle(kind, frame)
        want = total_rotation(kind, deg) @ (base_world['l_weapon'][0] @ BARREL)
        got = world['l_weapon'][0] @ BARREL
        lines.append(f'  第 {frame:2d} 格：瞄 {deg:7.1f}°；槍管和該瞄的方向差 {angle_deg(got, want):.3f}°；'
                     f'右手掌心離握把 {palm_grip_cm(world):.2f} 公分；torso3 轉了 {angle_deg(world["torso3"][0] @ [0, 1, 0], base_world["torso3"][0] @ [0, 1, 0]):.1f}°')
    return lines


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8')  # Blender 內建的 Python 不讀 PYTHONUTF8
    ap = argparse.ArgumentParser()
    ap.add_argument('orig_dir', type=Path)
    ap.add_argument('base', type=Path)
    ap.add_argument('out_dir', type=Path)
    a = ap.parse_args()
    hier = read_skeleton(a.base)
    base_local = read_frame0(a.base)
    base_world = fk(hier, base_local)
    parent = dict(hier)
    print('脊椎：' + ' → '.join(f'{parent[b]} → {b}' if i == 0 else b for i, b in enumerate(SPINE)))
    barrel0 = base_world['l_weapon'][0] @ BARREL
    print(f'底層姿勢第 0 格：槍管方向 ({barrel0[0]:.3f}, {barrel0[1]:.3f}, {barrel0[2]:.3f})；右手掌心離握把 {palm_grip_cm(base_world):.2f} 公分')
    a.out_dir.mkdir(parents=True, exist_ok=True)
    for kind, name in NAMES.items():
        template = a.orig_dir / f'{name}.re'
        out = a.out_dir / f'{name}.re'
        print(f'{out.name}（{"左右" if kind == "horizontal" else "上下"}）')
        for line in write_delta(template, out, kind, hier, base_world, base_local):
            print(line)
    return 0


if __name__ == '__main__':
    sys.exit(main())
