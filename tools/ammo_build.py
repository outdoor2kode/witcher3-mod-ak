"""第 27 項：AK 的子彈（2026-10-18）。CS2 的 ak47_bullet（整顆子彈）→ 物品圖示、射出去的彈頭模型、彈頭的貼圖。

用法：
    "D:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --factory-startup --background
        --python-exit-code 1 --python tools/ammo_build.py --
        ak47_bullet.gltf 顏色.png 圖示.png 輸出資料夾 [--preview 大圖.png] [--samples 64] [--count 1] [--pitch 8]
        [--tilt 25] [--shadow 0.6] [--margin 0.1]

- 來源：Source 2 Viewer 匯出的 weapons/models/shared/shells/ak47/ak47_bullet.gltf、ak47_bullet_color.png（docs/handoff.md「#27 查到的」）
  - Blender 匯入後（公尺）：長軸 Y，尖在 -Y（-0.0418）、底在 +Y（0.0213）；7 塊互不相連的頂點
  - 彈頭 = 有尖端的那一塊（59 個頂點，Y -0.0418～-0.0233、半徑 3.4 公釐）；其他是彈殼（外面、內壁、底）
- 圖示（第 3 個參數）：--count 顆子彈並排、尖朝上，整組在畫面上往右斜 --tilt 度；正交鏡頭往下看 --pitch 度；Cycles、透明背景
  - 先渲染 8 倍大（512×1024），再在線性空間、預乘 alpha 平均每 8×8 → 64×128（同原版箭的圖示 bodkin_bolt_64x128.png）
  - 第 28 項（2026-10-19，使用者：「一顆子彈就夠，然後不要死死的垂直呈現」）：預設改成 1 顆、往右斜 25°（同原版魚叉箭
    harpoon_bolt_64x128.png 尖朝右上）；--shadow：子彈後面加一圈往右下偏的柔和暗影（不透明度；原版箭的圖示也有暗邊）；
    --margin：上下左右留白（比例）；舊的 3 顆直立 = --count 3 --tilt 0 --shadow 0 --margin 0.04
  - 打光：Blender 內建的環境圖 studiolights/world/studio.exr；色彩轉換 Standard（不用預設的 AgX）
- 輸出資料夾：
  - gfg_ak47_bullet.fbx：彈頭模型，REDkit 的模型座標（公尺，長軸 +Y、尖朝 +Y、底在原點、Z 朝上）
    - 同原版箭 witcher_bolt_01.w2mesh 的方向：Y 0～0.308、原點在箭尾（docs/m3.md）
    - 底部原本是開口（在彈殼裡看不到）→ 補一面封起來：從正後方看才不會整顆不見（背面不畫）
    - 平滑著色，封口的邊是硬邊
    - 匯出照 tools/m3_build_ak.py：物件的世界矩陣 = 縮放 0.01 × 繞 Z 轉 -180°、模型資料用公分、Up Z、Forward -Y
      → FBX 裡模型節點是單位變換，頂點 = REDkit 座標 × 100（公分）；REDkit 匯入時換成公尺（docs/m3.md「第 3 步」）
    - 名稱：模型、材質都叫 gfg_ak47_bullet（材質 XML assets/ak47/gfg_ak47_bullet.xml 用同名）；UV 叫 DiffuseUV
    - 匯出後解析 FBX：節點的變換、頂點的外框（公分）
  - gfg_ak47_bullet_d01.png：顏色圖存成 RGB（pbr_std 會把 Diffuse 的 alpha 當 Mask：tools/m3_textures.py）
- 只讀來源檔
- Blender 內建的 Python 預設不讀 PYTHONUTF8 等環境變數，所以在腳本裡把輸出改成 UTF-8
"""
import argparse
import math
import sys
import tempfile
from pathlib import Path

import bmesh
import bpy
import numpy as np
from io_scene_fbx import parse_fbx
from mathutils import Matrix, Vector

NAME = 'gfg_ak47_bullet'
ICON_W, ICON_H, SS = 64, 128, 8  # 圖示大小、超取樣倍數
SPACING = 1.15  # 圖示裡子彈的間距（直徑的倍數）


