from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

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
    """Test scraper without saving to DB — just return what it finds."""
    import traceback
    
    try:
        # Try to fetch the page first
        import requests
        url = f"{DiyanetScraper.BASE_URL}/kategoriler/yayinlarimiz/hutbeler/türkçe"
        response = requests.get(url, headers=DiyanetScraper.HEADERS, timeout=15)
        
        page_info = {
            "status_code": response.status_code,
            "content_length": len(response.content),
            "content_type": response.headers.get("content-type", ""),
            "first_500_chars": response.text[:500],
        }
        
        # Try scraping
        hutbe_list = DiyanetScraper.scrape_hutbe_list()
        
        return {
            "page_info": page_info,
            "hutbe_count": len(hutbe_list),
            "hutbeler": hutbe_list[:5],  # First 5 for inspection
            "scraper_status": "working" if hutbe_list else "no_results",
        }
    except Exception as e:
        return {
            "error": str(e),
            "traceback": traceback.format_exc(),
            "scraper_status": "error",
        }


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
