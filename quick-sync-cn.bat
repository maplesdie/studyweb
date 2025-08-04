@echo off
REM 设置代码页为UTF-8
chcp 65001 >nul 2>&1

echo.
echo ==========================================
echo           一键同步脚本
echo ==========================================
echo.
echo [信息] 开始同步流程...
echo.

REM Git 同步和 Cloudflare Workers 部署
echo [步骤1] 添加文件到 git...
git add .
if %errorlevel% neq 0 (
    echo [错误] Git 添加失败
    goto :error
)

echo [步骤2] 提交更改...
git commit -m "快速同步更新"
if %errorlevel% neq 0 (
    echo [错误] Git 提交失败
    goto :error
)

echo [步骤3] 推送到 GitHub...
git push origin main
if %errorlevel% neq 0 (
    echo [错误] Git 推送失败
    goto :error
)

echo [步骤4] 部署到 Cloudflare Workers...
wrangler deploy
if %errorlevel% neq 0 (
    echo [错误] Wrangler 部署失败
    goto :error
)

echo.
echo ==========================================
echo [成功] 同步完成！
echo [信息] API 地址: https://study-api.maples-die.workers.dev
echo ==========================================
goto :end

:error
echo.
echo ==========================================
echo [错误] 同步失败！请检查上面的错误信息。
echo ==========================================

:end
echo.
echo 按任意键退出...
pause >nul