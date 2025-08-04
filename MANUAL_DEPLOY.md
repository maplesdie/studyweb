# 手动部署指南

如果自动化脚本出现问题，请按照以下步骤手动部署：

## 步骤 1: 安装 Wrangler

打开命令提示符或 PowerShell，运行：

```bash
npm install -g wrangler
```

## 步骤 2: 登录 Cloudflare

```bash
wrangler login
```

## 步骤 3: 创建 D1 数据库

```bash
wrangler d1 create study-database
```

复制输出中的 `database_id`，编辑 `wrangler.toml` 文件，替换其中的 `your-database-id-here`。

## 步骤 4: 初始化数据库

```bash
wrangler d1 execute study-database --file=./migrations/schema.sql
```

## 步骤 5: 部署 Workers

```bash
wrangler deploy
```

## 步骤 6: 更新前端 API 地址

编辑 `src/views/Study/index.vue` 文件，将第 79 行的 API 地址更新为您的 Workers 域名：

```javascript
const API_BASE = "https://your-worker-name.your-subdomain.workers.dev";
```

## 测试 API

部署完成后，您可以测试 API：

```bash
# 测试发布文章
curl -X POST https://your-worker-name.your-subdomain.workers.dev/api/post \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 123456" \
  -d '{"title":"测试文章","content":"这是测试内容"}'

# 测试获取文章列表
curl https://your-worker-name.your-subdomain.workers.dev/api/articles
```

## 常见问题

### 1. 编码问题
如果批处理文件显示乱码，请：
- 使用 `deploy-simple.bat` 替代
- 或直接在 PowerShell 中运行 `deploy.ps1`

### 2. 权限问题
如果 PowerShell 执行策略限制，运行：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. 数据库连接失败
确保 `wrangler.toml` 中的 `database_id` 正确。

### 4. CORS 错误
检查 Workers 代码中的 CORS 设置是否正确。

## 直接运行 PowerShell 脚本

如果批处理文件有问题，可以直接运行：

```powershell
PowerShell -ExecutionPolicy Bypass -File deploy.ps1
```

或者在 PowerShell 中：

```powershell
.\deploy.ps1
```