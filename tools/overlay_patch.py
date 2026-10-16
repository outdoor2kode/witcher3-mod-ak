"""改原版上半身動畫圖 pc_overlay.w2beh 的手臂覆蓋節點，存到專案的 workspace。

用法：
    python -X utf8 tools/overlay_patch.py            → 檢查原檔、寫出修改後的檔（手臂覆蓋版，2026-10-16 起的預設）
    python -X utf8 tools/overlay_patch.py --check    → 只檢查，不寫檔
    python -X utf8 tools/overlay_patch.py --legacy   → 舊版：只把曲線 #18561 改成 0（站著時不再蓋右手臂）
    python -X utf8 tools/overlay_patch.py --legacy --switch → 舊版＋實驗（失敗，見下）

- 原檔（唯讀）：<REDKIT_DEPOT>\\gameplay\\behaviors\\pc\\behaviorgraph\\pc_overlay.w2beh
- 輸出：workspace\\gameplay\\behaviors\\pc\\behaviorgraph\\pc_overlay.w2beh
  - 虛擬 depot 的優先順序 workspace > uncook > r4data；check out 就是把 r4data 的檔案複製到 workspace 的相同路徑
    （docs/findings.md §12.2）→ 這裡直接寫出「check out 再修改」的結果
- 改的節點都在十字弩瞄準區塊 AimAnimation（#17460）輸出前的手臂覆蓋（docs/m3.md「雙手持槍：右手臂被換成另一段動畫」）：
  - #18505（BlendOverride）：Base = 瞄準姿勢；Override = #18531 的動畫；Weight ← #18539 Damp ← #18543 Comparator
  - 原版：把右手臂換成 man_ger_sword_axii_arm_override（右肩 25%、上臂 50%、前臂 0%、手和手指 100%）；
    #18543（CF_Greater）：dampedMoveSpeed（#18547）> 0（移動中）→ 0；站著 → 曲線 #18554／#18561（輸入 playerWeaponForOverlay；
    沒武器、拳頭 0.75，鋼劍、銀劍 0）→ 原版十字弩是單手的，站著時給空著的右手一個姿勢
- 手臂覆蓋版（預設；2026-10-16 自主模式，使用者回報：衝刺時拿槍的姿勢很怪、跳躍落地瞬間變回持槍姿勢）：
  - 主動畫圖的衝刺、跳躍、落地沒有十字弩版本 → 手臂照衝刺、跳躍擺動，AK 跟著左手甩；落地後一格就跳回持槍
  - 改成「腳本把 inSlomoForOverlay 設成 1 時，兩手臂用雙手持槍的姿勢蓋住」（腳本：gfg_ak47.ws 的 GfgArmsHoldTick）
    - inSlomoForOverlay：動畫圖有宣告、接到十字弩狀態機 #17015 的 'inSlomo' 輸入（#17231 → #17229），但原版腳本從不設定、
      圖裡也沒有節點讀 'inSlomo' 的值（2026-10-16 查 pc_overlay.w2beh 全部物件）→ 借來當開關
  - #18531 animationName：man_ger_sword_axii_arm_override → man_geralt_gabriel_aim_idle_rp（我們的雙手持槍姿勢；名稱表裡原本就有）
  - #18505 骨頭表：右手臂 30 根 → 兩手臂 64 根（肩、上臂、前臂、手、手指、扭轉骨頭、l_weapon、r_weapon；權重都是 1；
    名稱、編號照主動畫圖 #25956 的 70 根扣掉 torso、torso2、torso3、neck、head、hroll）→ 胸口以上的脊椎照衝刺、跳躍的動作，
    兩手臂和 AK 跟著胸口
  - #18547 parentSocket：dampedMoveSpeed → inSlomo；cachedParentValueNode：#17078 → #17231
  - #18543 operation：CF_Greater → CF_LessEqual：inSlomo ≤ 0 → trueValue（沒存，預設 0）；> 0 → 曲線 #18554
  - 曲線 #18561 的 4 個點的值 → 全部 1（> 0 時不管拿什麼武器都是 1）
  - #18539 increaseSpeed：2 → 8（約 0.13 秒蓋上）；decreaseSpeed 2 不變（約 0.5 秒放開：落地、停止衝刺時慢慢回到持槍姿勢）
  - 骨頭表變長 → 物件變大：後面的物件位移往後挪、物件表更新、檔頭第 6、7 個 u32（檔案大小）更新（同 tools/gameplay_patch.py）
- 舊版（--legacy，2026-10-16 00:1x～）：只把曲線 #18561 的值 (0.75, 0, 0, 0.75) → 全部 0 → 站著時 #18505 的權重是 0
  - 曲線每個點 48 bytes：時間、值、兩個控制點（相對位移，各 4 個 float）、2 個 float；控制點是 (∓0.1, 0) → 只改值，斜率還是平的
  - --switch（2026-10-16 自主模式，雙手持槍的走路、跑步；**實驗失敗**）：比較節點 #18960 的 secondValue 1.0 → 0.0
    - #18960（CF_GreaterEqual：isInCombatActionForOverlay ≥ secondValue → 1；否則看 #18956 → … → fullBodyAnimWeight）
    - 遊戲實測（03:09）：按 W 角色完全不動 → 預設不改
- CR2W 的校驗碼（2026-10-16 用原檔驗證三層都對）：
  - 每個物件：物件資料的 CRC32，存在物件表每筆（24 bytes）的最後 4 bytes
  - 物件表：整張表的 CRC32，存在檔頭第 4 張表（從 0 數）的第 3 個欄位
  - 檔頭：前 160 bytes（檔頭 40 bytes ＋ 10 張表的位置、數量、校驗碼）的 CRC32；計算時第 32 byte 起的校驗碼欄位先填 0xDEADBEEF
- 寫檔前檢查：原檔的三層校驗碼都對；要改的節點的類別、原本的值和預期一樣；物件資料連續、沒有 buffer
- 寫完讀回來檢查：三層校驗碼；改的值；其他物件的資料和原檔一樣；物件表之前的表格和原檔一樣
- 輸出檔已經存在時：和要寫的內容一樣 → 不動；是原檔或這個工具的其他版本 → 換成這次的；其他 → 停止（不知道誰改過）
"""
import argparse
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cr2w_dump import Cr2wFile  # noqa: E402