def parse_args():
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    p = argparse.ArgumentParser(prog='ammo_build.py')
    p.add_argument('gltf', type=Path)
    p.add_argument('color', type=Path)
    p.add_argument('icon', type=Path)
    p.add_argument('out_dir', type=Path)
    p.add_argument('--preview', type=Path, help='另外存渲染的原尺寸大圖（目視用）')
    p.add_argument('--samples', type=int, default=64)
    p.add_argument('--count', type=int, default=1)
    p.add_argument('--pitch', type=float, default=8.0, help='鏡頭往下看幾度')
    p.add_argument('--tilt', type=float, default=25.0, help='畫面上往右斜幾度（尖朝右上）')
    p.add_argument('--shadow', type=float, default=0.6, help='暗影的不透明度（0 = 不加）')
    p.add_argument('--margin', type=float, default=0.22, help='上下左右留白（比例）')
    # 第 36 項（2026-10-19，使用者：「子彈在物品欄裝備時的圖示還是太滿太大沒有質感。沒有專業殺手或者說專家的感覺」）：
    # 材質、打光的選項；預設＝第 36 項選定的（黃銅彈殼＋銅彈頭、暗一點的環境＋主光＋輪廓光、留白 22%）
    # 第 28 項的樣子：--margin 0.1 --style cs2 --env-strength 1 --key 0 --rim 0
    p.add_argument('--style', choices=('cs2', 'brass', 'steel'), default='brass',
                   help='cs2：CS2 的貼圖；brass：黃銅彈殼＋銅彈頭；steel：深色鋼殼＋銅彈頭（金屬，保留 CS2 的法線貼圖）')
    p.add_argument('--rough', type=float, nargs=2, default=(0.18, 0.25), metavar=('彈殼', '彈頭'), help='brass、steel 的粗糙度')
    p.add_argument('--env', default='studio.exr', help='Blender 內建的環境圖（datafiles/studiolights/world）')
    p.add_argument('--env-strength', type=float, default=0.5)
    p.add_argument('--view', default='Standard', help='色彩轉換（Standard、AgX…）')
    p.add_argument('--look', default='None', help='色彩轉換的 look（例：AgX - Punchy）')
    p.add_argument('--key', type=float, default=2.0, help='左上前方面光的強度（W；0 = 不加）')
    p.add_argument('--rim', type=float, default=3.0, help='右後方輪廓光的強度（W；0 = 不加）')
    a = p.parse_args(argv)
    # Blender 的相對路徑是相對於 .blend 檔 → 一律換成絕對路徑
    for k in ('gltf', 'color', 'icon', 'out_dir', 'preview'):
        if getattr(a, k) is not None:
            setattr(a, k, getattr(a, k).resolve())
    return a


def import_bullet(path: Path) -> bpy.types.Object:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    if len(meshes) != 1:
        raise SystemExit(f'{path.name}：預期 1 個模型，實際 {len(meshes)} 個')
    return meshes[0]


def world_points(obj) -> list[Vector]:
    return [obj.matrix_world @ v.co for v in obj.data.vertices]


def bbox(points):
    lo = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    hi = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return lo, hi


def fmt(v) -> str:
    return '(' + ', '.join(f'{x:+.4f}' for x in v) + ')'


def check_source(obj) -> tuple[Vector, Vector]:
    """確認長軸是 Y、尖在 -Y（尖端附近比底部細）；回傳外框。"""
    pts = world_points(obj)
    lo, hi = bbox(pts)
    size = hi - lo
    if not (size.y > 4 * size.x and size.y > 4 * size.z):
        raise SystemExit(f'長軸不是 Y：外框大小 {fmt(size)}')
    near = 0.1 * size.y

    def radius(sel):
        return max(math.hypot(p.x, p.z) for p in sel)
    r_tip = radius([p for p in pts if p.y < lo.y + near])
    r_base = radius([p for p in pts if p.y > hi.y - near])
    if not r_tip < 0.7 * r_base:
        raise SystemExit(f'尖端不在 -Y：-Y 端半徑 {r_tip:.4f}、+Y 端 {r_base:.4f}')
    print(f'來源：頂點 {len(pts)} 個；外框 {fmt(lo)}～{fmt(hi)}；尖端半徑 {r_tip:.4f}、底部 {r_base:.4f}')
    return lo, hi


# ---------- 圖示 ----------

