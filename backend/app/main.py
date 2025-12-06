from fastapi import FastAPI
from . import db, models
from .auth import router as auth_router
from .chat import router as chat_router
from .roadmap import router as roadmap_router
from .recommendations import router as recommendations_router # Importe o novo roteador

app = FastAPI(title="Tutor Acadêmico API")

models.Base.metadata.create_all(bind=db.engine)

app.include_router(auth_router)
app.include_router(chat_router)
app.include_router(roadmap_router)
app.include_router(recommendations_router) # Inclua o novo roteador

@app.get("/")
def root():
    return {"msg": "Tutor Acadêmico API is running"}
