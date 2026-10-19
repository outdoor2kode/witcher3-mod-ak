<#
讓 Claude 自己看螢幕、操作滑鼠鍵盤（使用者 2026-10-16 要求：REDkit 和遊戲由 Claude 自己操作、自己驗證）
只用 Windows 內建的東西：Windows PowerShell 5.1 + .NET Framework（System.Drawing、UI Automation）+ user32.dll

用法（Bash）：
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/desk.ps1 <指令> [參數…]

指令（<視窗> = handle（十進位或 0x 十六進位）、標題的一部分、或 proc:程序名稱）：
  windows                                  列出看得到的視窗：handle、程序、位置、標題
  shot <out.png> [scale=0.5] [rect=x,y,w,h] [grid=100]
                                           截桌面（全部螢幕或指定範圍）存 PNG；grid 畫格線、標螢幕座標
  burst <前綴> <張數> <間隔毫秒> [scale=0.5] [rect=x,y,w,h] [hold=w,shift] [pre=毫秒] [key=space 或 key=shift,shift] [keyhold=shift]
                                           [mouse=left|right|middle]：連拍開始時按住滑鼠鍵（在游標位置），連拍結束放開
                                           連拍：先按住 hold、等 pre、按一下 key，再每隔幾毫秒拍一張（看跳躍落地等快速動作）
  wshot <視窗> <out.png> [scale=…] [grid=…] [mode=print]
                                           截視窗的範圍；mode=print 用 PrintWindow：視窗被擋住也截得到（含 REDkit 的 D3D12 畫面）
                                           mode=print 的圖：(0,0) = GetWindowRect 的左上（含隱形邊框；最大化的視窗是 (-8,-8)）
                                           → 圖上的位置換成螢幕座標要加上它；照格線的標籤讀最準（2026-10-20 裁圖後直接當螢幕座標，點偏 8 像素）
  focus <視窗>                             把視窗叫到最前面
  place <視窗> <x> <y> <寬> <高>            移動、縮放視窗（例：跑到螢幕外的 Asset Browser）
  close <視窗>                             關視窗（等於按 X）
  click <x> <y> [left|right|middle] [次數]  螢幕座標
  down|up [left|right|middle]              按住、放開滑鼠鍵（在游標目前的位置）
  move <x> <y>                             游標移到螢幕座標
  rmove <dx> <dy> [分幾次=1] [間隔毫秒=10]   相對移動（遊戲的鏡頭）
  drag <x1> <y1> <x2> <y2>
  wheel <x> <y> <格數>                     正數往上捲
  key <組合鍵> [按住毫秒]                   例：enter、esc、f7、ctrl+s、shift+tab、oem3（~ 那一鍵）、num1
  type <文字>                              Unicode 逐字輸入（輸入框用；不經過輸入法）
  typepath <路徑>                          同 type，但 / 換成 \（檔案視窗不接受正斜線；Bash 裡不用寫反斜線）
  keys <文字>                              逐字按鍵輸入（遊戲的主控台用：它不吃 Unicode 輸入）
  keydown|keyup <鍵>                       分開按住、放開（按住之後一定要 keyup）
  uia <視窗> [深度=4] [關鍵字]              列出 UI Automation 元件：類型、名稱、位置
  invoke <視窗> <名稱>                      按下名稱相符的元件（沒有 Invoke 就點它的中心）
  cursor                                   印出游標位置、游標下的視窗
  awake [秒數=604800]                      保持清醒（不睡眠、不關螢幕），直到時間到或程序被關掉；在背景跑

2026-10-16 實測：REDkit（editor.exe，沒有用系統管理員權限跑）點選單、按 Esc 都有反應；
REDkit 是 wxWidgets，UI Automation 看不到裡面的元件（uia 列不出東西）→ 截圖加 grid 找座標再點

安全：
- 滑鼠、鍵盤的動作前，檢查會收到輸入的視窗屬於哪個程序：只允許 $Allowed（REDkit 和從 REDkit 開的遊戲 editor、遊戲 witcher3、Blender、REDkit 的 Script Studio scriptstudio）
  終端機（Claude Code 在裡面跑）、瀏覽器不在名單內 → 擋下來、不送出
