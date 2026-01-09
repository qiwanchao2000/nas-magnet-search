#!/bin/bash

# 0. 修复 Tor 数据目录权限 (防止 Permission denied)
# 如果目录不存在则创建
mkdir -p /var/lib/tor
# 赋予当前用户 (root) 权限，确保 Tor 能写文件
chmod 700 /var/lib/tor

echo ">>> [1] 正在启动内置 Tor 代理..."
# 后台启动 Tor
tor -f /app/torrc &

echo ">>> [2] 等待 Tor 建立加密链路 (可能需要 15-60 秒)..."
# 循环检查本地 9050 端口是否开启
# 增加重试次数到 120 次 (2分钟)，给 Tor 更多时间
for i in {1..120}; do
    if echo > /dev/tcp/127.0.0.1/9050; then
        echo ">>> Tor 端口已就绪！"
        break
    fi
    sleep 1
done

# 给 Tor 一点时间去寻找节点 (Warm-up)
sleep 10

echo ">>> [3] 启动搜索服务..."
# 启动 Web 服务
exec gunicorn -w 3 -b 0.0.0.0:5000 --timeout 120 app:app
