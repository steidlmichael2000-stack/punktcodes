<#
    make-icons.ps1 - erzeugt die PWA-Icons (Vermessungspunkt-Symbol).
    Muss nur einmal laufen bzw. wenn sich das Icon aendern soll.
#>
[CmdletBinding()] param()
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function New-Icon {
    param(
        [int]    $Size,
        [string] $Path,
        [double] $Inset   # Anteil Rand (maskable braucht mehr Luft)
    )
    $bmp = [System.Drawing.Bitmap]::new($Size, $Size)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'

    $bg = [System.Drawing.Color]::FromArgb(11, 61, 98)      # #0b3d62
    $g.Clear($bg)

    $fg  = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $pad = $Size * $Inset
    $box = $Size - 2 * $pad
    $cx  = $Size / 2.0
    $stroke = [math]::Max(2.0, $Size * 0.055)
    $pen = [System.Drawing.Pen]::new($fg, $stroke)
    $pen.StartCap = 'Round'; $pen.EndCap = 'Round'

    # Kreis
    $r = $box * 0.34
    $g.DrawEllipse($pen, [float]($cx - $r), [float]($cx - $r), [float](2 * $r), [float](2 * $r))

    # Kreuz durch den Kreis (Vermessungspunkt)
    $arm = $box * 0.48
    $g.DrawLine($pen, [float]($cx - $arm), [float]$cx, [float]($cx + $arm), [float]$cx)
    $g.DrawLine($pen, [float]$cx, [float]($cx - $arm), [float]$cx, [float]($cx + $arm))

    # Mittelpunkt
    $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 209, 102))
    $d = $box * 0.10
    $g.FillEllipse($accent, [float]($cx - $d), [float]($cx - $d), [float](2 * $d), [float](2 * $d))

    $g.Dispose()
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  $([System.IO.Path]::GetFileName($Path)) ($Size x $Size)"
}

$root = $PSScriptRoot
Write-Host "Icons werden erzeugt:" -ForegroundColor Cyan
New-Icon -Size 192 -Path (Join-Path $root "icon-192.png")          -Inset 0.14
New-Icon -Size 512 -Path (Join-Path $root "icon-512.png")          -Inset 0.14
New-Icon -Size 512 -Path (Join-Path $root "icon-maskable-512.png") -Inset 0.22
Write-Host "Fertig." -ForegroundColor Green
