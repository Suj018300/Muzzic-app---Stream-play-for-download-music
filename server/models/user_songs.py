import uuid
from datetime import datetime
from sqlalchemy import TEXT, UUID, VARCHAR, Column, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship, Mapped, mapped_column
from models.base import Base


class UserSong(Base):
    __tablename__ = 'user_songs'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    song_url = Column(TEXT, nullable=False)
    thumbnail_url = Column(TEXT)
    artist = Column(TEXT)
    song_name = Column(VARCHAR(100))
    hex_code = Column(VARCHAR(6))
    create_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    user_id = Column(UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), nullable=False)

    uploader = relationship('User', back_populates='user_songs')
    favorites = relationship('Favorite', back_populates='user_song', cascade="all, delete-orphan")
