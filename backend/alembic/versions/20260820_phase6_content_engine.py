"""Phase 6 Content Engine & Social Posts Schema Migration

Revision ID: phase6_content_engine
Revises: 14c5172e69ee
Create Date: 2026-08-20 15:48:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = 'phase6_content_engine'
down_revision = '14c5172e69ee'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Create contenttype enum if not exists
    op.execute("""
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'contenttype') THEN
            CREATE TYPE contenttype AS ENUM ('google_post', 'instagram', 'facebook', 'linkedin', 'twitter', 'advertisement', 'website', 'seo_article', 'review_reply');
        ELSE
            ALTER TYPE contenttype ADD VALUE IF NOT EXISTS 'linkedin';
            ALTER TYPE contenttype ADD VALUE IF NOT EXISTS 'twitter';
        END IF;
    END$$;
    """)

    # 2. Create contentstatus enum if not exists
    op.execute("""
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'contentstatus') THEN
            CREATE TYPE contentstatus AS ENUM ('draft', 'scheduled', 'approved', 'published', 'failed');
        ELSE
            ALTER TYPE contentstatus ADD VALUE IF NOT EXISTS 'scheduled';
            ALTER TYPE contentstatus ADD VALUE IF NOT EXISTS 'failed';
        END IF;
    END$$;
    """)

    # 3. Create or update contents table
    op.execute("""
    CREATE TABLE IF NOT EXISTS contents (
        id VARCHAR(36) PRIMARY KEY,
        business_id VARCHAR(36) NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
        content_type contenttype NOT NULL,
        title VARCHAR(500),
        body TEXT NOT NULL,
        tone VARCHAR(100),
        target_audience VARCHAR(255),
        marketing_goal VARCHAR(255),
        hashtags TEXT,
        call_to_action VARCHAR(500),
        image_prompt TEXT,
        image_url VARCHAR(1000),
        status contentstatus NOT NULL DEFAULT 'draft',
        scheduled_at TIMESTAMP WITH TIME ZONE,
        published_at TIMESTAMP WITH TIME ZONE,
        generation_metadata JSON,
        campaign_id VARCHAR(36) REFERENCES campaigns(id) ON DELETE SET NULL,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
    );
    CREATE INDEX IF NOT EXISTS ix_contents_business_id ON contents (business_id);
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS contents CASCADE;")
