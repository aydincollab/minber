import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
from datetime import datetime
import re
from app.services.hutbe_service import HutbeService


class DiyanetScraper:
    """Scraper for Diyanet İşleri Başkanlığı hutbeler."""
    
    BASE_URL = "https://diyanet.gov.tr"
    
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
        This is a placeholder implementation - actual URL structure may vary.
        """
        hutbeler = []
        
        # Note: This is a simplified example. The actual Diyanet website structure
        # may be different and would need to be analyzed.
        try:
            # Example URL structure - needs to be verified
            url = f"{DiyanetScraper.BASE_URL}/tr-TR/Kurumsal/Detay/29/hutbeler"
            if year:
                url += f"?year={year}"
            
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # This selector would need to be adjusted based on actual website structure
            hutbe_items = soup.select('.hutbe-item')  # Placeholder selector
            
            for item in hutbe_items:
                try:
                    hutbe_data = DiyanetScraper._parse_hutbe_item(item)
                    if hutbe_data:
                        hutbeler.append(hutbe_data)
                except Exception as e:
                    print(f"Error parsing hutbe item: {e}")
                    continue
            
        except Exception as e:
            print(f"Error scraping hutbe list: {e}")
        
        return hutbeler
    
    @staticmethod
    def _parse_hutbe_item(item) -> Optional[Dict]:
        """Parse a single hutbe item from the list."""
        try:
            # These selectors are placeholders and need to be adjusted
            title = item.select_one('.title')?.get_text(strip=True)
            date_str = item.select_one('.date')?.get_text(strip=True)
            link = item.select_one('a')?.get('href')
            
            if not title or not link:
                return None
            
            # Parse date
            hutbe_date = DiyanetScraper._parse_date(date_str) if date_str else datetime.now().date()
            
            return {
                'title': title,
                'date': hutbe_date,
                'url': DiyanetScraper.BASE_URL + link if not link.startswith('http') else link,
            }
        except Exception as e:
            print(f"Error in _parse_hutbe_item: {e}")
            return None
    
    @staticmethod
    def scrape_hutbe_detail(url: str) -> Optional[Dict]:
        """Scrape full hutbe content from detail page."""
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # These selectors are placeholders
            title = soup.select_one('.hutbe-title, h1')?.get_text(strip=True)
            content = soup.select_one('.hutbe-content, .content')?.get_text(strip=True)
            
            if not title or not content:
                return None
            
            # Generate summary (first 200 characters)
            summary = content[:200] + "..." if len(content) > 200 else content
            
            # Determine category
            category = DiyanetScraper._determine_category(title + " " + content)
            
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
            print(f"Error scraping hutbe detail: {e}")
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
        
        print(f"Starting scraper for year {year or 'current'}...")
        
        # Get list of hutbeler
        hutbe_list = DiyanetScraper.scrape_hutbe_list(year)
        
        saved_count = 0
        for hutbe_item in hutbe_list[:limit]:
            try:
                # Get full content
                detail = DiyanetScraper.scrape_hutbe_detail(hutbe_item['url'])
                if not detail:
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
                
                print(f"Saved hutbe: {hutbe_data['title'][:50]}...")
                
            except Exception as e:
                print(f"Error saving hutbe: {e}")
                continue
        
        print(f"Scraping completed. Saved {saved_count} hutbeler.")
        return saved_count
