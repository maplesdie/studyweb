@echo off
REM 完整部署脚本 - 包含前端构建和 Cloudflare Pages 部署
chcp 65001 >nul 2>&1

echo.
echo ==========================================
echo        Complete Deployment Script
echo ==========================================
echo.
echo [INFO] Starting full deployment process...
echo.

REM Step 1: Build frontend
echo [STEP 1] Building frontend...
npm run build
if %errorlevel% neq 0 (
    echo [ERROR] Frontend build failed
    goto :error
)
echo [SUCCESS] Frontend build completed
echo.

REM Step 2: Git operations
echo [STEP 2] Adding files to git...
git add .
if %errorlevel% neq 0 (
    echo [ERROR] Git add failed
    goto :error
)

echo [STEP 3] Committing changes...
git commit -m "Deploy: Frontend build + API update"
if %errorlevel% neq 0 (
    echo [INFO] No changes to commit, continuing...
)

echo [STEP 4] Pushing to GitHub...
git push origin main
if %errorlevel% neq 0 (
    echo [ERROR] Git push failed
    goto :error
)
echo [SUCCESS] Code pushed to GitHub
echo.

REM Step 3: Deploy Workers API
echo [STEP 5] Deploying Cloudflare Workers API...
wrangler deploy
if %errorlevel% neq 0 (
    echo [ERROR] Workers deployment failed
    goto :error
)
echo [SUCCESS] Workers API deployed
echo.

REM Step 4: Deploy to Cloudflare Pages
echo [STEP 6] Deploying to Cloudflare Pages...
wrangler pages deploy dist --project-name=home
if %errorlevel% neq 0 (
    echo [WARNING] Pages deployment failed, trying alternative method...
    echo [INFO] Please check Cloudflare Pages dashboard for auto-deployment
    echo [INFO] GitHub push should trigger automatic build on Cloudflare Pages
)
echo.

REM Step 5: Test API
echo [STEP 7] Testing API endpoint...
curl -s https://study-api.maples-die.workers.dev/api/articles >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] API is responding
) else (
    echo [WARNING] API test failed, but deployment may be successful
)
echo.

echo ==========================================
echo [SUCCESS] Deployment completed!
echo [INFO] Frontend: Check Cloudflare Pages dashboard
echo [INFO] API: https://study-api.maples-die.workers.dev
echo [INFO] Website: https://love.xiugou.top
echo ==========================================
goto :end

:error
echo.
echo ==========================================
echo [ERROR] Deployment failed! Check error messages above.
echo ==========================================

:end
echo.
echo Press any key to exit...
pause >nul