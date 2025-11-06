import os
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, timedelta
import random

# ---------- CONFIG ----------
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./database.db")

engine = sa.create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
    future=True,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
Base = declarative_base()

# ---------- MODELS ----------
class User(Base):
    __tablename__ = "users"
    id = sa.Column(sa.Integer, primary_key=True, index=True)
    phone = sa.Column(sa.String, unique=True, index=True, nullable=False)
    name = sa.Column(sa.String, nullable=True)
    role = sa.Column(sa.String, nullable=True)  # ASHA / Doctor / Volunteer / Community

class SymptomReport(Base):
    __tablename__ = "symptom_reports"
    id = sa.Column(sa.Integer, primary_key=True, index=True)
    reporter_phone = sa.Column(sa.String, nullable=True)  # optional
    patient_name = sa.Column(sa.String, nullable=True)
    village = sa.Column(sa.String, nullable=True)
    symptoms = sa.Column(sa.String, nullable=False)  # comma-separated
    created_at = sa.Column(sa.DateTime, default=datetime.utcnow, nullable=False)

class WaterReport(Base):
    __tablename__ = "water_reports"
    id = sa.Column(sa.Integer, primary_key=True, index=True)
    reporter_phone = sa.Column(sa.String, nullable=True)
    location = sa.Column(sa.String, nullable=True)
    ph = sa.Column(sa.String, nullable=True) # Changed from Float to String
    turbidity = sa.Column(sa.String, nullable=True)
    chlorine = sa.Column(sa.String, nullable=True)
    bacteria_present = sa.Column(sa.Boolean, nullable=True)
    quality = sa.Column(sa.String, nullable=True)
    created_at = sa.Column(sa.DateTime, default=datetime.utcnow, nullable=False)

class Alert(Base):
    __tablename__ = "alerts"
    id = sa.Column(sa.Integer, primary_key=True, index=True)
    message = sa.Column(sa.String, nullable=False)
    village = sa.Column(sa.String, nullable=True)
    level = sa.Column(sa.String, nullable=True)  # e.g. warning/critical
    created_at = sa.Column(sa.DateTime, default=datetime.utcnow, nullable=False)
    is_seen = sa.Column(sa.Boolean, default=False) # New field to track if alert is seen

Base.metadata.create_all(bind=engine)

# ---------- Pydantic Schemas ----------
class RegisterRequest(BaseModel):
    phone: str = Field(..., example="9876543210")
    name: Optional[str] = None
    role: Optional[str] = None

class LoginRequest(BaseModel):
    phone: str

class SymptomReportRequest(BaseModel):
    reporter_phone: Optional[str] = None
    patient_name: Optional[str] = None
    village: Optional[str] = None
    symptoms: List[str] = Field(..., example=["fever", "diarrhea"])

class WaterReportRequest(BaseModel):
    reporter_phone: Optional[str] = None
    location: Optional[str] = None
    ph: Optional[str] = None
    turbidity: Optional[str] = None
    chlorine: Optional[str] = None
    bacteria_present: Optional[bool] = None
    quality: Optional[str] = None

class OtpRequest(BaseModel):
    phone: str

class OtpVerificationRequest(BaseModel):
    phone: str
    otp: str

class UserUpdateRequest(BaseModel):
    name: str
    role: str

class ChatbotRequest(BaseModel):
    message: str

class AlertResponse(BaseModel):
    id: int
    message: str
    village: Optional[str]
    level: Optional[str]
    created_at: datetime
    is_seen: bool

# In-memory store for mock OTPs
otp_store = {}

app = FastAPI(title="JalSuraksha Backend - FastAPI")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ---------- User Endpoints (with mock OTP) ----------
@app.post("/register")
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == req.phone).first()
    if user:
        raise HTTPException(status_code=400, detail="Phone already registered")
    new = User(phone=req.phone, name=req.name, role=req.role)
    db.add(new)
    db.commit()
    db.refresh(new)
    return {"status": "ok", "user_id": new.id}

