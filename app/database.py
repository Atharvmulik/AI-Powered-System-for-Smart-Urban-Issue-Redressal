# app/database.py
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

# Use PostgreSQL with asyncpg
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql+asyncpg://urban_user:urban_password@localhost:5432/urban_db"
)

# Create async engine
engine = create_async_engine(DATABASE_URL, echo=True)

# Session maker for async sessions
AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False
)

# Base class for models
Base = declarative_base()

# Dependency for FastAPI endpoints
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()