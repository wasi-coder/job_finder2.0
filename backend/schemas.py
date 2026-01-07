from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    first_name: str
    last_name: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    dob: Optional[str] = None
    user_type: str = "employee"  # 'employer' or 'employee'
    company_name: Optional[str] = None  # For employers
    company_description: Optional[str] = None  # For employers

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)

class UserLogin(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    password: str

class UserResponse(UserBase):
    id: int
    verified: bool
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class VerifyCode(BaseModel):
    user_id: int
    code: str

class ResendCode(BaseModel):
    user_id: int

class JobBase(BaseModel):
    company_name: str
    position: str
    location: str
    salary_min: Optional[int] = None
    salary_max: Optional[int] = None
    job_type: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    requirements: Optional[str] = None

class JobCreate(JobBase):
    pass

class JobResponse(JobBase):
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class JobApplicationCreate(BaseModel):
    job_id: int

class JobApplicationResponse(BaseModel):
    id: int
    user_id: int
    job_id: int
    status: str
    applied_at: datetime
    
    class Config:
        from_attributes = True