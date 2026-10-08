from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class Match(Base):
    __tablename__ = "matches"

    id = Column(String, primary_key=True)  # Benzersiz maç ID'si
    league = Column(String, index=True)    # Lig/Turnuva adı
    home_team = Column(String, index=True) # Ev sahibi
    away_team = Column(String, index=True) # Deplasman
    match_time = Column(DateTime)          # Başlama saati
    status = Column(String, default="UPCOMING") # UPCOMING, COMPLETED
    created_at = Column(DateTime, default=datetime.utcnow)

    odds = relationship("Odds", back_populates="match", cascade="all, delete-orphan")

class Odds(Base):
    __tablename__ = "odds"

    id = Column(Integer, primary_key=True, autoincrement=True)
    match_id = Column(String, ForeignKey("matches.id"))
    bookmaker = Column(String)  # Bet365, Pinnacle, 1xBet, Unibet, Betfair, TR_Legal
    market = Column(String)     # 1X2, OVER_UNDER_2_5, BOTH_TEAMS_SCORE vb.
    outcome = Column(String)    # 1, X, 2, Over, Under, Yes, No
    price = Column(Float)       # Oran (örn: 1.85)
    updated_at = Column(DateTime, default=datetime.utcnow)

    match = relationship("Match", back_populates="odds")