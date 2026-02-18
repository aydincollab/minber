from fastapi import APIRouter, HTTPException, Query
from app.services.prayer_service import PrayerService
from typing import Optional

router = APIRouter(prefix="/namaz-vakitleri", tags=["namaz-vakitleri"])


@router.get("/")
async def get_prayer_times(
    lat: Optional[float] = Query(None, description="Latitude"),
    lng: Optional[float] = Query(None, description="Longitude"),
    city: Optional[str] = Query(None, description="City name"),
    country: str = Query("TR", description="Country code (default: TR)"),
    date: Optional[str] = Query(None, description="Date in DD-MM-YYYY format"),
):
    """
    Get prayer times by location.
    Either provide lat/lng coordinates OR city/country.
    """
    try:
        if lat is not None and lng is not None:
            # Use coordinates
            result = await PrayerService.get_prayer_times_by_coordinates(
                latitude=lat,
                longitude=lng,
                date=date
            )
        elif city:
            # Use city name
            result = await PrayerService.get_prayer_times_by_city(
                city=city,
                country=country,
                date=date
            )
        else:
            raise HTTPException(
                status_code=400,
                detail="Either provide lat/lng coordinates or city name"
            )
        
        # Add next prayer info
        next_prayer, next_time = PrayerService.get_next_prayer(result["timings"])
        result["next_prayer"] = {
            "name": next_prayer,
            "time": next_time
        }
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch prayer times: {str(e)}"
        )
