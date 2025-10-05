from fastapi import FastAPI, Depends, HTTPException, status, Query, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional
from pydantic import BaseModel, EmailStr, validator
import re
import json
from jose import JWTError, jwt
from datetime import datetime, timedelta
from fastapi.security import OAuth2PasswordBearer
from app.ai_model import predict_category
from fastapi.middleware.cors import CORSMiddleware

# Import from our app
from app import models
from app.database import get_db, engine, AsyncSessionLocal
from app.models import Report, User, Category, Status
from app.schemas import UserCreate, UserResponse, UserLogin  
from app.auth_utils import get_password_hash, verify_password, create_access_token, SECRET_KEY, ALGORITHM  

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# ✅ ADDED: Enhanced Pydantic models for validation
class UserCreateEnhanced(BaseModel):
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

class UserLoginEnhanced(BaseModel):
    email: EmailStr
    password: str
    is_admin: bool = False

# ✅ ADDED: New Report Creation Schema
class ReportCreate(BaseModel):
    # User Information
    user_name: str
    user_mobile: str
    user_email: Optional[str] = None
    
    # Issue Information
    issue_type: str
    title: str
    description: str
    
    # Location Information
    location_lat: float
    location_long: float
    location_address: Optional[str] = None
    
    # Validation
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

    @validator('issue_type')
    def validate_issue_type(cls, v):
        valid_issue_types = [
            "Pothole", "Garbage", "Water Leak", "Streetlight Issue", 
            "Stray Animals", "Traffic Signal", "Sewage Problem", 
            "Road Damage", "Tree Fallen", "Other"
        ]
        if v not in valid_issue_types:
            raise ValueError(f'Issue type must be one of: {", ".join(valid_issue_types)}')
        return v

    @validator('title')
    def validate_title(cls, v):
        if not v or not v.strip():
            raise ValueError('Title cannot be empty')
        if len(v) < 5:
            raise ValueError('Title must be at least 5 characters long')
        return v.strip()

    @validator('description')
    def validate_description(cls, v):
        if not v or not v.strip():
            raise ValueError('Description cannot be empty')
        if len(v) < 10:
            raise ValueError('Description must be at least 10 characters long')
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

app = FastAPI(title="Smart Urban Issue Redressal API", version="0.1.0")

@app.on_event("startup")
async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(models.Base.metadata.create_all)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add this function to verify tokens
async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        is_admin: bool = payload.get("is_admin")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    result = await db.execute(select(User).filter(User.email == email))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    return user

# Add this function to check if user is admin
async def get_current_admin(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to perform this action"
        )
    return current_user

# Basic health check endpoint
@app.get("/")
async def read_root():
    return {"message": "Welcome to the Smart Urban Issue Redressal API"}

# Database initialization endpoint
@app.post("/init-db")
async def initialize_database(db: AsyncSession = Depends(get_db)):
    """
    Initialize the database with default categories and statuses.
    This should only be run once when setting up the application.
    """
    try:
        # Create default categories if they don't exist
        categories = [
            Category(name="Infrastructure", description="Roads, bridges, public facilities"),
            Category(name="Sanitation", description="Waste management, cleanliness"),
            Category(name="Public Safety", description="Safety and security issues"),
            Category(name="Utilities", description="Water, electricity, gas services"),
            Category(name="Environment", description="Parks, pollution, green spaces"),
        ]
        
        for category in categories:
            result = await db.execute(select(Category).filter(Category.name == category.name))
            existing_category = result.scalar_one_or_none()
            if not existing_category:
                db.add(category)
        
        # Create default statuses if they don't exist
        statuses = [
            Status(name="Reported", description="Issue has been reported"),
            Status(name="In Progress", description="Issue is being addressed"),
            Status(name="Resolved", description="Issue has been resolved"),
            Status(name="Closed", description="Issue has been closed"),
        ]
        
        for status in statuses:
            result = await db.execute(select(Status).filter(Status.name == status.name))
            existing_status = result.scalar_one_or_none()
            if not existing_status:
                db.add(status)
        
        # Create admin user if it doesn't exist
        result = await db.execute(select(User).filter(User.email == "admin@urbanissues.com"))
        admin_user_exists = result.scalar_one_or_none()
        if not admin_user_exists:
            admin_user = User(
                email="admin@urbanissues.com",
                hashed_password=get_password_hash("admin123"),
                full_name="Administrator",
                mobile_number="1234567890",
                is_admin=True
            )
            db.add(admin_user)
        
        await db.commit()
        
        return {"message": "Database initialized successfully!", "admin_credentials": {"email": "admin@urbanissues.com", "password": "admin123"}}
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error initializing database: {str(e)}"
        )

