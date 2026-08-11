from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from uuid import UUID
from pydantic import BaseModel
from app.schemas.all_schemas import ChatSessionResponse, ChatSessionCreate, ChatMessageResponse
from app.repositories.all_repos import chat_session_repo, chat_message_repo
from app.database.session import get_db
from app.dependencies.auth import get_current_user
from app.models.all_models import User
from app.services.ai_service import generate_chat_response

router = APIRouter()

class ChatRequest(BaseModel):
    message: str

@router.post("/sessions", response_model=ChatSessionResponse)
async def create_session(session_in: ChatSessionCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await chat_session_repo.create(db, obj_in=session_in, user_id=current_user.id)

@router.get("/sessions", response_model=List[ChatSessionResponse])
async def get_sessions(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await chat_session_repo.get_by_user(db, user_id=current_user.id)

@router.post("/sessions/{session_id}/message")
async def send_message(session_id: UUID, req: ChatRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    response_text = await generate_chat_response(db, session_id, req.message)
    return {"reply": response_text}
    
@router.get("/sessions/{session_id}/messages", response_model=List[ChatMessageResponse])
async def get_messages(session_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await chat_message_repo.get_by_session(db, session_id=session_id)
