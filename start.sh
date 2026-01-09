#!/bin/bash

# 1. 强制配置 DNS (使用阿里和114，确保能解析微软域名)
echo "nameserver 223.5.5.5" > /etc/resolv.conf
echo "nameserver 114.114.114.114" >> /etc/resolv.conf

# 2. 修复 Tor 目录权限
if [ -d "/var/lib/tor" ]; then
    chown -R root:root /var/lib/tor
    chmod 700 /var/lib/tor
else
    mkdir -p /var/lib/tor
    chown -R root:root /var/lib/tor
    chmod 700 /var/lib/tor
fi

echo ">>> [1/3] 启动 Tor 代理 (Meek-Azure Mode)..."
tor -f /app/torrc &

echo ">>> [2/3] 等待 Tor 建立链路 (最长等待 3 分钟)..."
# 循环检查本地 9050 端口
for i in {1..180}; do
    if echo > /dev/tcp/127.0.0.1/9050; then
        echo ">>> Tor 端口已就绪！正在进行流量伪装..."
        break
    fi
    if [ $i -eq 60 ]; then
        echo ">>> Meek 协议连接较慢，正在伪装成 HTTPS 流量..."
    fi
    sleep 1
done

sleep 5

echo ">>> [3/3] 启动搜索服务..."
cd /app
exec gunicorn -w 3 -b 0.0.0.0:5000 --timeout 120 app:app
