# app/chat.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from fastapi.security import HTTPBearer
from typing import List, Optional


from . import db, models, schemas, config, utils # Importe utils aqui para o get_current_user
from langchain.chains import ConversationChain
from langchain.memory import ConversationBufferMemory

router = APIRouter(prefix="/chat", tags=["chat"])
security = HTTPBearer()

def get_db():
    db_sess = db.SessionLocal()
    try:
        yield db_sess
    finally:
        db_sess.close()

# Reutilize a função de utils.py
get_current_user = utils.get_current_user

# Remova as variáveis globais llm, memory e conversation
# Elas serão criadas dentro de cada requisição
class ChatRequest(schemas.BaseModel):
    conversation_id: Optional[int] = None
    question: str
    provider: Optional[str] = config.DEFAULT_LLM_PROVIDER # Novo campo

@router.post("/", response_model=schemas.MessageSchema)
def chat(request: ChatRequest, current_user: models.User = Depends(get_current_user), database: Session = Depends(get_db)):
    if request.conversation_id:
        conv = database.query(models.Conversation).filter(
            models.Conversation.id == request.conversation_id,
            models.Conversation.user_id == current_user.id
        ).first()
        if not conv:
            raise HTTPException(status_code=404, detail="Conversation not found")
    else:
        conv = models.Conversation(user_id=current_user.id)
        database.add(conv)
        database.commit()
        database.refresh(conv)

    # Buscar histórico da conversa no banco de dados
    messages_from_db = database.query(models.Message).filter(
        models.Message.conversation_id == conv.id
    ).order_by(models.Message.timestamp).all()

    # Criar uma memória para a conversa atual e carregar o histórico
    memory = ConversationBufferMemory(return_messages=True)
    for msg in messages_from_db:
        if msg.sender == "user":
            memory.chat_memory.add_user_message(msg.content)
        else:
            memory.chat_memory.add_ai_message(msg.content)

    # Inicializar o LLM com base no provedor escolhido
    try:
        llm = utils.get_llm(request.provider)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
        
    conversation = ConversationChain(llm=llm, memory=memory)

    # Salvar a nova pergunta do usuário
    user_msg = models.Message(conversation_id=conv.id, sender="user", content=request.question)
    database.add(user_msg)

    # Gerar a resposta com o LLM
    response = conversation.predict(input=request.question)
    ai_msg = models.Message(conversation_id=conv.id, sender="assistant", content=response)
    database.add(ai_msg)
    
    database.commit()
    database.refresh(ai_msg)

    return ai_msg

# Novo endpoint para listar as conversas do usuário
@router.get("/conversations", response_model=List[schemas.ConversationSchema])
def get_conversations(current_user: models.User = Depends(get_current_user), database: Session = Depends(get_db)):
    conversations = database.query(models.Conversation).filter(
        models.Conversation.user_id == current_user.id
    ).all()
    return conversations

# Novo endpoint para listar as mensagens de uma conversa específica
@router.get("/{conversation_id}", response_model=schemas.ConversationSchema)
def get_conversation(conversation_id: int, current_user: models.User = Depends(get_current_user), database: Session = Depends(get_db)):
    conv = database.query(models.Conversation).filter(
        models.Conversation.id == conversation_id,
        models.Conversation.user_id == current_user.id
    ).first()
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return conv