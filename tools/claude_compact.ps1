<#
Claude 自己清理 context（使用者 2026-10-16：「不要跟我說做不到，你一定有方法，你都能控制 WINDOWS 了」）
Claude 不能從工具直接下 /compact、/clear（內建指令要從輸入框打）→ 由這個背景程式在 Claude 這一輪結束後，替它在終端機打。

用法（Bash 的 run_in_background；Claude 啟動它之後就結束這一輪）：
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/claude_compact.ps1 <對話紀錄.jsonl> [compact|clear] [-Test] [接著做的訊息]
  -Test：只找自己的分頁、印出來，不打字

流程：
  1. 等 Claude 這一輪結束：對話紀錄新增的內容裡出現 "stop_reason":"end_turn"，而且紀錄 3 秒沒有變動（最多等 30 分鐘）
  2. 把 Windows Terminal（Claude Code 在裡面跑）叫到前面，打 /compact（或 /clear）＋ Enter
     - /compact 後面接一段說明：摘要以交接檔、現在在做的事為主
  3. 等清理完成：/compact → 紀錄出現 "subtype":"compact_boundary"（最多 10 分鐘）；/clear → 等 5 秒
  4. 打「接著做的訊息」＋ Enter → Claude 讀交接檔接著做
安全：
  - 只送到程序名稱 windowsterminal 的視窗（tools/desk.ps1 一律擋終端機；這支只做這件事）
  - 只打上面固定的兩段文字；打字用 Unicode（KEYEVENTF_UNICODE），不經過輸入法
  - 送出前檢查前景視窗確實是 Windows Terminal，不是就不打、結束
紀錄：每一步寫到標準輸出（Bash 背景工作的輸出檔）
#>
param(
    [Parameter(Mandatory = $true)][string]$Jsonl,
    [ValidateSet('compact', 'clear')][string]$Mode = 'compact',
    [switch]$Test,
    [string]$Message = '（自主模式：context 已清理）讀 docs\handoff.md 最上面的「自主模式」「現在在做」「接續的步驟」，從那裡接著做；不要問使用者問題，自己決定、自己驗證。'
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$desk = Join-Path $PSScriptRoot 'desk.ps1'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SelfType {
    [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] struct UNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public UNION u; }
    [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    static void Send(INPUT i) {
        if (SendInput(1, new[] { i }, Marshal.SizeOf(typeof(INPUT))) != 1)
            throw new Exception("SendInput failed: " + Marshal.GetLastWin32Error());
    }
    public static void Text(string s) {
        foreach (char c in s) {
            foreach (bool up in new[] { false, true }) {
                var i = new INPUT { type = 1 };
                i.u.ki.wScan = c; i.u.ki.dwFlags = 0x0004u | (up ? 0x0002u : 0u);  // KEYEVENTF_UNICODE
                Send(i);
            }
            System.Threading.Thread.Sleep(8);
        }
    }
    public static void Enter() {
        foreach (bool up in new[] { false, true }) {
            var i = new INPUT { type = 1 };
            i.u.ki.wVk = 0x0D; i.u.ki.dwFlags = up ? 0x0002u : 0u;
            Send(i);
        }
    }
}
'@

function Log([string]$s) { "$(Get-Date -Format 'HH:mm:ss') $s" }

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

# 這個 session 的分頁名稱：對話紀錄裡最後一筆 aiTitle（Claude Code 把它當分頁標題，前面加狀態符號：◐◓◑◒ 忙碌、✳ 閒置）
# 2026-10-16 13:47 第一次試：終端機有兩個分頁、選中的是另一個 Claude Code session → 只叫視窗到前面會打錯分頁
function Get-SessionTitle {
    $r = Read-New ([Math]::Max(0, (Get-Item $Jsonl).Length - 4000000))
    $m = [regex]::Matches($r[0], '"aiTitle":"([^"]+)"')
    if ($m.Count -eq 0) { throw '對話紀錄裡找不到 aiTitle：不知道哪個分頁是自己' }
    return [regex]::Unescape($m[$m.Count - 1].Groups[1].Value)
}

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
function Find-MyTab([string]$title) {
    foreach ($p in Get-Process WindowsTerminal -ErrorAction SilentlyContinue) {
        if ($p.MainWindowHandle -eq [IntPtr]::Zero) { continue }
        $root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
        $cond = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
        foreach ($t in $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)) {
            if ($t.Current.Name.Contains($title)) { return @($t, $p) }
        }
    }
    return $null
}

