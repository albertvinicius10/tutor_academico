# app/chat.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from fastapi.security import HTTPBearer
from typing import List, Optional

from . import db, models, schemas, config, utils
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.memory import ConversationBufferWindowMemory
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings

# --- Configuração do RAG ---
CHROMA_DB_PATH = "chroma_db"
router = APIRouter(prefix="/chat", tags=["chat"])
security = HTTPBearer()

def get_db():
    db_sess = db.SessionLocal()
    try:
        yield db_sess
    finally:
        db_sess.close()

get_current_user = utils.get_current_user

class ChatRequest(schemas.BaseModel):
    conversation_id: Optional[int] = None
    question: str
    provider: Optional[str] = config.DEFAULT_LLM_PROVIDER

@router.post("/", response_model=schemas.MessageSchema)
def chat(request: ChatRequest, current_user: models.User = Depends(get_current_user), database: Session = Depends(get_db)):
    is_new_conversation = False
    if request.conversation_id:
        conv = database.query(models.Conversation).filter(
            models.Conversation.id == request.conversation_id,
            models.Conversation.user_id == current_user.id
        ).first()
        if not conv:
            raise HTTPException(status_code=404, detail="Conversation not found")
    else:
        is_new_conversation = True
        conv = models.Conversation(user_id=current_user.id)
        database.add(conv)
        database.commit()
        database.refresh(conv)

    # 1. Carregar o Vector Store e criar o retriever
    embedding_function = HuggingFaceEmbeddings(
        model_name="paraphrase-multilingual-MiniLM-L12-v2",
        model_kwargs={'device': 'cpu'}
    )
    vector_store = Chroma(persist_directory=CHROMA_DB_PATH, embedding_function=embedding_function)
    retriever = vector_store.as_retriever(search_kwargs={"k": 3}) # Busca os 3 chunks mais relevantes

    # 2. Buscar histórico da conversa no banco de dados para a memória
    messages_from_db = database.query(models.Message).filter(
        models.Message.conversation_id == conv.id
    ).order_by(models.Message.timestamp).all()

    # 3. Inicializar o LLM
    try:
        llm = utils.get_llm(request.provider)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # 4. Criar o prompt para o RAG
    # Este prompt instrui o LLM a usar o contexto (retrieved documents) e o histórico do chat.
    rag_prompt = ChatPromptTemplate.from_messages([
        ("system", "Você é um tutor acadêmico. Responda a pergunta do usuário com base no contexto fornecido e no histórico da conversa. Priorize as informações do contexto. Se o contexto estiver vazio ou não contiver a resposta, use seu conhecimento geral para responder à pergunta.\n\nContexto:\n{context}"),
        MessagesPlaceholder(variable_name="chat_history"),
        ("human", "{input}"),
    ])

    # 5. Criar a cadeia RAG
    # Esta cadeia primeiro passa o contexto e a pergunta para o LLM
    question_answer_chain = create_stuff_documents_chain(llm, rag_prompt)
    # A cadeia completa que primeiro busca documentos (retrieval) e depois chama a cadeia acima
    rag_chain = create_retrieval_chain(retriever, question_answer_chain)

    # 6. Preparar o histórico para a cadeia
    chat_history = []
    for msg in messages_from_db:
        if msg.sender == "user":
            chat_history.append(("human", msg.content))
        else:
            chat_history.append(("ai", msg.content))

    # 7. Salvar a nova pergunta do usuário no banco
    user_msg = models.Message(conversation_id=conv.id, sender="user", content=request.question)
    database.add(user_msg)

    # 8. Invocar a cadeia RAG para gerar a resposta
    response = rag_chain.invoke({"input": request.question, "chat_history": chat_history})
    ai_msg = models.Message(conversation_id=conv.id, sender="assistant", content=response["answer"])
    database.add(ai_msg)

    if is_new_conversation:
        title_prompt = f"Gere um título curto e conciso (máximo 5 palavras) para uma conversa que começa com a pergunta: '{request.question}'. Responda apenas com o título."
        title_response = llm.invoke(title_prompt)
        conv.title = title_response.content.strip().strip('"')
        database.add(conv)
    
    database.commit()
    database.refresh(ai_msg)

    return ai_msg

@router.get("/conversations", response_model=List[schemas.ConversationSchema])
def get_conversations(current_user: models.User = Depends(get_current_user), database: Session = Depends(get_db)):
    conversations = database.query(models.Conversation).filter(
        models.Conversation.user_id == current_user.id
    ).order_by(models.Conversation.id.desc()).all()
    return conversations

@router.get("/{conversation_id}", response_model=schemas.ConversationSchema)
def get_conversation(conversation_id: int, current_user: models.User = Depends(get_current_user), database: Session = Depends(get_db)):
    conv = database.query(models.Conversation).filter(
        models.Conversation.id == conversation_id,
        models.Conversation.user_id == current_user.id
    ).first()
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    conv.messages.sort(key=lambda m: m.timestamp)
    return conv