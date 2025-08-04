<template>
  <div class="study-container">
    <!-- 顶部导航栏 -->
    <div class="header">
      <button class="back-btn" @click="store.studyOpenState = false">
        <arrow-left theme="outline" size="20" />
        返回主页
      </button>
      <h1>学习记录</h1>
    </div>
    
    <!-- 主要内容区域 -->
    <div class="content">
      <!-- 发布文章表单 -->
      <div class="publish-form">
        <h2>发布文章</h2>
        <form @submit.prevent="submitArticle">
          <label>标题：<input v-model="title" required /></label><br />
          <label>内容：</label><br />
          <textarea v-model="content" rows="10" cols="50" required></textarea><br />
          <button type="submit" :disabled="isSubmitting">{{ isSubmitting ? '发布中...' : '发布' }}</button>
        </form>
        <p v-if="msg" :class="msgType">{{ msg }}</p>
      </div>
      
      <!-- 文章列表 -->
      <div class="articles-list">
        <h2>已发布文章</h2>
        <div v-if="loading" class="loading">加载中...</div>
        <div v-else-if="articles.length === 0" class="no-articles">暂无文章</div>
        <div v-else class="articles">
          <div v-for="article in articles" :key="article.id" class="article-item">
            <h3>{{ article.title }}</h3>
            <p class="article-content">{{ truncateContent(article.content) }}</p>
            <div class="article-meta">
              <span class="date">{{ formatDate(article.created_at) }}</span>
              <button @click="viewFullArticle(article)" class="view-btn">查看全文</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 文章详情弹窗 -->
    <div v-if="selectedArticle" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>{{ selectedArticle.title }}</h2>
          <button @click="closeModal" class="close-btn">&times;</button>
        </div>
        <div class="modal-body">
          <p class="article-full-content">{{ selectedArticle.content }}</p>
          <div class="article-meta">
            <span class="date">发布时间：{{ formatDate(selectedArticle.created_at) }}</span>
          </div>
        </div>
      </div>
    </div>
   </div>
 </template>

<script setup>
import { ref, onMounted } from 'vue';
import { ArrowLeft } from '@icon-park/vue-next';
import { mainStore } from '@/store';

const store = mainStore();
const title = ref('');
const content = ref('');
const msg = ref('');
const msgType = ref('success');
const isSubmitting = ref(false);
const articles = ref([]);
const loading = ref(false);
const selectedArticle = ref(null);

// API 基础地址 - 已更新为实际的 Workers 域名
const API_BASE = "https://study-api.maples-die.workers.dev";

// 发布文章
const submitArticle = async () => {
  if (isSubmitting.value) return;
  
  isSubmitting.value = true;
  msg.value = '';
  
  try {
    const res = await fetch(`${API_BASE}/api/post`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer 123456"
      },
      body: JSON.stringify({
        title: title.value,
        content: content.value
      })
    });
    
    const result = await res.json();
    
    if (res.ok && result.success) {
      msg.value = "发布成功！";
      msgType.value = 'success';
      title.value = "";
      content.value = "";
      // 重新加载文章列表
      await loadArticles();
    } else {
      msg.value = result.error || "发布失败！";
      msgType.value = 'error';
    }
  } catch (error) {
    console.error('发布文章错误:', error);
    msg.value = "网络错误，发布失败！";
    msgType.value = 'error';
  } finally {
    isSubmitting.value = false;
  }
};

// 加载文章列表
const loadArticles = async () => {
  loading.value = true;
  try {
    const res = await fetch(`${API_BASE}/api/articles`);
    const result = await res.json();
    
    if (res.ok && result.success) {
      articles.value = result.articles || [];
    } else {
      console.error('加载文章失败:', result.error);
    }
  } catch (error) {
    console.error('加载文章错误:', error);
  } finally {
    loading.value = false;
  }
};

// 截断文章内容
const truncateContent = (text, maxLength = 100) => {
  if (!text) return '';
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
};

// 格式化日期
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// 查看完整文章
const viewFullArticle = (article) => {
  selectedArticle.value = article;
};

// 关闭弹窗
const closeModal = () => {
  selectedArticle.value = null;
};

