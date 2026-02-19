from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
import requests

from app.config import get_settings
from app.database import init_db, get_db
from app.api.routes import hutbe, prayer
from app.scraper.scheduler import start_scheduler, stop_scheduler
from app.scraper.diyanet import DiyanetScraper
from app.services.hutbe_service import HutbeService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    # Startup
    logger.info("Starting up Minber API...")
    
    # Initialize database
    await init_db()
    logger.info("Database initialized")
    
    # Auto-seed if database is empty
    try:
        async for db in get_db():
            try:
                hutbe_count = await HutbeService.get_hutbe_count(db)
                if hutbe_count == 0:
                    logger.info("Database is empty, loading seed data...")
                    from app.seed_data import load_seed_data
                    await load_seed_data(db)
                    logger.info("Seed data loaded successfully")
                else:
                    logger.info(f"Database already contains {hutbe_count} hutbeler")
            except Exception as e:
                logger.warning(f"Could not check/load seed data: {e}")
            finally:
                break
    except Exception as e:
        logger.warning(f"Seed data check failed: {e}")
    
    # Start scheduler if enabled
    if settings.SCRAPER_ENABLED:
        start_scheduler()
    
    yield
    
    # Shutdown
    logger.info("Shutting down Minber API...")
    if settings.SCRAPER_ENABLED:
        stop_scheduler()


# Create FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="API for Minber - Hutbe & Namaz Vakitleri Uygulaması",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(hutbe.router, prefix=settings.API_V1_PREFIX)
app.include_router(prayer.router, prefix=settings.API_V1_PREFIX)


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Minber API",
        "version": settings.VERSION,
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.get(f"{settings.API_V1_PREFIX}/scraper/test")
async def test_scraper():
    """Test scraper with full pagination and PDF extraction."""
    import traceback
    
    try:
        # Test page 1
        url = f"{DiyanetScraper.BASE_URL}/kategoriler/yayinlarimiz/hutbeler/türkçe"
        response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=15)
        
        page1_items = DiyanetScraper._parse_sharepoint_json(response.text)
        
        # Run full scraper (with pagination)
        all_hutbeler = DiyanetScraper.scrape_hutbe_list()
        
        # Test PDF extraction on first hutbe
        pdf_test = None
        if all_hutbeler and all_hutbeler[0].get('pdf_url'):
            try:
                pdf_response = requests.get(
                    all_hutbeler[0]['pdf_url'], 
                    headers=DiyanetScraper.HEADERS, 
                    timeout=30
                )
                if pdf_response.status_code == 200:
                    detail = DiyanetScraper._extract_text_from_pdf(
                        pdf_response.content, all_hutbeler[0]['pdf_url']
                    )
                    if detail:
                        pdf_test = {
                            "status": "success",
                            "title": detail.get("title"),
                            "content_preview": detail.get("content", "")[:500],
                            "content_length": len(detail.get("content", "")),
                        }
                    else:
                        pdf_test = {"status": "no_text_extracted"}
                else:
                    pdf_test = {"status": f"http_{pdf_response.status_code}"}
            except Exception as e:
                pdf_test = {"status": "error", "error": str(e)}
        
        # Year distribution
        year_counts = {}
        for h in all_hutbeler:
            year = h['date'].year if hasattr(h['date'], 'year') else 'unknown'
            year_counts[year] = year_counts.get(year, 0) + 1
        
        return {
            "page1_count": len(page1_items),
            "total_hutbe_count": len(all_hutbeler),
            "year_distribution": dict(sorted(year_counts.items())),
            "first_5": [
                {"title": h["title"], "date": str(h["date"]), "pdf_url": h.get("pdf_url")} 
                for h in all_hutbeler[:5]
            ],
            "last_5": [
                {"title": h["title"], "date": str(h["date"]), "pdf_url": h.get("pdf_url")} 
                for h in all_hutbeler[-5:]
            ],
            "pdf_extraction_test": pdf_test,
            "scraper_status": "fully_working" if len(all_hutbeler) > 100 else "partial",
        }
    except Exception as e:
        return {"error": str(e), "traceback": traceback.format_exc()}


@app.post(f"{settings.API_V1_PREFIX}/scraper/run")
async def manual_scraper_run(
    db = Depends(get_db),
):
    """Manually trigger the scraper."""
    try:
        count = await DiyanetScraper.scrape_and_save_hutbeler(db, limit=50)
        return {"status": "completed", "saved_count": count}
    except Exception as e:
        return {"status": "error", "error": str(e)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
    )
