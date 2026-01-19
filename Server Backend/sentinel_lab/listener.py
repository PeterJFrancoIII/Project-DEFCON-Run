# ==============================================================================
# SYSTEM: SENTINEL FLASH TESTBED
# MODULE: listener.py
# ROLE:   BACKGROUND SCHEDULER (15-MINUTE CYCLE)
# ==============================================================================

import schedule
import time
import logging
import os
from datetime import datetime

# Configure logging
LOG_DIR = os.path.dirname(os.path.abspath(__file__))
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(LOG_DIR, 'sentinel_lab.log')),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Import intelligence module
from intelligence import run_cycle


def job():
    """Scheduled job that runs the intelligence cycle."""
    logger.info("="*50)
    logger.info("SCHEDULED CYCLE TRIGGERED")
    logger.info("="*50)
    
    try:
        results = run_cycle()
        logger.info(f"Cycle complete. Processed {len(results)} events.")
    except Exception as e:
        logger.error(f"Cycle failed: {e}")


def main():
    """Main entry point for the listener."""
    logger.info("="*60)
    logger.info("SENTINEL FLASH LISTENER - STARTING")
    logger.info(f"Current Time: {datetime.utcnow().isoformat()}")
    logger.info("="*60)
    
    # Run immediately on startup
    logger.info("Running initial cycle...")
    job()
    
    # Schedule every 15 minutes
    schedule.every(15).minutes.do(job)
    
    logger.info("Scheduler active. Next run in 15 minutes.")
    logger.info("Press Ctrl+C to stop.\n")
    
    try:
        while True:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
    except KeyboardInterrupt:
        logger.info("\nListener stopped by user.")


if __name__ == "__main__":
    main()
