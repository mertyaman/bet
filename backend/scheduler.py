from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta
from database import SessionLocal
from models import Match

def clean_old_matches():
    """Bitiş tarihinden 7 gün geçen maçları veritabanından temizler."""
    db = SessionLocal()
    try:
        cutoff_date = datetime.utcnow() - timedelta(days=7)
        deleted = db.query(Match).filter(Match.match_time < cutoff_date).delete()
        db.commit()
        print(f"[TEMİZLİK] {deleted} adet 7 günden eski maç silindi.")
    except Exception as e:
        db.rollback()
        print(f"[HATA] Temizlik sırasında hata: {e}")
    finally:
        db.close()

def start_scheduler(fetch_data_function):
    scheduler = BackgroundScheduler()
    # 30 saniyede bir oranları yenile
    scheduler.add_job(fetch_data_function, 'interval', seconds=12000)
    # Her gün gece yarısı 7 günden eski maçları temizle
    scheduler.add_job(clean_old_matches, 'cron', hour=0, minute=0)
    scheduler.start()