@app.post("/send-otp")
def send_otp(req: OtpRequest):
    otp = str(random.randint(1000, 9999))
    otp_store[req.phone] = otp
    print(f"DEBUG: OTP for {req.phone} is {otp}")
    return {"status": "ok"}

@app.post("/verify-otp")
def verify_otp(req: OtpVerificationRequest, db: Session = Depends(get_db)):
    stored_otp = otp_store.get(req.phone)
    if stored_otp and stored_otp == req.otp:
        del otp_store[req.phone]
        return {"status": "ok", "message": "OTP verified"}
    raise HTTPException(status_code=400, detail="Invalid OTP")

@app.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == req.phone).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not registered")
    return {"status": "ok", "user": {"id": user.id, "phone": user.phone, "name": user.name, "role": user.role}}

@app.put("/user/{user_id}")
def update_user(user_id: int, req: UserUpdateRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.name = req.name
    user.role = req.role
    db.commit()
    db.refresh(user)
    return {"status": "ok", "user": {"id": user.id, "phone": user.phone, "name": user.name, "role": user.role}}

# ---------- Reporting Endpoints ----------
@app.post("/report/symptom")
def report_symptom(payload: SymptomReportRequest, db: Session = Depends(get_db)):
    symptoms_text = ",".join(payload.symptoms)
    sr = SymptomReport(
        reporter_phone=payload.reporter_phone,
        patient_name=payload.patient_name,
        village=payload.village,
        symptoms=symptoms_text,
    )
    db.add(sr)
    db.commit()
    db.refresh(sr)

    try:
        if payload.village:
            since = datetime.utcnow() - timedelta(hours=48)
            count = db.query(SymptomReport).filter(
                SymptomReport.village == payload.village,
                SymptomReport.created_at >= since,
                SymptomReport.symptoms.ilike("%diarrhea%")
            ).count()
            if count >= 5:
                msg = f"Possible outbreak of diarrhea in {payload.village}"
                a = Alert(message=msg, village=payload.village, level="warning")
                db.add(a)
                db.commit()
    except Exception:
        pass

    return {"status": "ok", "report_id": sr.id}

@app.post("/report/water")
def report_water(payload: WaterReportRequest, db: Session = Depends(get_db)):
    wr = WaterReport(
        reporter_phone=payload.reporter_phone,
        location=payload.location,
        ph=payload.ph,
        turbidity=payload.turbidity,
        chlorine=payload.chlorine,
        bacteria_present=payload.bacteria_present,
        quality=payload.quality,
    )
    db.add(wr)
    db.commit()
    db.refresh(wr)

    try:
        if payload.bacteria_present or payload.ph == "Acidic (<6.5)" or payload.ph == "Alkaline (>8.5)":
            village = payload.location
            msg = f"Water contamination detected at {village}"
            a = Alert(message=msg, village=village, level="critical")
            db.add(a)
            db.commit()
    except Exception:
        pass

    return {"status": "ok", "water_report_id": wr.id}

# ---------- Query Endpoints ----------
@app.get("/alerts", response_model=List[AlertResponse])
def get_alerts(db: Session = Depends(get_db)):
    rows = db.query(Alert).order_by(Alert.created_at.desc()).limit(100).all()
    return [
        AlertResponse(
            id=r.id,
            message=r.message,
            village=r.village,
            level=r.level,
            created_at=r.created_at,
            is_seen=r.is_seen,
        ) for r in rows
    ]

@app.put("/alerts/mark-seen")
def mark_alerts_as_seen(db: Session = Depends(get_db)):
    db.query(Alert).filter(Alert.is_seen == False).update({"is_seen": True})
    db.commit()
    return {"status": "ok", "message": "All alerts marked as seen"}

@app.get("/alerts/unseen-count")
def get_unseen_alert_count(db: Session = Depends(get_db)):
    count = db.query(Alert).filter(Alert.is_seen == False).count()
    return {"count": count}

@app.get("/symptom-reports")
def get_symptom_reports(limit: int = 100, db: Session = Depends(get_db)):
    rows = db.query(SymptomReport).order_by(SymptomReport.created_at.desc()).limit(limit).all()
    return [
        {
            "id": r.id,
            "patient_name": r.patient_name,
            "village": r.village,
            "symptoms": r.symptoms.split(",") if r.symptoms else [],
            "created_at": r.created_at,
        } for r in rows
    ]

@app.get("/water-reports")
def get_water_reports(limit: int = 100, db: Session = Depends(get_db)):
    rows = db.query(WaterReport).order_by(WaterReport.created_at.desc()).limit(limit).all()
    return [
        {
            "id": r.id,
            "location": r.location,
            "ph": r.ph,
            "turbidity": r.turbidity,
            "chlorine": r.chlorine,
            "bacteria_present": r.bacteria_present,
            "quality": r.quality,
            "created_at": r.created_at,
        } for r in rows
    ]

@app.put("/report/water/{report_id}")
def update_water_report(report_id: int, payload: WaterReportRequest, db: Session = Depends(get_db)):
    report = db.query(WaterReport).filter(WaterReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    report.ph = payload.ph
    report.turbidity = payload.turbidity
    report.chlorine = payload.chlorine
    report.bacteria_present = payload.bacteria_present
    report.quality = payload.quality

    db.commit()
    db.refresh(report)
    return {"status": "ok", "water_report_id": report.id}

# ---------- Simple Prediction Endpoint ----------
@app.get("/predict-outbreak")
def predict_outbreak(village: Optional[str] = None, hours: int = 48, db: Session = Depends(get_db)):
    since = datetime.utcnow() - timedelta(hours=hours)
    diag_count = 0
    water_bad = 0
    if village:
        diag_count = db.query(SymptomReport).filter(
            SymptomReport.village == village,
            SymptomReport.created_at >= since,
            SymptomReport.symptoms.ilike("%diarrhea%")
        ).count()

        water_bad = db.query(WaterReport).filter(
            WaterReport.location == village,
            WaterReport.created_at >= since,
            sa.or_(WaterReport.bacteria_present == True,
                   WaterReport.ph == "Acidic (<6.5)",
                   WaterReport.ph == "Alkaline (>8.5)")
        ).count()
    else:
        diag_count = db.query(SymptomReport).filter(SymptomReport.created_at >= since,
                                                   SymptomReport.symptoms.ilike("%diarrhea%")).count()
        water_bad = db.query(WaterReport).filter(WaterReport.created_at >= since,
                                                sa.or_(WaterReport.bacteria_present == True,
                                                       WaterReport.ph == "Acidic (<6.5)",
                                                       WaterReport.ph == "Alkaline (>8.5)")).count()

    score = min(100, diag_count * 10 + water_bad * 20)
    level = "low"
    if score >= 60:
        level = "high"
    elif score >= 30:
        level = "medium"

    return {
        "village": village,
        "hours": hours,
        "diarrhea_reports": diag_count,
        "water_issues": water_bad,
        "risk_score": score,
        "risk_level": level,
    }

# ---------- Chatbot Endpoint ----------
@app.post("/chatbot")
def chatbot(req: ChatbotRequest):
    user_message = req.message.lower()
    if "hello" in user_message or "hi" in user_message:
        return {"response": "Namaste! Mai ek health assistant hoon. Aapki kya madad kar sakta hoon?"}
    elif "water" in user_message or "paani" in user_message:
        return {"response": "Safe water ke liye paani ubaal kar ya filter karke piyein."}
    elif "symptoms" in user_message or "diarrhea" in user_message:
        return {"response": "Diarrhea ya bukhaar ke symptoms hain to turant doctor se milein ya report karein."}
    else:
        return {"response": "Mai aapki query samajh nahi paya. Kya aap aur detail me bata sakte hain?"}

# ---------- Healthcheck ----------
@app.get("/")
def root():
    return {"status": "ok", "time": datetime.utcnow()}
