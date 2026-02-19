"""Try sitemap, robots.txt, and Google-based approaches to find all hutbe URLs."""
import requests
import re
import json
import time
from xml.etree import ElementTree as ET

BASE_URL = "https://dinhizmetleri.diyanet.gov.tr"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
}

session = requests.Session()
session.headers.update(HEADERS)

# === Check robots.txt ===
print("=== robots.txt ===")
try:
    r = session.get(f"{BASE_URL}/robots.txt", timeout=10)
    print(f"Status: {r.status_code}")
    if r.status_code == 200:
        print(r.text[:1000])
except Exception as e:
    print(f"Error: {e}")

# === Check sitemap.xml ===
print("\n=== sitemap.xml ===")
sitemap_urls = [
    f"{BASE_URL}/sitemap.xml",
    f"{BASE_URL}/Sitemap.xml",
    f"{BASE_URL}/siteindex.xml",
]
for su in sitemap_urls:
    try:
        r = session.get(su, timeout=10)
        print(f"{su}: status={r.status_code}, length={len(r.text)}")
        if r.status_code == 200 and len(r.text) > 100:
            print(f"  Content: {r.text[:500]}")
    except Exception as e:
        print(f"{su}: Error {e}")

# === Check if there's a direct Documents listing ===
print("\n=== Documents folder listing ===")
try:
    r = session.get(f"{BASE_URL}/Documents", timeout=10)
    print(f"Status: {r.status_code}, Length: {len(r.text)}")
    # Count PDF links
    pdf_links = re.findall(r'href="([^"]*\.pdf)"', r.text, re.IGNORECASE)
    print(f"PDF links found: {len(pdf_links)}")
    if pdf_links:
        for link in pdf_links[:5]:
            print(f"  {link}")
except Exception as e:
    print(f"Error: {e}")

# === Check if there are archive/category pages by year ===
print("\n=== Category/Archive pages ===")
archive_urls = [
    f"{BASE_URL}/kategoriler/yayinlarimiz/hutbeler",
    f"{BASE_URL}/kategoriler/yayinlarimiz/hutbeler/turkce",
    f"{BASE_URL}/kategoriler/yayinlarimiz/hutbeler/2024",
    f"{BASE_URL}/kategoriler/yayinlarimiz/hutbeler/arsiv",
    f"{BASE_URL}/SitePages/hutbe-arsiv.aspx",
]
for au in archive_urls:
    try:
        r = session.get(au, timeout=10)
        # Count JSON hutbe items
        count = len(re.findall(r'"Title"\s*:', r.text))
        print(f"  {au.replace(BASE_URL, '')}: status={r.status_code}, Title-count={count}")
    except Exception as e:
        print(f"  {au}: Error {e}")

# === Check page 1: how many items? Also look for "next page" links ===
print("\n=== Page 1 analysis ===")
r = session.get(
    f"{BASE_URL}/kategoriler/yayinlarimiz/hutbeler/t%C3%BCrk%C3%A7e",
    timeout=30
)
print(f"Page 1: {r.status_code}, {len(r.text)} bytes")

# Look for pagination info in HTML
paging_info = re.findall(r'Paged[^"]*', r.text)
if paging_info:
    print(f"Paging references found: {len(paging_info)}")
    for p in paging_info[:3]:
        print(f"  {p[:150]}")

# Look for "next page" pattern
next_patterns = re.findall(r'"PageFirstRow=\d+"', r.text)
if next_patterns:
    print(f"PageFirstRow references: {next_patterns}")

# Look for total item count
total_pattern = re.search(r'TotalListItems\s*[=:]\s*"?(\d+)"?', r.text)
if total_pattern:
    print(f"TotalListItems: {total_pattern.group(1)}")

# Check the Paging fields in the response
paging_section = re.search(r'"NextHref"\s*:\s*"([^"]*)"', r.text)
if paging_section:
    print(f"NextHref: {paging_section.group(1)[:200]}")

# Check for all View-related data
view_data = re.search(r'"Row"\s*:', r.text)
if view_data:
    print("Found 'Row' key in response - this might be RenderListDataAsStream format")
    
# Find any pagination link in HTML
paged_links = re.findall(r'(Paged=TRUE[^"\']*)', r.text)
if paged_links:
    print(f"\nPaged links found:")
    for pl in paged_links[:5]:
        print(f"  {pl[:200]}")
