#!/bin/bash

# === [修复 1] 强制配置 DNS ===
# 解决 "lookup ... no such host" 报错
# 使用阿里云 DNS，确保在国内能解析微软域名
echo "nameserver 223.5.5.5" > /etc/resolv.conf
echo "nameserver 114.114.114.114" >> /etc/resolv.conf

# === [修复 2] 修复 Tor 目录权限 ===
if [ -d "/var/lib/tor" ]; then
    chown -R root:root /var/lib/tor
    chmod 700 /var/lib/tor
else
    mkdir -p /var/lib/tor
    chown -R root:root /var/lib/tor
    chmod 700 /var/lib/tor
fi

echo ">>> [1/3] 启动 Tor 代理 (Azure Snowflake)..."
tor -f /app/torrc &

echo ">>> [2/3] 等待 Tor 建立链路 (最长等待 180 秒)..."
# Snowflake 建立连接比较慢，稍微多给点耐心
for i in {1..180}; do
    if echo > /dev/tcp/127.0.0.1/9050; then
        echo ">>> Tor 端口已就绪！正在寻找节点..."
        break
    fi
    if [ $i -eq 60 ]; then
        echo ">>> 正在努力穿透防火墙，请耐心..."
    fi
    sleep 1
done

sleep 5

echo ">>> [3/3] 启动搜索服务..."
cd /app
exec gunicorn -w 3 -b 0.0.0.0:5000 --timeout 120 app:app