PROJECT = Path(__file__).resolve().parent.parent
REL = Path('gameplay/behaviors/pc/behaviorgraph/pc_overlay.w2beh')
SRC = Path(r'D:\Program Files (x86)\Steam\steamapps\common\The Witcher 3 REDkit\r4data') / REL
DST = PROJECT / 'workspace' / REL

CURVE = 18561
CURVE_PARENT = 18554
EXPECT_TIMES = (0.0, 1.0, 2.0, 3.0)
EXPECT_VALUES = (0.75, 0.0, 0.0, 0.75)
LEGACY_VALUES = (0.0, 0.0, 0.0, 0.0)
ARMS_VALUES = (1.0, 1.0, 1.0, 1.0)

OVERRIDE = 18505            # BlendOverride
OVERRIDE_ANIM = 18531       # 覆蓋的動畫
WEIGHT_DAMP = 18539
WEIGHT_CMP = 18543
WEIGHT_INPUT = 18547
SLOMO_VAR = 17231           # Crossbow 區塊裡讀 inSlomoForOverlay 的變數節點
OLD_INPUT_CACHE = 17078
BONES_PROP = 'Bones with weights'
OLD_BONE_COUNT = 30
# 兩手臂：名稱、骨架編號（照 pc_gameplay.w2beh #25956 的 70 根扣掉 torso、torso2、torso3、neck、head、hroll）
ARM_BONES = (
    ('l_shoulder', 21), ('l_bicep', 22), ('l_forearm', 23), ('l_hand', 24), ('l_middle1', 25), ('l_middle2', 26),
    ('r_shoulder', 27), ('r_bicep', 28), ('r_forearm', 29), ('r_hand', 30), ('r_middle1', 31), ('r_middle2', 32),
    ('r_weapon', 33), ('l_weapon', 34),
    ('l_bicep2', 43), ('l_shoulderRoll', 44), ('l_elbowRoll', 45), ('l_forearmRoll1', 46), ('l_forearmRoll2', 47), ('l_handRoll', 48),
    ('r_bicep2', 49), ('r_elbowRoll', 50), ('r_forearmRoll1', 51), ('r_forearmRoll2', 52), ('r_handRoll', 53), ('r_shoulderRoll', 54),
    ('l_index1', 56), ('l_index2', 57), ('l_index3', 58), ('l_middle3', 59), ('l_pinky0', 60), ('l_pinky1', 61), ('l_pinky2', 62),
    ('l_pinky3', 63), ('l_ring1', 64), ('l_ring2', 65), ('l_ring3', 66), ('l_thumb1', 67), ('l_thumb2', 68), ('l_thumb3', 69),
    ('r_index1', 70), ('r_index2', 71), ('r_index3', 72), ('r_middle3', 73), ('r_pinky0', 74), ('r_pinky1', 75), ('r_pinky2', 76),
    ('r_pinky3', 77), ('r_ring1', 78), ('r_ring2', 79), ('r_ring3', 80), ('r_thumb1', 81), ('r_thumb2', 82), ('r_thumb3', 83),
    ('l_index_knuckleRoll', 84), ('l_middle_knuckleRoll', 85), ('l_pinky_knuckleRoll', 86), ('l_ring_knuckleRoll', 87),
    ('l_thumb_roll', 88), ('r_index_knuckleRoll', 89), ('r_middle_knuckleRoll', 90), ('r_pinky_knuckleRoll', 91),
    ('r_ring_knuckleRoll', 92), ('r_thumb_roll', 93),
)
# (物件, 屬性, 型別, 原本的值, 新的值)；CName／列舉存成名稱表的編號（2 bytes），ptr 存成「物件編號 + 1」（4 bytes）
NAME_EDITS = (
    (OVERRIDE_ANIM, 'animationName', 'man_ger_sword_axii_arm_override', 'man_geralt_gabriel_aim_idle_rp'),
    (WEIGHT_CMP, 'operation', 'CF_Greater', 'CF_LessEqual'),
    (WEIGHT_INPUT, 'parentSocket', 'dampedMoveSpeed', 'inSlomo'),
)
PTR_EDITS = ((WEIGHT_INPUT, 'cachedParentValueNode', OLD_INPUT_CACHE, SLOMO_VAR),)
FLOAT_EDITS = ((WEIGHT_DAMP, 'increaseSpeed', 2.0, 8.0),)
CLASSES = {
    OVERRIDE: 'CBehaviorGraphBlendOverrideNode', OVERRIDE_ANIM: 'CBehaviorGraphAnimationNode',
    WEIGHT_DAMP: 'CBehaviorGraphDampValueNode', WEIGHT_CMP: 'CBehaviorGraphComparatorNode',
    WEIGHT_INPUT: 'CBehaviorGraphParentValueInputNode', SLOMO_VAR: 'CBehaviorGraphVariableNode',
}

