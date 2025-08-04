-- 创建文章表
CREATE TABLE IF NOT EXISTS articles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_articles_created_at ON articles(created_at);
CREATE INDEX IF NOT EXISTS idx_articles_title ON articles(title);

-- 插入示例数据（可选）
INSERT OR IGNORE INTO articles (id, title, content, created_at, updated_at) VALUES 
(1, '欢迎使用学习记录系统', '这是您的第一篇文章！您可以在这里记录学习心得、技术笔记等内容。', datetime('now'), datetime('now'));