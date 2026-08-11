from pydantic import BaseModel, ConfigDict, EmailStr
from datetime import datetime
from uuid import UUID
from typing import List, Optional

class CustomBaseModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)

class BaseSchema(CustomBaseModel):
    id: UUID
    created_at: datetime
    updated_at: datetime

# --- User ---
class UserBase(CustomBaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    family_size: float = 1.0
    monthly_income: float = 60000.0
    monthly_budget: float = 30000.0

class UserCreate(UserBase):
    password: str

class UserUpdate(CustomBaseModel):
    full_name: Optional[str] = None
    family_size: Optional[float] = None
    monthly_income: Optional[float] = None
    monthly_budget: Optional[float] = None

class UserResponse(BaseSchema, UserBase):
    pass

# --- Grocery ---
class GroceryItemBase(CustomBaseModel):
    name: str
    category: str = "Essentials"
    quantity_needed: float = 1.0
    unit: str = "Kg"
    estimated_price_per_unit: float = 0.0
    is_purchased: bool = False
    date_purchased: Optional[str] = None

class GroceryItemCreate(GroceryItemBase):
    pass

class GroceryItemUpdate(CustomBaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    quantity_needed: Optional[float] = None
    unit: Optional[str] = None
    estimated_price_per_unit: Optional[float] = None
    is_purchased: Optional[bool] = None
    date_purchased: Optional[str] = None

class GroceryItemResponse(BaseSchema, GroceryItemBase):
    user_id: UUID

# --- Transactions ---
class TransactionBase(CustomBaseModel):
    title: str
    amount: float
    category: str = "General"
    type: str = "expense" # 'expense' or 'income'
    date: Optional[str] = None

class TransactionCreate(TransactionBase):
    pass

class TransactionResponse(BaseSchema, TransactionBase):
    user_id: UUID

# --- Journal ---
class JournalEntryBase(CustomBaseModel):
    title: str
    content: str
    mood: str = "Neutral"

class JournalEntryCreate(JournalEntryBase):
    pass

class JournalEntryResponse(BaseSchema, JournalEntryBase):
    user_id: UUID

# --- Task / Planning ---
class TaskBase(CustomBaseModel):
    title: str
    due_date: Optional[str] = None
    due_time: Optional[str] = None
    is_completed: bool = False
    priority: str = "Medium"
    time_of_day: str = "Morning"

class TaskCreate(TaskBase):
    pass

class TaskUpdate(CustomBaseModel):
    title: Optional[str] = None
    due_date: Optional[str] = None
    due_time: Optional[str] = None
    is_completed: Optional[bool] = None
    priority: Optional[str] = None
    time_of_day: Optional[str] = None

class TaskResponse(BaseSchema, TaskBase):
    user_id: UUID

# --- Goals ---
class GoalBase(CustomBaseModel):
    title: str
    category: str = "Custom Goal"
    target_amount: float
    current_savings: float = 0.0
    monthly_contribution: float = 0.0
    target_date: Optional[str] = None

class GoalCreate(GoalBase):
    pass

class GoalUpdate(CustomBaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    target_amount: Optional[float] = None
    current_savings: Optional[float] = None
    monthly_contribution: Optional[float] = None
    target_date: Optional[str] = None

class GoalResponse(BaseSchema, GoalBase):
    user_id: UUID

# --- Chat ---
class ChatMessageBase(CustomBaseModel):
    role: str
    content: str
    detected_emotion: Optional[str] = None

class ChatMessageCreate(ChatMessageBase):
    pass

class ChatMessageResponse(BaseSchema, ChatMessageBase):
    session_id: UUID

class ChatSessionBase(CustomBaseModel):
    title: str = "AASARA Session"

class ChatSessionCreate(ChatSessionBase):
    pass

class ChatSessionResponse(BaseSchema, ChatSessionBase):
    user_id: UUID

# --- Auth ---
class Token(CustomBaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
