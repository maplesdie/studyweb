<template>
  <div class="study-container">
    <!-- 顶部导航栏 -->
    <div class="header">
      <button class="back-btn" @click="store.studyOpenState = false">
        <arrow-left theme="outline" size="20" />
        返回主页
      </button>
      <h1>学习记录</h1>
      <button class="new-post-btn" @click="showPublishForm">
        新建发布
      </button>
    </div>
    
    <!-- 主要内容区域 -->
    <div class="content">
      <!-- 文章列表 -->
      <div class="articles-list">
        <div v-if="loading" class="loading">加载中...</div>
        <div v-else-if="articles.length === 0" class="no-articles">暂无文章</div>
        <div v-else class="articles">
          <div v-for="article in articles" :key="article.id" class="article-item">
            <h3>{{ article.title }}</h3>
            <p class="article-content">{{ truncateContent(article.content) }}</p>
            <div class="article-meta">
              <span class="date">{{ formatDate(article.created_at) }}</span>
              <div class="article-actions">
                <button @click="viewFullArticle(article)" class="view-btn">查看全文</button>
                <button @click="editArticle(article)" class="edit-btn">编辑</button>
                <button @click="deleteArticle(article.id)" class="delete-btn">删除</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 发布/编辑文章弹窗 -->
    <div v-if="showForm" class="modal-overlay" @click="closeForm">
      <div class="modal-content publish-modal" @click.stop>
        <div class="modal-header">
          <h2>{{ isEditing ? '编辑文章' : '发布文章' }}</h2>
          <button @click="closeForm" class="close-btn">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="submitArticle" class="publish-form">
            <label>标题：</label>
            <input v-model="title" required placeholder="请输入文章标题" />
            <label>内容：</label>
            <textarea v-model="content" rows="15" required placeholder="请输入文章内容"></textarea>
            <div class="form-actions">
              <button type="submit" :disabled="isSubmitting" class="submit-btn">
                {{ isSubmitting ? (isEditing ? '更新中...' : '发布中...') : (isEditing ? '更新' : '发布') }}
              </button>
              <button v-if="isEditing" type="button" @click="cancelEdit" class="cancel-btn">取消编辑</button>
            </div>
          </form>
          <p v-if="msg" :class="msgType">{{ msg }}</p>
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
import { 
  getAvailableApiBase, 
  setCustomApiBase, 
  getCustomApiBase, 
  clearCustomApiBase,
  API_CONFIGS 
} from '@/config/api';

const store = mainStore();
const title = ref('');
const content = ref('');
const msg = ref('');
const msgType = ref('success');
const isSubmitting = ref(false);
const articles = ref([]);
const loading = ref(false);
const selectedArticle = ref(null);
const editingArticle = ref(null);
const isEditing = ref(false);
const isDeleting = ref(false);
const deletingId = ref(null);
const showForm = ref(false);

// API 基础地址 - 动态获取
let API_BASE = "https://workers.xiugou.top"; // 默认值

// 显示发布表单
const showPublishForm = () => {
  showForm.value = true;
  isEditing.value = false;
  editingArticle.value = null;
  title.value = '';
  content.value = '';
  msg.value = '';
};

// 关闭发布表单
const closeForm = () => {
  showForm.value = false;
  isEditing.value = false;
  editingArticle.value = null;
  title.value = '';
  content.value = '';
  msg.value = '';
};

