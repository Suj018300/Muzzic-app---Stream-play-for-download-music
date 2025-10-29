from sqlalchemy import TEXT, Column, ForeignKey
from models.base import Base
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid

class Favorite(Base):
    __tablename__ = 'favorites'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"))
    user_song_id = Column(UUID(as_uuid=True), ForeignKey("user_songs.id", ondelete="CASCADE"), nullable=True)
    song_id = Column(UUID(as_uuid=True), ForeignKey("songs.id", ondelete="CASCADE"), nullable=True)

    user_song = relationship('UserSong', back_populates='favorites')
    user = relationship('User', back_populates='favorites')
    song = relationship("Song", back_populates="favorites")
