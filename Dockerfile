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

# 3. 【修复】浏览器下载和解压 - 双重下载策略（官方源 + 备用源）
ARG CAMOUFOX_URL
ARG FALLBACK_URL
RUN echo "=== Browser Download Strategy ===" && \
    echo "Primary URL: ${CAMOUFOX_URL}" && \
    echo "Fallback URL: ${FALLBACK_URL}" && \
    echo "" && \
    # 尝试从主 URL 下载
    if [ -n "${CAMOUFOX_URL}" ]; then \
        echo "Attempting download from primary source..." && \
        if curl -fSL "${CAMOUFOX_URL}" -o camoufox-linux.tar.gz; then \
            echo "✓ Primary download successful"; \
        else \
            echo "✗ Primary download failed, trying fallback..."; \
            rm -f camoufox-linux.tar.gz; \
        fi; \
    else \
        echo "⚠ Primary URL is empty, skipping to fallback..."; \
    fi && \
    # 如果主 URL 失败或为空，使用备用 URL
    if [ ! -f camoufox-linux.tar.gz ]; then \
        echo "Downloading from fallback source..." && \
        curl -fSL "${FALLBACK_URL}" -o camoufox-linux.tar.gz && \
        echo "✓ Fallback download successful"; \
    fi && \
    echo "" && \
    echo "Extracting archive..." && \
    tar -xzf camoufox-linux.tar.gz && \
    echo "✓ Extraction completed" && \
    echo "" && \
    echo "Directory contents:" && \
    ls -la && \
    echo "" && \
    echo "Cleaning up archive..." && \
    rm camoufox-linux.tar.gz && \
    echo "Setting executable permissions..." && \
    chmod +x /app/camoufox-linux/camoufox && \
    echo "✓ Browser setup completed successfully"

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