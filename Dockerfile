FROM python:3.9-slim

# 安装 Tor 和常用工具
RUN apt-get update && \
    apt-get install -y tor curl netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. 安装依赖
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 2. [核心修复] 明确复制文件结构
# 确保 app.py 直接位于 /app/app.py
COPY src/app.py /app/app.py
# 确保 templates 文件夹位于 /app/templates
COPY src/templates /app/templates
# 复制配置文件
COPY torrc /app/torrc
COPY start.sh /app/start.sh

# 3. 赋予脚本执行权限
RUN chmod +x /app/start.sh

# 暴露端口
EXPOSE 5000

# 启动
CMD ["/app/start.sh"]
