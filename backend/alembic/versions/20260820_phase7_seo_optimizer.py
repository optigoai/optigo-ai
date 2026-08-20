"""Phase 7 SEO & Visibility Optimizer Schema Migration

Revision ID: phase7_seo_optimizer
Revises: phase6_content_engine
Create Date: 2026-08-20 17:15:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = 'phase7_seo_optimizer'
down_revision = 'phase6_content_engine'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Create seo_keywords table if not exists
    op.execute("""
    CREATE TABLE IF NOT EXISTS seo_keywords (
        id VARCHAR PRIMARY KEY,
        business_id VARCHAR NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
        keyword VARCHAR NOT NULL,
        target_location VARCHAR,
        current_rank INTEGER,
        previous_rank INTEGER,
        search_volume VARCHAR DEFAULT '500 / mo',
        difficulty VARCHAR DEFAULT 'Medium',
        intent VARCHAR DEFAULT 'Local Intent',
        is_tracked BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS ix_seo_keywords_business_id ON seo_keywords(business_id);
    CREATE INDEX IF NOT EXISTS ix_seo_keywords_keyword ON seo_keywords(keyword);
    """)

    # 2. Create seo_audits table if not exists
    op.execute("""
    CREATE TABLE IF NOT EXISTS seo_audits (
        id VARCHAR PRIMARY KEY,
        business_id VARCHAR NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
        overall_seo_score INTEGER NOT NULL DEFAULT 70,
        map_pack_score INTEGER NOT NULL DEFAULT 65,
        keyword_score INTEGER NOT NULL DEFAULT 75,
        citation_score INTEGER NOT NULL DEFAULT 80,
        missing_attributes JSON NOT NULL DEFAULT '[]'::json,
        actionable_recommendations JSON NOT NULL DEFAULT '[]'::json,
        competitor_insights JSON NOT NULL DEFAULT '[]'::json,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS ix_seo_audits_business_id ON seo_audits(business_id);
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS seo_audits CASCADE;")
    op.execute("DROP TABLE IF EXISTS seo_keywords CASCADE;")
