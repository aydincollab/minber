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
    
    # SharePoint pagination constants
    ITEMS_PER_PAGE = 30  # SharePoint returns 30 items per page
    SHAREPOINT_TIME_SUFFIX = '%2021%3a00%3a00'  # Time component for pagination (21:00:00 URL encoded)
    
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
        Uses both GET and POST methods with retry for robustness.
        """
        hutbeler = []
        
        try:
            # SharePoint List & View IDs
            LIST_ID = "24A21FB8-6393-49BA-80CB-8D5C8A61AF3A"
            VIEW_ID = "3371EE93-ABFB-4357-8754-14A7F3175DA5"
            
            # Step A: Fetch page 1 with GET
            url = f"{DiyanetScraper.BASE_URL}/kategoriler/yayinlarimiz/hutbeler/türkçe"
            
            logger.info(f"Fetching hutbe list page 1 from: {url}")
            response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=30)
            response.raise_for_status()
            
            # Step B: Parse JSON blocks from page 1
            page1_items = DiyanetScraper._parse_sharepoint_json(response.text)
            hutbeler.extend(page1_items)
            
            logger.info(f"Page 1: Found {len(page1_items)} hutbeler")
            
            # Step C: Paginate using both GET and POST with retry
            if hutbeler:
                page_first_row = DiyanetScraper.ITEMS_PER_PAGE + 1  # Row 31 for page 2
                max_pages = 30  # Safety limit
                consecutive_failures = 0
                
                while page_first_row < max_pages * DiyanetScraper.ITEMS_PER_PAGE + 1:
                    if not hutbeler:
                        break
                    
                    last_hutbe = hutbeler[-1]
                    last_date = last_hutbe['date']
                    last_id = last_hutbe.get('sharepoint_id', '')
                    
                    sp_date = last_date.strftime('%Y%m%d') + DiyanetScraper.SHAREPOINT_TIME_SUFFIX
                    
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
                    
                    page_items = None
                    
                    # Try GET first (more reliable on some servers)
                    for method in ['GET', 'POST']:
                        try:
                            if method == 'GET':
                                page_response = requests.get(
                                    pagination_url,
                                    headers=DiyanetScraper.HEADERS,
                                    timeout=30,
                                )
                            else:
                                page_response = requests.post(
                                    pagination_url,
                                    headers={
                                        **DiyanetScraper.HEADERS,
                                        'X-Requested-With': 'XMLHttpRequest',
                                        'Content-Type': 'application/x-www-form-urlencoded',
                                    },
                                    timeout=30,
                                )
                            
                            if page_response.status_code == 200:
                                page_items = DiyanetScraper._parse_sharepoint_json(page_response.text)
                                if page_items:
                                    logger.info(f"Row {page_first_row}: {method} returned {len(page_items)} items")
                                    break
                                else:
                                    logger.debug(f"Row {page_first_row}: {method} returned 200 but 0 items parsed")
                            else:
                                logger.debug(f"Row {page_first_row}: {method} returned status {page_response.status_code}")
                        except Exception as e:
                            logger.debug(f"Row {page_first_row}: {method} failed: {e}")
                            continue
                    
                    if not page_items:
                        consecutive_failures += 1
                        logger.warning(f"Row {page_first_row}: No items from GET or POST (failure #{consecutive_failures})")
                        if consecutive_failures >= 3:
                            logger.info(f"Stopping pagination after {consecutive_failures} consecutive failures")
                            break
                        # Try skipping ahead
                        page_first_row += DiyanetScraper.ITEMS_PER_PAGE
                        time.sleep(2)
                        continue
                    
                    consecutive_failures = 0
                    hutbeler.extend(page_items)
                    page_num = page_first_row // DiyanetScraper.ITEMS_PER_PAGE + 1
                    logger.info(f"Page {page_num}: +{len(page_items)} hutbeler (total: {len(hutbeler)})")
                    
                    page_first_row += DiyanetScraper.ITEMS_PER_PAGE
                    time.sleep(1)
            
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
            except Exception as e:
                logger.debug(f"Error parsing SharePoint JSON block: {e}")
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
    
    # Arabic Unicode ranges for filtering
    ARABIC_PATTERN = re.compile(r'[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDCF\uFDF0-\uFDFF]')

    @staticmethod
    def _is_arabic_line(line: str) -> bool:
        """Check if a line contains predominantly Arabic characters."""
        if not line.strip():
            return False
        arabic_chars = len(DiyanetScraper.ARABIC_PATTERN.findall(line))
        total_alpha = sum(1 for c in line if c.isalpha())
        if total_alpha == 0:
            return False
        # If more than 30% of alphabetic characters are Arabic, skip the line
        return (arabic_chars / total_alpha) > 0.3

    @staticmethod
    def _filter_turkish_content(raw_text: str) -> str:
        """Filter out Arabic lines and clean up Turkish content, preserving paragraph breaks."""
        lines = raw_text.split('\n')
        paragraphs = []
        current_para = []

        for line in lines:
            stripped = line.strip()

            if not stripped:
                # Blank line = paragraph boundary
                if current_para:
                    paragraphs.append(' '.join(current_para))
                    current_para = []
                continue

            # Skip lines that are predominantly Arabic
            if DiyanetScraper._is_arabic_line(stripped):
                # When we skip an Arabic line that was mid-paragraph,
                # treat it as a paragraph break so text doesn't merge
                if current_para:
                    paragraphs.append(' '.join(current_para))
                    current_para = []
                continue

            # Remove any remaining inline Arabic characters
            cleaned = DiyanetScraper.ARABIC_PATTERN.sub('', stripped)
            cleaned = re.sub(r'\s{2,}', ' ', cleaned).strip()
            if cleaned and len(cleaned) > 2:
                current_para.append(cleaned)

        # Flush remaining
        if current_para:
            paragraphs.append(' '.join(current_para))

        # Join paragraphs with double newline (clear visual separation)
        content = '\n\n'.join(p for p in paragraphs if p.strip())
        return content.strip()

    @staticmethod
    def _extract_text_from_pdf(pdf_bytes: bytes, source_url: str) -> Optional[Dict]:
        """
        Extract text from Diyanet PDF files.
        Diyanet hutbe PDFs use a 2-column layout — we extract left column then
        right column for each page to avoid text from both columns interleaving.
        """
        try:
            import io

            raw_content = None

            # Primary: pdfplumber with 2-column aware extraction
            try:
                import pdfplumber
                text_parts = []
                with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
                    for page in pdf.pages:
                        width = page.width
                        height = page.height

                        # Split page vertically at the midpoint
                        left_bbox  = (0,      0, width / 2, height)
                        right_bbox = (width / 2, 0, width,    height)

                        left_text  = page.crop(left_bbox).extract_text()  or ""
                        right_text = page.crop(right_bbox).extract_text() or ""

                        # Check if the page actually has 2 columns by comparing
                        # content density; if right side is nearly empty, treat as 1-column
                        if len(right_text.strip()) < 30:
                            # Single-column page
                            page_text = page.extract_text() or ""
                        else:
                            page_text = left_text + "\n\n" + right_text

                        if page_text.strip():
                            text_parts.append(page_text)

                raw_content = "\n\n".join(text_parts)

            except ImportError:
                # Fallback to PyPDF2 (no column support, but better than nothing)
                try:
                    from PyPDF2 import PdfReader
                    reader = PdfReader(io.BytesIO(pdf_bytes))
                    text_parts = []
                    for page in reader.pages:
                        page_text = page.extract_text()
                        if page_text:
                            text_parts.append(page_text)
                    raw_content = "\n\n".join(text_parts)
                except ImportError:
                    logger.error("No PDF library available. Install pdfplumber or PyPDF2.")
                    return None

            if not raw_content or len(raw_content) < 50:
                logger.warning(f"PDF had no extractable text: {source_url}")
                return None

            # Remove footnote markers: patterns like "1 Müslim, 288." or "2 Tevbe, 9/18."
            # These appear at the bottom of pages and get mixed into the text by some PDF extractors
            raw_content = re.sub(
                r'\b\d+\s+[A-ZÇĞİÖŞÜa-zçğışöüı][a-zçğışöüı]+,?\s*[\d/]+\.?',
                '',
                raw_content
            )

            # Filter out Arabic text, keep only Turkish, preserve paragraph breaks
            content = DiyanetScraper._filter_turkish_content(raw_content)

            if not content or len(content) < 30:
                logger.warning(f"PDF had no Turkish text after filtering: {source_url}")
                return None

            summary = content[:200] + "..." if len(content) > 200 else content
            category = DiyanetScraper._determine_category(content)
            reading_time = HutbeService.calculate_reading_time(content)

            return {
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
    async def scrape_and_save_hutbeler(db, year: Optional[int] = None, limit: int = 500):
        """
        Phase 1: Scrape hutbe METADATA and save to database (fast, no PDF downloads).
        Uses upsert to prevent duplicates. Typically finishes in <30 seconds.
        
        Args:
            db: Database session
            year: Year to scrape (None for current)
            limit: Maximum number of hutbeler to scrape
        """
        from app.schemas.hutbe import HutbeCreate
        
        logger.info(f"Starting scraper (metadata only) for year {year or 'all'}...")
        
        # Get list of hutbeler (pagination takes ~20 seconds for all pages)
        hutbe_list = DiyanetScraper.scrape_hutbe_list(year)
        
        if not hutbe_list:
            logger.warning("No hutbeler found in scrape_hutbe_list")
            return 0
        
        logger.info(f"Found {len(hutbe_list)} hutbeler, saving metadata...")
        
        saved_count = 0
        new_count = 0
        updated_count = 0
        
        for i, hutbe_item in enumerate(hutbe_list[:limit]):
            try:
                json_title = hutbe_item.get('title', '')
                
                # Build hutbe data from JSON metadata ONLY (no PDF download)
                hutbe_data = {
                    'title': json_title,
                    'date': hutbe_item['date'],
                    'source_url': hutbe_item.get('pdf_url') or hutbe_item.get('url', ''),
                    'content': f"{json_title}\n\nHutbe içeriği yükleniyor...",
                    'summary': json_title,
                    'category': DiyanetScraper._determine_category(json_title),
                    'reading_time_minutes': 5,
                }
                
                # Ensure date is date object
                if isinstance(hutbe_data['date'], str):
                    hutbe_data['date'] = DiyanetScraper._parse_date(hutbe_data['date'])
                
                hutbe_data['year'] = hutbe_data['date'].year
                
                # Create hutbe schema
                hutbe_create = HutbeCreate(**hutbe_data)
                
                # UPSERT — prevents duplicates
                hutbe, is_new = await HutbeService.upsert_hutbe(db, hutbe_create)
                saved_count += 1
                if is_new:
                    new_count += 1
                else:
                    updated_count += 1
                
            except Exception as e:
                logger.error(f"Error saving hutbe '{hutbe_item.get('title', '?')[:40]}': {e}")
                continue
        
        # Set the most recent hutbe as featured
        await HutbeService.set_featured_hutbe(db)
        
        # Commit the changes
        await db.commit()
        
        logger.info(f"Metadata save completed. Total: {saved_count}, New: {new_count}, Updated: {updated_count}")
        return saved_count

    @staticmethod
    async def enrich_hutbe_content(db, batch_size: int = 20):
        """
        Phase 2: Download PDFs and enrich hutbe content for items that only have placeholder text.
        Processes in batches to avoid Railway timeout (5 min).
        Call multiple times until all hutbes are enriched.
        
        Returns: (enriched_count, remaining_count)
        """
        from sqlalchemy import select
        from app.models.hutbe import Hutbe
        
        # Find hutbes with placeholder content (not yet enriched)
        result = await db.execute(
            select(Hutbe)
            .where(Hutbe.content.like('%Hutbe içeriği yükleniyor%'))
            .order_by(Hutbe.date.desc())
            .limit(batch_size)
        )
        hutbes_to_enrich = list(result.scalars().all())
        
        if not hutbes_to_enrich:
            logger.info("All hutbes already enriched with content")
            return 0, 0
        
        # Count remaining (for progress reporting)
        from sqlalchemy import func as sa_func
        count_result = await db.execute(
            select(sa_func.count(Hutbe.id))
            .where(Hutbe.content.like('%Hutbe içeriği yükleniyor%'))
        )
        total_remaining = count_result.scalar()
        
        enriched = 0
        for hutbe in hutbes_to_enrich:
            try:
                if not hutbe.source_url:
                    continue
                
                detail = DiyanetScraper.scrape_hutbe_detail(hutbe.source_url)
                
                if detail and detail.get('content'):
                    hutbe.content = detail['content']
                    hutbe.summary = detail.get('summary', hutbe.content[:200])
                    hutbe.category = detail.get('category', hutbe.category)
                    hutbe.reading_time_minutes = detail.get('reading_time_minutes', 5)
                    enriched += 1
                    logger.info(f"Enriched: {hutbe.title[:50]}")
                else:
                    # Mark as "no content available" so we don't retry forever
                    hutbe.content = f"{hutbe.title}\n\nBu hutbenin içeriğine şu anda ulaşılamıyor."
                    logger.warning(f"No content extractable for: {hutbe.title[:50]}")
                
                # Rate limiting between PDF downloads
                time.sleep(1)
                
            except Exception as e:
                logger.error(f"Error enriching hutbe '{hutbe.title[:40]}': {e}")
                continue
        
        await db.commit()
        
        remaining = total_remaining - len(hutbes_to_enrich)
        logger.info(f"Enrichment batch done. Enriched: {enriched}, Remaining: {remaining}")
        return enriched, max(0, remaining)

    @staticmethod
    async def import_seed_data(db, items: list) -> dict:
        """
        Import hutbe metadata from browser-extracted JSON seed data.
        Each item should have: {title, date (DD.MM.YYYY), pdf, id}
        Uses upsert to prevent duplicates.
        
        This solves the Diyanet WAF blocking all automated pagination.
        The user extracts data via F12 console JS script, then submits here.
        """
        from app.schemas.hutbe import HutbeCreate
        
        logger.info(f"Importing {len(items)} hutbe seed items...")
        
        new_count = 0
        updated_count = 0
        error_count = 0
        
        for item in items:
            try:
                title = item.get('title', '').strip()
                date_str = item.get('date', '')
                pdf_path = item.get('pdf', '')
                
                if not title or not date_str:
                    error_count += 1
                    continue
                
                # Parse date (DD.MM.YYYY format from Diyanet)
                hutbe_date = DiyanetScraper._parse_date(date_str)
                
                # Build full PDF URL
                pdf_url = f"{DiyanetScraper.BASE_URL}{pdf_path}" if pdf_path and not pdf_path.startswith('http') else pdf_path
                
                hutbe_data = {
                    'title': title,
                    'date': hutbe_date,
                    'year': hutbe_date.year,
                    'source_url': pdf_url or '',
                    'content': f"{title}\n\nHutbe içeriği yükleniyor...",
                    'summary': title,
                    'category': DiyanetScraper._determine_category(title),
                    'reading_time_minutes': 5,
                }
                
                hutbe_create = HutbeCreate(**hutbe_data)
                hutbe, is_new = await HutbeService.upsert_hutbe(db, hutbe_create)
                
                if is_new:
                    new_count += 1
                else:
                    updated_count += 1
                    
            except Exception as e:
                logger.error(f"Error importing '{item.get('title', '?')[:40]}': {e}")
                error_count += 1
                continue
        
        # Set the most recent hutbe as featured
        await HutbeService.set_featured_hutbe(db)
        await db.commit()
        
        total = new_count + updated_count
        logger.info(f"Seed import done. New: {new_count}, Updated: {updated_count}, Errors: {error_count}")
        
        return {
            "total_processed": total,
            "new": new_count,
            "updated": updated_count,
            "errors": error_count,
        }

