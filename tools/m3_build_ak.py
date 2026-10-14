"""M3 第 3 步：把 CS2 的 AK 轉到十字弩的方向、握把放到十字弩的原點、綁到十字弩骨架，
存成 .blend（目視用）和 .fbx（匯入 REDkit 用）。

用法：
    "D:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --factory-startup --background
        --python-exit-code 1 --python tools/m3_build_ak.py --
        AK.gltf 十字弩.fbx 輸出資料夾 [--scale 1.0] [--up -X] [--offset X Y Z]

- 只讀兩個來源檔；輸出 gfg_ak47_m3.blend、gfg_ak47.fbx 到輸出資料夾（沒有就建立）
- AK：只留 body_hd（已含彈匣：綁在 clip 骨頭上的 5,246 個頂點），用匯入後的原始頂點
  - 檔案裡的頂點就是 CS2 的預設姿勢：每根骨頭「節點 × 反綁定」都是單位矩陣（docs/m3.md）
  - Blender 匯入後，CS2 骨架的姿勢會把模型整體移動，所以不套用 CS2 的骨架
- 十字弩：FBX 照 Wiki 的設定匯入（Primary X、Secondary Y），留骨架 Root（8 根骨頭）
- 以下座標都是 Blender 的世界座標（Z 往上、公尺）
- 方向：AK 的前方 -Y 轉到十字弩的前方 +Z；AK 的上方 +Z 轉到 --up（預設 -X）
  - 十字弩的前方 +Z：弓臂在那頭（骨頭位置）
  - 十字弩的上方 -X：遊戲截圖裡前端的方形環、淺色木板在下面，它們在 +X 那面；
    骨頭 r_wing（右翼）在 -Y，上方 -X 時右手邊正好是 -Y（docs/m3.md）
- 位置：AK 的 ag1_hand_r（CS2 右手握把的骨頭）放到十字弩的原點，再加 --offset（公尺）
- 綁定：所有頂點 100% 綁 handle；和十字弩模型一樣當 Root 的子物件，相對變換是單位矩陣
- 法線：先讀出原本的法線，轉換後再照同一個旋轉設回去，最後檢查和面的方向一致
- 匯出 FBX 照 Wiki：Primary X、Secondary -Y、Armature FBXNode Type = Null、Only Deform Bones、
  不加 Leaf Bones、Smoothing = Normals Only、Apply Modifiers
  （Wiki 頁面 6326771「HOW-TO: Use skinned meshes in Blender」，見 docs/m3.md）
  - Wiki 沒寫的：不匯出動畫（bake_anim = False），只匯出骨架和 AK
- 匯出後用同樣的 Wiki 匯入設定讀回來，比對骨頭和 AK 的位置
- .blend 另外放十字弩模型和原點標記（集合 reference，不匯出）
- Blender 內建的 Python 預設不讀 PYTHONUTF8 等環境變數，所以在腳本裡把輸出改成 UTF-8
"""
import argparse
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

AK_BODY_SUFFIX = '.body_hd'
GRIP_BONE = 'ag1_hand_r'
BIND_BONE = 'handle'
AK_FORWARD = Vector((0, -1, 0))  # 槍口方向
AK_UP = Vector((0, 0, 1))
XBOW_FORWARD = Vector((0, 0, 1))  # 弓臂那頭
UP_CHOICES = {'+X': Vector((1, 0, 0)), '-X': Vector((-1, 0, 0)), '+Y': Vector((0, 1, 0)), '-Y': Vector((0, -1, 0))}
NAME = 'gfg_ak47'
UV_NAMES = ('DiffuseUV', 'SecondUV')  # 和十字弩匯出的 FBX 一樣


def parse_args() -> argparse.Namespace:
    # blender 會把 "--" 後面的參數留給腳本
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    p = argparse.ArgumentParser(prog='m3_build_ak.py')
    p.add_argument('ak', type=Path, help='CS2 匯出的 weapon_rif_ak47.gltf')
    p.add_argument('crossbow', type=Path, help='REDkit 匯出的 witcher_crossbow_lvl1.fbx')
    p.add_argument('out_dir', type=Path, help='輸出資料夾')
    p.add_argument('--scale', type=float, default=1.0, help='AK 的縮放（預設 1.0 = 原尺寸）')
    p.add_argument('--up', choices=sorted(UP_CHOICES), default='-X', help='AK 的上方要轉到哪個軸（預設 -X）')
    p.add_argument('--offset', type=float, nargs=3, default=(0.0, 0.0, 0.0), metavar=('X', 'Y', 'Z'),
                   help='握把對到原點之後再移動多少（公尺）')
    return p.parse_args(argv)


