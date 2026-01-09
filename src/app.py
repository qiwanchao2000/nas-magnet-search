from flask import Flask, render_template, request
import requests
import cloudscraper
import concurrent.futures
import os

app = Flask(__name__)

# === 读取环境变量中的代理 ===
# Docker Compose 会把 'warp' 容器的地址传进来
# 格式通常是: socks5h://warp:9091
PROXY_URL = os.getenv('ALL_PROXY') 

PROXIES = {
    'http': PROXY_URL,
    'https': PROXY_URL
} if PROXY_URL else None

# 浏览器伪装
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

# === 引擎 1: SolidTorrents ===
def search_solid(kw):
    url = "https://solidtorrents.to/api/v1/search"
    params = {"q": kw, "category": "all", "sort": "seeders"}
    try:
        print(f"Searching Solid via {PROXIES}...")
        resp = requests.get(url, params=params, headers=HEADERS, proxies=PROXIES, timeout=15)
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

# === 引擎 2: BitSearch (Cloudscraper) ===
def search_bit(kw):
    url = f"https://bitsearch.to/search?q={kw}"
    # 创建 scraper 实例，让它也走代理
    scraper = cloudscraper.create_scraper(browser={'browser': 'chrome', 'platform': 'windows', 'desktop': True})
    try:
        print(f"Searching BitSearch via {PROXIES}...")
        # Cloudscraper 传代理的方式略有不同，通常它会自动处理 requests 的 proxies 参数
        resp = scraper.get(url, proxies=PROXIES, timeout=15)
        if resp.status_code != 200: return []
        
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(resp.text, 'html.parser')
        results = []
        for item in soup.select('li.search-result'):
            try:
                name = item.select_one('.info h5 a').get_text(strip=True)
                magnet = item.select_one('.links a.dl-magnet')['href']
                stats = item.select('.stats div')
                if len(stats) >= 5:
                    results.append({
                        'engine': 'Bit',
                        'name': name,
                        'size': stats[1].get_text(strip=True),
                        'date': stats[4].get_text(strip=True),
                        'magnet': magnet,
                        'seeders': stats[2].get_text(strip=True),
                        'leechers': stats[3].get_text(strip=True)
                    })
            except: continue
        return results
    except Exception as e:
        print(f"[Bit Error] {e}")
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
                f2 = executor.submit(search_bit, kw)
                results = f1.result() + f2.result()
            
            if not results:
                error = "未找到资源 (请检查 WARP 容器是否启动成功)"

    return render_template('index.html', results=results, keyword=kw, error=error)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
