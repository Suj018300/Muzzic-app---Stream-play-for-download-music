from fastapi import FastAPI
from models.base import Base
from routes import auth, song, download, user_songs
from database import engine


app = FastAPI()
app.include_router(auth.router, prefix="/auth")
app.include_router(song.router, prefix="/song")
app.include_router(download.router, prefix="/download")
app.include_router(user_songs.router, prefix="/user_song")

Base.metadata.create_all(engine)