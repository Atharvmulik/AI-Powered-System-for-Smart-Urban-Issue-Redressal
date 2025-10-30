from fastapi import FastAPI, Depends, HTTPException, status, Query, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import and_, func
from typing import List, Optional
from pydantic import BaseModel, EmailStr, validator
import re
import json
from jose import JWTError, jwt
from datetime import datetime, timedelta, date
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
import math
from sqlalchemy.orm import selectinload

from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from app import models, schemas, database
from sqlalchemy.future import select

from app import models
from app.database import get_db, engine, AsyncSessionLocal
from app.models import Report, User, Category, Status
from app.schemas import UserCreate, UserResponse, UserLogin  
from app.auth_utils import get_password_hash, verify_password, create_access_token, SECRET_KEY, ALGORITHM    

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

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

# ✅ UPDATED: Report Creation Schema with Urgency Level
class ReportCreate(BaseModel):
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

@app.get("/")
async def read_root():
    return {"message": "Welcome to the Smart Urban Issue Redressal API"}

@app.post("/init-db")
async def initialize_database(db: AsyncSession = Depends(get_db)):
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
        
        # Create default statuses
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
        
        # Create default admin user
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

@app.get("/reports/", response_model=List[dict])
async def read_reports(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Number of records to return"),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Report).offset(skip).limit(limit))
    reports = result.scalars().all()
    return reports

# ✅ UPDATED: Report creation endpoint with urgency level
@app.post("/reports/")
async def create_report(
    report_data: ReportCreate,
    db: AsyncSession = Depends(get_db)
):
    try:
        # Validate location data
        if not report_data.location_lat or not report_data.location_long:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Location coordinates are required"
            )

        # Get or create a default category (since we removed issue_type)
        result = await db.execute(select(Category).filter(Category.name == "General"))
        category = result.scalar_one_or_none()
        if not category:
            category = Category(name="General", description="General issues category")
            db.add(category)
            await db.commit()
            await db.refresh(category)
        
        # Get the default status
        result = await db.execute(select(Status).filter(Status.name == "Reported"))
        status_obj = result.scalar_one_or_none()
        if not status_obj:
            status_obj = Status(name="Reported", description="Issue has been reported")
            db.add(status_obj)
            await db.commit()
            await db.refresh(status_obj)
        
        # Create report with urgency level
        db_report = Report(
            user_name=report_data.user_name,
            user_mobile=report_data.user_mobile,
            user_email=report_data.user_email,
            issue_type=report_data.urgency_level,  # Store urgency as issue_type for now
            title=report_data.title,
            description=report_data.description,
            location_lat=report_data.location_lat,
            location_long=report_data.location_long,
            location_address=report_data.location_address,
            category_id=category.id,
            status_id=status_obj.id,
        )
        
        db.add(db_report)
        await db.commit()
        await db.refresh(db_report)
        
        return {
            "message": "Report created successfully!",
            "report_id": db_report.id,
            "urgency_level": report_data.urgency_level,
            "location_provided": True
        }
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,  
            detail=f"Error creating report: {str(e)}"
        )

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

# ✅ UPDATED: Get urgency levels instead of issue types
@app.get("/urgency-levels")
async def get_urgency_levels():
    urgency_levels = ["High", "Medium", "Low"]
    return {"urgency_levels": urgency_levels}

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
    
    # Prevent self-assigning admin role
    if user_data.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot self-assign admin role during signup"
        )
    
    # Hash password
    hashed_password = get_password_hash(user_data.password)
    
    # Create new user
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

@app.post("/login")
async def login(login_data: UserLogin, db: AsyncSession = Depends(get_db)):
    # Find user by email
    result = await db.execute(select(User).filter(User.email == login_data.email))
    user = result.scalar_one_or_none()
    
    # Verify password
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Create access token
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



# some extra end points

