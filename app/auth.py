from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas, utils, db
from datetime import timedelta

router = APIRouter(prefix="/auth", tags=["auth"])

def get_db():
    db_sess = db.SessionLocal()
    try:
        yield db_sess
    finally:
        db_sess.close()

@router.post("/register", response_model=schemas.Token)
def register(user: schemas.UserCreate, database: Session = Depends(get_db)):
    if database.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(status_code=400, detail="User already exists")
    hashed = utils.hash_password(user.password)
    new_user = models.User(username=user.username, hashed_password=hashed)
    database.add(new_user)
    database.commit()
    database.refresh(new_user)
    access_token = utils.create_access_token({"sub": new_user.username})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=schemas.Token)
def login(user: schemas.UserLogin, database: Session = Depends(get_db)):
    db_user = database.query(models.User).filter(models.User.username == user.username).first()
    if not db_user or not utils.verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    access_token = utils.create_access_token({"sub": db_user.username})
    return {"access_token": access_token, "token_type": "bearer"}
