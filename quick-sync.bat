@echo off
chcp 65001 >nul 2>&1
echo.
echo ==========================================
echo           Quick Sync Script
echo ==========================================
echo.
echo [INFO] Starting sync process...
echo.

REM Git sync and Cloudflare Workers deploy
echo [STEP 1] Adding files to git...
git add .
if %errorlevel% neq 0 (
    echo [ERROR] Git add failed
    goto :error
)

echo [STEP 2] Committing changes...
git commit -m "Quick sync update"
if %errorlevel% neq 0 (
    echo [ERROR] Git commit failed
    goto :error
)

echo [STEP 3] Pushing to GitHub...
git push origin main
if %errorlevel% neq 0 (
    echo [ERROR] Git push failed
    goto :error
)

echo [STEP 4] Deploying to Cloudflare Workers...
wrangler deploy
if %errorlevel% neq 0 (
    echo [ERROR] Wrangler deploy failed
    goto :error
)

echo.
echo ==========================================
echo [SUCCESS] Sync completed successfully!
echo [INFO] API URL: https://study-api.maples-die.workers.dev
echo ==========================================
goto :end

:error
echo.
echo ==========================================
echo [ERROR] Sync failed! Please check the error messages above.
echo ==========================================

:end
echo.
echo Press any key to exit...
pause >nul