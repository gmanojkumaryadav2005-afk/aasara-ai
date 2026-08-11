from sqlalchemy import Column, String, Boolean, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.models.base import Base

class User(Base):
    __tablename__ = "users"

    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, index=True)
    firebase_uid = Column(String, unique=True, index=True, nullable=True)
    is_active = Column(Boolean, default=True)
    family_size = Column(Float, default=1.0)
    monthly_income = Column(Float, default=60000.0)
    monthly_budget = Column(Float, default=30000.0)

    grocery_items = relationship("GroceryItem", back_populates="user", cascade="all, delete-orphan")
    chat_sessions = relationship("ChatSession", back_populates="user", cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    journal_entries = relationship("JournalEntry", back_populates="user", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")
    goals = relationship("Goal", back_populates="user", cascade="all, delete-orphan")

class GroceryItem(Base):
    __tablename__ = "grocery_items"
    
    user_id = Column(ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    category = Column(String, default="Essentials")
    quantity_needed = Column(Float, default=1.0)
    unit = Column(String, default="Kg")
    estimated_price_per_unit = Column(Float, default=0.0)
    is_purchased = Column(Boolean, default=False)
    date_purchased = Column(String, nullable=True)
    
    user = relationship("User", back_populates="grocery_items")

class ChatSession(Base):
    __tablename__ = "chat_sessions"
    
    user_id = Column(ForeignKey("users.id"), nullable=False)
    title = Column(String, default="AASARA Session")
    
    user = relationship("User", back_populates="chat_sessions")
    messages = relationship("ChatMessage", back_populates="session", cascade="all, delete-orphan")

class ChatMessage(Base):
    __tablename__ = "chat_messages"
    
    session_id = Column(ForeignKey("chat_sessions.id"), nullable=False)
    role = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    detected_emotion = Column(String, nullable=True)
    
    session = relationship("ChatSession", back_populates="messages")

class Transaction(Base):
    __tablename__ = "transactions"
    
    user_id = Column(ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    category = Column(String, default="General")
    type = Column(String, default="expense") # 'expense' or 'income'
    date = Column(String, nullable=True)
    
    user = relationship("User", back_populates="transactions")

class JournalEntry(Base):
    __tablename__ = "journal_entries"
    
    user_id = Column(ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    mood = Column(String, default="Neutral")
    
    user = relationship("User", back_populates="journal_entries")

class Task(Base):
    __tablename__ = "tasks"
    
    user_id = Column(ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    due_date = Column(String, nullable=True)
    due_time = Column(String, nullable=True)
    is_completed = Column(Boolean, default=False)
    priority = Column(String, default="Medium") # 'High', 'Medium', 'Low'
    time_of_day = Column(String, default="Morning") # 'Morning', 'Afternoon', 'Evening'
    
    user = relationship("User", back_populates="tasks")

class Goal(Base):
    __tablename__ = "goals"
    
    user_id = Column(ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    category = Column(String, default="Custom Goal") # 'House', 'Car', 'Emergency Fund', 'Education', 'Vacation', 'Business', 'Custom Goal'
    target_amount = Column(Float, nullable=False)
    current_savings = Column(Float, default=0.0)
    monthly_contribution = Column(Float, default=0.0)
    target_date = Column(String, nullable=True)
    
    user = relationship("User", back_populates="goals")
