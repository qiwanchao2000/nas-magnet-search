FROM python:3.9-slim

# === [关键修改] 安装 obfs4proxy (用于网桥混淆) ===
RUN apt-get update && \
    apt-get install -y tor curl netcat-openbsd obfs4proxy && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. 安装依赖
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 2. 复制文件
COPY src/app.py /app/app.py
COPY src/templates /app/templates
COPY torrc /app/torrc
COPY start.sh /app/start.sh

# 3. 权限
RUN chmod +x /app/start.sh

EXPOSE 5000

CMD ["/app/start.sh"]
