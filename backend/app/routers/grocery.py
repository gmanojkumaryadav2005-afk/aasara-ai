from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Dict, Any
from uuid import UUID
from app.schemas.all_schemas import GroceryItemResponse, GroceryItemCreate, GroceryItemUpdate
from app.repositories.all_repos import grocery_repo
from app.database.session import get_db
from app.dependencies.auth import get_current_user
from app.models.all_models import User

router = APIRouter()

@router.get("/", response_model=List[GroceryItemResponse])
async def get_my_groceries(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await grocery_repo.get_by_user(db, user_id=current_user.id)

@router.get("/summary")
async def get_grocery_summary(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)) -> Dict[str, Any]:
    items = await grocery_repo.get_by_user(db, user_id=current_user.id)
    
    grocery_budget = 5000.0
    planned_cost = sum(i.quantity_needed * i.estimated_price_per_unit for i in items if not i.is_purchased)
    purchased_cost = sum(i.quantity_needed * i.estimated_price_per_unit for i in items if i.is_purchased)
    remaining_grocery_budget = max(0.0, grocery_budget - purchased_cost)
    
    total_items = len(items)
    purchased_items = sum(1 for i in items if i.is_purchased)
    remaining_items = total_items - purchased_items
    
    return {
        "grocery_budget": grocery_budget,
        "planned_cost": planned_cost,
        "purchased_cost": purchased_cost,
        "remaining_grocery_budget": remaining_grocery_budget,
        "total_items": total_items,
        "purchased_items": purchased_items,
        "remaining_items": remaining_items,
        "currency_symbol": "₹"
    }

@router.post("/", response_model=GroceryItemResponse)
async def create_grocery(item: GroceryItemCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await grocery_repo.create(db, obj_in=item, user_id=current_user.id)

@router.put("/{item_id}", response_model=GroceryItemResponse)
async def update_grocery(item_id: UUID, item_in: GroceryItemUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = await grocery_repo.get(db, id=item_id)
    if not existing or existing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Grocery item not found")
    return await grocery_repo.update(db, db_obj=existing, obj_in=item_in)

@router.delete("/{item_id}")
async def delete_grocery(item_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = await grocery_repo.get(db, id=item_id)
    if not existing or existing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Grocery item not found")
    await grocery_repo.remove(db, id=item_id)
    return {"status": "ok"}
