from datetime import datetime
from sqlalchemy import TEXT, VARCHAR, Column, DateTime, String, func
from models.base import Base
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
import uuid

class Song(Base):
    __tablename__ = 'songs'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    # id = Column(id)
    song_url = Column(TEXT)
    thumbnail_url = Column(TEXT)
    artist = Column(TEXT)
    song_name = Column(VARCHAR(100))
    hex_code = Column(VARCHAR(6))
    create_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    favorites = relationship("Favorite", back_populates="song", cascade="all, delete-orphan")
 