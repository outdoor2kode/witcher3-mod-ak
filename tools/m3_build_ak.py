"""M3 第 3 步：把 CS2 的 AK 轉到十字弩的方向、握把放到十字弩的原點、綁到十字弩骨架，
存成 .blend（目視用）和 .fbx（匯入 REDkit 用）。

用法：
    "D:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --factory-startup --background
        --python-exit-code 1 --python tools/m3_build_ak.py --
        AK.gltf 十字弩.fbx 十字弩.w2mesh 輸出資料夾 [--scale 1.0] [--up -X] [--offset X Y Z] [--pitch 0]
        [--place GX GY GZ FX FY FZ UX UY UZ]

- 只讀三個來源檔；輸出 gfg_ak47_m3.blend、gfg_ak47.fbx 到輸出資料夾（沒有就建立）
  - 十字弩.w2mesh：uncook depot 的原版 witcher_crossbow_lvl1.w2mesh，只讀 handle 的綁定矩陣
- AK：只留 body_hd（已含彈匣：綁在 clip 骨頭上的 5,246 個頂點），用匯入後的原始頂點
  - 檔案裡的頂點就是 CS2 的預設姿勢：每根骨頭「節點 × 反綁定」都是單位矩陣（docs/m3.md）
  - Blender 匯入後，CS2 骨架的姿勢會把模型整體移動，所以不套用 CS2 的骨架
- 十字弩：FBX 照 Wiki 的設定匯入（Primary X、Secondary Y），留骨架 Root（8 根骨頭）
- 以下座標都是 Blender 的世界座標（Z 往上、公尺）
- 方向：AK 的前方 -Y 轉到十字弩的前方 +Z；AK 的上方 +Z 轉到 --up（預設 -X）
  - 十字弩的前方 +Z：弓臂在那頭（骨頭位置）
  - 十字弩的上方 -X：遊戲截圖裡前端的方形環、淺色木板在下面，它們在 +X 那面；
    骨頭 r_wing（右翼）在 -Y，上方 -X 時右手邊正好是 -Y（docs/m3.md）
- --pitch：AK 繞握把再轉幾度（轉軸是十字弩的左右方向；正＝槍口往上）
  - -20.5：槍管和原版十字弩的箭平行。箭沿 chord 骨頭的 x 軸（模板 slot 的 Yaw -90），比 handle 的 x 軸低 20.4°（docs/m3.md）
- 位置：AK 的 ag1_hand_r（CS2 右手握把的骨頭）放到十字弩的原點，再加 --offset（公尺）
- --place（雙手持槍用；有填時取代 --up、--pitch、--offset）：握把位置 G、槍管方向 F、上方 U 各 3 個數字，
  用十字弩模型座標（REDkit，公尺）＝ Geralt 的 l_weapon 骨頭座標（slot l_weapon 沒有位移；docs/m3.md「Calc bone 的結果」）
  - 骨架區域座標（公分）＝ 十字弩模型座標 × 100；U 先扣掉 F 方向的分量再正規化
- .blend：AK 當 Root 的子物件、所有頂點 100% 綁 handle（目視用）；另外放十字弩模型和原點標記（集合 reference）
- 法線：先讀出原本的法線，轉換後再照同一個旋轉設回去，最後檢查和面的方向一致
- 匯出 FBX：**不帶骨架**，只有一個叫 handle 的模型，頂點換到 handle 骨頭的座標系（docs/m3.md）
  - 原因：REDkit 匯入 Blender 做的蒙皮 FBX 時，不用 FBX 的骨頭群組，而是用 NODE 模式
    （editor.log「HasSkinning: true (NODE '模型名稱')」）：整個模型綁在一根「和模型節點同名」的骨頭上、綁定矩陣是單位矩陣；
    照 Wiki 的設定和照 REDkit 匯出格式的設定都試過，結果一樣
  - → 模型節點取名 handle（骨頭名稱就是 handle，對得上十字弩骨架）；頂點先乘上原版十字弩模型裡 handle 的綁定矩陣，
    遊戲套上 handle 骨頭的位置時剛好回到十字弩模型的座標
  - Up = Z、Forward = -Y：和 REDkit 匯出的十字弩 FBX 同樣的座標系，模型節點是單位變換；Smoothing = Normals Only、Apply Modifiers 照 Wiki
  - 不匯出動畫（bake_anim = False）
- 匯出後解析 FBX：節點名稱、沒有蒙皮、頂點換回十字弩模型座標後和匯出前比對
- Blender 內建的 Python 預設不讀 PYTHONUTF8 等環境變數，所以在腳本裡把輸出改成 UTF-8
"""
import argparse
import math
import struct
import sys
from pathlib import Path

