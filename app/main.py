from fastapi import FastAPI
from . import db, models
from .auth import router as auth_router
from .chat import router as chat_router

app = FastAPI(title="Tutor Acadêmico API")

models.Base.metadata.create_all(bind=db.engine)

app.include_router(auth_router)
app.include_router(chat_router)

@app.get("/")
def root():
    return {"msg": "Tutor Acadêmico API is running"}
