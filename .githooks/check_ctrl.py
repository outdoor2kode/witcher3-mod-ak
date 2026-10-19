# commit 前檢查：要 commit 的文字檔裡有沒有控制字元（第 41 項回顧；2026-10-19）
# 原因：Windows 路徑的反斜線經過 shell 或 Python 字串時被轉成控制字元（\f 換頁、\a BEL、\r…）：
#       10-15～10-19 發生 9 次、8 個 commit 在修（docs/retrospective.md 5.7）
# 允許：Tab、LF、CRLF 的 CR（CR 後面一定要接 LF）；檔頭的 BOM 不算控制字元
# 用法：pre-commit 會叫；手動檢查：python -X utf8 .githooks/check_ctrl.py 檔案...（檢查工作目錄的檔）
import subprocess
import sys

TEXT_EXT = ('.md', '.ws', '.xml', '.py', '.ps1', '.sh', '.csv', '.txt', '.json', '.yaml', '.yml', '.gitignore', '.gitattributes')


def bad_chars(data: bytes):
    out = []
    for i, b in enumerate(data):
        if b < 32 and b not in (9, 10, 13):
            out.append((i, b))
        elif b == 13 and (i + 1 >= len(data) or data[i + 1] != 10):
            out.append((i, b))
    return out


def line_of(data: bytes, pos: int) -> int:
    return data.count(b'\n', 0, pos) + 1


def main() -> int:
    if len(sys.argv) > 1:
        files = [(f, open(f, 'rb').read()) for f in sys.argv[1:]]
    else:
        names = subprocess.run(['git', 'diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z'],
                               capture_output=True, check=True).stdout.decode('utf-8').split('\0')
        files = []
        for n in names:
            if n and n.lower().endswith(TEXT_EXT):
                files.append((n, subprocess.run(['git', 'show', ':' + n], capture_output=True, check=True).stdout))
    found = 0
    for name, data in files:
        if b'\x00' in data:
            continue  # 含 NUL＝二進位或 UTF-16（例：REDkit 產生的 *_lg.csv），git 也當二進位
        for pos, b in bad_chars(data)[:5]:
            found += 1
            ctx = ''.join(c if ord(c) >= 32 else f'\\x{ord(c):02x}'
                          for c in data[max(0, pos - 20):pos + 20].decode('utf-8', 'replace'))
            print(f'控制字元 0x{b:02X}：{name} 第 {line_of(data, pos)} 行附近：…{ctx}…')
    if found:
        print('commit 擋下來了：上面的控制字元多半是反斜線被轉掉（例：\\f、\\a、\\r）→ 用 Write／Edit 改回反斜線再 commit')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
