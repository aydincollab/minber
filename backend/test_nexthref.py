"""Test NextHref-based GET pagination on the main hutbe page URL."""
import requests
import re
import json
import time

BASE_URL = "https://dinhizmetleri.diyanet.gov.tr"
PAGE_URL = f"{BASE_URL}/kategoriler/yayinlarimiz/hutbeler/t%C3%BCrk%C3%A7e"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
}


def parse_json(text):
    """Parse SharePoint embedded JSON data."""
    items = []
    json_block_pattern = re.compile(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}')
    for block_match in json_block_pattern.finditer(text):
        block = block_match.group(0)
        if '"Tarih"' not in block or '"Title"' not in block:
            continue
        try:
            fixed = block.replace('\\u002f', '/')
            item_data = json.loads(fixed)
            tarih = item_data.get('Tarih', '')
            title = item_data.get('Title', '')
            if not title or not re.match(r'\d{2}\.\d{2}\.\d{4}', tarih):
                continue
            items.append({
                'title': title,
                'tarih': tarih,
                'id': item_data.get('ID', ''),
            })
        except Exception:
            continue
    return items


def find_next_href(text):
    """Find NextHref in the page response."""
    match = re.search(r'"NextHref"\s*:\s*"([^"]*)"', text)
    if match:
        href = match.group(1)
        # Unescape
        href = href.replace('\\u002f', '/').replace('\\u0026', '&')
        return href
    return None


session = requests.Session()
session.headers.update(HEADERS)

# === PAGE 1 ===
print(f"=== PAGE 1 (GET) ===")
r = session.get(PAGE_URL, timeout=30)
items = parse_json(r.text)
next_href = find_next_href(r.text)
print(f"Items: {len(items)}")
if items:
    print(f"  First: {items[0]['title'][:50]} ({items[0]['tarih']})")
    print(f"  Last: {items[-1]['title'][:50]} ({items[-1]['tarih']})")
print(f"NextHref: {next_href}")

all_items = list(items)
page_num = 2

# === PAGINATE ===
while next_href and page_num <= 15:
    # Append NextHref to the PAGE URL (not to inplview.aspx!)
    next_url = f"{PAGE_URL}{next_href}"
    print(f"\n=== PAGE {page_num} ===")
    print(f"  URL: {next_url[:120]}...")
    
    time.sleep(1)
    
    try:
        r = session.get(next_url, timeout=30)
        print(f"  Status: {r.status_code}, Length: {len(r.text)}")
        
        # Check for WAF block
        if len(r.text) < 600 and 'güvenlik' in r.text:
            print(f"  -> WAF BLOCKED!")
            break
        
        items = parse_json(r.text)
        print(f"  Items: {len(items)}")
        
        if not items:
            print(f"  -> No items, stopping")
            break
        
        if items:
            print(f"    First: {items[0]['title'][:50]} ({items[0]['tarih']})")
            print(f"    Last: {items[-1]['title'][:50]} ({items[-1]['tarih']})")
        
        all_items.extend(items)
        
        # Find next page link
        next_href = find_next_href(r.text)
        print(f"  NextHref: {next_href[:80] if next_href else 'None'}")
        
        page_num += 1
        
    except Exception as e:
        print(f"  ERROR: {e}")
        break

# === SUMMARY ===
print(f"\n{'='*60}")
print(f"TOTAL: {len(all_items)} items across {page_num-1} pages")
years = {}
for item in all_items:
    year = item['tarih'].split('.')[-1]
    years[year] = years.get(year, 0) + 1
print(f"YEARS: {dict(sorted(years.items()))}")