# 等自己的分頁變成閒置（名稱開頭不是忙碌的轉圈符號），最多 $sec 秒
function Wait-TabIdle([string]$title, [int]$sec) {
    $deadline = (Get-Date).AddSeconds($sec)
    while ((Get-Date) -lt $deadline) {
        $f = Find-MyTab $title
        if ($f -and -not ('◐◓◑◒'.Contains($f[0].Current.Name.Substring(0, 1)))) { return $true }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Send-ToTerminal([string]$text) {
    $title = Get-SessionTitle
    $f = Find-MyTab $title
    if (-not $f) { throw "找不到標題含「$title」的分頁：不打字" }
    $f[0].GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Start-Sleep -Milliseconds 500
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $desk focus proc:windowsterminal | Out-Null
    Start-Sleep -Milliseconds 600
    $h = [SelfType]::GetForegroundWindow()
    $procId = [uint32]0
    [SelfType]::GetWindowThreadProcessId($h, [ref]$procId) | Out-Null
    $fg = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($fg.ProcessName -ne 'WindowsTerminal') { throw "前景視窗是 $($fg.ProcessName)，不是 Windows Terminal：不打字" }
    $now = (Get-Process -Id $procId).MainWindowTitle
    if (-not $now.Contains($title)) { throw "Windows Terminal 目前的分頁是「$now」，不是「$title」：不打字" }
    Log "分頁：$now"
    [SelfType]::Text($text)
    Start-Sleep -Milliseconds 700
    [SelfType]::Enter()
}

if (-not (Test-Path $Jsonl)) { throw "找不到對話紀錄：$Jsonl" }
if ($Test) {
    $t = Get-SessionTitle
    $f = Find-MyTab $t
    if ($f) { Log "測試：session 標題「$t」→ 分頁「$($f[0].Current.Name)」；Windows Terminal 目前的標題「$($f[1].MainWindowTitle)」" } else { Log "測試：找不到標題含「$t」的分頁" }
    exit 0
}
$start = (Get-Item $Jsonl).Length
Log "開始：等這一輪結束（紀錄 $start bytes）"
$offset = Wait-For '"stop_reason":"end_turn"' $start 1800 3
if ($offset -lt 0) { Log '30 分鐘內這一輪沒有結束：不清理'; exit 1 }
Log "這一輪結束了（紀錄 $offset bytes）"
$title = Get-SessionTitle
if (-not (Wait-TabIdle $title 60)) { Log "分頁「$title」60 秒內沒有變成閒置：不清理"; exit 1 }
Log "分頁「$title」閒置"

if ($Mode -eq 'compact') {
    Send-ToTerminal '/compact 摘要以 docs\handoff.md（交接檔）和現在在做的事為主：自主模式、使用者回報的 10 個問題的進度、接續的步驟、測試的操作方法'
    Log '打了 /compact，等壓縮完成'
    $done = Wait-For '"subtype":"compact_boundary"' $offset 600 3
    if ($done -lt 0) { Log '10 分鐘內沒看到壓縮完成的紀錄：不打接續的訊息'; exit 1 }
    Log '壓縮完成'
} else {
    Send-ToTerminal '/clear'
    Log '打了 /clear'
    Start-Sleep -Seconds 5
}
Send-ToTerminal $Message
Log '打了接著做的訊息；結束'
