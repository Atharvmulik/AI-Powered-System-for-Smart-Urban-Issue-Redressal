# app/schemas.py
from pydantic import BaseModel, EmailStr

# Schema for user creation (Sign Up)
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    is_admin: bool = False  # Default to False for safety

# Schema for what we return to the client (hiding the password)
class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    is_admin: bool

    class Config:
        from_attributes = True  # Allows ORM mode (works with SQLAlchemy models)

# Schema for user login
class UserLogin(BaseModel):
    email: EmailStr
    password: str
    is_admin: bool  # This is the key: the user selects their role