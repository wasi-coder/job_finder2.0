from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import random
import uvicorn
import shutil
import os
from typing import List, Optional

# IMPORTS FROM YOUR MODULES
from database import get_db, init_db, User, Verification, Job, JobApplication, Message
from schemas import (
    UserCreate, UserLogin, UserResponse, Token,
    VerifyCode, ResendCode,
    JobCreate, JobResponse,
    JobApplicationCreate, JobApplicationResponse,
    MessageCreate, MessageResponse
)
from auth import (
    get_password_hash, verify_password, create_access_token,
    get_current_active_user
)

app = FastAPI(title="Job Finder API", version="1.0.0")

# 1. SETUP UPLOADS FOLDER & STATIC MOUNT
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# 2. CORS CONFIGURATION
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def startup_event():
    init_db()
    print("Database initialized successfully!")

# UTILITIES
def generate_verification_code() -> str:
    return str(random.randint(100000, 999999))

def send_verification_code(email: str, code: str):
    # TODO: Implement actual email sending (SendGrid, AWS SES, etc.)
    print(f"Sending verification code {code} to {email}")

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
        user_type=user_data.user_type, # Handle user_type
        company_name=user_data.company_name, # Handle company_name
        company_description=user_data.company_description,
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
                "verification_code": code 
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
    
    user = db.query(User).filter(User.id == verify_data.user_id).first()
    user.verified = True
    
    db.delete(verification)
    db.commit()
    
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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    db.query(Verification).filter(Verification.user_id == user.id).delete()
    
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
        "verification_code": code
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
    
    query = query.order_by(Job.created_at.desc())
    
    jobs = query.offset(skip).limit(limit).all()
    return jobs

@app.get("/api/jobs/{job_id}", response_model=JobResponse)
def get_job_by_id(job_id: int, db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id, Job.is_active == True).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    return job

