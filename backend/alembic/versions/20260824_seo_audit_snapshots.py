"""SEO Audit Snapshots Migration

Revision ID: seo_audit_snapshots
Revises: external_providers_and_gsc
Create Date: 2026-08-24 12:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = 'seo_audit_snapshots'
down_revision = 'external_providers_and_gsc'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
    CREATE TABLE IF NOT EXISTS seo_audit_snapshots (
        id VARCHAR(36) PRIMARY KEY,
        business_id VARCHAR(36) NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
        visibility_score INTEGER NOT NULL DEFAULT 0,
        map_pack_score INTEGER NOT NULL DEFAULT 0,
        organic_rank_avg INTEGER NOT NULL DEFAULT 0,
        top3_ratio INTEGER NOT NULL DEFAULT 0,
        recorded_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS ix_seo_snapshots_biz_time ON seo_audit_snapshots(business_id, recorded_at);
    """)


def downgrade() -> None:
    op.execute("""
    DROP TABLE IF EXISTS seo_audit_snapshots;
    """)
