# ─────────────────────────────────────────────────────────────────────────────
# jarvis-graphify installer — Windows (PowerShell)
#
# One-liner install:
#   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dronaprod/jarvis-graphify/main/install.ps1" -OutFile install.ps1; .\install.ps1
#
# Options:
#   .\install.ps1            # user install (no admin needed)
#   .\install.ps1 -Global    # system-wide (requires Administrator)
# ─────────────────────────────────────────────────────────────────────────────
param(
    [switch]$Global = $false
)

$Tool        = "jarvis-graphify"
$Repo        = "dronaprod/jarvis-graphify"
$ReleaseBase = "https://github.com/$Repo/releases/latest/download"
$Binary      = "jarvis-graphify-windows-x86_64.exe"
$UserBin     = "$env:USERPROFILE\.local\bin"
$GlobalBin   = "C:\Program Files\jarvis-graphify"

function Write-Step($msg) { Write-Host "[jarvis-graphify] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[warning] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[error] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║      jarvis-graphify installer       ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Download binary ───────────────────────────────────────────────────────
$Url    = "$ReleaseBase/$Binary"
$TmpExe = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.exe'

Write-Step "Downloading $Binary from GitHub Releases..."
try {
    Invoke-WebRequest -Uri $Url -OutFile $TmpExe -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Err "Download failed: $_`nVisit https://github.com/$Repo/releases"
}

# ── Install ───────────────────────────────────────────────────────────────
if ($Global) {
    Write-Step "Installing system-wide to $GlobalBin ..."
    New-Item -ItemType Directory -Force -Path $GlobalBin | Out-Null
    Copy-Item $TmpExe "$GlobalBin\$Tool.exe" -Force
    Remove-Item $TmpExe -Force

    $syspath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($syspath -notlike "*$GlobalBin*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$syspath;$GlobalBin", "Machine")
        Write-Step "Added $GlobalBin to system PATH"
    }
    $InstalledBin = "$GlobalBin\$Tool.exe"
} else {
    Write-Step "Installing to $UserBin ..."
    New-Item -ItemType Directory -Force -Path $UserBin | Out-Null
    Copy-Item $TmpExe "$UserBin\$Tool.exe" -Force
    Remove-Item $TmpExe -Force

    $userpath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($userpath -notlike "*$UserBin*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$userpath;$UserBin", "User")
        Write-Step "Added $UserBin to user PATH"
    }
    Write-Warn "Close and reopen PowerShell for PATH changes to take effect."
    $InstalledBin = "$UserBin\$Tool.exe"
}

# ── Verify ────────────────────────────────────────────────────────────────
$Ver = & $InstalledBin --version 2>&1
Write-Host ""
Write-Step "Installed: $Ver"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    1. Restart PowerShell"
Write-Host "    2. Go to your project:    cd C:\path\to\your-project"
Write-Host "    3. Create config:         jarvis-graphify setup"
Write-Host "    4. Edit the config:       notepad jarvis-graphify-in\settings.json"
Write-Host "    5. Run:                   jarvis-graphify ."
Write-Host "    6. Open graph:            start jarvis-graphify-out\graph.html"
Write-Host ""
Write-Host "  Docs: https://github.com/$Repo" -ForegroundColor Cyan
Write-Host ""
