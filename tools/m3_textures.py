"""M3 第 4 步前：把 CS2 匯出的 AK 貼圖做成巫師3 `pbr_std` 材質用的兩張 PNG。

用法：
    "D:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --factory-startup --background
        --python-exit-code 1 --python tools/m3_textures.py --
        顏色.png 法線.png ORM.png 輸出資料夾 [--size 2048]

- 只讀三張來源圖；輸出 gfg_ak47_d01.png、gfg_ak47_n01.png 到輸出資料夾（沒有就建立）
- gfg_ak47_d01.png：顏色圖縮小，RGB（`pbr_std` 的 Diffuse；alpha 會當 Mask，所以不放）
- gfg_ak47_n01.png：法線圖縮小，RGB = 法線、alpha = 粗糙度（ORM 圖的 G）
  - `pbr_std` 把 Normal 的 alpha 當 Roughness（docs/m3.md「第 4 步前的查證」）
  - ORM 圖的 G 是 Source 2 Viewer 的 csgo_weapon 對照表從 g_tMetalness 拿到的粗糙度（docs/m3.md）
- 尺寸：預設 2048（貼圖群組 WorldDiffuse、NormalmapGloss 的 maxsize，texturegroups.xml）
  - 只接受整數倍縮小；每個輸出像素是來源 N×N 個像素的平均
  - 法線縮小後重新正規化（解碼成向量 → 平均 → 正規化 → 編碼回 0～1）
- 讀寫都當成原始數值（Non-Color），不做色彩空間轉換
- 存完再讀回來，印出每個通道的平均，和來源比對
- Blender 內建的 Python 預設不讀 PYTHONUTF8 等環境變數，所以在腳本裡把輸出改成 UTF-8
"""
import argparse
import struct
import sys
from pathlib import Path

import bpy
import numpy as np

NAME = 'gfg_ak47'


def parse_args() -> argparse.Namespace:
    # blender 會把 "--" 後面的參數留給腳本
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    p = argparse.ArgumentParser(prog='m3_textures.py')
    p.add_argument('color', type=Path, help='ak47_default_color_*.png')
    p.add_argument('normal', type=Path, help='ak47_default_normal_*.png')
    p.add_argument('orm', type=Path, help='ak47_default_ao_*_orm_*.png')
    p.add_argument('out_dir', type=Path, help='輸出資料夾')
    p.add_argument('--size', type=int, default=2048, help='輸出的邊長（預設 2048）')
    return p.parse_args(argv)


def load(path: Path) -> np.ndarray:
    img = bpy.data.images.load(str(path))
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return px.reshape(h, w, 4)


def shrink(a: np.ndarray, size: int) -> np.ndarray:
    h, w, c = a.shape
    if h != w or h % size:
        raise ValueError(f'來源 {w}x{h} 不能整數倍縮成 {size}')
    k = h // size
    return a.reshape(size, k, size, k, c).mean(axis=(1, 3))


def save(path: Path, rgba: np.ndarray, alpha: bool) -> None:
    h, w, _ = rgba.shape
    img = bpy.data.images.new(path.stem, w, h, alpha=alpha)
    img.colorspace_settings.name = 'Non-Color'
    img.pixels.foreach_set(np.clip(rgba, 0, 1).astype(np.float32).ravel())
    img.filepath_raw = str(path)
    img.file_format = 'PNG'
    img.save()
    bpy.data.images.remove(img)


def png_kind(path: Path) -> str:
    w, h, depth, ctype = struct.unpack('>IIBB', path.read_bytes()[16:26])
    return f'{w}x{h}、{depth} 位元、' + {2: 'RGB', 6: 'RGBA'}.get(ctype, f'色彩類型 {ctype}')


def means(a: np.ndarray, channels: str) -> str:
    return '、'.join(f'{ch} {a[..., i].mean():.3f}' for i, ch in enumerate(channels))


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    args = parse_args()
    for p in (args.color, args.normal, args.orm):
        if not p.is_file():
            print(f'找不到檔案：{p}')
            return 2
    args.out_dir.mkdir(parents=True, exist_ok=True)
    d_path = (args.out_dir / f'{NAME}_d01.png').resolve()
    n_path = (args.out_dir / f'{NAME}_n01.png').resolve()

    color = load(args.color)
    normal = load(args.normal)
    orm = load(args.orm)
    print(f'來源：顏色 {color.shape[1]}x{color.shape[0]}、法線 {normal.shape[1]}x{normal.shape[0]}、ORM {orm.shape[1]}x{orm.shape[0]}')
    print(f'來源平均：顏色 {means(color, "RGB")}；法線 {means(normal, "RGB")}；ORM 的 G（粗糙度）{orm[..., 1].mean():.3f}')

    d = shrink(color, args.size)
    d[..., 3] = 1.0
    save(d_path, d, alpha=False)

    vec = shrink(normal[..., :3] * 2.0 - 1.0, args.size)
    vec /= np.maximum(np.linalg.norm(vec, axis=-1, keepdims=True), 1e-6)
    n = np.empty((args.size, args.size, 4), dtype=np.float32)
    n[..., :3] = vec * 0.5 + 0.5
    n[..., 3] = shrink(orm, args.size)[..., 1]
    save(n_path, n, alpha=True)

    print('\n## 輸出（存完讀回來）')
    for path, channels in ((d_path, 'RGB'), (n_path, 'RGBA')):
        back = load(path)
        print(f'{path}：{png_kind(path)}；平均 {means(back, channels)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
