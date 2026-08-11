from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import Optional, List
from uuid import UUID
from app.repositories.base import BaseRepository
from app.models.all_models import User, GroceryItem, ChatSession, ChatMessage, Transaction, JournalEntry, Task, Goal
from app.schemas.all_schemas import (
    UserCreate, UserUpdate, 
    GroceryItemCreate, GroceryItemUpdate, 
    ChatSessionCreate, ChatMessageCreate,
    TransactionCreate, JournalEntryCreate, TaskCreate, TaskUpdate,
    GoalCreate, GoalUpdate
)
import bcrypt

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

class UserRepository(BaseRepository[User, UserCreate, UserUpdate]):
    async def get_by_email(self, db: AsyncSession, *, email: str) -> Optional[User]:
        query = select(User).where(User.email == email)
        result = await db.execute(query)
        return result.scalars().first()

    async def create(self, db: AsyncSession, *, obj_in: UserCreate) -> User:
        db_obj = User(
            email=obj_in.email,
            hashed_password=get_password_hash(obj_in.password),
            full_name=obj_in.full_name,
            family_size=obj_in.family_size,
            monthly_income=obj_in.monthly_income,
            monthly_budget=obj_in.monthly_budget
        )
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return db_obj

class GroceryRepository(BaseRepository[GroceryItem, GroceryItemCreate, GroceryItemUpdate]):
    async def get_by_user(self, db: AsyncSession, *, user_id: UUID) -> List[GroceryItem]:
        query = select(GroceryItem).where(GroceryItem.user_id == user_id).order_by(GroceryItem.created_at.desc())
        result = await db.execute(query)
        return list(result.scalars().all())

class TransactionRepository(BaseRepository[Transaction, TransactionCreate, dict]):
    async def get_by_user(self, db: AsyncSession, *, user_id: UUID) -> List[Transaction]:
        query = select(Transaction).where(Transaction.user_id == user_id).order_by(Transaction.created_at.desc())
        result = await db.execute(query)
        return list(result.scalars().all())

class JournalRepository(BaseRepository[JournalEntry, JournalEntryCreate, dict]):
    async def get_by_user(self, db: AsyncSession, *, user_id: UUID) -> List[JournalEntry]:
        query = select(JournalEntry).where(JournalEntry.user_id == user_id).order_by(JournalEntry.created_at.desc())
        result = await db.execute(query)
        return list(result.scalars().all())

class TaskRepository(BaseRepository[Task, TaskCreate, TaskUpdate]):
    async def get_by_user(self, db: AsyncSession, *, user_id: UUID) -> List[Task]:
        query = select(Task).where(Task.user_id == user_id).order_by(Task.created_at.asc())
        result = await db.execute(query)
        return list(result.scalars().all())

class GoalRepository(BaseRepository[Goal, GoalCreate, GoalUpdate]):
    async def get_by_user(self, db: AsyncSession, *, user_id: UUID) -> List[Goal]:
        query = select(Goal).where(Goal.user_id == user_id).order_by(Goal.created_at.desc())
        result = await db.execute(query)
        return list(result.scalars().all())

class ChatSessionRepository(BaseRepository[ChatSession, ChatSessionCreate, dict]):
    async def get_by_user(self, db: AsyncSession, *, user_id: UUID) -> List[ChatSession]:
        query = select(ChatSession).where(ChatSession.user_id == user_id).order_by(ChatSession.created_at.desc())
        result = await db.execute(query)
        return list(result.scalars().all())

class ChatMessageRepository(BaseRepository[ChatMessage, ChatMessageCreate, dict]):
    async def get_by_session(self, db: AsyncSession, *, session_id: UUID) -> List[ChatMessage]:
        query = select(ChatMessage).where(ChatMessage.session_id == session_id).order_by(ChatMessage.created_at.asc())
        result = await db.execute(query)
        return list(result.scalars().all())

user_repo = UserRepository(User)
grocery_repo = GroceryRepository(GroceryItem)
transaction_repo = TransactionRepository(Transaction)
journal_repo = JournalRepository(JournalEntry)
task_repo = TaskRepository(Task)
goal_repo = GoalRepository(Goal)
chat_session_repo = ChatSessionRepository(ChatSession)
chat_message_repo = ChatMessageRepository(ChatMessage)