HEADER_SIZE = 160          # 檔頭 40 bytes ＋ 10 張表 × 12 bytes
HEADER_CRC = 32            # 檔頭校驗碼的位置
HEADER_CRC_FILL = 0xDEADBEEF
FILE_SIZE_FIELDS = (24, 28)  # 檔頭第 6、7 個 u32
EXPORT_TABLE = 4           # 物件表是第 4 張表
BUFFER_TABLE = 5
EXPORT_ENTRY = 24
POINT_START = 7            # 曲線的物件資料：1 個 0、屬性串列結束 2 bytes、點數 4 bytes
POINT_SIZE = 48

SWITCH = 18960
SWITCH_CLASS = 'CBehaviorGraphComparatorNode'
SWITCH_PROP = 'secondValue'
SWITCH_OLD = 1.0
SWITCH_NEW = 0.0


def crc(b: bytes) -> int:
    return zlib.crc32(b) & 0xFFFFFFFF


def table(data: bytes, i: int) -> tuple[int, int, int]:
    return struct.unpack_from('<III', data, 40 + 12 * i)


def header_crc(data: bytes) -> int:
    head = bytearray(data[:HEADER_SIZE])
    struct.pack_into('<I', head, HEADER_CRC, HEADER_CRC_FILL)
    return crc(bytes(head))


