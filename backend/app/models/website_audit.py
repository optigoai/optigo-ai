# ==================================================
# OptigoAI Backend — Website Audit Models
# ==================================================

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship

from app.core.database import Base


class WebsiteAudit(Base):
    __tablename__ = "website_audits"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    business_id = Column(String(36), ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, index=True)
    
    site_url = Column(String(500), nullable=False)
    overall_score = Column(Integer, default=75, nullable=False)
    technical_score = Column(Integer, default=70, nullable=False)
    content_score = Column(Integer, default=80, nullable=False)
    local_signals_score = Column(Integer, default=75, nullable=False)
    
    # Structured findings & actionable items
    findings = Column(JSON, default=list, nullable=False)  # List of {type, status, title, impact}
    actionable_recommendations = Column(JSON, default=list, nullable=False)
    raw_crawl_meta = Column(JSON, default=dict, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    business = relationship("Business", lazy="selectin")
