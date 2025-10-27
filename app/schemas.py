from pydantic import BaseModel, EmailStr, validator
from typing import Optional, List
import re

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    mobile_number: str
    is_admin: bool = False

    @validator('password')
    def password_strength(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters long')
        return v

    @validator('full_name')
    def validate_full_name(cls, v):
        if not v or not v.strip():
            raise ValueError('Full name cannot be empty')
        if len(v) < 2:
            raise ValueError('Full name must be at least 2 characters long')
        if not re.match(r'^[a-zA-Z\s_]+$', v):
            raise ValueError('Full name can only contain letters, spaces and underscores')
        return v.strip()

    @validator('mobile_number')
    def validate_mobile_number(cls, v):
        if not re.match(r'^\d{10}$', v):
            raise ValueError('Mobile number must be exactly 10 digits')
        return v

    @validator('is_admin')
    def validate_admin_role(cls, v):
        if v:
            raise ValueError('Cannot self-assign admin role during signup')
        return v

# Schema for what we return to the client (hiding the password)
class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    mobile_number: str
    is_admin: bool

    class Config:
        from_attributes = True

# Schema for user login
class UserLogin(BaseModel):
    email: EmailStr
    password: str
    

    @validator('password')
    def password_not_empty(cls, v):
        if not v or len(v) < 1:
            raise ValueError('Password cannot be empty')
        return v

# ✅ UPDATED: ReportCreate schema with urgency_level
class ReportCreate(BaseModel):
    user_name: str
    user_mobile: str
    user_email: Optional[str] = None
    urgency_level: str  # ✅ CHANGED: issue_type → urgency_level
    title: str
    description: str
    location_lat: float  
    location_long: float  
    location_address: Optional[str] = None
    
    @validator('user_name')
    def validate_user_name(cls, v):
        if not v or not v.strip():
            raise ValueError('Full name cannot be empty')
        if len(v) < 2:
            raise ValueError('Full name must be at least 2 characters long')
        return v.strip()

    @validator('user_mobile')
    def validate_user_mobile(cls, v):
        if not re.match(r'^\d{10}$', v):
            raise ValueError('Mobile number must be exactly 10 digits')
        return v

    @validator('urgency_level')
    def validate_urgency_level(cls, v):
        valid_urgency_levels = ["High", "Medium", "Low"]
        if v not in valid_urgency_levels:
            raise ValueError(f'Urgency level must be one of: {", ".join(valid_urgency_levels)}')
        return v

    @validator('title')
    def validate_title(cls, v):
        if not v or not v.strip():
            raise ValueError('Title cannot be empty')
        if len(v) < 5:
            raise ValueError('Title must be at least 5 characters long')
        if len(v) > 100:
            raise ValueError('Title cannot exceed 100 characters')
        return v.strip()

    @validator('description')
    def validate_description(cls, v):
        if not v or not v.strip():
            raise ValueError('Description cannot be empty')
        if len(v) < 10:
            raise ValueError('Description must be at least 10 characters long')
        if len(v) > 1000:
            raise ValueError('Description cannot exceed 1000 characters')
        return v.strip()

    @validator('location_lat')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v

    @validator('location_long')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v

class ReportResponse(BaseModel):
    id: int
    user_name: str
    user_mobile: str
    user_email: Optional[str]
    urgency_level: str  # ✅ CHANGED: issue_type → urgency_level
    title: str
    description: str
    location_lat: float
    location_long: float
    location_address: Optional[str]
    images: Optional[str]
    voice_note: Optional[str]
    created_at: str
    updated_at: str
    category_name: Optional[str]
    status_name: Optional[str]
    user_id: Optional[int]

    class Config:
        from_attributes = True

class ReportCreateWithMedia(BaseModel):
    # User Information
    user_name: str
    user_mobile: str
    user_email: Optional[str] = None
    
    # Issue Information
    urgency_level: str  # ✅ CHANGED: issue_type → urgency_level
    title: str
    description: str
    
    # Location Information
    location_lat: float
    location_long: float
    location_address: Optional[str] = None
    
    # Media Information (file paths/URLs after upload)
    image_paths: Optional[List[str]] = None
    voice_note_path: Optional[str] = None

# Schema for status update
class StatusUpdate(BaseModel):
    new_status: str

    @validator('new_status')
    def validate_status(cls, v):
        valid_statuses = ["Reported", "In Progress", "Resolved", "Closed"]
        if v not in valid_statuses:
            raise ValueError(f'Status must be one of: {", ".join(valid_statuses)}')
        return v

# Schema for token response
class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user_id: int
    is_admin: bool
    full_name: str
    email: str
    message: str

# Schema for file upload response
class FileUploadResponse(BaseModel):
    filename: str
    file_url: str
    message: str

# ✅ ADDED: Schema for urgency levels response
class UrgencyLevelsResponse(BaseModel):
    urgency_levels: List[str]