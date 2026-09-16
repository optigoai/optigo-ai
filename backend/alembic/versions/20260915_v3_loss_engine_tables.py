"""Add vertical_profiles and calibration_logs for v3 loss engine

Revision ID: v3_loss_engine_tables
Revises: seo_audit_snapshots
Create Date: 2026-09-15 15:20:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = 'v3_loss_engine_tables'
down_revision = 'seo_audit_snapshots'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Create vertical_profiles table
    op.execute("""
    CREATE TABLE IF NOT EXISTS vertical_profiles (
        id VARCHAR(36) PRIMARY KEY,
        vertical_key VARCHAR(50) NOT NULL UNIQUE,
        label VARCHAR(255) NOT NULL,
        aov_min FLOAT NOT NULL,
        aov_max FLOAT NOT NULL,
        p_call_to_order_min FLOAT NOT NULL,
        p_call_to_order_max FLOAT NOT NULL,
        p_direction_to_visit_min FLOAT NOT NULL,
        p_direction_to_visit_max FLOAT NOT NULL,
        directions_per_call_ratio_min FLOAT NOT NULL,
        directions_per_call_ratio_max FLOAT NOT NULL,
        max_loss_pct_of_benchmark_revenue FLOAT NOT NULL DEFAULT 0.35,
        click_to_call_rate_min FLOAT NOT NULL DEFAULT 0.04,
        click_to_call_rate_max FLOAT NOT NULL DEFAULT 0.06,
        decay_k FLOAT NOT NULL DEFAULT 0.5,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
    )
    """)

    op.execute("""CREATE INDEX IF NOT EXISTS ix_vertical_profiles_vertical_key ON vertical_profiles(vertical_key)""")

    # 2. Seed the starter verticals
    seed_verticals = [
        ("fnb_casual", "F&B - Casual / Family Restaurant", 250, 550, 0.20, 0.35, 0.10, 0.20, 1.2, 2.5, 0.35, 0.04, 0.06, 0.5),
        ("fnb_fine_dining", "F&B - Fine Dining", 600, 1500, 0.25, 0.40, 0.12, 0.22, 1.0, 2.0, 0.35, 0.04, 0.06, 0.5),
        ("fnb_bakery_cafe", "F&B - Bakery, Cafe & Desserts", 180, 480, 0.15, 0.30, 0.12, 0.25, 1.5, 3.0, 0.35, 0.04, 0.06, 0.5),
        ("fnb_fast_food", "F&B - Fast Food & Quick Bites", 150, 400, 0.18, 0.32, 0.15, 0.28, 1.5, 3.0, 0.35, 0.04, 0.06, 0.5),
        ("services_local", "Local Services (salon, repair, tutoring)", 300, 1500, 0.30, 0.50, 0.15, 0.30, 0.8, 1.8, 0.30, 0.04, 0.06, 0.5),
        ("services_high_ticket", "High-Ticket Services (clinics, dental, eye care, hospital)", 5000, 30000, 0.05, 0.15, 0.03, 0.10, 0.5, 1.2, 0.20, 0.03, 0.05, 0.5),
        ("retail_grocery", "Retail & Grocery (supermarket, mart, store)", 500, 1800, 0.20, 0.35, 0.20, 0.40, 2.0, 4.0, 0.25, 0.03, 0.05, 0.5),
        ("hotel_lodging", "Hotel & Lodging", 1800, 4500, 0.15, 0.30, 0.10, 0.20, 0.8, 1.5, 0.25, 0.04, 0.06, 0.5),
        ("gym_fitness", "Gym & Fitness Center", 800, 3000, 0.25, 0.40, 0.15, 0.30, 1.0, 2.0, 0.25, 0.04, 0.06, 0.5),
        ("automobile_garage", "Automobile & Garage", 1500, 5000, 0.20, 0.35, 0.10, 0.20, 0.6, 1.5, 0.25, 0.03, 0.05, 0.5),
        ("clothing_fashion", "Clothing & Fashion", 800, 3000, 0.10, 0.25, 0.20, 0.40, 2.0, 4.0, 0.25, 0.03, 0.05, 0.5),
        ("local_business", "General Local Business", 500, 2000, 0.20, 0.35, 0.10, 0.25, 1.0, 2.5, 0.30, 0.04, 0.06, 0.5),
    ]

    for v in seed_verticals:
        op.execute(f"""
        INSERT INTO vertical_profiles (
            id, vertical_key, label,
            aov_min, aov_max,
            p_call_to_order_min, p_call_to_order_max,
            p_direction_to_visit_min, p_direction_to_visit_max,
            directions_per_call_ratio_min, directions_per_call_ratio_max,
            max_loss_pct_of_benchmark_revenue,
            click_to_call_rate_min, click_to_call_rate_max,
            decay_k
        ) VALUES (
            gen_random_uuid()::text, '{v[0]}', '{v[1]}',
            {v[2]}, {v[3]},
            {v[4]}, {v[5]},
            {v[6]}, {v[7]},
            {v[8]}, {v[9]},
            {v[10]},
            {v[11]}, {v[12]},
            {v[13]}
        ) ON CONFLICT (vertical_key) DO NOTHING
        """)

    # 3. Create calibration_logs table
    op.execute("""
    CREATE TABLE IF NOT EXISTS calibration_logs (
        id VARCHAR(36) PRIMARY KEY,
        vertical_key VARCHAR(50) NOT NULL,
        parameter_name VARCHAR(100) NOT NULL,
        old_range_min FLOAT NOT NULL,
        old_range_max FLOAT NOT NULL,
        new_range_min FLOAT NOT NULL,
        new_range_max FLOAT NOT NULL,
        trials INTEGER NOT NULL,
        successes INTEGER NOT NULL,
        calibrated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
    )
    """)

    op.execute("""CREATE INDEX IF NOT EXISTS ix_calibration_logs_vertical_key ON calibration_logs(vertical_key)""")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS calibration_logs")
    op.execute("DROP TABLE IF EXISTS vertical_profiles")
