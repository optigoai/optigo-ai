# ==================================================
# OptigoAI Backend — Configuration
# ==================================================
"""
Application settings loaded from environment variables.
Never hardcode secrets — use .env file.
"""

from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator


class Settings(BaseSettings):
    """Application configuration from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ---- Application ----
    app_name: str = "OptigoAI"
    app_env: str = "development"
    debug: bool = True
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    frontend_url: str = "http://localhost:3000"

    # ---- Database ----
    database_url: str = "postgresql+asyncpg://optigoai:optigoai_dev_password@db:5432/optigoai"
    database_url_sync: str = "postgresql://optigoai:optigoai_dev_password@db:5432/optigoai"

    # ---- Redis ----
    redis_url: str = "redis://redis:6379/0"
    celery_broker_url: str = "redis://redis:6379/1"
    celery_result_backend: str = "redis://redis:6379/2"

    # ---- JWT Authentication ----
    jwt_secret_key: str = "CHANGE_ME_GENERATE_A_STRONG_SECRET"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080  # 7 days for mobile session stability
    refresh_token_expire_days: int = 30

    # ---- AI Provider ----
    ai_provider: str = "gemini"
    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.5-flash-lite"

    # ---- Google OAuth & Search Console ----
    google_client_id: str = ""
    google_client_secret: str = ""
    google_redirect_uri: str = "http://localhost:8000/api/v1/integrations/google/search-console/callback"
    google_token_encryption_key: str = "OPTIGOAI_SECRET_KEY_FOR_OAUTH_TOKEN_ENCRYPTION_32B"

    # ---- SEO & SERP Providers ----
    seo_provider: str = "dataforseo"  # dataforseo, serper, serpapi
    dataforseo_login: str = ""
    dataforseo_password: str = ""
    serper_api_key: str = ""
    serpapi_api_key: str = ""

    # ---- Website Crawler & Intelligence ----
    website_crawler_provider: str = "firecrawl"  # firecrawl, beautifulsoup, playwright
    firecrawl_api_key: str = ""
    crawler_max_pages: int = 10
    crawler_timeout_seconds: int = 30
    crawler_max_response_size_bytes: int = 5242880  # 5 MB

    # ---- Storage ----
    storage_provider: str = "local"
    gcs_bucket_name: str = ""
    gcs_project_id: str = ""
    google_application_credentials: str = ""
    local_storage_path: str = "./uploads"

    # ---- CORS ----
    cors_origins: str = '["http://localhost:3000","http://localhost:8080","http://localhost:5173"]'

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: str) -> str:
        return v

    @property
    def cors_origins_list(self) -> List[str]:
        import json
        try:
            return json.loads(self.cors_origins)
        except (json.JSONDecodeError, TypeError):
            return ["http://localhost:3000"]

    # ---- Admin ----
    admin_email: str = "admin@optigoai.com"
    admin_default_password: str = "CHANGE_ME_ON_FIRST_LOGIN"

    # ---- Rate Limiting ----
    rate_limit_per_minute: int = 60

    # ---- Logging ----
    log_level: str = "INFO"

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def is_development(self) -> bool:
        return self.app_env == "development"


# Singleton settings instance
settings = Settings()
