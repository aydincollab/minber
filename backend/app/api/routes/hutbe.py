from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, List
from uuid import UUID
import math

from app.api.deps import get_database
from app.services.hutbe_service import HutbeService
from app.schemas.hutbe import (
    HutbeResponse,
    HutbeCreate,
    HutbeUpdate,
    HutbeListItem,
    HutbeSearchResult,
)

router = APIRouter(prefix="/hutbeler", tags=["hutbeler"])


@router.get("/", response_model=HutbeSearchResult)
async def list_hutbeler(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=100, description="Items per page"),
    year: Optional[int] = Query(None, description="Filter by year"),
    category: Optional[str] = Query(None, description="Filter by category"),
    search: Optional[str] = Query(None, description="Search in title, content, summary"),
    db: AsyncSession = Depends(get_database),
):
    """Get list of hutbeler with pagination and filters."""
    skip = (page - 1) * page_size
    
    hutbeler, total = await HutbeService.get_hutbeler(
        db=db,
        skip=skip,
        limit=page_size,
        year=year,
        category=category,
        search=search,
    )
    
    total_pages = math.ceil(total / page_size) if total > 0 else 0
    
    return HutbeSearchResult(
        total=total,
        items=[HutbeListItem.model_validate(h) for h in hutbeler],
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/featured", response_model=HutbeResponse)
async def get_featured_hutbe(
    db: AsyncSession = Depends(get_database),
):
    """Get the featured hutbe. Falls back to the latest hutbe if none is featured."""
    hutbe = await HutbeService.get_featured_hutbe(db)
    
    # Fallback: if no featured hutbe, return the most recent one
    if not hutbe:
        latest_list = await HutbeService.get_latest_hutbeler(db, limit=1)
        hutbe = latest_list[0] if latest_list else None
    
    if not hutbe:
        raise HTTPException(status_code=404, detail="No hutbeler found")
    
    return HutbeResponse.model_validate(hutbe)


@router.get("/latest", response_model=List[HutbeListItem])
async def get_latest_hutbeler(
    limit: int = Query(10, ge=1, le=50, description="Number of items to return"),
    db: AsyncSession = Depends(get_database),
):
    """Get latest hutbeler."""
    hutbeler = await HutbeService.get_latest_hutbeler(db, limit=limit)
    return [HutbeListItem.model_validate(h) for h in hutbeler]


@router.get("/years")
async def get_years_stats(
    db: AsyncSession = Depends(get_database),
):
    """Get hutbe counts grouped by year."""
    return await HutbeService.get_years_stats(db)


@router.get("/categories")
async def get_categories_stats(
    db: AsyncSession = Depends(get_database),
):
    """Get hutbe counts grouped by category."""
    return await HutbeService.get_categories_stats(db)


@router.get("/search", response_model=HutbeSearchResult)
async def search_hutbeler(
    q: str = Query(..., min_length=1, description="Search query"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_database),
):
    """Search hutbeler by title, content, or summary."""
    skip = (page - 1) * page_size
    
    hutbeler, total = await HutbeService.get_hutbeler(
        db=db,
        skip=skip,
        limit=page_size,
        search=q,
    )
    
    total_pages = math.ceil(total / page_size) if total > 0 else 0
    
    return HutbeSearchResult(
        total=total,
        items=[HutbeListItem.model_validate(h) for h in hutbeler],
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/{hutbe_id}", response_model=HutbeResponse)
async def get_hutbe(
    hutbe_id: UUID,
    db: AsyncSession = Depends(get_database),
):
    """Get hutbe by ID."""
    hutbe = await HutbeService.get_hutbe_by_id(db, hutbe_id)
    
    if not hutbe:
        raise HTTPException(status_code=404, detail="Hutbe not found")
    
    return HutbeResponse.model_validate(hutbe)


@router.post("/", response_model=HutbeResponse, status_code=201)
async def create_hutbe(
    hutbe_data: HutbeCreate,
    db: AsyncSession = Depends(get_database),
):
    """Create a new hutbe (admin only - add auth later)."""
    hutbe = await HutbeService.create_hutbe(db, hutbe_data)
    return HutbeResponse.model_validate(hutbe)


@router.put("/{hutbe_id}", response_model=HutbeResponse)
async def update_hutbe(
    hutbe_id: UUID,
    hutbe_data: HutbeUpdate,
    db: AsyncSession = Depends(get_database),
):
    """Update a hutbe (admin only - add auth later)."""
    hutbe = await HutbeService.update_hutbe(db, hutbe_id, hutbe_data)
    
    if not hutbe:
        raise HTTPException(status_code=404, detail="Hutbe not found")
    
    return HutbeResponse.model_validate(hutbe)


@router.delete("/{hutbe_id}", status_code=204)
async def delete_hutbe(
    hutbe_id: UUID,
    db: AsyncSession = Depends(get_database),
):
    """Delete a hutbe (admin only - add auth later)."""
    success = await HutbeService.delete_hutbe(db, hutbe_id)
    
    if not success:
        raise HTTPException(status_code=404, detail="Hutbe not found")
    
    return None
