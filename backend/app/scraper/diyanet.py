import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
from datetime import datetime
import re
import logging
import time
from app.services.hutbe_service import HutbeService

logger = logging.getLogger(__name__)


class DiyanetScraper:
    """Scraper for Diyanet İşleri Başkanlığı hutbeler."""
    
    BASE_URL = "https://dinhizmetleri.diyanet.gov.tr"
    
    # HTTP headers to mimic a real browser
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
    def scrape_hutbe_list(year: Optional[int] = None, page: int = 1) -> List[Dict]:
        """
        Scrape list of hutbeler from Diyanet website.
        
        Args:
            year: Year to scrape (None for current)
            page: Page number for pagination
            
        Returns:
            List of hutbe dictionaries with title, date, and url
        """
        hutbeler = []
        
        try:
            # Build URL based on year
            if year:
                url = f"{DiyanetScraper.BASE_URL}/HutbeArsivi/{year}"
            else:
                url = f"{DiyanetScraper.BASE_URL}/HutbeArsivi"
            
            # Add pagination
            if page > 1:
                url += f"?sayfa={page}"
            
            logger.info(f"Scraping hutbe list from: {url}")
            
            response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=15)
            logger.info(f"Response status: {response.status_code}")
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Try multiple selector patterns to find hutbe items
            hutbe_items = []
            
            # Pattern 1: Card-based layout
            hutbe_items = soup.find_all("div", class_="card")
            if hutbe_items:
                logger.info(f"Found {len(hutbe_items)} items using div.card selector")
            
            # Pattern 2: Table-based layout
            if not hutbe_items:
                hutbe_items = soup.select("table tbody tr")
                if hutbe_items:
                    logger.info(f"Found {len(hutbe_items)} items using table selector")
            
            # Pattern 3: Generic links containing 'hutbe' or 'Hutbe'
            if not hutbe_items:
                hutbe_items = soup.find_all("a", href=re.compile(r'/(H|h)utbe/'))
                if hutbe_items:
                    logger.info(f"Found {len(hutbe_items)} items using generic link selector")
            
            if not hutbe_items:
                logger.warning("No hutbe items found with any selector pattern")
                return hutbeler
            
            for item in hutbe_items:
                try:
                    hutbe_data = DiyanetScraper._parse_hutbe_item(item)
                    if hutbe_data:
                        hutbeler.append(hutbe_data)
                except Exception as e:
                    logger.error(f"Error parsing hutbe item: {e}")
                    continue
            
            logger.info(f"Successfully parsed {len(hutbeler)} hutbeler")
            
        except requests.RequestException as e:
            logger.error(f"Request error scraping hutbe list from {url}: {e}")
        except Exception as e:
            logger.error(f"Error scraping hutbe list: {e}")
        
        return hutbeler
    
    @staticmethod
    def _parse_hutbe_item(item) -> Optional[Dict]:
        """Parse a single hutbe item from the list."""
        try:
            title = None
            date_str = None
            link = None
            
            # Try to extract based on item type
            if item.name == 'div':
                # Card-based layout
                title_elem = item.select_one('h5.card-title, h4, h3, .title')
                title = title_elem.get_text(strip=True) if title_elem else None
                
                date_elem = item.select_one('.date, .card-text, time')
                date_str = date_elem.get_text(strip=True) if date_elem else None
                
                link_elem = item.select_one('a.card-link, a')
                link = link_elem.get('href') if link_elem else None
                
            elif item.name == 'tr':
                # Table-based layout
                cells = item.find_all('td')
                if len(cells) >= 2:
                    title = cells[0].get_text(strip=True) if cells[0] else None
                    date_str = cells[1].get_text(strip=True) if len(cells) > 1 and cells[1] else None
                    
                    link_elem = item.find('a')
                    link = link_elem.get('href') if link_elem else None
                    
            elif item.name == 'a':
                # Direct link element
                title = item.get_text(strip=True)
                link = item.get('href')
                
                # Try to find date in parent or sibling elements
                parent = item.parent
                if parent:
                    date_elem = parent.find(class_=re.compile(r'date|tarih'))
                    date_str = date_elem.get_text(strip=True) if date_elem else None
            
            if not title or not link:
                logger.debug("Missing title or link in item")
                return None
            
            # Clean and complete the URL
            if link and not link.startswith('http'):
                link = DiyanetScraper.BASE_URL + link if link.startswith('/') else DiyanetScraper.BASE_URL + '/' + link
            
            # Parse date
            hutbe_date = DiyanetScraper._parse_date(date_str) if date_str else datetime.now().date()
            
            return {
                'title': title,
                'date': hutbe_date,
                'url': link,
            }
        except Exception as e:
            logger.error(f"Error in _parse_hutbe_item: {e}")
            return None
    
    @staticmethod
    def scrape_hutbe_detail(url: str) -> Optional[Dict]:
        """Scrape full hutbe content from detail page."""
        try:
            logger.info(f"Scraping hutbe detail from: {url}")
            
            response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=15)
            logger.info(f"Response status: {response.status_code}")
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Try multiple selector patterns for title
            title_elem = soup.select_one('h1, h2, .icerik-baslik, .details-header, .hutbe-title, .page-title')
            title = title_elem.get_text(strip=True) if title_elem else None
            
            # Try multiple selector patterns for content
            content_elem = None
            
            # Pattern 1: Specific content classes
            content_elem = soup.select_one('.icerik, .hutbe-icerik, .details-content, .content, article, .icerik-body, .detail-body')
            
            # Pattern 2: Generic content container with regex
            if not content_elem:
                content_elem = soup.find("div", {"class": re.compile(r'.*(content|icerik|detail|hutbe).*', re.I)})
            
            # Pattern 3: Main content area
            if not content_elem:
                content_elem = soup.find("main") or soup.find("div", {"id": "content"})
            
            # Extract text content
            content = None
            if content_elem:
                # Get text and clean it
                content = content_elem.get_text(separator='\n', strip=True)
                # Remove excessive whitespace
                content = re.sub(r'\n{3,}', '\n\n', content)
                content = re.sub(r' {2,}', ' ', content)
            
            if not title and not content:
                logger.warning(f"Could not extract title or content from {url}")
                return None
            
            # If title not found in specific element, try to extract from content or page
            if not title:
                title_from_page = soup.find('title')
                title = title_from_page.get_text(strip=True) if title_from_page else "Hutbe"
            
            # Generate summary (first 200 characters)
            summary = content[:200] + "..." if content and len(content) > 200 else content
            
            # Determine category
            category = DiyanetScraper._determine_category(title + " " + (content or ""))
            
            # Calculate reading time
            reading_time = HutbeService.calculate_reading_time(content) if content else 5
            
            return {
                'title': title,
                'content': content or "",
                'summary': summary or "",
                'category': category,
                'reading_time_minutes': reading_time,
                'source_url': url,
            }
            
        except requests.RequestException as e:
            logger.error(f"Request error scraping hutbe detail from {url}: {e}")
            return None
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
            logger.warning("No hutbeler found in list")
            return 0
        
        saved_count = 0
        for hutbe_item in hutbe_list[:limit]:
            try:
                # Rate limiting - don't overwhelm the server
                time.sleep(1)
                
                # Get full content
                detail = DiyanetScraper.scrape_hutbe_detail(hutbe_item['url'])
                if not detail:
                    logger.warning(f"Could not get detail for: {hutbe_item.get('title', 'unknown')}")
                    continue
                
                # Merge with list data
                hutbe_data = {
                    **hutbe_item,
                    **detail,
                }
                
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
                logger.error(f"Error saving hutbe '{hutbe_item.get('title', 'unknown')}': {e}")
                continue
        
        logger.info(f"Scraping completed. Saved {saved_count} hutbeler.")
        return saved_count
