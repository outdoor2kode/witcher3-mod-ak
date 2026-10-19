# 把多張圖橫向拼成一張：montage.ps1 out.png in1.png in2.png ...（g.sh 的 mont 會叫）
param([string]$Out, [Parameter(ValueFromRemainingArguments=$true)][string[]]$Ins)
Add-Type -AssemblyName System.Drawing
$imgs = $Ins | ForEach-Object { [System.Drawing.Image]::FromFile($_) }
$w = ($imgs | Measure-Object -Property Width -Sum).Sum
$h = ($imgs | Measure-Object -Property Height -Maximum).Maximum
$bmp = New-Object System.Drawing.Bitmap ([int]$w), ([int]$h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$x = 0
foreach ($i in $imgs) { $g.DrawImage($i, $x, 0, $i.Width, $i.Height); $x += $i.Width }
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $imgs | ForEach-Object { $_.Dispose() }
"ok $Out"
