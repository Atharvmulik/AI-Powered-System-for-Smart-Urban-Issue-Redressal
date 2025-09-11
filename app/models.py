# app/models.py
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, Boolean, func, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    is_admin = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # NEW: Add relationship to reports (one user can have many reports)
    reports = relationship("Report", back_populates="owner")

class Report(Base):
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100), nullable=False)
    description = Column(Text)
    category = Column(String(50), index=True)
    location_lat = Column(Float)
    location_long = Column(Float)
    status = Column(String(20), default="pending", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # NEW: Add foreign key to link report to user
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # NEW: Add relationship to user
    owner = relationship("User", back_populates="reports")





# app/ai_model.py
# Sample training data - we'll use this to train our AI model
training_data = [
    {"text": "huge pothole on main road near hospital", "category": "pothole"},
    {"text": "garbage pile growing on street corner", "category": "garbage"},
    {"text": "street light not working for 3 days", "category": "broken_streetlight"},
    {"text": "water leakage from broken pipe", "category": "water_leakage"},
    {"text": "graffiti on public walls", "category": "graffiti"},
    {"text": "road damaged with cracks", "category": "road_damage"},
    {"text": "trash not collected for a week", "category": "garbage"},
    {"text": "broken traffic signal causing chaos", "category": "traffic_signal"},
    {"text": "deep pothole damaging vehicles", "category": "pothole"},
    {"text": "street light pole bent and dangerous", "category": "broken_streetlight"}
]

# This is a simple AI classifier (we'll improve it later)
def predict_category(text_description):
    """Simple rule-based classifier for now - we'll replace with real ML later"""
    text = text_description.lower()
    
    if "pothole" in text:
        return "pothole"
    elif "garbage" in text or "trash" in text:
        return "garbage"
    elif "street light" in text or "light" in text:
        return "broken_streetlight"
    elif "water" in text or "leak" in text:
        return "water_leakage"
    elif "graffiti" in text:
        return "graffiti"
    elif "road" in text or "crack" in text:
        return "road_damage"
    elif "traffic" in text or "signal" in text:
        return "traffic_signal"
    else:
        return "other"    