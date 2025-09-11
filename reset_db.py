# reset_db.py
from app.database import Base, engine
from app.models import User, Report

print("Dropping all tables...")
Base.metadata.drop_all(bind=engine)

print("Creating all tables...")
Base.metadata.create_all(bind=engine)

print("Database reset complete! All existing data has been deleted.")