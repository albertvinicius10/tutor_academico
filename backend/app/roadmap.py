# app/roadmap.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
import json
from redis import Redis

from . import utils, models, schemas, config, cache
from langchain.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser

router = APIRouter(prefix="/roadmap", tags=["roadmap"])



class RoadmapStep(schemas.BaseModel):
    step: int
    title: str
    description: str
    topics: List[str]

class RoadmapResponse(schemas.BaseModel):
    main_topic: str
    roadmap: List[RoadmapStep]

class RoadmapRequest(schemas.BaseModel):
    topic: str
    provider: Optional[str] = config.DEFAULT_LLM_PROVIDER


@router.post("/", response_model=schemas.RoadmapSchema) 
def generate_roadmap(
    request: RoadmapRequest,
    current_user: models.User = Depends(utils.get_current_user),
    db: Session = Depends(utils.get_db),
    rd: Redis = Depends(cache.get_cache)
):

    cache_key = f"roadmap:{request.topic}:{request.provider}"
    cached_content = rd.get(cache_key)

    if cached_content:
        print(f"Cache hit for key: {cache_key}.")
        roadmap_content = json.loads(cached_content)
    else:
        print(f"Cache miss for key: {cache_key}. Calling LLM.")
        try:
            llm = utils.get_llm(request.provider)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

        parser = JsonOutputParser(pydantic_object=RoadmapResponse)

        prompt_template = """
        Você é um tutor especialista e planejador de currículos educacionais.
        Sua tarefa é criar um roadmap de estudos detalhado para o tópico: "{topic}".
        O roadmap deve ser estruturado em passos sequenciais, claros e lógicos.
        {format_instructions}
        """
        prompt = ChatPromptTemplate.from_template(template=prompt_template, partial_variables={"format_instructions": parser.get_format_instructions()})
        chain = prompt | llm | parser
        
        roadmap_content = chain.invoke({"topic": request.topic})
        rd.set(cache_key, json.dumps(roadmap_content), ex=86400)

   
    new_roadmap = models.Roadmap(
        user_id=current_user.id,
        main_topic=roadmap_content.get("main_topic") or request.topic,
        content=roadmap_content 
    )


    db.add(new_roadmap)
    db.commit()
    db.refresh(new_roadmap)


    return new_roadmap

@router.get("/", response_model=List[schemas.RoadmapSchema])
def get_user_roadmaps(
    current_user: models.User = Depends(utils.get_current_user),
    db: Session = Depends(utils.get_db)
):
    """Lista todos os roadmaps salvos para o usuário logado."""
    return db.query(models.Roadmap).filter(models.Roadmap.user_id == current_user.id).order_by(models.Roadmap.created_at.desc()).all()