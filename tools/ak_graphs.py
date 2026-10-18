"""AK 專用的動畫圖、動畫組改名（第 25 項：原版十字弩不受 AK 影響；2026-10-18）

用法：
    python -X utf8 tools/ak_graphs.py              → 做 4 張 AK 專用的動畫圖（workspace\\dlc\\gunforgeralt\\data\\behaviors\\gfg_*.w2beh）
    python -X utf8 tools/ak_graphs.py --animset    → 另外把我們動畫組裡的動畫改名（man_ → gfg_；原地改，改過的不再改）
    python -X utf8 tools/ak_graphs.py --check      → 只檢查，不寫檔

為什麼（docs/findings.md §34）：
- 之前 AK 的 84 段動畫和原版十字弩的動畫同名，用 DLC 加到 Geralt 身上就蓋過原版；動畫圖 pc_overlay、pc_gameplay 也直接改原版
  → 原版十字弩也變成雙手持槍、腰扭（使用者 2026-10-18 回報）
- 改成：
  1. 我們動畫組裡的動畫改名：名稱裡第一個 'man_' 換成 'gfg_'（例：man_geralt_gabriel_aim_idle_rp → gfg_geralt_gabriel_aim_idle_rp、
     ex_man_geralt_gabriel_aim_run → ex_gfg_geralt_gabriel_aim_run）→ 不再蓋過原版
  2. 原版的 4 張動畫圖各做一份 AK 專用的複本：原版（＋之前的修改：overlay_patch.py、gameplay_patch.py）＋同樣的改名
     → 複本裡的十字弩節點播我們的動畫；原版的圖、動畫都不動
  3. 腳本（gfg_ak47.ws）裝上 AK 時把玩家這 4 個動畫圖 slot 的圖換成複本、重新啟用；換成別的十字弩時換回原版
- 改名只換名稱表：名稱字串同長度直接換、名稱的雜湊重算、字串表和名稱表的校驗碼、檔頭校驗碼重算；物件資料不動（CName 存的是名稱表的編號）
  - 名稱的雜湊：FNV-1a 32，算到結尾的 0（空名稱是 0）；2026-10-18 用 pc_rider.w2beh 的名稱表驗證
  - 表 0（字串）、表 1（名稱）的校驗碼：整張表的 CRC32（同物件表；2026-10-18 用 pc_rider.w2beh 驗證）
  - 動畫組裡同樣的字串另外出現在 importFile（匯入來源的路徑，String）：只是紀錄，不改

要改名的名稱：動畫組裡的動畫（CSkeletalAnimation 的 name）；改過的（gfg_）換回 man_ 當作原版的名稱
- 例外：物品欄預覽的 5 段（第 24 項，tools/inv_pose.py）：原版名稱 inventory_*，AK 的 gfg_akinv_*（INV_NAMES）
  → 只用在物品欄預覽的圖（gfg_inventory.w2beh），不參與 man_／gfg_ 的改名
- 以後在 REDkit 匯入新動畫：檔名用 gfg_ 開頭（例：gfg_geralt_gabriel_aim_idle_rp.re），同名覆蓋；
  用 man_ 開頭匯入會多一段蓋過原版的動畫 → 這個工具會停下來（同一個名稱改名後重複）
"""
import argparse
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cr2w_dump import Cr2wFile  # noqa: E402
import overlay_patch  # noqa: E402
import gameplay_patch  # noqa: E402

PROJECT = Path(__file__).resolve().parent.parent
R4DATA = Path(r'D:\Program Files (x86)\Steam\steamapps\common\The Witcher 3 REDkit\r4data')
PC_GRAPHS = Path('gameplay/behaviors/pc/behaviorgraph')
OUT_DIR = PROJECT / 'workspace' / 'dlc' / 'gunforgeralt' / 'data' / 'behaviors'
ANIMSET = PROJECT / 'workspace' / 'dlc' / 'gunforgeralt' / 'data' / 'animations' / 'gfg_ak47_geralt.w2anims'

