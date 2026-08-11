from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Dict, Any
from app.repositories.all_repos import transaction_repo, grocery_repo, journal_repo, goal_repo
from app.database.session import get_db
from app.dependencies.auth import get_current_user
from app.models.all_models import User

router = APIRouter()

@router.get("/")
async def get_insights(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)) -> Dict[str, Any]:
    transactions = await transaction_repo.get_by_user(db, user_id=current_user.id)
    groceries = await grocery_repo.get_by_user(db, user_id=current_user.id)
    journal_entries = await journal_repo.get_by_user(db, user_id=current_user.id)
    goals = await goal_repo.get_by_user(db, user_id=current_user.id)
    
    total_spent = sum(t.amount for t in transactions if t.type == "expense")
    income = current_user.monthly_income or 60000.0
    budget = current_user.monthly_budget or 30000.0
    pct = (total_spent / budget * 100.0) if budget > 0 else 0.0
    savings_rate = round(((income - total_spent) / income * 100.0), 1) if income > 0 else 0.0
    
    insights: List[Dict[str, str]] = []
    
    # 1. Budget & Savings Rate
    insights.append({
        "type": "positive" if savings_rate >= 20.0 else "warning",
        "title": "Savings Progress",
        "description": f"Your current savings rate is {savings_rate}%. A healthy savings target is 20%+ of monthly income (₹{income:,.0f})."
    })
    
    # 2. Financial Goals
    if goals:
        top_goal = goals[0]
        rem = top_goal.target_amount - top_goal.current_savings
        months = round(rem / top_goal.monthly_contribution, 1) if top_goal.monthly_contribution > 0 else 0
        insights.append({
            "type": "goal",
            "title": f"Goal: {top_goal.title}",
            "description": f"Target: ₹{top_goal.target_amount:,.0f} | Current Savings: ₹{top_goal.current_savings:,.0f}. At ₹{top_goal.monthly_contribution:,.0f}/mo, target reached in approx {months} months."
        })
    else:
        insights.append({
            "type": "info",
            "title": "Financial Goals",
            "description": "Create your first goal (House, Car, Emergency Fund) to receive personalized timeline projections."
        })
        
    # 3. Grocery Overview
    purchased_cost = sum(g.quantity_needed * g.estimated_price_per_unit for g in groceries if g.is_purchased)
    planned_cost = sum(g.quantity_needed * g.estimated_price_per_unit for g in groceries if not g.is_purchased)
    if groceries:
        insights.append({
            "type": "info",
            "title": "Grocery Budget Overview",
            "description": f"Purchased: ₹{purchased_cost:,.0f} | Planned: ₹{planned_cost:,.0f} across {len(groceries)} list items."
        })
        
    # 4. Mindfulness Reflections
    if journal_entries:
        last_entry = journal_entries[0]
        insights.append({
            "type": "reflection",
            "title": "Mindfulness Reflection",
            "description": f"Your recent reflection noted mood '{last_entry.mood}'. Patterns suggest self-reflection helps balance financial discipline and wellbeing."
        })
        
    return {
        "has_sufficient_data": True,
        "message": "Personalized Insights",
        "budget_percentage": pct,
        "savings_rate": savings_rate,
        "insights": insights
    }