- 座標一律是螢幕的實際像素（開頭設成 DPI aware）
#>
$ErrorActionPreference = 'Stop'
$Allowed = @('editor', 'witcher3', 'blender', 'scriptstudio')
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8  # 系統語系是 cp950；Bash 讀 UTF-8

Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Desk {
    [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr value);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();
    public static void Init() {
        try { if (SetProcessDpiAwarenessContext(new IntPtr(-4))) return; } catch (EntryPointNotFoundException) {}
        SetProcessDPIAware();
    }

    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    public static List<IntPtr> TopWindows() {
        var list = new List<IntPtr>();
        EnumWindows((h, l) => { if (IsWindowVisible(h)) list.Add(h); return true; }, IntPtr.Zero);
        return list;
    }
    public static string Title(IntPtr h) { var sb = new StringBuilder(512); GetWindowText(h, sb, 512); return sb.ToString(); }
    public static int Pid(IntPtr h) { uint pid; GetWindowThreadProcessId(h, out pid); return (int)pid; }

    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);
    public static RECT Rect(IntPtr h) {
        RECT r;
        // DWMWA_EXTENDED_FRAME_BOUNDS：看得到的外框（不含隱形的縮放邊）
        if (DwmGetWindowAttribute(h, 9, out r, Marshal.SizeOf(typeof(RECT))) == 0) return r;
        GetWindowRect(h, out r);
        return r;
    }
    // 視窗被擋住也截得到：PW_RENDERFULLCONTENT（2）連 DirectX 的內容一起畫；範圍是 GetWindowRect（含隱形的縮放邊）
    [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
    public static System.Drawing.Bitmap Print(IntPtr h) {
        RECT r; GetWindowRect(h, out r);
        var bmp = new System.Drawing.Bitmap(r.Right - r.Left, r.Bottom - r.Top);
        using (var g = System.Drawing.Graphics.FromImage(bmp)) {
            IntPtr dc = g.GetHdc();
            bool ok = PrintWindow(h, dc, 2);
            g.ReleaseHdc(dc);
            if (!ok) throw new Exception("PrintWindow failed");
        }
        return bmp;
    }

    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
    public static bool Focus(IntPtr h) {
        if (IsIconic(h)) ShowWindow(h, 9);  // SW_RESTORE
        SetForegroundWindow(h);
        Thread.Sleep(150);
        if (GetForegroundWindow() == h) return true;
        // 背景程序不能直接搶前景：暫時接上前景視窗的輸入佇列再設
        uint dummy;
        uint fgThread = GetWindowThreadProcessId(GetForegroundWindow(), out dummy);
        uint me = GetCurrentThreadId();
        AttachThreadInput(me, fgThread, true);
        BringWindowToTop(h);
        SetForegroundWindow(h);
        AttachThreadInput(me, fgThread, false);
        Thread.Sleep(150);
        if (GetForegroundWindow() == h) return true;
        // Alt+Tab 用的切換
        SwitchToThisWindow(h, true);
        Thread.Sleep(250);
        if (GetForegroundWindow() == h) return true;
        // 最後一招：自己送一個輸入（F24，一般程式不理它），送出輸入的程序可以換前景
        Key(0x87, false); Key(0x87, true);
        SetForegroundWindow(h);
        Thread.Sleep(150);
        return GetForegroundWindow() == h;
    }
    [DllImport("user32.dll")] static extern void SwitchToThisWindow(IntPtr h, bool altTab);

    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hgt, bool repaint);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);

    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
    [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr h, uint flags);
    public static IntPtr RootAt(int x, int y) {
        var p = new POINT { X = x, Y = y };
        IntPtr h = WindowFromPoint(p);
        return h == IntPtr.Zero ? h : GetAncestor(h, 2);  // GA_ROOT
    }
    [DllImport("user32.dll")] static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out POINT p);
    public static void MoveTo(int x, int y) { SetCursorPos(x, y); }
    public static POINT Cursor() { POINT p; GetCursorPos(out p); return p; }

    [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] struct UNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public UNION u; }
    [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
    [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint type);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern short VkKeyScan(char c);
    static void Send(INPUT i) {
        if (SendInput(1, new[] { i }, Marshal.SizeOf(typeof(INPUT))) != 1)
            throw new Exception("SendInput failed: " + Marshal.GetLastWin32Error());
    }
    // 滑鼠：MOVE 0x1、LEFTDOWN 0x2、LEFTUP 0x4、RIGHTDOWN 0x8、RIGHTUP 0x10、MIDDLEDOWN 0x20、MIDDLEUP 0x40、WHEEL 0x800
    public static void Mouse(uint flags, int dx, int dy, int data) {
        var i = new INPUT { type = 0 };
        i.u.mi.dx = dx; i.u.mi.dy = dy; i.u.mi.mouseData = unchecked((uint)data); i.u.mi.dwFlags = flags;
        Send(i);
    }
    // 鍵盤用掃描碼送（遊戲讀掃描碼；一般程式由系統換回虛擬鍵碼）
    public static void Key(ushort vk, bool up) {
        var i = new INPUT { type = 1 };
        uint flags = 0x0008;  // KEYEVENTF_SCANCODE
        if (IsExtended(vk)) flags |= 0x0001;
        if (vk == 0x13) flags = 0;  // Pause 的掃描碼是 E1 1D 45，送不出來 → 用虛擬鍵碼（REDkit 讀虛擬鍵碼）
        if (up) flags |= 0x0002;
        i.u.ki.wVk = vk; i.u.ki.wScan = (ushort)MapVirtualKey(vk, 0); i.u.ki.dwFlags = flags;
        Send(i);
    }
    static bool IsExtended(ushort vk) {
        switch (vk) {
            case 0x21: case 0x22: case 0x23: case 0x24: case 0x25: case 0x26: case 0x27: case 0x28:
            case 0x2D: case 0x2E: case 0x5B: case 0x5C: case 0x5D: case 0x6F: case 0xA3: case 0xA5:
                return true;
        }
        return false;
    }
    public static void Char(char c) {
        foreach (bool up in new[] { false, true }) {
            var i = new INPUT { type = 1 };
            i.u.ki.wScan = c; i.u.ki.dwFlags = 0x0004u | (up ? 0x0002u : 0u);  // KEYEVENTF_UNICODE
            Send(i);
        }
    }
}
'@
[Desk]::Init()

