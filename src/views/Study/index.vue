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
        <plus theme="outline" size="16" />
        新建发布
      </button>
    </div>
    
    <!-- 时间轴主要内容区域 -->
    <div class="timeline-container" ref="timelineContainer">
      <div v-if="loading" class="loading">
        <div class="loading-spinner"></div>
        <span>加载中...</span>
      </div>
      <div v-else-if="groupedArticles.length === 0" class="no-articles">
        <div class="empty-icon">📚</div>
        <p>暂无学习记录</p>
        <span>开始记录你的学习之旅吧！</span>
      </div>
      <div v-else class="timeline-wrapper">
        <!-- 时间轴线 -->
        <div class="timeline-line"></div>
        
        <!-- 时间轴节点 -->
        <div 
          v-for="(dayGroup, index) in groupedArticles" 
          :key="dayGroup.date"
          :class="['timeline-item', index % 2 === 0 ? 'timeline-item-top' : 'timeline-item-bottom']"
          :style="{ left: `${index * 200 + 100}px` }"
        >
          <!-- 时间轴点 -->
          <div class="timeline-dot" @click="selectDay(dayGroup)">
            <div class="dot-inner">
              <span class="article-count">{{ dayGroup.articles.length }}</span>
            </div>
            <div class="date-label">{{ formatDateShort(dayGroup.date) }}</div>
          </div>
          
          <!-- 文章卡片 -->
          <div class="article-card cards" @click="handleArticleClick(dayGroup)">
            <div class="card-content">
              <h3 class="article-title">{{ getDisplayArticle(dayGroup).title }}</h3>
              <div class="article-meta">
                <span class="article-time">{{ formatTime(getDisplayArticle(dayGroup).created_at) }}</span>
                <span v-if="dayGroup.articles.length > 1" class="multiple-indicator">
                  +{{ dayGroup.articles.length - 1 }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 多文章选择弹窗 -->
    <div v-if="showArticleSelector" class="modal-overlay" @click="closeArticleSelector">
      <div class="modal-content article-selector-modal" @click.stop>
        <div class="modal-header">
          <h2>{{ formatDate(selectedDay?.date) }} 的文章</h2>
          <button @click="closeArticleSelector" class="close-btn">&times;</button>
        </div>
        <div class="modal-body">
          <div class="article-list">
            <div 
              v-for="article in selectedDay?.articles" 
              :key="article.id"
              class="article-option cards"
              @click="selectArticleFromDay(article)"
            >
              <h4>{{ article.title }}</h4>
              <p class="article-preview">{{ truncateContent(article.content, 60) }}</p>
              <div class="article-time">{{ formatTime(article.created_at) }}</div>
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
          <div class="article-actions">
            <button @click="editArticle(selectedArticle)" class="action-btn edit-btn">
              <Edit :size="16" />
              编辑
            </button>
            <button @click="deleteArticle(selectedArticle.id)" class="action-btn delete-btn">
              <Delete :size="16" />
              删除
            </button>
          </div>
        </div>
      </div>
    </div>
   </div>
 </template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { ArrowLeft, Plus, Edit, Delete } from '@icon-park/vue-next';
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

// 时间轴相关状态
const showArticleSelector = ref(false);
const selectedDay = ref(null);
const randomizedArticles = ref(new Map()); // 存储每天随机选择的文章
const selectedArticle = ref(null);
const editingArticle = ref(null);
const isEditing = ref(false);
const isDeleting = ref(false);
const deletingId = ref(null);
const showForm = ref(false);

// API 基础地址 - 动态获取
let API_BASE = "https://workers.xiugou.top"; // 默认值

// 按日期分组的文章
const groupedArticles = computed(() => {
  const groups = new Map();
  
  articles.value.forEach(article => {
    const date = new Date(article.created_at).toDateString();
    if (!groups.has(date)) {
      groups.set(date, {
        date: date,
        articles: []
      });
    }
    groups.get(date).articles.push(article);
  });
  
  // 按日期排序（新日期在前）
  return Array.from(groups.values()).sort((a, b) => new Date(b.date) - new Date(a.date));
});

// 获取要显示的文章（每天随机选择一篇）
const getDisplayArticle = (dayGroup) => {
  const dateKey = dayGroup.date;
  
  // 如果已经为这一天选择了文章，返回已选择的
  if (randomizedArticles.value.has(dateKey)) {
    const selectedId = randomizedArticles.value.get(dateKey);
    return dayGroup.articles.find(article => article.id === selectedId) || dayGroup.articles[0];
  }
  
  // 随机选择一篇文章
  const randomIndex = Math.floor(Math.random() * dayGroup.articles.length);
  const selectedArticle = dayGroup.articles[randomIndex];
  randomizedArticles.value.set(dateKey, selectedArticle.id);
  
  return selectedArticle;
};

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
      
      // 重新添加测试数据（与现有文章合并）
      const testData = generateTestData();
      articles.value = [...articles.value, ...testData];
      console.log('重新添加测试数据，现有文章总数:', articles.value.length, '篇');
      
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
    day: '2-digit'
  });
};

