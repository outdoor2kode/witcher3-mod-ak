"""/clear 的 hook：清掉對話前，讓 Claude 用舊對話的內容更新 docs/handoff.md，再 commit。

設定在 .claude/settings.local.json，兩個 hook 搭配：
    SessionEnd（matcher clear）   → handoff_on_clear.py end
    SessionStart（matcher clear） → handoff_on_clear.py start

- SessionEnd 預設只有 1.5 秒、最多 60 秒，也不能讓 Claude 做事（官方 hooks 文件「SessionEnd」）
  → 這裡只記下舊對話的 session_id
- SessionStart 在 /clear 後於背景執行，新對話的第一個回應會等它跑完（官方 hooks 文件「SessionStart」）
  → 在這裡用 claude -p --resume <舊 id> 接回舊對話，請它更新交接檔
- 子程序只能讀檔、改 docs/handoff.md、跑唯讀的 git 指令（--permission-mode dontAsk 加 --allowedTools）
- 子程序關掉所有 hook（disableAllHooks）：不會遞迴，也不會觸發 Stop 的通知
- commit 由這個腳本做，只 commit docs/handoff.md（git commit -- 路徑，不會帶到其他已 stage 的檔案）
- 紀錄：.claude/hooks/logs/handoff_on_clear.log（不納入 git）
"""
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

PROJECT_DIR = Path(os.environ.get('CLAUDE_PROJECT_DIR') or Path(__file__).resolve().parents[2])
LOG_DIR = PROJECT_DIR / '.claude' / 'hooks' / 'logs'
PENDING = LOG_DIR / 'pending_clear.json'
LOG = LOG_DIR / 'handoff_on_clear.log'
HANDOFF = 'docs/handoff.md'
PENDING_MAX_AGE = 300  # 秒；SessionEnd 的紀錄超過這個時間就不用
CHILD_TIMEOUT = 840    # 秒；比 settings 裡 SessionStart 的 timeout（900）短，逾時才來得及回報
TRAILER = 'Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>'

ALLOWED_TOOLS = [
    'Read', 'Grep', 'Glob', f'Edit({HANDOFF})',
    'Bash(git status *)', 'Bash(git diff *)', 'Bash(git log *)', 'Bash(git show *)',
]

PROMPT = '''（這則訊息是 /clear 的 hook 自動送出的，不是使用者打的）
使用者執行了 /clear，這段對話即將結束。請照 CLAUDE.md §11 的交接檔規則更新 docs/handoff.md，讓新對話能直接接著做。
- 先讀目前的 docs/handoff.md，再用 git status、git diff --stat、git log 確認狀態
- 這段對話如果沒有改變進行中的狀態，就不要改檔案
- 只改 docs/handoff.md，不要 commit（hook 會 commit）
最後一行只輸出這次更新的摘要（繁體中文，30 字以內）；沒有修改就輸出「無變更」。'''


def log(msg: str) -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with LOG.open('a', encoding='utf-8') as f:
        f.write(f'[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}\n')


def output(message: str, context: str | None = None) -> None:
    # systemMessage 顯示給使用者；additionalContext 交給新對話的 Claude（官方 hooks 文件「SessionStart decision control」）
    out: dict = {'systemMessage': message}
    if context:
        out['hookSpecificOutput'] = {'hookEventName': 'SessionStart', 'additionalContext': context}
    print(json.dumps(out))


