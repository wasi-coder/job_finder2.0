from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import random
import uvicorn
from typing import List

from database import get_db, init_db, User, Verification, Job, JobApplication
from schemas import (
    UserCreate, UserLogin, UserResponse, Token,
    VerifyCode, ResendCode,
    JobCreate, JobResponse,
    JobApplicationCreate, JobApplicationResponse
)
from auth import (
    get_password_hash, verify_password, create_access_token,
    get_current_active_user
)

app = FastAPI(title="Job Finder API", version="1.0.0")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database on startup
@app.on_event("startup")
def startup_event():
    init_db()
    print("Database initialized successfully!")

# Utility Functions
def generate_verification_code() -> str:
    return str(random.randint(100000, 999999))

def send_verification_code(email: str, code: str):
    # TODO: Implement actual email sending (SendGrid, AWS SES, etc.)
    print(f"Sending verification code {code} to {email}")
    # For now, just print. In production, integrate with email service

# ==================== AUTH ROUTES ====================

@app.post("/api/register", response_model=dict, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(User).filter(
        (User.email == user_data.email) | (User.phone == user_data.phone)
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email or phone already exists"
        )
    
    # Validate that at least email or phone is provided
    if not user_data.email and not user_data.phone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either email or phone must be provided"
        )
    
    # Create new user
    new_user = User(
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        email=user_data.email,
        phone=user_data.phone,
        dob=user_data.dob,
        password_hash=get_password_hash(user_data.password)
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Generate verification code
    code = generate_verification_code()
    verification = Verification(
        user_id=new_user.id,
        code=code,
        expires_at=datetime.utcnow() + timedelta(minutes=10)
    )
    
    db.add(verification)
    db.commit()
    
    # Send verification code (email/SMS)
    if new_user.email:
        send_verification_code(new_user.email, code)
    
    return {
        "message": "User registered successfully",
        "user_id": new_user.id,
        "verification_code": code  # Remove in production!
    }

@app.post("/api/login", response_model=Token)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    # Find user by email or phone
    user = None
    if credentials.email:
        user = db.query(User).filter(User.email == credentials.email).first()
    elif credentials.phone:
        user = db.query(User).filter(User.phone == credentials.phone).first()
    
    if not user or not verify_password(credentials.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email/phone or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Check if user is verified
    if not user.verified:
        # Generate new verification code
        code = generate_verification_code()
        
        # Delete old verification codes
        db.query(Verification).filter(Verification.user_id == user.id).delete()
        
        verification = Verification(
            user_id=user.id,
            code=code,
            expires_at=datetime.utcnow() + timedelta(minutes=10)
        )
        db.add(verification)
        db.commit()
        
        if user.email:
            send_verification_code(user.email, code)
        
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "message": "User not verified",
                "user_id": user.id,
                "verification_code": code  # Remove in production!
            }
        )
    
    # Create access token
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserResponse.model_validate(user)
    }

@app.post("/api/verify", response_model=dict)
def verify_code(verify_data: VerifyCode, db: Session = Depends(get_db)):
    # Find verification record
    verification = db.query(Verification).filter(
        Verification.user_id == verify_data.user_id,
        Verification.code == verify_data.code,
        Verification.expires_at > datetime.utcnow()
    ).first()
    
    if not verification:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired verification code"
        )
    
    # Update user as verified
    user = db.query(User).filter(User.id == verify_data.user_id).first()
    user.verified = True
    
    # Delete verification record
    db.delete(verification)
    db.commit()
    
    # Create access token
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return {
        "message": "User verified successfully",
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserResponse.model_validate(user)
    }

