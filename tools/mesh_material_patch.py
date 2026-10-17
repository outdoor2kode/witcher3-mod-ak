"""改 .w2mesh 裡材質的數值參數（例：SpecularColor、RSpecScale、RSpecBase），原地改、重算校驗碼（第 23 項，2026-10-18）

用法：
    python -X utf8 tools/mesh_material_patch.py <w2mesh>... --list
    python -X utf8 tools/mesh_material_patch.py <w2mesh>... --material weapon_rif_ak47 --set SpecularColor=59,59,59 --set RSpecScale=0 --set RSpecBase=1 [--check]

- 只改已經有的參數；型別 Color（R,G,B；Alpha 不動）或 Float；值的長度不變 → 原地改，其他 bytes 不動
- 材質參數存在 CMaterialInstance 物件的自訂資料（屬性串列之後；tools/cr2w_dump.py 印成「+N bytes 自訂資料」）：
  - u32 數量；每筆：u32 大小（含自己 4 bytes）、u16 名稱、u16 型別、值
  - Color 的值是結構：1 個 0、Red／Green／Blue／Alpha 各一筆屬性（u16 名稱、u16 型別 Uint8、u32 大小 5、1 byte 值）、結束的 u16 0
  - 2026-10-18 讀 gfg_ak47.w2mesh 確認（材質 weapon_rif_ak47：Diffuse、Normal、SpecularColor 130、RSpecScale 1.5、RSpecBase -0.4）
- 材質名稱：CMesh（物件 0）的 materialNames 和 materials（handle）一一對應
- 校驗碼三層（同 tools/overlay_patch.py）：物件資料 → 物件表 → 檔頭（前 160 bytes，校驗碼欄位先填 0xDEADBEEF）
- 寫檔前檢查三層校驗碼都對；寫完讀回來檢查三層校驗碼、改的值
- 模型檔是 REDkit 匯入的產物（不進 git）；重新匯入時用 assets\\ak47\\ 的材質 XML（數值要和這裡一樣）
- 2026-10-18：改完重開 REDkit 後，遊戲裡生效（沒試過不重開）
"""
import argparse
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cr2w_dump import Cr2wFile, Ref  # noqa: E402

HEADER_SIZE = 160
HEADER_CRC = 32
HEADER_CRC_FILL = 0xDEADBEEF
EXPORT_TABLE = 4
EXPORT_ENTRY = 24
EXPORT_CRC = 20             # 物件表每筆的校驗碼位置


def crc(b: bytes) -> int:
    return zlib.crc32(b) & 0xFFFFFFFF


def table(data, i):
    return struct.unpack_from('<III', data, 40 + 12 * i)


def header_crc(data) -> int:
    head = bytearray(data[:HEADER_SIZE])
    struct.pack_into('<I', head, HEADER_CRC, HEADER_CRC_FILL)
    return crc(bytes(head))


def check_crcs(data) -> list:
    errors = []
    if struct.unpack_from('<I', data, HEADER_CRC)[0] != header_crc(data):
        errors.append('檔頭校驗碼')
    off, count, table_crc = table(data, EXPORT_TABLE)
    if crc(data[off:off + count * EXPORT_ENTRY]) != table_crc:
        errors.append('物件表校驗碼')
    for i in range(count):
        _c, _fl, _p, size, offset, _t, ocrc = struct.unpack_from('<HHIIIII', data, off + EXPORT_ENTRY * i)
        if crc(data[offset:offset + size]) != ocrc:
            errors.append(f'物件 #{i} 校驗碼')
    return errors


def string_array(b: bytes) -> list:
    """array:String 的原始 bytes（u32 數量、每個字串：長度前綴＋內容；格式同 cr2w_dump.read_string）"""
    count = struct.unpack_from('<I', b, 0)[0]
    pos, out = 4, []
    for _ in range(count):
        first = b[pos]
        length, pos = first & 0x3F, pos + 1
        if first & 0x40:
            shift = 6
            while True:
                c = b[pos]
                pos += 1
                length |= (c & 0x7F) << shift
                shift += 7
                if not c & 0x80:
                    break
        if first & 0x80:
            out.append(b[pos:pos + length].decode('utf-8'))
            pos += length
        else:
            out.append(b[pos:pos + 2 * length].decode('utf-16-le'))
            pos += 2 * length
    return out


def materials(f: Cr2wFile) -> dict:
    """材質名稱 → 物件編號"""
    props, _extra = f.read_export(0)
    d = dict((n, v) for n, _t, v in props)
    names, mats = d.get('materialNames'), d.get('materials')
    if hasattr(names, 'b'):
        names = string_array(names.b)
    if not isinstance(names, list) or not isinstance(mats, list) or len(names) != len(mats):
        raise SystemExit('讀不到 CMesh 的 materialNames／materials')
    out = {}
    for n, m in zip(names, mats):
        if isinstance(m, Ref) and f.exports[m.idx]['class'] == 'CMaterialInstance':
            out[n] = m.idx
    return out


