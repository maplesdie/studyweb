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

## 快捷部署方法 🚀

为了方便您快速部署项目，我们提供了一个完整的部署脚本：

### 一键完整部署（推荐）⭐
```bash
.\full-deploy.ps1
```
**功能**: 前端构建 + Git 同步 + Workers 部署 + Pages 部署

### 手动部署命令
```bash
# Git 同步
git add .
git commit -m "更新学习记录功能"
git push origin main

# Cloudflare 部署
wrangler deploy
```

### 脚本功能说明

- **full-deploy.ps1**: 🌟 完整部署流程，包含前端构建、Git 同步、Workers 部署和 Pages 部署

### ⚠️ 重要说明：前端和后端分离部署

您的项目包含两个部分：
1. **后端 API** (Cloudflare Workers) - 处理学习记录数据
2. **前端网站** (Cloudflare Pages) - 显示网页界面

**使用 `full-deploy.ps1` 的优势**：
- 自动构建前端 (`npm run build`)
- 同步代码到 GitHub
- 部署后端 API 到 Cloudflare Workers
- 触发 Cloudflare Pages 自动部署前端
- 一键完成所有部署步骤

### 使用建议

1. **日常更新**: 直接运行 `full-deploy.ps1` 完成所有部署
2. **首次使用**: 确保已安装 Node.js 和 Wrangler CLI
3. **出现问题**: 查看脚本输出信息或使用手动命令逐步排查

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