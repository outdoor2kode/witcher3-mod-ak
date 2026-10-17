"""從 Valve 的 VPK 封存檔取出檔案（只讀 VPK；CS2 的 pak01_dir.vpk）
用法：
  python -X utf8 tools/vpk_extract.py <pak01_dir.vpk> --list <萬用字元>          列出符合的路徑、大小
  python -X utf8 tools/vpk_extract.py <pak01_dir.vpk> <輸出資料夾> <萬用字元>…   取出（保留 VPK 內的路徑）
萬用字元照 fnmatch，例：'sounds/weapons/ak47/*'、'*weapon_ak47_png*'
格式（VPK 1／2）：檔頭 → 目錄樹（副檔名 → 路徑 → 檔名，每筆 CRC、預載大小、封存編號、位移、長度、0xFFFF、預載資料）；
封存編號 0x7FFF = 資料在 _dir.vpk 目錄樹後面，否則在同資料夾的 pak01_NNN.vpk
"""
import fnmatch
import os
import struct
import sys


def read_tree(dir_path):
    with open(dir_path, 'rb') as f:
        sig, ver, tree_size = struct.unpack('<III', f.read(12))
        assert sig == 0x55AA1234, '不是 VPK'
        header = 28 if ver == 2 else 12
        f.seek(header)
        tree = f.read(tree_size)
    entries = {}
    pos = 0

    def rs():
        nonlocal pos
        e = tree.index(b'\0', pos)
        s = tree[pos:e].decode('utf-8', 'replace')
        pos = e + 1
        return s

    while True:
        ext = rs()
        if not ext:
            break
        while True:
            path = rs()
            if not path:
                break
            while True:
                name = rs()
                if not name:
                    break
                crc, preload, arch, off, length, term = struct.unpack('<IHHIIH', tree[pos:pos + 18])
                assert term == 0xFFFF
                pos += 18
                pre = tree[pos:pos + preload]
                pos += preload
                full = (path + '/' if path.strip() else '') + name + ('.' + ext if ext.strip() else '')
                entries[full] = (arch, off, length, pre)
    return entries, header + tree_size


def read_entry(dir_path, data_start, entry):
    arch, off, length, pre = entry
    if length == 0:
        return pre
    if arch == 0x7FFF:
        fn, off = dir_path, data_start + off
    else:
        fn = dir_path.replace('_dir.vpk', '_%03d.vpk' % arch)
    with open(fn, 'rb') as f:
        f.seek(off)
        return pre + f.read(length)


def main():
    dir_path = sys.argv[1]
    entries, data_start = read_tree(dir_path)
    if sys.argv[2] == '--list':
        for pat in sys.argv[3:]:
            for k in sorted(entries):
                if fnmatch.fnmatch(k, pat):
                    a, o, n, p = entries[k]
                    print(f'{n + len(p):10d}  {k}')
        return
    out = sys.argv[2]
    count = 0
    for pat in sys.argv[3:]:
        for k in sorted(entries):
            if fnmatch.fnmatch(k, pat):
                dst = os.path.join(out, *k.split('/'))
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                with open(dst, 'wb') as f:
                    f.write(read_entry(dir_path, data_start, entries[k]))
                count += 1
                print('取出', k)
    print('共', count, '個')


if __name__ == '__main__':
    main()