def exports(data: bytes) -> list[tuple]:
    off, count, _crc = table(data, EXPORT_TABLE)
    return [struct.unpack_from('<HHIIIII', data, off + EXPORT_ENTRY * i) for i in range(count)]


def check_crcs(data: bytes) -> list[str]:
    """三層校驗碼不對的地方；全對就是空的。"""
    errors = []
    if struct.unpack_from('<I', data, HEADER_CRC)[0] != header_crc(data):
        errors.append('檔頭校驗碼')
    off, count, table_crc = table(data, EXPORT_TABLE)
    if crc(data[off:off + count * EXPORT_ENTRY]) != table_crc:
        errors.append('物件表校驗碼')
    bad = [i for i, e in enumerate(exports(data)) if crc(data[e[4]:e[4] + e[3]]) != e[6]]
    if bad:
        errors.append(f'物件校驗碼（{len(bad)} 個，例：#{bad[0]}）')
    return errors


def curve_points(data: bytes, f: Cr2wFile) -> tuple[list[float], list[float], list[int]]:
    """曲線 #CURVE 每個點的時間、值，和值在檔案裡的位置。"""
    e = f.exports[CURVE]
    count = struct.unpack_from('<I', data, e['offset'] + POINT_START - 4)[0]
    if POINT_START + POINT_SIZE * count != e['size']:
        raise ValueError(f'#{CURVE} 的大小 {e["size"]} 和 {count} 個點對不上')
    starts = [e['offset'] + POINT_START + POINT_SIZE * k for k in range(count)]
    times = [struct.unpack_from('<f', data, p)[0] for p in starts]
    values = [struct.unpack_from('<f', data, p + 4)[0] for p in starts]
    return times, values, [p + 4 for p in starts]


def find_prop(data: bytes, f: Cr2wFile, idx: int, prop: str) -> tuple[int, str, int]:
    """物件 #idx 的屬性 prop：(值在檔案裡的位置, 型別名稱, 值的大小)。"""
    e = f.exports[idx]
    pos, end = e['offset'], e['offset'] + e['size']
    if data[pos] == 0:
        pos += 1
    while pos + 2 <= end:
        name_id = struct.unpack_from('<H', data, pos)[0]
        if name_id == 0:
            break
        type_id, size = struct.unpack_from('<HI', data, pos + 2)
        if f.names[name_id] == prop:
            return pos + 8, f.names[type_id], size - 4
        pos += 4 + size
    raise ValueError(f'#{idx} 沒有存 {prop}')


def prop_span(data: bytes, f: Cr2wFile, idx: int, prop: str) -> tuple[int, int]:
    """屬性（含名稱、型別、大小的標頭）在物件資料裡的 (起點, 終點)，相對物件開頭。"""
    value_pos, _typ, size = find_prop(data, f, idx, prop)
    base = f.exports[idx]['offset']
    return value_pos - 8 - base, value_pos + size - base


def read_name(data: bytes, f: Cr2wFile, idx: int, prop: str) -> str:
    pos, _typ, size = find_prop(data, f, idx, prop)
    if size != 2:
        raise ValueError(f'#{idx} 的 {prop} 大小 {size}，不是名稱')
    return f.names[struct.unpack_from('<H', data, pos)[0]]


def read_ptr(data: bytes, f: Cr2wFile, idx: int, prop: str) -> int:
    pos, typ, size = find_prop(data, f, idx, prop)
    if size != 4 or not typ.startswith('ptr:'):
        raise ValueError(f'#{idx} 的 {prop} 是 {typ}（大小 {size}），不是 ptr')
    return struct.unpack_from('<i', data, pos)[0] - 1


def read_float(data: bytes, f: Cr2wFile, idx: int, prop: str) -> float:
    pos, typ, size = find_prop(data, f, idx, prop)
    if typ != 'Float' or size != 4:
        raise ValueError(f'#{idx} 的 {prop} 是 {typ}（大小 {size}），不是 Float')
    return struct.unpack_from('<f', data, pos)[0]


