# init_db.py
from app.database import engine, Base
from app.models import Report  # Import your models

print("Creating database tables...")
Base.metadata.create_all(bind=engine)
print("Tables created successfully!")