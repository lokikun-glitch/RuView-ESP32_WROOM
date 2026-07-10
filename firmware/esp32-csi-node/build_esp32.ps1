#Requires -Version 5.1
<#
.SYNOPSIS
    Build RuView CSI Node firmware for ESP32-WROOM-32 / ESP32-D0WD.

.DESCRIPTION
    Sets ESP-IDF target to esp32, applies sdkconfig.defaults.esp32, builds the
    firmware, and optionally flashes it to the specified COM port.

    Requirements:
      - ESP-IDF v5.2 or later, sourced via ". $env:IDF_PATH\export.ps1"
      - Python 3 in PATH (provided by ESP-IDF environment)

.PARAMETER Port
    Optional COM port to flash after building (e.g., COM5).
    If omitted, only builds; flash separately with:
        idf.py -p COM<N> flash monitor

.PARAMETER Clean
    When specified, removes the build\ directory and stale sdkconfig before
    building.  Use this when switching from a previous S3/C6 build.

.EXAMPLE
    # Build only
    .\build_esp32.ps1

.EXAMPLE
    # Build and flash to COM5
    .\build_esp32.ps1 -Port COM5

.EXAMPLE
    # Clean rebuild and flash
    .\build_esp32.ps1 -Clean -Port COM5
#>

param(
    [string] $Port  = "",
    [switch] $Clean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host "[build_esp32] $msg" -ForegroundColor Cyan
}
function Write-Ok([string]$msg) {
    Write-Host "[build_esp32] $msg" -ForegroundColor Green
}
function Write-Fail([string]$msg) {
    Write-Host "[build_esp32] ERROR: $msg" -ForegroundColor Red
}

# --- Validate IDF environment ------------------------------------------------
if (-not $env:IDF_PATH) {
    Write-Fail "IDF_PATH is not set. Source the IDF environment first:"
    Write-Host "    . `$env:IDF_PATH\export.ps1"
    exit 1
}
Write-Step "IDF_PATH = $env:IDF_PATH"

# --- Optional clean ----------------------------------------------------------
if ($Clean) {
    Write-Step "Cleaning build directory and sdkconfig ..."
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
    }
    if (Test-Path "sdkconfig") {
        Remove-Item -Force "sdkconfig"
    }
    Write-Ok "Clean done."
}

# --- Auto-detect stale sdkconfig from a different target --------------------
if (Test-Path "sdkconfig") {
    $cfg = Get-Content "sdkconfig" -Raw
    $isS3 = $cfg -match "CONFIG_IDF_TARGET_ESP32S3=y"
    $isC6 = $cfg -match "CONFIG_IDF_TARGET_ESP32C6=y"
    if ($isS3 -or $isC6) {
        Write-Step "Detected stale S3/C6 sdkconfig - removing before set-target ..."
        Remove-Item -Force "sdkconfig"
        Write-Ok "Stale sdkconfig removed."
    }
}

# --- set-target --------------------------------------------------------------
Write-Step "Running: idf.py -D SDKCONFIG_DEFAULTS=sdkconfig.defaults.esp32 set-target esp32"
& idf.py -D SDKCONFIG_DEFAULTS="sdkconfig.defaults.esp32" set-target esp32
if ($LASTEXITCODE -ne 0) {
    Write-Fail "idf.py set-target failed (exit $LASTEXITCODE). Check IDF v5.2+ is sourced."
    exit $LASTEXITCODE
}
Write-Ok "set-target esp32: done."

# --- Build -------------------------------------------------------------------
Write-Step "Running: idf.py build"
& idf.py build
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Build failed (exit $LASTEXITCODE). See compiler output above."
    exit $LASTEXITCODE
}

Write-Ok "Build successful!"
Write-Host "  Binary : build\esp32-csi-node.bin"
Write-Host "  Map    : build\esp32-csi-node.map"

# --- Binary size report ------------------------------------------------------
if (Test-Path "build\esp32-csi-node.bin") {
    $sz  = (Get-Item "build\esp32-csi-node.bin").Length
    $cap = 1875 * 1024
    $pct = [math]::Round($sz / $cap * 100, 1)
    Write-Host ("  Size   : {0:N0} bytes ({1}% of 1.875 MB OTA slot)" -f $sz, $pct)
    if ($sz -gt $cap) {
        Write-Host "  WARNING: binary exceeds OTA slot size! Enable size optimisation." -ForegroundColor Yellow
    }
}

# --- Optional flash ----------------------------------------------------------
if ($Port -eq "") {
    Write-Host ""
    Write-Host "  To flash: idf.py -p COM<N> flash monitor" -ForegroundColor DarkGray
    exit 0
}

Write-Step "Flashing to $Port ..."
& idf.py -p $Port flash monitor
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Flash/monitor failed (exit $LASTEXITCODE)."
    exit $LASTEXITCODE
}
