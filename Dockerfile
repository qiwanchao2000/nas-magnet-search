FROM python:3.9-slim

# 安装 Tor 和编译环境 (为了装 Snowflake)
RUN apt-get update && \
    apt-get install -y tor curl netcat-openbsd git golang && \
    rm -rf /var/lib/apt/lists/*

# 编译安装 Snowflake 客户端
RUN go install github.com/keroserene/snowflake/client@latest && \
    mv /root/go/bin/client /usr/bin/snowflake-client

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

EXPOSE 5000

CMD ["/app/start.sh"]