def vec(v) -> str:
    return '(' + ', '.join(f'{x:.4f}' for x in v) + ')'


def frame(forward: Vector, up: Vector) -> Matrix:
    # 三個欄：前、上、前×上（右手座標）
    return Matrix((forward, up, forward.cross(up))).transposed()


def world_points(obj) -> list[Vector]:
    obj_eval = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = obj_eval.to_mesh()
    try:
        return [obj_eval.matrix_world @ v.co for v in mesh.vertices]
    finally:
        obj_eval.to_mesh_clear()


def bbox(points: list[Vector]) -> tuple[Vector, Vector]:
    return (Vector([min(p[i] for p in points) for i in range(3)]),
            Vector([max(p[i] for p in points) for i in range(3)]))


def normals_agree(mesh) -> float:
    # 和所屬的面同一側的 corner normal 比例
    corner = mesh.corner_normals
    good = sum(1 for poly in mesh.polygons for i in poly.loop_indices if corner[i].vector.dot(poly.normal) > 0)
    return good / len(mesh.loops)


def import_crossbow(path: Path):
    # Wiki：Primary = X、Secondary = Y
    bpy.ops.import_scene.fbx(filepath=str(path), primary_bone_axis='X', secondary_bone_axis='Y')
    root = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    return root, meshes


def import_ak(path: Path):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path), disable_bone_shape=True)
    new = [o for o in bpy.context.scene.objects if o not in before]
    arm = next(o for o in new if o.type == 'ARMATURE')
    body = next(o for o in new if o.type == 'MESH' and o.name.endswith(AK_BODY_SUFFIX))
    grip = arm.matrix_world @ arm.data.bones[GRIP_BONE].head_local
    for o in new:
        if o is not body:
            bpy.data.objects.remove(o)
    return body, grip


def build(args: argparse.Namespace):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    root, xbow_meshes = import_crossbow(args.crossbow)
    body, grip = import_ak(args.ak)
    print(f'十字弩骨架 {root.name}：{len(root.data.bones)} 根骨頭；AK 握把 {GRIP_BONE} 在 {vec(grip)}')

    # 原始頂點：拿掉 CS2 骨架的修改器與頂點群組
    body.modifiers.clear()
    body.vertex_groups.clear()
    body.parent = None
    body.matrix_world = Matrix.Identity(4)
    me = body.data
    agree_before = normals_agree(me)
    normals = [c.vector.copy() for c in me.corner_normals]

    up = UP_CHOICES[args.up]
    rot = frame(XBOW_FORWARD, up) @ frame(AK_FORWARD, AK_UP).transposed()
    m_world = (Matrix.Translation(Vector(args.offset)) @ Matrix.Scale(args.scale, 4)
               @ rot.to_4x4() @ Matrix.Translation(-grip))
    m_local = root.matrix_world.inverted() @ m_world  # 換成十字弩骨架的區域座標（公分）
    me.transform(m_local)
    normal_matrix = m_local.to_3x3().inverted().transposed()
    me.normals_split_custom_set([(normal_matrix @ n).normalized() for n in normals])
    me.update()
    agree_after = normals_agree(me)

    body.parent = root
    body.matrix_parent_inverse = Matrix.Identity(4)
    body.matrix_basis = Matrix.Identity(4)
    body.name = me.name = NAME
    for uv, name in zip(me.uv_layers, UV_NAMES):
        uv.name = name
    group = body.vertex_groups.new(name=BIND_BONE)
    group.add(range(len(me.vertices)), 1.0, 'REPLACE')
    mod = body.modifiers.new(name='Armature', type='ARMATURE')
    mod.object = root

    # 十字弩模型當參考；碰撞模型不要
    ref = bpy.data.collections.new('reference')
    bpy.context.scene.collection.children.link(ref)
    for o in xbow_meshes:
        if o.parent is root:
            for c in o.users_collection:
                c.objects.unlink(o)
            ref.objects.link(o)
            o.parent = None  # 不跟著骨架匯出；位置不變（骨架是靜止姿勢，拿掉修改器形狀不變）
            o.matrix_world = root.matrix_world.copy()
            o.modifiers.clear()
        else:
            bpy.data.objects.remove(o)
    marker = bpy.data.objects.new('grip_point', None)
    marker.empty_display_type = 'PLAIN_AXES'
    marker.empty_display_size = 0.05
    ref.objects.link(marker)

    print(f'\n## AK（{body.name}）')
    print(f'頂點 {len(me.vertices)}、面 {len(me.polygons)}；材質：{", ".join(s.material.name for s in body.material_slots)}')
    print(f'UV：{", ".join(uv.name for uv in me.uv_layers)}；頂點群組：{", ".join(g.name for g in body.vertex_groups)}')
    print(f'縮放 {args.scale}；上方 {args.up}；位移 {vec(args.offset)}')
    print(f'法線和面同一側的比例：轉換前 {agree_before:.4f}，轉換後 {agree_after:.4f}')
    return root, body


