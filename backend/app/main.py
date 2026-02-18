from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.config import get_settings
from app.database import init_db, get_db
from app.api.routes import hutbe, prayer
from app.scraper.scheduler import start_scheduler, stop_scheduler
from app.scraper.diyanet import DiyanetScraper

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
    
    # Seed data kontrolü - veritabanı boşsa seed hutbeleri yükle
    try:
        from app.services.hutbe_service import HutbeService
        from app.seed_data import SEED_HUTBELER
        from app.schemas.hutbe import HutbeCreate
        from app.database import AsyncSessionLocal
        
        async with AsyncSessionLocal() as db:
            count = await HutbeService.get_hutbe_count(db)
            if count == 0:
                logger.info("Database is empty. Loading seed hutbeler...")
                for hutbe_data in SEED_HUTBELER:
                    try:
                        hutbe_create = HutbeCreate(**hutbe_data)
                        await HutbeService.create_hutbe(db, hutbe_create)
                    except Exception as e:
                        logger.error(f"Error seeding hutbe '{hutbe_data.get('title', 'unknown')}': {e}")
                await db.commit()
                logger.info(f"Seeded {len(SEED_HUTBELER)} hutbeler successfully.")
            else:
                logger.info(f"Database already contains {count} hutbeler. Skipping seed.")
    except Exception as e:
        logger.error(f"Error during seed data check: {e}")
    
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


@app.post(f"{settings.API_V1_PREFIX}/scraper/run")
async def manual_scraper_run(
    year: int = None,
    limit: int = 5,
    db = Depends(get_db),
):
    """
    Manually trigger scraper (admin only - add auth later).
    
    Args:
        year: Year to scrape (optional)
        limit: Maximum number of hutbeler to scrape
    """
    try:
        count = await DiyanetScraper.scrape_and_save_hutbeler(db, year=year, limit=limit)
        return {
            "status": "success",
            "message": f"Scraped and saved {count} hutbeler",
            "count": count,
        }
    except Exception as e:
        logger.error(f"Error in manual scraper: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
    )
