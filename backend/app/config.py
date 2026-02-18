from pydantic_settings import BaseSettings
from pydantic import field_validator
from functools import lru_cache
from typing import List


class Settings(BaseSettings):
    """Application settings."""
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://minber_user:minber_password@localhost:5432/minber_db"
    
    @field_validator('DATABASE_URL')
    @classmethod
    def fix_database_url(cls, v: str) -> str:
        """Fix DATABASE_URL if it starts with postgres:// (Railway format)"""
        if v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql+asyncpg://", 1)
        elif v.startswith("postgresql://"):
            return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v
    
    # Application
    ENVIRONMENT: str = "development"
    SECRET_KEY: str = "your-secret-key-change-in-production"
    DEBUG: bool = False
    PORT: int = 8000
    
    # API
    API_V1_PREFIX: str = "/api/v1"
    PROJECT_NAME: str = "Minber API"
    VERSION: str = "1.0.0"
    
    # CORS
    ALLOWED_ORIGINS: str = "*"
    
    @property
    def allowed_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
    
    # Scraper
    SCRAPER_ENABLED: bool = True
    DIYANET_BASE_URL: str = "https://dinhizmetleri.diyanet.gov.tr"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()