import asyncio
from app.database import engine
from app.models import Base

async def update_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    print("Database tables updated!")

if __name__ == "__main__":
    asyncio.run(update_tables())