@app.get("/dashboard/summary")
async def get_dashboard_summary(db: AsyncSession = Depends(get_db)):
    
    try:
        # Get total reports in system
        total_reports_result = await db.execute(select(func.count(Report.id)))
        total_reports_count = total_reports_result.scalar()

        # Get today's resolved issues count
        today = date.today()
        today_resolved_result = await db.execute(
            select(func.count(Report.id))
            .join(Status)
            .filter(Status.name == "Resolved")
            .filter(func.date(Report.updated_at) == today)
        )
        today_resolved_count = today_resolved_result.scalar()

        # Get recent reports (public)
        recent_reports_result = await db.execute(
            select(Report)
            .order_by(Report.created_at.desc())
            .limit(5)
        )
        recent_reports = recent_reports_result.scalars().all()

        return {
            "message": "Welcome to CivicEye - Make your city better today",
            "public_stats": {
                "total_reports": total_reports_count,
                "today_resolved": today_resolved_count,
                "active_issues": total_reports_count - today_resolved_count
            },
            "recent_reports": recent_reports
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching dashboard summary: {str(e)}"
        )

@app.get("/reports/nearby")
async def get_nearby_issues(
    lat: float = Query(..., description="User latitude"),
    long: float = Query(..., description="User longitude"),
    radius_km: float = Query(5.0, description="Search radius in km"),
    db: AsyncSession = Depends(get_db)
):

    try:
        # Haversine formula for distance calculation
        earth_radius_km = 6371
        
        # Calculate bounding box for initial filtering
        lat_range = radius_km / earth_radius_km * (180 / math.pi)
        long_range = radius_km / (earth_radius_km * math.cos(math.radians(lat))) * (180 / math.pi)
        
        min_lat = lat - lat_range
        max_lat = lat + lat_range
        min_long = long - long_range
        max_long = long + long_range
        
        # Get reports within bounding box (only unresolved issues)
        result = await db.execute(
            select(Report)
            .filter(
                and_(
                    Report.location_lat >= min_lat,
                    Report.location_lat <= max_lat,
                    Report.location_long >= min_long,
                    Report.location_long <= max_long
                )
            )
            .join(Status)
            .filter(Status.name.in_(["Reported", "In Progress"]))  # Only show active issues
        )
        nearby_reports = result.scalars().all()
        
        # Calculate exact distances and filter by radius
        reports_with_distance = []
        for report in nearby_reports:
            # Haversine distance calculation
            dlat = math.radians(report.location_lat - lat)
            dlong = math.radians(report.location_long - long)
            a = math.sin(dlat/2) * math.sin(dlat/2) + math.cos(math.radians(lat)) * math.cos(math.radians(report.location_lat)) * math.sin(dlong/2) * math.sin(dlong/2)
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
            distance = earth_radius_km * c
            
            if distance <= radius_km:
                report_data = {
                    "id": report.id,
                    "title": report.title,
                    "description": report.description,
                    "urgency_level": report.issue_type,
                    "category": report.category.name if report.category else "General",
                    "status": report.status.name if report.status else "Reported",
                    "location_lat": report.location_lat,
                    "location_long": report.location_long,
                    "location_address": report.location_address,
                    "created_at": report.created_at,
                    "distance_km": round(distance, 2)
                }
                reports_with_distance.append(report_data)
        
        return {
            "user_location": {"lat": lat, "long": long},
            "search_radius_km": radius_km,
            "nearby_issues_count": len(reports_with_distance),
            "nearby_issues": reports_with_distance
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching nearby issues: {str(e)}"
        )

@app.get("/reports/resolved/today")
async def get_todays_resolved_issues(db: AsyncSession = Depends(get_db)):
    
    try:
        today = date.today()
        
        # Get resolved reports from today
        result = await db.execute(
            select(Report)
            .join(Status)
            .filter(Status.name == "Resolved")
            .filter(func.date(Report.updated_at) == today)
        )
        resolved_reports = result.scalars().all()
        
        # Format response data
        formatted_reports = []
        for report in resolved_reports:
            report_data = {
                "id": report.id,
                "title": report.title,
                "description": report.description,
                "urgency_level": report.issue_type,
                "category": report.category.name if report.category else "General",
                "location_address": report.location_address,
                "resolved_at": report.updated_at
            }
            formatted_reports.append(report_data)
        
        # Get count by category
        category_count_result = await db.execute(
            select(Category.name, func.count(Report.id))
            .select_from(Report)
            .join(Category)
            .join(Status)
            .filter(Status.name == "Resolved")
            .filter(func.date(Report.updated_at) == today)
            .group_by(Category.name)
        )
        category_counts = category_count_result.all()
        
        return {
            "date": today.isoformat(),
            "total_resolved_today": len(resolved_reports),
            "resolved_issues": formatted_reports,
            "category_breakdown": [{"category": cat, "count": cnt} for cat, cnt in category_counts]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching today's resolved issues: {str(e)}"
        )

