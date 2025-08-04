// Cloudflare Workers 代码用于处理学习记录API

// CORS 头部设置
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

// 处理 CORS 预检请求
function handleCORS(request) {
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }
  return null;
}

// 验证授权token
function validateAuth(request, env) {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return false;
  }
  const token = authHeader.substring(7);
  return token === env.AUTH_TOKEN;
}

// 创建文章表（如果不存在）
async function createTableIfNotExists(env) {
  const createTableSQL = `
    CREATE TABLE IF NOT EXISTS articles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `;
  
  try {
    await env.DB.prepare(createTableSQL).run();
    console.log('Table created or already exists');
  } catch (error) {
    console.error('Error creating table:', error);
    throw error;
  }
}

// 发布文章
async function createArticle(request, env) {
  try {
    // 验证授权
    if (!validateAuth(request, env)) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 确保表存在
    await createTableIfNotExists(env);

    // 解析请求体
    const { title, content } = await request.json();
    
    if (!title || !content) {
      return new Response(JSON.stringify({ error: 'Title and content are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 插入文章到数据库
    const insertSQL = `
      INSERT INTO articles (title, content, created_at, updated_at) 
      VALUES (?, ?, datetime('now'), datetime('now'))
    `;
    
    const result = await env.DB.prepare(insertSQL)
      .bind(title, content)
      .run();

    if (result.success) {
      return new Response(JSON.stringify({ 
        success: true, 
        id: result.meta.last_row_id,
        message: 'Article created successfully' 
      }), {
        status: 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } else {
      throw new Error('Failed to insert article');
    }
  } catch (error) {
    console.error('Error creating article:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
}

// 获取所有文章
async function getArticles(env) {
  try {
    // 确保表存在
    await createTableIfNotExists(env);

    const selectSQL = `
      SELECT id, title, content, created_at, updated_at 
      FROM articles 
      ORDER BY created_at DESC
    `;
    
    const result = await env.DB.prepare(selectSQL).all();
    
    return new Response(JSON.stringify({ 
      success: true, 
      articles: result.results 
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error fetching articles:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
}

// 获取单个文章
async function getArticle(articleId, env) {
  try {
    // 确保表存在
    await createTableIfNotExists(env);

    const selectSQL = `
      SELECT id, title, content, created_at, updated_at 
      FROM articles 
      WHERE id = ?
    `;
    
    const result = await env.DB.prepare(selectSQL).bind(articleId).first();
    
    if (!result) {
      return new Response(JSON.stringify({ error: 'Article not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    
    return new Response(JSON.stringify({ 
      success: true, 
      article: result 
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error fetching article:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
}

// 更新文章
async function updateArticle(articleId, request, env) {
  try {
    // 验证授权
    if (!validateAuth(request, env)) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 确保表存在
    await createTableIfNotExists(env);

    // 解析请求体
    const { title, content } = await request.json();
    
    if (!title || !content) {
      return new Response(JSON.stringify({ error: 'Title and content are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 检查文章是否存在
    const checkSQL = `SELECT id FROM articles WHERE id = ?`;
    const existingArticle = await env.DB.prepare(checkSQL).bind(articleId).first();
    
    if (!existingArticle) {
      return new Response(JSON.stringify({ error: 'Article not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 更新文章
    const updateSQL = `
      UPDATE articles 
      SET title = ?, content = ?, updated_at = datetime('now') 
      WHERE id = ?
    `;
    
    const result = await env.DB.prepare(updateSQL)
      .bind(title, content, articleId)
      .run();

    if (result.success) {
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'Article updated successfully' 
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } else {
      throw new Error('Failed to update article');
    }
  } catch (error) {
    console.error('Error updating article:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
}

// 删除文章
async function deleteArticle(articleId, request, env) {
  try {
    // 验证授权
    if (!validateAuth(request, env)) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 确保表存在
    await createTableIfNotExists(env);

    // 检查文章是否存在
    const checkSQL = `SELECT id FROM articles WHERE id = ?`;
    const existingArticle = await env.DB.prepare(checkSQL).bind(articleId).first();
    
    if (!existingArticle) {
      return new Response(JSON.stringify({ error: 'Article not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 删除文章
    const deleteSQL = `DELETE FROM articles WHERE id = ?`;
    
    const result = await env.DB.prepare(deleteSQL)
      .bind(articleId)
      .run();

    if (result.success) {
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'Article deleted successfully' 
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } else {
      throw new Error('Failed to delete article');
    }
  } catch (error) {
    console.error('Error deleting article:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
}

// 主要的请求处理函数
export default {
  async fetch(request, env, ctx) {
    // 处理 CORS 预检请求
    const corsResponse = handleCORS(request);
    if (corsResponse) {
      return corsResponse;
    }

    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    try {
      // 路由处理
      if (path === '/api/post' && method === 'POST') {
        return await createArticle(request, env);
      } else if (path === '/api/articles' && method === 'GET') {
        return await getArticles(env);
      } else if (path.startsWith('/api/articles/') && method === 'GET') {
        const articleId = path.split('/').pop();
        return await getArticle(articleId, env);
      } else if (path.startsWith('/api/articles/') && method === 'PUT') {
        const articleId = path.split('/').pop();
        return await updateArticle(articleId, request, env);
      } else if (path.startsWith('/api/articles/') && method === 'DELETE') {
        const articleId = path.split('/').pop();
        return await deleteArticle(articleId, request, env);
      } else {
        return new Response(JSON.stringify({ error: 'Not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    } catch (error) {
      console.error('Unhandled error:', error);
      return new Response(JSON.stringify({ error: 'Internal server error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};