"""修補 REDkit 的 Blender 外掛匯出的 .re：把外掛改掉的骨頭位置、Root 改回原檔的值，再和原檔比對。

用法（要有 h5py、numpy：用 Blender 內建的 Python，h5py 在 tools\\_vendor\\pylib）：
    "D:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/re_fix.py
        外掛匯出.re 原檔.re 輸出.re [--report-deg 0.01]

- 原檔：REDkit 的 Export animation 匯出的 .re（改動畫之前的那一段）
- 外掛的匯出（docs/m3.md「.re 的內容與 Blender 來回測試」）：
  - 旋轉正確（來回差 0.001° 以內）
  - 位置：和父骨頭同一點的骨頭被補成 5 公分（外掛 import_anims.py:402-409），接在後面的骨頭差 2 公分；
    名稱是 root 的骨頭被歸零（export_anims.py:524-527、:439-440）
- 修補（輸出檔先複製外掛的匯出，再改數字；檔案結構照外掛的）：
  - 所有骨頭每一格的位置換成原檔的：改動畫只轉骨頭、不改骨頭長度；pelvis、IK_*、Trajectory 這些會動的位置也照原檔
  - Root：位置、旋轉都換成原檔的
  - 旋轉（Root 以外）、縮放照外掛的匯出
- 骨頭名稱或格數和原檔不同就停止，不寫輸出檔
- 輸出檔可以和外掛匯出是同一個檔（就地修補）
- 最後列出和原檔不同的骨頭：旋轉差超過 --report-deg 度、或位置差超過 0.001 公分
"""
import argparse
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent / '_vendor' / 'pylib'))
import h5py  # noqa: E402

CLIP = '.re_asset_node/.re_animation_container/.re_animation/.re_anim_clip'
ROOT = 'Root'
POS = ('pos.x', 'pos.y', 'pos.z')
ROT = ('rot.x', 'rot.y', 'rot.z', 'rot.w')
POS_EPS_CM = 0.001


def read_frames(path: Path) -> dict[str, np.ndarray]:
    """每根骨頭的 xformframes（攤平成一維的結構陣列）。"""
    with h5py.File(path, 'r') as f:
        clip = f[CLIP]
        return {k: clip[k]['xformframes'][()].reshape(-1) for k in clip.keys() if isinstance(clip[k], h5py.Group)}


def check_same_layout(a: dict[str, np.ndarray], b: dict[str, np.ndarray]) -> str | None:
    if set(a) != set(b):
        return f'骨頭名稱不同：只在第一個檔 {sorted(set(a) - set(b))}；只在第二個檔 {sorted(set(b) - set(a))}'
    counts = {k: (len(a[k]), len(b[k])) for k in a if len(a[k]) != len(b[k])}
    if counts:
        return f'格數不同（骨頭：(第一個, 第二個)）：{counts}'
    return None


def fix(plugin_path: Path, orig_path: Path, out_path: Path) -> list[tuple[str, float]]:
    """寫出修補後的檔；回傳每根骨頭改回去的位置量（公分，整段最大值）。"""
    orig = read_frames(orig_path)
    layout_error = check_same_layout(read_frames(plugin_path), orig)
    if layout_error:
        raise ValueError(layout_error)
    if plugin_path.resolve() != out_path.resolve():
        shutil.copyfile(plugin_path, out_path)
    moved = []
    with h5py.File(out_path, 'r+') as f:
        clip = f[CLIP]
        for name, src in orig.items():
            ds = clip[name]['xformframes']
            data = ds[()]
            flat = data.reshape(-1).copy()
            before = np.stack([flat[c] for c in POS], axis=1).astype(np.float64)
            for c in POS:
                flat[c] = src[c]
            if name == ROOT:
                for c in ROT:
                    flat[c] = src[c]
            after = np.stack([flat[c] for c in POS], axis=1).astype(np.float64)
            moved.append((name, float(np.linalg.norm(before - after, axis=1).max())))
            ds[...] = flat.reshape(data.shape)
    return moved


def compare(a_path: Path, b_path: Path) -> list[tuple[str, float, float]]:
    """每根骨頭：(名稱, 旋轉差的最大角度（度）, 位置差的最大值（公分）)。"""
    a, b = read_frames(a_path), read_frames(b_path)
    layout_error = check_same_layout(a, b)
    if layout_error:
        raise ValueError(layout_error)
    rows = []
    for name in sorted(a):
        qa = np.stack([a[name][c] for c in ROT], axis=1).astype(np.float64)
        qb = np.stack([b[name][c] for c in ROT], axis=1).astype(np.float64)
        qa /= np.linalg.norm(qa, axis=1, keepdims=True)
        qb /= np.linalg.norm(qb, axis=1, keepdims=True)
        dot = np.abs(np.sum(qa * qb, axis=1)).clip(0, 1)
        deg = float(np.degrees(2 * np.arccos(dot)).max())
        pa = np.stack([a[name][c] for c in POS], axis=1).astype(np.float64)
        pb = np.stack([b[name][c] for c in POS], axis=1).astype(np.float64)
        rows.append((name, deg, float(np.linalg.norm(pa - pb, axis=1).max())))
    return rows


def report(out_path: Path, orig_path: Path, moved: list[tuple[str, float]], report_deg: float) -> None:
    fixed = [(n, d) for n, d in moved if d > POS_EPS_CM]
    print(f'改回原檔位置的骨頭：{len(fixed)} 根' + (f'（最多 {max(d for _, d in fixed):.2f} 公分）' if fixed else ''))
    for n, d in sorted(fixed, key=lambda x: -x[1]):
        print(f'  {n}: {d:.3f} 公分')
    rows = compare(out_path, orig_path)
    diff = [r for r in rows if r[1] > report_deg or r[2] > POS_EPS_CM]
    same = [r for r in rows if r not in diff]
    print(f'\n和原檔不同的骨頭（旋轉差 > {report_deg}° 或位置差 > {POS_EPS_CM} 公分）：{len(diff)} 根')
    for n, deg, cm in sorted(diff, key=lambda r: -r[1]):
        print(f'  {n}: 旋轉 {deg:.3f}°、位置 {cm:.4f} 公分')
    if same:
        print(f'其他 {len(same)} 根和原檔一樣（旋轉差最大 {max(r[1] for r in same):.4f}°）')


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description='修補外掛匯出的 .re')
    p.add_argument('plugin', type=Path, help='外掛匯出的 .re')
    p.add_argument('original', type=Path, help='REDkit 匯出的原檔 .re')
    p.add_argument('out', type=Path, help='輸出 .re（可以和外掛匯出同一個檔）')
    p.add_argument('--report-deg', type=float, default=0.01, help='旋轉差超過幾度才列出（預設 0.01）')
    return p.parse_args()


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    args = parse_args()
    for p in (args.plugin, args.original):
        if not p.is_file():
            print(f'找不到檔案：{p}')
            return 2
    try:
        moved = fix(args.plugin, args.original, args.out)
    except ValueError as e:
        print(f'停止：{e}')
        return 1
    print(f'已存：{args.out}')
    report(args.out, args.original, moved, args.report_deg)
    return 0


if __name__ == '__main__':
    sys.exit(main())