@app.get("/activity/today")
async def get_todays_activity(db: AsyncSession = Depends(get_db)):
    """
    Returns today's public activity feed (no auth required)
    """
    try:
        today = date.today()
        activities = []
        
        # Get new reports created today
        new_reports_result = await db.execute(
            select(Report)
            .filter(func.date(Report.created_at) == today)
            .order_by(Report.created_at.desc())
            .limit(10)
        )
        new_reports = new_reports_result.scalars().all()
        
        for report in new_reports:
            activities.append({
                "type": "new_report",
                "title": f"New {report.issue_type} issue reported",
                "description": report.title,
                "urgency": report.issue_type,
                "category": report.category.name if report.category else "General",
                "timestamp": report.created_at,
                "location": report.location_address
            })
        
        # Get issues resolved today
        resolved_reports_result = await db.execute(
            select(Report)
            .join(Status)
            .filter(Status.name == "Resolved")
            .filter(func.date(Report.updated_at) == today)
            .order_by(Report.updated_at.desc())
            .limit(10)
        )
        resolved_reports = resolved_reports_result.scalars().all()
        
        for report in resolved_reports:
            activities.append({
                "type": "issue_resolved", 
                "title": f"{report.issue_type} issue resolved",
                "description": f"'{report.title}' has been fixed",
                "category": report.category.name if report.category else "General",
                "timestamp": report.updated_at,
                "location": report.location_address
            })
        
        # Sort activities by timestamp
        activities.sort(key=lambda x: x["timestamp"], reverse=True)
        
        return {
            "date": today.isoformat(),
            "total_activities": len(activities),
            "activities": activities[:15]  # Return top 15 most recent
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching today's activity: {str(e)}"
        )

