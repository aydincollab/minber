from pydantic import BaseModel, Field, ConfigDict
from datetime import date, datetime
from typing import Optional
from uuid import UUID


class HutbeBase(BaseModel):
    """Base Hutbe schema."""
    title: str = Field(..., min_length=1, max_length=500)
    content: str = Field(..., min_length=1)
    summary: Optional[str] = None
    date: date
    year: int
    category: Optional[str] = Field(None, max_length=100)
    reading_time_minutes: Optional[int] = None
    source_url: Optional[str] = Field(None, max_length=500)
    is_featured: bool = False


class HutbeCreate(HutbeBase):
    """Schema for creating a Hutbe."""
    pass


class HutbeUpdate(BaseModel):
    """Schema for updating a Hutbe."""
    title: Optional[str] = Field(None, min_length=1, max_length=500)
    content: Optional[str] = Field(None, min_length=1)
    summary: Optional[str] = None
    date: Optional[date] = None
    year: Optional[int] = None
    category: Optional[str] = Field(None, max_length=100)
    reading_time_minutes: Optional[int] = None
    source_url: Optional[str] = Field(None, max_length=500)
    is_featured: Optional[bool] = None


class HutbeInDB(HutbeBase):
    """Schema for Hutbe in database."""
    id: UUID
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class HutbeResponse(HutbeInDB):
    """Schema for Hutbe API response."""
    pass


class HutbeListItem(BaseModel):
    """Schema for Hutbe list item (minimal data)."""
    id: UUID
    title: str
    date: date
    year: int
    category: Optional[str] = None
    reading_time_minutes: Optional[int] = None
    is_featured: bool = False
    
    model_config = ConfigDict(from_attributes=True)


class HutbeSearchResult(BaseModel):
    """Schema for search results."""
    total: int
    items: list[HutbeListItem]
    page: int
    page_size: int
    total_pages: int


class YearStats(BaseModel):
    """Schema for year statistics."""
    year: int
    count: int
    categories: dict[str, int]


class CategoryStats(BaseModel):
    """Schema for category statistics."""
    category: str
    count: int
