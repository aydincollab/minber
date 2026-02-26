from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.scraper.diyanet import DiyanetScraper
from app.database import AsyncSessionLocal
import logging

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


async def scheduled_scrape_job():
    """
    Weekly job — runs every Thursday at 21:00 UTC (00:00 Türkiye).
    Phase 1: Scrape new hutbe metadata from Diyanet (fast, ~30 sec).
    Phase 2: Download PDFs and enrich placeholder content (can take a few min).
             Runs multiple batches until all placeholders are filled.
    """
    logger.info("=== Weekly hutbe job starting ===")

    async with AsyncSessionLocal() as db:
        try:
            # ── Phase 1: metadata ──────────────────────────────────────
            logger.info("Phase 1: scraping metadata...")
            count = await DiyanetScraper.scrape_and_save_hutbeler(db, limit=10)
            logger.info(f"Phase 1 done. Saved/updated {count} hutbeler.")
        except Exception as e:
            logger.error(f"Phase 1 failed: {e}")
            await db.rollback()

    # ── Phase 2: PDF enrichment (separate sessions for safety) ────────
    # Run up to 5 batches of 20 so we catch newly added + any leftovers.
    total_enriched = 0
    for batch in range(5):
        async with AsyncSessionLocal() as db:
            try:
                enriched, remaining = await DiyanetScraper.enrich_hutbe_content(db, batch_size=20)
                total_enriched += enriched
                logger.info(f"Phase 2 batch {batch + 1}: enriched={enriched}, remaining={remaining}")
                if remaining == 0:
                    break
            except Exception as e:
                logger.error(f"Phase 2 batch {batch + 1} failed: {e}")
                await db.rollback()
                break

    logger.info(f"=== Weekly hutbe job done. Total enriched this run: {total_enriched} ===")


def start_scheduler():
    """Start the scheduler with weekly cron job."""
    # Every Friday at 05:00 UTC = 08:00 Türkiye (UTC+3)
    # Diyanet publishes the hutbe by Friday morning; scraping at 08:00 TR ensures it's available.
    scheduler.add_job(
        scheduled_scrape_job,
        trigger=CronTrigger(day_of_week='fri', hour=5, minute=0, timezone='UTC'),
        id='weekly_hutbe_scraper',
        name='Weekly Hutbe Scraper (scrape + enrich)',
        replace_existing=True,
    )

    scheduler.start()
    logger.info("Scheduler started — weekly hutbe job will run every Thursday 21:00 UTC (00:00 TR).")


def stop_scheduler():
    """Stop the scheduler."""
    scheduler.shutdown()
    logger.info("Scheduler stopped.")
