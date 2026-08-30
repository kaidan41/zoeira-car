# =============================================================
# ZOEIRA CAR - Gera icones do app (launcher + round)
# Roda com:  powershell -ExecutionPolicy Bypass -File scripts/generate_icons.ps1
# Saida: android/app/src/main/res/mipmap-*/ic_launcher*.png
# =============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$resDir = Join-Path $PSScriptRoot "..\android\app\src\main\res"

# Densidades Android (dpi -> pixels)
$mipmaps = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

function Draw-CarIcon([int]$size, [bool]$round) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # fundo: gradiente vermelho "Zoeira"
    $top    = [System.Drawing.Color]::FromArgb(255, 229, 57, 53)
    $bottom = [System.Drawing.Color]::FromArgb(255, 150, 20, 30)
    $bgRect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
    $gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $bgRect, $top, $bottom, 90.0)

    if ($round) {
        # fundo circular
        $g.FillEllipse($gradBrush, 0, 0, $size, $size)
        # anel branco interno
        $ringBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,31,31,31))
        $ringWidth = [Math]::Max(2, [int]($size * 0.02))
        $g.DrawEllipse((New-Object System.Drawing.Pen($ringBrush, $ringWidth)), $ringWidth, $ringWidth, $size - 2*$ringWidth, $size - 2*$ringWidth)
        $ringBrush.Dispose()
    } else {
        $g.FillRectangle($gradBrush, 0, 0, $size, $size)
    }

    # carroceria branca
    $bodyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $bodyH = [Math]::Max(4, [int]($size * 0.52))
    $bodyY = [int]($size * 0.38)
    $carBody = New-Object System.Drawing.RectangleF(
        [float]($size * 0.22), [float]$bodyY,
        [float]($size * 0.56), [float]$bodyH)
    $carBodyRounded = New-Object System.Drawing.Drawing2D.GraphicsPath
    $radiusBody = [int]($size * 0.06)
    $r = $radiusBody
    $x = $carBody.X; $y = $carBody.Y; $w = $carBody.Width; $h = $carBody.Height
    $carBodyRounded.AddArc($x, $y, 2*$r, 2*$r, 180, 90)
    $carBodyRounded.AddArc($x + $w - 2*$r, $y, 2*$r, 2*$r, 270, 90)
    $carBodyRounded.AddArc($x + $w - 2*$r, $y + $h - 2*$r, 2*$r, 2*$r, 0, 90)
    $carBodyRounded.AddArc($x, $y + $h - 2*$r, 2*$r, 2*$r, 90, 90)
    $carBodyRounded.CloseFigure()
    $g.FillPath($bodyBrush, $carBodyRounded)

    # cabine (janela) escura
    $winBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,31,31,31))
    $g.FillRectangle($winBrush,
        [float]($size * 0.34), [float]($size * 0.24),
        [float]($size * 0.32), [float]($size * 0.24))
    $g.FillPolygon($winBrush, @(
        (New-Object System.Drawing.PointF([float]($size*0.34), [float]($size*0.48))),
        (New-Object System.Drawing.PointF([float]($size*0.42), [float]($size*0.36))),
        (New-Object System.Drawing.PointF([float]($size*0.58), [float]($size*0.36))),
        (New-Object System.Drawing.PointF([float]($size*0.66), [float]($size*0.48)))
    ))

    # pneus
    $tireBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,31,31,31))
    $tireD = [int]($size * 0.20)
    $tireY = [int]($size * 0.72)
    $g.FillEllipse($tireBrush, [int]($size * 0.24), $tireY, $tireD, $tireD)
    $g.FillEllipse($tireBrush, [int]($size * 0.56), $tireY, $tireD, $tireD)

    # calotas cinza
    $hubBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,158,158,158))
    $hubD = [int]($size * 0.08)
    $hubY = $tireY + ($tireD - $hubD) / 2
    $hubX1 = [int]($size * 0.24) + ($tireD - $hubD) / 2
    $hubX2 = [int]($size * 0.56) + ($tireD - $hubD) / 2
    $g.FillEllipse($hubBrush, $hubX1, [int]$hubY, $hubD, $hubD)
    $g.FillEllipse($hubBrush, $hubX2, [int]$hubY, $hubD, $hubD)

    $hubBrush.Dispose(); $tireBrush.Dispose(); $winBrush.Dispose()
    $bodyBrush.Dispose(); $gradBrush.Dispose(); $carBodyRounded.Dispose()
    $g.Dispose()

    return $bmp
}

foreach ($mipmap in $mipmaps.GetEnumerator()) {
    $dir = Join-Path $resDir $mipmap.Key
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $size = $mipmap.Value

    $bmpSquare = Draw-CarIcon $size $false
    $bmpSquare.Save((Join-Path $dir "ic_launcher.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpSquare.Dispose()

    $bmpRound = Draw-CarIcon $size $true
    $bmpRound.Save((Join-Path $dir "ic_launcher_round.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpRound.Dispose()

    Write-Host "OK  $($mipmap.Key) (${size}px)"
}

Write-Host ""
Write-Host "Icones gerados em $resDir\mipmap-*"