def setup_render(scene, a):
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = a.samples
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = ICON_W * SS
    scene.render.resolution_y = ICON_H * SS
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.color_depth = '8'
    scene.view_settings.view_transform = a.view
    scene.view_settings.look = a.look
    world = bpy.data.worlds.new('gfg_world')
    world.use_nodes = True
    nodes, links = world.node_tree.nodes, world.node_tree.links
    env = nodes.new('ShaderNodeTexEnvironment')
    # system_resource 只找得到資料夾（給檔案路徑會回傳空字串）
    env.image = bpy.data.images.load(str(Path(bpy.utils.system_resource('DATAFILES', path='studiolights/world')) / a.env))
    links.new(env.outputs['Color'], nodes['Background'].inputs['Color'])
    nodes['Background'].inputs['Strength'].default_value = a.env_strength
    scene.world = world
    print(f'打光：環境圖 {a.env} ×{a.env_strength}、色彩轉換 {a.view}／{a.look}、主光 {a.key} W、輪廓光 {a.rim} W')


BRASS = (0.910, 0.778, 0.423)  # 黃銅、銅的 F0（線性；常用的 PBR 參考值）：金屬的底色＝反射的顏色
COPPER = (0.955, 0.638, 0.538)
STEEL = (0.12, 0.13, 0.12)  # 塗漆的鋼殼（深灰綠；自己定的）