HEADER_SIZE = 160
HEADER_CRC = 32
HEADER_CRC_FILL = 0xDEADBEEF
STRING_TABLE = 0
NAME_TABLE = 1
NAME_ENTRY = 8


def crc(b: bytes) -> int:
    return zlib.crc32(b) & 0xFFFFFFFF


def table(data: bytes, i: int) -> tuple[int, int, int]:
    return struct.unpack_from('<III', data, 40 + 12 * i)


def header_crc(data: bytes) -> int:
    head = bytearray(data[:HEADER_SIZE])
    struct.pack_into('<I', head, HEADER_CRC, HEADER_CRC_FILL)
    return crc(bytes(head))


def name_hash(raw: bytes) -> int:
    if not raw:
        return 0
    h = 0x811C9DC5
    for x in raw + b'\0':
        h = ((h ^ x) * 0x01000193) & 0xFFFFFFFF
    return h


# 物品欄預覽（第 24 項）：原版 → AK（同長度）
INV_NAMES = {n: 'gfg_akinv_' + n[len('inventory_'):] for n in (
    'inventory_unsheathe_crossbow', 'inventory_crossbow_idle', 'inventory_crossbow_check1',
    'inventory_crossbow_to_noequipment', 'inventory_sheathe_crossbow')}


def ak_name(vanilla: str) -> str:
    """原版名稱 → AK 的名稱（第一個 'man_' 換成 'gfg_'，長度不變）"""
    i = vanilla.index('man_')
    return vanilla[:i] + 'gfg_' + vanilla[i + 4:]


def vanilla_name(name: str) -> str:
    """動畫組裡的名稱（改過或沒改過）→ 原版名稱"""
    if 'gfg_' in name and ('man_' not in name or name.index('gfg_') < name.index('man_')):
        i = name.index('gfg_')
        return name[:i] + 'man_' + name[i + 4:]
    return name


def name_entries(data: bytes) -> list[tuple[int, bytes, int]]:
    """名稱表：（字串在字串表裡的位置, 字串 bytes, 雜湊）"""
    so, ss, _ = table(data, STRING_TABLE)
    no, nc, _ = table(data, NAME_TABLE)
    out = []
    for i in range(nc):
        off, h = struct.unpack_from('<II', data, no + NAME_ENTRY * i)
        end = data.index(b'\0', so + off)
        out.append((off, data[so + off:end], h))
    return out


def check_name_tables(data: bytes) -> list[str]:
    """字串表、名稱表的校驗碼和每個名稱的雜湊；全對就是空的"""
    errors = []
    so, ss, sc = table(data, STRING_TABLE)
    if crc(data[so:so + ss]) != sc:
        errors.append('字串表校驗碼')
    no, nc, ncrc = table(data, NAME_TABLE)
    if crc(data[no:no + NAME_ENTRY * nc]) != ncrc:
        errors.append('名稱表校驗碼')
    bad = [raw for _off, raw, h in name_entries(data) if name_hash(raw) != h]
    if bad:
        errors.append(f'名稱雜湊（{len(bad)} 個，例：{bad[0]!r}）')
    if struct.unpack_from('<I', data, HEADER_CRC)[0] != header_crc(data):
        errors.append('檔頭校驗碼')
    return errors