@app.post("/api/resend-code", response_model=dict)
def resend_verification_code(resend_data: ResendCode, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == resend_data.user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Delete old verification codes
    db.query(Verification).filter(Verification.user_id == user.id).delete()
    
    # Generate new code
    code = generate_verification_code()
    verification = Verification(
        user_id=user.id,
        code=code,
        expires_at=datetime.utcnow() + timedelta(minutes=10)
    )
    
    db.add(verification)
    db.commit()
    
    if user.email:
        send_verification_code(user.email, code)
    
    return {
        "message": "Verification code resent",
        "verification_code": code  # Remove in production!
    }

# ==================== USER ROUTES ====================

@app.get("/api/users/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_active_user)):
    return current_user

@app.put("/api/users/me", response_model=UserResponse)
def update_current_user(
    user_update: UserCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    current_user.first_name = user_update.first_name
    current_user.last_name = user_update.last_name
    current_user.dob = user_update.dob
    
    db.commit()
    db.refresh(current_user)
    
    return current_user

# ==================== JOB ROUTES ====================

@app.get("/api/jobs", response_model=List[JobResponse])
def get_all_jobs(
    skip: int = 0,
    limit: int = 20,
    category: str = None,
    job_type: str = None,
    search: str = None,
    min_salary: int = None,
    max_salary: int = None,
    location: str = None,
    db: Session = Depends(get_db)
):
    query = db.query(Job).filter(Job.is_active == True)
    
    if category:
        query = query.filter(Job.category == category)
    
    if job_type:
        query = query.filter(Job.job_type == job_type)
    
    if search:
        search_filter = f"%{search}%"
        query = query.filter(
            (Job.position.ilike(search_filter)) |
            (Job.company_name.ilike(search_filter)) |
            (Job.description.ilike(search_filter))
        )
    
    if min_salary:
        query = query.filter(Job.salary_max >= min_salary)
    
    if max_salary:
        query = query.filter(Job.salary_min <= max_salary)
    
    if location:
        location_filter = f"%{location}%"
        query = query.filter(Job.location.ilike(location_filter))
    
    # Order by most recent first
    query = query.order_by(Job.created_at.desc())
    
    jobs = query.offset(skip).limit(limit).all()
    return jobs

@app.get("/api/jobs/{job_id}", response_model=JobResponse)
def get_job_by_id(job_id: int, db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id, Job.is_active == True).first()
    
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found"
        )
    
    return job

@app.post("/api/jobs", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
def create_job(
    job_data: JobCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # Check if user is an employer
    if current_user.user_type != "employer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only employers can create job listings"
        )
    
    # Add company name from the employer's profile
    job_dict = job_data.model_dump()
    job_dict["company_name"] = current_user.company_name or job_dict.get("company_name")
    
    new_job = Job(**job_dict)
    
    db.add(new_job)
    db.commit()
    db.refresh(new_job)
    
    return new_job

# ==================== JOB APPLICATION ROUTES ====================

@app.post("/api/applications", response_model=JobApplicationResponse, status_code=status.HTTP_201_CREATED)
def apply_for_job(
    application_data: JobApplicationCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # Check if user is an employee
    if current_user.user_type != "employee":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only employees can apply for jobs"
        )
    
    # Check if job exists
    job = db.query(Job).filter(Job.id == application_data.job_id).first()
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found"
        )
    
    # Check if already applied
    existing_application = db.query(JobApplication).filter(
        JobApplication.user_id == current_user.id,
        JobApplication.job_id == application_data.job_id
    ).first()
    
    if existing_application:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already applied for this job"
        )
    
    new_application = JobApplication(
        user_id=current_user.id,
        job_id=application_data.job_id
    )
    
    db.add(new_application)
    db.commit()
    db.refresh(new_application)
    
    return new_application

@app.get("/api/applications/me", response_model=List[JobApplicationResponse])
def get_my_applications(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    applications = db.query(JobApplication).filter(
        JobApplication.user_id == current_user.id
    ).all()
    
    return applications

# ==================== JOB METADATA ROUTES ====================

@app.get("/api/job-categories")
def get_job_categories():
    return [
        "Technology",
        "Healthcare",
        "Finance",
        "Education",
        "Marketing",
        "Sales",
        "Customer Service",
        "Administration",
        "Engineering",
        "Design",
        "Other"
    ]

@app.get("/api/job-types")
def get_job_types():
    return [
        "Full-time",
        "Part-time",
        "Contract",
        "Freelance",
        "Internship",
        "Remote"
    ]

# ==================== EMPLOYER ROUTES ====================

@app.get("/api/employer/jobs", response_model=List[JobResponse])
def get_employer_jobs(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.user_type != "employer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only employers can access this endpoint"
        )
    
    jobs = db.query(Job).filter(
        Job.company_name == current_user.company_name
    ).order_by(Job.created_at.desc()).all()
    
    return jobs

@app.get("/api/employer/applications/{job_id}", response_model=List[JobApplicationResponse])
def get_job_applications(
    job_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.user_type != "employer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only employers can access this endpoint"
        )
    
    # Check if job belongs to the employer
    job = db.query(Job).filter(
        Job.id == job_id,
        Job.company_name == current_user.company_name
    ).first()
    
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found or you don't have access to it"
        )
    
    applications = db.query(JobApplication).filter(
        JobApplication.job_id == job_id
    ).order_by(JobApplication.applied_at.desc()).all()
    
    return applications

@app.put("/api/employer/applications/{application_id}")
def update_application_status(
    application_id: int,
    status: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.user_type != "employer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only employers can update application status"
        )
    
    if status not in ["pending", "accepted", "rejected", "interviewing"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid status value"
        )
    
    application = db.query(JobApplication).filter(JobApplication.id == application_id).first()
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    # Check if job belongs to the employer
    job = db.query(Job).filter(
        Job.id == application.job_id,
        Job.company_name == current_user.company_name
    ).first()
    
    if not job:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this application"
        )
    
    application.status = status
    db.commit()
    
    return {"message": "Application status updated successfully"}

# ==================== HEALTH CHECK ====================

@app.get("/")
def health_check():
    return {"status": "healthy", "message": "Job Finder API is running"}

if __name__ == "__main__":
    
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)