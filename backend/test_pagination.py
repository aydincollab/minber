"""Test script to debug Diyanet SharePoint pagination."""
import requests
import re
import json
import time

BASE_URL = "https://dinhizmetleri.diyanet.gov.tr"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
}
LIST_ID = "24A21FB8-6393-49BA-80CB-8D5C8A61AF3A"
VIEW_ID = "3371EE93-ABFB-4357-8754-14A7F3175DA5"


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
        except Exception as e:
            continue
    return items


def parse_date_for_sp(tarih_str):
    """Convert '06.02.2026' to '20260206%2021%3a00%3a00'"""
    parts = tarih_str.split('.')
    return f"{parts[2]}{parts[1]}{parts[0]}%2021%3a00%3a00"


# Use a session for cookies
session = requests.Session()
session.headers.update(HEADERS)

# === PAGE 1 ===
url = f"{BASE_URL}/kategoriler/yayinlarimiz/hutbeler/t%C3%BCrk%C3%A7e"
print(f"=== PAGE 1 (GET) ===")
r = session.get(url, timeout=30)
print(f"Status: {r.status_code}, Body length: {len(r.text)}")

items = parse_json(r.text)
print(f"Items found: {len(items)}")
if items:
    print(f"  First: ID={items[0]['id']}, '{items[0]['title'][:50]}', {items[0]['tarih']}")
    print(f"  Last:  ID={items[-1]['id']}, '{items[-1]['title'][:50]}', {items[-1]['tarih']}")

all_items = list(items)

# === PAGINATE ===
page_num = 2
page_first_row = 31

for attempt in range(15):  # max 15 pages
    if not all_items:
        break
    
    last = all_items[-1]
    sp_date = parse_date_for_sp(last['tarih'])
    last_id = last['id']
    
    pag_url = (
        f"{BASE_URL}/_layouts/15/inplview.aspx"
        f"?List=%7B{LIST_ID}%7D"
        f"&View=%7B{VIEW_ID}%7D"
        f"&ViewCount=1&IsXslView=TRUE&IsCSR=TRUE"
        f"&ListViewPageUrl=https%3A%2F%2Fdinhizmetleri.diyanet.gov.tr%2Fkategoriler%2Fyayinlarimiz%2Fhutbeler%2Ft%25C3%25BCrk%25C3%25A7e"
        f"&Paged=TRUE&p_SortBehavior=0"
        f"&p_Tarih={sp_date}"
        f"&p_ID={last_id}"
        f"&PageFirstRow={page_first_row}"
    )
    
    print(f"\n=== PAGE {page_num} (Row {page_first_row}) ===")
    print(f"  p_Tarih={sp_date}, p_ID={last_id}")
    
    # Try POST (as the browser does)
    post_headers = {
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type': 'application/x-www-form-urlencoded',
    }
    
    page_items = []
    
    # Method 1: POST with session
    try:
        r2 = session.post(pag_url, headers=post_headers, timeout=30)
        print(f"  POST: status={r2.status_code}, length={len(r2.text)}")
        page_items = parse_json(r2.text)
        print(f"  POST parsed: {len(page_items)} items")
        if page_items:
            print(f"    First: ID={page_items[0]['id']}, '{page_items[0]['title'][:50]}', {page_items[0]['tarih']}")
            print(f"    Last:  ID={page_items[-1]['id']}, '{page_items[-1]['title'][:50]}', {page_items[-1]['tarih']}")
    except Exception as e:
        print(f"  POST error: {e}")
    
    # Method 2: GET with session (if POST returned nothing)
    if not page_items:
        try:
            r3 = session.get(pag_url, timeout=30)
            print(f"  GET: status={r3.status_code}, length={len(r3.text)}")
            page_items = parse_json(r3.text)
            print(f"  GET parsed: {len(page_items)} items")
            if page_items:
                print(f"    First: ID={page_items[0]['id']}, '{page_items[0]['title'][:50]}', {page_items[0]['tarih']}")
                print(f"    Last:  ID={page_items[-1]['id']}, '{page_items[-1]['title'][:50]}', {page_items[-1]['tarih']}")
        except Exception as e:
            print(f"  GET error: {e}")
    
    if not page_items:
        print(f"  NO ITEMS - stopping pagination")
        break
    
    all_items.extend(page_items)
    page_num += 1
    page_first_row += 30
    time.sleep(1)

# === SUMMARY ===
print(f"\n{'='*60}")
print(f"TOTAL ITEMS: {len(all_items)}")
years = {}
for item in all_items:
    year = item['tarih'].split('.')[-1]
    years[year] = years.get(year, 0) + 1
print(f"YEAR DISTRIBUTION: {dict(sorted(years.items()))}")
