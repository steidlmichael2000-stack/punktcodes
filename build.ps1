<#
    build.ps1 - erzeugt index.html aus app.template.html + punktcodes.csv

    Die Codeliste wird direkt in die HTML-Datei eingebettet. Dadurch laeuft die App
    ohne Netz und ohne Server (auch per Doppelklick als lokale Datei).

    Aufruf:
        .\build.ps1                                  # nutzt data\punktcodes.csv
        .\build.ps1 -FromSource                      # liest die Original-CSV aus Lisp_Tools und
                                                     # aktualisiert vorher den Snapshot in data\
        .\build.ps1 -CsvPath "D:\pfad\codes.csv"     # beliebige CSV
#>
[CmdletBinding()]
param(
    [string] $CsvPath,
    [switch] $FromSource,
    [string] $SourceCsv = "C:\Users\msteidl\Desktop\Lisp_Tools\punktcode\punktcodes.csv"
)

$ErrorActionPreference = "Stop"
$root     = $PSScriptRoot
$snapshot = Join-Path $root "data\punktcodes.csv"

# --- Quelle bestimmen -------------------------------------------------------
if ($FromSource) {
    if (-not (Test-Path $SourceCsv)) { throw "Original-CSV nicht gefunden: $SourceCsv" }
    New-Item -ItemType Directory -Force -Path (Split-Path $snapshot) | Out-Null
    # Original ist Windows-1252, Snapshot im Repo ist UTF-8
    $lines = Get-Content -LiteralPath $SourceCsv -Encoding windows-1252
    Set-Content -LiteralPath $snapshot -Value $lines -Encoding utf8NoBOM
    Write-Host "Snapshot aktualisiert aus $SourceCsv" -ForegroundColor Cyan
    $CsvPath = $snapshot
}
elseif (-not $CsvPath) {
    if (-not (Test-Path $snapshot)) { throw "Kein Snapshot vorhanden - einmal mit -FromSource starten." }
    $CsvPath = $snapshot
}
if (-not (Test-Path $CsvPath)) { throw "CSV nicht gefunden: $CsvPath" }

# --- Kodierung erkennen (Snapshot = UTF-8, Original = Windows-1252) ---------
$bytes = [System.IO.File]::ReadAllBytes($CsvPath)
$utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)
try   { $utf8Strict.GetString($bytes) | Out-Null; $enc = "utf8" }
catch { $enc = "windows-1252" }

$rows = Import-Csv -LiteralPath $CsvPath -Delimiter ';' -Encoding $enc
if (-not $rows) { throw "CSV enthaelt keine Datenzeilen." }

$needed = @('Code','Art','Gruppe','Element','Berechnungsart')
$have   = $rows[0].PSObject.Properties.Name
$missing = $needed | Where-Object { $_ -notin $have }
if ($missing) { throw "Spalten fehlen in der CSV: $($missing -join ', ')" }

# --- Kompaktes JSON: eine Zeile je Code, Reihenfolge nach Codenummer -------
$sorted = $rows | Sort-Object { [int]($_.Code -replace '\D','0') }
$items = foreach ($r in $sorted) {
    $tuple = @($r.Code, $r.Art, $r.Gruppe, $r.Element, $r.Berechnungsart) |
             ForEach-Object { ($_ ?? '').Trim() | ConvertTo-Json -Compress }
    '[' + ($tuple -join ',') + ']'
}
$json = "[`n" + ($items -join ",`n") + "`n]"

# --- Einbetten --------------------------------------------------------------
$templatePath = Join-Path $root "app.template.html"
if (-not (Test-Path $templatePath)) { throw "app.template.html fehlt." }
$html   = Get-Content -LiteralPath $templatePath -Raw -Encoding utf8
$marker = '/*__CODES__*/[]'
if (-not $html.Contains($marker)) { throw "Platzhalter $marker im Template nicht gefunden." }

$html = $html.Replace($marker, "/*__CODES__*/$json")
$outPath = Join-Path $root "index.html"
Set-Content -LiteralPath $outPath -Value $html -Encoding utf8NoBOM

$kb = [math]::Round((Get-Item $outPath).Length / 1KB, 1)
Write-Host "index.html geschrieben - $($rows.Count) Codes, $kb KB" -ForegroundColor Green

# --- Cache-Version des Service Workers mitziehen ---------------------------
$swPath = Join-Path $root "sw.js"
if (Test-Path $swPath) {
    $sw  = Get-Content -LiteralPath $swPath -Raw -Encoding utf8
    $sum = [System.BitConverter]::ToString(
               [System.Security.Cryptography.SHA1]::HashData([System.Text.Encoding]::UTF8.GetBytes($html))
           ).Replace('-','').Substring(0,8).ToLower()
    $new = $sw -replace "const CACHE = 'punktcodes-[^']*'", "const CACHE = 'punktcodes-$sum'"
    if ($new -ne $sw) {
        Set-Content -LiteralPath $swPath -Value $new -Encoding utf8NoBOM
        Write-Host "sw.js Cache-Version -> punktcodes-$sum" -ForegroundColor DarkGray
    }
}
