from app.database import Base
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

class Confirmation(Base):
    __tablename__ = "confirmations"
    
    id = Column(Integer, primary_key=True, index=True)
    report_id = Column(Integer, ForeignKey("reports.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    confirmed_at = Column(DateTime, default=datetime.utcnow)

class ActivityLog(Base):
    __tablename__ = "activity_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    activity_type = Column(String)  # 'report_created', 'issue_resolved', 'confirmed'
    report_id = Column(Integer, ForeignKey("reports.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    description = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

from sqlalchemy import Column, Integer, String, Text, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime

class Report(Base):
    __tablename__ = "reports"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # User Information
    user_name = Column(String(255), nullable=False)  # Added length limit
    user_mobile = Column(String(15), nullable=False)  # Increased length for international numbers
    user_email = Column(String(255), nullable=True)   # Added length limit

    # Issue Information
    title = Column(String(255), nullable=False)       # Added length limit
    description = Column(Text, nullable=False)
    category = Column(String(50), nullable=False)     # Added length limit
    urgency_level = Column(String(20), nullable=False) # Added length limit
    
    # Status Information
    status = Column(String(20), default="Pending")    # Added length limit
    
    # Location Information
    location_lat = Column(Float, nullable=False)
    location_long = Column(Float, nullable=False)
    location_address = Column(Text, nullable=True)
    distance = Column(Float, nullable=True)  # Distance in km
    
    # Admin Assignment
    assigned_department = Column(String(100), nullable=True)  # Added length limit
    resolution_notes = Column(Text, nullable=True)
    resolved_by = Column(String(255), nullable=True)  # Added length limit
    
    # Media Files
    images = Column(Text, nullable=True)  # JSON string or comma-separated paths
    voice_note = Column(String(500), nullable=True)  # Added length limit for file path
    
    # Timestamps - Improved with server_default
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Foreign keys
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="reports")