param(
    [Parameter(Mandatory=$true)]
    [string]$Source
)

if (-not (Test-Path $Source)) {
    Write-Error "Arquivo nao encontrado: $Source"
    exit 1
}

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path $PSScriptRoot -Parent
$resPath = Join-Path $projectRoot "android\app\src\main\res"

$sizes = @(
    @{ folder = "mipmap-mdpi";    size = 48  },
    @{ folder = "mipmap-hdpi";    size = 72  },
    @{ folder = "mipmap-xhdpi";   size = 96  },
    @{ folder = "mipmap-xxhdpi";  size = 144 },
    @{ folder = "mipmap-xxxhdpi"; size = 192 }
)

Write-Host ""
Write-Host "Zoeira Car - Gerando icones Android..."
Write-Host ""

$src = [System.Drawing.Image]::FromFile((Resolve-Path $Source).Path)

foreach ($item in $sizes) {
    $outFolder = Join-Path $resPath $item.folder
    $sz = $item.size

    # ic_launcher.png
    $outPath = Join-Path $outFolder "ic_launcher.png"
    $bmp = New-Object System.Drawing.Bitmap($sz, $sz)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, 0, 0, $sz, $sz)
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "  OK $($item.folder)\ic_launcher.png ($sz x $sz)"

    # ic_launcher_round.png
    $outPathR = Join-Path $outFolder "ic_launcher_round.png"
    $bmpR = New-Object System.Drawing.Bitmap($sz, $sz)
    $gR = [System.Drawing.Graphics]::FromImage($bmpR)
    $gR.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gR.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $gR.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gR.DrawImage($src, 0, 0, $sz, $sz)
    $bmpR.Save($outPathR, [System.Drawing.Imaging.ImageFormat]::Png)
    $gR.Dispose(); $bmpR.Dispose()
    Write-Host "  OK $($item.folder)\ic_launcher_round.png ($sz x $sz)"
}

# 512x512 para o Play Store
$playOut = Join-Path $projectRoot "assets\images\ic_launcher_playstore.png"
$bmpPlay = New-Object System.Drawing.Bitmap(512, 512)
$gPlay = [System.Drawing.Graphics]::FromImage($bmpPlay)
$gPlay.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gPlay.DrawImage($src, 0, 0, 512, 512)
$bmpPlay.Save($playOut, [System.Drawing.Imaging.ImageFormat]::Png)
$gPlay.Dispose(); $bmpPlay.Dispose()
Write-Host "  OK assets\images\ic_launcher_playstore.png (512 x 512)"

$src.Dispose()

Write-Host ""
Write-Host "Todos os icones gerados com sucesso!"
Write-Host ""
Write-Host "PROXIMO PASSO: flutter build appbundle --release"
Write-Host ""
