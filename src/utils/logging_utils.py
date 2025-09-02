import logging
import os
import sys
from datetime import datetime

LOG_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build', 'logs')
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, f'app_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger('kivixa')

def log_exception(exc_type, exc_value, exc_traceback):
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        return
    logger.critical("Uncaught exception", exc_info=(exc_type, exc_value, exc_traceback))
    # Optionally, write a crash report
    crash_file = os.path.join(LOG_DIR, f'crash_{datetime.now().strftime("%Y%m%d_%H%M%S")}.txt')
    with open(crash_file, 'w', encoding='utf-8') as f:
        import traceback
        traceback.print_exception(exc_type, exc_value, exc_traceback, file=f)
    # Show user-friendly message (if GUI available)
    try:
        from PySide6.QtWidgets import QMessageBox, QApplication
        app = QApplication.instance()
        if app:
            QMessageBox.critical(None, "Application Error", "A critical error occurred. A crash report was saved. Please contact support.")
    except Exception:
        pass

# To use: sys.excepthook = log_exception
