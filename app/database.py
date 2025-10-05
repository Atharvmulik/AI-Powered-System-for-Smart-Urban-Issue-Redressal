# app/database.py - PROPER ASYNC VERSION
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from typing import AsyncGenerator

load_dotenv()

# Use PostgreSQL with asyncpg - CORRECT FORMAT
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql+asyncpg://urban_user:urban_password@localhost:5432/urban_db"
)

# Create async engine
engine = create_async_engine(DATABASE_URL, echo=True)

# Async session maker
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False
)

# Base class for models
Base = declarative_base()

# Async dependency for FastAPI endpoints
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()