@app.get("/reports/{report_id}/confirmations")
async def get_issue_confirmations(
    report_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    Get confirmation count for an issue (public - no auth required)
    """
    try:
        report_result = await db.execute(select(Report).filter(Report.id == report_id))
        report = report_result.scalar_one_or_none()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Report with ID {report_id} not found"
            )
        
        confirmation_count = getattr(report, 'confirmation_count', 0)
        
        return {
            "report_id": report_id,
            "title": report.title,
            "confirmation_count": confirmation_count,
            "confirmed_by_citizens": confirmation_count
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching confirmations: {str(e)}"
        )

@app.get("/dashboard/stats")
async def get_dashboard_stats(db: AsyncSession = Depends(get_db)):
    """
    Returns public dashboard statistics (no auth required)
    """
    try:
        # Total reports count
        total_reports_result = await db.execute(select(func.count(Report.id)))
        total_reports = total_reports_result.scalar()
        
        # Resolved reports count
        resolved_reports_result = await db.execute(
            select(func.count(Report.id))
            .join(Status)
            .filter(Status.name == "Resolved")
        )
        resolved_reports = resolved_reports_result.scalar()
        
        # In progress reports count
        in_progress_result = await db.execute(
            select(func.count(Report.id))
            .join(Status)
            .filter(Status.name == "In Progress")
        )
        in_progress_reports = in_progress_result.scalar()
        
        # Category-wise counts
        category_stats_result = await db.execute(
            select(Category.name, func.count(Report.id))
            .select_from(Report)
            .join(Category)
            .group_by(Category.name)
        )
        category_stats = category_stats_result.all()
        
        # Urgency level counts
        urgency_stats_result = await db.execute(
            select(Report.issue_type, func.count(Report.id))
            .group_by(Report.issue_type)
        )
        urgency_stats = urgency_stats_result.all()
        
        return {
            "total_reports": total_reports,
            "resolved_reports": resolved_reports,
            "in_progress_reports": in_progress_reports,
            "resolution_rate": round((resolved_reports / total_reports * 100) if total_reports > 0 else 0, 1),
            "category_stats": [{"category": cat, "count": cnt} for cat, cnt in category_stats],
            "urgency_stats": [{"urgency": urg, "count": cnt} for urg, cnt in urgency_stats]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching dashboard stats: {str(e)}"
        )

@app.get("/reports/category-summary")
async def get_category_summary(db: AsyncSession = Depends(get_db)):
    """
    Returns count of issues per category (public - no auth required)
    """
    try:
        result = await db.execute(
            select(Category.name, Category.description, func.count(Report.id))
            .select_from(Report)
            .join(Category)
            .group_by(Category.name, Category.description)
        )
        category_summary = result.all()
        
        return {
            "category_summary": [
                {
                    "category_name": name,
                    "description": desc,
                    "issue_count": count
                }
                for name, desc, count in category_summary
            ]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching category summary: {str(e)}"
        )


@app.get("/users/reports/filtered")
async def get_user_reports_filtered(
    status_filter: str = Query("all", description="Filter by status: all, active, resolved"),
    user_email: str = Query(..., description="User email to filter reports"),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns user's reports with filtering and search capability
    For "My Complaints" page (2nd image) - Public access
    """
    try:
        # Start with base query and eager load relationships
        base_query = select(Report).options(
            selectinload(Report.category),
            selectinload(Report.status)
        ).filter(Report.user_email == user_email)
        
        # Apply status filter
        if status_filter == "active":
            base_query = base_query.join(Status).filter(Status.name.in_(["Reported", "In Progress"]))
        elif status_filter == "resolved":
            base_query = base_query.join(Status).filter(Status.name == "Resolved")
        
        # Order by latest first
        base_query = base_query.order_by(Report.created_at.desc())
        
        result = await db.execute(base_query)
        user_reports = result.scalars().all()
        
        # Format response for frontend
        formatted_reports = []
        for report in user_reports:
            report_data = {
                "id": report.id,
                "complaint_id": f"#{report.id:05d}",
                "title": report.title,
                "description": report.description,
                "date": report.created_at.strftime("%d %b. %I:%M %p"),
                "category": report.category.name if report.category else "General",
                "status": report.status.name if report.status else "Reported",
                "urgency_level": report.issue_type,
                "location_address": report.location_address,
                "user_name": report.user_name,
                "user_email": report.user_email
            }
            formatted_reports.append(report_data)
        
        return {
            "total_complaints": len(formatted_reports),
            "filter": status_filter,
            "user_email": user_email,
            "complaints": formatted_reports
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching user reports: {str(e)}"
        )


@app.get("/users/reports/search")
async def search_user_reports(
    query: str = Query(..., description="Search by complaint ID or text"),
    user_email: str = Query(..., description="User email to search reports"),
    db: AsyncSession = Depends(get_db)
):
    """
    Search user's reports by complaint ID or text
    For search functionality in "My Complaints" page - Public access
    """
    try:
        # Check if query is a complaint ID (format: #12345 or 12345)
        complaint_id = None
        if query.startswith('#'):
            try:
                complaint_id = int(query[1:])
            except ValueError:
                complaint_id = None
        else:
            try:
                complaint_id = int(query)
            except ValueError:
                complaint_id = None
        
        base_query = select(Report).options(
            selectinload(Report.category),
            selectinload(Report.status)
        ).filter(Report.user_email == user_email)
        
        if complaint_id:
            # Search by exact ID
            base_query = base_query.filter(Report.id == complaint_id)
        else:
            # Search by title or description
            search_term = f"%{query}%"
            base_query = base_query.filter(
                Report.title.ilike(search_term) | 
                Report.description.ilike(search_term)
            )
        
        base_query = base_query.order_by(Report.created_at.desc())
        
        result = await db.execute(base_query)
        search_results = result.scalars().all()
        
        formatted_results = []
        for report in search_results:
            report_data = {
                "id": report.id,
                "complaint_id": f"#{report.id:05d}",
                "title": report.title,
                "description": report.description,
                "date": report.created_at.strftime("%d %b. %I:%M %p"),
                "category": report.category.name if report.category else "General",
                "status": report.status.name if report.status else "Reported",
                "location_address": report.location_address,
                "user_name": report.user_name,
                "user_email": report.user_email
            }
            formatted_results.append(report_data)
        
        return {
            "search_query": query,
            "user_email": user_email,
            "results_count": len(formatted_results),
            "complaints": formatted_results
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error searching reports: {str(e)}"
        )

@app.get("/reports/{report_id}/timeline")
async def get_report_timeline(
    report_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    Returns detailed report information with timeline
    For individual complaint tracking page (3rd image) - Public access
    """
    try:
        # Get the report with eager loading of relationships
        result = await db.execute(
            select(Report)
            .options(
                selectinload(Report.category),
                selectinload(Report.status)
            )
            .filter(Report.id == report_id)
        )
        report = result.scalar_one_or_none()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Report with ID {report_id} not found"
            )
        
        # Build timeline events
        timeline_events = []
        
        # Event 1: Complaint Submitted
        timeline_events.append({
            "event": "Complaint Submitted",
            "description": f"Your complaint was submitted on {report.created_at.strftime('%d %b. %I:%M %p')}",
            "timestamp": report.created_at.isoformat(),
            "status": "completed"
        })
        
        # Event 2: Assigned to Department (simulate based on status)
        if report.status and report.status.name in ["In Progress", "Resolved", "Closed"]:
            assigned_time = report.created_at + timedelta(hours=2)
            timeline_events.append({
                "event": "Assigned to Department",
                "description": f"Assigned to {report.category.name if report.category else 'Public Works Department'}",
                "timestamp": assigned_time.isoformat(),
                "status": "completed"
            })
        
        # Event 3: Work in Progress
        if report.status and report.status.name in ["In Progress", "Resolved", "Closed"]:
            work_start_time = report.created_at + timedelta(hours=4)
            expected_resolution = report.created_at + timedelta(days=2)
            timeline_events.append({
                "event": "Work in Progress",
                "description": f"Work is in progress. Expected resolution: {expected_resolution.strftime('%d %b')}",
                "timestamp": work_start_time.isoformat(),
                "status": "completed" if report.status.name in ["Resolved", "Closed"] else "in_progress"
            })
        
        # Event 4: Resolved
        if report.status and report.status.name in ["Resolved", "Closed"]:
            resolved_time = report.updated_at if report.updated_at else report.created_at + timedelta(days=2)
            timeline_events.append({
                "event": "Resolved",
                "description": f"Issue resolved on {resolved_time.strftime('%d %b, %I:%M %p')}",
                "timestamp": resolved_time.isoformat(),
                "status": "completed"
            })
        
        # Sort timeline by timestamp
        timeline_events.sort(key=lambda x: x["timestamp"])
        
        # Prepare response data
        response_data = {
            "complaint_details": {
                "id": report.id,
                "complaint_id": f"#{report.id:05d}",
                "title": report.title,
                "description": report.description,
                "submitted_on": report.created_at.strftime("%d %b. %I:%M %p"),
                "category": report.category.name if report.category else "Road Maintenance",
                "department": "Public Works Department",
                "urgency_level": report.issue_type,
                "current_status": report.status.name if report.status else "Reported",
                "location_address": report.location_address,
                "location_lat": report.location_lat,
                "location_long": report.location_long,
                "user_name": report.user_name,
                "user_email": report.user_email
            },
            "timeline": timeline_events,
            "confirmation_count": getattr(report, 'confirmation_count', 0)
        }
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching report timeline: {str(e)}"
        )
    



# admin endpoints


@app.get("/api/admin/issues")
async def get_admin_issues(db: AsyncSession = Depends(get_db)):
    try:
        # Execute query using the session
        result = await db.execute(select(Report))
        issues = result.scalars().all()
        
        # Convert to list of dictionaries
        issues_list = []
        for issue in issues:
            issues_list.append({
                "id": issue.id,
                "user_name": issue.user_name,
                "user_email": issue.user_email,
                "user_mobile": issue.user_mobile,
                "title": issue.title,
                "description": issue.description,
                "category": issue.category,
                "urgency_level": issue.urgency_level,
                "status": issue.status,
                "location_address": issue.location_address,
                "assigned_department": issue.assigned_department,
                "resolution_notes": issue.resolution_notes,
                "images": issue.images,
                "created_at": issue.created_at.isoformat() if issue.created_at else None,
                "updated_at": issue.updated_at.isoformat() if issue.updated_at else None
            })
        
        return {"issues": issues_list}
        
    except Exception as e:
        print(f"Error fetching issues: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

# 2. Get Single Report Details
@app.get("/api/admin/issues/{report_id}", response_model=schemas.ReportResponse)
async def get_issue_details(report_id: int, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(
            select(models.Report).where(models.Report.id == report_id)
        )
        report = result.scalar_one_or_none()
        if not report:
            raise HTTPException(status_code=404, detail="Issue not found")
        return report
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# 3. Update Report Status - CORRECTED FOR STRING STATUS
@app.patch("/api/admin/issues/{report_id}/status")
async def update_issue_status(report_id: int, status_update: schemas.StatusUpdate, db: AsyncSession = Depends(get_db)):
    try:
        # Get the report
        result = await db.execute(
            select(models.Report).where(models.Report.id == report_id)
        )
        report = result.scalar_one_or_none()
        
        if not report:
            raise HTTPException(status_code=404, detail="Issue not found")
        
        # Update the status directly as string
        report.status = status_update.status
        report.updated_at = datetime.utcnow()
        
        # Commit the changes
        await db.commit()
        await db.refresh(report)
        
        return {"message": "Status updated successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# 4. Assign Report to Department - CORRECTED
@app.patch("/api/admin/issues/{report_id}/assign")
async def assign_to_department(report_id: int, assign_data: schemas.DepartmentAssign, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(
            select(models.Report).where(models.Report.id == report_id)
        )
        report = result.scalar_one_or_none()
        
        if not report:
            raise HTTPException(status_code=404, detail="Issue not found")
        
        report.assigned_department = assign_data.department
        report.updated_at = datetime.utcnow()
        
        await db.commit()
        await db.refresh(report)
        
        return {"message": "Issue assigned to department successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# 5. Delete Report - CORRECTED (no changes needed here)
@app.delete("/api/admin/issues/{report_id}")
async def delete_issue(report_id: int, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(
            select(models.Report).where(models.Report.id == report_id)
        )
        report = result.scalar_one_or_none()
        
        if not report:
            raise HTTPException(status_code=404, detail="Issue not found")
        
        await db.delete(report)
        await db.commit()
        
        return {"message": "Issue deleted successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# 6. Verify & Resolve Report - CORRECTED FOR STRING STATUS
@app.post("/api/admin/issues/{report_id}/resolve")
async def resolve_issue(report_id: int, resolve_data: schemas.ResolveIssue, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(
            select(models.Report).where(models.Report.id == report_id)
        )
        report = result.scalar_one_or_none()
        
        if not report:
            raise HTTPException(status_code=404, detail="Issue not found")
        
        # Update status to Resolved as string
        report.status = "Resolved"
        report.resolution_notes = resolve_data.resolution_notes
        report.resolved_by = resolve_data.resolved_by
        report.updated_at = datetime.utcnow()
        
        await db.commit()
        await db.refresh(report)
        
        return {"message": "Issue resolved successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# 7. Get All Departments - CORRECTED (no changes needed here)
@app.get("/api/admin/departments")
async def get_departments():
    departments = [
        {"id": 1, "name": "Public Works", "email": "publicworks@city.gov", "phone": "+1-555-0101", "head": "John Smith"},
        {"id": 2, "name": "Water Dept", "email": "waterdept@city.gov", "phone": "+1-555-0102", "head": "Sarah Johnson"},
        {"id": 3, "name": "Road Dept", "email": "roaddept@city.gov", "phone": "+1-555-0103", "head": "Mike Brown"},
        {"id": 4, "name": "Sanitation Dept", "email": "sanitation@city.gov", "phone": "+1-555-0104", "head": "Lisa Davis"},
        {"id": 5, "name": "Other", "email": "other@city.gov", "phone": "+1-555-0105", "head": "Admin"}
    ]
    return departments