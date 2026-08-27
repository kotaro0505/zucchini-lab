[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Paths,

    [string]$VerifyPath = "",

    [ValidateRange(30, 900)]
    [int]$TimeoutSeconds = 300,

    [ValidateRange(2, 60)]
    [int]$RetrySeconds = 10
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed." }
}

function Get-GhCommand {
    $installed = Get-Command gh -ErrorAction SilentlyContinue
    if ($installed) { return $installed.Source }

    $portable = Join-Path $env:TEMP "codex-gh-2.97.0\bin\gh.exe"
    if (Test-Path -LiteralPath $portable) { return $portable }

    throw "GitHub CLI (gh) is required. Install it and run 'gh auth login'."
}

function Invoke-GhJson {
    param([string]$Gh, [string]$Endpoint)
    $json = & $Gh api $Endpoint
    if ($LASTEXITCODE -ne 0) { throw "GitHub API request failed: $Endpoint" }
    return $json | ConvertFrom-Json
}

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw "Run this script inside a Git repository." }
Set-Location $repoRoot

$branch = (& git branch --show-current).Trim()
if ($branch -ne "main") { throw "Publishing must run from main. Current branch: $branch" }

$deleted = @($Paths | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($deleted.Count -gt 0) {
    throw "Refusing to publish missing/deleted paths without user confirmation: $($deleted -join ', ')"
}

$alreadyStaged = @(& git diff --cached --name-only)
if ($alreadyStaged.Count -gt 0) {
    throw "The index already contains staged changes. Review or unstage them first: $($alreadyStaged -join ', ')"
}

Invoke-Git -Arguments (@("add", "--") + $Paths)
$staged = @(& git diff --cached --name-only)
if ($staged.Count -eq 0) { throw "No changes were staged." }

$allowed = @($Paths | ForEach-Object { ($_ -replace '\\','/').TrimStart('./') })
$unexpected = @($staged | Where-Object { $_ -notin $allowed })
if ($unexpected.Count -gt 0) { throw "Unexpected staged paths: $($unexpected -join ', ')" }

Invoke-Git -Arguments @("commit", "-m", $Message)
$commit = (& git rev-parse HEAD).Trim()
Invoke-Git -Arguments @("push", "origin", "main")

$origin = (& git remote get-url origin).Trim()
if ($origin -notmatch 'github\.com[/:](?<slug>[^/]+/[^/]+?)(?:\.git)?$') {
    throw "Could not derive the GitHub repository from origin: $origin"
}
$slug = $Matches.slug
$parts = $slug.Split('/')
$owner = $parts[0]
$repo = $parts[1]
$gh = Get-GhCommand

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    $build = Invoke-GhJson -Gh $gh -Endpoint "repos/$slug/pages/builds/latest"
    if ($build.commit -eq $commit -and $build.status -eq "built") { break }
    if ($build.commit -eq $commit -and $build.status -eq "errored") {
        throw "GitHub Pages build failed for commit $commit."
    }
    Start-Sleep -Seconds $RetrySeconds
} while ((Get-Date) -lt $deadline)

if ($build.commit -ne $commit -or $build.status -ne "built") {
    throw "Timed out waiting for GitHub Pages to publish commit $commit."
}

$cleanVerifyPath = $VerifyPath.Trim('/')
$suffix = if ($cleanVerifyPath) { "/$cleanVerifyPath/" } else { "/" }
$publicUrl = "https://$owner.github.io/$repo$suffix"
$localFile = if ($cleanVerifyPath) { Join-Path $repoRoot "$cleanVerifyPath\index.html" } else { Join-Path $repoRoot "index.html" }
if (-not (Test-Path -LiteralPath $localFile)) { throw "Verification file not found: $localFile" }
$expected = [IO.File]::ReadAllText($localFile).Replace("`r`n", "`n")

do {
    try {
        $separator = if ($publicUrl.Contains('?')) { '&' } else { '?' }
        $response = Invoke-WebRequest -Uri "$publicUrl${separator}commit=$commit" -UseBasicParsing
        if ($response.StatusCode -eq 200 -and $response.Content.Replace("`r`n", "`n") -eq $expected) { break }
    } catch {
        $response = $null
    }
    Start-Sleep -Seconds $RetrySeconds
} while ((Get-Date) -lt $deadline)

if (-not $response -or $response.StatusCode -ne 200 -or $response.Content.Replace("`r`n", "`n") -ne $expected) {
    throw "Pages built, but the latest file was not confirmed at $publicUrl before timeout."
}

[PSCustomObject]@{
    Commit = $commit
    PagesStatus = $build.status
    StatusCode = $response.StatusCode
    PublicUrl = $publicUrl
}
