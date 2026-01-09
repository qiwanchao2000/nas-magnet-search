# ==========================================
# 第一阶段：编译 Snowflake 客户端 (使用 Go 镜像)
# ==========================================
FROM golang:1.21-alpine AS builder

# 安装 git
RUN apk add --no-cache git

WORKDIR /build

# 克隆 Snowflake 官方仓库
# 使用 --depth 1 加速下载
RUN git clone --depth 1 https://git.torproject.org/pluggable-transports/snowflake.git

# 进入客户端目录并编译
WORKDIR /build/snowflake/client
# 编译生成名为 snowflake-client 的二进制文件
RUN go mod download
RUN go build -o snowflake-client .

# ==========================================
# 第二阶段：最终运行环境 (Python 镜像)
# ==========================================
FROM python:3.9-slim

# 安装 Tor 和基础网络工具
# 注意：这里不再需要安装 golang，节省空间
RUN apt-get update && \
    apt-get install -y tor curl netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# === 关键步骤：从第一阶段复制编译好的 Snowflake ===
COPY --from=builder /build/snowflake/client/snowflake-client /usr/bin/snowflake-client

# 1. 安装依赖
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 2. 复制项目文件
COPY src/app.py /app/app.py
COPY src/templates /app/templates
COPY torrc /app/torrc
COPY start.sh /app/start.sh

# 3. 赋予权限
RUN chmod +x /app/start.sh /usr/bin/snowflake-client

# 4. 创建 Tor 数据目录权限
RUN mkdir -p /var/lib/tor && chown -R root:root /var/lib/tor && chmod 700 /var/lib/tor

EXPOSE 5000

CMD ["/app/start.sh"]
