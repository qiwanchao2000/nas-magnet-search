from flask import Flask, render_template, request, jsonify
import requests
import concurrent.futures
import time

app = Flask(__name__)

# Tor 代理
PROXIES = {
    'http': 'socks5h://127.0.0.1:9050',
    'https': 'socks5h://127.0.0.1:9050'
}

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

def format_size(size):
    try:
        size = int(size)
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size < 1024: return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} PB"
    except: return str(size)

# === 新增：状态检查接口 ===
@app.route('/status')
def check_status():
    try:
        # 尝试通过 Tor 访问一个极小的网站
        start = time.time()
        requests.get("https://checkip.amazonaws.com", proxies=PROXIES, timeout=5)
        latency = int((time.time() - start) * 1000)
        return jsonify({"status": "connected", "msg": f"🟢 Tor 网络已连接 (延迟 {latency}ms)"})
    except:
        return jsonify({"status": "connecting", "msg": "🟡 Tor 正在穿越防火墙，请稍候..."})

def search_solid(kw):
    url = "https://solidtorrents.to/api/v1/search"
    params = {"q": kw, "category": "all", "sort": "seeders"}
    try:
        resp = requests.get(url, params=params, headers=HEADERS, proxies=PROXIES, timeout=30)
        data = resp.json()
        results = []
        for i in data.get('hits', []):
            try:
                results.append({
                    'engine': 'Solid',
                    'name': i['title'],
                    'size': format_size(i['size']),
                    'date': i['imported'].split('T')[0],
                    'magnet': i['magnet'],
                    'seeders': i['swarm']['seeders'],
                    'leechers': i['swarm']['leechers']
                })
            except: continue
        return results
    except Exception as e:
        print(f"[Solid Error] {e}")
        return []

def search_bit(kw):
    # 暂时禁用 BitSearch HTML 解析，它太慢且容易被封，先专注 Solid
    # 如果 Solid 稳定了再加回来
    return []

@app.route('/', methods=['GET', 'POST'])
def index():
    results = []
    kw = ""
    error = None

    if request.method == 'POST':
        kw = request.form.get('keyword')
        if kw:
            # 单线程测试，确保稳定
            results = search_solid(kw)
            
            if not results:
                error = "未找到资源，或 Tor 连接超时。请看下方状态提示。"

    return render_template('index.html', results=results, keyword=kw, error=error)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
