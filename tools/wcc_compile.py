"""用 REDkit 的 wcc_lite 編譯 mod 腳本，檢查能不能通過（不進遊戲）。

用法：
    python -X utf8 tools/wcc_compile.py [patch 資料夾] [--out 輸出資料夾] [--timeout 秒]

- patch 資料夾預設是 workspace/scripts（會遞迴找 .ws）
- 原版腳本固定用 <REDKIT_DEPOT>/scripts，不會被修改
- 工作目錄必須是 <REDKIT_DIR>/bin/x64_RedKit，否則紀錄檔會寫到別處（docs/findings.md §12.5）
- 第一次在這台電腦執行時會跳出 EULA 視窗，要使用者本人確認
- wcc_lite 會自動重建 <REDKIT_DEPOT>/x64.release.redscripts（CLAUDE.md §11 的例外）
- 錯誤訊息只有行號 [N]、沒有檔名，所以失敗時會列出每個檔案的第 N 行供對照
- 編譯分階段（語法 → annotation → 函式內容），前一階段失敗時，後面的錯誤不會顯示
"""
import argparse
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REDKIT_DIR = Path(r'D:\Program Files (x86)\Steam\steamapps\common\The Witcher 3 REDkit')
WCC_DIR = REDKIT_DIR / 'bin' / 'x64_RedKit'
VANILLA_SCRIPTS = REDKIT_DIR / 'r4data' / 'scripts'
PROJECT_DIR = Path(__file__).resolve().parent.parent

ERROR_RE = re.compile(r'\]\[Error\]\[WCC\] (?:\[(\d+)\]: )?(.*)')
GENERIC_ERRORS = ('Could not compile patch.', 'Wcc operation failed')


def show_line_candidates(files: list[Path], root: Path, line_no: int) -> None:
    for f in files:
        lines = f.read_text(encoding='utf-8-sig', errors='replace').splitlines()
        if line_no <= len(lines):
            print(f'      {f.relative_to(root)}:{line_no}: {lines[line_no - 1].strip()}')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('patch', nargs='?', default=str(PROJECT_DIR / 'workspace' / 'scripts'))
    parser.add_argument('--out', help='輸出資料夾（預設為系統暫存資料夾）')
    parser.add_argument('--timeout', type=int, default=600)
    args = parser.parse_args()

    patch = Path(args.patch).resolve()
    files = sorted(patch.rglob('*.ws'))
    if not files:
        print(f'找不到 .ws 檔：{patch}')
        return 2
    if ' ' in str(patch):
        print(f'警告：路徑含空白，wcc_lite 可能無法正確解析：{patch}')
    out = Path(args.out).resolve() if args.out else Path(tempfile.mkdtemp(prefix='wcc_'))
    out.mkdir(parents=True, exist_ok=True)

    cmd = [str(WCC_DIR / 'wcc_lite.exe'), 'compilescripts', str(VANILLA_SCRIPTS),
           f'-patch={patch}', f'-out={out}']
    print(f'編譯 {len(files)} 個檔案：{patch}')
    start = time.monotonic()
    try:
        result = subprocess.run(cmd, cwd=WCC_DIR, capture_output=True, timeout=args.timeout)
    except subprocess.TimeoutExpired:
        print(f'逾時（{args.timeout} 秒）。如果是第一次執行，請確認畫面上的 EULA 視窗。')
        return 3
    print(f'耗時 {time.monotonic() - start:.1f} 秒，exit={result.returncode}')

    log = result.stdout.decode('utf-8', errors='replace').splitlines()
    errors = [m for m in map(ERROR_RE.search, log) if m and m.group(2).strip() not in GENERIC_ERRORS]
    success = any('Success! Patch scripts blob saved' in line for line in log)

    for m in errors:
        line_no = m.group(1)
        print(f'  錯誤{f" [第 {line_no} 行]" if line_no else ""}：{m.group(2).strip()}')
        if line_no:
            show_line_candidates(files, patch, int(line_no))

    if success:
        print(f'成功：{out / "blob.rsblob"}')
        return 0
    if not errors:
        print('失敗，但沒有解析到錯誤行；完整紀錄見 <REDKIT_DIR>/bin/wcc.log')
    return 1


if __name__ == '__main__':
    sys.exit(main())
