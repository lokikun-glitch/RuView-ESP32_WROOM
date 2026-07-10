@echo off
REM ============================================================
REM  build_esp32.bat — Build RuView CSI Node for ESP32-WROOM-32
REM  Usage:  build_esp32.bat [PORT]
REM  Example: build_esp32.bat COM5
REM ============================================================

setlocal EnableDelayedExpansion

REM ── Validate IDF environment ──────────────────────────────────
if not defined IDF_PATH (
    echo [ERROR] IDF_PATH is not set. Run: . %%IDF_PATH%%\export.bat
    exit /b 1
)

echo [build_esp32] IDF_PATH=%IDF_PATH%
echo [build_esp32] Target: esp32 ^(ESP-WROOM-32 / ESP32-D0WD^)

REM ── Clean stale sdkconfig if target has changed ───────────────
REM If a previous build targeted esp32s3, the cached sdkconfig will
REM conflict.  idf.py set-target handles this, but a leftover
REM sdkconfig file can confuse menuconfig on first run.
if exist sdkconfig (
    findstr /C:"CONFIG_IDF_TARGET_ESP32S3=y" sdkconfig >nul 2>&1
    if !errorlevel! == 0 (
        echo [build_esp32] Removing stale esp32s3 sdkconfig ...
        del sdkconfig
    )
    findstr /C:"CONFIG_IDF_TARGET_ESP32C6=y" sdkconfig >nul 2>&1
    if !errorlevel! == 0 (
        echo [build_esp32] Removing stale esp32c6 sdkconfig ...
        del sdkconfig
    )
)

REM ── set-target ────────────────────────────────────────────────
echo [build_esp32] Setting target to esp32 with sdkconfig.defaults.esp32 ...
idf.py -D SDKCONFIG_DEFAULTS="sdkconfig.defaults.esp32" set-target esp32
if %errorlevel% neq 0 (
    echo [ERROR] set-target failed. Check ESP-IDF installation ^(requires v5.2+^).
    exit /b %errorlevel%
)

REM ── Build ─────────────────────────────────────────────────────
echo [build_esp32] Building ...
idf.py build
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.  See above for compiler errors.
    exit /b %errorlevel%
)

echo.
echo [build_esp32] Build successful!
echo   Binary: build\esp32-csi-node.bin
echo   Map:    build\esp32-csi-node.map

REM ── Optional flash ────────────────────────────────────────────
if "%~1" == "" (
    echo.
    echo [build_esp32] No PORT argument given — skipping flash.
    echo   To flash: idf.py -p COM^<N^> flash monitor
    exit /b 0
)

set PORT=%~1
echo.
echo [build_esp32] Flashing to %PORT% ...
idf.py -p %PORT% flash monitor
