import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, Form, File
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.dialects.postgresql import UUID
from database import get_db
from middleware.auth_middleware import auth_middleware
import cloudinary
import cloudinary.uploader
import cloudinary.api
from typing import Optional
from dotenv import load_dotenv
from cloudinary import CloudinaryImage
from cloudinary import CloudinaryVideo
from models.favorite import Favorite
from models.song import Song
from models.user_songs import UserSong
from pydantic_schemas.favorite_song import FavoriteSong
from pydantic_schemas.songs_list import SongResponse
from fastapi.encoders import jsonable_encoder
from fastapi.responses import  JSONResponse
from pydantic_schemas.song_edit import UpdateSong

router = APIRouter()

load_dotenv()  # This loads the .env file into os.environ

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

@router.post('/upload', status_code=201)
def upload_user_song(
    song: UploadFile = File(...),
    thumbnail: UploadFile = File(...),
    artist: str = Form(...),
    song_name: str = Form(...),
    hex_code: str = Form(...),
    db: Session = Depends(get_db),
    auth_details = Depends(auth_middleware)
):
    user_id = auth_details['uid']
    song_id = str(uuid.uuid4())

    # Upload to Cloudinary
    song_res = cloudinary.uploader.upload(
        song.file,
        resource_type='auto',
        folder=f'user_songs/{user_id}/{song_id}'
    )
    thumbnail_res = cloudinary.uploader.upload(
        thumbnail.file,
        resource_type='image',
        folder=f'user_songs/{user_id}/{song_id}'
    )

    new_song = UserSong(
        id=song_id,
        song_url=song_res['url'],
        thumbnail_url=thumbnail_res['url'],
        artist=artist,
        song_name=song_name,
        hex_code=hex_code,
        user_id=user_id
    )

    db.add(new_song)
    db.commit()
    db.refresh(new_song)
    return new_song


@router.get('/list')
def list_user_songs(
    db: Session = Depends(get_db),
    auth_details = Depends(auth_middleware)
):
    user_id = auth_details['uid']
    songs = db.query(UserSong).all()
    return songs


@router.post('/favorite')
def toggle_user_song_favorite(
    favorite_song: dict,
    db: Session = Depends(get_db),
    auth_details = Depends(auth_middleware)
):
    user_id = auth_details['uid']
    user_song_id = favorite_song.get('user_song_id')
    song_id = favorite_song.get('song_id')

    if not user_song_id and not song_id :
        raise HTTPException(status_code=400, detail="user_song_id is required")

    fav_song = db.query(Favorite).filter(Favorite.user_id == user_id)
    if user_song_id:
        fav_song = fav_song.filter(Favorite.user_song_id == user_song_id)
    if song_id:
        fav_song = fav_song.filter(Favorite.song_id == song_id)
    fav = fav_song.first()

    # If already favorited, unfavorite
    if fav:
        db.delete(fav)
        db.commit()
        return {"message": False}

    # Otherwise, add as new favorite
    new_fav = Favorite(
        id=str(uuid.uuid4()),
        song_id = song_id,
        user_song_id=user_song_id,
        user_id=user_id
    )
    db.add(new_fav)
    db.commit()
    return {"message": True}


@router.get('/list/favorite')
def list_user_song_favorites(
    db: Session = Depends(get_db),
    auth_details = Depends(auth_middleware)
):
    user_id = auth_details['uid']
    fav_songs = db.query(Favorite).filter(Favorite.user_id == user_id).options(
        joinedload(Favorite.user_song),
        joinedload(Favorite.song)
    ).all()

    result = []
    for fav in fav_songs:
        song = fav.user_song or fav.song
        if not song:
            continue
        result.append({
            "song": {
                "id": str(song.id),
                "song_url": song.song_url,
                "thumbnail_url": song.thumbnail_url,
                "artist": song.artist,
                "song_name": song.song_name,
                "hex_code": song.hex_code
            }
        }) 

    return result


@router.put('/list/{id}')
def update_user_song(
    id: str,
    song: UploadFile = File(None),
    thumbnail: UploadFile = File(None),
    artist: str = Form(None),
    song_name: str = Form(None),
    hex_code: str = Form(None),
    db: Session = Depends(get_db),
    auth_details = Depends(auth_middleware)
):
    user_id = auth_details['uid']
    db_song = db.query(UserSong).filter(UserSong.id == id, UserSong.user_id == user_id).first()

    if not db_song:
        raise HTTPException(status_code=404, detail="Song not found or access denied")

    if song is not None:
        song_res = cloudinary.uploader.upload(song.file, resource_type='auto', folder=f'user_songs/{user_id}/{id}')
        db_song.song_url = song_res['url']

    if thumbnail is not None:
        thumbnail_res = cloudinary.uploader.upload(thumbnail.file, resource_type='image', folder=f'user_songs/{user_id}/{id}')
        db_song.thumbnail_url = thumbnail_res['url']

    if song_name is not None:
        db_song.song_name = song_name
    if artist is not None:
        db_song.artist = artist
    if hex_code is not None:
        db_song.hex_code = hex_code

    db.commit()
    db.refresh(db_song)
    return db_song


@router.delete('/list/{id}')
def delete_user_song(
    id: str,
    db: Session = Depends(get_db),
    auth_details = Depends(auth_middleware)
):
    user_id = auth_details['uid']
    db_song = db.query(UserSong).filter(UserSong.id == id, UserSong.user_id == user_id).first()

    if not db_song:
        raise HTTPException(status_code=404, detail="Song not found or access denied")

    db.delete(db_song)
    db.commit()
    return {"message": f"Song with id {id} deleted successfully"}


@router.get('/list/{id}')
def get_user_song(
    id: str,
    db: Session = Depends(get_db),
    auth_details = Depends(auth_middleware)
):
    user_id = auth_details['uid']
    song = db.query(UserSong).filter(UserSong.id == id, UserSong.user_id == user_id).first()
    if not song:
        raise HTTPException(status_code=404, detail="Song not found or access denied")
    return song