# Endpoint to get all reports
@app.get("/reports/", response_model=List[dict])
async def read_reports(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Number of records to return"),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Report).offset(skip).limit(limit))
    reports = result.scalars().all()
    return reports

# ✅ FIXED: Remove authentication for anonymous report submission
@app.post("/reports/")
async def create_report(
    report_data: ReportCreate,
    db: AsyncSession = Depends(get_db)
    # ❌ REMOVED: current_user: User = Depends(get_current_user)
):
    try:
        # AI MAGIC: Predict the category automatically!
        predicted_category = predict_category(report_data.description)
        
        # Get or create the category
        result = await db.execute(select(Category).filter(Category.name == predicted_category))
        category = result.scalar_one_or_none()
        if not category:
            category = Category(name=predicted_category, description="AI-predicted category")
            db.add(category)
            await db.commit()
            await db.refresh(category)
        
        # Get the default status
        result = await db.execute(select(Status).filter(Status.name == "Reported"))
        status = result.scalar_one_or_none()
        if not status:
            status = Status(name="Reported", description="Issue has been reported")
            db.add(status)
            await db.commit()
            await db.refresh(status)
        
        # ✅ FIXED: Create report WITHOUT user_id for anonymous submission
        db_report = Report(
            # User Information (from form)
            user_name=report_data.user_name,
            user_mobile=report_data.user_mobile,
            user_email=report_data.user_email,
            
            # Issue Information
            issue_type=report_data.issue_type,
            title=report_data.title,
            description=report_data.description,
            
            # Location Information
            location_lat=report_data.location_lat,
            location_long=report_data.location_long,
            location_address=report_data.location_address,
            
            # Relationships
            category_id=category.id,
            status_id=status.id,
            # user_id is NULL for anonymous submissions
        )
        
        db.add(db_report)
        await db.commit()
        await db.refresh(db_report)
        
        return {
            "message": "Report created successfully!",
            "report_id": db_report.id,
            "ai_predicted_category": predicted_category,
            "issue_type": report_data.issue_type
        }
        
        # ✅ FIXED: Use status module, not Status model
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,  # ← status module
            detail=f"Error creating report: {str(e)}"
        )

# Get a single report by ID
@app.get("/reports/{report_id}")
async def get_report(
    report_id: int,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Report).filter(Report.id == report_id))
    db_report = result.scalar_one_or_none()
    
    if db_report is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    return db_report

# Update a report's status
@app.put("/reports/{report_id}")
async def update_report_status(
    report_id: int, 
    new_status: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    result = await db.execute(select(Report).filter(Report.id == report_id))
    db_report = result.scalar_one_or_none()
    
    if db_report is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    result = await db.execute(select(Status).filter(Status.name == new_status))
    status = result.scalar_one_or_none()
    if not status:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Status '{new_status}' is not valid"
        )
    
    db_report.status_id = status.id
    await db.commit()
    await db.refresh(db_report)
    
    return {"message": f"Report {report_id} status updated to {new_status}", "report": db_report}

# Delete a report
@app.delete("/reports/{report_id}")
async def delete_report(
    report_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    result = await db.execute(select(Report).filter(Report.id == report_id))
    db_report = result.scalar_one_or_none()
    
    if db_report is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    await db.delete(db_report)
    await db.commit()
    
    return {"message": f"Report with ID {report_id} has been successfully deleted."}

# ✅ NEW: Get available issue types
@app.get("/issue-types")
async def get_issue_types():
    """Get all available issue types for dropdown"""
    issue_types = [
        "Pothole", "Garbage", "Water Leak", "Streetlight Issue",
        "Stray Animals", "Traffic Signal", "Sewage Problem",
        "Road Damage", "Tree Fallen", "Other"
    ]
    return {"issue_types": issue_types}

# ✅ CORRECTED: User Signup Endpoint with mobile_number
@app.post("/signup", response_model=UserResponse)
async def signup(user_data: UserCreateEnhanced, db: AsyncSession = Depends(get_db)):
    # Check if user already exists
    result = await db.execute(select(User).filter(User.email == user_data.email))
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Check if mobile number already exists
    result = await db.execute(select(User).filter(User.mobile_number == user_data.mobile_number))
    existing_mobile = result.scalar_one_or_none()
    if existing_mobile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already registered"
        )
    
    # SECURITY: Prevent regular users from creating admin accounts
    if user_data.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot self-assign admin role during signup"
        )
    
    # Hash the password
    hashed_password = get_password_hash(user_data.password)
    
    # ✅ FIXED: Create new user WITH mobile_number
    new_user = User(
        email=user_data.email,
        hashed_password=hashed_password,
        full_name=user_data.full_name,
        mobile_number=user_data.mobile_number,
        is_admin=False
    )
    
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return new_user

# User Login Endpoint
@app.post("/login")
async def login(login_data: UserLogin, db: AsyncSession = Depends(get_db)):
    # Find the user by email
    result = await db.execute(select(User).filter(User.email == login_data.email))
    user = result.scalar_one_or_none()
    
    # Check if user exists and password is correct
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Check if the selected role matches the user's actual role
    if user.is_admin != login_data.is_admin:
        if login_data.is_admin:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Admin access denied for this user"
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User access denied for this admin"
            )
    
    # Create JWT token
    access_token = create_access_token(
        data={"sub": user.email, "is_admin": user.is_admin}
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "is_admin": user.is_admin,
        "message": "Login successful! Redirecting to dashboard..."
    }

# Get current user's profile
@app.get("/users/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user

# Get current user's reports
@app.get("/users/me/reports")
async def read_own_reports(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Report).filter(Report.user_id == current_user.id))
    user_reports = result.scalars().all()
    return user_reports

# Get all reports (Admin only)
@app.get("/admin/reports")
async def read_all_reports(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Report))
    all_reports = result.scalars().all()
    return all_reports

# Get all categories
@app.get("/categories")
async def get_categories(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Category))
    categories = result.scalars().all()
    return categories

# Get all statuses
@app.get("/statuses")
async def get_statuses(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Status))
    statuses = result.scalars().all()
    return statuses