// 组件挂载时加载文章列表
onMounted(() => {
  loadArticles();
});
</script>

<style scoped>
.study-container {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  z-index: 1000;
  overflow: hidden;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 40px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.back-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 20px;
  background: rgba(255, 255, 255, 0.2);
  border: none;
  border-radius: 25px;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 14px;
}

.back-btn:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.header h1 {
  color: white;
  font-size: 28px;
  margin: 0;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.content {
  padding: 40px;
  height: calc(100vh - 100px);
  overflow-y: auto;
  display: flex;
  gap: 40px;
  justify-content: flex-start;
  align-items: flex-start;
}

.publish-form {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20px;
  padding: 40px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(10px);
  width: 100%;
  max-width: 500px;
  flex-shrink: 0;
}

.publish-form h2 {
  color: #333;
  margin-bottom: 30px;
  text-align: center;
  font-size: 24px;
}

.publish-form form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.publish-form label {
  font-weight: 600;
  color: #555;
  margin-bottom: 5px;
}

.publish-form input,
.publish-form textarea {
  padding: 12px 16px;
  border: 2px solid #e1e5e9;
  border-radius: 10px;
  font-size: 16px;
  transition: border-color 0.3s ease;
}

.publish-form input:focus,
.publish-form textarea:focus {
  outline: none;
  border-color: #667eea;
}

.publish-form button {
  padding: 15px 30px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 20px;
}

.publish-form button:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
}

.publish-form p {
  text-align: center;
  margin-top: 20px;
  padding: 10px;
  border-radius: 8px;
}

.publish-form p.success {
  background: #f0f9ff;
  color: #0369a1;
}

.publish-form p.error {
  background: #fef2f2;
  color: #dc2626;
}

/* 文章列表样式 */
.articles-list {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20px;
  padding: 40px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(10px);
  width: 100%;
  max-width: 600px;
  flex-grow: 1;
}

.articles-list h2 {
  color: #333;
  margin-bottom: 30px;
  text-align: center;
  font-size: 24px;
}

.loading, .no-articles {
  text-align: center;
  color: #666;
  font-size: 16px;
  padding: 40px 0;
}

.articles {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.article-item {
  background: rgba(255, 255, 255, 0.8);
  border-radius: 12px;
  padding: 20px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.article-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.article-item h3 {
  color: #333;
  margin: 0 0 10px 0;
  font-size: 18px;
  font-weight: 600;
}

.article-content {
  color: #666;
  margin: 0 0 15px 0;
  line-height: 1.6;
  font-size: 14px;
}

.article-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #999;
}

.view-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 6px;
  padding: 6px 12px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.view-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

/* 弹窗样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
  backdrop-filter: blur(5px);
}

.modal-content {
  background: white;
  border-radius: 20px;
  max-width: 800px;
  max-height: 80vh;
  width: 90%;
  overflow: hidden;
  box-shadow: 0 25px 50px rgba(0, 0, 0, 0.25);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 30px 40px 20px;
  border-bottom: 1px solid #eee;
}

.modal-header h2 {
  margin: 0;
  color: #333;
  font-size: 24px;
}

.close-btn {
  background: none;
  border: none;
  font-size: 30px;
  color: #999;
  cursor: pointer;
  padding: 0;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.3s ease;
}

.close-btn:hover {
  background: #f5f5f5;
  color: #333;
}

.modal-body {
  padding: 30px 40px;
  overflow-y: auto;
  max-height: calc(80vh - 120px);
}

.article-full-content {
  color: #333;
  line-height: 1.8;
  font-size: 16px;
  margin: 0 0 20px 0;
  white-space: pre-wrap;
}

/* 响应式设计 */
@media (max-width: 1200px) {
  .content {
    flex-direction: column;
    align-items: center;
  }
  
  .publish-form,
  .articles-list {
    max-width: 800px;
  }
}

@media (max-width: 768px) {
  .content {
    padding: 20px;
  }
  
  .publish-form,
  .articles-list {
    padding: 20px;
  }
  
  .modal-content {
    width: 95%;
    max-height: 90vh;
  }
  
  .modal-header,
  .modal-body {
    padding: 20px;
  }
}
</style>