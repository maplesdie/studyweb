# Cloudflare Workers + D1 数据库部署指南

本指南将帮助您将学习记录功能部署到 Cloudflare Workers，并使用 D1 数据库存储文章数据。

## 前置要求

1. 拥有 Cloudflare 账户
2. 已安装 Node.js (版本 16 或更高)
3. 已安装 npm 或 pnpm

## 步骤 1: 安装 Wrangler CLI

```bash
npm install -g wrangler
# 或者
pnpm install -g wrangler
```

## 步骤 2: 登录 Cloudflare

```bash
wrangler login
```

这将打开浏览器，让您登录 Cloudflare 账户。

## 步骤 3: 创建 D1 数据库

```bash
wrangler d1 create study-database
```

执行后，您会看到类似以下的输出：

```
✅ Successfully created DB 'study-database' in region APAC
Created your database using D1's new storage backend. The new storage backend is not yet recommended for production workloads, but backs up your data via point-in-time restore.

[[d1_databases]]
binding = "DB"
database_name = "study-database"
database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**重要**: 复制输出中的 `database_id`，并更新 `wrangler.toml` 文件中的 `database_id` 字段。

## 步骤 4: 更新配置文件

编辑 `wrangler.toml` 文件，将 `database_id` 替换为步骤 3 中获得的实际 ID：

```toml
[[d1_databases]]
binding = "DB"
database_name = "study-database"
database_id = "your-actual-database-id-here"  # 替换为实际的 database_id
```

## 步骤 5: 初始化数据库表

```bash
# 在本地测试环境中创建表
wrangler d1 execute study-database --local --file=./migrations/schema.sql

# 在生产环境中创建表
wrangler d1 execute study-database --file=./migrations/schema.sql
```

## 步骤 6: 本地测试

```bash
wrangler dev
```

这将启动本地开发服务器，您可以在 `http://localhost:8787` 测试 API。

### 测试 API 端点

1. **发布文章** (POST `/api/post`):
   ```bash
   curl -X POST http://localhost:8787/api/post \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer 123456" \
     -d '{"title":"测试文章","content":"这是测试内容"}'
   ```

2. **获取所有文章** (GET `/api/articles`):
   ```bash
   curl http://localhost:8787/api/articles
   ```

3. **获取单个文章** (GET `/api/articles/{id}`):
   ```bash
   curl http://localhost:8787/api/articles/1
   ```

## 步骤 7: 部署到生产环境

```bash
wrangler deploy
```

部署成功后，您会看到类似以下的输出：

```
✨ Success! Uploaded 1 files (x.xx sec)
✨ Deployment complete! Take a flight over to https://study-api.your-subdomain.workers.dev to see your worker in action.
```

## 步骤 8: 更新前端配置

将前端代码中的 API 地址更新为您的 Workers 域名。

编辑 `src/views/Study/index.vue` 文件，将第 40 行的 URL 更新为：

```javascript
const res = await fetch("https://study-api.your-subdomain.workers.dev/api/post", {
```

**注意**: 将 `your-subdomain` 替换为您实际的 Workers 域名。

## 快捷同步方法 🚀

为了方便您快速同步代码到 GitHub 和 Cloudflare，我们提供了三种快捷脚本：

### 方法 1: 完整同步脚本（推荐）
```bash
# Windows 批处理版本
.\sync.bat

# PowerShell 版本（更好的错误处理）
.\sync.ps1
```

### 方法 2: 一键快速同步
```bash
# 英文版本（避免乱码）
.\quick-sync.bat

# 中文版本（如果需要中文显示）
.\quick-sync-cn.bat
```

### 方法 3: 手动命令
```bash
# Git 同步
git add .
git commit -m "更新学习记录功能"
git push origin main

# Cloudflare 部署
wrangler deploy
```

### 脚本功能说明

- **sync.bat / sync.ps1**: 完整的同步流程，包含状态检查、错误处理和 API 测试
- **quick-sync.bat**: 一键快速同步（英文界面，避免乱码）
- **quick-sync-cn.bat**: 一键快速同步（中文界面）
- 所有脚本都会自动完成 Git 提交、推送和 Workers 部署

### 乱码问题解决方案

如果运行脚本时出现乱码，请尝试以下解决方案：

1. **使用英文版本**: 运行 `quick-sync.bat`（英文界面）
2. **使用 PowerShell**: 运行 `sync.ps1`（更好的编码支持）
3. **设置终端编码**: 在命令行中先运行 `chcp 65001`
4. **使用 Windows Terminal**: 推荐使用 Windows Terminal 而不是传统的 cmd

### 使用建议

1. **首次使用**: 建议使用 `sync.ps1`，可以看到详细的执行过程
2. **日常更新**: 使用 `quick-sync.bat` 快速同步
3. **出现问题**: 使用手动命令逐步排查

## 步骤 9: 自定义域名（可选）

如果您想使用自定义域名（如 `study.xiugou.top`），可以在 Cloudflare Dashboard 中配置：

1. 进入 Workers & Pages
2. 选择您的 Worker
3. 点击 "Settings" > "Triggers"
4. 添加自定义域名

## 环境变量配置

您可以在 `wrangler.toml` 中配置环境变量：

```toml
[vars]
AUTH_TOKEN = "your-secure-token-here"  # 建议更改为更安全的令牌
```

## 数据库管理

### 查看数据库内容

```bash
# 本地数据库
wrangler d1 execute study-database --local --command="SELECT * FROM articles;"

# 生产数据库
wrangler d1 execute study-database --command="SELECT * FROM articles;"
```

### 备份数据库

```bash
wrangler d1 export study-database --output=backup.sql
```

## 故障排除

### 常见问题

1. **数据库连接错误**: 确保 `wrangler.toml` 中的 `database_id` 正确
2. **CORS 错误**: 检查前端域名是否在 CORS 设置中允许
3. **认证失败**: 确保请求头中包含正确的 Authorization token

### 查看日志

```bash
wrangler tail
```

## 安全建议

1. 更改默认的 AUTH_TOKEN
2. 考虑实现更复杂的认证机制
3. 添加请求频率限制
4. 验证输入数据以防止 SQL 注入

## 成本说明

Cloudflare Workers 和 D1 数据库都有免费额度：

- **Workers**: 每天 100,000 次请求
- **D1**: 每天 100,000 次读取，50,000 次写入

对于个人博客使用，这些免费额度通常足够。

## 下一步

部署完成后，您的学习记录功能就可以正常使用了！文章将被安全地存储在 Cloudflare D1 数据库中。

如果需要添加更多功能（如文章编辑、删除、分类等），可以扩展 `src/worker.js` 中的 API 端点。