def vertex_islands(me) -> list[set]:
    """面相連的頂點分成一塊一塊（同 clean_for_render 的找法）。"""
    parent = list(range(len(me.vertices)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for p in me.polygons:
        r0 = find(p.vertices[0])
        for v in p.vertices[1:]:
            parent[find(v)] = r0
    groups = {}
    for v in me.vertices:
        groups.setdefault(find(v.index), set()).add(v.index)
    return list(groups.values())


def apply_metal(obj, case_color, case_rough: float, head_rough: float) -> None:
    """彈殼（case_color）、彈頭銅：複製匯入的材質（保留法線貼圖），底色、金屬度、粗糙度改成固定值。
    彈頭 = 有尖端（世界座標 Y 最小的頂點）的那塊，同 build_head 的找法。"""
    me = obj.data
    src = me.materials[0]
    mats = []
    for name, color, rough in (('gfg_case', case_color, case_rough), ('gfg_head', COPPER, head_rough)):
        m = src.copy()
        m.name = name
        bsdf = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        for key, value in (('Base Color', (*color, 1.0)), ('Metallic', 1.0), ('Roughness', rough)):
            sock = bsdf.inputs[key]
            for link in list(sock.links):
                m.node_tree.links.remove(link)
            sock.default_value = value
        mats.append(m)
    me.materials.clear()
    for m in mats:
        me.materials.append(m)
    tip = min(me.vertices, key=lambda v: (obj.matrix_world @ v.co).y).index
    head = next(s for s in vertex_islands(me) if tip in s)
    n_head = 0
    for p in me.polygons:
        p.material_index = 1 if p.vertices[0] in head else 0
        n_head += p.material_index
    print(f'材質：彈殼 {case_color}（粗糙度 {case_rough}）＋銅彈頭（{head_rough}）；彈頭 {len(head)} 個頂點、{n_head} 個面')


def add_light(scene, name: str, power: float, pos: Vector, target: Vector, size: float) -> None:
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = power
    data.size = size
    ob = bpy.data.objects.new(name, data)
    scene.collection.objects.link(ob)
    ob.location = pos
    ob.rotation_euler = (target - pos).to_track_quat('-Z', 'Y').to_euler()  # 面光朝自己的 -Z 發光


def clean_for_render(obj) -> None:
    """彈殼有完全重疊的兩份（位置、UV 都一樣），渲染時出現黑色條紋 → 拿掉：
    著色法線和面的方向相反的那塊、位置和前面某塊完全一樣的那塊。模型資料是匯入的複本，不影響彈頭的 FBX。"""
    me = obj.data
    parent = list(range(len(me.vertices)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for p in me.polygons:
        r0 = find(p.vertices[0])
        for v in p.vertices[1:]:
            parent[find(v)] = r0
    groups = {}
    for v in me.vertices:
        groups.setdefault(find(v.index), []).append(v.index)
    cn = me.corner_normals
    seen, drop = set(), []
    for verts in groups.values():
        vs = set(verts)
        polys = [p for p in me.polygons if p.vertices[0] in vs]
        dots = [cn[li].vector.dot(p.normal) for p in polys for li in p.loop_indices]
        mean = sum(dots) / len(dots)
        key = tuple(sorted(tuple(round(c, 5) for c in me.vertices[i].co) for i in verts))
        why = '著色法線朝內' if mean < 0 else ('和前面那塊重疊' if key in seen else '')
        print(f'  一塊：頂點 {len(verts)}、面 {len(polys)}、著色法線和面的方向（內積平均）{mean:+.2f}' + (f' → 拿掉（{why}）' if why else ''))
        if why:
            drop.extend(verts)
        else:
            seen.add(key)
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.verts[i] for i in drop], context='VERTS')
    bm.to_mesh(me)
    bm.free()
    print(f'圖示用的模型：拿掉 {len(drop)} 個頂點，剩 {len(me.vertices)} 個')


def render_icon(obj, lo: Vector, hi: Vector, a) -> None:
    scene = bpy.context.scene
    setup_render(scene, a)
    clean_for_render(obj)
    if a.style != 'cs2':
        apply_metal(obj, BRASS if a.style == 'brass' else STEEL, *a.rough)
    length = hi.y - lo.y
    diameter = max(hi.x - lo.x, hi.z - lo.z)
    # 直立：繞 X 轉 -90°（-Y → +Z），底放在 Z = 0；每顆再繞自己的長軸轉不同角度（貼圖的細節不一樣）
    # 斜放：整組繞 Y（鏡頭的視線）轉 --tilt 度 → +Z 往 +X 倒 = 畫面上往右斜
    upright = Matrix.Rotation(math.radians(-90), 4, 'X')
    base = Matrix.Translation((0, 0, hi.y))
    tilt = Matrix.Rotation(math.radians(a.tilt), 4, 'Y')
    copies = [obj]
    for _ in range(a.count - 1):
        dup = obj.copy()  # 共用模型資料
        scene.collection.objects.link(dup)
        copies.append(dup)
    for i, o in enumerate(copies):
        x = (i - (a.count - 1) / 2) * diameter * SPACING
        spin = Matrix.Rotation(math.radians(360 * i / a.count + 30), 4, 'Z')
        o.matrix_world = tilt @ Matrix.Translation((x, 0, 0)) @ spin @ base @ upright
    bpy.context.view_layer.update()

    cam = bpy.data.objects.new('gfg_camera', bpy.data.cameras.new('gfg_camera'))
    scene.collection.objects.link(cam)
    cam.data.type = 'ORTHO'
    cam.data.clip_start = 0.001
    cam.data.clip_end = 10
    # 鏡頭在前方（-Y）往 +Y 看，稍微往下 pitch 度
    rot = Matrix.Rotation(math.radians(90 - a.pitch), 4, 'X')
    cam_x, cam_y = rot.col[0].xyz, rot.col[1].xyz
    pts = [o.matrix_world @ v.co for o in copies for v in o.data.vertices]
    us = [p.dot(cam_x) for p in pts]
    vs = [p.dot(cam_y) for p in pts]
    u0, u1, v0, v1 = min(us), max(us), min(vs), max(vs)
    center = cam_x * (u0 + u1) / 2 + cam_y * (v0 + v1) / 2
    cam.matrix_world = Matrix.Translation(center + rot.col[2].xyz * 1.0) @ rot  # 鏡頭看 -Z → 放在 +Z 那側
    # 正交鏡頭的 ortho_scale 對應較長的邊（高）；寬是高的一半
    need_h = (v1 - v0) / (1 - 2 * a.margin)
    need_w = (u1 - u0) / (1 - 2 * a.margin)
    cam.data.ortho_scale = max(need_h, need_w * ICON_H / ICON_W)
    scene.camera = cam
    # 光放在子彈長度的幾倍遠（子彈約 6 公分）：主光在鏡頭這側的左上，輪廓光在後面的右上
    reach = 4 * length
    right, up, back = cam_x, cam_y, -rot.col[2].xyz  # 畫面的右、上；離開鏡頭的方向
    if a.key > 0:
        add_light(scene, 'gfg_key', a.key, center + reach * (-0.6 * right + 0.6 * up - 0.5 * back), center, length)
    if a.rim > 0:
        add_light(scene, 'gfg_rim', a.rim, center + reach * (0.7 * right + 0.3 * up + 0.6 * back), center, length * 0.6)
    print(f'圖示：{a.count} 顆、往右斜 {a.tilt}°，長 {length:.4f}、直徑 {diameter:.4f}；畫面上寬 {u1 - u0:.4f}、高 {v1 - v0:.4f}；ortho_scale {cam.data.ortho_scale:.4f}')

    with tempfile.TemporaryDirectory() as tmp:
        big = Path(tmp) / 'big.png'
        scene.render.filepath = str(big)
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(str(big))
        px = np.array(img.pixels[:], dtype=np.float64).reshape(ICON_H * SS, ICON_W * SS, 4)
        if a.preview:
            a.preview.parent.mkdir(parents=True, exist_ok=True)
            img.save(filepath=str(a.preview))
            print(f'大圖：{a.preview}')
        bpy.data.images.remove(img)

    if a.shadow > 0:
        px = add_shadow(px, a.shadow)
    small = downscale(px)
    a.icon.parent.mkdir(parents=True, exist_ok=True)
    out = bpy.data.images.new('gfg_icon', ICON_W, ICON_H, alpha=True)
    out.pixels[:] = small.ravel()
    out.filepath_raw = str(a.icon)
    out.file_format = 'PNG'
    out.save()
    back = bpy.data.images.load(str(a.icon))
    chk = np.array(back.pixels[:]).reshape(ICON_H, ICON_W, 4)
    rows = np.where(chk[:, :, 3].max(axis=1) > 0.05)[0]
    cols = np.where(chk[:, :, 3].max(axis=0) > 0.05)[0]
    print(f'圖示：{a.icon}（{back.size[0]}×{back.size[1]}）；不透明的範圍 x {cols.min()}～{cols.max()}、y {rows.min()}～{rows.max()}（下往上）')


def srgb_to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


SHADOW_RADIUS = 2.0  # 暗影模糊的半徑（高斯的標準差；圖示的像素）
SHADOW_OFFSET = (1.0, 1.5)  # 暗影往右、往下偏（圖示的像素）


def box_blur(a, r: int):
    """每個方向做 3 次寬 2r+1 的平均（近似高斯）；邊界外當 0。"""
    for axis in (0, 1):
        for _ in range(3):
            pad = [(r + 1, r) if ax == axis else (0, 0) for ax in range(a.ndim)]
            c = np.cumsum(np.pad(a, pad), axis=axis)
            hi_, lo_ = [slice(None)] * a.ndim, [slice(None)] * a.ndim
            hi_[axis], lo_[axis] = slice(2 * r + 1, None), slice(None, -2 * r - 1)
            a = (c[tuple(hi_)] - c[tuple(lo_)]) / (2 * r + 1)
    return a


def add_shadow(px, opacity: float):
    """子彈後面墊一層黑色的柔和暗影（alpha 模糊、往右下偏），在線性、預乘空間疊上去；回傳同格式（sRGB、alpha 沒預乘）。
    Blender 的 pixels 第 0 列在最下面 → 往下偏 = 列號變小。"""
    alpha = px[:, :, 3]
    sigma = SHADOW_RADIUS * SS
    blur = box_blur(alpha, max(1, int(round((sigma ** 2 + 0.25) ** 0.5 - 0.5))))  # 3 次寬 2r+1 的平均：變異數 r(r+1)
    blur = np.roll(blur, (-int(SHADOW_OFFSET[1] * SS), int(SHADOW_OFFSET[0] * SS)), axis=(0, 1))
    shade = np.clip(opacity * blur, 0, 1) * (1 - alpha)
    out_a = alpha + shade
    rgb = srgb_to_linear(px[:, :, :3]) * alpha[:, :, None]  # 暗影是黑色：顏色只來自子彈
    color = np.divide(rgb, out_a[:, :, None], out=np.zeros_like(rgb), where=out_a[:, :, None] > 1e-6)
    print(f'暗影：不透明度 {opacity}、半徑 {SHADOW_RADIUS} 像素、偏移 {SHADOW_OFFSET}；最濃 {shade.max():.2f}')
    return np.concatenate([linear_to_srgb(color), out_a[:, :, None]], axis=2)


def downscale(px):
    """8 位元 PNG 的 pixels 是 sRGB 編碼、alpha 沒預乘 → 線性、預乘後每 SS×SS 平均，再換回去。"""
    rgb = srgb_to_linear(px[:, :, :3]) * px[:, :, 3:4]
    alpha = px[:, :, 3:4]
    h, w = ICON_H, ICON_W
    rgb = rgb.reshape(h, SS, w, SS, 3).mean(axis=(1, 3))
    alpha = alpha.reshape(h, SS, w, SS, 1).mean(axis=(1, 3))
    color = np.divide(rgb, alpha, out=np.zeros_like(rgb), where=alpha > 1e-6)
    return np.concatenate([linear_to_srgb(color), alpha], axis=2)


# ---------- 彈頭模型 ----------

def islands(bm) -> list[set]:
    seen, out = set(), []
    for v in bm.verts:
        if v in seen:
            continue
        stack, comp = [v], {v}
        seen.add(v)
        while stack:
            a = stack.pop()
            for e in a.link_edges:
                b = e.other_vert(a)
                if b not in seen:
                    seen.add(b)
                    comp.add(b)
                    stack.append(b)
        out.append(comp)
    return out


def build_head(obj) -> bpy.types.Object:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.transform(obj.matrix_world)
    comps = islands(bm)
    tip = min(bm.verts, key=lambda v: v.co.y)
    head = next(c for c in comps if tip in c)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v not in head], context='VERTS')
    # glTF 在貼圖接縫的頂點是分開的兩份（UV 不同）→ 合併（UV 存在每個角上，不受影響），開口才只剩底部那圈
    n_before = len(bm.verts)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    uv = bm.loops.layers.uv.active
    boundary = [e for e in bm.edges if e.is_boundary]
    ring = {v for e in boundary for v in e.verts}
    ys = [v.co.y for v in ring]
    print(f'彈頭：{len(comps)} 塊裡有尖端的那塊，頂點 {n_before} 個（合併接縫後 {len(bm.verts)} 個）、面 {len(bm.faces)} 個；'
          f'開口的邊 {len(boundary)} 條（Y {min(ys):+.4f}～{max(ys):+.4f}）')
    if max(ys) - min(ys) > 1e-4:
        raise SystemExit('開口不只底部那一圈')
    # 開口邊上的 UV 平均：封口用（彈頭底部的顏色）
    edge_uvs = [l[uv].uv.copy() for v in ring for l in v.link_loops]
    cap_uv = sum(edge_uvs, Vector((0, 0))) / len(edge_uvs)
    for f in bm.faces:
        f.smooth = True
    filled = bmesh.ops.holes_fill(bm, edges=boundary, sides=0)['faces']
    cap = bmesh.ops.triangulate(bm, faces=filled)['faces']
    for f in cap:
        f.smooth = False
        for l in f.loops:
            l[uv].uv = cap_uv
    for e in boundary:
        e.smooth = False  # 硬邊
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    # 朝外：側面的法線朝離開長軸的方向；尖端的小平面（法線幾乎平行長軸）朝 -Y；封口（底部在 +Y 那頭）朝 +Y
    cap_set = set(cap)
    mid_y = (min(v.co.y for v in bm.verts) + max(v.co.y for v in bm.verts)) / 2

    def outward(f) -> bool:
        n, c = f.normal, f.calc_center_median()
        if abs(n.y) > 0.9:
            return n.y < 0 if c.y < mid_y else n.y > 0
        return n.x * c.x + n.z * c.z > 0
    side_out = sum(1 for f in bm.faces if f not in cap_set and outward(f))
    tip_flat = sum(1 for f in bm.faces if f not in cap_set and abs(f.normal.y) > 0.9)
    cap_out = sum(1 for f in cap if f.normal.y > 0.99)
    print(f'封口：{len(cap)} 個三角形；側面朝外 {side_out}／{len(bm.faces) - len(cap)}（含尖端的小平面 {tip_flat} 個）、'
          f'封口朝後 {cap_out}／{len(cap)}')
    if side_out != len(bm.faces) - len(cap) or cap_out != len(cap):
        raise SystemExit('有面的法線朝內')

    # 世界座標（尖在 -Y）→ REDkit 模型座標（尖在 +Y、底在原點）：繞 Z 轉 180°，再把底移到 Y = 0
    bm.transform(Matrix.Rotation(math.radians(180), 4, 'Z'))
    base_y = min(v.co.y for v in bm.verts)
    bm.transform(Matrix.Translation((0, -base_y, 0)))
    redkit = [v.co.copy() for v in bm.verts]
    bm.transform(Matrix.Scale(100, 4))  # 公分（m3_build_ak.py 的做法）

    me = bpy.data.meshes.new(NAME)
    bm.to_mesh(me)
    bm.free()
    me.uv_layers[0].name = 'DiffuseUV'
    mat = obj.data.materials[0].copy()
    mat.name = NAME
    me.materials.clear()
    me.materials.append(mat)
    head_obj = bpy.data.objects.new(NAME, me)
    bpy.context.scene.collection.objects.link(head_obj)
    head_obj.matrix_world = Matrix.Scale(0.01, 4) @ Matrix.Rotation(math.radians(-180), 4, 'Z')
    lo, hi = bbox(redkit)
    print(f'彈頭（REDkit 座標，公尺）：外框 {fmt(lo)}～{fmt(hi)}；長 {hi.y - lo.y:.4f}、直徑 {max(hi.x - lo.x, hi.z - lo.z):.4f}')
    return head_obj, lo, hi


