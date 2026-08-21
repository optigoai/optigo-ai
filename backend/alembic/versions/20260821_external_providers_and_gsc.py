"""External Data Providers, Google Search Console, and Website Audits Migration

Revision ID: external_providers_and_gsc
Revises: phase7_seo_optimizer
Create Date: 2026-08-21 12:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = 'external_providers_and_gsc'
down_revision = 'phase7_seo_optimizer'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Create google_search_console_connections table
    op.execute("""
    CREATE TABLE IF NOT EXISTS google_search_console_connections (
        id VARCHAR(36) PRIMARY KEY,
        business_id VARCHAR(36) NOT NULL UNIQUE REFERENCES businesses(id) ON DELETE CASCADE,
        organization_id VARCHAR(36) NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
        site_url VARCHAR(500),
        access_token VARCHAR(2000),
        refresh_token VARCHAR(2000),
        token_expires_at TIMESTAMP WITHOUT TIME ZONE,
        is_connected BOOLEAN NOT NULL DEFAULT FALSE,
        sync_status VARCHAR(50) NOT NULL DEFAULT 'idle',
        last_synced_at TIMESTAMP WITHOUT TIME ZONE,
        sync_error VARCHAR(1000),
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS ix_gsc_conn_biz ON google_search_console_connections(business_id);
    CREATE INDEX IF NOT EXISTS ix_gsc_conn_org ON google_search_console_connections(organization_id);
    """)

    # 2. Create search_console_metrics table
    op.execute("""
    CREATE TABLE IF NOT EXISTS search_console_metrics (
        id VARCHAR(36) PRIMARY KEY,
        business_id VARCHAR(36) NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
        site_url VARCHAR(500) NOT NULL,
        date DATE NOT NULL,
        query VARCHAR(500) NOT NULL,
        page VARCHAR(1000),
        clicks INTEGER NOT NULL DEFAULT 0,
        impressions INTEGER NOT NULL DEFAULT 0,
        ctr FLOAT NOT NULL DEFAULT 0.0,
        position FLOAT NOT NULL DEFAULT 0.0,
        device VARCHAR(50) DEFAULT 'ALL',
        country VARCHAR(10) DEFAULT 'ALL',
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS ix_gsc_metrics_biz_date ON search_console_metrics(business_id, date);
    CREATE INDEX IF NOT EXISTS ix_gsc_metrics_query ON search_console_metrics(query);
    """)

    # 3. Create website_audits table
    op.execute("""
    CREATE TABLE IF NOT EXISTS website_audits (
        id VARCHAR(36) PRIMARY KEY,
        business_id VARCHAR(36) NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
        site_url VARCHAR(500) NOT NULL,
        overall_score INTEGER NOT NULL DEFAULT 75,
        technical_score INTEGER NOT NULL DEFAULT 70,
        content_score INTEGER NOT NULL DEFAULT 80,
        local_signals_score INTEGER NOT NULL DEFAULT 75,
        findings JSON NOT NULL DEFAULT '[]'::json,
        actionable_recommendations JSON NOT NULL DEFAULT '[]'::json,
        raw_crawl_meta JSON NOT NULL DEFAULT '{}'::json,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS ix_website_audits_biz ON website_audits(business_id);
    """)


def downgrade() -> None:
    op.execute("""
    DROP TABLE IF EXISTS website_audits;
    DROP TABLE IF EXISTS search_console_metrics;
    DROP TABLE IF EXISTS google_search_console_connections;
    """)
