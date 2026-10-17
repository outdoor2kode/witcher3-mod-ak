"""讀巫師3 的聲音封存檔 soundspc.cache（CS3W 第 2 版），列出、取出裡面的檔案（只讀；第 22 項，2026-10-18）

用法：
    python -X utf8 tools/sound_cache.py <soundspc.cache> --list [萬用字元…]
    python -X utf8 tools/sound_cache.py <soundspc.cache> --extract <輸出資料夾> <萬用字元>…

格式（2026-10-18 讀 <W3_GAME_DIR>\\content\\content0\\soundspc.cache 對出來的）：
- 檔頭：'CS3W'、u32 版本（2）、u64（不明，像時間）、u64 檔案表位置、u64 檔案數、u64 名稱表位置、
  u32 名稱表大小（= 檔案表位置 − 名稱表位置）、u32（不明）、u64（不明，可能是最大的檔案大小）、u64（可能是校驗碼）
- 名稱表：以 0 結尾的字串（例：amb_bob_bg_01.bnk、123456.wem）
- 檔案表：每筆 24 bytes：u64 名稱位置（相對名稱表）、u64 資料位置、u64 大小；檔案表一直到檔尾
"""
import fnmatch
import os
import struct
import sys


def read_index(path):
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
    entries = []
    for i in range(count):
        noff, off, size = struct.unpack_from('<QQQ', table, 24 * i)
        end = names.index(b'\0', noff)
        entries.append((names[noff:end].decode('utf-8'), off, size))
    return entries


def main():
    path = sys.argv[1]
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