@app.post("/api/jobs", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
def create_job(
    job_data: JobCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.user_type != "employer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only employers can create job listings"
        )
    
    job_dict = job_data.model_dump()
    # Use the employer's company name if not provided (or override it)
    job_dict["company_name"] = current_user.company_name or job_dict.get("company_name")
    
    new_job = Job(**job_dict)
    
    db.add(new_job)
    db.commit()
    db.refresh(new_job)
    
    return new_job

# --- NEW: CLOSE JOB ENDPOINT ---
@app.put("/api/jobs/{job_id}/close", response_model=JobResponse)
def close_job(
    job_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.user_type != "employer":
        raise HTTPException(status_code=403, detail="Only employers can close jobs")
    
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
        
    # Check if this employer owns the job
    if job.company_name != current_user.company_name:
         raise HTTPException(status_code=403, detail="You do not own this job")

    job.is_active = False # This hides it from the main list
    db.commit()
    db.refresh(job)
    return job

# ==================== JOB APPLICATION ROUTES ====================

@app.post("/api/applications", status_code=status.HTTP_201_CREATED)
def apply_for_job(
    job_id: int = Form(...),
    message: str = Form(None),
    linkedin: str = Form(None),
    github: str = Form(None),
    portfolio: str = Form(None),
    cv: UploadFile = File(None), # The PDF file
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.user_type != "employee":
        raise HTTPException(status_code=403, detail="Only employees can apply")
    
    # Check if job exists
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
        
    # Check duplicates
    existing = db.query(JobApplication).filter(
        JobApplication.user_id == current_user.id,
        JobApplication.job_id == job_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already applied")

    # Handle File Upload
    cv_path = None
    if cv:
        # Create a unique filename: user_1_job_5_cv.pdf
        filename = f"user_{current_user.id}_job_{job_id}_{cv.filename}"
        file_location = f"uploads/{filename}"
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(cv.file, buffer)
        cv_path = file_location

    new_application = JobApplication(
        user_id=current_user.id,
        job_id=job_id,
        cover_message=message,
        linkedin_url=linkedin,
        github_url=github,
        portfolio_url=portfolio,
        cv_file=cv_path
    )
    
    db.add(new_application)
    db.commit()
    db.refresh(new_application)
    
    return {"message": "Application submitted successfully", "id": new_application.id}

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
    return ["Technology", "Healthcare", "Finance", "Education", "Marketing", "Sales", "Engineering", "Design", "Other"]

@app.get("/api/job-types")
def get_job_types():
    return ["Full-time", "Part-time", "Contract", "Freelance", "Internship", "Remote"]

# ==================== EMPLOYER SPECIFIC ROUTES ====================

@app.get("/api/employer/jobs", response_model=List[JobResponse])
def get_employer_jobs(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.user_type != "employer":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only employers can access this")
    
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
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only employers can access this")
    
    job = db.query(Job).filter(
        Job.id == job_id,
        Job.company_name == current_user.company_name
    ).first()
    
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found or you don't have access"
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
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only employers can update status")
    
    application = db.query(JobApplication).filter(JobApplication.id == application_id).first()
    if not application:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")
    
    job = db.query(Job).filter(
        Job.id == application.job_id,
        Job.company_name == current_user.company_name
    ).first()
    
    if not job:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have access")
    
    application.status = status
    db.commit()
    
    return {"message": "Application status updated successfully"}

# ==================== NEW: MESSAGING & EMPLOYER DASHBOARD ROUTES ====================

@app.get("/api/employer/all-applications", response_model=List[JobApplicationResponse])
def get_all_employer_applications(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Fetch all applications for all jobs posted by the logged-in employer."""
    if current_user.user_type != "employer":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only employers can access this")

    # Get all jobs posted by this company
    jobs = db.query(Job).filter(Job.company_name == current_user.company_name).all()
    job_ids = [job.id for job in jobs]

    if not job_ids:
        return []

    # Get all applications for these jobs
    applications = db.query(JobApplication).filter(
        JobApplication.job_id.in_(job_ids)
    ).order_by(JobApplication.applied_at.desc()).all()

    return applications

@app.post("/api/messages", response_model=MessageResponse)
def send_message(
    application_id: int = Form(...),
    content: str = Form(None),
    file: UploadFile = File(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify application exists
    application = db.query(JobApplication).filter(JobApplication.id == application_id).first()
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")

    # Security check: Ensure the user is part of this application (applicant or employer)
    job = db.query(Job).filter(Job.id == application.job_id).first()
    
    is_applicant = (application.user_id == current_user.id)
    is_employer = (current_user.user_type == 'employer' and 
                   job.company_name == current_user.company_name)
    
    if not (is_applicant or is_employer):
        raise HTTPException(status_code=403, detail="Permission denied")

    # Handle File Upload
    attachment_path = None
    attachment_type = None
    
    if file:
        filename = f"chat_{application_id}_{int(datetime.utcnow().timestamp())}_{file.filename}"
        file_location = f"uploads/{filename}"
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        attachment_path = file_location
        
        # Simple type detection
        if filename.endswith(('.png', '.jpg', '.jpeg')):
            attachment_type = 'image'
        elif filename.endswith('.pdf'):
            attachment_type = 'pdf'
        else:
            attachment_type = 'file'

    new_msg = Message(
        application_id=application_id,
        sender_id=current_user.id,
        content=content or "",
        attachment_url=attachment_path,
        attachment_type=attachment_type
    )
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)
    return new_msg

@app.get("/api/applications/{application_id}/messages", response_model=List[MessageResponse])
def get_messages(
    application_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Retrieve chat history for a specific application."""
    # Check if application exists
    application = db.query(JobApplication).filter(JobApplication.id == application_id).first()
    if not application:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")

    # Security Check
    job = db.query(Job).filter(Job.id == application.job_id).first()
    is_applicant = (application.user_id == current_user.id)
    is_employer = (current_user.user_type == 'employer' and 
                   job.company_name == current_user.company_name)

    if not (is_applicant or is_employer):
         raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You do not have permission to view these messages")

    messages = db.query(Message).filter(
        Message.application_id == application_id
    ).order_by(Message.created_at.asc()).all()
    
    return messages

# ==================== HEALTH CHECK ====================

@app.get("/")
def health_check():
    return {"status": "healthy", "message": "Job Finder API is running"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)