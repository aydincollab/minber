"""Debug script - see what the 489-byte pagination response actually contains."""
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

session = requests.Session()
session.headers.update(HEADERS)

# Page 1 - get cookies
url = f"{BASE_URL}/kategoriler/yayinlarimiz/hutbeler/t%C3%BCrk%C3%A7e"
r = session.get(url, timeout=30)
print(f"Page 1: status={r.status_code}, length={len(r.text)}")
print(f"Cookies after page 1: {dict(session.cookies)}")

# Extract request digest / form digest from page 1 (SharePoint needs this)
digest_match = re.search(r'id="__REQUESTDIGEST"[^>]*value="([^"]*)"', r.text)
if digest_match:
    digest = digest_match.group(1)
    print(f"\nRequest Digest found: {digest[:50]}...")
else:
    print("\nNo Request Digest found in page!")
    # Try another pattern
    digest_match2 = re.search(r'"formDigestValue"\s*:\s*"([^"]*)"', r.text)
    if digest_match2:
        digest = digest_match2.group(1)
        print(f"Form Digest Value found: {digest[:50]}...")
    else:
        digest = None
        print("No form digest at all!")

# Try page 2 
pag_url = (
    f"{BASE_URL}/_layouts/15/inplview.aspx"
    f"?List=%7B{LIST_ID}%7D"
    f"&View=%7B{VIEW_ID}%7D"
    f"&ViewCount=1&IsXslView=TRUE&IsCSR=TRUE"
    f"&ListViewPageUrl=https%3A%2F%2Fdinhizmetleri.diyanet.gov.tr%2Fkategoriler%2Fyayinlarimiz%2Fhutbeler%2Ft%25C3%25BCrk%25C3%25A7e"
    f"&Paged=TRUE&p_SortBehavior=0"
    f"&p_Tarih=20250801%2021%3a00%3a00"
    f"&p_ID=275"
    f"&PageFirstRow=31"
)

# Strategy 1: POST with session (no digest)
print("\n=== Strategy 1: POST session, no digest ===")
r2 = session.post(pag_url, headers={
    'X-Requested-With': 'XMLHttpRequest',
    'Content-Type': 'application/x-www-form-urlencoded',
}, timeout=30)
print(f"Status: {r2.status_code}, Length: {len(r2.text)}")
print(f"Response body (first 500 chars):\n{r2.text[:500]}")

# Strategy 2: POST with X-RequestDigest header
if digest:
    print("\n=== Strategy 2: POST with X-RequestDigest ===")
    r3 = session.post(pag_url, headers={
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-RequestDigest': digest,
    }, timeout=30)
    print(f"Status: {r3.status_code}, Length: {len(r3.text)}")
    print(f"Response body (first 500 chars):\n{r3.text[:500]}")

# Strategy 3: POST with form data __REQUESTDIGEST
if digest:
    print("\n=== Strategy 3: POST with form body digest ===")
    r4 = session.post(pag_url, headers={
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type': 'application/x-www-form-urlencoded',
    }, data={'__REQUESTDIGEST': digest}, timeout=30)
    print(f"Status: {r4.status_code}, Length: {len(r4.text)}")
    print(f"Response body (first 500 chars):\n{r4.text[:500]}")

# Strategy 4: POST with Referer header
print("\n=== Strategy 4: POST with Referer ===")
r5 = session.post(pag_url, headers={
    'X-Requested-With': 'XMLHttpRequest',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Referer': f'{BASE_URL}/kategoriler/yayinlarimiz/hutbeler/t%C3%BCrk%C3%A7e',
}, timeout=30)
print(f"Status: {r5.status_code}, Length: {len(r5.text)}")
print(f"Response body (first 500 chars):\n{r5.text[:500]}")
