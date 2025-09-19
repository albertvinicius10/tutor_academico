# app/schemas.py
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class UserCreate(BaseModel):
    username: str
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class ChatRequest(BaseModel):
    conversation_id: Optional[int] = None
    question: str

class MessageSchema(BaseModel):
    sender: str
    content: str
    timestamp: datetime

    class Config:
        orm_mode = True

class ConversationSchema(BaseModel):
    id: int
    title: str
    messages: List[MessageSchema] = [] # Adicione a lista de mensagens aqui
    
    class Config:
        orm_mode = True