from datetime import datetime
import uuid
from pydantic import BaseModel
from typing import Optional


class SongResponse(BaseModel):
    id: uuid.UUID
    song_name: str
    thumbnail_url: str
    song_url: str
    artist: str
    hex_code: str
    create_at: Optional[datetime]

    class Config:
        orm_mode = True