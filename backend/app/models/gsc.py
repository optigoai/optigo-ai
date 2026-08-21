# ==================================================
# OptigoAI Backend — Google Search Console Models
# ==================================================

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Date, ForeignKey, Index
from sqlalchemy.orm import relationship

from app.core.database import Base


class GoogleSearchConsoleConnection(Base):
    __tablename__ = "google_search_console_connections"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    business_id = Column(String(36), ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    organization_id = Column(String(36), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    
    site_url = Column(String(500), nullable=True)
    # Tokens are stored securely on backend only, never exposed in client API responses
    access_token = Column(String(2000), nullable=True)
    refresh_token = Column(String(2000), nullable=True)
    token_expires_at = Column(DateTime, nullable=True)
    
    is_connected = Column(Boolean, default=False, nullable=False)
    sync_status = Column(String(50), default="idle", nullable=False)  # idle, syncing, success, error
    last_synced_at = Column(DateTime, nullable=True)
    sync_error = Column(String(1000), nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    business = relationship("Business", lazy="selectin")
    organization = relationship("Organization", lazy="selectin")


class SearchConsoleMetric(Base):
    __tablename__ = "search_console_metrics"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    business_id = Column(String(36), ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, index=True)
    site_url = Column(String(500), nullable=False)
    date = Column(Date, nullable=False, index=True)
    
    query = Column(String(500), nullable=False, index=True)
    page = Column(String(1000), nullable=True)
    clicks = Column(Integer, default=0, nullable=False)
    impressions = Column(Integer, default=0, nullable=False)
    ctr = Column(Float, default=0.0, nullable=False)
    position = Column(Float, default=0.0, nullable=False)
    
    device = Column(String(50), default="ALL", nullable=True)  # DESKTOP, MOBILE, TABLET, ALL
    country = Column(String(10), default="ALL", nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    __table_args__ = (
        Index("ix_gsc_metrics_biz_date", "business_id", "date"),
    )
