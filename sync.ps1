# 快捷同步脚本 - Git + Cloudflare Workers
# PowerShell 版本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 快捷同步脚本 - Git + Cloudflare Workers" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 函数：检查命令执行结果
function Test-CommandSuccess {
    param($ExitCode, $ErrorMessage)
    if ($ExitCode -ne 0) {
        Write-Host "❌ $ErrorMessage" -ForegroundColor Red
        Read-Host "按回车键退出"
        exit 1
    }
}

try {
    # 1. 检查当前状态
    Write-Host "📋 检查当前状态..." -ForegroundColor Yellow
    git status
    Write-Host ""

    # 2. 添加所有修改的文件
    Write-Host "📦 添加所有修改的文件..." -ForegroundColor Yellow
    git add .
    Test-CommandSuccess $LASTEXITCODE "Git add 失败"
    Write-Host ""

    # 3. 获取提交信息
    $commitMsg = Read-Host "💬 请输入提交信息 (按回车使用默认信息)"
    if ([string]::IsNullOrWhiteSpace($commitMsg)) {
        $commitMsg = "更新学习记录功能和API配置"
    }

    # 4. 提交更改
    Write-Host "📝 提交更改..." -ForegroundColor Yellow
    git commit -m $commitMsg
    Test-CommandSuccess $LASTEXITCODE "Git 提交失败，请检查是否有文件需要提交"
    Write-Host ""

    # 5. 推送到 GitHub
    Write-Host "🌐 推送到 GitHub..." -ForegroundColor Yellow
    git push origin main
    Test-CommandSuccess $LASTEXITCODE "Git 推送失败，请检查网络连接和权限"
    Write-Host ""

    # 6. 部署到 Cloudflare Workers
    Write-Host "☁️ 部署到 Cloudflare Workers..." -ForegroundColor Yellow
    wrangler deploy
    Test-CommandSuccess $LASTEXITCODE "Workers 部署失败，请检查配置"
    Write-Host ""

    # 7. 测试 API 端点
    Write-Host "🧪 测试 API 端点..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri 'https://study-api.maples-die.workers.dev/api/articles' -Method GET
        Write-Host "✅ API 测试成功:" -ForegroundColor Green
        $response | ConvertTo-Json
    }
    catch {
        Write-Host "⚠️ API 测试失败，但部署可能成功" -ForegroundColor Yellow
        Write-Host "错误信息: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""

    # 8. 完成提示
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ 同步完成！" -ForegroundColor Green
    Write-Host "📱 GitHub: 代码已推送" -ForegroundColor Green
    Write-Host "☁️ Cloudflare: Workers 已部署" -ForegroundColor Green
    Write-Host "🔗 API 地址: https://study-api.maples-die.workers.dev" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
}
catch {
    Write-Host "❌ 脚本执行过程中发生错误:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    Write-Host ""
    Read-Host "按回车键退出"
}