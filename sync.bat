@echo off
chcp 65001 >nul 2>&1
echo ========================================
echo    Quick Sync Script - Git + Cloudflare Workers
echo ========================================
echo.

echo [INFO] Checking current status...
git status
echo.

echo [INFO] Adding all modified files...
git add .
echo.

echo [INPUT] Enter commit message (press Enter for default):
set /p commit_msg="Commit message: "
if "%commit_msg%"=="" set commit_msg=Update study features and API config

echo [INFO] Committing changes...
git commit -m "%commit_msg%"
if %errorlevel% neq 0 (
    echo [ERROR] Git commit failed, please check if there are files to commit
    pause
    exit /b 1
)
echo.

echo [INFO] Pushing to GitHub...
git push origin main
if %errorlevel% neq 0 (
    echo [ERROR] Git push failed, please check network connection and permissions
    pause
    exit /b 1
)
echo.

echo [INFO] Deploying to Cloudflare Workers...
wrangler deploy
if %errorlevel% neq 0 (
    echo [ERROR] Workers deployment failed, please check configuration
    pause
    exit /b 1
)
echo.

echo [INFO] Testing API endpoint...
powershell -Command "try { $response = Invoke-RestMethod -Uri 'https://study-api.maples-die.workers.dev/api/articles' -Method GET; Write-Host '[SUCCESS] API test successful:' -ForegroundColor Green; $response | ConvertTo-Json } catch { Write-Host '[WARNING] API test failed, but deployment might be successful' -ForegroundColor Yellow }"
echo.

echo ========================================
echo [SUCCESS] Sync completed!
echo [INFO] GitHub: Code pushed
echo [INFO] Cloudflare: Workers deployed
echo [INFO] API URL: https://study-api.maples-die.workers.dev
echo ========================================
echo.
echo Press any key to exit...
pause >nul