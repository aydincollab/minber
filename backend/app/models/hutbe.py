from sqlalchemy import Column, String, Text, Integer, Boolean, Date, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid
from app.database import Base


class Hutbe(Base):
    """Hutbe (Sermon) database model."""
    
    __tablename__ = "hutbeler"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    title = Column(String(500), nullable=False, index=True)
    content = Column(Text, nullable=False)
    summary = Column(Text, nullable=True)
    date = Column(Date, nullable=False, index=True)
    year = Column(Integer, nullable=False, index=True)
    category = Column(String(100), nullable=True, index=True)
    reading_time_minutes = Column(Integer, nullable=True)
    source_url = Column(String(500), nullable=True)
    is_featured = Column(Boolean, default=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Create composite indexes for common queries
    __table_args__ = (
        Index('ix_hutbe_year_date', 'year', 'date'),
        Index('ix_hutbe_category_date', 'category', 'date'),
    )
    
    def __repr__(self):
        return f"<Hutbe(id={self.id}, title='{self.title[:30]}...', date={self.date})>"
