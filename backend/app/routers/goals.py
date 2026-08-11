from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from uuid import UUID
from app.schemas.all_schemas import GoalResponse, GoalCreate, GoalUpdate
from app.repositories.all_repos import goal_repo
from app.database.session import get_db
from app.dependencies.auth import get_current_user
from app.models.all_models import User

router = APIRouter()

@router.get("/", response_model=List[GoalResponse])
async def get_my_goals(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await goal_repo.get_by_user(db, user_id=current_user.id)

@router.post("/", response_model=GoalResponse)
async def create_goal(item: GoalCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await goal_repo.create(db, obj_in=item, user_id=current_user.id)

@router.put("/{goal_id}", response_model=GoalResponse)
async def update_goal(goal_id: UUID, goal_in: GoalUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = await goal_repo.get(db, id=goal_id)
    if not existing or existing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Goal not found")
    return await goal_repo.update(db, db_obj=existing, obj_in=goal_in)

@router.delete("/{goal_id}")
async def delete_goal(goal_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = await goal_repo.get(db, id=goal_id)
    if not existing or existing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Goal not found")
    await goal_repo.remove(db, id=goal_id)
    return {"status": "ok"}
