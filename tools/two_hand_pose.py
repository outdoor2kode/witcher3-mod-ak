"""雙手持槍第 1 步：底層姿勢（docs/m3.md「雙手持槍：第 1 步：底層姿勢」）

把 NPC 的雙手瞄準（我們動畫組裡的 man_geralt_gabriel_aim_idle_rp；REDkit 匯出成 gfg_aim_idle_rp.re）改成兩手握著 AK：
AK 放在第 0 格的左掌上、槍管水平朝正前方，之後跟著胸口（torso3）動；兩手用 IK 握在 AK 上。

用法：
    PIP_NO_INDEX=1 PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
    "D:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --factory-startup --background
        --python-exit-code 1 --python tools/two_hand_pose.py --
        原檔.re AK.gltf 輸出.re 預覽圖.png [--palm-s 0.375] [--palm-drop 0] [--grip-deg 13]

- 座標：外掛匯入後的骨架空間（X 右、Y 前、Z 上，公尺）＝ 原檔 FK、Root 不套（docs/m3.md「使用者選 A：外掛匯出＋修補」）
- 骨頭的方向用遊戲的骨頭座標：.re 的四元數轉置 ＝ 區域旋轉（docs/m3.md「.re 的內容與 Blender 來回測試」）
  - Blender 的骨頭矩陣 ＝ 遊戲的骨頭矩陣 × 每根骨頭固定的旋轉（外掛 import_anims.py:531-557）→ 用第 0 格算，再用其他格檢查
- AK（第 0 格決定擺法；遊戲裡 AK 掛在 l_weapon 上）：
  - 槍管朝 +Y、上方 +Z（瞄準的偏轉交給第 2 步）
  - 護木底部（槍管方向離握把 --palm-s 公尺；底部的高度從 AK 的模型量）放在 l_weapon 往下 --palm-drop 公尺；左右在 l_weapon 的正前後方
  - 每一格：AK 跟著 torso3 動（和 torso3 的相對位置照第 0 格）
    - 原因：原檔的左手相對胸口晃到 4.7°；AK 跟著左手的話，待機時槍管會晃到 4°
- 兩手的目標（手腕的位置、手的方向）：
  - 左手：照第 0 格握在 AK 上（每一格 ＝ 第 0 格的左手跟著 torso3 動）→ l_weapon 和 AK 一起動
  - 右手：掌心（r_hand 座標 (0.061, 0.032, -0.002)，l_weapon 在左手的對稱位置：docs/m3.md「兩隻手的位置」）放到握把 ag1_hand_r；
    拳頭的軸（r_hand 的 -z，食指側往小指側）轉到握把的方向（上端往前 --grip-deg 度）：用最小的旋轉，其他方向照原本的
- 兩節手臂的 IK（上臂、前臂；手的方向直接設成目標）：肩膀自由轉，手肘當鉸鏈（只在手臂平面裡彎），手肘盡量留在原本的方向
  - 不用 Blender 的 IK 約束：它把手肘當成能往各方向轉的關節，試算時右手肘往側面彎了 8°；調 ik_stiffness 右手改善、左手變差
  - 每一格把三根骨頭的矩陣設回 Blender（照外掛 set_pose_matrices 的寫法，用新的父骨頭矩陣換算）、插關鍵格
  → re_blender.export_re（外掛匯出、re_fix 修補、和原檔比對）
- 檢查（讀輸出檔做 FK）：每一格的掌心和握把、拳頭的軸和握把、l_weapon 和 AK 該在的位置
- 印出 m3_build_ak.py 的 --place 和 bolt slot：照遊戲裡 handle 骨頭的實際方向（繞槍管轉 180°：docs/m3.md「遊戲裡實測」）
- 預覽圖（Workbench，第 0 格）：骨頭畫成棒子、關節畫成球；右手臂紅（淡紅＝原本的位置）、左手臂藍、AK 褐色；
  黃球＝握把、綠球＝護木底部；2×2：左上從右邊看、右上從上面看、左下從前面看、右下從右後上方看
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
from mathutils import Matrix, Vector

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import re_blender  # noqa: E402

SKEL = '.re_asset_node/.re_asset_description_node/.re_skeleton'
CLIP = '.re_asset_node/.re_animation_container/.re_animation/.re_anim_clip'
CHEST = 'torso3'
ARMS = {'左手': ('l_bicep', 'l_forearm', 'l_hand'), '右手': ('r_bicep', 'r_forearm', 'r_hand')}
PALM_R = np.array([0.061, 0.032, -0.002])  # 右掌心，r_hand 座標（公尺）
GRIP_BONE = 'ag1_hand_r'
AK_BODY_SUFFIX = '.body_hd'
AK_FORWARD = np.array([0.0, -1.0, 0.0])  # glTF 裡 AK 的槍口方向（m3_build_ak.py）
AK_UP = np.array([0.0, 0.0, 1.0])
FORWARD = np.array([0.0, 1.0, 0.0])
UP = np.array([0.0, 0.0, 1.0])
# 遊戲裡 AK 的 handle 骨頭（l_weapon 座標）：原點 (0, 0, -0.0723)，x → +Z、y → +Y、z → -X（docs/m3.md「遊戲裡實測」）
HANDLE_GAME = np.array([[0.0, 0.0, -1.0, 0.0], [0.0, 1.0, 0.0, 0.0], [1.0, 0.0, 0.0, -0.0723], [0.0, 0.0, 0.0, 1.0]])
# bolt slot：箭尾在握把往前 0.3507、往上 0.0969（槍管中心線、箭頭在槍口後 1 公分：docs/m3.md「使用者選 A」）
BOLT_S, BOLT_H = 0.3507, 0.0969
SKIP_DRAW = ('Root', 'Reference', 'Trajectory')


def parse_args() -> argparse.Namespace:
    # blender 會把 "--" 後面的參數留給腳本
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    p = argparse.ArgumentParser(prog='two_hand_pose.py')
    p.add_argument('src', type=Path, help='REDkit 匯出的原檔 .re（NPC 的雙手瞄準）')
    p.add_argument('ak', type=Path, help='CS2 匯出的 weapon_rif_ak47.gltf')
    p.add_argument('out', type=Path, help='輸出 .re')
    p.add_argument('preview', type=Path, help='預覽圖 .png')
    p.add_argument('--palm-s', type=float, default=0.375,
                   help='左掌放在護木的哪裡：槍管方向離握把幾公尺（預設 0.375，下護木 0.30～0.45 的中間）')
    p.add_argument('--palm-drop', type=float, default=0.0, help='護木底部放在 l_weapon 往下幾公尺（預設 0）')
    p.add_argument('--grip-deg', type=float, default=13.0, help='握把的斜度：上端往前幾度（預設 13，從 AK 的模型量）')
    return p.parse_args(argv)


# ---------- 數學 ----------

def vec(v) -> str:
    return '(' + ', '.join(f'{x:.4f}' for x in v) + ')'


def unit(v: np.ndarray) -> np.ndarray:
    return v / np.linalg.norm(v)


def rot_deg(r: np.ndarray) -> float:
    """3×3 旋轉矩陣轉了幾度。"""
    return math.degrees(math.acos(max(-1.0, min(1.0, (np.trace(r) - 1) / 2))))


def angle_deg(a: np.ndarray, b: np.ndarray) -> float:
    return math.degrees(math.acos(max(-1.0, min(1.0, float(unit(a) @ unit(b))))))


def rotation_between(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """把方向 a 轉到 b 的最小旋轉（3×3）。"""
    return np.array(Vector(a).rotation_difference(Vector(b)).to_matrix())


def frame3(forward: np.ndarray, up: np.ndarray) -> np.ndarray:
    # 三個欄：前、上、前×上（和 m3_build_ak.py 的 frame 一樣）
    return np.column_stack([forward, up, np.cross(forward, up)])


def rigid(r: np.ndarray, t) -> np.ndarray:
    m = np.eye(4)
    m[:3, :3] = r
    m[:3, 3] = t
    return m


def to_np(m: Matrix) -> np.ndarray:
    return np.array([list(row) for row in m])


def to_mat(a: np.ndarray) -> Matrix:
    return Matrix(a.tolist())


def twist_deg(delta: np.ndarray, axis: np.ndarray) -> float:
    """旋轉 delta 繞 axis 的扭轉角度（swing-twist 分解，度）。"""
    q = Matrix(delta.tolist()).to_quaternion()
    return math.degrees(2 * math.atan2(float(np.dot([q.x, q.y, q.z], unit(axis))), q.w))


# ---------- .re ----------

def quat_rot(d) -> np.ndarray:
    """.re 的四元數 (x, y, z, w) → 骨頭的區域旋轉：照 Hamilton 轉矩陣後轉置。"""
    x, y, z, w = (float(d[c]) for c in ('rot.x', 'rot.y', 'rot.z', 'rot.w'))
    n = math.sqrt(x * x + y * y + z * z + w * w)
    x, y, z, w = x / n, y / n, z / n, w / n
    m = np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])
    return m.T


class Anim:
    """.re 的骨架階層和每一格的資料；fk(f) ＝ {骨頭: 4×4}（公尺，Root 不套）。"""

    def __init__(self, path: Path, hier: list | None = None):
        import h5py
        with h5py.File(path, 'r') as f:
            if hier is None:
                hier = []

                def walk(g, parent):
                    for k in g.keys():
                        if isinstance(g[k], h5py.Group):
                            hier.append((k, parent))
                            walk(g[k], k)
                walk(f[SKEL], None)
            clip = f[CLIP]
            self.frames = {k: clip[k]['xformframes'][()].reshape(-1) for k in clip.keys() if isinstance(clip[k], h5py.Group)}
        self.hier = hier
        self.parent = dict(hier)
        self.count = len(self.frames[hier[0][0]])

    def fk(self, f: int) -> dict[str, np.ndarray]:
        world = {}
        for name, parent in self.hier:
            if parent is None:
                world[name] = np.eye(4)
                continue
            d = self.frames[name][f]
            local = rigid(quat_rot(d), [float(d['pos.x']) * 0.01, float(d['pos.y']) * 0.01, float(d['pos.z']) * 0.01])
            world[name] = world[parent] @ local
        return world


# ---------- AK ----------

def load_ak(path: Path):
    """匯入 glTF，只留 body_hd 的原始頂點（m3_build_ak.py 的做法）；回傳 (物件, 握把位置, 頂點)。"""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path), disable_bone_shape=True)
    new = [o for o in bpy.data.objects if o not in before]
    arm = next(o for o in new if o.type == 'ARMATURE')
    body = next(o for o in new if o.type == 'MESH' and o.name.endswith(AK_BODY_SUFFIX))
    grip = np.array(arm.matrix_world @ arm.data.bones[GRIP_BONE].head_local)
    for o in new:
        if o is not body:
            bpy.data.objects.remove(o)
    body.modifiers.clear()
    body.vertex_groups.clear()
    body.parent = None
    body.matrix_world = Matrix.Identity(4)
    pts = np.array([tuple(v.co) for v in body.data.vertices])
    return body, grip, pts


def handguard_bottom(pts: np.ndarray, grip: np.ndarray, s0: float) -> float:
    """護木在 s0（槍管方向離握把幾公尺）前後 1.25 公分內的最低點（高度，以握把為 0）。"""
    s = -(pts[:, 1] - grip[1])
    h = pts[:, 2] - grip[2]
    m = (np.abs(s - s0) <= 0.0125) & (h > 0.03)
    if not m.any():
        raise ValueError(f'AK 在 s = {s0} 附近沒有護木的頂點')
    return float(h[m].min())


# ---------- Blender ----------

def blender_offsets(obj, anim: Anim, names: list[str], frames: list[int]) -> dict[str, np.ndarray]:
    """Blender 的骨頭矩陣 ＝ 遊戲的骨頭矩陣 × D：回傳每根骨頭的 D，並檢查位置、D 在各格都一樣。"""
    scene = bpy.context.scene
    offsets, worst_pos, worst_rot = {}, 0.0, {}
    for f in frames:
        scene.frame_set(f)
        world = anim.fk(f)
        for name in names:
            m = to_np(obj.pose.bones[name].matrix)
            d = world[name][:3, :3].T @ m[:3, :3]
            offsets.setdefault(name, d)
            worst_rot[name] = max(worst_rot.get(name, 0.0), rot_deg(offsets[name].T @ d))
            worst_pos = max(worst_pos, float(np.linalg.norm(m[:3, 3] - world[name][:3, 3])))
    print(f'Blender 和 FK 比對（第 {frames} 格）：位置差最多 {worst_pos * 1000:.3f} 公釐；固定旋轉在各格的差：'
          + '、'.join(f'{n} {d:.3f}°' for n, d in worst_rot.items()))
    if worst_pos > 1e-4 or max(worst_rot.values()) > 0.2:
        raise RuntimeError('Blender 的骨頭和 FK 對不上，停止')
    return offsets


def axis_angle(axis: np.ndarray, angle: float) -> np.ndarray:
    return np.array(Matrix.Rotation(angle, 3, Vector(unit(axis))))


def two_bone_ik(world: dict, bones: tuple[str, str, str], target: np.ndarray) -> dict[str, np.ndarray]:
    """兩節手臂的 IK：手腕到 target 的位置、手的方向 ＝ target 的方向。回傳三根骨頭的新世界矩陣（遊戲骨頭座標）。

    1. 手肘當鉸鏈：前臂繞手臂平面的法線轉，讓肩膀到手腕的距離剛好（餘弦定理）
    2. 整隻手臂繞肩膀轉：手腕轉到目標；再繞「肩膀 → 目標」的軸轉，讓手肘最接近原本的方向
    """
    upper, lower, hand = bones
    s, e, w = (world[b][:3, 3] for b in bones)
    goal = target[:3, 3]
    a, b = np.linalg.norm(e - s), np.linalg.norm(w - e)
    d = min(max(np.linalg.norm(goal - s), abs(a - b) + 1e-6), a + b - 1e-6)

    def inner(dist):  # 手肘的內角
        return math.acos(max(-1.0, min(1.0, (a * a + b * b - dist * dist) / (2 * a * b))))

    bend = axis_angle(np.cross(e - s, w - e), inner(np.linalg.norm(w - s)) - inner(d))
    w1 = e + bend @ (w - e)
    swing = rotation_between(w1 - s, goal - s)
    u = unit(goal - s)
    e1 = swing @ (e - s)
    p_new, p_old = e1 - (e1 @ u) * u, (e - s) - ((e - s) @ u) * u
    turn = math.atan2(float(u @ np.cross(p_new, p_old)), float(p_new @ p_old))
    r = axis_angle(u, turn) @ swing
    return {
        upper: rigid(r @ world[upper][:3, :3], s),
        lower: rigid(r @ bend @ world[lower][:3, :3], s + r @ (e - s)),
        hand: target.copy(),
    }


def apply_arms(obj, old: list[dict], targets: dict[str, list[np.ndarray]], offsets: dict[str, np.ndarray]) -> list[dict]:
    """每一格算 IK，把三根骨頭設回 Blender、插關鍵格；回傳每一格的新世界矩陣（檢查用）。"""
    scene = bpy.context.scene
    result = []
    for f, world in enumerate(old):
        scene.frame_set(f)
        posed = {}
        for side, bones in ARMS.items():
            posed.update(two_bone_ik(world, bones, targets[side][f]))
        result.append(posed)
        for bones in ARMS.values():
            parent = obj.pose.bones[bones[0]].parent.matrix.copy()  # 肩膀：不動
            for name in bones:
                pb = obj.pose.bones[name]
                m = to_mat(rigid(posed[name][:3, :3] @ offsets[name], posed[name][:3, 3]))
                # 外掛 set_pose_matrices 的寫法：用新的父骨頭矩陣換算成 matrix_basis
                pb.matrix_basis = pb.bone.convert_local_to_pose(m, pb.bone.matrix_local, parent_matrix=parent,
                                                                parent_matrix_local=pb.parent.bone.matrix_local, invert=True)
                pb.keyframe_insert('rotation_quaternion', frame=f)
                pb.keyframe_insert('location', frame=f)
                parent = m
    # 讀回 Blender 的姿勢檢查
    worst_pos = worst_rot = 0.0
    for f, posed in enumerate(result):
        scene.frame_set(f)
        for name, m in posed.items():
            got = to_np(obj.pose.bones[name].matrix)
            worst_pos = max(worst_pos, float(np.linalg.norm(got[:3, 3] - m[:3, 3])))
            worst_rot = max(worst_rot, rot_deg((m[:3, :3] @ offsets[name]).T @ got[:3, :3]))
    print(f'IK 設回 Blender（{len(result)} 格）：和算出來的差最多 {worst_pos * 1000:.3f} 公釐、{worst_rot:.4f}°')
    return result


# ---------- 檢查 ----------

def arm_report(side: str, bones: tuple[str, str, str], old: list[dict], new: list[dict]) -> None:
    upper, lower, hand = bones
    elbow = wrist = bicep_twist = hinge_turn = hinge_dev = wrist_twist = 0.0
    for wo, wn in zip(old, new):
        elbow = max(elbow, float(np.linalg.norm(wn[lower][:3, 3] - wo[lower][:3, 3])))
        wrist = max(wrist, float(np.linalg.norm(wn[hand][:3, 3] - wo[hand][:3, 3])))
        # 上臂繞自己的軸（x）扭了多少：先把舊的 x 轉到新的 x，再比 y 軸
        ro, rn = wo[upper][:3, :3], wn[upper][:3, :3]
        swing = rotation_between(ro[:, 0], rn[:, 0])
        bicep_twist = max(bicep_twist, abs(twist_deg(rn @ (swing @ ro).T, rn[:, 0])))
        # 手肘：前臂相對上臂的變化（上臂座標），和手肘的轉軸（手臂平面的法線）差幾度
        delta = (rn.T @ wn[lower][:3, :3]) @ (ro.T @ wo[lower][:3, :3]).T
        s, e, w = (wo[b][:3, 3] for b in bones)
        hinge = ro.T @ unit(np.cross(e - s, w - e))
        q = Matrix(delta.tolist()).to_quaternion()
        turn = math.degrees(q.angle)
        hinge_turn = max(hinge_turn, turn)
        if turn > 0.5:
            axis = np.array(q.axis)
            hinge_dev = max(hinge_dev, min(angle_deg(axis, hinge), angle_deg(-axis, hinge)))
        # 手腕：手相對前臂繞前臂的軸（x）扭了多少
        rel_o = wo[lower][:3, :3].T @ wo[hand][:3, :3]
        rel_n = wn[lower][:3, :3].T @ wn[hand][:3, :3]
        wrist_twist = max(wrist_twist, abs(twist_deg(rel_n @ rel_o.T, np.array([1.0, 0.0, 0.0]))))
    print(f'{side}（整段最大值）：手肘移動 {elbow * 100:.1f} 公分、手腕移動 {wrist * 100:.1f} 公分；'
          f'上臂繞自己的軸扭 {bicep_twist:.1f}°；手肘彎曲改變 {hinge_turn:.1f}°（轉軸偏離手肘的轉軸 {hinge_dev:.1f}°）；'
          f'手相對前臂扭 {wrist_twist:.1f}°')


# ---------- 預覽圖 ----------

def primitive(kind: str):
    me = bpy.data.meshes.new(f'gfg_{kind}')
    bm = bmesh.new()
    if kind == 'ball':
        bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=8, radius=1.0)
    else:
        bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=1.0, radius2=1.0, depth=1.0)
    for face in bm.faces:
        face.smooth = True
    bm.to_mesh(me)
    bm.free()
    return me


def render_preview(path: Path, anim: Anim, new0: dict, old0: dict, ak_body, ak_matrix: np.ndarray,
                   markers: list[tuple[np.ndarray, tuple]]) -> None:
    scene = bpy.data.scenes.new('gfg_preview')
    ball, stick = primitive('ball'), primitive('stick')

    def add(me, m: Matrix, color):
        o = bpy.data.objects.new(me.name, me)
        o.color = (*color, 1.0)
        scene.collection.objects.link(o)
        o.matrix_world = m

    def add_ball(p, r, color):
        add(ball, Matrix.Translation(Vector(p)) @ Matrix.Scale(r, 4), color)

    def add_stick(a, b, r, color):
        d = Vector(b) - Vector(a)
        if d.length < 1e-4:
            return
        m = (Matrix.Translation((Vector(a) + Vector(b)) / 2) @ Vector((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4()
             @ Matrix.Diagonal((r, r, d.length, 1)))
        add(stick, m, color)

    def drawn(name):
        low = name.lower()
        return not (name in SKIP_DRAW or name.startswith('IK_') or 'roll' in low or 'bicep2' in low)

    def under(name, top):
        while name is not None:
            if name == top:
                return True
            name = anim.parent[name]
        return False

    def finger(name):
        return any(k in name for k in ('index', 'middle', 'ring', 'pinky', 'thumb'))

    for name, parent in anim.hier:
        if not drawn(name):
            continue
        color = (0.85, 0.12, 0.1) if under(name, 'r_shoulder') else (0.15, 0.35, 0.9) if under(name, 'l_shoulder') else (0.55, 0.55, 0.55)
        r = 0.005 if finger(name) else 0.011
        add_ball(new0[name][:3, 3], r, color)
        if parent is not None and drawn(parent):
            add_stick(new0[parent][:3, 3], new0[name][:3, 3], r * 0.55, color)
        # 原本的右手臂（淡紅，細一點）
        if under(name, 'r_bicep') and name != 'r_bicep':
            pale = (1.0, 0.72, 0.72)
            add_ball(old0[name][:3, 3], r * 0.7, pale)
            if parent is not None and drawn(parent):
                add_stick(old0[parent][:3, 3], old0[name][:3, 3], r * 0.35, pale)
    for p, color in markers:
        add_ball(p, 0.008, color)
    ak = bpy.data.objects.new('gfg_ak', ak_body.data)
    ak.color = (0.55, 0.42, 0.3, 1.0)
    scene.collection.objects.link(ak)
    ak.matrix_world = to_mat(ak_matrix)

    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'OBJECT'
    scene.display.shading.show_object_outline = True
    scene.view_settings.view_transform = 'Standard'
    scene.world = bpy.data.worlds.new('gfg_preview')
    scene.world.color = (1.0, 1.0, 1.0)
    scene.render.resolution_x = scene.render.resolution_y = 1000
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    cam = bpy.data.objects.new('gfg_camera', bpy.data.cameras.new('gfg_camera'))
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 1.5
    cam.data.clip_end = 20
    scene.collection.objects.link(cam)
    scene.camera = cam
    center = Vector((0.05, 0.25, 1.35))
    views = [  # 2×2：左上、右上、左下、右下
        ('right', center + Vector((3, 0, 0)), None),
        ('top', center + Vector((0, 0, 3)), (0.0, 0.0, 0.0)),
        ('front', center + Vector((0, 3, 0)), None),
        ('rear_right', Vector((1.1, -1.4, 2.3)), None),
    ]
    tiles = []
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=path.parent) as tmp:
        for name, loc, euler in views:
            cam.location = loc
            if euler is None:
                cam.rotation_euler = (center - loc).to_track_quat('-Z', 'Y').to_euler()
            else:
                cam.rotation_euler = euler
            scene.render.filepath = str(Path(tmp) / f'{name}.png')
            bpy.ops.render.render(write_still=True, scene=scene.name)
            img = bpy.data.images.load(scene.render.filepath)
            tiles.append(np.array(img.pixels[:]).reshape(img.size[1], img.size[0], 4))
            bpy.data.images.remove(img)
    h, w = tiles[0].shape[:2]
    grid = np.ones((2 * h, 2 * w, 4))
    # 像素是由下往上存：上排放在後半
    grid[h:, :w], grid[h:, w:], grid[:h, :w], grid[:h, w:] = tiles
    grid[h - 1:h + 1, :, :3] = 0.3
    grid[:, w - 1:w + 1, :3] = 0.3
    out = bpy.data.images.new('gfg_preview', 2 * w, 2 * h, alpha=True)
    out.pixels.foreach_set(grid.astype(np.float32).ravel())
    out.filepath_raw = str(path)
    out.file_format = 'PNG'
    out.save()
    print(f'已存預覽圖：{path}')


# ---------- 主程式 ----------

def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    args = parse_args()
    for p in (args.src, args.ak):
        if not p.is_file():
            print(f'找不到檔案：{p}')
            return 2
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj, info = re_blender.import_re(args.src)
    anim = Anim(args.src)
    count = anim.count
    if count != info['numkeys']:
        raise RuntimeError(f'格數不同：h5py 讀到 {count}、外掛 {info["numkeys"]}')
    old = [anim.fk(f) for f in range(count)]
    w0 = old[0]
    offsets = blender_offsets(obj, anim, [CHEST, 'l_weapon'] + [b for bones in ARMS.values() for b in bones],
                              [0, count // 2, count - 1])

    bpy.ops.object.mode_set(mode='OBJECT')
    ak_body, grip, ak_pts = load_ak(args.ak)

    # AK 的擺法（第 0 格，骨架空間）
    bottom = handguard_bottom(ak_pts, grip, args.palm_s)
    lw0 = w0['l_weapon']
    contact = lw0[:3, 3] - args.palm_drop * UP
    g = contact - args.palm_s * FORWARD - bottom * UP
    ak0 = rigid(frame3(FORWARD, UP) @ frame3(AK_FORWARD, AK_UP).T, g) @ rigid(np.eye(3), -grip)
    a = math.radians(args.grip_deg)
    grip_up = UP * math.cos(a) + FORWARD * math.sin(a)

    # 右手的目標（第 0 格）：掌心到握把、拳頭的軸對齊握把
    rh = w0['r_hand'][:3, :3]
    rt = rotation_between(rh @ np.array([0.0, 0.0, 1.0]), grip_up) @ rh
    right0 = rigid(rt, g - rt @ PALM_R)
    palm_old = w0['r_hand'][:3, :3] @ PALM_R + w0['r_hand'][:3, 3]
    print(f'\n護木底部（s = {args.palm_s}）的高度：握把往上 {bottom:.4f}')
    print(f'握把（骨架空間）：{vec(g)}；原本的右掌心 {vec(palm_old)}，要移動 {np.linalg.norm(g - palm_old) * 100:.1f} 公分；'
          f'拳頭的軸要轉 {rot_deg(rt @ rh.T):.1f}°')

    # 每一格：AK、兩手跟著 torso3 動
    chest = [w[CHEST] @ np.linalg.inv(w0[CHEST]) for w in old]
    targets = {'左手': [c @ w0['l_hand'] for c in chest], '右手': [c @ right0 for c in chest]}
    apply_arms(obj, old, targets, offsets)
    re_blender.export_re(obj, info, args.out)

    # 檢查輸出檔
    out_anim = Anim(args.out, anim.hier)
    new = [out_anim.fk(f) for f in range(count)]
    palm_err = axis_err = lw_pos = lw_rot = chest_err = 0.0
    for f in range(count):
        c, wn = chest[f], new[f]
        palm = wn['r_hand'][:3, :3] @ PALM_R + wn['r_hand'][:3, 3]
        palm_err = max(palm_err, float(np.linalg.norm(palm - (c[:3, :3] @ g + c[:3, 3]))))
        axis_err = max(axis_err, angle_deg(wn['r_hand'][:3, 2], c[:3, :3] @ grip_up))
        want = c @ lw0
        lw_pos = max(lw_pos, float(np.linalg.norm(wn['l_weapon'][:3, 3] - want[:3, 3])))
        lw_rot = max(lw_rot, rot_deg(want[:3, :3].T @ wn['l_weapon'][:3, :3]))
        chest_err = max(chest_err, float(np.linalg.norm(wn[CHEST] - old[f][CHEST])))
    print(f'\n## 檢查輸出檔（FK，{count} 格的最大值）')
    print(f'右掌心和握把差 {palm_err * 1000:.2f} 公釐；拳頭的軸和握把差 {axis_err:.3f}°')
    print(f'l_weapon 和 AK 該在的位置差 {lw_pos * 1000:.2f} 公釐、{lw_rot:.3f}°；torso3 和原檔的矩陣差 {chest_err:.2e}')
    for side, bones in ARMS.items():
        arm_report(side, bones, old, new)
    sway = max(rot_deg(old[0]['l_weapon'][:3, :3].T @ w['l_weapon'][:3, :3]) for w in old)
    sway_new = max(rot_deg(new[0]['l_weapon'][:3, :3].T @ w['l_weapon'][:3, :3]) for w in new)
    print(f'l_weapon（＝ AK）整段最多轉：原檔 {sway:.1f}°、輸出 {sway_new:.1f}°')

    # 給 m3_build_ak.py 的 --place、bolt slot
    inv_lw = np.linalg.inv(lw0)
    g_l, f_l, u_l = inv_lw[:3, :3] @ g + inv_lw[:3, 3], inv_lw[:3, :3] @ FORWARD, inv_lw[:3, :3] @ UP
    flip = np.array([-1.0, -1.0, 1.0])  # 繞 l_weapon 的 z 軸轉 180°：抵掉遊戲裡 handle 的方向和綁定矩陣的差
    place = np.concatenate([g_l * flip, f_l * flip, u_l * flip])
    print('\n## AK 的擺法')
    print(f'l_weapon 座標：握把 {vec(g_l)}、槍管 {vec(f_l)}、上方 {vec(u_l)}')
    print('m3_build_ak.py 的 --place（已修正 handle 的 180°）：' + ' '.join(f'{x:.5f}' for x in place))
    inv_h = np.linalg.inv(HANDLE_GAME)
    bolt = inv_h[:3, :3] @ (g_l + BOLT_S * f_l + BOLT_H * u_l) + inv_h[:3, 3]
    f_h, u_h = inv_h[:3, :3] @ f_l, inv_h[:3, :3] @ u_l
    right_h = np.cross(f_h, u_h)
    pitch, yaw = math.asin(f_h[2]), math.atan2(-f_h[0], f_h[1])
    axis_a = np.array([math.cos(yaw), math.sin(yaw), 0.0])
    axis_c = np.array([math.sin(yaw) * math.sin(pitch), -math.cos(yaw) * math.sin(pitch), math.cos(pitch)])
    roll = math.atan2(-(right_h @ axis_c), right_h @ axis_a)
    print(f'bolt slot（handle 骨頭座標）：位置 {vec(bolt)}；Pitch {math.degrees(pitch):.1f}、Yaw {math.degrees(yaw):.1f}、'
          f'Roll {math.degrees(roll):.1f}；槍管方向 {vec(f_h)}')
    butt = ak0 @ np.array([grip[0], grip[1] + 0.2777, grip[2] + 0.045, 1.0])
    shoulder = w0['r_bicep'][:3, 3]
    print(f'槍托後端中心（骨架空間）{vec(butt[:3])}；右肩關節 {vec(shoulder)}；'
          f'槍托在肩關節的 前 {(butt[1] - shoulder[1]) * 100:.1f}、右 {(butt[0] - shoulder[0]) * 100:.1f}、'
          f'上 {(butt[2] - shoulder[2]) * 100:.1f} 公分')

    render_preview(args.preview, anim, new[0], w0, ak_body, ak0,
                   [(g, (1.0, 0.85, 0.0)), (contact, (0.1, 0.75, 0.2))])
    return 0


if __name__ == '__main__':
    sys.exit(main())
