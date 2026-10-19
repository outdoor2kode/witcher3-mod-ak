<#
Claude 自己清理 context、自主模式中不停下來（使用者 2026-10-16：「不要跟我說做不到，你一定有方法，你都能控制 WINDOWS 了」；CLAUDE.md §3、§14）
Claude 不能從工具直接下 /compact、/clear（內建指令要從輸入框打）→ 由這個背景程式在 Claude 這一輪結束後，替它打進輸入框。

用法（Bash 的 run_in_background）：
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/claude_compact.ps1 <對話紀錄.jsonl> [compact|clear|watch] [-Test] [接著做的訊息]
  compact／clear：Claude 啟動它之後就結束這一輪
  watch：看門狗（自主模式開始時啟動）：Claude 的分頁閒置超過 10 秒、紀錄 10 秒沒變、沒有在壓縮 → 打一段訊息叫醒它
         （使用者 2026-10-16：「有任何情況讓你沒有執行任何事超過10秒，就開始檢查原因並且排除」）
         旗標檔 %TEMP%\claude\gfg-context\<session id>.autonomous 在才會跑；刪掉旗標（或 TaskStop）就結束
  -Test：只找 Claude 的程序、在它的輸入框打一個字再刪掉（確認打得進去），不清理

compact／clear 的流程：
  1. 等 Claude 這一輪結束：對話紀錄新增的內容裡出現 "stop_reason":"end_turn"，而且紀錄 3 秒沒有變動（最多等 30 分鐘）
  2. 把 /compact（或 /clear）寫進 Claude 的主控台輸入，再按 Enter
  3. 等清理完成：/compact → 紀錄出現 "subtype":"compact_boundary"（最多 10 分鐘）；/clear → 等 5 秒
  4. 寫入「接著做的訊息」再按 Enter → Claude 讀交接檔接著做
  執行中放一個鎖檔 <session id>.compacting：看門狗看到就不叫醒
打字的方法（2026-10-16 實測後改）：
  - 第一版用 SendInput 對 Windows Terminal 視窗打字：13:47 打到另一個分頁的 session、14:14 選對分頁後還是沒有效果（輸入框沒收到）
  - 現在：往上找這支程式的上層程序裡的 claude（＝啟動它的那個 Claude Code session），AttachConsole 到它的主控台，
    用 WriteConsoleInput 把按鍵直接寫進輸入緩衝區 → 不經過視窗、不會打錯分頁，使用者在用其他視窗也不受影響
  - 文字和 Enter 分開寫（14:2x 實測：一起寫入時 Enter 沒有送出）；送出後確認分頁變忙碌（標題開頭 ◐◓◑◒，閒置是 ✳）
  - 使用者正在輸入框打字時寫進去，會接在使用者的文字後面一起送出（10-16 14:23、10-19 16:27 發生過）
    → 看門狗在使用者 5 秒內有操作時先等（最多 60 秒）；每次送出（Submit）前再等使用者停手 8 秒、分頁不忙（最多 10 分鐘，等不到就不送）
