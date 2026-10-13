"""在 Blender 背景模式匯入模型，印出大小、方向、骨頭位置、材質（只讀，不存任何檔案）。

用法：
    "D:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --factory-startup --background
        --python-exit-code 1 --python tools/m3_inspect.py -- 模型檔 [模型檔 ...]

- 支援 .gltf／.glb（CS2：Source 2 Viewer 的 Decompile & Export）與 .fbx（REDkit：Export Asset）
- 每個檔案各自在空場景匯入，互不影響；不存 .blend，也不改模型檔
- FBX 匯入照 Wiki 的設定：Primary Bone Axis = X、Secondary Bone Axis = Y
  （Wiki 頁面 6326771「HOW-TO: Use skinned meshes in Blender」，見 docs/m3.md）
- 數字都是 Blender 的世界座標（Z 往上）；單位是 Blender 單位，場景的單位設定會一起印出
- 外框用套用修改器後的頂點計算，蒙皮模型照骨架的靜止姿勢
- 輸出：
  - 物件：類型、父物件／父骨頭、位置、旋轉（度）、縮放、外框（最小值、最大值、尺寸、最長的軸）
  - 模型：頂點數、面數、頂點群組、修改器、材質
  - 骨架：每根骨頭的父骨頭、長度、頭尾位置、三個軸的方向
  - 材質：每個貼圖節點的圖檔，以及它接到哪個節點的哪個輸入；最後列出所有圖檔
- Blender 內建的 Python 預設不讀 PYTHONUTF8 等環境變數，所以在腳本裡把輸出改成 UTF-8
"""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def script_args() -> list[str]:
    # blender 會把 "--" 後面的參數留給腳本
    return sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []


def vec(v) -> str:
    return '(' + ', '.join(f'{x:.4f}' for x in v) + ')'


def import_model(path: Path) -> None:
    ext = path.suffix.lower()
    if ext in ('.gltf', '.glb'):
        # 不建骨頭的顯示用形狀：匯入器預設會多建一個 Icosphere（放在 glTF_not_exported 集合），會混進外框
        bpy.ops.import_scene.gltf(filepath=str(path), disable_bone_shape=True)
    elif ext == '.fbx':
        # REDkit 匯出的 FBX：Primary = X、Secondary = Y（Wiki 頁面 6326771）
        bpy.ops.import_scene.fbx(filepath=str(path), primary_bone_axis='X', secondary_bone_axis='Y')
    else:
        raise ValueError(f'不支援的副檔名：{path}')


def mesh_world_points(obj, depsgraph) -> list[Vector]:
    obj_eval = obj.evaluated_get(depsgraph)
    mesh = obj_eval.to_mesh()
    try:
        return [obj_eval.matrix_world @ v.co for v in mesh.vertices]
    finally:
        obj_eval.to_mesh_clear()


def bbox_text(points: list[Vector]) -> str:
    lo = Vector([min(p[i] for p in points) for i in range(3)])
    hi = Vector([max(p[i] for p in points) for i in range(3)])
    size = hi - lo
    longest = 'XYZ'[max(range(3), key=lambda i: size[i])]
    return f'最小 {vec(lo)}  最大 {vec(hi)}  尺寸 {vec(size)}  最長的軸 {longest}'


def report_objects(depsgraph) -> list[Vector]:
    all_points = []
    print('\n## 物件')
    for obj in sorted(bpy.context.scene.objects, key=lambda o: o.name):
        parent = obj.parent.name if obj.parent else '-'
        if obj.parent_bone:
            parent += f' / 骨頭 {obj.parent_bone}'
        rot = [math.degrees(a) for a in obj.matrix_world.to_euler()]
        print(f'- {obj.name}（{obj.type}）父：{parent}')
        print(f'  位置 {vec(obj.matrix_world.translation)}  旋轉（度）{vec(rot)}  縮放 {vec(obj.matrix_world.to_scale())}')
        if obj.type != 'MESH':
            continue
        points = mesh_world_points(obj, depsgraph)
        all_points += points
        if points:
            print(f'  外框 {bbox_text(points)}')
        print(f'  頂點 {len(obj.data.vertices)}、面 {len(obj.data.polygons)}')
        if obj.vertex_groups:
            print(f'  頂點群組：{", ".join(g.name for g in obj.vertex_groups)}')
        for mod in obj.modifiers:
            target = getattr(mod, 'object', None)
            print(f'  修改器：{mod.type}' + (f' → {target.name}' if target else ''))
        mats = [s.material.name for s in obj.material_slots if s.material]
        if mats:
            print(f'  材質：{", ".join(mats)}')
    return all_points


def report_armatures() -> None:
    for obj in bpy.context.scene.objects:
        if obj.type != 'ARMATURE':
            continue
        print(f'\n## 骨架 {obj.name}（{len(obj.data.bones)} 根骨頭）')
        for bone in obj.data.bones:
            axes = (obj.matrix_world @ bone.matrix_local).to_3x3()
            parent = bone.parent.name if bone.parent else '-'
            print(f'- {bone.name}（父：{parent}）長度 {bone.length:.4f}')
            print(f'  頭 {vec(obj.matrix_world @ bone.head_local)}  尾 {vec(obj.matrix_world @ bone.tail_local)}')
            print(f'  X 軸 {vec(axes.col[0].normalized())}  Y 軸 {vec(axes.col[1].normalized())}  Z 軸 {vec(axes.col[2].normalized())}')


def report_materials() -> None:
    print('\n## 材質')
    for mat in bpy.data.materials:
        users = [o.name for o in bpy.data.objects if any(s.material == mat for s in o.material_slots)]
        print(f'- {mat.name}（使用的物件：{", ".join(users) or "-"}）')
        if not mat.node_tree:
            continue
        for node in mat.node_tree.nodes:
            if node.type != 'TEX_IMAGE':
                continue
            img = node.image
            name = img.name if img else '（沒有圖）'
            targets = [f'{link.to_node.name}.{link.to_socket.name}' for out in node.outputs for link in out.links]
            print(f'  貼圖 {name}  接到：{", ".join(targets) or "-"}')
    print('\n## 圖檔')
    for img in bpy.data.images:
        path = bpy.path.abspath(img.filepath) if img.filepath else '-'
        print(f'- {img.name}  {img.size[0]}x{img.size[1]}  {img.colorspace_settings.name}  檔案 {path}')


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    files = [Path(a) for a in script_args()]
    if not files:
        print('用法：blender --factory-startup --background --python tools/m3_inspect.py -- 模型檔 [模型檔 ...]')
        return 2
    missing = [p for p in files if not p.is_file()]
    if missing:
        for p in missing:
            print(f'找不到檔案：{p}')
        return 2
    for path in files:
        # 每個檔案用空場景，避免名稱和外框互相混到
        bpy.ops.wm.read_factory_settings(use_empty=True)
        print(f'\n===== {path}')
        import_model(path)
        units = bpy.context.scene.unit_settings
        print(f'Blender {bpy.app.version_string}；場景單位：{units.system}，scale_length = {units.scale_length}')
        points = report_objects(bpy.context.evaluated_depsgraph_get())
        if points:
            print(f'\n## 所有模型合起來的外框\n{bbox_text(points)}')
        report_armatures()
        report_materials()
    return 0


if __name__ == '__main__':
    sys.exit(main())
