from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import auth, grocery, chat, finances, journal, planning, insights, goals
from app.database.session import engine
from app.models.base import Base

app = FastAPI(title=settings.PROJECT_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(grocery.router, prefix=f"{settings.API_V1_STR}/groceries", tags=["groceries"])
app.include_router(chat.router, prefix=f"{settings.API_V1_STR}/chat", tags=["chat"])
app.include_router(finances.router, prefix=f"{settings.API_V1_STR}/finances", tags=["finances"])
app.include_router(journal.router, prefix=f"{settings.API_V1_STR}/journal", tags=["journal"])
app.include_router(planning.router, prefix=f"{settings.API_V1_STR}/planning", tags=["planning"])
app.include_router(insights.router, prefix=f"{settings.API_V1_STR}/insights", tags=["insights"])
app.include_router(goals.router, prefix=f"{settings.API_V1_STR}/goals", tags=["goals"])

@app.on_event("startup")
async def startup_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.get("/health")
async def health_check():
    return {"status": "ok", "project": "AASARA"}
