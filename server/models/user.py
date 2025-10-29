from sqlalchemy import TEXT, VARCHAR, Column, LargeBinary, String
from models.base import Base
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid

class User(Base):
    __tablename__ = 'user'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(VARCHAR(100))
    email = Column(VARCHAR(100))
    password = Column(LargeBinary, nullable=True)
    google_id = Column(String, unique=True, nullable=True)

    user_songs = relationship('UserSong', back_populates='uploader', cascade="all, delete-orphan")
    favorites = relationship('Favorite', back_populates='user', cascade="all, delete-orphan")