def rename(data: bytes, mapping: dict[str, str]) -> tuple[bytes, list[str]]:
    """名稱表裡出現的舊名稱換成新名稱（同長度）；回傳（新檔, 換掉的舊名稱）。不對就丟 ValueError"""
    d = bytearray(data)
    so, ss, _ = table(data, STRING_TABLE)
    no, nc, _ = table(data, NAME_TABLE)
    entries = name_entries(data)
    existing = {raw.decode('utf-8') for _off, raw, _h in entries}
    # 匯入（表 2）的路徑字串也在字串表裡：改名的字串不能和它們共用
    io, ic, _ = table(data, 2)
    other_offsets = {struct.unpack_from('<I', data, io + 8 * i)[0] for i in range(ic)}
    renamed = []
    for i, (off, raw, _h) in enumerate(entries):
        name = raw.decode('utf-8')
        if name not in mapping:
            continue
        new = mapping[name].encode('utf-8')
        if len(new) != len(raw):
            raise ValueError(f'長度不同：{name} → {mapping[name]}')
        if mapping[name] in existing:
            raise ValueError(f'新名稱已經在名稱表裡（會重複）：{mapping[name]}')
        span = range(off, off + len(raw) + 1)
        shared = [o for o in other_offsets if o in span]
        shared += [o for j, (o, _r, _x) in enumerate(entries) if j != i and o in span]
        if shared:
            raise ValueError(f'{name} 的字串和其他名稱或路徑共用（位置 {shared[:3]}）')
        d[so + off:so + off + len(raw)] = new
        struct.pack_into('<I', d, no + NAME_ENTRY * i + 4, name_hash(new))
        renamed.append(name)
    struct.pack_into('<I', d, 40 + 12 * STRING_TABLE + 8, crc(bytes(d[so:so + ss])))
    struct.pack_into('<I', d, 40 + 12 * NAME_TABLE + 8, crc(bytes(d[no:no + NAME_ENTRY * nc])))
    struct.pack_into('<I', d, HEADER_CRC, header_crc(bytes(d)))
    return bytes(d), renamed


def verify_rename(before: bytes, after: bytes, mapping: dict[str, str]) -> None:
    """改名前後：只差在字串表、名稱表的雜湊和三個校驗碼；名稱 = 舊名稱照 mapping 換掉；校驗碼都對"""
    if len(before) != len(after):
        raise ValueError('檔案大小變了')
    errors = check_name_tables(after) + overlay_patch.check_crcs(after)
    if errors:
        raise ValueError('改名後的校驗碼不對：' + '、'.join(errors))
    so, ss, _ = table(before, STRING_TABLE)
    no, nc, _ = table(before, NAME_TABLE)
    allowed = set(range(so, so + ss)) | {no + NAME_ENTRY * i + k for i in range(nc) for k in range(4, 8)}
    allowed |= {HEADER_CRC + k for k in range(4)} | {40 + 12 * t + 8 + k for t in (STRING_TABLE, NAME_TABLE) for k in range(4)}
    diff = [i for i in range(len(before)) if before[i] != after[i] and i not in allowed]
    if diff:
        raise ValueError(f'字串表、名稱表以外的地方也變了（位置 {diff[:5]}）')
    want = [mapping.get(n, n) for n in Cr2wFile(before).names]
    if Cr2wFile(after).names != want:
        raise ValueError('名稱表和預期的不一樣')


def animset_names(data: bytes) -> list[str]:
    f = Cr2wFile(data)
    names = []
    for i, e in enumerate(f.exports):
        if e['class'] != 'CSkeletalAnimation':
            continue
        props, _extra = f.read_export(i)
        for prop, _type, value in props:
            if prop == 'name':
                names.append(value)
    return names


def patch_overlay(src: bytes) -> bytes:
    f, positions = overlay_patch.check_source(src)
    out = overlay_patch.patch_arms(src, f, positions)
    overlay_patch.verify_arms(src, out, f)
    return out


def patch_gameplay(src: bytes) -> bytes:
    f = gameplay_patch.check_source(src)
    out = gameplay_patch.patch(src, f)
    gameplay_patch.verify(src, out, f)
    return out


