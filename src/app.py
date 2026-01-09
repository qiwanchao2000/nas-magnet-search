from flask import Flask, render_template, request
import requests
import concurrent.futures

app = Flask(__name__)

# === 核心配置：走 Tor 代理 ===
# socks5h 表示让 Tor 帮我们解析域名（防止 DNS 污染）
PROXIES = {
    'http': 'socks5h://127.0.0.1:9050',
    'https': 'socks5h://127.0.0.1:9050'
}

# 伪装浏览器头
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

# === 引擎 1: SolidTorrents (通过 Tor 访问) ===
def search_solid(kw):
    url = "https://solidtorrents.to/api/v1/search"
    params = {"q": kw, "category": "all", "sort": "seeders"}
    try:
        # 必须带上 proxies=PROXIES
        resp = requests.get(url, params=params, headers=HEADERS, proxies=PROXIES, timeout=40)
        data = resp.json()
        results = []
        for i in data.get('hits', []):
            results.append({
                'engine': 'Solid',
                'name': i['title'],
                'size': format_size(i['size']),
                'date': i['imported'].split('T')[0],
                'magnet': i['magnet'],
                'seeders': i['swarm']['seeders'],
                'leechers': i['swarm']['leechers']
            })
        return results
    except Exception as e:
        print(f"[Solid Error] {e}")
        return []

# === 引擎 2: APIBay (通过 Tor 访问) ===
def search_apibay(kw):
    url = "https://apibay.org/q.php"
    params = {'q': kw, 'cat': ''}
    try:
        resp = requests.get(url, params=params, headers=HEADERS, proxies=PROXIES, timeout=40)
        data = resp.json()
        results = []
        if data and data[0].get('id') == '0': return []
        
        for i in data[:20]:
            magnet = f"magnet:?xt=urn:btih:{i['info_hash']}&dn={i['name']}"
            results.append({
                'engine': 'TPB',
                'name': i['name'],
                'size': format_size(int(i['size'])),
                'date': 'Unknown',
                'magnet': magnet,
                'seeders': int(i['seeders']),
                'leechers': int(i['leechers'])
            })
        return results
    except Exception as e:
        print(f"[TPB Error] {e}")
        return []

@app.route('/', methods=['GET', 'POST'])
def index():
    results = []
    kw = ""
    error = None

    if request.method == 'POST':
        kw = request.form.get('keyword')
        if kw:
            # 并行搜索
            with concurrent.futures.ThreadPoolExecutor() as executor:
                f1 = executor.submit(search_solid, kw)
                f2 = executor.submit(search_apibay, kw)
                results = f1.result() + f2.result()
            
            if not results:
                error = "未找到资源 (Tor网络较慢，请尝试刷新重试)"

    return render_template('index.html', results=results, keyword=kw, error=error)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
