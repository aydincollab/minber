from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from typing import AsyncGenerator


async def get_database() -> AsyncGenerator[AsyncSession, None]:
    """Dependency for getting database session."""
    async for session in get_db():
        yield session
