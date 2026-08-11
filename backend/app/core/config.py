import os
from typing import List

from pydantic import field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "AASARA API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    ENVIRONMENT: str = "development"
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str
    DATABASE_URL: str

    GEMINI_API_KEY: str
    FIREBASE_CREDENTIALS_PATH: str = "firebase-adminsdk.json"

    CORS_ORIGINS: str = "*"

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def make_database_url_async(cls, value):
        if value:
            value = str(value)

            if value.startswith("postgres://"):
                value = value.replace(
                    "postgres://",
                    "postgresql+asyncpg://",
                    1
                )

            elif value.startswith("postgresql://"):
                value = value.replace(
                    "postgresql://",
                    "postgresql+asyncpg://",
                    1
                )

        return value

    @property
    def cors_origin_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