安全：只寫上面固定的幾段文字；只寫給自己的上層 claude 程序
#>
param(
    [Parameter(Mandatory = $true)][string]$Jsonl,
    [ValidateSet('compact', 'clear', 'watch')][string]$Mode = 'compact',
    [switch]$Test,
    [string]$Keys = "x`b",
    [string]$Message = '（自主模式：context 已清理）讀 docs\handoff.md 最上面的「自主模式」「現在在做」「接續的步驟」，照 CLAUDE.md §14 從那裡接著做；不要問使用者問題，自己決定、自己驗證。',
    [string]$Poke = '[gfg-watchdog] 自主模式中你停了超過 10 秒（CLAUDE.md §14）：先查停下來的原因、排除（寫進交接檔），再照 docs\handoff.md 最上面的「現在在做」「接續的步驟」接著做；不要問使用者問題。'
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class ConIn {
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool FreeConsole();
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool AttachConsole(uint pid);
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern IntPtr CreateFileW(string name, uint access, uint share, IntPtr sec, uint disp, uint flags, IntPtr tmpl);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool CloseHandle(IntPtr h);
    [StructLayout(LayoutKind.Explicit, CharSet = CharSet.Unicode)] struct KEY_EVENT_RECORD {
        [FieldOffset(0)] public int bKeyDown; [FieldOffset(4)] public ushort wRepeatCount; [FieldOffset(6)] public ushort wVirtualKeyCode;
        [FieldOffset(8)] public ushort wVirtualScanCode; [FieldOffset(10)] public char UnicodeChar; [FieldOffset(12)] public uint dwControlKeyState; }
    [StructLayout(LayoutKind.Explicit)] struct INPUT_RECORD { [FieldOffset(0)] public ushort EventType; [FieldOffset(4)] public KEY_EVENT_RECORD KeyEvent; }
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool WriteConsoleInputW(IntPtr h, INPUT_RECORD[] recs, uint n, out uint written);
    [StructLayout(LayoutKind.Sequential)] struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
    [DllImport("user32.dll")] static extern bool GetLastInputInfo(ref LASTINPUTINFO li);
    static void Add(List<INPUT_RECORD> l, ushort vk, ushort scan, char c) {
        foreach (int down in new[] { 1, 0 }) {
            var r = new INPUT_RECORD { EventType = 1 };
            r.KeyEvent.bKeyDown = down; r.KeyEvent.wRepeatCount = 1; r.KeyEvent.wVirtualKeyCode = vk;
            r.KeyEvent.wVirtualScanCode = scan; r.KeyEvent.UnicodeChar = c;
            l.Add(r);
        }
    }
    // 寫進 pid 那個程序的主控台輸入；keys：一般字元照打，'\b' = Backspace，'\r' = Enter
    public static uint Inject(uint pid, string keys) {
        var l = new List<INPUT_RECORD>();
        foreach (char c in keys) {
            if (c == '\r') Add(l, 0x0D, 0x1C, '\r');
            else if (c == '\b') Add(l, 0x08, 0x0E, '\b');
            else Add(l, 0, 0, c);
        }
        FreeConsole();
        if (!AttachConsole(pid)) throw new Exception("AttachConsole(" + pid + ") failed: " + Marshal.GetLastWin32Error());
        try {
            IntPtr h = CreateFileW("CONIN$", 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero);
            if (h == new IntPtr(-1)) throw new Exception("CONIN$ failed: " + Marshal.GetLastWin32Error());
            uint written;
            bool ok = WriteConsoleInputW(h, l.ToArray(), (uint)l.Count, out written);
            int err = Marshal.GetLastWin32Error();
            CloseHandle(h);
            if (!ok) throw new Exception("WriteConsoleInput failed: " + err);
            return written;
        } finally { FreeConsole(); }
    }
    // 使用者（鍵盤、滑鼠）多久沒操作；WriteConsoleInput 不算
    public static double UserIdleSeconds() {
        var li = new LASTINPUTINFO(); li.cbSize = (uint)Marshal.SizeOf(li);
        if (!GetLastInputInfo(ref li)) return 1e9;
        return unchecked((uint)Environment.TickCount - li.dwTime) / 1000.0;
    }
}
'@

function Log([string]$s) { "$(Get-Date -Format 'HH:mm:ss') $s" }

# 啟動這支程式的 Claude Code：往上找第一個名稱是 claude 的程序
function Find-ClaudePid {
    $p = $PID
    for ($i = 0; $i -lt 10; $i++) {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$p"
        if (-not $proc) { break }
        if ($proc.Name -like 'claude*') { return [uint32]$p }
        $p = $proc.ParentProcessId
    }
    throw '上層程序裡找不到 claude'
}

# 讀對話紀錄從 $offset 起新增的部分（Claude Code 一直在寫，用共用讀取）
function Read-New([long]$offset) {
    $fs = [System.IO.File]::Open($Jsonl, 'Open', 'Read', 'ReadWrite')
    try {
        if ($fs.Length -le $offset) { return @('', $fs.Length) }
        $fs.Seek($offset, 'Begin') | Out-Null
        $buf = New-Object byte[] ($fs.Length - $offset)
        $n = $fs.Read($buf, 0, $buf.Length)
        return @([System.Text.Encoding]::UTF8.GetString($buf, 0, $n), ($offset + $n))
    } finally { $fs.Close() }
}
function Get-Len {
    $fs = [System.IO.File]::Open($Jsonl, 'Open', 'Read', 'ReadWrite')
    try { return $fs.Length } finally { $fs.Close() }
}

function Wait-For([string]$pattern, [long]$offset, [int]$timeoutSec, [int]$quietSec) {
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    $seen = $false
    $lastChange = Get-Date
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
        $r = Read-New $offset
        if ($r[1] -ne $offset) { $lastChange = Get-Date; $offset = $r[1] }
        if ($r[0].Contains($pattern)) { $seen = $true }
        if ($seen -and ((Get-Date) - $lastChange).TotalSeconds -ge $quietSec) { return $offset }
    }
    return -1
}

