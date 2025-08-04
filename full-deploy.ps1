# 完整部署脚本 - PowerShell 版本
# 包含前端构建、Git 同步、Workers 部署和 Cloudflare Pages 部署

function Test-CommandSuccess {
    param([int]$ExitCode, [string]$ErrorMessage)
    if ($ExitCode -ne 0) {
        Write-Host "❌ $ErrorMessage" -ForegroundColor Red
        exit 1
    }
}

function Write-Step {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
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
    wrangler deploy
    Test-CommandSuccess $LASTEXITCODE "Workers deployment failed"
    Write-Success "Workers API deployed"
    Write-Host ""
    
    # Step 4: Deploy to Cloudflare Pages (optional)
    Write-Step "Attempting Cloudflare Pages deployment..."
    try {
        wrangler pages deploy dist --project-name=home
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Pages deployed successfully"
        } else {
            Write-Warning "Pages deployment failed, but GitHub auto-deployment should work"
        }
    }
    catch {
        Write-Warning "Pages deployment command failed, relying on GitHub auto-deployment"
    }
    Write-Host ""
    
    # Step 5: Test API
    Write-Step "Testing API endpoint..."
    try {
        $response = Invoke-RestMethod -Uri 'https://study-api.maples-die.workers.dev/api/articles' -Method GET -TimeoutSec 10
        Write-Success "API is responding correctly"
        Write-Host "📊 Articles count: $($response.articles.Count)" -ForegroundColor Green
    }
    catch {
        Write-Warning "API test failed, but deployment may be successful"
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Step 6: Wait for Pages deployment
    Write-Step "Waiting for Cloudflare Pages auto-deployment..."
    Write-Host "⏳ GitHub push should trigger automatic build on Cloudflare Pages" -ForegroundColor Yellow
    Write-Host "⏳ This usually takes 1-3 minutes" -ForegroundColor Yellow
    Write-Host ""
    
    # Final status
    Write-Host "==========================================" -ForegroundColor Green
    Write-Success "Deployment completed!"
    Write-Host "📱 Frontend: Building on Cloudflare Pages" -ForegroundColor Green
    Write-Host "☁️ API: https://study-api.maples-die.workers.dev" -ForegroundColor Green
    Write-Host "🌐 Website: https://love.xiugou.top" -ForegroundColor Green
    Write-Host "📊 Check Cloudflare Pages dashboard for build status" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
}
catch {
    Write-Host "❌ Script execution failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")