# Dockerfile (修复版)
FROM node:18-slim
WORKDIR /app

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libcups2 \
    libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 libx11-6 \
    libx11-xcb1 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
    libxrandr2 libxss1 libxtst6 xvfb \
    && rm -rf /var/lib/apt/lists/*

# 2. 拷贝 package.json 并安装依赖
COPY package*.json ./
RUN npm install --production

# 3. 【修复】浏览器下载和解压 - 添加错误处理和调试信息
ARG CAMOUFOX_URL
RUN echo "Downloading browser from: ${CAMOUFOX_URL}" && \
    curl -fSL "${CAMOUFOX_URL}" -o camoufox-linux.tar.gz && \
    echo "Download completed, extracting..." && \
    tar -xzf camoufox-linux.tar.gz && \
    ls -la && \
    echo "Cleaning up..." && \
    rm camoufox-linux.tar.gz && \
    echo "Setting permissions..." && \
    chmod +x /app/camoufox-linux/camoufox && \
    echo "Browser setup completed successfully"

# 4. 拷贝代码文件
COPY unified-server.js black-browser.js models.json ./

# 5. 创建目录并设置权限
RUN mkdir -p ./auth && chown -R node:node /app

# 切换到非 root 用户
USER node

# 暴露服务端口
EXPOSE 7860
EXPOSE 9998

# 设置环境变量
ENV CAMOUFOX_EXECUTABLE_PATH=/app/camoufox-linux/camoufox

# 定义容器启动命令
CMD ["node", "unified-server.js"]