"""把原版上半身動畫圖 pc_overlay.w2beh 的「站著時右手臂被換成另一段動畫」關掉，存到專案的 workspace。

用法：
    python -X utf8 tools/overlay_patch.py           → 檢查原檔、寫出修改後的檔
    python -X utf8 tools/overlay_patch.py --check   → 只檢查，不寫檔

- 原檔（唯讀）：<REDKIT_DEPOT>\\gameplay\\behaviors\\pc\\behaviorgraph\\pc_overlay.w2beh
- 輸出：workspace\\gameplay\\behaviors\\pc\\behaviorgraph\\pc_overlay.w2beh
  - 虛擬 depot 的優先順序 workspace > uncook > r4data；check out 就是把 r4data 的檔案複製到 workspace 的相同路徑
    （docs/findings.md §12.2）→ 這裡直接寫出「check out 再修改」的結果
- 改的東西（docs/m3.md「雙手持槍：右手臂被換成另一段動畫」）：曲線 #18561 的 4 個點的值 (0.75, 0, 0, 0.75) → 全部 0
  - #18561 只被 #18554（CurveMapValue）的 curve 用到；#18554 → #18543（Comparator 的 False）→ #18539（Damp）→ #18505 的 Weight
  - #18505（BlendOverride）是十字弩瞄準區塊 AimAnimation 輸出前的最後一步：把右手臂換成 man_ger_sword_axii_arm_override
    （右肩 25%、上臂 50%、前臂 0%、手和手指 100%）
  - #18543：移動中（dampedMoveSpeed > 0）是 0；站著時才看曲線
  - 曲線的輸入是 playerWeaponForOverlay（EPlayerWeapon：PW_None、PW_Steel、PW_Silver、PW_Fists，playerTypes.ws:795-801）
    → 沒武器、拳頭 0.75；鋼劍、銀劍 0
  - 曲線每個點 48 bytes：時間、值、兩個控制點（相對位移，各 4 個 float）、2 個 float；控制點是 (∓0.1, 0) → 只改值，斜率還是平的
- CR2W 的校驗碼（2026-10-16 用原檔驗證三層都對）：
  - 每個物件：物件資料的 CRC32，存在物件表每筆（24 bytes）的最後 4 bytes
  - 物件表：整張表的 CRC32，存在檔頭第 4 張表（從 0 數）的第 3 個欄位
  - 檔頭：前 160 bytes（檔頭 40 bytes ＋ 10 張表的位置、數量、校驗碼）的 CRC32；計算時第 32 byte 起的校驗碼欄位先填 0xDEADBEEF
- 寫檔前檢查：原檔的三層校驗碼都對；#18561 是 CCurve、父物件是 #18554 CBehaviorGraphCurveMapValueNode；4 個點的時間、值和預期一樣
- 輸出檔已經存在時：和要寫的內容一樣 → 不動；和原檔一樣（REDkit check out 的）→ 覆寫；其他 → 停止，不寫（不知道誰改過）
- 寫完讀回來檢查：三層校驗碼、曲線的值、和原檔只差預期的位置
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
NEW_VALUES = (0.0, 0.0, 0.0, 0.0)

HEADER_SIZE = 160          # 檔頭 40 bytes ＋ 10 張表 × 12 bytes
HEADER_CRC = 32            # 檔頭校驗碼的位置
HEADER_CRC_FILL = 0xDEADBEEF
EXPORT_TABLE = 4           # 物件表是第 4 張表
EXPORT_ENTRY = 24
POINT_START = 7            # 物件資料：1 個 0、屬性串列結束 2 bytes、點數 4 bytes
POINT_SIZE = 48


def crc(b: bytes) -> int:
    return zlib.crc32(b) & 0xFFFFFFFF


def table(data: bytes, i: int) -> tuple[int, int, int]:
    return struct.unpack_from('<III', data, 40 + 12 * i)


def header_crc(data: bytes) -> int:
    head = bytearray(data[:HEADER_SIZE])
    struct.pack_into('<I', head, HEADER_CRC, HEADER_CRC_FILL)
    return crc(bytes(head))


def check_crcs(data: bytes) -> list[str]:
    """三層校驗碼不對的地方；全對就是空的。"""
    errors = []
    if struct.unpack_from('<I', data, HEADER_CRC)[0] != header_crc(data):
        errors.append('檔頭校驗碼')
    off, count, table_crc = table(data, EXPORT_TABLE)
    if crc(data[off:off + count * EXPORT_ENTRY]) != table_crc:
        errors.append('物件表校驗碼')
    bad = []
    for i in range(count):
        _cls, _flags, _parent, size, offset, _tmpl, obj_crc = struct.unpack_from('<HHIIIII', data, off + EXPORT_ENTRY * i)
        if crc(data[offset:offset + size]) != obj_crc:
            bad.append(i)
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


def check_source(data: bytes) -> tuple[Cr2wFile, list[int]]:
    """檢查原檔；回傳 (解析結果, 值的位置)。不對就丟 ValueError。"""
    f = Cr2wFile(data)
    errors = check_crcs(data)
    if errors:
        raise ValueError('原檔的校驗碼算出來不對：' + '、'.join(errors) + '（算法和預期不同，不能改）')
    e = f.exports[CURVE]
    if e['class'] != 'CCurve' or e['parent'] != CURVE_PARENT or f.exports[CURVE_PARENT]['class'] != 'CBehaviorGraphCurveMapValueNode':
        raise ValueError(f'#{CURVE} 是 {e["class"]}（父物件 #{e["parent"]}），和預期的 CCurve（父物件 #{CURVE_PARENT}）不同')
    times, values, positions = curve_points(data, f)
    if tuple(round(t, 6) for t in times) != EXPECT_TIMES or tuple(round(v, 6) for v in values) != EXPECT_VALUES:
        raise ValueError(f'#{CURVE} 的點和預期不同：時間 {times}、值 {values}')
    return f, positions


def patch(src: bytes, f: Cr2wFile, positions: list[int]) -> bytes:
    out = bytearray(src)
    for p, v in zip(positions, NEW_VALUES):
        struct.pack_into('<f', out, p, v)
    off, count, _crc = table(src, EXPORT_TABLE)
    e = f.exports[CURVE]
    struct.pack_into('<I', out, off + EXPORT_ENTRY * CURVE + 20, crc(bytes(out[e['offset']:e['offset'] + e['size']])))
    struct.pack_into('<I', out, 40 + 12 * EXPORT_TABLE + 8, crc(bytes(out[off:off + count * EXPORT_ENTRY])))
    struct.pack_into('<I', out, HEADER_CRC, header_crc(bytes(out)))
    return bytes(out)


def verify(src: bytes, out: bytes, f: Cr2wFile, positions: list[int]) -> None:
    errors = check_crcs(out)
    if errors:
        raise ValueError('寫出的檔校驗碼不對：' + '、'.join(errors))
    _times, values, _pos = curve_points(out, Cr2wFile(out))
    if tuple(values) != NEW_VALUES:
        raise ValueError(f'寫出的檔曲線的值是 {values}')
    off, _count, _crc = table(src, EXPORT_TABLE)
    allowed = set()
    for p in positions:
        allowed.update(range(p, p + 4))
    for p in (off + EXPORT_ENTRY * CURVE + 20, 40 + 12 * EXPORT_TABLE + 8, HEADER_CRC):
        allowed.update(range(p, p + 4))
    if len(src) != len(out):
        raise ValueError('寫出的檔大小和原檔不同')
    diff = [i for i in range(len(src)) if src[i] != out[i]]
    if any(i not in allowed for i in diff):
        raise ValueError(f'和原檔差在預期以外的位置：{[i for i in diff if i not in allowed][:10]}')
    print(f'和原檔不同的 bytes：{len(diff)} 個（曲線的值、#{CURVE} 的校驗碼、物件表校驗碼、檔頭校驗碼）')


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    p = argparse.ArgumentParser(description='關掉 pc_overlay.w2beh 站著時的右手臂覆蓋')
    p.add_argument('--check', action='store_true', help='只檢查，不寫檔')
    args = p.parse_args()
    if not SRC.is_file():
        print(f'找不到原檔：{SRC}')
        return 2
    src = SRC.read_bytes()
    try:
        f, positions = check_source(src)
        out = patch(src, f, positions)
        verify(src, out, f, positions)
    except ValueError as e:
        print(f'停止：{e}')
        return 1
    print(f'原檔：{SRC}（{len(src)} bytes，三層校驗碼都對）')
    print(f'#{CURVE} 曲線的值：{EXPECT_VALUES} → {NEW_VALUES}')
    if args.check:
        print('只檢查（--check），沒有寫檔')
        return 0
    if DST.is_file():
        current = DST.read_bytes()
        if current == out:
            print(f'輸出檔已經是修改後的版本，沒有寫：{DST}')
            return 0
        if current != src:
            print(f'停止：輸出檔已經存在，而且和原檔、修改後的版本都不同（不知道誰改過）：{DST}')
            return 1
    DST.parent.mkdir(parents=True, exist_ok=True)
    DST.write_bytes(out)
    back = DST.read_bytes()
    try:
        verify(src, back, f, positions)
    except ValueError as e:
        print(f'寫出後讀回來檢查失敗：{e}')
        return 1
    print(f'已存：{DST}（讀回來檢查過）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
