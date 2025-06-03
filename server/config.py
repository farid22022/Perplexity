# server/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    TAVILY_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    SECRET_KEY: str = "your-secret-key"  # Generate a secure key
    ALGORITHM: str = "HS256"