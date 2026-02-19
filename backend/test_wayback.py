"""Use Wayback Machine CDX API to find ALL hutbe PDF URLs from archive."""
import requests
import re
import json
import time

# Wayback Machine CDX API - finds all archived URLs matching a pattern
CDX_API = "https://web.archive.org/cdx/search/cdx"

print("=== Wayback Machine: Find all hutbe PDFs ===")
print("Searching for all PDFs on dinhizmetleri.diyanet.gov.tr/Documents/...")

try:
    r = requests.get(CDX_API, params={
        'url': 'dinhizmetleri.diyanet.gov.tr/Documents/*.pdf',
        'output': 'json',
        'limit': '500',
        'fl': 'original,timestamp',
        'collapse': 'urlkey',  # Deduplicate by URL
    }, timeout=60)
    
    print(f"Status: {r.status_code}, Length: {len(r.text)}")
    
    if r.status_code == 200:
        data = r.json()
        print(f"Total unique PDF URLs found: {len(data) - 1}")  # -1 for header row
        
        if len(data) > 1:
            # First row is header
            urls = [row[0] for row in data[1:]]
            print(f"\nFirst 10 PDFs:")
            for u in urls[:10]:
                print(f"  {u}")
            print(f"\nLast 10 PDFs:")
            for u in urls[-10:]:
                print(f"  {u}")
    else:
        print(f"Response: {r.text[:500]}")
        
except Exception as e:
    print(f"Error: {e}")


# Also check for the main hutbe page snapshots
print(f"\n\n=== Wayback Machine: Hutbe list page snapshots ===")
try:
    r2 = requests.get(CDX_API, params={
        'url': 'dinhizmetleri.diyanet.gov.tr/kategoriler/yayinlarimiz/hutbeler/türkçe',
        'output': 'json',
        'limit': '20',
        'fl': 'original,timestamp,statuscode',
    }, timeout=60)
    
    if r2.status_code == 200:
        data2 = r2.json()
        print(f"Snapshots found: {len(data2) - 1}")
        if len(data2) > 1:
            for row in data2[1:5]:
                print(f"  {row}")
except Exception as e:
    print(f"Error: {e}")


# Try the Diyanet main site for hutbe content pages (not PDF)
print(f"\n\n=== Wayback Machine: Hutbe detail pages ===")
try:
    r3 = requests.get(CDX_API, params={
        'url': 'dinhizmetleri.diyanet.gov.tr/kategoriler/yayinlarimiz/hutbeler/*',
        'output': 'json',
        'limit': '50',
        'fl': 'original,timestamp',
        'collapse': 'urlkey',
    }, timeout=60)
    
    if r3.status_code == 200:
        data3 = r3.json()
        print(f"Unique hutbe URLs: {len(data3) - 1}")
        if len(data3) > 1:
            for row in data3[1:20]:
                print(f"  {row[0][:100]}")
except Exception as e:
    print(f"Error: {e}")
