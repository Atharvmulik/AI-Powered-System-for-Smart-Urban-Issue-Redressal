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
        
        print("🔄 Adding missing columns to reports table...")
        
        # Add missing columns
        await conn.execute("""
            ALTER TABLE reports 
            ADD COLUMN IF NOT EXISTS category VARCHAR(50),
            ADD COLUMN IF NOT EXISTS urgency_level VARCHAR(20),
            ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'Pending',
            ADD COLUMN IF NOT EXISTS distance FLOAT,
            ADD COLUMN IF NOT EXISTS assigned_department VARCHAR(100),
            ADD COLUMN IF NOT EXISTS resolution_notes TEXT,
            ADD COLUMN IF NOT EXISTS resolved_by VARCHAR(255),
            ADD COLUMN IF NOT EXISTS images TEXT,
            ADD COLUMN IF NOT EXISTS voice_note VARCHAR(500);
        """)
        
        # Set default values
        await conn.execute("""
            UPDATE reports SET category = 'Other' WHERE category IS NULL;
            UPDATE reports SET urgency_level = 'Medium' WHERE urgency_level IS NULL;
            UPDATE reports SET status = 'Pending' WHERE status IS NULL;
        """)
        
        # Make columns NOT NULL
        await conn.execute("""
            ALTER TABLE reports 
            ALTER COLUMN category SET NOT NULL,
            ALTER COLUMN urgency_level SET NOT NULL,
            ALTER COLUMN status SET NOT NULL;
        """)
        
        print("✅ Missing columns added successfully!")
        print("📊 Columns added:")
        print("   - category (VARCHAR(50), NOT NULL)")
        print("   - urgency_level (VARCHAR(20), NOT NULL)") 
        print("   - status (VARCHAR(20), NOT NULL, DEFAULT 'Pending')")
        print("   - distance (FLOAT)")
        print("   - assigned_department (VARCHAR(100))")
        print("   - resolution_notes (TEXT)")
        print("   - resolved_by (VARCHAR(255))")
        print("   - images (TEXT)")
        print("   - voice_note (VARCHAR(500))")
        
        await conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(fix_database())