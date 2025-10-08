# NetLogo Web Docker 部署指南

本指南介绍如何使用 Docker 构建和运行 NetLogo Web (Galapagos) 应用。

## 快速开始

### 1. 构建镜像

首先需要构建 Docker 镜像：

```bash
# 使用构建脚本（推荐）
./build-docker-image.sh

# 或者直接使用 Docker 命令
docker build -t netlogo-web:latest .
```

### 2. 使用 docker-compose（推荐）

构建完镜像后，使用 docker-compose 启动服务：

```bash
# 启动服务
docker-compose up

# 后台运行
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 3. 构建脚本选项

```bash
# 构建默认镜像
./build-docker-image.sh

# 构建指定标签的镜像
./build-docker-image.sh --tag v1.0

# 构建并推送到镜像仓库
./build-docker-image.sh --push --registry your-registry.com/your-org

# 不使用缓存重新构建
./build-docker-image.sh --no-cache
```

### 4. 直接使用 Docker 命令

```bash
# 运行容器（开发模式，支持热重载）
docker run -p 9000:9000 -v $(pwd):/app -v $(pwd)/public/modelslib:/app/public/modelslib netlogo-web:latest

# 运行容器（生产模式，不挂载源代码）
docker run -p 9000:9000 netlogo-web:latest
```

## 访问应用

启动成功后，在浏览器中访问：
- **本地访问**: http://localhost:9000
- **容器内访问**: http://container-ip:9000

## 配置说明

### 镜像源优化

本 Dockerfile 已配置使用国内镜像源以提高下载速度：

- **Debian 源**: 使用阿里云 Debian 镜像
- **Node.js**: 使用华为云 Node.js v22.18.0 镜像
- **SBT**: 使用阿里云 SBT 镜像
- **NPM**: 配置使用 npmmirror.com
- **Maven**: 配置使用阿里云 Maven 仓库

### 环境变量

- `PLAY_HTTP_SECRET_KEY`: Play Framework 密钥
- `SBT_OPTS`: SBT JVM 选项
- `JAVA_OPTS`: Java JVM 选项

### 端口配置

- **默认端口**: 9000
- **修改端口**: 在 docker-compose.yml 中修改 `ports` 配置

### 内存配置

默认配置为 2GB 内存，如需调整：

```yaml
environment:
  - SBT_OPTS=-Xmx4G -XX:+UseG1GC
  - JAVA_OPTS=-Xmx4G -XX:+UseG1GC
```

## 开发模式 vs 生产模式

### 开发模式（默认）
- 挂载源代码目录，支持热重载
- 使用 `sbt run` 启动
- 适合开发和调试

### 生产模式
- 不挂载源代码，使用镜像内的代码
- 更好的性能和安全性
- 适合生产部署

```bash
# 生产模式运行
docker run -p 9000:9000 netlogo-web
```

## 数据持久化

Docker Compose 配置了以下 volumes：

### 缓存 volumes
- `sbt-cache`: SBT 缓存
- `ivy-cache`: Ivy 依赖缓存
- `npm-cache`: NPM 缓存
- `node-modules`: Node.js 模块

### 文件映射
- `./public/modelslib`: NetLogo 模型库目录，用户可以在此添加自定义的 .nlogo 文件

## 自定义 NetLogo 模型

您可以将自定义的 NetLogo 模型文件（.nlogo）放在 `public/modelslib/` 目录中：

```bash
# 在宿主机上添加自定义模型
cp your-model.nlogo third_party/Galapagos/public/modelslib/

# 重启服务以加载新模型
docker-compose restart
```

模型文件将自动在 NetLogo Web 界面中可用。

## 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口占用
   lsof -i :9000
   # 或修改 docker-compose.yml 中的端口映射
   ```

2. **内存不足**
   ```bash
   # 增加内存限制
   docker run -m 4g -p 9000:9000 netlogo-web
   ```

3. **构建失败**
   ```bash
   # 清理缓存重新构建
   docker-compose build --no-cache
   ```

4. **网络问题**
   ```bash
   # 如果阿里云镜像源无法访问，可以临时使用官方源
   # 修改 Dockerfile 中的镜像源配置
   ```

5. **依赖下载慢**
   - 已配置阿里云镜像源，通常下载速度较快
   - 如仍然较慢，可检查网络连接或尝试其他镜像源

### 查看日志

```bash
# 查看容器日志
docker-compose logs netlogo-web

# 实时查看日志
docker-compose logs -f netlogo-web

# 查看最近的日志
docker-compose logs --tail=100 netlogo-web
```

## 自定义配置

### 修改 Dockerfile

如需自定义构建过程，可以修改 `Dockerfile`：

- 更改 Java 版本
- 添加额外的系统依赖
- 修改内存配置
- 添加自定义脚本

### 修改 docker-compose.yml

如需自定义运行配置，可以修改 `docker-compose.yml`：

- 更改端口映射
- 添加环境变量
- 配置网络
- 添加额外的服务

## 生产部署建议

1. **使用固定版本标签**
   ```bash
   ./build-docker-image.sh --tag v1.0.0
   ```

2. **配置健康检查**
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:9000/"]
     interval: 30s
     timeout: 10s
     retries: 3
   ```

3. **使用 Docker Swarm 或 Kubernetes**
   - 支持高可用部署
   - 自动扩缩容
   - 负载均衡

4. **配置日志收集**
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

## 支持

如有问题，请检查：
1. Docker 和 Docker Compose 版本
2. 系统资源（内存、磁盘空间）
3. 网络连接
4. 防火墙设置