# （輸出檔名, 原版的圖, 之前對原版的修改, 改名的對照：None = 動畫組的 man_ → gfg_）；腳本裡的路徑要一樣（gfg_ak47.ws 的 GfgAkGraphPath）
GRAPHS = (
    ('gfg_overlay.w2beh', 'pc_overlay.w2beh', patch_overlay, None),     # PlayerOverlay：上半身（瞄準、射擊、換彈）
    ('gfg_gameplay.w2beh', 'pc_gameplay.w2beh', patch_gameplay, None),  # Gameplay：主動畫圖（走跑）
    ('gfg_rider.w2beh', 'pc_rider.w2beh', None, None),                  # VehicleHorse：騎馬
    ('gfg_swimming.w2beh', 'pc_swimming.w2beh', None, None),            # PlayerSwimming：游泳、潛水
    ('gfg_inventory.w2beh', 'pc_inventory.w2beh', None, INV_NAMES),     # 物品欄預覽人物的 Inventory（第 24 項）
)


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    p = argparse.ArgumentParser(description='AK 專用的動畫圖、動畫組改名')
    p.add_argument('--animset', action='store_true', help='也把動畫組裡的動畫改名（原地改）')
    p.add_argument('--check', action='store_true', help='只檢查，不寫檔')
    args = p.parse_args()

    anim_data = ANIMSET.read_bytes()
    errors = check_name_tables(anim_data) + overlay_patch.check_crcs(anim_data)
    if errors:
        print('停止：動畫組的校驗碼不對：' + '、'.join(errors))
        return 1
    current = [n for n in animset_names(anim_data) if n not in INV_NAMES.values()]
    vanilla = sorted({vanilla_name(n) for n in current})
    if len(vanilla) != len(current):
        print('停止：動畫組裡同一段動畫有原版名稱和 gfg_ 名稱兩筆（用 man_ 開頭的檔名匯入過？）：'
              + ', '.join(n for n in current if vanilla_name(n) != n and vanilla_name(n) in current))
        return 1
    bad = [n for n in vanilla if 'man_' not in n]
    if bad:
        print('停止：這些動畫的名稱裡沒有 man_，不知道怎麼改：' + ', '.join(bad))
        return 1
    mapping = {n: ak_name(n) for n in vanilla}
    print(f'動畫組：{len(current)} 段（還是原版名稱的 {sum(1 for n in current if n in mapping)} 段）')

    outputs = []
    for out_name, src_name, patcher, names in GRAPHS:
        names = names or mapping
        src_path = R4DATA / PC_GRAPHS / src_name
        src = src_path.read_bytes()
        try:
            base = patcher(src) if patcher else src
            errors = check_name_tables(base) + overlay_patch.check_crcs(base)
            if errors:
                raise ValueError('改名前的校驗碼不對：' + '、'.join(errors))
            out, renamed = rename(base, names)
            verify_rename(base, out, names)
        except ValueError as e:
            print(f'停止（{src_name}）：{e}')
            return 1
        print(f'{src_name}：{"套用之前的修改、" if patcher else ""}改名 {len(renamed)} 個 → {out_name}')
        outputs.append((OUT_DIR / out_name, out))

    anim_out = None
    if args.animset:
        try:
            anim_out, renamed = rename(anim_data, mapping)
            if renamed:
                verify_rename(anim_data, anim_out, mapping)
        except ValueError as e:
            print(f'停止（動畫組）：{e}')
            return 1
        print(f'動畫組：改名 {len(renamed)} 段' + ('' if renamed else '（都改過了）'))
        if not renamed:
            anim_out = None

    if args.check:
        print('--check：不寫檔')
        return 0
    for path, data in outputs:
        if path.is_file() and path.read_bytes() == data:
            print(f'沒變：{path}')
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        if path.read_bytes() != data:
            print(f'寫出後讀回來不一樣：{path}')
            return 1
        print(f'已存：{path}')
    if anim_out is not None:
        ANIMSET.write_bytes(anim_out)
        back = ANIMSET.read_bytes()
        if back != anim_out or check_name_tables(back) or overlay_patch.check_crcs(back):
            print(f'動畫組寫出後讀回來檢查失敗：{ANIMSET}')
            return 1
        print(f'已存：{ANIMSET}（讀回來檢查過）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
