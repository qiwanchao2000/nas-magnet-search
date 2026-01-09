FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制代码
COPY src/ .

# 暴露 5000 端口
EXPOSE 5000

# 使用 Gunicorn 启动 (生产级 Web 服务器，比 python app.py 更稳)
# 4 个 worker 进程处理并发
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
