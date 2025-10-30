# test_db_async.py
import sys
import os
import asyncio

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def test_db():
    try:
        from app.database import engine
        print("✅ Database engine imported successfully")
        print(f"Engine: {engine}")
        print(f"Engine URL: {engine.url}")
        
        # Test connection with async
        async with engine.begin() as conn:
            result = await conn.execute("SELECT version()")
            db_version = result.scalar()
            print(f"✅ PostgreSQL Version: {db_version}")
            
            # Check if reports table exists
            result = await conn.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'reports'
                );
            """)
            table_exists = result.scalar()
            print(f"✅ Reports table exists: {table_exists}")
            
        print("✅ All database tests passed!")
        
    except Exception as e:
        print(f"❌ Database error: {e}")
        print(f"Error type: {type(e).__name__}")

if __name__ == "__main__":
    asyncio.run(test_db())