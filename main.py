# main.py
from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from jose import JWTError, jwt
from fastapi.security import OAuth2PasswordBearer
from app.ai_model import predict_category



# Import from our app
from app import models
from app.database import get_db, engine
from app.models import Report, User  
from app.schemas import UserCreate, UserResponse, UserLogin  
from app.auth_utils import get_password_hash, verify_password, create_access_token, SECRET_KEY, ALGORITHM  



oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# Create the database tables (in production, use Alembic migrations instead)
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Smart Urban Issue Redressal API", version="0.1.0")



# Add this function to verify tokens
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
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
    
    user = db.query(User).filter(User.email == email).first()
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
def read_root():
    return {"message": "Welcome to the Smart Urban Issue Redressal API"}

# Endpoint to get all reports
@app.get("/reports/", response_model=List[dict])
def read_reports(db: Session = Depends(get_db)):
    reports = db.query(Report).all()
    return reports

# main.py (modify the create_report endpoint)
@app.post("/reports/")
def create_report(
    title: str,
    description: str,
    location_lat: float,
    location_long: float,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # AI MAGIC: Predict the category automatically!
    predicted_category = predict_category(description)
    
    db_report = Report(
        title=title,
        description=description,
        category=predicted_category,  # Now using AI prediction!
        location_lat=location_lat,
        location_long=location_long,
        status="pending",
        user_id=current_user.id
    )
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    return {
        "message": "Report created successfully!",
        "report_id": db_report.id,
        "ai_predicted_category": predicted_category  # Return the AI result
    }

# --- NEW ENDPOINT 1: Get a single report by ID ---
@app.get("/reports/{report_id}")
def get_report(report_id: int, db: Session = Depends(get_db)):
    # Query the database for the report with the given ID
    db_report = db.query(Report).filter(Report.id == report_id).first()
    
    # If no report is found, raise a 404 error
    if db_report is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    # Return the found report
    return db_report

# --- NEW ENDPOINT 2: Update a report's status ---
@app.put("/reports/{report_id}")
def update_report_status(
    report_id: int, 
    new_status: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)  # ← CHANGE TO get_current_admin
):
    # Find the report
    db_report = db.query(Report).filter(Report.id == report_id).first()
    
    if db_report is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    # Update the status
    db_report.status = new_status
    db.commit()
    db.refresh(db_report)
    
    return {"message": f"Report {report_id} status updated to {new_status}", "report": db_report}

# --- NEW ENDPOINT 3: Delete a report ---
@app.delete("/reports/{report_id}")
def delete_report(
    report_id: int, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)  # ✅ Only admins can delete
):
    # Find the report
    db_report = db.query(Report).filter(Report.id == report_id).first()
    
    if db_report is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    # Delete the report
    db.delete(db_report)
    db.commit()
    
    return {"message": f"Report with ID {report_id} has been successfully deleted."}




# --- NEW: User Signup Endpoint ---
@app.post("/signup", response_model=UserResponse)
def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Hash the password
    hashed_password = get_password_hash(user_data.password)
    
    # Create new user
    new_user = User(
        email=user_data.email,
        hashed_password=hashed_password,
        full_name=user_data.full_name,
        is_admin=user_data.is_admin
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

# --- NEW: User Login Endpoint ---
@app.post("/login")
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    # Find the user by email
    user = db.query(User).filter(User.email == login_data.email).first()
    
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






# --- Get current user's profile ---
@app.get("/users/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """Get the profile of the currently logged-in user."""
    return current_user

# --- Get current user's reports ---
@app.get("/users/me/reports")
async def read_own_reports(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all reports created by the current user."""
    user_reports = db.query(Report).filter(Report.user_id == current_user.id).all()
    return user_reports

# --- Get all reports (Admin only) ---
@app.get("/admin/reports")
async def read_all_reports(
    current_user: User = Depends(get_current_admin),  # Only admins can access
    db: Session = Depends(get_db)
):
    """Get all reports from all users (Admin only)."""
    all_reports = db.query(Report).all()
    return all_reports





# from app.database import SessionLocal
# from app.models import User

# db = SessionLocal()
# users = db.query(User).all()
# for user in users:
#     print(f"ID: {user.id}, Email: {user.email}, Admin: {user.is_admin}")