# 分頁標題（Claude Code 忙碌時開頭是 ◐◓◑◒，閒置是 ✳）：用 UI Automation 讀 Windows Terminal 的分頁，找含 aiTitle 的那個
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
function Get-TabTitles {
    $out = @()
    foreach ($p in Get-Process WindowsTerminal -ErrorAction SilentlyContinue) {
        if ($p.MainWindowHandle -eq [IntPtr]::Zero) { continue }
        $root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
        $cond = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
        foreach ($t in $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)) { $out += $t.Current.Name }
    }
    return $out
}
function Get-SessionTitle {
    $r = Read-New ([Math]::Max(0, (Get-Len) - 4000000))
    $m = [regex]::Matches($r[0], '"aiTitle":"([^"]+)"')
    if ($m.Count -eq 0) { return '' }
    return [regex]::Unescape($m[$m.Count - 1].Groups[1].Value)
}
$script:SessionTitle = ''
# 'busy'／'idle'／'unknown'（找不到自己的分頁）
function Get-State {
    if (-not $script:SessionTitle) { $script:SessionTitle = Get-SessionTitle }
    if (-not $script:SessionTitle) { return 'unknown' }
    $state = 'unknown'
    foreach ($t in Get-TabTitles) {
        if (-not $t.Contains($script:SessionTitle) -or $t.Length -eq 0) { continue }
        $c = $t.Substring(0, 1)
        if ('◐◓◑◒'.Contains($c)) { return 'busy' }
        if ($c -eq '✳') { $state = 'idle' }
    }
    return $state
}
function Test-Busy { return (Get-State) -eq 'busy' }
# 等使用者停手：鍵盤、滑鼠 $quietSec 秒沒操作，而且分頁不是忙碌（使用者剛送出訊息時 Claude 在忙）
# 10-19 16:27：送 /compact 時使用者正在打字 → 兩段黏在一起送出、使用者重貼（docs/retrospective.md 第 1 節第 10 條）
# 等不到（使用者一直在操作）就不送：compact 交給 autoCompactWindow（48%）當保險，看門狗 60 秒後再試
function Wait-UserQuiet([int]$quietSec = 8, [int]$maxSec = 600) {
    $t0 = Get-Date; $logged = $false
    while (((Get-Date) - $t0).TotalSeconds -lt $maxSec) {
        if ([ConIn]::UserIdleSeconds() -ge $quietSec -and -not (Test-Busy)) { return $true }
        if (-not $logged) { Log "使用者在操作（或分頁忙碌）：等停手 $quietSec 秒再送"; $logged = $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

# 打一段文字再送出：文字和 Enter 分開寫（14:2x 實測：一起寫入時 Enter 沒有送出，文字留在輸入框）
# 按 Enter 後 8 秒內分頁要變成忙碌（或紀錄出現這段文字）；沒有就再按一次（最多 3 次）
function Submit([string]$text) {
    if (-not (Wait-UserQuiet)) { Log "使用者 10 分鐘內一直在操作：不送「$($text.Substring(0, [Math]::Min(12, $text.Length)))…」"; return $false }
    $probe = ($text -split '[\\"]')[0]
    if ($probe.Length -gt 14) { $probe = $probe.Substring(0, 14) }
    $off = Get-Len
    [ConIn]::Inject($claude, $text) | Out-Null
    Start-Sleep -Milliseconds 1200
    for ($try = 1; $try -le 3; $try++) {
        [ConIn]::Inject($claude, "`r") | Out-Null
        for ($k = 0; $k -lt 16; $k++) {
            Start-Sleep -Milliseconds 500
            if (Test-Busy) { Log "送出了（第 $try 次 Enter：分頁變忙碌）"; return $true }
            if ($probe.Length -ge 4 -and (Read-New $off)[0].Contains($probe)) { Log "送出了（第 $try 次 Enter：紀錄有這段文字）"; return $true }
        }
        Log "按了 Enter，分頁沒有變成忙碌（第 $try 次）"
    }
    return $false
}

$claude = Find-ClaudePid
Log "Claude 的程序：$claude"
if ($Test) {
    $n = [ConIn]::Inject($claude, $Keys)
    Log "測試：寫了 $n 筆按鍵；分頁狀態：$(Get-State)；使用者 $([int][ConIn]::UserIdleSeconds()) 秒沒操作"
    exit 0
}
if (-not (Test-Path $Jsonl)) { throw "找不到對話紀錄：$Jsonl" }
$sid = [System.IO.Path]::GetFileNameWithoutExtension($Jsonl)
$stateDir = Join-Path $env:TEMP 'claude\gfg-context'
New-Item -ItemType Directory -Force $stateDir | Out-Null
$lock = Join-Path $stateDir "$sid.compacting"
$flag = Join-Path $stateDir "$sid.autonomous"

if ($Mode -eq 'watch') {
    Set-Content -Path $flag -Value (Get-Date -Format o) -Encoding UTF8
    Log "看門狗開始（旗標 $flag）；分頁狀態：$(Get-State)「$script:SessionTitle」"
    $idleSince = $null; $busySince = $null; $lastLen = -1; $lenAt = Get-Date; $titleAt = Get-Date
    $wait = 10; $poked = $false; $lastState = ''
    while (Test-Path $flag) {
        Start-Sleep -Seconds 1
        if (((Get-Date) - $titleAt).TotalSeconds -ge 60) { $t = Get-SessionTitle; if ($t) { $script:SessionTitle = $t }; $titleAt = Get-Date }
        $l = Get-Len
        if ($l -ne $lastLen) { $lastLen = $l; $lenAt = Get-Date }
        if ((Test-Path $lock) -and (Get-Item $lock).LastWriteTime -gt (Get-Date).AddMinutes(-15)) { $idleSince = $null; continue }
        $state = Get-State
        if ($state -ne $lastState) { Log "分頁狀態：$state"; $lastState = $state }
        if ($state -eq 'busy') { if (-not $busySince) { $busySince = Get-Date }; $idleSince = $null; continue }
        if ($state -ne 'idle') { $idleSince = $null; continue }
        if ($busySince) {
            # 叫醒後很快又停：等久一點再叫（10 → 20 → … 秒，最多 10 分鐘）；做了一陣子才停：回到 10 秒
            $dur = ((Get-Date) - $busySince).TotalSeconds; $busySince = $null
            if ($poked -and $dur -lt 20) { $wait = [Math]::Min($wait * 2, 600) } else { $wait = 10 }
            $poked = $false
        }
        if (-not $idleSince) { $idleSince = Get-Date }
        $idle = ((Get-Date) - $idleSince).TotalSeconds
        $quiet = ((Get-Date) - $lenAt).TotalSeconds
        if ($idle -lt $wait -or $quiet -lt 10) { continue }
        $user = [ConIn]::UserIdleSeconds()
        if ($user -lt 5 -and $idle -lt 60) { continue }
        Log "閒置 $([int]$idle) 秒（紀錄 $([int]$quiet) 秒沒變、使用者 $([int]$user) 秒沒操作）→ 叫醒"
        $ok = Submit $Poke
        $poked = $true; $idleSince = $null
        if (-not $ok) { Log '沒叫醒：60 秒後再試'; $wait = [Math]::Max($wait, 60) }
    }
    Log '旗標不見了：看門狗結束'
    exit 0
}

Set-Content -Path $lock -Value (Get-Date -Format o) -Encoding UTF8
function Finish([int]$code) { Remove-Item $lock -ErrorAction SilentlyContinue; exit $code }
$start = Get-Len
Log "開始：等這一輪結束（紀錄 $start bytes）"
$offset = Wait-For '"stop_reason":"end_turn"' $start 1800 3
if ($offset -lt 0) { Log '30 分鐘內這一輪沒有結束：不清理'; Finish 1 }
Log "這一輪結束了（紀錄 $offset bytes）"
Set-Content -Path $lock -Value (Get-Date -Format o) -Encoding UTF8

if ($Mode -eq 'compact') {
    if (-not (Submit "/compact 摘要以 docs\handoff.md（交接檔）和現在在做的事為主：自主模式、使用者回報的 10 個問題的進度、接續的步驟、測試的操作方法")) { Log '/compact 沒有送出：結束'; Finish 1 }
    Log '等壓縮完成'
    $done = Wait-For '"subtype":"compact_boundary"' $offset 600 3
    if ($done -lt 0) { Log '10 分鐘內沒看到壓縮完成的紀錄：不打接續的訊息'; Finish 1 }
    Log '壓縮完成'
} else {
    if (-not (Submit '/clear')) { Log '/clear 沒有送出：結束'; Finish 1 }
    Start-Sleep -Seconds 5
}
Start-Sleep -Seconds 2
if (-not (Submit $Message)) { Log '接著做的訊息沒有送出'; Finish 1 }
Log '送出接著做的訊息；結束'
Finish 0
