@echo off
setlocal

:: --- Store the script directory ---
set "ORIGINAL_DIRECTORY=%~dp0"

:: --- Check if script is already running as admin ---
net session >nul 2>&1
if %ERRORLEVEL%==0 (
    :: Already elevated, skip to the main logic
    goto :ELEVATED
)

:: Not admin. Relaunch the script as admin:
echo Requesting administrative privileges...
powershell -NoProfile -ExecutionPolicy Bypass ^
    -Command "Start-Process cmd -ArgumentList '/k \"\"%~f0\" %*\"' -Verb RunAs -WorkingDirectory \"%ORIGINAL_DIRECTORY%\""

:: Exit from the non-admin shell
exit /B

:ELEVATED
:: --- Once elevated, cd to the script's directory ---
cd /d "%ORIGINAL_DIRECTORY%"

:: Set console width and height:
mode con: cols=146
mode con: lines=30

:: --- Print the banner ---
echo ======================================================================
echo VoidFletcher's Path of Exile Loot Filters
echo ----------------------------------------------------------------------
echo Loot Filters Update Tool
echo (https://github.com/VoidFletcher/PathOfExile2-Loot-Filter)
echo ======================================================================
echo.
echo [Info] Checking for updates...

:: --- Find and validate the latest filter version ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '[Info] Searching for the latest release...'; $r = Invoke-WebRequest -Uri 'https://github.com/VoidFletcher/PathOfExile2-Loot-Filter/releases/latest'; $u = $r.BaseResponse.ResponseUri.AbsoluteUri; if($u -match 'tag/([^/]+)$') { $v = $Matches[1]; Write-Host ('[Info] Latest version is: ' + $v); } else { Write-Host '[Warning] Could not parse version tag from the latest release.'; exit 1; }"

if %ERRORLEVEL% neq 0 (
    echo [Error] Failed to check the latest version.
    pause
    exit /b
)

:: --- Deletes the existing copy of VoidFletcher's Loot Filter ---
echo [Info] Checking for existing filter file...
if exist "VoidFletcher-SemiStrict-POE2.filter" (
    echo [Info] Found existing filter file. Deleting...
    del "VoidFletcher-SemiStrict-POE2.filter"
    if %ERRORLEVEL% neq 0 (
        echo [Error] Unable to delete the existing filter file. Aborting update.
        goto :END
    )
)

:: --- Download the latest version of the filter ---
echo [Info] Downloading the latest filter (via GitHub API)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '[Info] Fetching latest .filter file from GitHub API...'; $apiUrl='https://api.github.com/repos/VoidFletcher/PathOfExile2-Loot-Filter/releases/latest'; $res=Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -Headers @{ 'User-Agent'='Mozilla/5.0' }; $data=$res.Content | ConvertFrom-Json; $asset=$data.assets | Where-Object { $_.browser_download_url -match '\.filter$' }; if(-not $asset) { Write-Host '[Error] No .filter link found.'; exit 1 }; $url=$asset.browser_download_url; if($url -is [System.Array]) { $url=$url[0] }; Write-Host '[Info] Download URL:' $url; Invoke-WebRequest -Uri $url -OutFile 'VoidFletcher-SemiStrict-POE2.filter'; Write-Host '[Info] Download complete.'"

if %ERRORLEVEL% neq 0 (
    echo [Error] Failed to download the latest filter. Aborting update.
    goto :END
)

echo [Info] Successfully updated to the latest filter.

:END
echo [Info] Done. You can now close this window.
pause >nul
exit /b