function Get-ProcName([IntPtr]$h) {
    $p = Get-Process -Id ([Desk]::Pid($h)) -ErrorAction SilentlyContinue
    if ($p) { $p.ProcessName.ToLower() } else { '?' }
}

function Assert-Allowed([IntPtr]$h, [string]$what) {
    $name = Get-ProcName $h
    if ($Allowed -notcontains $name) {
        throw "擋下：$what 會送到程序 '$name'（視窗 0x$($h.ToString('X'))「$([Desk]::Title($h))」），不在允許名單 $($Allowed -join ', ')"
    }
}

function Find-Win([string]$spec) {
    if ($spec -match '^(0x[0-9a-fA-F]+|\d+)$') {
        $base = if ($spec -like '0x*') { 16 } else { 10 }
        return [IntPtr][Convert]::ToInt64($spec, $base)
    }
    $hits = foreach ($h in [Desk]::TopWindows()) {
        $title = [Desk]::Title($h)
        if (-not $title) { continue }
        if ($spec -like 'proc:*') { if ((Get-ProcName $h) -eq $spec.Substring(5).ToLower()) { $h } }
        elseif ($title -like "*$spec*") { $h }
    }
    $hits = @($hits)
    if ($hits.Count -eq 0) { throw "找不到視窗：$spec" }
    if ($hits.Count -gt 1) {
        Write-Host "（$spec 符合 $($hits.Count) 個視窗，用第一個；其他：$(($hits | Select-Object -Skip 1 | ForEach-Object { '0x' + $_.ToString('X') }) -join ', ')）"
    }
    return $hits[0]
}

function Get-Opts($list) {
    $o = @{}
    foreach ($a in $list) { if ($a -match '^(\w+)=(.*)$') { $o[$Matches[1]] = $Matches[2] } }
    $o
}

