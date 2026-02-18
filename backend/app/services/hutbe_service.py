from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, desc
from app.models.hutbe import Hutbe
from app.schemas.hutbe import HutbeCreate, HutbeUpdate
from typing import Optional, List
from uuid import UUID
from datetime import date


class HutbeService:
    """Service for Hutbe business logic."""
    
    @staticmethod
    async def create_hutbe(db: AsyncSession, hutbe_data: HutbeCreate) -> Hutbe:
        """Create a new hutbe."""
        hutbe = Hutbe(**hutbe_data.model_dump())
        db.add(hutbe)
        await db.flush()
        await db.refresh(hutbe)
        return hutbe
    
    @staticmethod
    async def get_hutbe_by_id(db: AsyncSession, hutbe_id: UUID) -> Optional[Hutbe]:
        """Get hutbe by ID."""
        result = await db.execute(select(Hutbe).where(Hutbe.id == hutbe_id))
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_hutbeler(
        db: AsyncSession,
        skip: int = 0,
        limit: int = 10,
        year: Optional[int] = None,
        category: Optional[str] = None,
        search: Optional[str] = None,
    ) -> tuple[List[Hutbe], int]:
        """Get list of hutbeler with filters and pagination."""
        query = select(Hutbe)
        
        # Apply filters
        if year:
            query = query.where(Hutbe.year == year)
        if category:
            query = query.where(Hutbe.category == category)
        if search:
            search_pattern = f"%{search}%"
            query = query.where(
                or_(
                    Hutbe.title.ilike(search_pattern),
                    Hutbe.content.ilike(search_pattern),
                    Hutbe.summary.ilike(search_pattern),
                )
            )
        
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await db.execute(count_query)
        total = total_result.scalar()
        
        # Apply pagination and ordering
        query = query.order_by(desc(Hutbe.date)).offset(skip).limit(limit)
        
        # Execute query
        result = await db.execute(query)
        hutbeler = result.scalars().all()
        
        return list(hutbeler), total
    
    @staticmethod
    async def get_featured_hutbe(db: AsyncSession) -> Optional[Hutbe]:
        """Get the featured hutbe."""
        result = await db.execute(
            select(Hutbe)
            .where(Hutbe.is_featured == True)
            .order_by(desc(Hutbe.date))
            .limit(1)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_latest_hutbeler(db: AsyncSession, limit: int = 10) -> List[Hutbe]:
        """Get latest hutbeler."""
        result = await db.execute(
            select(Hutbe)
            .order_by(desc(Hutbe.date))
            .limit(limit)
        )
        return list(result.scalars().all())
    
    @staticmethod
    async def get_years_stats(db: AsyncSession) -> List[dict]:
        """Get hutbe counts grouped by year."""
        result = await db.execute(
            select(Hutbe.year, func.count(Hutbe.id).label('count'))
            .group_by(Hutbe.year)
            .order_by(desc(Hutbe.year))
        )
        return [{"year": year, "count": count} for year, count in result.all()]
    
    @staticmethod
    async def get_categories_stats(db: AsyncSession) -> List[dict]:
        """Get hutbe counts grouped by category."""
        result = await db.execute(
            select(Hutbe.category, func.count(Hutbe.id).label('count'))
            .where(Hutbe.category.isnot(None))
            .group_by(Hutbe.category)
            .order_by(desc('count'))
        )
        return [{"category": category, "count": count} for category, count in result.all()]
    
    @staticmethod
    async def update_hutbe(
        db: AsyncSession,
        hutbe_id: UUID,
        hutbe_data: HutbeUpdate
    ) -> Optional[Hutbe]:
        """Update a hutbe."""
        hutbe = await HutbeService.get_hutbe_by_id(db, hutbe_id)
        if not hutbe:
            return None
        
        update_data = hutbe_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(hutbe, field, value)
        
        await db.flush()
        await db.refresh(hutbe)
        return hutbe
    
    @staticmethod
    async def delete_hutbe(db: AsyncSession, hutbe_id: UUID) -> bool:
        """Delete a hutbe."""
        hutbe = await HutbeService.get_hutbe_by_id(db, hutbe_id)
        if not hutbe:
            return False
        
        await db.delete(hutbe)
        await db.flush()
        return True
    
    @staticmethod
    def calculate_reading_time(content: str) -> int:
        """Calculate reading time in minutes based on word count."""
        words = len(content.split())
        return max(1, words // 200)  # Average 200 words per minute
