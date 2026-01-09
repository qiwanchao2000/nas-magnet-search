#!/bin/bash

echo ">>> [1] 正在启动内置 Tor 代理..."
# 后台启动 Tor
tor -f /app/torrc &

echo ">>> [2] 等待 Tor 建立加密链路 (可能需要 15-30 秒)..."
# 循环检查本地 9050 端口是否开启
for i in {1..60}; do
    if echo > /dev/tcp/127.0.0.1/9050; then
        echo ">>> Tor 端口已就绪！"
        break
    fi
    sleep 1
done

# 给 Tor 一点时间去寻找节点
sleep 5

echo ">>> [3] 启动搜索服务..."
# 启动 Web 服务
exec gunicorn -w 3 -b 0.0.0.0:5000 --timeout 60 app:app
