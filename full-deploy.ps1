# 完整部署脚本 - PowerShell 版本
# 包含前端构建、Git 同步、Workers 部署和 Cloudflare Pages 部署

function Test-CommandSuccess {
    param([int]$ExitCode, [string]$ErrorMessage)
    if ($ExitCode -ne 0) {
        Write-Host "[ERROR] $ErrorMessage" -ForegroundColor Red
        exit 1
    }
}

function Write-Step {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

try {
    Write-Host "" 
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host "        Complete Deployment Script" -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host ""
    
    # Step 1: Build frontend
    Write-Step "Building frontend..."
    npm run build
    Test-CommandSuccess $LASTEXITCODE "Frontend build failed"
    Write-Success "Frontend build completed"
    Write-Host ""
    
    # Step 2: Git operations
    Write-Step "Adding files to git..."
    git add .
    Test-CommandSuccess $LASTEXITCODE "Git add failed"
    
    Write-Step "Committing changes..."
    $commitMessage = "Deploy: Frontend build + API update - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "No changes to commit, continuing..."
    }
    
    Write-Step "Pushing to GitHub..."
    git push origin main
    Test-CommandSuccess $LASTEXITCODE "Git push failed"
    Write-Success "Code pushed to GitHub"
    Write-Host ""
    
    # Step 3: Deploy Workers API
    Write-Step "Deploying Cloudflare Workers API..."
    wrangler deploy --env=""
    Test-CommandSuccess $LASTEXITCODE "Workers deployment failed"
    Write-Success "Workers API deployed"
    Write-Host ""
    
    # Step 4: Skip Pages deployment (rely on GitHub auto-deployment)
    Write-Step "Skipping direct Pages deployment..."
    Write-Host "[INFO] Relying on GitHub auto-deployment for Cloudflare Pages" -ForegroundColor Yellow
    Write-Host "[INFO] GitHub push will trigger automatic build on Cloudflare Pages" -ForegroundColor Yellow
    Write-Host ""
    
    # Step 5: Test API
    Write-Step "Testing API endpoint..."
    try {
        $response = Invoke-RestMethod -Uri 'https://workers.xiugou.top/api/articles' -Method GET -TimeoutSec 10
        Write-Success "API is responding correctly"
        Write-Host "[DATA] Articles count: $($response.articles.Count)" -ForegroundColor Green
    }
    catch {
        Write-Warning "API test failed, but deployment may be successful"
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Step 6: Deployment summary
    Write-Step "Deployment process completed"
    Write-Host "[INFO] Cloudflare Pages will auto-deploy from GitHub in 1-3 minutes" -ForegroundColor Yellow
    Write-Host ""
    
    # Final status
    Write-Host "=========================================" -ForegroundColor Green
    Write-Success "Deployment completed!"
    Write-Host "[FRONTEND] Building on Cloudflare Pages" -ForegroundColor Green
    Write-Host "[API] https://workers.xiugou.top" -ForegroundColor Green
    Write-Host "[WEBSITE] https://love.xiugou.top" -ForegroundColor Green
    Write-Host "[STATUS] Check Cloudflare Pages dashboard for build status" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Script execution failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")