def instance_params(f: Cr2wFile, idx: int) -> list:
    """[(名稱, 型別, 值的位置 dict)]；Float：{'v': 位置}；Color：{'Red': 位置, …}"""
    data = f.data
    exp = f.exports[idx]
    pos, end = exp['offset'], exp['offset'] + exp['size']
    if data[pos] == 0:
        pos += 1
    _props, pos = f.read_props(pos, end)
    count = struct.unpack_from('<I', data, pos)[0]
    pos += 4
    out = []
    for _ in range(count):
        size, name_id, type_id = struct.unpack_from('<IHH', data, pos)
        vstart, vend = pos + 8, pos + size
        name, tname = f.names[name_id], f.names[type_id]
        where = {}
        if tname == 'Float' and vend - vstart == 4:
            where['v'] = vstart
        elif tname == 'Color':
            p = vstart + 1 if data[vstart] == 0 else vstart
            while True:
                nid = struct.unpack_from('<H', data, p)[0]
                if nid == 0:
                    break
                tid, sz = struct.unpack_from('<HI', data, p + 2)   # 大小含自己 4 bytes
                if f.names[tid] == 'Uint8' and sz == 5:
                    where[f.names[nid]] = p + 8
                p += 4 + sz
        out.append((name, tname, where))
        pos = vend
    if pos != end:
        raise SystemExit(f'#{idx}：參數讀完的位置 {pos} 不是物件結尾 {end}')
    return out


def show(data, params) -> str:
    parts = []
    for name, tname, where in params:
        if 'v' in where:
            parts.append(f'{name}={struct.unpack_from("<f", data, where["v"])[0]:g}')
        elif 'Red' in where:
            parts.append(f'{name}=' + ','.join(str(data[where[c]]) for c in ('Red', 'Green', 'Blue', 'Alpha') if c in where))
        else:
            parts.append(f'{name}({tname})')
    return '  '.join(parts)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('files', nargs='+')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--material')
    ap.add_argument('--set', action='append', default=[])
    ap.add_argument('--check', action='store_true', help='只檢查、不寫檔')
    a = ap.parse_args()

    edits = []
    for s in a.set:
        k, v = s.split('=', 1)
        edits.append((k, [float(x) for x in v.split(',')]))

    for path in a.files:
        data = bytearray(Path(path).read_bytes())
        errs = check_crcs(data)
        if errs:
            print(path, '校驗碼不對，不改：', '、'.join(errs))
            return 1
        f = Cr2wFile(bytes(data))
        mats = materials(f)
        if a.list or not edits:
            for n, idx in mats.items():
                print(f'{Path(path).name}  {n} (#{idx})  {show(data, instance_params(f, idx))}')
            continue
        if a.material not in mats:
            print(path, '沒有材質', a.material, '；有：', list(mats))
            return 1
        idx = mats[a.material]
        params = {n: (t, w) for n, t, w in instance_params(f, idx)}
        before = show(data, instance_params(f, idx))
        for k, vals in edits:
            if k not in params:
                print(path, '材質沒有參數', k)
                return 1
            t, w = params[k]
            if 'v' in w and len(vals) == 1:
                struct.pack_into('<f', data, w['v'], vals[0])
            elif 'Red' in w and len(vals) == 3:
                for c, v in zip(('Red', 'Green', 'Blue'), vals):
                    if not 0 <= v <= 255 or v != int(v):
                        print('顏色要是 0～255 的整數：', k, vals)
                        return 1
                    data[w[c]] = int(v)
            else:
                print(path, '參數', k, '的型別', t, '和值', vals, '對不上')
                return 1
        # 校驗碼：物件 → 物件表 → 檔頭
        off, count, _tc = table(data, EXPORT_TABLE)
        e = f.exports[idx]
        struct.pack_into('<I', data, off + EXPORT_ENTRY * idx + EXPORT_CRC, crc(data[e['offset']:e['offset'] + e['size']]))
        struct.pack_into('<I', data, 40 + 12 * EXPORT_TABLE + 8, crc(data[off:off + count * EXPORT_ENTRY]))
        struct.pack_into('<I', data, HEADER_CRC, header_crc(data))
        errs = check_crcs(data)
        if errs:
            print(path, '改完校驗碼不對（不寫檔）：', errs)
            return 1
        after = show(data, instance_params(Cr2wFile(bytes(data)), idx))
        print(f'{Path(path).name}  {a.material}\n  前：{before}\n  後：{after}')
        if a.check:
            continue
        Path(path).write_bytes(bytes(data))
        back = Path(path).read_bytes()
        if back != bytes(data) or check_crcs(back):
            print(path, '寫回去讀出來不一樣')
            return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