def git(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(['git', *args], cwd=PROJECT_DIR, capture_output=True,
                          text=True, encoding='utf-8', errors='replace')


def has_reply(transcript: str | None) -> bool:
    # 舊對話至少要有一則 Claude 的回應，才有東西可交接
    # 紀錄檔是 Claude Code 的內部格式，可能隨版本改變（官方 sessions 文件）；略過時會顯示訊息，不會默默跳過
    if not transcript or not Path(transcript).is_file():
        return False
    with open(transcript, 'rb') as f:
        return any(b'"type":"assistant"' in line for line in f)


def on_end(data: dict) -> None:
    if data.get('reason') != 'clear':
        return
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    PENDING.write_text(json.dumps({
        'session_id': data.get('session_id'),
        'transcript_path': data.get('transcript_path'),
        'time': time.time(),
    }), encoding='utf-8')
    log(f'end: 記下 {data.get("session_id")}')


def run_child(old_id: str) -> tuple[subprocess.CompletedProcess, dict]:
    claude = shutil.which('claude') or str(Path.home() / '.local' / 'bin' / 'claude.exe')
    cmd = [claude, '-p', '--resume', old_id, '--fork-session', '--no-session-persistence',
           '--output-format', 'json', '--permission-mode', 'dontAsk',
           '--settings', json.dumps({'disableAllHooks': True}),
           '--allowedTools', *ALLOWED_TOOLS]
    # 提示從 stdin 傳：--allowedTools 吃多個值，放在它後面的參數會被當成工具名稱
    proc = subprocess.run(cmd, input=PROMPT, cwd=PROJECT_DIR, capture_output=True,
                          text=True, encoding='utf-8', errors='replace', timeout=CHILD_TIMEOUT,
                          creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    try:
        result = json.loads(proc.stdout)
    except ValueError:
        result = {}
    return proc, result


def take_pending() -> dict | None:
    # SessionEnd 應該已經寫好紀錄；保險起見最多等 5 秒
    for _ in range(25):
        if PENDING.is_file():
            pending = json.loads(PENDING.read_text(encoding='utf-8'))
            PENDING.unlink()
            return pending
        time.sleep(0.2)
    return None


def on_start(data: dict) -> None:
    if data.get('source') != 'clear':
        return
    pending = take_pending()
    old_id = pending.get('session_id') if pending else None
    if not old_id or time.time() - pending.get('time', 0) > PENDING_MAX_AGE:
        log(f'start: 略過，沒有可用的 SessionEnd 紀錄：{pending}')
        output(f'交接檔：找不到 /clear 前的對話紀錄，沒有更新（紀錄：{LOG}）')
        return
    if not has_reply(pending.get('transcript_path')):
        log(f'start: 略過，{old_id} 沒有 Claude 的回應')
        output('交接檔：清掉的對話沒有 Claude 的回應，略過更新')
        return

    # 紀錄檔是非同步寫入的，最後一輪可能還沒寫完（官方 hooks 文件「Common input fields」的 transcript_path）
    time.sleep(2)
    started = time.time()
    try:
        proc, result = run_child(old_id)
    except subprocess.TimeoutExpired:
        log(f'start: {old_id} 逾時（{CHILD_TIMEOUT} 秒）')
        output(f'交接檔自動更新逾時，沒有 commit（紀錄：{LOG}）')
        return

    summary = (result.get('result') or '').strip().splitlines()
    summary = summary[-1].strip()[:60] if summary else '（沒有摘要）'
    log(f'start: {old_id} exit={proc.returncode} 秒數={time.time() - started:.0f} '
        f'cost_usd={result.get("total_cost_usd")} usage={json.dumps(result.get("usage"))} '
        f'denials={json.dumps(result.get("permission_denials"), ensure_ascii=False)} 摘要={summary}')
    if proc.returncode != 0 or result.get('is_error'):
        log(f'start: stderr={proc.stderr[-2000:]!r} stdout={proc.stdout[-2000:]!r}')
        output(f'交接檔自動更新失敗，沒有 commit（紀錄：{LOG}）')
        return

    if git('diff', '--quiet', '--', HANDOFF).returncode == 0:
        output(f'交接檔沒有變動：{summary}')
        return
    commit = git('commit', '-q', '-m', f'docs：交接檔自動更新（/clear 前）——{summary}', '-m', TRAILER, '--', HANDOFF)
    if commit.returncode != 0:
        log(f'start: commit 失敗：{commit.stderr.strip()}')
        output(f'交接檔已更新，但 commit 失敗（紀錄：{LOG}）')
        return
    head = git('rev-parse', '--short', 'HEAD').stdout.strip()
    log(f'start: commit {head}')
    output(f'交接檔已更新並 commit（{head}）：{summary}',
           f'/clear 前已自動更新 {HANDOFF}（commit {head}）。')


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}
    try:
        if mode == 'end':
            on_end(data)
        elif mode == 'start':
            on_start(data)
    except Exception as e:  # hook 出錯不能擋住 /clear；記下來，並在畫面上告知
        log(f'{mode}: 例外 {e!r}')
        if mode == 'start':
            output(f'交接檔自動更新出錯：{e}（紀錄：{LOG}）')


if __name__ == '__main__':
    main()
