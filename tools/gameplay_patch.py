"""改原版主動畫圖 pc_gameplay.w2beh：直線走路、跑步拿十字弩時，兩隻手臂都用十字弩的動畫（雙手持槍），存到專案的 workspace。

用法：
    python -X utf8 tools/gameplay_patch.py           → 檢查原檔、寫出修改後的檔
    python -X utf8 tools/gameplay_patch.py --check   → 只檢查，不寫檔

- 原檔（唯讀）：<REDKIT_DEPOT>\\gameplay\\behaviors\\pc\\behaviorgraph\\pc_gameplay.w2beh
- 輸出：workspace\\gameplay\\behaviors\\pc\\behaviorgraph\\pc_gameplay.w2beh（= check out 再修改；同 tools/overlay_patch.py）
- 原因（docs/m3.md「雙手持槍：直線走路、跑步的右手」）：WalkAndRun（#25095）拿十字弩時用 BlendOverride 把十字弩的動畫蓋在走路、跑步上
  - 轉彎的 5 個節點（#25603、#25766、#25956、#28808、#28970、#29160）蓋 70 根：脊椎、頭、兩手臂（含手指、l_weapon、r_weapon）
  - 直線的 3 個節點只蓋左手臂 → 右手臂來自一般的走路、跑步動畫，會擺：
    - #27932 跑步（62 根：Root、IK、骨盆、脊椎、頭、腿、左手臂；覆蓋 ex_man_geralt_gabriel_aim_run 和坡度的兩段）
    - #26392 慢走、#27168 快走（38 根：脊椎、頭、左手臂；覆蓋 ex_man_gabriel_walk_cycle_slow_forward／fast_forward）
- 改法：這 3 個節點的骨頭表（屬性 'Bones with weights'）整個換成 #25956 的（同一個檔，名稱表的編號一樣，直接複製 bytes）
  - 跑步的腿、骨盆、位移改由一般跑步動畫負責（同轉彎時）；上半身用十字弩的動畫（我們換成雙手持槍的姿勢）
- 檔案結構（2026-10-16 讀原檔確認）：物件資料照物件表的順序連續排列、沒有 buffer（表 5 是空的）；
  檔頭第 6、7 個 u32 都是檔案大小 → 物件變大後：後面的物件位移往後挪、物件表更新大小／位移／校驗碼、檔頭兩個大小更新
- 校驗碼三層（同 tools/overlay_patch.py）：物件資料、物件表、檔頭（前 160 bytes，校驗碼欄位先填 0xDEADBEEF）
- 寫檔前檢查：原檔三層校驗碼都對；目標和來源節點的類別、骨頭數、來源有右手臂；物件資料連續、沒有 buffer、檔頭的兩個大小 = 檔案大小
- 寫完讀回來檢查：三層校驗碼；3 個節點的骨頭表和 #25956 一樣、其他屬性不變；其他物件的資料和原檔一樣；檔頭大小
- 輸出檔已經存在時：和要寫的一樣 → 不動；和原檔一樣（REDkit check out 的）→ 覆寫；其他 → 停止（不知道誰改過）
"""
import argparse
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cr2w_dump import Cr2wFile  # noqa: E402

PROJECT = Path(__file__).resolve().parent.parent
REL = Path('gameplay/behaviors/pc/behaviorgraph/pc_gameplay.w2beh')
SRC = Path(r'D:\Program Files (x86)\Steam\steamapps\common\The Witcher 3 REDkit\r4data') / REL
DST = PROJECT / 'workspace' / REL

CLASS = 'CBehaviorGraphBlendOverrideNode'
PROP = 'Bones with weights'
DONOR = 25956                                  # 轉彎跑步：70 根（脊椎、頭、兩手臂）
TARGETS = {27932: 62, 26392: 38, 27168: 38}    # 直線跑步、慢走、快走：原本的骨頭數
DONOR_COUNT = 70
RIGHT_ARM = ('r_shoulder', 'r_bicep', 'r_forearm', 'r_hand', 'r_weapon')

HEADER_SIZE = 160          # 檔頭 40 bytes ＋ 10 張表 × 12 bytes
HEADER_CRC = 32            # 檔頭校驗碼的位置
HEADER_CRC_FILL = 0xDEADBEEF
FILE_SIZE_FIELDS = (24, 28)  # 檔頭第 6、7 個 u32
EXPORT_TABLE = 4
BUFFER_TABLE = 5
EXPORT_ENTRY = 24


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


def find_prop(data: bytes, f: Cr2wFile, idx: int, prop: str) -> tuple[int, int]:
    """物件 #idx 的屬性 prop（含名稱、型別、大小的標頭）在物件資料裡的 (起點, 終點)，相對物件開頭。"""
    e = f.exports[idx]
    base, end = e['offset'], e['offset'] + e['size']
    pos = base + 1 if data[base] == 0 else base
    while pos + 2 <= end:
        name_id = struct.unpack_from('<H', data, pos)[0]
        if name_id == 0:
            break
        _type_id, size = struct.unpack_from('<HI', data, pos + 2)
        if f.names[name_id] == prop:
            return pos - base, pos + 4 + size - base
        pos += 4 + size
    raise ValueError(f'#{idx} 沒有屬性 {prop}')


def bone_names(f: Cr2wFile, idx: int) -> list[str]:
    props, _rest = f.read_export(idx)
    for name, _typ, value in props:
        if name == PROP:
            out = []
            for item in value:
                d = {k: v for k, _t, v in item.props}
                out.append(d.get('m_boneName'))
            return out
    raise ValueError(f'#{idx} 讀不到 {PROP}')


