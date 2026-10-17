"""巫師3 的聲音封存檔 soundspc.cache（CS3W 第 2 版）：列出、取出、檢查、打包（第 22 項，2026-10-18）

用法：
    python -X utf8 tools/sound_cache.py <soundspc.cache> --list [萬用字元…]
    python -X utf8 tools/sound_cache.py <soundspc.cache> --extract <輸出資料夾> <萬用字元>…
    python -X utf8 tools/sound_cache.py <soundspc.cache> --verify
    python -X utf8 tools/sound_cache.py <輸出的 soundspc.cache> --pack <檔案>…

    例（裝進遊戲時：mod 的聲音放 mods\\<mod>\\content\\soundspc.cache）：
    python -X utf8 tools/sound_cache.py packed/mods/modgunforgeralt/content/soundspc.cache --pack workspace/soundbanks/pc/gfg_ak47.bnk

格式（2026-10-18 讀 <W3_GAME_DIR>\\content\\content0\\soundspc.cache 對出來的）：
- 檔頭 64 bytes：'CS3W'、u32 版本（2）、u64（不明，像時間）、u64 檔案表位置、u64 檔案數、u64 名稱表位置、
  u32 名稱表大小（= 檔案表位置 − 名稱表位置）、u32（不明；原版 186）、u64 最大的檔案大小進位到 4096 的倍數、u64 校驗碼
- 校驗碼：FNV-1a 64 位元，算「名稱表＋檔案表」（WolvenKit-7 的 Sound_Cache.cs CalculateChecksum；用原版的檔驗證過）；
  遊戲會檢查（wcc_lite／editor.exe 的字串「Sound cache index file is corrupted: CRC error」）
- 資料從第 64 byte 開始，一個接一個、不對齊；接著名稱表、檔案表（到檔尾）
- 名稱表：以 0 結尾的字串（例：amb_bob_bg_01.bnk、123456.wem）
- 檔案表：每筆 24 bytes：u64 名稱位置（相對名稱表）、u64 資料位置、u64 大小
- 打包時兩個不明的欄位照抄原版（第 8 byte 的 u64、第 44 byte 的 u32）：意思不明，讀取的程式看來只檢查表格範圍、校驗碼
"""
import fnmatch
import os
import struct
import sys

UNKNOWN_8 = 0x05e3e6c97ea49400  # 原版 content0 的值
UNKNOWN_44 = 186                # 原版 content0 的值


def fnv1a64(data):
    h = 0xcbf29ce484222325
    for b in data:
        h ^= b
        h = (h * 0x100000001b3) & 0xffffffffffffffff
    return h


def read_tables(path):
    """回傳（檔頭、名稱表、檔案表）的 bytes"""
    with open(path, 'rb') as f:
        h = f.read(64)
        if h[:4] != b'CS3W':
            raise SystemExit('不是 CS3W')
        version = struct.unpack_from('<I', h, 4)[0]
        if version != 2:
            raise SystemExit(f'版本 {version}，只看過第 2 版')
        info_off, count, names_off = struct.unpack_from('<QQQ', h, 16)
        names_size = struct.unpack_from('<I', h, 40)[0]
        f.seek(names_off)
        names = f.read(names_size)
        f.seek(info_off)
        table = f.read(24 * count)
    if info_off + 24 * count != os.path.getsize(path):
        print('注意：檔案表沒有剛好到檔尾', file=sys.stderr)
    return h, names, table


def read_index(path):
    h, names, table = read_tables(path)
    entries = []
    for i in range(len(table) // 24):
        noff, off, size = struct.unpack_from('<QQQ', table, 24 * i)
        end = names.index(b'\0', noff)
        entries.append((names[noff:end].decode('utf-8'), off, size))
    return entries


def pack(out, files):
    datas = [open(p, 'rb').read() for p in files]
    names = b''.join(os.path.basename(p).encode('utf-8') + b'\0' for p in files)
    table = bytearray()
    noff, off = 0, 64
    for p, d in zip(files, datas):
        table += struct.pack('<QQQ', noff, off, len(d))
        noff += len(os.path.basename(p).encode('utf-8')) + 1
        off += len(d)
    names_off = off
    info_off = names_off + len(names)
    buf = -(-max(len(d) for d in datas) // 4096) * 4096
    head = struct.pack('<4sIQQQQIIQQ', b'CS3W', 2, UNKNOWN_8, info_off, len(files), names_off,
                       len(names), UNKNOWN_44, buf, fnv1a64(names + table))
    assert len(head) == 64
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, 'wb') as f:
        f.write(head)
        for d in datas:
            f.write(d)
        f.write(names)
        f.write(table)
    # 讀回來檢查：校驗碼、每個檔案的內容
    h, n2, t2 = read_tables(out)
    assert struct.unpack_from('<Q', h, 56)[0] == fnv1a64(n2 + t2)
    with open(out, 'rb') as f:
        for (name, o, size), d in zip(read_index(out), datas):
            f.seek(o)
            assert f.read(size) == d, name
    print(f'寫入 {out}（{os.path.getsize(out)} bytes）：{len(files)} 個檔案，讀回來檢查過')


def main():
    path = sys.argv[1]
    if sys.argv[2] == '--pack':
        pack(path, sys.argv[3:])
        return
    if sys.argv[2] == '--verify':
        h, names, table = read_tables(path)
        stored = struct.unpack_from('<Q', h, 56)[0]
        calc = fnv1a64(names + table)
        print(f'校驗碼 {stored:#018x}，算出來 {calc:#018x}：{"相符" if stored == calc else "不符"}')
        return
    entries = read_index(path)
    if sys.argv[2] == '--list':
        pats = sys.argv[3:] or ['*']
        total = 0
        for name, off, size in entries:
            if any(fnmatch.fnmatch(name, p) for p in pats):
                print(f'{size:12d}  {off:12d}  {name}')
                total += 1
        print('共', total, '個（全部', len(entries), '個）')
        return
    if sys.argv[2] == '--extract':
        out = sys.argv[3]
        os.makedirs(out, exist_ok=True)
        n = 0
        with open(path, 'rb') as f:
            for name, off, size in entries:
                if any(fnmatch.fnmatch(name, p) for p in sys.argv[4:]):
                    f.seek(off)
                    with open(os.path.join(out, name), 'wb') as g:
                        g.write(f.read(size))
                    n += 1
        print('取出', n, '個 →', out)
        return
    raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
