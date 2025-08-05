// API配置文件
// 根据网络环境自动选择合适的API地址

// 检测网络连接状态
const checkNetworkAccess = async (url, timeout = 5000) => {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);
    
    const response = await fetch(url, {
      method: 'HEAD',
      signal: controller.signal,
      mode: 'cors'
    });
    
    clearTimeout(timeoutId);
    return response.ok;
  } catch (error) {
    console.log(`无法访问 ${url}:`, error.message);
    return false;
  }
};

// API地址配置
const API_CONFIGS = {
  // 主要的Cloudflare Workers API
  primary: {
    name: 'Cloudflare Workers',
    baseUrl: 'https://workers.xiugou.top',
    description: '主要API服务器（可能需要VPN）'
  },
  
  // 本地开发API（如果启动了本地服务器）
  local: {
    name: 'Local Development',
    baseUrl: 'http://localhost:8787',
    description: '本地开发服务器'
  },
  
  // 备用API地址（如果有的话）
  backup: {
    name: 'Backup Server',
    baseUrl: 'https://your-backup-domain.com',
    description: '备用API服务器'
  }
};

// 自动选择可用的API地址
const getAvailableApiBase = async () => {
  console.log('正在检测可用的API服务器...');
  
  // 按优先级检测API可用性
  const checkOrder = ['local', 'primary', 'backup'];
  
  for (const configKey of checkOrder) {
    const config = API_CONFIGS[configKey];
    if (!config) continue;
    
    console.log(`检测 ${config.name}: ${config.baseUrl}`);
    
    const isAvailable = await checkNetworkAccess(`${config.baseUrl}/api/articles`);
    
    if (isAvailable) {
      console.log(`✅ ${config.name} 可用`);
      return {
        baseUrl: config.baseUrl,
        config: config
      };
    } else {
      console.log(`❌ ${config.name} 不可用`);
    }
  }
  
  // 如果都不可用，返回主要地址并提示用户
  console.warn('所有API服务器都不可用，使用主要地址');
  return {
    baseUrl: API_CONFIGS.primary.baseUrl,
    config: API_CONFIGS.primary,
    needsVpn: true
  };
};

// 手动设置API地址（用于用户自定义）
const setCustomApiBase = (customUrl) => {
  localStorage.setItem('custom_api_base', customUrl);
  console.log('已设置自定义API地址:', customUrl);
};

// 获取自定义API地址
const getCustomApiBase = () => {
  return localStorage.getItem('custom_api_base');
};

// 清除自定义API地址
const clearCustomApiBase = () => {
  localStorage.removeItem('custom_api_base');
  console.log('已清除自定义API地址');
};

export {
  API_CONFIGS,
  getAvailableApiBase,
  setCustomApiBase,
  getCustomApiBase,
  clearCustomApiBase,
  checkNetworkAccess
};