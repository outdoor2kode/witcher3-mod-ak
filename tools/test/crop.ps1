# 裁切放大：crop.ps1 in.png out.png x y w h [倍數=3]（g.sh 的 crop 會叫）
param([string]$in, [string]$out, [int]$x, [int]$y, [int]$w, [int]$h, [double]$s = 3)
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile($in)
$dst = New-Object System.Drawing.Bitmap ([int]($w * $s)), ([int]($h * $s))
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $dst.Width, $dst.Height), (New-Object System.Drawing.Rectangle $x, $y, $w, $h), [System.Drawing.GraphicsUnit]::Pixel)
$dst.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $dst.Dispose(); $src.Dispose()
"ok $out"
