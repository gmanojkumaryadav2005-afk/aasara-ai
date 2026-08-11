from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from uuid import UUID
from app.schemas.all_schemas import JournalEntryResponse, JournalEntryCreate
from app.repositories.all_repos import journal_repo
from app.database.session import get_db
from app.dependencies.auth import get_current_user
from app.models.all_models import User

router = APIRouter()

@router.get("/", response_model=List[JournalEntryResponse])
async def get_journal_entries(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await journal_repo.get_by_user(db, user_id=current_user.id)

@router.post("/", response_model=JournalEntryResponse)
async def create_journal_entry(entry: JournalEntryCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await journal_repo.create(db, obj_in=entry, user_id=current_user.id)

@router.delete("/{entry_id}")
async def delete_journal_entry(entry_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = await journal_repo.get(db, id=entry_id)
    if not existing or existing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Journal entry not found")
    await journal_repo.remove(db, id=entry_id)
    return {"status": "ok"}