def bone_list(f: Cr2wFile, idx: int) -> list[tuple[str, float, int]]:
    props, _rest = f.read_export(idx)
    for name, _typ, value in props:
        if name == BONES_PROP:
            out = []
            for item in value:
                d = {k: v for k, _t, v in item.props}
                out.append((d.get('m_boneName'), d.get('m_weight', 0.0), d.get('num')))
            return out
    raise ValueError(f'#{idx} 讀不到 {BONES_PROP}')


def encode_bones(f: Cr2wFile, src: bytes) -> bytes:
    """兩手臂的骨頭表（整個屬性，含標頭）；格式照原檔：每筆 1 個 0、m_boneName（String）、m_weight（Float）、num（Int32）、2 bytes 的 0。"""
    ids = {n: f.names.index(n) for n in ('m_boneName', 'm_weight', 'num', 'String', 'Float', 'Int32', BONES_PROP)}
    value_pos, typ, _size = find_prop(src, f, OVERRIDE, BONES_PROP)
    type_id = f.names.index(typ)
    body = bytearray(struct.pack('<I', len(ARM_BONES)))
    for name, num in ARM_BONES:
        raw = name.encode('ascii')
        if len(raw) >= 64:
            raise ValueError(f'骨頭名稱太長：{name}')
        body += b'\0'
        body += struct.pack('<HHI', ids['m_boneName'], ids['String'], 4 + 1 + len(raw)) + bytes([0x80 | len(raw)]) + raw
        body += struct.pack('<HHIf', ids['m_weight'], ids['Float'], 8, 1.0)
        body += struct.pack('<HHIi', ids['num'], ids['Int32'], 8, num)
        body += b'\0\0'
    return struct.pack('<HHI', ids[BONES_PROP], type_id, 4 + len(body)) + bytes(body)


def check_source(data: bytes) -> tuple[Cr2wFile, list[int]]:
    """檢查原檔；回傳 (解析結果, 曲線的值的位置)。不對就丟 ValueError。"""
    f = Cr2wFile(data)
    errors = check_crcs(data)
    if errors:
        raise ValueError('原檔的校驗碼算出來不對：' + '、'.join(errors) + '（算法和預期不同，不能改）')
    if table(data, BUFFER_TABLE)[1] != 0:
        raise ValueError('原檔有 buffer，這個工具沒處理')
    for field in FILE_SIZE_FIELDS:
        if struct.unpack_from('<I', data, field)[0] != len(data):
            raise ValueError(f'檔頭第 {field} byte 的值不是檔案大小')
    ex = exports(data)
    pos = ex[0][4]
    for i, e in enumerate(ex):
        if e[4] != pos:
            raise ValueError(f'物件資料不連續（#{i}）')
        pos += e[3]
    if pos != len(data):
        raise ValueError('最後一個物件的結尾不是檔案結尾')
    e = f.exports[CURVE]
    if e['class'] != 'CCurve' or e['parent'] != CURVE_PARENT or f.exports[CURVE_PARENT]['class'] != 'CBehaviorGraphCurveMapValueNode':
        raise ValueError(f'#{CURVE} 是 {e["class"]}（父物件 #{e["parent"]}），和預期的 CCurve（父物件 #{CURVE_PARENT}）不同')
    times, values, positions = curve_points(data, f)
    if tuple(round(t, 6) for t in times) != EXPECT_TIMES or tuple(round(v, 6) for v in values) != EXPECT_VALUES:
        raise ValueError(f'#{CURVE} 的點和預期不同：時間 {times}、值 {values}')
    if f.exports[SWITCH]['class'] != SWITCH_CLASS:
        raise ValueError(f'#{SWITCH} 是 {f.exports[SWITCH]["class"]}，不是 {SWITCH_CLASS}')
    if read_float(data, f, SWITCH, SWITCH_PROP) != SWITCH_OLD:
        raise ValueError(f'#{SWITCH} 的 {SWITCH_PROP} 不是 {SWITCH_OLD}')
    for idx, cls in CLASSES.items():
        if f.exports[idx]['class'] != cls:
            raise ValueError(f'#{idx} 是 {f.exports[idx]["class"]}，不是 {cls}')
    for idx, prop, old, new in NAME_EDITS:
        if read_name(data, f, idx, prop) != old:
            raise ValueError(f'#{idx} 的 {prop} 是 {read_name(data, f, idx, prop)}，不是 {old}')
        if new not in f.names:
            raise ValueError(f'名稱表裡沒有 {new}')
    for idx, prop, old, _new in PTR_EDITS:
        if read_ptr(data, f, idx, prop) != old:
            raise ValueError(f'#{idx} 的 {prop} 是 #{read_ptr(data, f, idx, prop)}，不是 #{old}')
    for idx, prop, old, _new in FLOAT_EDITS:
        if read_float(data, f, idx, prop) != old:
            raise ValueError(f'#{idx} 的 {prop} 是 {read_float(data, f, idx, prop)}，不是 {old}')
    if read_name(data, f, SLOMO_VAR, 'variableName') != 'inSlomoForOverlay':
        raise ValueError(f'#{SLOMO_VAR} 讀的變數不是 inSlomoForOverlay')
    bones = bone_list(f, OVERRIDE)
    if len(bones) != OLD_BONE_COUNT or bones[0][0] != 'r_shoulder' or any(b[0].startswith('l_') for b in bones):
        raise ValueError(f'#{OVERRIDE} 的骨頭表和預期的右手臂 {OLD_BONE_COUNT} 根不同')
    for name, num in ARM_BONES:
        if name.startswith('r_') and (name, num) not in [(b[0], b[2]) for b in bones] and name not in ('r_shoulderRoll', 'r_bicep2'):
            raise ValueError(f'右手臂的 {name} 編號和原檔對不上')
    return f, positions


