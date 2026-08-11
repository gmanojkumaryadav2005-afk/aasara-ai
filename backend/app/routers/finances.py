from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Dict, Any
from uuid import UUID
from app.schemas.all_schemas import TransactionResponse, TransactionCreate
from app.repositories.all_repos import transaction_repo
from app.database.session import get_db
from app.dependencies.auth import get_current_user
from app.models.all_models import User

router = APIRouter()

@router.get("/transactions", response_model=List[TransactionResponse])
async def get_transactions(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await transaction_repo.get_by_user(db, user_id=current_user.id)

@router.post("/transactions", response_model=TransactionResponse)
async def create_transaction(item: TransactionCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await transaction_repo.create(db, obj_in=item, user_id=current_user.id)

@router.delete("/transactions/{transaction_id}")
async def delete_transaction(transaction_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = await transaction_repo.get(db, id=transaction_id)
    if not existing or existing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Transaction not found")
    await transaction_repo.remove(db, id=transaction_id)
    return {"status": "ok"}

@router.get("/summary")
async def get_summary(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)) -> Dict[str, Any]:
    transactions = await transaction_repo.get_by_user(db, user_id=current_user.id)
    
    total_spent = sum(t.amount for t in transactions if t.type == "expense")
    total_income = current_user.monthly_income or 60000.0
    monthly_budget = current_user.monthly_budget or 30000.0
    
    savings = max(0.0, total_income - total_spent)
    savings_rate = round((savings / total_income * 100), 1) if total_income > 0 else 0.0
    remaining_budget = max(0.0, monthly_budget - total_spent)
    percentage_used = round((total_spent / monthly_budget * 100), 1) if monthly_budget > 0 else 0.0
    
    categories: Dict[str, float] = {}
    for t in transactions:
        if t.type == "expense":
            categories[t.category] = categories.get(t.category, 0.0) + t.amount
            
    return {
        "monthly_income": total_income,
        "monthly_budget": monthly_budget,
        "total_spent": total_spent,
        "savings": savings,
        "savings_rate": savings_rate,
        "remaining_budget": remaining_budget,
        "percentage_used": percentage_used,
        "currency": "INR",
        "currency_symbol": "₹",
        "spending_categories": categories,
        "transaction_count": len(transactions)
    }

@router.get("/weekly_review")
async def get_weekly_review(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)) -> Dict[str, Any]:
    transactions = await transaction_repo.get_by_user(db, user_id=current_user.id)
    
    weekly_income = round((current_user.monthly_income or 60000.0) / 4.0, 2)
    weekly_spending = sum(t.amount for t in transactions if t.type == "expense") # recent transactions total
    weekly_savings = max(0.0, weekly_income - weekly_spending)
    
    categories: Dict[str, float] = {}
    for t in transactions:
        if t.type == "expense":
            categories[t.category] = categories.get(t.category, 0.0) + t.amount
            
    top_category = max(categories.items(), key=lambda x: x[1])[0] if categories else "Groceries"
    
    return {
        "weekly_income": weekly_income,
        "weekly_spending": weekly_spending,
        "weekly_savings": weekly_savings,
        "top_spending_category": top_category,
        "status": "Within Budget" if weekly_spending <= weekly_income else "Over Budget",
        "recommendation": f"Prioritize reducing discretionary spending in {top_category} to increase weekly savings rate."
    }
