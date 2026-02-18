from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import List


class Settings(BaseSettings):
    """Application settings."""
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://minber_user:minber_password@localhost:5432/minber_db"
    
    # Application
    ENVIRONMENT: str = "development"
    SECRET_KEY: str = "your-secret-key-change-in-production"
    DEBUG: bool = False
    PORT: int = 8000
    
    def model_post_init(self, __context):
        """Fix DATABASE_URL if it starts with postgres://"""
        if self.DATABASE_URL.startswith("postgres://"):
            self.DATABASE_URL = self.DATABASE_URL.replace("postgres://", "postgresql+asyncpg://", 1)
    
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
    DIYANET_BASE_URL: str = "https://diyanet.gov.tr"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
