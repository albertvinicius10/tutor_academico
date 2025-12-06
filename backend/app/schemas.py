# app/schemas.py
from pydantic import BaseModel, computed_field, Field
from typing import List, Optional
from datetime import datetime

class UserCreate(BaseModel):
    username: str
    password: str = Field(..., min_length=8, max_length=72, description="A senha deve ter entre 8 e 72 caracteres.")

class UserLogin(BaseModel):
    username: str
    password: str = Field(..., max_length=72)

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
    messages: List[MessageSchema] = []
    @computed_field
    @property
    def last_message_at(self) -> Optional[datetime]:
        """Retorna o timestamp da última mensagem da conversa."""
        if not self.messages:
            return None
        return self.messages[-1].timestamp
    
    class Config:
        orm_mode = True


class RoadmapSchema(BaseModel):
    id: int
    main_topic: Optional[str] = None
    created_at: datetime
    content: dict 

    class Config:
        orm_mode = True