"""在 Blender 背景模式用 REDkit 的 Blender 外掛匯入、匯出 .re（docs/m3.md「Blender 外掛」）。

用法：
- 直接執行：來回測試（匯入、什麼都不改、匯出、修補、和原檔比對）
    PIP_NO_INDEX=1 PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
    "D:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --factory-startup --background
        --python-exit-code 1 --python tools/re_blender.py -- 原檔.re 輸出.re
- 當模組（改動畫的腳本用）：
    sys.path.insert(0, r'D:\\OneDrive\\Desktop\\gunforgeralt\\tools'); import re_blender
    obj, info = re_blender.import_re(Path('原檔.re'))
    ...（改 obj 的姿勢，每一格都要插關鍵格）...
    re_blender.export_re(obj, info, Path('輸出.re'))

- 外掛：tools/_vendor/blender_re_animations_plugin（REDkit 附的 zip 解壓；不進 git）；h5py 在 tools/_vendor/pylib
- 載入外掛前先放替身模組 pocketsphinx、audioop：外掛的對嘴功能 import 它們，缺了會自己 pip install 到 AppData
  （外掛 phoneme_extractor.py:8-19、install_dependecies.py:9-24；2026-10-15 發生過）；上面的 PIP_* 環境變數是第二道防線
- 外掛匯入的骨架：位置是原檔的公分 × 0.01、物件縮放 10；Root 的動畫不套用（import_anims.py:306-321、:239）
- 外掛匯入時把場景的結束格設成「格數」（多 1 格：import_anims.py:200-201），匯出用場景的格數（export_anims.py:219）
  → export_re 先把結束格設回「格數 − 1」；匯出的長度（秒）用原檔的 .animlength
- 外掛的匯出會改掉部分骨頭的位置、Root → export_re 匯出後用 re_fix 就地修補，再列出和原檔不同的骨頭
- Blender 內建的 Python 預設不讀 PYTHONUTF8 等環境變數，所以在腳本裡把輸出改成 UTF-8
"""
import sys
import types
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
PLUGIN = 'blender_re_animations_plugin'
H5_ANIM = '.re_asset_node/.re_animation_container/.re_animation'

_loaded = False


def load_plugin() -> None:
    """載入外掛（只做一次）。"""
    global _loaded
    if _loaded:
        return
    sys.dont_write_bytecode = True
    for p in (TOOLS, TOOLS / '_vendor' / 'pylib', TOOLS / '_vendor'):
        if str(p) not in sys.path:
            sys.path.insert(0, str(p))
    pocketsphinx = types.ModuleType('pocketsphinx')
    pocketsphinx.AudioFile = object
    pocketsphinx.get_model_path = lambda *a, **k: ''
    sys.modules.setdefault('pocketsphinx', pocketsphinx)
    sys.modules.setdefault('audioop', types.ModuleType('audioop'))
    import addon_utils
    if addon_utils.enable(PLUGIN, default_set=True, persistent=False) is None:
        raise RuntimeError(f'外掛載入失敗：{TOOLS / "_vendor" / PLUGIN}')
    _loaded = True


def import_re(path: Path):
    """匯入 .re，回傳 (骨架物件, 原檔資訊)。"""
    load_plugin()
    import bpy
    import h5py
    with h5py.File(path, 'r') as f:
        anim = f[H5_ANIM]
        info = {'path': Path(path), 'numkeys': int(anim.attrs['.numkeys']), 'animlength': float(anim.attrs['.animlength'])}
    result = bpy.ops.import_animset.re('EXEC_DEFAULT', filepath=str(path))
    if result != {'FINISHED'}:
        raise RuntimeError(f'匯入失敗：{result}')
    obj = bpy.data.objects[Path(path).stem]
    print(f'匯入：{path}（{len(obj.data.bones)} 根骨頭、{info["numkeys"]} 格、{info["animlength"]:.4f} 秒）')
    return obj, info


def export_re(obj, info: dict, out_path: Path, report_deg: float = 0.01) -> None:
    """匯出 .re，用 re_fix 就地修補，再和原檔比對。"""
    import bpy
    import re_fix
    scene = bpy.context.scene
    scene.frame_start = 0
    scene.frame_end = info['numkeys'] - 1
    if bpy.context.view_layer.objects.active and bpy.context.view_layer.objects.active.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    result = bpy.ops.export_animset.re('EXEC_DEFAULT', filepath=str(out_path), anim_length=info['animlength'])
    if result != {'FINISHED'} or not out_path.is_file():
        raise RuntimeError(f'匯出失敗：{result}（{out_path}）')
    moved = re_fix.fix(out_path, info['path'], out_path)
    print(f'已存：{out_path}（外掛匯出後已修補）')
    re_fix.report(out_path, info['path'], moved, report_deg)


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    if len(argv) != 2:
        print('用法：blender --factory-startup --background --python-exit-code 1 --python tools/re_blender.py -- 原檔.re 輸出.re')
        return 2
    src, dst = Path(argv[0]), Path(argv[1])
    if not src.is_file():
        print(f'找不到檔案：{src}')
        return 2
    obj, info = import_re(src)
    export_re(obj, info, dst)
    return 0


if __name__ == '__main__':
    sys.exit(main())