// 格式化短日期（用于时间轴点）
const formatDateShort = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const month = date.getMonth() + 1;
  const day = date.getDate();
  return `${month}/${day}`;
};

// 格式化时间（用于文章选择器）
const formatTime = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleString('zh-CN', {
    hour: '2-digit',
    minute: '2-digit'
  });
};

// 处理文章卡片点击
const handleArticleClick = (dayGroup) => {
  if (dayGroup.articles.length === 1) {
    // 只有一篇文章，直接查看
    viewFullArticle(dayGroup.articles[0]);
  } else {
    // 多篇文章，显示选择器
    selectDay(dayGroup);
  }
};

// 选择某一天（显示文章选择器）
const selectDay = (dayGroup) => {
  selectedDay.value = dayGroup;
  showArticleSelector.value = true;
};

// 关闭文章选择器
const closeArticleSelector = () => {
  showArticleSelector.value = false;
  selectedDay.value = null;
};

// 从某一天选择特定文章
const selectArticleFromDay = (article) => {
  closeArticleSelector();
  viewFullArticle(article);
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
      
      // 重新添加测试数据（与现有文章合并）
      const testData = generateTestData();
      articles.value = [...articles.value, ...testData];
      console.log('删除后重新添加测试数据，现有文章总数:', articles.value.length, '篇');
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

// 生成测试数据
const generateTestData = () => {
  const testArticles = [];
  const baseDate = new Date('2024-08-03');
  
  const titles = [
    'Vue 3 响应式原理深度解析',
    'JavaScript 异步编程最佳实践',
    'CSS Grid 布局完全指南',
    'TypeScript 高级类型系统',
    'React Hooks 使用技巧',
    'Node.js 性能优化策略',
    'Webpack 5 配置详解',
    'ES2023 新特性总览',
    '前端工程化实践指南',
    '微前端架构设计思考',
    'GraphQL 实战应用',
    'PWA 开发完整教程',
    'Docker 容器化部署',
    'MongoDB 数据库设计',
    'Redis 缓存优化'
  ];
  
  const contents = [
    '深入探讨Vue 3的响应式系统，包括Proxy的使用、依赖收集机制、以及与Vue 2的区别。通过实例代码演示如何利用响应式特性构建高效的应用。',
    '详细介绍JavaScript中的异步编程模式，包括Promise、async/await、以及错误处理最佳实践。帮助开发者写出更优雅的异步代码。',
    '全面讲解CSS Grid布局系统，从基础概念到高级应用，包含大量实例和最佳实践，让你彻底掌握现代CSS布局技术。',
    '深入TypeScript的高级类型系统，包括泛型、条件类型、映射类型等，提升代码的类型安全性和可维护性。',
    '分享React Hooks的实用技巧和最佳实践，包括自定义Hook的设计模式和性能优化策略。',
    '探讨Node.js应用的性能优化方法，包括内存管理、事件循环优化、以及监控和调试技巧。',
    '详细解析Webpack 5的新特性和配置方法，包括模块联邦、Tree Shaking优化等高级功能。',
    '介绍ES2023的最新语言特性，包括新的语法糖、API改进，以及在实际项目中的应用场景。',
    '分享前端工程化的完整实践方案，包括代码规范、自动化测试、CI/CD流程等。',
    '探讨微前端架构的设计理念和实现方案，分析不同技术栈的集成策略和最佳实践。',
    '深入GraphQL的实战应用，包括Schema设计、查询优化、以及与REST API的对比分析。',
    'Progressive Web App开发的完整教程，包括Service Worker、缓存策略、离线功能实现。',
    '详解Docker在前端项目中的应用，包括镜像构建、容器编排、以及部署优化策略。',
    'MongoDB数据库设计的最佳实践，包括文档结构设计、索引优化、以及查询性能调优。',
    'Redis缓存系统的深度应用，包括数据结构选择、过期策略、以及分布式缓存架构。'
  ];
  
  // 预定义每天的文章数量和内容索引，确保数据稳定
  const dailyData = [
    { count: 2, indices: [0, 1] },    // 8月3日 - 2篇
    { count: 1, indices: [2] },       // 8月2日 - 1篇
    { count: 2, indices: [3, 4] },    // 8月1日 - 2篇
    { count: 3, indices: [5, 6, 7] }, // 7月31日 - 3篇
    { count: 1, indices: [8] },       // 7月30日 - 1篇
    { count: 2, indices: [9, 10] },   // 7月29日 - 2篇
    { count: 1, indices: [11] },      // 7月28日 - 1篇
    { count: 2, indices: [12, 13] },  // 7月27日 - 2篇
    { count: 1, indices: [14] },      // 7月26日 - 1篇
    { count: 2, indices: [0, 5] }     // 7月25日 - 2篇
  ];
  
  // 生成10天的数据
  for (let i = 0; i < 10; i++) {
    const currentDate = new Date(baseDate);
    currentDate.setDate(baseDate.getDate() - i);
    
    const dayData = dailyData[i];
    
    for (let j = 0; j < dayData.count; j++) {
      const titleIndex = dayData.indices[j] % titles.length;
      testArticles.push({
        id: `test-${i}-${j}`,
        title: titles[titleIndex],
        content: contents[titleIndex],
        created_at: currentDate.toISOString()
      });
    }
  }
  
  return testArticles;
};

// 时间轴容器引用
const timelineContainer = ref(null);

// 鼠标滚轮事件处理
const handleWheel = (event) => {
  event.preventDefault();
  const container = timelineContainer.value;
  if (container) {
    // 滚轮向上滚动时向左滑动，向下滚动时向右滑动
    const scrollAmount = event.deltaY > 0 ? 100 : -100;
    container.scrollBy({
      left: scrollAmount,
      behavior: 'smooth'
    });
  }
};

// 组件挂载时加载文章列表
onMounted(async () => {
  console.log('学习记录组件已挂载');
  await loadArticles();
  
  // 添加测试数据（与现有文章合并）
  const testData = generateTestData();
  articles.value = [...articles.value, ...testData];
  console.log('已添加测试数据，现有文章总数:', articles.value.length, '篇');
  
  // 添加鼠标滚轮事件监听器
  const container = timelineContainer.value;
  if (container) {
    container.addEventListener('wheel', handleWheel, { passive: false });
  }
});

// 组件卸载时清理事件监听器
onBeforeUnmount(() => {
  const container = timelineContainer.value;
  if (container) {
    container.removeEventListener('wheel', handleWheel);
  }
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
  background: linear-gradient(135deg, rgba(0, 0, 0, 0.1) 0%, rgba(0, 0, 0, 0.3) 100%);
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.5rem 2rem;
  background-color: #00000040;
  backdrop-filter: blur(20px);
  border-radius: 16px;
  margin-bottom: 2rem;
  animation: slideInDown 0.6s ease-out;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.new-post-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0.75rem 1.5rem;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 25px;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 14px;
  font-weight: 500;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.new-post-btn:hover {
  background: rgba(255, 255, 255, 0.15);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  border-color: rgba(255, 255, 255, 0.3);
}

.new-post-btn:active {
  transform: translateY(0);
}

.back-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0.75rem 1.5rem;
  background-color: #00000040;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 25px;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 14px;
}

.back-btn:hover {
  background-color: #00000060;
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
}

.back-btn:active {
  transform: translateY(0);
}

.header h1 {
  color: white;
  font-size: 1.8rem;
  font-weight: 600;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

/* 时间轴容器 */
.timeline-container {
  flex: 1;
  overflow-x: auto;
  overflow-y: hidden;
  position: relative;
  padding: 2rem 0;
}

.timeline-wrapper {
  position: relative;
  height: 100%;
  min-width: 100%;
  padding: 0 100px;
}

/* 时间轴主线 */
.timeline-line {
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  height: 2px;
  background: linear-gradient(90deg, 
    rgba(255, 255, 255, 0.1) 0%, 
    rgba(255, 255, 255, 0.3) 50%, 
    rgba(255, 255, 255, 0.1) 100%);
  border-radius: 1px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

/* 时间轴项目 */
.timeline-item {
  position: absolute;
  width: 280px;
  transition: all 0.3s ease;
}

.timeline-item-top {
  top: 10%;
}

.timeline-item-bottom {
  bottom: 10%;
}

/* 时间轴点 */
.timeline-dot {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  cursor: pointer;
  z-index: 10;
}

.timeline-item-top .timeline-dot {
  bottom: -60px;
}

.timeline-item-bottom .timeline-dot {
  top: -60px;
}

.dot-inner {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
  transition: all 0.3s ease;
  border: 2px solid rgba(255, 255, 255, 0.2);
}

.dot-inner:hover {
  transform: scale(1.05);
  background: rgba(255, 255, 255, 0.25);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.article-count {
  color: white;
  font-weight: bold;
  font-size: 14px;
}

.date-label {
  position: absolute;
  top: 50px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.6);
  color: rgba(255, 255, 255, 0.9);
  padding: 3px 8px;
  border-radius: 8px;
  font-size: 11px;
  white-space: nowrap;
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  font-weight: 500;
}

.timeline-item-bottom .date-label {
  top: -35px;
}

/* 文章卡片 */
.article-card {
  background: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  padding: 1rem 1.2rem;
  border: 1px solid rgba(255, 255, 255, 0.1);
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
  animation: fadeInUp 0.6s ease-out;
  max-width: 240px;
}

.article-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
  background: rgba(0, 0, 0, 0.5);
  border-color: rgba(255, 255, 255, 0.2);
}

.card-content {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.article-title {
  color: white;
  font-size: 0.95rem;
  font-weight: 500;
  margin: 0;
  line-height: 1.3;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.article-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.6);
}

.article-time {
  color: rgba(255, 255, 255, 0.6);
}

.multiple-indicator {
  background: rgba(255, 255, 255, 0.15);
  color: rgba(255, 255, 255, 0.8);
  padding: 2px 6px;
  border-radius: 8px;
  font-size: 0.7rem;
  font-weight: 500;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.article-preview {
  color: rgba(255, 255, 255, 0.8);
  line-height: 1.5;
  font-size: 0.9rem;
}

.card-footer {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding-top: 1rem;
}

.article-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 0.4rem 0.8rem;
  border: none;
  border-radius: 8px;
  font-size: 0.8rem;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(10px);
}

.view-btn {
  background: rgba(52, 152, 219, 0.3);
  color: #3498db;
  border: 1px solid rgba(52, 152, 219, 0.5);
}

.view-btn:hover {
  background: rgba(52, 152, 219, 0.5);
  color: white;
}

.edit-btn {
  background: rgba(241, 196, 15, 0.3);
  color: #f1c40f;
  border: 1px solid rgba(241, 196, 15, 0.5);
}

.edit-btn:hover {
  background: rgba(241, 196, 15, 0.5);
  color: white;
}

.delete-btn {
  background: rgba(231, 76, 60, 0.3);
  color: #e74c3c;
  border: 1px solid rgba(231, 76, 60, 0.5);
}

.delete-btn:hover {
  background: rgba(231, 76, 60, 0.5);
  color: white;
}

/* 加载状态 */
.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: white;
  font-size: 1.1rem;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-top: 3px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 空状态 */
.no-articles {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: white;
  text-align: center;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
  opacity: 0.7;
}

.no-articles p {
  font-size: 1.3rem;
  margin-bottom: 0.5rem;
  font-weight: 600;
}

.no-articles span {
  font-size: 1rem;
  opacity: 0.7;
}

/* 文章选择器模态框 */
.article-selector-modal {
  max-width: 600px;
  max-height: 70vh;
}

.article-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-height: 400px;
  overflow-y: auto;
}

.article-option {
  padding: 1rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.article-option:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: translateY(-2px);
}

.article-option h4 {
  color: white;
  margin-bottom: 0.5rem;
  font-size: 1rem;
}

.article-option .article-preview {
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.9rem;
  margin-bottom: 0.5rem;
  line-height: 1.4;
}

.article-time {
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.8rem;
}

/* 动画 */
@keyframes slideInDown {
  from {
    opacity: 0;
    transform: translateY(-30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 滚动条样式 */
.timeline-container::-webkit-scrollbar {
  height: 12px;
}

.timeline-container::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.timeline-container::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.3) 0%, rgba(255, 255, 255, 0.5) 100%);
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  transition: all 0.3s ease;
}

.timeline-container::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.5) 0%, rgba(255, 255, 255, 0.7) 100%);
  border-color: rgba(255, 255, 255, 0.3);
  transform: scaleY(1.2);
}

.article-list::-webkit-scrollbar {
  width: 6px;
}

.article-list::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
}

.article-list::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 3px;
}

.article-list::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.5);
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

.article-actions {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 8px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(10px);
}

.edit-btn {
  background: rgba(59, 130, 246, 0.2);
  color: #60a5fa;
  border: 1px solid rgba(59, 130, 246, 0.3);
}

.edit-btn:hover {
  background: rgba(59, 130, 246, 0.3);
  transform: translateY(-1px);
}

.delete-btn {
  background: rgba(239, 68, 68, 0.2);
  color: #f87171;
  border: 1px solid rgba(239, 68, 68, 0.3);
}

.delete-btn:hover {
  background: rgba(239, 68, 68, 0.3);
  transform: translateY(-1px);
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