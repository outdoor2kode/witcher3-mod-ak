<#
Claude 自己清理 context（使用者 2026-10-16：「不要跟我說做不到，你一定有方法，你都能控制 WINDOWS 了」；CLAUDE.md §3、§14）
Claude 不能從工具直接下 /compact、/clear（內建指令要從輸入框打）→ 由這個背景程式在 Claude 這一輪結束後，替它打進輸入框。

用法（Bash 的 run_in_background；Claude 啟動它之後就結束這一輪）：
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/claude_compact.ps1 <對話紀錄.jsonl> [compact|clear] [-Test] [接著做的訊息]
  -Test：只找 Claude 的程序、在它的輸入框打一個字再刪掉（確認打得進去），不清理

流程：
  1. 等 Claude 這一輪結束：對話紀錄新增的內容裡出現 "stop_reason":"end_turn"，而且紀錄 3 秒沒有變動（最多等 30 分鐘）
  2. 把 /compact（或 /clear）＋ Enter 寫進 Claude 的主控台輸入
  3. 等清理完成：/compact → 紀錄出現 "subtype":"compact_boundary"（最多 10 分鐘）；/clear → 等 5 秒
  4. 寫入「接著做的訊息」＋ Enter → Claude 讀交接檔接著做
打字的方法（2026-10-16 實測後改）：
  - 第一版用 SendInput 對 Windows Terminal 視窗打字：13:47 打到另一個分頁的 session、14:14 選對分頁後還是沒有效果（輸入框沒收到）
  - 現在：往上找這支程式的上層程序裡的 claude（＝啟動它的那個 Claude Code session），AttachConsole 到它的主控台，
    用 WriteConsoleInput 把按鍵直接寫進輸入緩衝區 → 不經過視窗、不會打錯分頁，使用者在用其他視窗也不受影響
安全：只寫上面固定的兩段文字；只寫給自己的上層 claude 程序
#>
param(
    [Parameter(Mandatory = $true)][string]$Jsonl,
    [ValidateSet('compact', 'clear')][string]$Mode = 'compact',
    [switch]$Test,
    [string]$Keys = "x`b",
    [string]$Message = '（自主模式：context 已清理）讀 docs\handoff.md 最上面的「自主模式」「現在在做」「接續的步驟」，照 CLAUDE.md §14 從那裡接著做；不要問使用者問題，自己決定、自己驗證。'
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

$claude = Find-ClaudePid
Log "Claude 的程序：$claude"
if ($Test) {
    $n = [ConIn]::Inject($claude, $Keys)
    Log "測試：寫了 $n 筆按鍵"
    exit 0
}
if (-not (Test-Path $Jsonl)) { throw "找不到對話紀錄：$Jsonl" }
$start = (Get-Item $Jsonl).Length
Log "開始：等這一輪結束（紀錄 $start bytes）"
$offset = Wait-For '"stop_reason":"end_turn"' $start 1800 3
if ($offset -lt 0) { Log '30 分鐘內這一輪沒有結束：不清理'; exit 1 }
Log "這一輪結束了（紀錄 $offset bytes）"

if ($Mode -eq 'compact') {
    $n = [ConIn]::Inject($claude, "/compact 摘要以 docs\handoff.md（交接檔）和現在在做的事為主：自主模式、使用者回報的 10 個問題的進度、接續的步驟、測試的操作方法`r")
    Log "寫了 /compact（$n 筆按鍵），等壓縮完成"
    $done = Wait-For '"subtype":"compact_boundary"' $offset 600 3
    if ($done -lt 0) { Log '10 分鐘內沒看到壓縮完成的紀錄：不打接續的訊息'; exit 1 }
    Log '壓縮完成'
} else {
    $n = [ConIn]::Inject($claude, "/clear`r")
    Log "寫了 /clear（$n 筆按鍵）"
    Start-Sleep -Seconds 5
}
$n = [ConIn]::Inject($claude, "$Message`r")
Log "寫了接著做的訊息（$n 筆按鍵）；結束"
