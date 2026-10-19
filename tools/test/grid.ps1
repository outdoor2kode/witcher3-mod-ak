# 多張圖拼成格子：grid.ps1 out.png 每行張數 裁切x:y:w:h（0:0:0:0 = 不裁） in1.png in2.png ...（g.sh 的 gridm 會叫）
# 每格左上角寫編號（第幾張）
param([string]$Out, [int]$Cols, [string]$Crop, [Parameter(ValueFromRemainingArguments=$true)][string[]]$Ins)
Add-Type -AssemblyName System.Drawing
$cx, $cy, $cw, $ch = $Crop -split '[:,]' | ForEach-Object { [int]$_ }
$imgs = $Ins | ForEach-Object { [System.Drawing.Image]::FromFile($_) }
if ($cw -le 0) { $cw = $imgs[0].Width; $ch = $imgs[0].Height; $cx = 0; $cy = 0 }
$rows = [math]::Ceiling($imgs.Count / $Cols)
$bmp = New-Object System.Drawing.Bitmap ([int]($cw * $Cols)), ([int]($ch * $rows))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$font = New-Object System.Drawing.Font 'Arial', 14, ([System.Drawing.FontStyle]::Bold)
for ($k = 0; $k -lt $imgs.Count; $k++) {
    $x = ($k % $Cols) * $cw; $y = [math]::Floor($k / $Cols) * $ch
    $src = New-Object System.Drawing.Rectangle $cx, $cy, $cw, $ch
    $dst = New-Object System.Drawing.Rectangle $x, $y, $cw, $ch
    $g.DrawImage($imgs[$k], $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
    $g.FillRectangle([System.Drawing.Brushes]::Black, $x, $y, 30, 22)
    $g.DrawString("$($k + 1)", $font, [System.Drawing.Brushes]::Yellow, $x + 2, $y + 1)
}
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $imgs | ForEach-Object { $_.Dispose() }
"ok $Out"
