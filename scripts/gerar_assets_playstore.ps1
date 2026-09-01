Add-Type -AssemblyName System.Drawing

$out = "f:\Kiro Projetcts\zoeira_car\assets\playstore"
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

# Cores do app
$corFundo     = [System.Drawing.ColorTranslator]::FromHtml("#0D0D0D")
$corPrimaria  = [System.Drawing.ColorTranslator]::FromHtml("#E53935")
$corTexto     = [System.Drawing.Color]::White
$corCinza     = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")

# ─────────────────────────────────────────────────────────────
# 1. RECURSO GRAFICO 1024x500 (Feature Graphic)
# ─────────────────────────────────────────────────────────────
Write-Host "Gerando recurso grafico 1024x500..."

$bmp = New-Object System.Drawing.Bitmap(1024, 500)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

# Fundo preto
$g.Clear($corFundo)

# Gradiente vermelho na parte superior
$gradRect  = [System.Drawing.Rectangle]::new(0, 0, 1024, 250)
$gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $gradRect,
    [System.Drawing.ColorTranslator]::FromHtml("#B71C1C"),
    [System.Drawing.ColorTranslator]::FromHtml("#0D0D0D"),
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
)
$g.FillRectangle($gradBrush, $gradRect)
$gradBrush.Dispose()

# Linha vermelha horizontal
$penVerm = New-Object System.Drawing.Pen($corPrimaria, 3)
$g.DrawLine($penVerm, 60, 200, 964, 200)
$penVerm.Dispose()

# Titulo principal
$fonteTitulo = New-Object System.Drawing.Font("Arial", 72, [System.Drawing.FontStyle]::Bold)
$brushBranco = New-Object System.Drawing.SolidBrush($corTexto)
$g.DrawString("ZOEIRA CAR", $fonteTitulo, $brushBranco, 60, 80)
$fonteTitulo.Dispose()

# Subtitulo
$fonteSubt = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Regular)
$brushCinza = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#AAAAAA"))
$g.DrawString("O raio-x completo da sua nave!", $fonteSubt, $brushCinza, 60, 220)
$fonteSubt.Dispose()
$brushCinza.Dispose()

# Tres badges
$fonteTag = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Bold)
$brushVerm = New-Object System.Drawing.SolidBrush($corPrimaria)

$tags = @("Ficha tecnica", "Tabela FIPE", "Problemas cronicos")
$x = 60
foreach ($tag in $tags) {
    $rect = [System.Drawing.RectangleF]::new($x, 310, 200, 48)
    $border = [System.Drawing.Rectangle]::new([int]$x, 310, 200, 48)
    $penTag = New-Object System.Drawing.Pen($corPrimaria, 2)
    $g.DrawRectangle($penTag, $border)
    $penTag.Dispose()
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString($tag, $fonteTag, $brushBranco, $rect, $sf)
    $x += 220
}
$fonteTag.Dispose()
$brushVerm.Dispose()

# Rodape
$fonteRod = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Regular)
$brushRod = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#666666"))
$g.DrawString("Assine por R$ 14,90/mes ou consulte por R$ 7,90", $fonteRod, $brushRod, 60, 420)
$fonteRod.Dispose()
$brushRod.Dispose()

