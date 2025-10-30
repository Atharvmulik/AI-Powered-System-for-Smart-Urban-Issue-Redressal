import asyncio
from sqlalchemy import text
from main import engine  # Import your engine from main.py

async def add_missing_columns():
    try:
        async with engine.begin() as conn:
            print("🔄 Adding missing columns to reports table...")
            
            # Add the missing columns
            await conn.execute(text("""
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
            """))
            
            # Set default values for existing records
            await conn.execute(text("""
                UPDATE reports SET category = 'Other' WHERE category IS NULL;
                UPDATE reports SET urgency_level = 'Medium' WHERE urgency_level IS NULL;
                UPDATE reports SET status = 'Pending' WHERE status IS NULL;
            """))
            
            # Make columns NOT NULL after setting defaults
            await conn.execute(text("""
                ALTER TABLE reports 
                ALTER COLUMN category SET NOT NULL,
                ALTER COLUMN urgency_level SET NOT NULL,
                ALTER COLUMN status SET NOT NULL;
            """))
            
            await conn.commit()
            print("✅ Missing columns added successfully!")
            print("📊 Columns added: category, urgency_level, status, distance, assigned_department, resolution_notes, resolved_by, images, voice_note")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(add_missing_columns())