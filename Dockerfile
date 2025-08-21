FROM openjdk:17-jdk-slim

# 使用阿里云 Debian 源
RUN sed -i 's/deb.debian.org/mirrors.huaweicloud.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.huaweicloud.com/g' /etc/apt/sources.list

# 安装必要的系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    xz-utils

# 安装 Node.js (使用华为云镜像，根据架构自动选择)
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) NODE_ARCH="x64" ;; \
        aarch64|arm64) NODE_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    echo "Detected architecture: $ARCH, using Node.js arch: $NODE_ARCH" && \
    curl -fsSL https://mirrors.huaweicloud.com/nodejs/v22.18.0/node-v22.18.0-linux-${NODE_ARCH}.tar.xz -o node.tar.xz \
    && tar -xf node.tar.xz -C /usr/local --strip-components=1 \
    && rm node.tar.xz \
    && ln -sf /usr/local/bin/node /usr/bin/node \
    && ln -sf /usr/local/bin/npm /usr/bin/npm \
    && ln -sf /usr/local/bin/npx /usr/bin/npx \
    && node --version && npm --version

# 安装 SBT (直接下载二进制文件)
COPY third/sbt-1.11.4.tgz sbt.tgz
RUN tar -xzf sbt.tgz -C /usr/local \
    && rm sbt.tgz \
    && ln -sf /usr/local/sbt/bin/sbt /usr/bin/sbt \
    && sbt --version

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 设置 SBT 和 Java 选项
ENV SBT_OPTS="-Xmx2G -XX:+UseG1GC"
ENV JAVA_OPTS="-Xmx2G -XX:+UseG1GC"

# 配置 NPM 使用阿里云镜像
RUN npm config set registry https://registry.npmmirror.com

# 配置 SBT 使用阿里云镜像
RUN mkdir -p /root/.sbt/1.0 && \
    echo 'resolvers += "huaweicloud Maven" at "https://maven.huaweicloud.com/repository/public"' > /root/.sbt/1.0/global.sbt && \
    echo 'resolvers += "huaweicloud Central" at "https://maven.huaweicloud.com/repository/central"' >> /root/.sbt/1.0/global.sbt

# 预下载依赖并编译（可选，用于加速后续启动）
RUN sbt update compile

# 暴露端口
EXPOSE 9000

# 启动命令
CMD ["sbt", "run"]