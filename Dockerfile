# ==========================================
# 第一阶段：编译 Snowflake (保留作为备用)
# ==========================================
FROM golang:alpine AS builder
RUN apk add --no-cache git
WORKDIR /build
RUN git clone --depth 1 https://git.torproject.org/pluggable-transports/snowflake.git
WORKDIR /build/snowflake/client
RUN go mod download && CGO_ENABLED=0 go build -o snowflake-client .

# ==========================================
# 第二阶段：最终运行环境
# ==========================================
FROM python:3.9-slim

# === [关键修改] 安装 obfs4proxy (用于 Meek 协议) ===
# 同时也保留了 curl, netcat 等工具
RUN apt-get update && \
    apt-get install -y tor curl netcat-openbsd obfs4proxy && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制 Snowflake (作为备用方案)
COPY --from=builder /build/snowflake/client/snowflake-client /usr/bin/snowflake-client

# 1. 安装依赖
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 2. 复制文件
COPY src/app.py /app/app.py
COPY src/templates /app/templates
COPY torrc /app/torrc
COPY start.sh /app/start.sh

# 3. 权限
RUN chmod +x /app/start.sh /usr/bin/snowflake-client
RUN mkdir -p /var/lib/tor && chown -R root:root /var/lib/tor && chmod 700 /var/lib/tor

EXPOSE 5000

CMD ["/app/start.sh"]