def export_fbx(obj, path: Path) -> None:
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(
        filepath=str(path), use_selection=True, object_types={'MESH'},
        axis_up='Z', axis_forward='-Y',
        mesh_smooth_type='OFF', use_mesh_modifiers=True, bake_anim=False)


def check_fbx(path: Path, lo: Vector, hi: Vector) -> None:
    root, _version = parse_fbx.parse(str(path))
    objects = next(e for e in root.elems if e.id == b'Objects')
    models = [e.props[1].split(b'\x00\x01')[0].decode() for e in objects.elems if e.id == b'Model']
    transforms = {}
    for e in objects.elems:
        if e.id == b'Model':
            for sub in e.elems:
                for p in sub.elems:
                    if p.id == b'P' and p.props[0] in (b'Lcl Translation', b'Lcl Rotation', b'Lcl Scaling'):
                        transforms[p.props[0].decode()] = tuple(round(v, 4) for v in p.props[4:7])
    geom = next(e for e in objects.elems if e.id == b'Geometry')
    raw = next(c for c in geom.elems if c.id == b'Vertices').props[0]
    pts = [Vector(raw[i:i + 3]) for i in range(0, len(raw), 3)]
    flo, fhi = bbox(pts)
    diff = max((flo - lo * 100).length, (fhi - hi * 100).length)
    print(f'## 解析 {path.name}')
    print(f'模型節點 {models}；變換 {transforms or "（單位）"}')
    print(f'頂點 {len(pts)} 個；外框（公分）{fmt(flo)}～{fmt(fhi)}；和 REDkit 座標 × 100 差 {diff:.5f}')
    bad = {k: v for k, v in transforms.items()
           if v != ((1.0, 1.0, 1.0) if k == 'Lcl Scaling' else (0.0, 0.0, 0.0))}
    if bad or diff > 1e-3:
        raise SystemExit(f'FBX 不是預期的：變換 {bad}、外框差 {diff}')