// 发布/更新文章
const submitArticle = async () => {
  if (isSubmitting.value) return;
  
  isSubmitting.value = true;
  msg.value = '';
  
  try {
    const url = isEditing.value 
      ? `${API_BASE}/api/articles/${editingArticle.value.id}`
      : `${API_BASE}/api/post`;
    
    const method = isEditing.value ? "PUT" : "POST";
    
    console.log('发送请求:', { url, method, title: title.value, content: content.value });
    
    const res = await fetch(url, {
      method: method,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer 123456"
      },
      body: JSON.stringify({
        title: title.value,
        content: content.value
      })
    });
    
    console.log('响应状态:', res.status, res.statusText);
    
    let result;
    try {
      result = await res.json();
      console.log('响应数据:', result);
    } catch (parseError) {
      console.error('解析响应JSON失败:', parseError);
      const text = await res.text();
      console.log('响应文本:', text);
      throw new Error(`服务器响应格式错误: ${text}`);
    }
    
    if (res.ok && result.success) {
      msg.value = isEditing.value ? "更新成功！" : "发布成功！";
      msgType.value = 'success';
      
      // 重新加载文章列表
      await loadArticles();
      
      // 延迟关闭表单，让用户看到成功消息
      setTimeout(() => {
        closeForm();
      }, 1500);
    } else {
      const errorMsg = result.error || `HTTP ${res.status}: ${res.statusText}`;
      msg.value = errorMsg + (isEditing.value ? " (更新失败)" : " (发布失败)");
      msgType.value = 'error';
      console.error('API错误:', errorMsg);
    }
  } catch (error) {
    console.error(isEditing.value ? '更新文章错误:' : '发布文章错误:', error);
    msg.value = `网络错误: ${error.message}`;
    msgType.value = 'error';
  } finally {
    isSubmitting.value = false;
  }
};

// 加载文章列表
const loadArticles = async () => {
  loading.value = true;
  try {
    console.log('正在加载文章列表...');
    const res = await fetch(`${API_BASE}/api/articles`);
    console.log('文章列表响应状态:', res.status, res.statusText);
    
    let result;
    try {
      result = await res.json();
      console.log('文章列表响应数据:', result);
    } catch (parseError) {
      console.error('解析文章列表响应JSON失败:', parseError);
      const text = await res.text();
      console.log('文章列表响应文本:', text);
      return;
    }
    
    if (res.ok && result.success) {
      articles.value = result.articles || [];
      console.log('成功加载文章数量:', articles.value.length);
    } else {
      console.error('加载文章失败:', result.error || `HTTP ${res.status}: ${res.statusText}`);
    }
  } catch (error) {
    console.error('加载文章网络错误:', error);
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

// 编辑文章
const editArticle = (article) => {
  editingArticle.value = article;
  isEditing.value = true;
  title.value = article.title;
  content.value = article.content;
  msg.value = '';
  showForm.value = true;
};

// 取消编辑
const cancelEdit = () => {
  closeForm();
};

// 删除文章
const deleteArticle = async (articleId) => {
  if (!confirm('确定要删除这篇文章吗？此操作不可撤销。')) {
    return;
  }
  
  isDeleting.value = true;
  deletingId.value = articleId;
  
  try {
    const res = await fetch(`${API_BASE}/api/articles/${articleId}`, {
      method: "DELETE",
      headers: {
        "Authorization": "Bearer 123456"
      }
    });
    
    const result = await res.json();
    
    if (res.ok && result.success) {
      msg.value = "删除成功！";
      msgType.value = 'success';
      
      // 如果正在编辑被删除的文章，取消编辑状态
      if (isEditing.value && editingArticle.value?.id === articleId) {
        cancelEdit();
      }
      
      // 重新加载文章列表
      await loadArticles();
    } else {
      msg.value = result.error || "删除失败！";
      msgType.value = 'error';
    }
  } catch (error) {
    console.error('删除文章错误:', error);
    msg.value = "网络错误，删除失败！";
    msgType.value = 'error';
  } finally {
    isDeleting.value = false;
    deletingId.value = null;
  }
};

// 组件挂载时加载文章列表
onMounted(async () => {
  console.log('学习记录组件已挂载');
  await loadArticles();
});
</script>

<style scoped>
.study-container {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  z-index: 1000;
  overflow: hidden;
  padding: 2rem;
  display: flex;
  flex-direction: column;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.5rem 2rem;
  background-color: #00000040;
  backdrop-filter: blur(10px);
  border-radius: 12px;
  margin-bottom: 1.5rem;
  animation: fade 0.5s;
}

.new-post-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0.75rem 1.5rem;
  background-color: #00d4aa;
  border: none;
  border-radius: 25px;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 14px;
  font-weight: 500;
}

.new-post-btn:hover {
  background-color: #00b894;
  transform: scale(1.05);
}

.new-post-btn:active {
  transform: scale(0.95);
}

.back-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0.75rem 1.5rem;
  background-color: #00000040;
  backdrop-filter: blur(10px);
  border: none;
  border-radius: 25px;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 14px;
}

