[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Title
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw "Run this script inside the zucchini-lab Git repository." }
Set-Location $repoRoot

$reserved = @("api", "assets", "factory", "games", "public", "src", "docs", "main", "admin")
if ($Slug -in $reserved) { throw "Reserved game slug: $Slug" }

$gameFolder = Join-Path $repoRoot $Slug
if (Test-Path -LiteralPath $gameFolder) {
    throw "The game folder already exists. Nothing was changed: $Slug/"
}

$safeTitle = [Net.WebUtility]::HtmlEncode($Title.Trim())
$html = @"
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#111827">
  <title>$safeTitle</title>
  <style>
    * { box-sizing: border-box; }
    html, body { min-height: 100%; margin: 0; }
    body { display: grid; place-items: center; padding: 24px; color: #fff; background: #111827; font-family: system-ui, sans-serif; }
    main { width: min(100%, 560px); text-align: center; }
  </style>
</head>
<body>
  <main>
    <h1>$safeTitle</h1>
    <p>ゲームを準備中です。</p>
  </main>
</body>
</html>
"@

New-Item -ItemType Directory -Path $gameFolder -ErrorAction Stop | Out-Null
[IO.File]::WriteAllText((Join-Path $gameFolder "index.html"), $html, [Text.UTF8Encoding]::new($false))

[PSCustomObject]@{
    Game = $Title.Trim()
    Slug = $Slug
    Folder = $gameFolder
    PublicUrl = "https://kotaro0505.github.io/zucchini-lab/$Slug/"
}
