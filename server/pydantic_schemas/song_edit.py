from pydantic import BaseModel

class UpdateSong(BaseModel):
    song_url: str | None = None
    thumbnail_url: str | None = None
    song_name: str | None = None 
    artist: str | None = None 
    hex_code: str | None = None