from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from uuid import UUID
from app.schemas.all_schemas import TaskResponse, TaskCreate, TaskUpdate
from app.repositories.all_repos import task_repo
from app.database.session import get_db
from app.dependencies.auth import get_current_user
from app.models.all_models import User

router = APIRouter()

@router.get("/tasks", response_model=List[TaskResponse])
async def get_tasks(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await task_repo.get_by_user(db, user_id=current_user.id)

@router.post("/tasks", response_model=TaskResponse)
async def create_task(task: TaskCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await task_repo.create(db, obj_in=task, user_id=current_user.id)

@router.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task(task_id: UUID, task_in: TaskUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = await task_repo.get(db, id=task_id)
    if not existing or existing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Task not found")
    return await task_repo.update(db, db_obj=existing, obj_in=task_in)

@router.delete("/tasks/{task_id}")
async def delete_task(task_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = await task_repo.get(db, id=task_id)
    if not existing or existing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Task not found")
    await task_repo.remove(db, id=task_id)
    return {"status": "ok"}
