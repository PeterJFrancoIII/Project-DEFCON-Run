import sys
import os

# Setup path
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)

from core.db_utils import get_db_handle

def main():
    try:
        db = get_db_handle()
        # Delete all documents in news_index
        result = db.news_index.delete_many({})
        print(f">> [RESET] Cleared 'news_index'. Deleted count: {result.deleted_count}")
    except Exception as e:
        print(f">> [ERROR] {e}")

if __name__ == "__main__":
    main()