def patch_legacy(src: bytes, f: Cr2wFile, positions: list[int], switch: bool) -> bytes:
    out = bytearray(src)
    for p, v in zip(positions, LEGACY_VALUES):
        struct.pack_into('<f', out, p, v)
    changed = [CURVE]
    if switch:
        struct.pack_into('<f', out, find_prop(src, f, SWITCH, SWITCH_PROP)[0], SWITCH_NEW)
        changed.append(SWITCH)
    off, count, _crc = table(src, EXPORT_TABLE)
    for idx in changed:
        e = f.exports[idx]
        struct.pack_into('<I', out, off + EXPORT_ENTRY * idx + 20, crc(bytes(out[e['offset']:e['offset'] + e['size']])))
    struct.pack_into('<I', out, 40 + 12 * EXPORT_TABLE + 8, crc(bytes(out[off:off + count * EXPORT_ENTRY])))
    struct.pack_into('<I', out, HEADER_CRC, header_crc(bytes(out)))
    return bytes(out)


def patch_arms(src: bytes, f: Cr2wFile, positions: list[int]) -> bytes:
    """手臂覆蓋版：原地改值，再換掉 #OVERRIDE 的骨頭表、重排物件資料。"""
    work = bytearray(src)
    for p, v in zip(positions, ARMS_VALUES):
        struct.pack_into('<f', work, p, v)
    for idx, prop, _old, new in NAME_EDITS:
        struct.pack_into('<H', work, find_prop(src, f, idx, prop)[0], f.names.index(new))
    for idx, prop, _old, new in PTR_EDITS:
        struct.pack_into('<i', work, find_prop(src, f, idx, prop)[0], new + 1)
    for idx, prop, _old, new in FLOAT_EDITS:
        struct.pack_into('<f', work, find_prop(src, f, idx, prop)[0], new)
    new_prop = encode_bones(f, src)
    ex = exports(src)
    blobs = []
    for i, e in enumerate(ex):
        blob = bytes(work[e[4]:e[4] + e[3]])
        if i == OVERRIDE:
            p0, p1 = prop_span(src, f, i, BONES_PROP)
            blob = blob[:p0] + new_prop + blob[p1:]
        blobs.append(blob)
    first = ex[0][4]
    out = bytearray(work[:first])
    off, count, _crc = table(src, EXPORT_TABLE)
    pos = first
    for i, (e, blob) in enumerate(zip(ex, blobs)):
        struct.pack_into('<HHIIIII', out, off + EXPORT_ENTRY * i, e[0], e[1], e[2], len(blob), pos, e[5], crc(blob))
        pos += len(blob)
    out += b''.join(blobs)
    for field in FILE_SIZE_FIELDS:
        struct.pack_into('<I', out, field, len(out))
    struct.pack_into('<I', out, 40 + 12 * EXPORT_TABLE + 8, crc(bytes(out[off:off + count * EXPORT_ENTRY])))
    struct.pack_into('<I', out, HEADER_CRC, header_crc(bytes(out)))
    return bytes(out)