function Save-Shot([int]$x, [int]$y, [int]$w, [int]$h, [string]$out, [double]$scale, [int]$grid, $bmp = $null) {
    if ($null -eq $bmp) {
        $bmp = New-Object System.Drawing.Bitmap $w, $h
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($x, $y, 0, 0, (New-Object System.Drawing.Size $w, $h))
        $g.Dispose()
    }
    $sw = [int][Math]::Round($w * $scale); $sh = [int][Math]::Round($h * $scale)
    $img = New-Object System.Drawing.Bitmap $sw, $sh
    $g = [System.Drawing.Graphics]::FromImage($img)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($bmp, 0, 0, $sw, $sh)
    if ($grid -gt 0) {
        # 格線標的是螢幕座標
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(110, 255, 0, 255)), 1
        $font = New-Object System.Drawing.Font 'Consolas', 9
        $brush = [System.Drawing.Brushes]::Magenta
        $back = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(170, 0, 0, 0))
        for ($gx = [Math]::Ceiling($x / $grid) * $grid; $gx -lt $x + $w; $gx += $grid) {
            $px = ($gx - $x) * $scale
            $g.DrawLine($pen, $px, 0, $px, $sh)
            $g.FillRectangle($back, $px + 1, 1, 34, 13); $g.DrawString("$gx", $font, $brush, $px + 1, 0)
        }
        for ($gy = [Math]::Ceiling($y / $grid) * $grid; $gy -lt $y + $h; $gy += $grid) {
            $py = ($gy - $y) * $scale
            $g.DrawLine($pen, 0, $py, $sw, $py)
            $g.FillRectangle($back, 1, $py + 1, 34, 13); $g.DrawString("$gy", $font, $brush, 1, $py)
        }
    }
    $g.Dispose(); $bmp.Dispose()
    $img.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
    "存好 $out：螢幕範圍 ($x, $y) 起 ${w}x${h}，縮放 $scale → 螢幕座標 = ($x, $y) + 圖上座標 / $scale"
}

$Buttons = @{ left = @(0x2, 0x4); right = @(0x8, 0x10); middle = @(0x20, 0x40) }

$Vk = @{
    enter = 0x0D; esc = 0x1B; escape = 0x1B; tab = 0x09; space = 0x20; backspace = 0x08; delete = 0x2E; del = 0x2E
    insert = 0x2D; home = 0x24; end = 0x23; pageup = 0x21; pagedown = 0x22
    pause = 0x13  # Pause Break：REDkit 開的遊戲中，焦點回編輯器、遊戲暫停（Wiki「Useful shortcuts」）
    left = 0x25; up = 0x26; right = 0x27; down = 0x28
    ctrl = 0x11; control = 0x11; shift = 0x10; alt = 0x12; win = 0x5B
    oem3 = 0xC0; tilde = 0xC0; minus = 0xBD; equal = 0xBB; comma = 0xBC; period = 0xBE; slash = 0xBF
    semicolon = 0xBA; quote = 0xDE; lbracket = 0xDB; rbracket = 0xDD; backslash = 0xDC
    numplus = 0x6B; numminus = 0x6D; nummul = 0x6A; numdiv = 0x6F; numdot = 0x6E
}
function Get-Vk([string]$name) {
    $n = $name.ToLower()
    if ($Vk.ContainsKey($n)) { return [uint16]$Vk[$n] }
    if ($n -match '^[a-z0-9]$') { return [uint16][char]$n.ToUpper() }
    if ($n -match '^f(\d{1,2})$') { return [uint16](0x6F + [int]$Matches[1]) }
    if ($n -match '^num(\d)$') { return [uint16](0x60 + [int]$Matches[1]) }
    throw "不認得的鍵：$name"
}

function Click-At([int]$x, [int]$y, [string]$button, [int]$count) {
    Assert-Allowed ([Desk]::RootAt($x, $y)) "點擊 ($x, $y)"
    [Desk]::MoveTo($x, $y); Start-Sleep -Milliseconds 60
    $b = $Buttons[$button]
    for ($i = 0; $i -lt $count; $i++) {
        [Desk]::Mouse($b[0], 0, 0, 0); Start-Sleep -Milliseconds 40
        [Desk]::Mouse($b[1], 0, 0, 0); Start-Sleep -Milliseconds 70
    }
}

