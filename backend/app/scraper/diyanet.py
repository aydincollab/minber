import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
from datetime import datetime
import re
import logging
import time
import json
from app.services.hutbe_service import HutbeService

logger = logging.getLogger(__name__)


class DiyanetScraper:
    """Scraper for Diyanet İşleri Başkanlığı hutbeler."""
    
    BASE_URL = "https://dinhizmetleri.diyanet.gov.tr"
    
    # PDF extraction constants
    MAX_TITLE_LENGTH = 100  # Maximum length for extracted title from PDF first line
    
    # Required headers for requests
    HEADERS = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
    }
    
    # Category keywords for automatic categorization
    CATEGORY_KEYWORDS = {
        "İman": ["iman", "inanç", "akide", "tevhid", "allah", "peygamber"],
        "Aile": ["aile", "evlilik", "anne", "baba", "çocuk", "eş"],
        "Ahlak": ["ahlak", "edep", "doğruluk", "emanet", "güven", "fazilet"],
        "İbadet": ["namaz", "oruç", "zekât", "hac", "dua", "ibadet"],
        "Toplum": ["toplum", "sosyal", "birlik", "kardeşlik", "komşu", "yardımlaşma"],
        "Oruç": ["ramazan", "oruç", "iftar", "sahur", "teravih"],
        "Hac": ["hac", "umre", "kâbe", "arafat", "kurban"],
    }
    
    @staticmethod
    def scrape_hutbe_list(year: Optional[int] = None) -> List[Dict]:
        """
        Scrape list of hutbeler from Diyanet website with full SharePoint pagination.
        Fetches ALL hutbeler from 2011-2026 using SharePoint API.
        """
        hutbeler = []
        
        try:
            # SharePoint List & View IDs
            LIST_ID = "24A21FB8-6393-49BA-80CB-8D5C8A61AF3A"
            VIEW_ID = "3371EE93-ABFB-4357-8754-14A7F3175DA5"
            
            # Step A: Fetch page 1 with GET
            url = f"{DiyanetScraper.BASE_URL}/kategoriler/yayinlarimiz/hutbeler/türkçe"
            
            logger.info(f"Fetching hutbe list page 1 from: {url}")
            response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=15)
            response.raise_for_status()
            
            # Step B: Parse JSON blocks from page 1
            page1_items = DiyanetScraper._parse_sharepoint_json(response.text)
            hutbeler.extend(page1_items)
            
            logger.info(f"Page 1: Found {len(page1_items)} hutbeler")
            
            # Step C: Paginate using POST requests
            if hutbeler:
                page_first_row = 31  # Start from row 31 for page 2
                max_pages = 30  # Safety limit (~900 hutbeler, 2011-2026)
                
                while page_first_row < max_pages * 30 + 1:
                    # Get last hutbe's date and ID for pagination
                    if not hutbeler:
                        break
                    
                    last_hutbe = hutbeler[-1]
                    last_date = last_hutbe['date']
                    last_id = last_hutbe.get('sharepoint_id', '')
                    
                    # Format date for SharePoint: yyyyMMdd HH:mm:ss (URL encoded)
                    sp_date = last_date.strftime('%Y%m%d') + '%2021%3a00%3a00'
                    
                    pagination_url = (
                        f"{DiyanetScraper.BASE_URL}/_layouts/15/inplview.aspx"
                        f"?List=%7B{LIST_ID}%7D"
                        f"&View=%7B{VIEW_ID}%7D"
                        f"&ViewCount=1&IsXslView=TRUE&IsCSR=TRUE"
                        f"&ListViewPageUrl=https%3A%2F%2Fdinhizmetleri.diyanet.gov.tr%2Fkategoriler%2Fyayinlarimiz%2Fhutbeler%2Ft%25C3%25BCrk%25C3%25A7e"
                        f"&Paged=TRUE&p_SortBehavior=0"
                        f"&p_Tarih={sp_date}"
                        f"&p_ID={last_id}"
                        f"&PageFirstRow={page_first_row}"
                    )
                    
                    try:
                        page_response = requests.post(
                            pagination_url,
                            headers={
                                **DiyanetScraper.HEADERS,
                                'X-Requested-With': 'XMLHttpRequest',
                                'Content-Type': 'application/x-www-form-urlencoded',
                            },
                            timeout=15,
                        )
                        
                        if page_response.status_code != 200:
                            logger.info(f"Pagination stopped at row {page_first_row}, status: {page_response.status_code}")
                            break
                        
                        # Parse hutbeler from this page
                        page_items = DiyanetScraper._parse_sharepoint_json(page_response.text)
                        
                        if not page_items:
                            logger.info(f"No more hutbeler found at row {page_first_row}, stopping pagination")
                            break
                        
                        hutbeler.extend(page_items)
                        logger.info(f"Page {page_first_row // 30 + 1}: Found {len(page_items)} hutbeler (total: {len(hutbeler)})")
                        
                        page_first_row += 30
                        
                        # Rate limiting
                        time.sleep(1)
                        
                    except Exception as e:
                        logger.error(f"Pagination error at row {page_first_row}: {e}")
                        break
            
            logger.info(f"Successfully scraped {len(hutbeler)} hutbeler total")
            
        except Exception as e:
            logger.error(f"Error scraping hutbe list: {e}")
        
        return hutbeler
    
    @staticmethod
    def _parse_sharepoint_json(page_text: str) -> List[Dict]:
        """Parse SharePoint embedded JSON data from page HTML/response."""
        items = []
        json_block_pattern = re.compile(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}')
        
        for block_match in json_block_pattern.finditer(page_text):
            block = block_match.group(0)
            if '"Tarih"' not in block or '"Title"' not in block:
                continue
            try:
                # Fix SharePoint unicode escapes before parsing
                fixed = block.replace('\\u002f', '/')
                item_data = json.loads(fixed)
                
                tarih = item_data.get('Tarih', '')
                title = item_data.get('Title', '')
                
                # Skip if no title or date doesn't match expected format
                if not title or not re.match(r'\d{2}\.\d{2}\.\d{4}', tarih):
                    continue
                
                pdf_path = item_data.get('PDF', '')
                word_path = item_data.get('Word', '')
                ses_path = item_data.get('Ses', '')
                
                hutbe_date = DiyanetScraper._parse_date(tarih)
                
                # Build full URLs
                pdf_url = f"{DiyanetScraper.BASE_URL}{pdf_path}" if pdf_path else None
                word_url = f"{DiyanetScraper.BASE_URL}{word_path}" if word_path else None
                ses_url = f"{DiyanetScraper.BASE_URL}{ses_path}" if ses_path else None
                
                items.append({
                    'title': title,
                    'date': hutbe_date,
                    'url': pdf_url,
                    'pdf_url': pdf_url,
                    'word_url': word_url,
                    'audio_url': ses_url,
                    'sharepoint_id': item_data.get('ID', ''),
                })
            except Exception:
                continue
        
        return items
    
    @staticmethod
    def _parse_card_item(item) -> Optional[Dict]:
        """Parse a card-based hutbe item."""
        try:
            title_elem = item.find("h5", class_="card-title") or item.find("h4") or item.find("h3")
            title = title_elem.get_text(strip=True) if title_elem else None
            
            # Look for date in various formats
            date_elem = item.find("span", class_="date") or item.find("small")
            date_str = date_elem.get_text(strip=True) if date_elem else None
            
            link_elem = item.find("a")
            link = link_elem.get('href') if link_elem else None
            
            if not title:
                return None
            
            # Parse date
            hutbe_date = DiyanetScraper._parse_date(date_str) if date_str else datetime.now().date()
            
            # Build full URL
            full_url = DiyanetScraper.BASE_URL + link if link and not link.startswith('http') else link
            
            return {
                'title': title,
                'date': hutbe_date,
                'url': full_url,
            }
        except Exception as e:
            logger.debug(f"Error in _parse_card_item: {e}")
            return None
    
    @staticmethod
    def _parse_table_row(row) -> Optional[Dict]:
        """Parse a table row hutbe item."""
        try:
            cells = row.find_all("td")
            if not cells:
                return None
            
            # Usually: date in first cell, title in second
            date_str = cells[0].get_text(strip=True) if len(cells) > 0 else None
            title = cells[1].get_text(strip=True) if len(cells) > 1 else None
            
            # Look for link in any cell
            link_elem = row.find("a")
            link = link_elem.get('href') if link_elem else None
            
            if not title:
                return None
            
            hutbe_date = DiyanetScraper._parse_date(date_str) if date_str else datetime.now().date()
            full_url = DiyanetScraper.BASE_URL + link if link and not link.startswith('http') else link
            
            return {
                'title': title,
                'date': hutbe_date,
                'url': full_url,
            }
        except Exception as e:
            logger.debug(f"Error in _parse_table_row: {e}")
            return None
    
    @staticmethod
    def _parse_link_item(link) -> Optional[Dict]:
        """Parse a generic link item."""
        try:
            title = link.get_text(strip=True)
            url = link.get('href')
            
            if not title or len(title) < 5:
                return None
            
            # Try to extract date from surrounding text
            parent_text = link.parent.get_text() if link.parent else ""
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{4})', parent_text)
            date_str = date_match.group(1) if date_match else None
            
            hutbe_date = DiyanetScraper._parse_date(date_str) if date_str else datetime.now().date()
            full_url = DiyanetScraper.BASE_URL + url if url and not url.startswith('http') else url
            
            return {
                'title': title,
                'date': hutbe_date,
                'url': full_url,
            }
        except Exception as e:
            logger.debug(f"Error in _parse_link_item: {e}")
            return None
    
    @staticmethod
    def _parse_list_item(item) -> Optional[Dict]:
        """Parse a list item hutbe."""
        try:
            text = item.get_text(strip=True)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{4})', text)
            date_str = date_match.group(1) if date_match else None
            
            link_elem = item.find("a")
            title = link_elem.get_text(strip=True) if link_elem else text
            url = link_elem.get('href') if link_elem else None
            
            if not title or len(title) < 5:
                return None
            
            hutbe_date = DiyanetScraper._parse_date(date_str) if date_str else datetime.now().date()
            full_url = DiyanetScraper.BASE_URL + url if url and not url.startswith('http') else url
            
            return {
                'title': title,
                'date': hutbe_date,
                'url': full_url,
            }
        except Exception as e:
            logger.debug(f"Error in _parse_list_item: {e}")
            return None
    
    @staticmethod
    def scrape_hutbe_detail(url: str) -> Optional[Dict]:
        """Scrape full hutbe content. Handles both HTML pages and PDF files."""
        if not url or url == DiyanetScraper.BASE_URL:
            return None
            
        try:
            logger.info(f"Fetching hutbe detail from: {url}")
            response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=30)
            response.raise_for_status()
            
            content_type = response.headers.get('content-type', '').lower()
            
            # If it's a PDF, extract text
            if 'pdf' in content_type or url.lower().endswith('.pdf'):
                return DiyanetScraper._extract_text_from_pdf(response.content, url)
            
            # Otherwise try HTML parsing (keep existing logic as fallback)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Try multiple title selectors
            title_elem = (
                soup.select_one("h1") or 
                soup.select_one("h2") or 
                soup.select_one(".icerik-baslik") or
                soup.select_one(".details-header") or
                soup.select_one(".post-title")
            )
            title = title_elem.get_text(strip=True) if title_elem else None
            
            # Try multiple content selectors
            content_elem = (
                soup.select_one(".post-text") or
                soup.select_one(".icerik") or
                soup.select_one(".hutbe-icerik") or
                soup.select_one(".details-content") or
                soup.select_one(".content") or
                soup.select_one("article") or
                soup.select_one("div.icerik-body") or
                soup.select_one("div.detail-body") or
                soup.find("div", {"class": re.compile(r".*content.*|.*icerik.*|.*post.*", re.I)})
            )
            
            content = content_elem.get_text(strip=True) if content_elem else None
            
            if not content or len(content) < 50:
                logger.warning(f"No valid content found for URL: {url}")
                return None
            
            # Generate summary (first 200 characters)
            summary = content[:200] + "..." if len(content) > 200 else content
            
            # Determine category
            category = DiyanetScraper._determine_category(title + " " + content if title else content)
            
            # Calculate reading time
            reading_time = HutbeService.calculate_reading_time(content)
            
            return {
                'title': title,
                'content': content,
                'summary': summary,
                'category': category,
                'reading_time_minutes': reading_time,
                'source_url': url,
            }
            
        except Exception as e:
            logger.error(f"Error scraping hutbe detail from {url}: {e}")
            return None
    
    @staticmethod
    def _parse_date(date_str: str) -> datetime.date:
        """Parse date string to date object."""
        try:
            # Try common date formats
            for fmt in ['%d.%m.%Y', '%d/%m/%Y', '%Y-%m-%d']:
                try:
                    return datetime.strptime(date_str, fmt).date()
                except ValueError:
                    continue
            
            # If no format works, return current date
            return datetime.now().date()
        except:
            return datetime.now().date()
    
    @staticmethod
    def _extract_text_from_pdf(pdf_bytes: bytes, source_url: str) -> Optional[Dict]:
        """Extract text content from a PDF file."""
        try:
            import io
            
            # Try pdfplumber first
            try:
                import pdfplumber
                with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
                    text_parts = []
                    for page in pdf.pages:
                        page_text = page.extract_text()
                        if page_text:
                            text_parts.append(page_text)
                    content = "\n\n".join(text_parts)
            except ImportError:
                # Fallback to PyPDF2
                try:
                    from PyPDF2 import PdfReader
                    reader = PdfReader(io.BytesIO(pdf_bytes))
                    text_parts = []
                    for page in reader.pages:
                        page_text = page.extract_text()
                        if page_text:
                            text_parts.append(page_text)
                    content = "\n\n".join(text_parts)
                except ImportError:
                    logger.error("No PDF library available. Install pdfplumber or PyPDF2.")
                    return None
            
            if not content or len(content) < 50:
                logger.warning(f"PDF had no extractable text: {source_url}")
                return None
            
            # Clean up the content
            content = re.sub(r'\n{3,}', '\n\n', content)  # Remove excessive newlines
            content = content.strip()
            
            # Try to extract title from first line
            lines = content.split('\n')
            title = lines[0].strip() if lines else None
            
            # If first line is too long to be a title, skip it
            if title and len(title) > DiyanetScraper.MAX_TITLE_LENGTH:
                title = None  # Too long to be a title
            
            summary = content[:200] + "..." if len(content) > 200 else content
            category = DiyanetScraper._determine_category(content)
            reading_time = HutbeService.calculate_reading_time(content)
            
            return {
                'title': title,
                'content': content,
                'summary': summary,
                'category': category,
                'reading_time_minutes': reading_time,
                'source_url': source_url,
            }
        except Exception as e:
            logger.error(f"Error extracting text from PDF: {e}")
            return None
    
    @staticmethod
    def _determine_category(text: str) -> str:
        """Determine hutbe category based on keywords."""
        text_lower = text.lower()
        
        category_scores = {}
        for category, keywords in DiyanetScraper.CATEGORY_KEYWORDS.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            if score > 0:
                category_scores[category] = score
        
        if category_scores:
            # Return category with highest score
            return max(category_scores, key=category_scores.get)
        
        return "Genel"
    
    @staticmethod
    async def scrape_and_save_hutbeler(db, year: Optional[int] = None, limit: int = 10):
        """
        Scrape hutbeler and save to database.
        
        Args:
            db: Database session
            year: Year to scrape (None for current)
            limit: Maximum number of hutbeler to scrape
        """
        from app.schemas.hutbe import HutbeCreate
        from datetime import date as date_type
        
        logger.info(f"Starting scraper for year {year or 'current'}...")
        
        # Get list of hutbeler
        hutbe_list = DiyanetScraper.scrape_hutbe_list(year)
        
        if not hutbe_list:
            logger.warning("No hutbeler found in scrape_hutbe_list")
            return 0
        
        saved_count = 0
        for i, hutbe_item in enumerate(hutbe_list[:limit]):
            try:
                # Rate limiting - wait 1 second between requests
                if i > 0:
                    time.sleep(1)
                
                # Try to get full content if URL is available
                if hutbe_item.get('pdf_url'):
                    detail = DiyanetScraper.scrape_hutbe_detail(hutbe_item['pdf_url'])
                elif hutbe_item.get('url'):
                    detail = DiyanetScraper.scrape_hutbe_detail(hutbe_item['url'])
                else:
                    detail = None
                
                if detail:
                    # Merge with list data
                    hutbe_data = {
                        **hutbe_item,
                        **detail,
                    }
                else:
                    # Use minimal data from list
                    hutbe_data = hutbe_item.copy()
                    if 'content' not in hutbe_data:
                        hutbe_data['content'] = f"{hutbe_data['title']}\n\nHutbe içeriği yakında eklenecektir."
                    if 'category' not in hutbe_data:
                        hutbe_data['category'] = DiyanetScraper._determine_category(hutbe_data['title'])
                
                # Ensure date is date object
                if isinstance(hutbe_data['date'], str):
                    hutbe_data['date'] = DiyanetScraper._parse_date(hutbe_data['date'])
                
                hutbe_data['year'] = hutbe_data['date'].year
                
                # Create hutbe schema
                hutbe_create = HutbeCreate(**hutbe_data)
                
                # Save to database
                await HutbeService.create_hutbe(db, hutbe_create)
                saved_count += 1
                
                logger.info(f"Saved hutbe: {hutbe_data['title'][:50]}...")
                
            except Exception as e:
                logger.error(f"Error saving hutbe: {e}")
                continue
        
        # Commit the changes
        await db.commit()
        
        logger.info(f"Scraping completed. Saved {saved_count} hutbeler.")
        return saved_count
