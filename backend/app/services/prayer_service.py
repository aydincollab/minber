import httpx
from typing import Optional, Dict, Any, Tuple
from datetime import datetime


class PrayerService:
    """Service for fetching prayer times from Aladhan API."""
    
    BASE_URL = "http://api.aladhan.com/v1"
    
    @staticmethod
    async def get_prayer_times_by_coordinates(
        latitude: float,
        longitude: float,
        date: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get prayer times by geographical coordinates.
        
        Args:
            latitude: Latitude coordinate
            longitude: Longitude coordinate
            date: Date in DD-MM-YYYY format (optional, defaults to today)
            
        Returns:
            Dictionary with prayer times
        """
        if date is None:
            date = datetime.now().strftime("%d-%m-%Y")
        
        url = f"{PrayerService.BASE_URL}/timings/{date}"
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "method": 13,  # Method 13 is for Turkey (Diyanet)
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, timeout=10.0)
            response.raise_for_status()
            data = response.json()
        
        return PrayerService._format_response(data)
    
    @staticmethod
    async def get_prayer_times_by_city(
        city: str,
        country: str,
        date: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get prayer times by city and country.
        
        Args:
            city: City name
            country: Country code (e.g., 'TR' for Turkey)
            date: Date in DD-MM-YYYY format (optional, defaults to today)
            
        Returns:
            Dictionary with prayer times
        """
        if date is None:
            date = datetime.now().strftime("%d-%m-%Y")
        
        url = f"{PrayerService.BASE_URL}/timingsByCity/{date}"
        params = {
            "city": city,
            "country": country,
            "method": 13,  # Method 13 is for Turkey (Diyanet)
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, timeout=10.0)
            response.raise_for_status()
            data = response.json()
        
        return PrayerService._format_response(data)
    
    @staticmethod
    def _format_response(data: Dict[str, Any]) -> Dict[str, Any]:
        """Format the API response to a simpler structure."""
        if data.get("code") != 200:
            raise Exception("Failed to fetch prayer times")
        
        timings = data["data"]["timings"]
        date_info = data["data"]["date"]
        
        return {
            "date": {
                "readable": date_info["readable"],
                "hijri": date_info["hijri"]["date"],
            },
            "timings": {
                "Fajr": timings["Fajr"],
                "Dhuhr": timings["Dhuhr"],
                "Asr": timings["Asr"],
                "Maghrib": timings["Maghrib"],
                "Isha": timings["Isha"],
            },
            "location": data["data"].get("meta", {}).get("timezone", ""),
        }
    
    @staticmethod
    def get_next_prayer(timings: Dict[str, str]) -> Tuple[str, str]:
        """
        Determine the next prayer and its time.
        
        Args:
            timings: Dictionary of prayer names and times
            
        Returns:
            Tuple of (prayer_name, prayer_time)
        """
        now = datetime.now().time()
        prayer_order = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
        
        for prayer in prayer_order:
            prayer_time_str = timings[prayer].split(" ")[0]  # Remove timezone info
            prayer_time = datetime.strptime(prayer_time_str, "%H:%M").time()
            
            if prayer_time > now:
                return prayer, timings[prayer]
        
        # If no prayer is left today, next is Fajr tomorrow
        return "Fajr", timings["Fajr"]