def verify_legacy(src: bytes, out: bytes, f: Cr2wFile, positions: list[int], switch: bool) -> None:
    errors = check_crcs(out)
    if errors:
        raise ValueError('寫出的檔校驗碼不對：' + '、'.join(errors))
    _times, values, _pos = curve_points(out, Cr2wFile(out))
    if tuple(values) != LEGACY_VALUES:
        raise ValueError(f'寫出的檔曲線的值是 {values}')
    sw = find_prop(src, f, SWITCH, SWITCH_PROP)[0]
    want = SWITCH_NEW if switch else SWITCH_OLD
    if struct.unpack_from('<f', out, sw)[0] != want:
        raise ValueError(f'寫出的檔 #{SWITCH} 的 {SWITCH_PROP} 是 {struct.unpack_from("<f", out, sw)[0]}，應該是 {want}')
    off, _count, _crc = table(src, EXPORT_TABLE)
    allowed = set()
    for p in positions + ([sw] if switch else []):
        allowed.update(range(p, p + 4))
    for p in (off + EXPORT_ENTRY * CURVE + 20, 40 + 12 * EXPORT_TABLE + 8, HEADER_CRC) + ((off + EXPORT_ENTRY * SWITCH + 20,) if switch else ()):
        allowed.update(range(p, p + 4))
    if len(src) != len(out):
        raise ValueError('寫出的檔大小和原檔不同')
    diff = [i for i in range(len(src)) if src[i] != out[i]]
    if any(i not in allowed for i in diff):
        raise ValueError(f'和原檔差在預期以外的位置：{[i for i in diff if i not in allowed][:10]}')
    print(f'和原檔不同的 bytes：{len(diff)} 個（曲線的值' + (f'、#{SWITCH} 的 {SWITCH_PROP}' if switch else '') + '、物件和物件表、檔頭的校驗碼）')


