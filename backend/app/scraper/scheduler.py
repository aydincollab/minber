from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.scraper.diyanet import DiyanetScraper
from app.database import AsyncSessionLocal
import logging

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


async def scheduled_scrape_job():
    """Scheduled job to scrape hutbeler weekly."""
    logger.info("Starting scheduled hutbe scraping...")
    
    async with AsyncSessionLocal() as db:
        try:
            count = await DiyanetScraper.scrape_and_save_hutbeler(db, limit=5)
            logger.info(f"Scheduled scraping completed. Saved {count} hutbeler.")
        except Exception as e:
            logger.error(f"Error in scheduled scraping: {e}")
            await db.rollback()


def start_scheduler():
    """Start the scheduler with weekly cron job."""
    # Run every Thursday at 23:00 (11 PM)
    scheduler.add_job(
        scheduled_scrape_job,
        trigger=CronTrigger(day_of_week='thu', hour=23, minute=0),
        id='weekly_hutbe_scraper',
        name='Weekly Hutbe Scraper',
        replace_existing=True,
    )
    
    scheduler.start()
    logger.info("Scheduler started. Hutbe scraper will run every Thursday at 23:00.")


def stop_scheduler():
    """Stop the scheduler."""
    scheduler.shutdown()
    logger.info("Scheduler stopped.")
