#!/bin/bash

# === [修复 1] 强制修复 Tor 目录权限 ===
# 这一步至关重要：因为容器是 root 运行的，必须把数据目录也给 root
if [ -d "/var/lib/tor" ]; then
    chown -R root:root /var/lib/tor
    chmod 700 /var/lib/tor
else
    mkdir -p /var/lib/tor
    chown -R root:root /var/lib/tor
    chmod 700 /var/lib/tor
fi

echo ">>> [1/3] 启动 Tor 代理..."
# 以前台模式启动 Tor (便于调试)，放入后台运行
tor -f /app/torrc &

echo ">>> [2/3] 等待 Tor 建立链路 (最长等待 120 秒)..."
# 循环检查本地 9050 端口
# 只有端口通了，才允许启动 Python
for i in {1..120}; do
    if echo > /dev/tcp/127.0.0.1/9050; then
        echo ">>> Tor 端口已就绪！"
        break
    fi
    # 如果 60 秒还没好，打印一个提示
    if [ $i -eq 60 ]; then
        echo ">>> Tor 启动较慢，请耐心等待..."
    fi
    sleep 1
done

# 再多等 5 秒，确保链路稳定
sleep 5

echo ">>> [3/3] 启动搜索服务..."
# === [修复 2] 显式指定目录，防止找不到文件 ===
# 确保我们在 /app 目录下运行
cd /app
exec gunicorn -w 3 -b 0.0.0.0:5000 --timeout 120 app:app
