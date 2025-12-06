# app/recommendations.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
import json
from sqlalchemy.orm import Session

from . import utils, models, schemas, config, cache
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from redis import Redis
from langchain.prompts import PromptTemplate
from langchain_core.output_parsers import JsonOutputParser

router = APIRouter(prefix="/recommendations", tags=["recommendations"])

# --- Pydantic Schemas ---

class VideoRequest(schemas.BaseModel):
    topic: str
    max_results: int = 5

class VideoInfo(schemas.BaseModel):
    title: str
    video_id: str
    url: str
    thumbnail_url: str

class VideoRecommendationResponse(schemas.BaseModel):
    search_topic: str
    videos: List[VideoInfo]

class ForYouResponse(schemas.BaseModel):
    suggested_topic: str
    reasoning: str
    recommended_video: Optional[VideoInfo] = None


# --- API Endpoint ---

@router.post("/videos", response_model=VideoRecommendationResponse)
def get_video_recommendations(
    request: VideoRequest,
    current_user: models.User = Depends(utils.get_current_user),
    rd: Redis = Depends(cache.get_cache)
):
    if not config.YOUTUBE_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="YouTube API key is not configured on the server."
        )

    # 1. Tentar buscar do cache primeiro
    cache_key = f"youtube_search:{request.topic}:{request.max_results}"
    cached_result = rd.get(cache_key)
    if cached_result:
        # Se encontrou no cache, desserializa o JSON e retorna
        return VideoRecommendationResponse(**json.loads(cached_result))

    # 2. Se não estiver no cache, buscar na API do YouTube
    print(f"Cache miss for key: {cache_key}. Fetching from YouTube API.")

    try:
        youtube = build('youtube', 'v3', developerKey=config.YOUTUBE_API_KEY)
        
        search_response = youtube.search().list(
            q=request.topic,
            part='snippet',
            maxResults=request.max_results,
            type='video',
            relevanceLanguage='pt' # Prioriza resultados em português
        ).execute()

        videos = []
        for item in search_response.get("items", []):
            video_id = item["id"]["videoId"]
            videos.append(VideoInfo(
                title=item["snippet"]["title"],
                video_id=video_id,
                url=f"https://www.youtube.com/watch?v={video_id}",
                thumbnail_url=item["snippet"]["thumbnails"]["high"]["url"]
            ))

        response_data = VideoRecommendationResponse(search_topic=request.topic, videos=videos)

        # 3. Salvar o resultado no cache antes de retornar
        # O resultado é convertido para JSON e salvo com um tempo de expiração (ex: 1 hora)
        rd.set(cache_key, response_data.model_dump_json(), ex=3600)
        return response_data

    except HttpError as e:
        # Log do erro no servidor seria uma boa prática aqui
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"An error occurred with the YouTube API: {e.reason}")
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"An unexpected error occurred: {str(e)}")

@router.get("/for-you", response_model=ForYouResponse)
def get_for_you_recommendation(
    current_user: models.User = Depends(utils.get_current_user),
    db: Session = Depends(utils.get_db),
    rd: Redis = Depends(cache.get_cache)
):
    # 1. Tentar buscar do cache primeiro (cache por usuário)
    cache_key = f"for_you:{current_user.id}"
    cached_result = rd.get(cache_key)
    if cached_result:
        print(f"Cache hit for key: {cache_key}.")
        return ForYouResponse(**json.loads(cached_result))

    print(f"Cache miss for key: {cache_key}. Generating new recommendation.")

    # 2. Coletar dados do usuário do banco
    recent_messages = db.query(models.Message).join(models.Conversation).filter(
        models.Conversation.user_id == current_user.id
    ).order_by(models.Message.timestamp.desc()).limit(20).all()

    recent_roadmaps = db.query(models.Roadmap).filter(
        models.Roadmap.user_id == current_user.id
    ).order_by(models.Roadmap.created_at.desc()).limit(5).all()

    if not recent_messages and not recent_roadmaps:
        # Se o usuário for novo, retorna uma sugestão genérica
        return ForYouResponse(
            suggested_topic="Explorar um novo hobby",
            reasoning="Vimos que você é novo por aqui! Que tal começar explorando um tópico que sempre teve curiosidade?",
            recommended_video=None
        )

    # 3. Formatar dados para o LLM
    chat_history = "\n".join([f"- {msg.sender}: {msg.content}" for msg in recent_messages])
    roadmap_topics = ", ".join([r.main_topic for r in recent_roadmaps])

    # 4. Usar LLM para sintetizar e sugerir
    llm = utils.get_llm(config.DEFAULT_LLM_PROVIDER)
    
    class Suggestion(schemas.BaseModel):
        topic: str
        reason: str

    parser = JsonOutputParser(pydantic_object=Suggestion)

    prompt_template = """
    Você é um conselheiro acadêmico e de carreira. Sua tarefa é analisar o histórico de um usuário e sugerir um próximo tópico de estudo relevante e interessante.

    HISTÓRICO DE CHAT RECENTE:
    {chat_history}

    TÓPICOS DE ROADMAPS GERADOS RECENTEMENTE:
    {roadmap_topics}

    Com base nesse histórico, identifique os principais interesses do usuário. Em seguida, sugira um ÚNICO tópico específico para ele estudar a seguir.
    Seja criativo e tente conectar ideias. Por exemplo, se ele estudou Python e Análise de Dados, sugira "Visualização de Dados Interativa com Plotly" ou "Machine Learning para Iniciantes com Scikit-learn".
    
    Forneça sua resposta no seguinte formato JSON:
    {format_instructions}
    """
    prompt = PromptTemplate(
        template=prompt_template,
        input_variables=["chat_history", "roadmap_topics"],
        partial_variables={"format_instructions": parser.get_format_instructions()}
    )
    
    chain = prompt | llm | parser
    suggestion = chain.invoke({
        "chat_history": chat_history,
        "roadmap_topics": roadmap_topics
    })

    # 5. Buscar um vídeo no YouTube para o tópico sugerido
    recommended_video = None
    if suggestion and config.YOUTUBE_API_KEY:
        try:
            youtube = build('youtube', 'v3', developerKey=config.YOUTUBE_API_KEY)
            search_response = youtube.search().list(
                q=suggestion['topic'],
                part='snippet',
                maxResults=1,
                type='video',
                relevanceLanguage='pt'
            ).execute()

            if search_response.get("items"):
                item = search_response["items"][0]
                video_id = item["id"]["videoId"]
                recommended_video = VideoInfo(
                    title=item["snippet"]["title"],
                    video_id=video_id,
                    url=f"https://www.youtube.com/watch?v={video_id}",
                    thumbnail_url=item["snippet"]["thumbnails"]["high"]["url"]
                )
        except Exception:
            # Se a busca do YouTube falhar, não quebra a requisição.
            # Apenas não teremos um vídeo recomendado.
            pass

    # 6. Construir e salvar a resposta no cache antes de retornar
    response_data = ForYouResponse(
        suggested_topic=suggestion['topic'],
        reasoning=suggestion['reason'],
        recommended_video=recommended_video
    )

    # Salva no cache por 15 minutos (900 segundos)
    rd.set(cache_key, response_data.model_dump_json(), ex=900)

    return response_data