def check_source(data: bytes) -> Cr2wFile:
    """檢查原檔；不對就丟 ValueError。"""
    f = Cr2wFile(data)
    errors = check_crcs(data)
    if errors:
        raise ValueError('原檔的校驗碼算出來不對：' + '、'.join(errors))
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
    for idx, count in list(TARGETS.items()) + [(DONOR, DONOR_COUNT)]:
        if f.exports[idx]['class'] != CLASS:
            raise ValueError(f'#{idx} 是 {f.exports[idx]["class"]}，不是 {CLASS}')
        names = bone_names(f, idx)
        if len(names) != count:
            raise ValueError(f'#{idx} 的骨頭數 {len(names)}，預期 {count}')
    donor = bone_names(f, DONOR)
    if any(b not in donor for b in RIGHT_ARM):
        raise ValueError(f'#{DONOR} 沒有右手臂的骨頭')
    for idx in TARGETS:
        if any(b in bone_names(f, idx) for b in RIGHT_ARM):
            raise ValueError(f'#{idx} 已經有右手臂（不是原版的內容？）')
    return f


def patch(src: bytes, f: Cr2wFile) -> bytes:
    """換掉 3 個節點的骨頭表，重排物件資料，更新物件表、檔頭。"""
    ex = exports(src)
    d0, d1 = find_prop(src, f, DONOR, PROP)
    donor_off = ex[DONOR][4]
    donor_prop = src[donor_off + d0:donor_off + d1]
    blobs = []
    for i, e in enumerate(ex):
        blob = src[e[4]:e[4] + e[3]]
        if i in TARGETS:
            p0, p1 = find_prop(src, f, i, PROP)
            blob = blob[:p0] + donor_prop + blob[p1:]
        blobs.append(blob)
    first = ex[0][4]
    out = bytearray(src[:first])
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


def verify(src: bytes, out: bytes, f: Cr2wFile) -> None:
    errors = check_crcs(out)
    if errors:
        raise ValueError('寫出的檔校驗碼不對：' + '、'.join(errors))
    g = Cr2wFile(out)
    for field in FILE_SIZE_FIELDS:
        if struct.unpack_from('<I', out, field)[0] != len(out):
            raise ValueError(f'寫出的檔：檔頭第 {field} byte 不是檔案大小')
    donor = bone_names(f, DONOR)
    ex_src, ex_out = exports(src), exports(out)
    if len(ex_src) != len(ex_out):
        raise ValueError('物件數不同')
    for i, (a, b) in enumerate(zip(ex_src, ex_out)):
        if a[0] != b[0] or a[1] != b[1] or a[2] != b[2] or a[5] != b[5]:
            raise ValueError(f'#{i} 物件表的類別／旗標／父物件不同')
        old = src[a[4]:a[4] + a[3]]
        new = out[b[4]:b[4] + b[3]]
        if i in TARGETS:
            if bone_names(g, i) != donor:
                raise ValueError(f'#{i} 的骨頭表和 #{DONOR} 不一樣')
            p0, p1 = find_prop(src, f, i, PROP)
            q0, q1 = find_prop(out, g, i, PROP)
            if old[:p0] != new[:q0] or old[p1:] != new[q1:]:
                raise ValueError(f'#{i} 骨頭表以外的地方變了')
        elif old != new:
            raise ValueError(f'#{i} 的資料和原檔不同')
    # 字串、名稱、匯入等表格（物件表之前）和原檔一樣
    off, _count, _crc = table(src, EXPORT_TABLE)
    if out[HEADER_SIZE:off] != src[HEADER_SIZE:off]:
        raise ValueError('物件表之前的表格和原檔不同')
    grow = 0
    for i in TARGETS:
        p0, p1 = find_prop(src, f, i, PROP)
        q0, q1 = find_prop(out, g, i, PROP)
        grow += (q1 - q0) - (p1 - p0)
    if len(out) != len(src) + grow:
        raise ValueError(f'檔案大小 {len(out)}，預期 {len(src) + grow}')
    print(f'寫出的檔：{len(out)} bytes（原檔 {len(src)}，多 {grow}）；3 個節點的骨頭表 = #{DONOR}（{len(donor)} 根）；其他 {len(ex_out) - len(TARGETS)} 個物件的資料和原檔一樣；校驗碼三層都對')


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    p = argparse.ArgumentParser(description='pc_gameplay.w2beh：直線走路、跑步拿十字弩時兩隻手臂都蓋')
    p.add_argument('--check', action='store_true', help='只檢查，不寫檔')
    args = p.parse_args()
    if not SRC.is_file():
        print(f'找不到原檔：{SRC}')
        return 1
    src = SRC.read_bytes()
    try:
        f = check_source(src)
    except ValueError as err:
        print(f'原檔檢查失敗：{err}')
        return 1
    print(f'原檔檢查通過：{SRC}（{len(src)} bytes；校驗碼三層都對；目標 #{", #".join(map(str, TARGETS))}、來源 #{DONOR}）')
    out = patch(src, f)
    try:
        verify(src, out, f)
    except ValueError as err:
        print(f'檢查失敗，不寫檔：{err}')
        return 1
    if args.check:
        print('--check：不寫檔')
        return 0
    if DST.exists():
        cur = DST.read_bytes()
        if cur == out:
            print(f'輸出檔已經是這個內容：{DST}')
            return 0
        if cur != src:
            print(f'輸出檔已經存在、而且和原檔、要寫的內容都不同（不知道誰改過），不覆寫：{DST}')
            return 1
    DST.parent.mkdir(parents=True, exist_ok=True)
    DST.write_bytes(out)
    back = DST.read_bytes()
    if back != out:
        print('寫出後讀回來的內容不一樣')
        return 1
    verify(src, back, f)
    print(f'寫好了：{DST}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