import bpy
from io_scene_fbx import parse_fbx
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cr2w_dump import Cr2wFile  # noqa: E402

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
    p.add_argument('rig_mesh', type=Path, help='uncook depot 的原版 witcher_crossbow_lvl1.w2mesh（讀 handle 的綁定矩陣）')
    p.add_argument('out_dir', type=Path, help='輸出資料夾')
    p.add_argument('--scale', type=float, default=1.0, help='AK 的縮放（預設 1.0 = 原尺寸）')
    p.add_argument('--up', choices=sorted(UP_CHOICES), default='-X', help='AK 的上方要轉到哪個軸（預設 -X）')
    p.add_argument('--offset', type=float, nargs=3, default=(0.0, 0.0, 0.0), metavar=('X', 'Y', 'Z'),
                   help='握把對到原點之後再移動多少（公尺）')
    p.add_argument('--pitch', type=float, default=0.0,
                   help='AK 繞握把再轉幾度，正＝槍口往上（預設 0；-20.5 讓槍管和原版十字弩的箭平行）')
    p.add_argument('--place', type=float, nargs=9, metavar=('GX', 'GY', 'GZ', 'FX', 'FY', 'FZ', 'UX', 'UY', 'UZ'),
                   help='握把位置、槍管方向、上方（l_weapon 骨頭座標，公尺）；有填時取代 --up、--pitch、--offset')
    return p.parse_args(argv)


def vec(v) -> str:
    return '(' + ', '.join(f'{x:.4f}' for x in v) + ')'


def frame(forward: Vector, up: Vector) -> Matrix:
    # 三個欄：前、上、前×上（右手座標）
    return Matrix((forward, up, forward.cross(up))).transposed()


def pitched(forward: Vector, up: Vector, deg: float) -> tuple[Vector, Vector]:
    # 前、上兩軸繞左右方向轉 deg 度，正＝前方往上抬
    a = math.radians(deg)
    return forward * math.cos(a) + up * math.sin(a), up * math.cos(a) - forward * math.sin(a)


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

    if args.place:
        g, f, u = (Vector(args.place[i:i + 3]) for i in (0, 3, 6))
        f.normalize()
        u = (u - f * f.dot(u)).normalized()
        rot = frame(f, u) @ frame(AK_FORWARD, AK_UP).transposed()
        # 直接放到十字弩骨架的區域座標（公分）
        m_local = (Matrix.Scale(100, 4) @ Matrix.Translation(g) @ Matrix.Scale(args.scale, 4)
                   @ rot.to_4x4() @ Matrix.Translation(-grip))
        forward = (root.matrix_world.to_3x3() @ f).normalized()  # 世界座標的槍管方向（找槍口用）
    else:
        forward, up = pitched(XBOW_FORWARD, UP_CHOICES[args.up], args.pitch)
        rot = frame(forward, up) @ frame(AK_FORWARD, AK_UP).transposed()
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
    if args.place:
        print(f'縮放 {args.scale}；--place 握把 {vec(args.place[0:3])}、前方 {vec(args.place[3:6])}、上方 {vec(args.place[6:9])}')
    else:
        print(f'縮放 {args.scale}；上方 {args.up}；位移 {vec(args.offset)}；轉 {args.pitch}°')
    print(f'法線和面同一側的比例：轉換前 {agree_before:.4f}，轉換後 {agree_after:.4f}')
    return root, body, forward


