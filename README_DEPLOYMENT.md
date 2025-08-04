# 学习记录功能 - Cloudflare Workers + D1 数据库部署指南

## 🚀 快速开始

您的学习记录功能现在可以连接到 Cloudflare D1 数据库了！按照以下步骤完成部署：

### 方法一：使用自动化脚本（推荐）

1. **双击运行** `deploy.bat` 文件
2. 按照提示完成部署
3. 更新前端 API 地址

### 方法二：手动部署

1. 安装 Wrangler CLI
2. 登录 Cloudflare
3. 创建 D1 数据库
4. 部署 Workers
5. 更新前端配置

详细步骤请查看 `WORKERS_SETUP.md`

## 📁 新增文件说明

- `wrangler.toml` - Cloudflare Workers 配置文件
- `src/worker.js` - Workers API 代码
- `migrations/schema.sql` - 数据库表结构
- `deploy.ps1` / `deploy.bat` - 自动化部署脚本
- `WORKERS_SETUP.md` - 详细部署指南

## 🔧 功能特性

✅ 文章发布到 D1 数据库  
✅ 文章列表显示  
✅ 文章详情查看  
✅ 响应式设计  
✅ 错误处理  
✅ 加载状态  

## 🌐 API 端点

- `POST /api/post` - 发布文章
- `GET /api/articles` - 获取文章列表
- `GET /api/articles/{id}` - 获取单个文章

## ⚠️ 重要提醒

1. 部署完成后，请更新 `src/views/Study/index.vue` 中的 API 地址
2. 建议更改默认的认证 token
3. 确保 D1 数据库 ID 配置正确

## 💰 费用说明

Cloudflare 提供慷慨的免费额度：
- Workers: 每天 100,000 次请求
- D1: 每天 100,000 次读取，50,000 次写入

个人使用完全免费！

## 🆘 需要帮助？

- 查看 `WORKERS_SETUP.md` 获取详细指南
- 检查 Cloudflare Dashboard 中的 Workers 日志
- 确认 D1 数据库连接正常

---

**开始部署：双击 `deploy.bat` 文件！** 🎉