def report_positions(root, body) -> dict:
    pts = world_points(body)
    lo, hi = bbox(pts)
    # 槍口：最前面 5 公釐內的頂點平均
    front = max(p.z for p in pts)
    tip = [p for p in pts if p.z > front - 0.005]
    muzzle = sum(tip, Vector()) / len(tip)
    to_local = root.matrix_world.inverted()
    print(f'外框（公尺）最小 {vec(lo)}  最大 {vec(hi)}  尺寸 {vec(hi - lo)}')
    print(f'槍口（最前面 5 公釐的頂點平均，{len(tip)} 個）：世界 {vec(muzzle)}；骨架區域座標（公分）{vec(to_local @ muzzle)}')
    heads = {b.name: root.matrix_world @ b.head_local for b in root.data.bones}
    for name in (BIND_BONE, 'chord'):
        print(f'骨頭 {name} 的頭：世界 {vec(heads[name])}')
    return {'lo': lo, 'hi': hi, 'heads': heads}


def export_fbx(root, body, path: Path) -> None:
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    body.select_set(True)
    bpy.context.view_layer.objects.active = root
    # Wiki：Primary X、Secondary -Y、Null、Only Deform Bones、不加 Leaf Bones、Normals Only、Apply Modifiers
    bpy.ops.export_scene.fbx(
        filepath=str(path), use_selection=True, object_types={'ARMATURE', 'MESH'},
        primary_bone_axis='X', secondary_bone_axis='-Y', armature_nodetype='NULL',
        use_armature_deform_only=True, add_leaf_bones=False,
        mesh_smooth_type='OFF', use_mesh_modifiers=True, bake_anim=False)


def check_roundtrip(path: Path, expected: dict) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    root, meshes = import_crossbow(path)
    body = next(o for o in meshes if o.name == NAME)
    lo, hi = bbox(world_points(body))
    diff_box = max((lo - expected['lo']).length, (hi - expected['hi']).length)
    diff_bone = max((root.matrix_world @ b.head_local - expected['heads'][b.name]).length for b in root.data.bones)
    print(f'\n## 讀回 {path.name}')
    print(f'骨架 {root.name}：{len(root.data.bones)} 根骨頭（{", ".join(b.name for b in root.data.bones)}）')
    print(f'AK 頂點 {len(body.data.vertices)}；頂點群組：{", ".join(g.name for g in body.vertex_groups)}')
    print(f'和匯出前的差距（公尺）：外框 {diff_box:.6f}、骨頭位置 {diff_bone:.6f}')


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    args = parse_args()
    for p in (args.ak, args.crossbow):
        if not p.is_file():
            print(f'找不到檔案：{p}')
            return 2
    args.out_dir.mkdir(parents=True, exist_ok=True)
    blend = (args.out_dir / f'{NAME}_m3.blend').resolve()
    fbx = (args.out_dir / f'{NAME}.fbx').resolve()

    root, body = build(args)
    expected = report_positions(root, body)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    export_fbx(root, body, fbx)
    print(f'\n已存：{blend}\n已存：{fbx}')
    check_roundtrip(fbx, expected)
    return 0


if __name__ == '__main__':
    sys.exit(main())
