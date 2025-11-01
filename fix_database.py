import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def fix_database():
    # Get database URL from environment or use default
    database_url = os.getenv('DATABASE_URL', 'postgresql+asyncpg://postgres:password@localhost:5432/urban_db')
    
    # Extract connection details
    if 'postgresql+asyncpg://' in database_url:
        database_url = database_url.replace('postgresql+asyncpg://', 'postgresql://')
    
    try:
        # Connect directly using asyncpg
        conn = await asyncpg.connect(database_url)
        
        print("🔄 Adding category_id and status_id columns to reports table...")
        
        # Add ONLY the two new columns
        await conn.execute("""
            ALTER TABLE reports 
            ADD COLUMN IF NOT EXISTS category_id INTEGER,
            ADD COLUMN IF NOT EXISTS status_id INTEGER;
        """)
        
        print("✅ category_id and status_id columns added successfully!")
        print("📊 Columns added:")
        print("   - category_id (INTEGER)")
        print("   - status_id (INTEGER)")
        
        await conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(fix_database())