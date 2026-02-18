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
        Scrape list of hutbeler from Diyanet website.
        Tries multiple selector patterns to handle varying site structure.
        """
        hutbeler = []
        
        try:
            # Primary URL for Turkish hutbeler
            url = f"{DiyanetScraper.BASE_URL}/kategoriler/yayinlarimiz/hutbeler/türkçe"
            
            logger.info(f"Fetching hutbe list from: {url}")
            response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=15)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Try Pattern 1: Card-based layout
            items = soup.find_all("div", class_="card")
            if items:
                logger.info(f"Found {len(items)} items using Pattern 1 (card layout)")
                for item in items:
                    try:
                        hutbe_data = DiyanetScraper._parse_card_item(item)
                        if hutbe_data:
                            hutbeler.append(hutbe_data)
                    except Exception as e:
                        logger.warning(f"Error parsing card item: {e}")
                        continue
            
            # Try Pattern 2: Table-based layout
            if not hutbeler:
                logger.info("Pattern 1 found no results, trying Pattern 2 (table layout)")
                rows = soup.select("table tbody tr")
                if rows:
                    logger.info(f"Found {len(rows)} rows using Pattern 2")
                    for row in rows:
                        try:
                            hutbe_data = DiyanetScraper._parse_table_row(row)
                            if hutbe_data:
                                hutbeler.append(hutbe_data)
                        except Exception as e:
                            logger.warning(f"Error parsing table row: {e}")
                            continue
            
            # Try Pattern 3: Generic hutbe links
            if not hutbeler:
                logger.info("Pattern 2 found no results, trying Pattern 3 (generic links)")
                links = soup.find_all("a", href=re.compile(r'(?i)hutbe'))
                if links:
                    logger.info(f"Found {len(links)} links using Pattern 3")
                    for link in links:
                        try:
                            hutbe_data = DiyanetScraper._parse_link_item(link)
                            if hutbe_data:
                                hutbeler.append(hutbe_data)
                        except Exception as e:
                            logger.warning(f"Error parsing link: {e}")
                            continue
            
            # Try Pattern 4: List-based layout
            if not hutbeler:
                logger.info("Pattern 3 found no results, trying Pattern 4 (list items)")
                list_items = soup.find_all("li")
                date_pattern = re.compile(r'\d{2}\.\d{2}\.\d{4}')
                for li in list_items:
                    text = li.get_text()
                    if date_pattern.search(text):
                        try:
                            hutbe_data = DiyanetScraper._parse_list_item(li)
                            if hutbe_data:
                                hutbeler.append(hutbe_data)
                        except Exception as e:
                            logger.warning(f"Error parsing list item: {e}")
                            continue
            
            logger.info(f"Successfully scraped {len(hutbeler)} hutbeler")
            
        except Exception as e:
            logger.error(f"Error scraping hutbe list: {e}")
        
        return hutbeler
    
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
        """Scrape full hutbe content from detail page."""
        if not url or url == DiyanetScraper.BASE_URL:
            return None
            
        try:
            logger.info(f"Fetching hutbe detail from: {url}")
            response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=15)
            response.raise_for_status()
            
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
                if hutbe_item.get('url'):
                    detail = DiyanetScraper.scrape_hutbe_detail(hutbe_item['url'])
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
                else:
                    # No URL, use list data only
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
