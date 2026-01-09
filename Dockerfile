FROM python:3.9-slim

# 安装 Tor 和必要的网络工具
RUN apt-get update && \
    apt-get install -y tor curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制所有文件
COPY . .

# 赋予脚本权限
RUN chmod +x start.sh
RUN mkdir -p /var/lib/tor && chown -R debian-tor:debian-tor /var/lib/tor

EXPOSE 5000

# 使用脚本启动
CMD ["./start.sh"]