$bmp.Save("$out\feature_graphic.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
$brushBranco.Dispose()
Write-Host "  OK feature_graphic.png (1024x500)"

# ─────────────────────────────────────────────────────────────
# 2. SCREENSHOTS 1080x1920 (9:16)
# ─────────────────────────────────────────────────────────────

function New-Screenshot {
    param([string]$arquivo, [string]$titulo, [string[]]$linhas, [string]$badge, [string]$corBadge)

    $W = 1080; $H = 1920
    $bmp = New-Object System.Drawing.Bitmap($W, $H)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $corF  = [System.Drawing.ColorTranslator]::FromHtml("#0D0D0D")
    $corP  = [System.Drawing.ColorTranslator]::FromHtml("#E53935")
    $corC  = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
    $brBco = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $brCz  = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#AAAAAA"))
    $brPr  = New-Object System.Drawing.SolidBrush($corP)

    $g.Clear($corF)

    # Header vermelho
    $hRect  = [System.Drawing.Rectangle]::new(0, 0, $W, 140)
    $hBrush = New-Object System.Drawing.SolidBrush($corP)
    $g.FillRectangle($hBrush, $hRect)
    $hBrush.Dispose()

    # Nome app no header
    $fHead = New-Object System.Drawing.Font("Arial", 38, [System.Drawing.FontStyle]::Bold)
    $sfC   = New-Object System.Drawing.StringFormat
    $sfC.Alignment = [System.Drawing.StringAlignment]::Center
    $sfC.LineAlignment = [System.Drawing.StringAlignment]::Center
    $headRect = [System.Drawing.RectangleF]::new(0, 0, $W, 140)
    $g.DrawString("ZOEIRA CAR", $fHead, $brBco, $headRect, $sfC)
    $fHead.Dispose()

    # Titulo da tela
    $fTit = New-Object System.Drawing.Font("Arial", 44, [System.Drawing.FontStyle]::Bold)
    $g.DrawString($titulo, $fTit, $brBco, 60, 180)
    $fTit.Dispose()

    # Linha separadora
    $pen = New-Object System.Drawing.Pen($corP, 3)
    $g.DrawLine($pen, 60, 260, $W-60, 260)
    $pen.Dispose()

    # Badge (veredito)
    if ($badge) {
        $badgeColor = [System.Drawing.ColorTranslator]::FromHtml($corBadge)
        $badgeBrush = New-Object System.Drawing.SolidBrush($badgeColor)
        $badgeRect  = [System.Drawing.Rectangle]::new(60, 280, 500, 64)
        $g.FillRectangle($badgeBrush, $badgeRect)
        $badgeBrush.Dispose()
        $fBadge = New-Object System.Drawing.Font("Arial", 26, [System.Drawing.FontStyle]::Bold)
        $sfBadge = New-Object System.Drawing.StringFormat
        $sfBadge.Alignment = [System.Drawing.StringAlignment]::Center
        $sfBadge.LineAlignment = [System.Drawing.StringAlignment]::Center
        $badgeRF = [System.Drawing.RectangleF]::new(60, 280, 500, 64)
        $g.DrawString($badge, $fBadge, $brBco, $badgeRF, $sfBadge)
        $fBadge.Dispose()
    }

    # Cartoes de conteudo
    $y = 380
    $fCard = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Regular)
    $fCardB = New-Object System.Drawing.Font("Arial", 26, [System.Drawing.FontStyle]::Bold)

    foreach ($linha in $linhas) {
        $cardBrush = New-Object System.Drawing.SolidBrush($corC)
        $cardRect  = [System.Drawing.Rectangle]::new(60, $y, $W-120, 110)
        $g.FillRectangle($cardBrush, $cardRect)
        $cardBrush.Dispose()

        # Barra vermelha esquerda
        $barBrush = New-Object System.Drawing.SolidBrush($corP)
        $barRect  = [System.Drawing.Rectangle]::new(60, $y, 8, 110)
        $g.FillRectangle($barBrush, $barRect)
        $barBrush.Dispose()

        $sfCard = New-Object System.Drawing.StringFormat
        $sfCard.LineAlignment = [System.Drawing.StringAlignment]::Center
        $textRect = [System.Drawing.RectangleF]::new(88, $y, $W-180, 110)
        $g.DrawString($linha, $fCard, $brBco, $textRect, $sfCard)

        $y += 130
    }
    $fCard.Dispose()
    $fCardB.Dispose()

    # Rodape
    $fRod = New-Object System.Drawing.Font("Arial", 24, [System.Drawing.FontStyle]::Regular)
    $sfRod = New-Object System.Drawing.StringFormat
    $sfRod.Alignment = [System.Drawing.StringAlignment]::Center
    $rodRect = [System.Drawing.RectangleF]::new(0, $H-120, $W, 80)
    $g.DrawString("zoeiracartv.com.br", $fRod, $brCz, $rodRect, $sfRod)
    $fRod.Dispose()

    $bmp.Save("$out\$arquivo", [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    $brBco.Dispose(); $brCz.Dispose(); $brPr.Dispose()
    Write-Host "  OK $arquivo (1080x1920)"
}

Write-Host "`nGerando screenshots..."

New-Screenshot -arquivo "screenshot_01_home.png" `
    -titulo "Ultimos videos do canal" `
    -linhas @(
        "Assistir no YouTube",
        "Videos do canal Zoeira Car",
        "Conteudo automotivo raiz",
        "Atualizados diariamente",
        "Player integrado no app"
    ) `
    -badge "" -corBadge ""

New-Screenshot -arquivo "screenshot_02_busca.png" `
    -titulo "Busque qualquer nave" `
    -linhas @(
        "Chevrolet Onix  |  ok se barato",
        "Toyota Corolla  |  recomendado",
        "Fiat Marea      |  corre que e cilada",
        "Honda Civic     |  recomendado",
        "Jeep Compass    |  ok se barato"
    ) `
    -badge "" -corBadge ""

New-Screenshot -arquivo "screenshot_03_veredito.png" `
    -titulo "Raio-x completo" `
    -linhas @(
        "Problemas cronicos documentados",
        "Por que comprar (ou evitar)",
        "Ficha tecnica completa",
        "Tabela FIPE atualizada",
        "Historico de confiabilidade"
    ) `
    -badge "Zoeira Car Recomenda!" -corBadge "#2E7D32"

New-Screenshot -arquivo "screenshot_04_assinatura.png" `
    -titulo "Planos e precos" `
    -linhas @(
        "Assinatura: R$ 14,90/mes",
        "Consulta avulsa: R$ 7,90",
        "Acesso ilimitado a todos os carros",
        "Cancele quando quiser",
        "Sem fidelidade"
    ) `
    -badge "" -corBadge ""

Write-Host "`nTodos os assets gerados em: $out"
Write-Host "Arquivos:"
Get-ChildItem $out | Format-Table Name, @{N='KB';E={[int]($_.Length/1KB)}}
