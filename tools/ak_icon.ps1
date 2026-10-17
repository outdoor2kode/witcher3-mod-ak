<#
做 AK 的物品圖示（第 21 項，2026-10-18）：CS2 物品欄的 AK 圖（512×384，透明背景）→ 巫師3 的直式圖示 64×128
用法：powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/ak_icon.ps1 <CS2 的 PNG> <輸出 PNG> [角度=88.2] [陰影=1]
- 來源：CS2 VPK 的 panorama/images/econ/weapons/base_weapons/weapon_ak47_png.vtex_c（tools/vpk_extract.py 取出、Source2Viewer-CLI 轉 PNG）
- 擺法照原版十字弩圖示（gameplay/gui_new/icons/inventory/weapons/crossbow/witcher_crossbow_lvl1_64x128.png）：直放、上端偏右、下端偏左、右下有淡陰影
  - 角度：來源圖裡槍托 (497,235) → 槍口 (10,115) 的方向 −166.2°；轉成往上偏右 12°（−78°）→ 順時針 88.2°
- 只用 Windows 內建的 System.Drawing（GDI+）
#>
param(
    [Parameter(Mandatory = $true)][string]$Src,
    [Parameter(Mandatory = $true)][string]$Out,
    [double]$Angle = 88.2,
    [int]$Shadow = 1
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Get-AlphaBox([System.Drawing.Bitmap]$bmp) {
    $minX = $bmp.Width; $minY = $bmp.Height; $maxX = -1; $maxY = -1
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            if ($bmp.GetPixel($x, $y).A -gt 8) {
                if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    return [System.Drawing.Rectangle]::new($minX, $minY, $maxX - $minX + 1, $maxY - $minY + 1)
}

function New-Graphics([System.Drawing.Bitmap]$bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    return $g
}

$srcBmp = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Src))

# 1. 轉：放進夠大的正方形畫布中央再轉（不會切到）
$side = [int][Math]::Ceiling([Math]::Sqrt($srcBmp.Width * $srcBmp.Width + $srcBmp.Height * $srcBmp.Height)) + 4
$rot = New-Object System.Drawing.Bitmap $side, $side, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = New-Graphics $rot
$g.TranslateTransform($side / 2, $side / 2)
$g.RotateTransform($Angle)
$g.DrawImage($srcBmp, - $srcBmp.Width / 2, - $srcBmp.Height / 2, $srcBmp.Width, $srcBmp.Height)
$g.Dispose()

# 2. 裁到不透明的範圍，等比例縮進 64×128（留 3 像素邊；陰影往右下 2 像素）
$box = Get-AlphaBox $rot
$W = 64; $H = 128; $margin = 3
$scale = [Math]::Min(($W - 2 * $margin - 2) / $box.Width, ($H - 2 * $margin - 2) / $box.Height)
$dw = $box.Width * $scale; $dh = $box.Height * $scale
$dx = ($W - 2 - $dw) / 2; $dy = ($H - 2 - $dh) / 2
$icon = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = New-Graphics $icon
$dst = [System.Drawing.RectangleF]::new($dx, $dy, $dw, $dh)

# 3. 陰影：黑色、低透明度，往右下 2 像素，在周圍 3×3 個位置各畫一次（簡單的模糊）
if ($Shadow) {
    $cm = New-Object System.Drawing.Imaging.ColorMatrix
    $cm.Matrix00 = 0; $cm.Matrix11 = 0; $cm.Matrix22 = 0; $cm.Matrix33 = 0.07
    $ia = New-Object System.Drawing.Imaging.ImageAttributes
    $ia.SetColorMatrix($cm)
    foreach ($ox in -1, 0, 1) {
        foreach ($oy in -1, 0, 1) {
            $r = [System.Drawing.Rectangle]::new([int][Math]::Round($dx + 2 + $ox), [int][Math]::Round($dy + 2 + $oy), [int][Math]::Round($dw), [int][Math]::Round($dh))
            $g.DrawImage($rot, $r, $box.X, $box.Y, $box.Width, $box.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
        }
    }
}
$g.DrawImage($rot, $dst, [System.Drawing.RectangleF]::new($box.X, $box.Y, $box.Width, $box.Height), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()

$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
$icon.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"輸出 $Out（${W}×${H}；裁切範圍 $($box.Width)×$($box.Height)、縮放 $([Math]::Round($scale, 4))）"
$srcBmp.Dispose(); $rot.Dispose(); $icon.Dispose()
