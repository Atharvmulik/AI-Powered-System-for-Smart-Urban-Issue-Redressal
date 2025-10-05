# In models.py
from app.database import Base  # Import Base from database
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    mobile_number = Column(String(10), unique=True, nullable=False)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    reports = relationship("Report", back_populates="user")

class Category(Base):
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    description = Column(Text)

class Status(Base):
    __tablename__ = "statuses"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    description = Column(Text)

class Report(Base):
    __tablename__ = "reports"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # User Information (for anonymous reports)
    user_name = Column(String, nullable=False)
    user_mobile = Column(String(10), nullable=False)
    user_email = Column(String, nullable=True)  # Optional
    
    # Issue Information
    issue_type = Column(String, nullable=False)  # Pothole, Garbage, Water Leak, etc.
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    
    # Location Information (Updated)
    location_lat = Column(Float, nullable=False)
    location_long = Column(Float, nullable=False)
    location_address = Column(Text, nullable=True)  # Human-readable address
    
    # Media Files
    images = Column(Text, nullable=True)  # Store as JSON string or comma-separated URLs
    voice_note = Column(String, nullable=True)  # Voice note URL
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Foreign keys
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # Optional for anonymous reports
    category_id = Column(Integer, ForeignKey("categories.id"))
    status_id = Column(Integer, ForeignKey("statuses.id"))
    
    # Relationships
    user = relationship("User", back_populates="reports")
    category = relationship("Category")
    status = relationship("Status")