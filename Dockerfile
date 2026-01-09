FROM python:3.9-slim

# 只安装 tor 和 obfs4proxy (Meek 协议包含在这里面)
# 移除了 git, golang 等累赘
RUN apt-get update && \
    apt-get install -y tor curl netcat-openbsd obfs4proxy && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 安装依赖
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 复制文件
COPY src/app.py /app/app.py
COPY src/templates /app/templates
COPY torrc /app/torrc
COPY start.sh /app/start.sh

# 权限
RUN chmod +x /app/start.sh
RUN mkdir -p /var/lib/tor && chown -R root:root /var/lib/tor && chmod 700 /var/lib/tor

EXPOSE 5000

CMD ["/app/start.sh"]
