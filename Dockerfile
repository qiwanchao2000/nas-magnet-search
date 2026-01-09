FROM python:3.9-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制代码
COPY src/ .

# 暴露端口
EXPOSE 5000

# 启动 (使用环境变量控制代理)
CMD ["gunicorn", "-w", "3", "-b", "0.0.0.0:5000", "app:app"]