def report_positions(root, body, forward: Vector, rig: Matrix) -> dict:
    pts = world_points(body)
    lo, hi = bbox(pts)
    # 槍口：沿槍管方向最前面 5 公釐內的頂點平均
    front = max(p.dot(forward) for p in pts)
    tip = [p for p in pts if p.dot(forward) > front - 0.005]
    muzzle = sum(tip, Vector()) / len(tip)
    to_local = root.matrix_world.inverted()
    # handle 骨頭座標（= 匯出的 FBX、.w2mesh 的頂點座標，公尺）：骨架區域座標（公分）→ 公尺 → 乘綁定矩陣
    to_bone = rig @ Matrix.Scale(0.01, 4) @ to_local
    bone_dir = (to_bone.to_3x3() @ forward).normalized()
    print(f'外框（公尺）最小 {vec(lo)}  最大 {vec(hi)}  尺寸 {vec(hi - lo)}')
    print(f'槍口（沿槍管最前面 5 公釐的頂點平均，{len(tip)} 個）：世界 {vec(muzzle)}；骨架區域座標（公分）{vec(to_local @ muzzle)}')
    print(f'handle 骨頭座標（公尺）：槍口 {vec(to_bone @ muzzle)}；槍管方向 {vec(bone_dir)}，'
          f'仰角 {math.degrees(math.atan2(bone_dir.z, bone_dir.x)):.2f}°')
    heads = {b.name: root.matrix_world @ b.head_local for b in root.data.bones}
    for name in (BIND_BONE, 'chord'):
        print(f'骨頭 {name} 的頭：世界 {vec(heads[name])}')
    return {'lo': lo, 'hi': hi, 'heads': heads}


def read_rig_matrices(path: Path) -> dict[str, Matrix]:
    """讀 .w2mesh 的骨頭名稱和綁定矩陣，回傳 {骨頭名稱: 矩陣}（欄向量慣例，位移在最後一欄，公尺）。

    在 CMesh 屬性串列之後的自訂資料（docs/m3.md「第一次匯入的模型沒用到骨頭群組」）：
    LOD 數；每個 LOD 的 chunk 數、chunk 編號（u16）、距離（float）；骨頭數、名稱（u16）；矩陣數、矩陣（16 個 float，列向量慣例）
    數量都是 1 byte（只處理小於 64 的值）
    """
    data = path.read_bytes()
    f = Cr2wFile(data)
    exp = f.exports[0]
    end = exp['offset'] + exp['size']
    _props, pos = f.read_props(exp['offset'] + 1, end)
    t = data[pos:end]

    def count(p: int) -> int:
        if t[p] >= 0x40:
            raise ValueError(f'{path.name}：數量 {t[p]:#x} 不是 1 byte 的小數字，格式和預期不同')
        return t[p]

    p = 0
    lods = count(p)
    p += 1
    for _ in range(lods):
        p += 1 + 2 * count(p) + 4
    names = [f.name(struct.unpack_from('<H', t, p + 1 + 2 * i)[0]) for i in range(count(p))]
    p += 1 + 2 * len(names)
    if count(p) != len(names):
        raise ValueError(f'{path.name}：骨頭 {len(names)} 根，矩陣 {count(p)} 個，數量不同')
    p += 1
    mats = {}
    for i, name in enumerate(names):
        v = struct.unpack_from('<16f', t, p + 64 * i)
        mats[name] = Matrix((v[0:4], v[4:8], v[8:12], v[12:16])).transposed()
    return mats


