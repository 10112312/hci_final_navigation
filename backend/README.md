# Tesla Navigation Backend

这是一个为Tesla导航应用提供的后端服务，提供以下功能：

1. 用户认证和管理
2. Tesla车辆数据集成
3. 天气数据集成
4. 社区功能（帖子、评论、点赞）
5. 续航焦虑计算

## 环境要求

- Python 3.8+
- pip（Python包管理器）

## 安装

1. 创建虚拟环境（推荐）：
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
.\venv\Scripts\activate  # Windows
```

2. 安装依赖：
```bash
pip install -r requirements.txt
```

3. 配置环境变量：
创建 `.env` 文件并添加以下配置：
```
TESLA_API_KEY=your_tesla_api_key
OPENWEATHER_API_KEY=your_openweather_api_key
SECRET_KEY=your_jwt_secret_key
```

## 运行服务

```bash
uvicorn app.main:app --reload
```

服务将在 http://localhost:8000 运行

## API文档

启动服务后，访问以下地址查看API文档：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 主要功能

### 用户认证
- 注册新用户
- 用户登录
- 获取用户信息
- 更新用户资料
- 修改密码

### Tesla集成
- 获取超级充电站位置
- 获取车辆数据
- 获取车辆状态
- 计算包含充电站的路线

### 天气服务
- 获取当前天气
- 获取天气预报
- 计算天气对续航的影响

### 社区功能
- 创建帖子
- 获取帖子列表
- 点赞帖子
- 添加评论
- 获取评论列表

### 续航焦虑计算
- 计算续航焦虑指数
- 获取车型效率系数

## 开发说明

- 所有API端点都需要认证（除了注册和登录）
- 使用JWT进行身份验证
- 所有响应都是JSON格式
- 错误处理使用HTTP状态码

## 注意事项

1. 在生产环境中，请确保：
   - 使用安全的密钥
   - 启用HTTPS
   - 配置适当的CORS策略
   - 使用数据库而不是内存存储

2. Tesla API需要有效的API密钥
3. OpenWeather API需要有效的API密钥 