.back-btn:hover {
  background-color: #00000060;
  transform: scale(1.05);
}

.back-btn:active {
  transform: scale(0.95);
}

.header h1 {
  color: white;
  font-size: 1.8rem;
  margin: 0;
  font-weight: 600;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.content {
  flex: 1;
  display: flex;
  overflow: hidden;
}

/* 发布弹窗样式 */
.publish-modal {
  max-width: 700px;
  width: 90%;
}

.publish-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.publish-form label {
  font-weight: 500;
  color: #ffffff90;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
}

.publish-form input,
.publish-form textarea {
  padding: 0.75rem 1rem;
  background-color: #ffffff20;
  backdrop-filter: blur(10px);
  border: 1px solid #ffffff30;
  border-radius: 8px;
  font-size: 14px;
  color: white;
  transition: all 0.3s ease;
  width: 100%;
  box-sizing: border-box;
}

.publish-form input::placeholder,
.publish-form textarea::placeholder {
  color: #ffffff60;
}

.publish-form input:focus,
.publish-form textarea:focus {
  outline: none;
  border-color: #ffffff60;
  background-color: #ffffff30;
}

.publish-form textarea {
  resize: vertical;
  min-height: 300px;
}

.form-actions {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
    align-items: center;
  }
  
  .submit-btn, .cancel-btn, .test-btn {
    background: transparent;
    border: 2px solid #00d4aa;
    color: #00d4aa;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    cursor: pointer;
    font-size: 1rem;
    transition: all 0.3s ease;
  }
  
  .submit-btn:hover, .cancel-btn:hover, .test-btn:hover {
    background-color: #00d4aa;
    color: #000;
    transform: translateY(-2px);
  }
  
  .cancel-btn {
    border-color: #ff6b6b;
    color: #ff6b6b;
  }
  
  .cancel-btn:hover {
    background-color: #ff6b6b;
    color: #fff;
  }
  
  .test-btn {
    border-color: #ffa500;
    color: #ffa500;
  }
  
  .test-btn:hover {
    background-color: #ffa500;
    color: #000;
  }

/* 消息样式 */
.modal-body p {
  text-align: center;
  margin-top: 1rem;
  padding: 0.75rem;
  border-radius: 8px;
  font-size: 0.9rem;
}

.modal-body p.success {
  background-color: #00ff0020;
  color: #90ee90;
  border: 1px solid #00ff0030;
}

.modal-body p.error {
  background-color: #ff000020;
  color: #ff9999;
  border: 1px solid #ff000030;
}

/* 文章列表样式 */
.articles-list {
  background-color: #00000040;
  backdrop-filter: blur(10px);
  border-radius: 12px;
  padding: 2rem;
  width: 100%;
  flex-grow: 1;
  animation: fade 0.5s;
  transition: all 0.3s ease;
  overflow-y: auto;
}

.articles-list:hover {
  transform: scale(1.01);
}

.articles-list:active {
  transform: scale(0.98);
}

.articles-list h2 {
  color: white;
  margin-bottom: 1.5rem;
  text-align: center;
  font-size: 1.5rem;
  font-weight: 600;
}

.loading, .no-articles {
  text-align: center;
  color: #ffffff80;
  font-size: 1rem;
  padding: 2rem 0;
}

.articles {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.article-item {
  background-color: #ffffff20;
  backdrop-filter: blur(10px);
  border-radius: 8px;
  padding: 1.25rem;
  border: 1px solid #ffffff30;
  transition: all 0.3s ease;
}

.article-item:hover {
  background-color: #ffffff30;
  transform: scale(1.02);
}

.article-item:active {
  transform: scale(0.98);
}

.article-item h3 {
  color: white;
  margin: 0 0 0.75rem 0;
  font-size: 1.1rem;
  font-weight: 600;
}

.article-content {
  color: #ffffff90;
  margin: 0 0 1rem 0;
  line-height: 1.6;
  font-size: 0.9rem;
}

.article-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
  color: #ffffff70;
}

.article-actions {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.view-btn, .edit-btn, .delete-btn {
  background-color: #ffffff20;
  backdrop-filter: blur(10px);
  color: white;
  border: 1px solid #ffffff30;
  border-radius: 6px;
  padding: 0.375rem 0.75rem;
  font-size: 0.75rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.view-btn:hover, .edit-btn:hover {
  background-color: #ffffff30;
  transform: scale(1.05);
}

.delete-btn:hover {
  background-color: #ff4444;
  border-color: #ff6666;
  transform: scale(1.05);
}

.view-btn:active, .edit-btn:active, .delete-btn:active {
  transform: scale(0.95);
}

.edit-btn {
  border-color: #4CAF50;
}

.edit-btn:hover {
  background-color: #4CAF50;
}

.delete-btn {
  border-color: #ff4444;
}

/* 弹窗样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
  backdrop-filter: blur(10px);
}

.modal-content {
  background-color: #00000080;
  backdrop-filter: blur(20px);
  border: 1px solid #ffffff30;
  border-radius: 12px;
  max-width: 800px;
  max-height: 80vh;
  width: 90%;
  overflow: hidden;
  box-shadow: 0 25px 50px rgba(0, 0, 0, 0.5);
  animation: fade 0.3s;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 30px 40px 20px;
  border-bottom: 1px solid #ffffff30;
}

.modal-header h2 {
  margin: 0;
  color: white;
  font-size: 24px;
  font-weight: 600;
}

.close-btn {
  background-color: #ffffff20;
  backdrop-filter: blur(10px);
  border: 1px solid #ffffff30;
  font-size: 30px;
  color: white;
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
  background-color: #ffffff30;
  transform: scale(1.1);
}

.close-btn:active {
  transform: scale(0.9);
}

.modal-body {
  padding: 30px 40px;
  overflow-y: auto;
  max-height: calc(80vh - 120px);
}

.article-full-content {
  color: #ffffff90;
  line-height: 1.8;
  font-size: 16px;
  margin: 0 0 20px 0;
  white-space: pre-wrap;
}

/* 响应式设计 */
@media (max-width: 1200px) {
  .articles-list {
    max-width: 100%;
  }
}

@media (max-width: 768px) {
  .study-container {
    padding: 1rem 0.5rem;
  }

  .header {
    padding: 1.25rem;
    margin-bottom: 1rem;
  }

  .header h1 {
    font-size: 1.5rem;
  }

  .back-btn {
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
  }

  .new-post-btn {
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
  }
  
  .articles-list {
    padding: 1.25rem;
    border-radius: 10px;
  }

  .publish-modal {
    width: 95%;
    max-width: 95%;
  }

  .publish-form label {
    font-size: 0.875rem;
  }

  .publish-form input,
  .publish-form textarea {
    font-size: 0.875rem;
    padding: 0.75rem;
  }

  .publish-form textarea {
    min-height: 200px;
  }

  .article-item {
    padding: 1rem;
  }

  .article-item h3 {
    font-size: 1rem;
  }

  .article-content {
    font-size: 0.8rem;
  }
  
  .modal-content {
    width: 95%;
    max-height: 90vh;
  }
  
  .modal-header {
    padding: 1.25rem 1.25rem 1rem;
  }

  .modal-header h2 {
    font-size: 1.25rem;
  }

  .modal-body {
    padding: 1.25rem;
    font-size: 0.875rem;
  }

  .close-btn {
    width: 1.75rem;
    height: 1.75rem;
    font-size: 1rem;
  }

  .article-actions {
     flex-direction: column;
     gap: 0.25rem;
     align-items: stretch;
   }

   .view-btn, .edit-btn, .delete-btn {
     padding: 0.25rem 0.5rem;
     font-size: 0.7rem;
   }

   .form-actions {
     flex-direction: column;
     gap: 0.75rem;
     align-items: stretch;
   }

   .submit-btn, .cancel-btn {
     padding: 0.625rem 1.25rem;
     font-size: 0.875rem;
   }
}
</style>