def export_node_fbx(root, body, rig: Matrix, path: Path) -> float:
    """匯出只有一個 handle 模型的 FBX（頂點在 handle 骨頭的座標系），回傳法線和面同一側的比例。"""
    # 模型資料是十字弩模型座標（公分）：換成公尺、乘綁定矩陣、再換回公分
    to_bone = Matrix.Scale(100, 4) @ rig @ Matrix.Scale(0.01, 4)
    me = body.data.copy()
    me.name = BIND_BONE
    normals = [c.vector.copy() for c in me.corner_normals]
    me.transform(to_bone)
    normal_matrix = to_bone.to_3x3().inverted().transposed()
    me.normals_split_custom_set([(normal_matrix @ n).normalized() for n in normals])
    me.update()
    agree = normals_agree(me)
    obj = bpy.data.objects.new(BIND_BONE, me)
    bpy.context.scene.collection.objects.link(obj)
    # 和 AK 一樣用 Root 的世界矩陣：Up Z、Forward -Y 的軸向轉換剛好抵掉，FBX 裡是單位變換
    obj.matrix_world = root.matrix_world.copy()
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(
        filepath=str(path), use_selection=True, object_types={'MESH'},
        axis_up='Z', axis_forward='-Y',
        mesh_smooth_type='OFF', use_mesh_modifiers=True, bake_anim=False)
    bpy.data.objects.remove(obj)
    return agree


def check_node_fbx(path: Path, expected_cm: list[Vector], rig: Matrix) -> None:
    root, _version = parse_fbx.parse(str(path))
    objects = next(e for e in root.elems if e.id == b'Objects')
    models = [(e.props[1].split(b'\x00\x01')[0].decode(), e.props[2].decode()) for e in objects.elems if e.id == b'Model']
    deformers = [e for e in objects.elems if e.id == b'Deformer']
    transforms = {}
    for e in objects.elems:
        if e.id == b'Model':
            for sub in e.elems:
                for p in sub.elems:
                    if p.id == b'P' and p.props[0] in (b'Lcl Translation', b'Lcl Rotation', b'Lcl Scaling'):
                        transforms[p.props[0].decode()] = tuple(round(v, 4) for v in p.props[4:7])
    geom = next(e for e in objects.elems if e.id == b'Geometry')
    raw = next(c for c in geom.elems if c.id == b'Vertices').props[0]
    back = Matrix.Scale(100, 4) @ rig.inverted() @ Matrix.Scale(0.01, 4)
    pts = [back @ Vector(raw[i:i + 3]) for i in range(0, len(raw), 3)]
    lo, hi = bbox(pts)
    elo, ehi = bbox(expected_cm)
    print(f'\n## 解析 {path.name}')
    print(f'模型節點：{models}；變換：{transforms or "（單位）"}；蒙皮元素 {len(deformers)} 個')
    print(f'頂點 {len(pts)} 個；換回十字弩模型座標後，外框和匯出前差 {max((lo - elo).length, (hi - ehi).length):.4f} 公分')


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    args = parse_args()
    for p in (args.ak, args.crossbow, args.rig_mesh):
        if not p.is_file():
            print(f'找不到檔案：{p}')
            return 2
    args.out_dir.mkdir(parents=True, exist_ok=True)
    blend = (args.out_dir / f'{NAME}_m3.blend').resolve()
    fbx = (args.out_dir / f'{NAME}.fbx').resolve()

    root, body, forward = build(args)
    rig = read_rig_matrices(args.rig_mesh)[BIND_BONE]
    report_positions(root, body, forward, rig)
    if args.place:
        print(f'握把在 handle 骨頭座標（公尺）：{vec(rig @ Vector(args.place[0:3]))}')
    head = root.data.bones[BIND_BONE].head_local / 100  # 骨架區域座標，公分 → 公尺
    print(f'\n{args.rig_mesh.name} 的 {BIND_BONE} 綁定矩陣：' + ' | '.join(' '.join(f'{x:.4f}' for x in row) for row in rig))
    print(f'檢查：十字弩 FBX 的 {BIND_BONE} 骨頭位置乘上綁定矩陣 = {vec(rig @ head)}（應該接近 0）')
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    expected_cm = [v.co.copy() for v in body.data.vertices]
    agree = export_node_fbx(root, body, rig, fbx)
    print(f'\n已存：{blend}\n已存：{fbx}（法線和面同一側的比例 {agree:.4f}）')
    check_node_fbx(fbx, expected_cm, rig)
    return 0


if __name__ == '__main__':
    sys.exit(main())
