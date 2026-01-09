# ==========================================
# 第一阶段：编译 Snowflake (使用最新版 Go)
# ==========================================
# 修改点：这里改成了 alpine (即 latest)，确保 Go 版本 >= 1.23
FROM golang:alpine AS builder

# 安装 git
RUN apk add --no-cache git

WORKDIR /build

# 克隆 Snowflake 官方仓库
RUN git clone --depth 1 https://git.torproject.org/pluggable-transports/snowflake.git

# 进入客户端目录
WORKDIR /build/snowflake/client

# 编译
# CGO_ENABLED=0 确保生成的是静态二进制文件，不依赖系统库
RUN go mod download
RUN CGO_ENABLED=0 go build -o snowflake-client .

# ==========================================
# 第二阶段：最终运行环境 (Python)
# ==========================================
FROM python:3.9-slim

# 安装 Tor 和基础工具
RUN apt-get update && \
    apt-get install -y tor curl netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# === 从第一阶段复制编译好的 Snowflake ===
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
# 同时也给 snowflake-client 执行权限
RUN chmod +x /app/start.sh /usr/bin/snowflake-client

# 4. 修复 Tor 目录权限
RUN mkdir -p /var/lib/tor && chown -R root:root /var/lib/tor && chmod 700 /var/lib/tor

EXPOSE 5000

CMD ["/app/start.sh"]
