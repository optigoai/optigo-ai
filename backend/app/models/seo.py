import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship

from app.core.database import Base


class SEOKeyword(Base):
    __tablename__ = "seo_keywords"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    business_id = Column(String, ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, index=True)
    keyword = Column(String, nullable=False, index=True)
    target_location = Column(String, nullable=True)
    current_rank = Column(Integer, nullable=True)
    previous_rank = Column(Integer, nullable=True)
    search_volume = Column(String, nullable=True, default="500 / mo")
    difficulty = Column(String, nullable=True, default="Medium")
    intent = Column(String, nullable=True, default="Local Intent")
    is_tracked = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    business = relationship("Business", back_populates="seo_keywords")


class SEOAudit(Base):
    __tablename__ = "seo_audits"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    business_id = Column(String, ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, index=True)
    overall_seo_score = Column(Integer, nullable=False, default=70)
    map_pack_score = Column(Integer, nullable=False, default=65)
    keyword_score = Column(Integer, nullable=False, default=75)
    citation_score = Column(Integer, nullable=False, default=80)
    missing_attributes = Column(JSON, nullable=False, default=list)
    actionable_recommendations = Column(JSON, nullable=False, default=list)
    competitor_insights = Column(JSON, nullable=False, default=list)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    business = relationship("Business", back_populates="seo_audits")