$cmd = if ($args.Count -gt 0) { $args[0].ToLower() } else { 'help' }
$rest = @($args | Select-Object -Skip 1)

switch ($cmd) {
    'windows' {
        $fg = [Desk]::GetForegroundWindow()
        foreach ($h in [Desk]::TopWindows()) {
            $title = [Desk]::Title($h)
            if (-not $title) { continue }
            $r = [Desk]::Rect($h)
            if ($r.Right - $r.Left -le 1) { continue }
            $mark = if ($h -eq $fg) { '*' } else { ' ' }
            '{0} 0x{1,-8} {2,-18} ({3},{4}) {5}x{6}  {7}' -f $mark, $h.ToString('X'), (Get-ProcName $h), $r.Left, $r.Top, ($r.Right - $r.Left), ($r.Bottom - $r.Top), $title
        }
        '（* = 前景視窗）'
    }
    'shot' {
        $o = Get-Opts $rest
        $scale = if ($o.scale) { [double]$o.scale } else { 0.5 }
        $grid = if ($o.grid) { [int]$o.grid } else { 0 }
        if ($o.rect) { $x, $y, $w, $h = $o.rect -split ',' | ForEach-Object { [int]$_ } }
        else {
            $vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
            $x = $vs.X; $y = $vs.Y; $w = $vs.Width; $h = $vs.Height
        }
        Save-Shot $x $y $w $h $rest[0] $scale $grid
    }
    'burst' {
        # 連拍（看跳躍、落地等快速的動作；一個程序裡拍，間隔準，2026-10-16 加）
        # 先按住 hold 的鍵、等 pre 毫秒、按一下 key，接著每 <間隔> 毫秒拍一張；最後放開 hold 的鍵、存成 前綴1.png、前綴2.png…
        Assert-Allowed ([Desk]::GetForegroundWindow()) 'burst'
        $o = Get-Opts $rest
        $n = [int]$rest[1]; $iv = [int]$rest[2]
        $scale = if ($o.scale) { [double]$o.scale } else { 0.5 }
        if ($o.rect) { $x, $y, $w, $h = $o.rect -split ',' | ForEach-Object { [int]$_ } }
        else {
            $vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
            $x = $vs.X; $y = $vs.Y; $w = $vs.Width; $h = $vs.Height
        }
        $holds = @(); if ($o.hold) { $holds = @($o.hold -split ',' | ForEach-Object { Get-Vk $_ }) }
        foreach ($k in $holds) { [Desk]::Key($k, $false); Start-Sleep -Milliseconds 20 }
        if ($o.pre) { Start-Sleep -Milliseconds ([int]$o.pre) }
        # key 可以用逗號給好幾個，依序各按一下、間隔 80 毫秒（例：key=shift,shift 騎馬時連按兩下 = 全速奔馳；2026-10-16 23:1x 加）
        if ($o.key) {
            foreach ($kn in ($o.key -split ',')) { $kk = Get-Vk $kn; [Desk]::Key($kk, $false); Start-Sleep -Milliseconds 40; [Desk]::Key($kk, $true); Start-Sleep -Milliseconds 80 }
        }
        # keyhold：按完 key 之後再按住這些鍵，到連拍結束才放開（例：key=shift keyhold=shift = 點一下、第二下按住）
        if ($o.keyhold) {
            foreach ($kn in ($o.keyhold -split ',')) { $kk = Get-Vk $kn; [Desk]::Key($kk, $false); $holds += $kk; Start-Sleep -Milliseconds 20 }
        }
        # mouse：按住滑鼠鍵到連拍結束（例：拿出 AK 到第一發的時間；第一張 = 按下的那一刻；2026-10-18 加）
        $mb = $null
        if ($o.mouse) {
            $mb = $o.mouse.ToLower(); $p = [Desk]::Cursor()
            Assert-Allowed ([Desk]::RootAt($p.X, $p.Y)) "滑鼠 $mb ($($p.X), $($p.Y))"
            [Desk]::Mouse($Buttons[$mb][0], 0, 0, 0)
        }
        $sw = [Diagnostics.Stopwatch]::StartNew(); $frames = @(); $times = @()
        for ($i = 0; $i -lt $n; $i++) {
            $bmp = New-Object System.Drawing.Bitmap $w, $h
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.CopyFromScreen($x, $y, 0, 0, (New-Object System.Drawing.Size $w, $h))
            $g.Dispose()
            $frames += $bmp; $times += $sw.ElapsedMilliseconds
            $wait = ($i + 1) * $iv - $sw.ElapsedMilliseconds
            if ($wait -gt 0) { Start-Sleep -Milliseconds $wait }
        }
        if ($mb) { [Desk]::Mouse($Buttons[$mb][1], 0, 0, 0) }
        [array]::Reverse($holds)
        foreach ($k in $holds) { [Desk]::Key($k, $true); Start-Sleep -Milliseconds 20 }
        for ($i = 0; $i -lt $n; $i++) { Save-Shot $x $y $w $h "$($rest[0])$($i + 1).png" $scale 0 $frames[$i] | Out-Null }
        "連拍 $n 張（毫秒：$($times -join ' ')）"
    }
    'wshot' {
        $hw = Find-Win $rest[0]
        $o = Get-Opts $rest
        $scale = if ($o.scale) { [double]$o.scale } else { 1.0 }
        $grid = if ($o.grid) { [int]$o.grid } else { 0 }
        if ($o.mode -eq 'print') {
            # 被擋住也截得到（視窗不用叫到前面）
            $r = New-Object Desk+RECT
            [void][Desk]::GetWindowRect($hw, [ref]$r)
            $bmp = [Desk]::Print($hw)
            Save-Shot $r.Left $r.Top $bmp.Width $bmp.Height $rest[1] $scale $grid $bmp
        } else {
            $r = [Desk]::Rect($hw)
            Save-Shot $r.Left $r.Top ($r.Right - $r.Left) ($r.Bottom - $r.Top) $rest[1] $scale $grid
        }
    }
    'focus' {
        # 只換前景、不送輸入 → 不限程序（做完把終端機叫回來給使用者看）
        $hw = Find-Win $rest[0]
        if ([Desk]::Focus($hw)) { "前景：0x$($hw.ToString('X'))「$([Desk]::Title($hw))」" }
        else { throw "叫不到前面；現在的前景：「$([Desk]::Title([Desk]::GetForegroundWindow()))」" }
    }
    'place' {
        $hw = Find-Win $rest[0]
        Assert-Allowed $hw '移動視窗'
        $x, $y, $w, $h = $rest[1..4] | ForEach-Object { [int]$_ }
        [void][Desk]::MoveWindow($hw, $x, $y, $w, $h, $true)
        $r = [Desk]::Rect($hw); "視窗移到 ($($r.Left), $($r.Top)) $($r.Right - $r.Left)x$($r.Bottom - $r.Top)"
    }
    'close' {
        # 等於按視窗的 X（WM_CLOSE）；程式要問存檔的話會跳出問題視窗
        $hw = Find-Win $rest[0]
        Assert-Allowed $hw '關視窗'
        [void][Desk]::PostMessage($hw, 0x10, [IntPtr]::Zero, [IntPtr]::Zero)
        "送出關閉：0x$($hw.ToString('X'))「$([Desk]::Title($hw))」"
    }
    'click' {
        $button = if ($rest.Count -ge 3) { $rest[2].ToLower() } else { 'left' }
        $count = if ($rest.Count -ge 4) { [int]$rest[3] } else { 1 }
        Click-At ([int]$rest[0]) ([int]$rest[1]) $button $count
        "點了 ($($rest[0]), $($rest[1])) $button ×$count"
    }
    { $_ -in 'down', 'up' } {
        $button = if ($rest.Count -ge 1) { $rest[0].ToLower() } else { 'left' }
        $p = [Desk]::Cursor()
        Assert-Allowed ([Desk]::RootAt($p.X, $p.Y)) "滑鼠 $cmd ($($p.X), $($p.Y))"
        $flag = if ($cmd -eq 'down') { $Buttons[$button][0] } else { $Buttons[$button][1] }
        [Desk]::Mouse($flag, 0, 0, 0)
        "$button $cmd 在 ($($p.X), $($p.Y))"
    }
    'move' {
        [Desk]::MoveTo([int]$rest[0], [int]$rest[1])
        $p = [Desk]::Cursor(); "游標 ($($p.X), $($p.Y))"
    }
    'rmove' {
        $p = [Desk]::Cursor()
        Assert-Allowed ([Desk]::GetForegroundWindow()) '相對移動'
        $steps = if ($rest.Count -ge 3) { [int]$rest[2] } else { 1 }
        $wait = if ($rest.Count -ge 4) { [int]$rest[3] } else { 10 }
        $dx = [int]$rest[0]; $dy = [int]$rest[1]; $sx = 0; $sy = 0
        for ($i = 1; $i -le $steps; $i++) {
            $nx = [int][Math]::Round($dx * $i / $steps) - $sx; $ny = [int][Math]::Round($dy * $i / $steps) - $sy
            [Desk]::Mouse(0x1, $nx, $ny, 0); $sx += $nx; $sy += $ny
            Start-Sleep -Milliseconds $wait
        }
        "相對移動 ($dx, $dy)，分 $steps 次"
    }
    'drag' {
        $x1, $y1, $x2, $y2 = $rest[0..3] | ForEach-Object { [int]$_ }
        Assert-Allowed ([Desk]::RootAt($x1, $y1)) "拖曳起點 ($x1, $y1)"
        Assert-Allowed ([Desk]::RootAt($x2, $y2)) "拖曳終點 ($x2, $y2)"
        [Desk]::MoveTo($x1, $y1); Start-Sleep -Milliseconds 80
        [Desk]::Mouse(0x2, 0, 0, 0); Start-Sleep -Milliseconds 120
        for ($i = 1; $i -le 10; $i++) {
            [Desk]::MoveTo([int]($x1 + ($x2 - $x1) * $i / 10), [int]($y1 + ($y2 - $y1) * $i / 10)); Start-Sleep -Milliseconds 30
        }
        Start-Sleep -Milliseconds 120
        [Desk]::Mouse(0x4, 0, 0, 0)
        "拖曳 ($x1, $y1) → ($x2, $y2)"
    }
    'wheel' {
        $x = [int]$rest[0]; $y = [int]$rest[1]
        Assert-Allowed ([Desk]::RootAt($x, $y)) "捲動 ($x, $y)"
        [Desk]::MoveTo($x, $y); Start-Sleep -Milliseconds 60
        [Desk]::Mouse(0x800, 0, 0, 120 * [int]$rest[2])
        "捲動 $($rest[2]) 格"
    }
    'key' {
        Assert-Allowed ([Desk]::GetForegroundWindow()) "按鍵 $($rest[0])"
        $keys = @($rest[0] -split '\+' | ForEach-Object { Get-Vk $_ })
        $hold = if ($rest.Count -ge 2) { [int]$rest[1] } else { 40 }
        foreach ($k in $keys) { [Desk]::Key($k, $false); Start-Sleep -Milliseconds 20 }
        Start-Sleep -Milliseconds $hold
        [array]::Reverse($keys)
        foreach ($k in $keys) { [Desk]::Key($k, $true); Start-Sleep -Milliseconds 20 }
        "按了 $($rest[0])"
    }
    'type' {
        Assert-Allowed ([Desk]::GetForegroundWindow()) '打字'
        foreach ($c in ($rest -join ' ').ToCharArray()) { [Desk]::Char($c); Start-Sleep -Milliseconds 15 }
        "打了 $($rest -join ' ')"
    }
    'typepath' {
        # 檔案視窗不接受正斜線（2026-10-16 實測：The filename is not valid）；Bash 裡寫反斜線容易被吃掉 → 這裡換
        Assert-Allowed ([Desk]::GetForegroundWindow()) '打字'
        $p = ($rest -join ' ').Replace('/', '\')
        foreach ($c in $p.ToCharArray()) { [Desk]::Char($c); Start-Sleep -Milliseconds 15 }
        "打了 $p"
    }
    { $_ -in 'keydown', 'keyup' } {
        # 分開按住、放開（例：按住 Tab 開輪盤時截圖）；按住之後一定要 keyup
        Assert-Allowed ([Desk]::GetForegroundWindow()) "$cmd $($rest[0])"
        [Desk]::Key((Get-Vk $rest[0]), $cmd -eq 'keyup')
        "$cmd $($rest[0])"
    }
    'keys' {
        # 逐字按鍵輸入（遊戲的主控台不吃 Unicode 輸入，2026-10-16 實測）：VkKeyScan 找鍵和要不要按 Shift
        Assert-Allowed ([Desk]::GetForegroundWindow()) '按鍵輸入'
        foreach ($c in ($rest -join ' ').ToCharArray()) {
            $vs = [Desk]::VkKeyScan($c)
            if ($vs -eq -1) { throw "鍵盤上找不到：$c" }
            $vk = [uint16]($vs -band 0xFF); $shift = ($vs -band 0x100) -ne 0
            if ($shift) { [Desk]::Key(0x10, $false); Start-Sleep -Milliseconds 10 }
            [Desk]::Key($vk, $false); Start-Sleep -Milliseconds 20; [Desk]::Key($vk, $true)
            if ($shift) { Start-Sleep -Milliseconds 10; [Desk]::Key(0x10, $true) }
            Start-Sleep -Milliseconds 20
        }
        "按鍵輸入 $($rest -join ' ')"
    }
    'uia' {
        Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
        $hw = Find-Win $rest[0]
        $max = if ($rest.Count -ge 2) { [int]$rest[1] } else { 4 }
        $filter = if ($rest.Count -ge 3) { $rest[2] } else { '' }
        $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
        function Dump($el, [int]$depth) {
            $child = $walker.GetFirstChild($el)
            while ($null -ne $child) {
                $c = $child.Current; $r = $c.BoundingRectangle
                $rs = if ($r.IsEmpty) { '[]' } else { "[$([int]$r.X),$([int]$r.Y) $([int]$r.Width)x$([int]$r.Height)]" }
                $line = ('  ' * $depth) + "$($c.ControlType.ProgrammaticName -replace '^ControlType\.', '') '$($c.Name)' $rs class=$($c.ClassName) id=$($c.AutomationId)"
                if (-not $filter -or $line -like "*$filter*") { $line }
                if ($depth + 1 -lt $max) { Dump $child ($depth + 1) }
                $child = $walker.GetNextSibling($child)
            }
        }
        Dump ([System.Windows.Automation.AutomationElement]::FromHandle($hw)) 0
    }
    'invoke' {
        Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
        $hw = Find-Win $rest[0]
        Assert-Allowed $hw '按下元件'
        $name = ($rest | Select-Object -Skip 1) -join ' '
        $A = [System.Windows.Automation.AutomationElement]
        $el = $A::FromHandle($hw).FindFirst([System.Windows.Automation.TreeScope]::Descendants,
            (New-Object System.Windows.Automation.PropertyCondition($A::NameProperty, $name)))
        if ($null -eq $el) { throw "找不到名稱是「$name」的元件" }
        $pat = $null
        if ($el.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$pat)) {
            $pat.Invoke(); "Invoke「$name」"
        } else {
            $r = $el.Current.BoundingRectangle
            Click-At ([int]($r.X + $r.Width / 2)) ([int]($r.Y + $r.Height / 2)) 'left' 1
            "點了「$name」的中心"
        }
    }
    'awake' {
        # 保持清醒：系統不睡眠、螢幕不關（使用者的設定是 30 分鐘沒動作就睡眠；睡著、鎖定後截圖和輸入都失效）
        # 只在這個程序活著的時候有效；程序結束（時間到或被關掉）就回到原本的設定
        $sec = if ($rest.Count -ge 1) { [int]$rest[0] } else { 604800 }
        Add-Type -Namespace Gfg -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
        [void][Gfg.Power]::SetThreadExecutionState([uint32]2147483651)  # ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
        "保持清醒 $sec 秒（$(Get-Date -Format 'MM-dd HH:mm') 起）"
        Start-Sleep -Seconds $sec
    }
    'cursor' {
        $p = [Desk]::Cursor(); $h = [Desk]::RootAt($p.X, $p.Y)
        "游標 ($($p.X), $($p.Y))：視窗 0x$($h.ToString('X')) $(Get-ProcName $h)「$([Desk]::Title($h))」"
    }
    default { Get-Content $PSCommandPath -TotalCount 33 | Select-Object -Skip 1 }
}