def verify_arms(src: bytes, out: bytes, f: Cr2wFile) -> None:
    errors = check_crcs(out)
    if errors:
        raise ValueError('寫出的檔校驗碼不對：' + '、'.join(errors))
    for field in FILE_SIZE_FIELDS:
        if struct.unpack_from('<I', out, field)[0] != len(out):
            raise ValueError(f'寫出的檔：檔頭第 {field} byte 不是檔案大小')
    g = Cr2wFile(out)
    off, _count, _crc = table(src, EXPORT_TABLE)
    if out[HEADER_SIZE:off] != src[HEADER_SIZE:off]:
        raise ValueError('物件表之前的表格（字串、名稱等）和原檔不同')
    _times, values, _pos = curve_points(out, g)
    if tuple(values) != ARMS_VALUES:
        raise ValueError(f'曲線的值是 {values}')
    for idx, prop, _old, new in NAME_EDITS:
        if read_name(out, g, idx, prop) != new:
            raise ValueError(f'#{idx} 的 {prop} 是 {read_name(out, g, idx, prop)}')
    for idx, prop, _old, new in PTR_EDITS:
        if read_ptr(out, g, idx, prop) != new:
            raise ValueError(f'#{idx} 的 {prop} 是 #{read_ptr(out, g, idx, prop)}')
    for idx, prop, _old, new in FLOAT_EDITS:
        if read_float(out, g, idx, prop) != new:
            raise ValueError(f'#{idx} 的 {prop} 是 {read_float(out, g, idx, prop)}')
    bones = bone_list(g, OVERRIDE)
    if [(b[0], b[2]) for b in bones] != list(ARM_BONES) or any(b[1] != 1.0 for b in bones):
        raise ValueError(f'#{OVERRIDE} 的骨頭表和預期不同')
    changed = {CURVE, OVERRIDE} | {e[0] for e in NAME_EDITS} | {e[0] for e in PTR_EDITS} | {e[0] for e in FLOAT_EDITS}
    ex_src, ex_out = exports(src), exports(out)
    if len(ex_src) != len(ex_out):
        raise ValueError('物件數不同')
    for i, (a, b) in enumerate(zip(ex_src, ex_out)):
        if a[0] != b[0] or a[1] != b[1] or a[2] != b[2] or a[5] != b[5]:
            raise ValueError(f'#{i} 物件表的類別／旗標／父物件不同')
        old = src[a[4]:a[4] + a[3]]
        new = out[b[4]:b[4] + b[3]]
        if i == OVERRIDE:
            p0, p1 = prop_span(src, f, i, BONES_PROP)
            q0, q1 = prop_span(out, g, i, BONES_PROP)
            if old[:p0] != new[:q0] or old[p1:] != new[q1:]:
                raise ValueError(f'#{i} 骨頭表以外的地方變了')
        elif i in changed:
            if len(old) != len(new) or sum(x != y for x, y in zip(old, new)) > 4 * len(ARMS_VALUES):
                raise ValueError(f'#{i} 變的地方比預期多')
        elif old != new:
            raise ValueError(f'#{i} 的資料和原檔不同')
    p0, p1 = prop_span(src, f, OVERRIDE, BONES_PROP)
    q0, q1 = prop_span(out, g, OVERRIDE, BONES_PROP)
    grow = (q1 - q0) - (p1 - p0)
    if len(out) != len(src) + grow:
        raise ValueError(f'檔案大小 {len(out)}，預期 {len(src) + grow}')
    print(f'寫出的檔：{len(out)} bytes（原檔 {len(src)}，多 {grow}）；#{OVERRIDE} 骨頭表 {len(bones)} 根（兩手臂，權重 1）；'
          f'改值的物件 {sorted(changed - {OVERRIDE})}；其他物件的資料和原檔一樣；校驗碼三層都對')


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    p = argparse.ArgumentParser(description='pc_overlay.w2beh：十字弩瞄準區塊的手臂覆蓋')
    p.add_argument('--check', action='store_true', help='只檢查，不寫檔')
    p.add_argument('--legacy', action='store_true', help='舊版：只把曲線 #18561 改成 0')
    p.add_argument('--switch', action='store_true', help='（只配 --legacy）也改 #18960（實驗：移動時走站著的瞄準；實測角色不能移動）')
    args = p.parse_args()
    if args.switch and not args.legacy:
        print('--switch 只能和 --legacy 一起用')
        return 2
    if not SRC.is_file():
        print(f'找不到原檔：{SRC}')
        return 2
    src = SRC.read_bytes()
    try:
        f, positions = check_source(src)
        if args.legacy:
            out = patch_legacy(src, f, positions, args.switch)
            verify_legacy(src, out, f, positions, args.switch)
        else:
            out = patch_arms(src, f, positions)
            verify_arms(src, out, f)
    except ValueError as e:
        print(f'停止：{e}')
        return 1
    print(f'原檔：{SRC}（{len(src)} bytes，三層校驗碼都對）')
    print('版本：' + ('舊版（曲線改 0' + ('、#18960 實驗' if args.switch else '') + '）' if args.legacy else '手臂覆蓋版（inSlomoForOverlay ≥ 1 時兩手臂用雙手持槍姿勢）'))
    if args.check:
        print('只檢查（--check），沒有寫檔')
        return 0
    if DST.is_file():
        current = DST.read_bytes()
        if current == out:
            print(f'輸出檔已經是這個版本，沒有寫：{DST}')
            return 0
        known = (src, patch_legacy(src, f, positions, False), patch_legacy(src, f, positions, True), patch_arms(src, f, positions))
        if current not in known:
            print(f'停止：輸出檔已經存在，而且和原檔、這個工具的各版本都不同（不知道誰改過）：{DST}')
            return 1
    DST.parent.mkdir(parents=True, exist_ok=True)
    DST.write_bytes(out)
    back = DST.read_bytes()
    try:
        if args.legacy:
            verify_legacy(src, back, f, positions, args.switch)
        else:
            verify_arms(src, back, f)
    except ValueError as e:
        print(f'寫出後讀回來檢查失敗：{e}')
        return 1
    print(f'已存：{DST}（讀回來檢查過）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