def save_diffuse(src: Path, dst: Path) -> None:
    """照 tools/m3_textures.py 的 save()：原始數值照抄（Non-Color），存成沒有 alpha 的 PNG。"""
    img = bpy.data.images.load(str(src))
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32)
    out = bpy.data.images.new(dst.stem, w, h, alpha=False)
    out.colorspace_settings.name = 'Non-Color'
    out.pixels.foreach_set(px)
    out.filepath_raw = str(dst)
    out.file_format = 'PNG'
    out.save()
    depth, ctype = dst.read_bytes()[24:26]
    back = bpy.data.images.load(str(dst))
    back.colorspace_settings.name = 'Non-Color'
    a = px.reshape(-1, 4)[:, :3].mean(axis=0)
    b = np.array(back.pixels[:]).reshape(-1, 4)[:, :3].mean(axis=0)
    kind = {2: 'RGB', 6: 'RGBA'}.get(ctype, f'色彩類型 {ctype}')
    print(f'貼圖：{dst.name} {w}×{h}、{depth} 位元 {kind}；RGB 平均 來源 {fmt(a)}、輸出 {fmt(b)}')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    a = parse_args()
    obj = import_bullet(a.gltf)
    lo, hi = check_source(obj)
    a.out_dir.mkdir(parents=True, exist_ok=True)

    head, hlo, hhi = build_head(obj)
    fbx = a.out_dir / f'{NAME}.fbx'
    export_fbx(head, fbx)
    check_fbx(fbx, hlo, hhi)
    bpy.data.objects.remove(head)

    save_diffuse(a.color, a.out_dir / f'{NAME}_d01.png')
    render_icon(obj, lo, hi, a)


main()
