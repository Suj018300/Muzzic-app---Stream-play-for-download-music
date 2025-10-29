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
def upload_song(
    song: UploadFile = File(...) , 
    thumbnail: UploadFile = File(...), 
    artist: str = Form(...), 
    song_name: str = Form(...), 
    hex_code: str = Form(...),
    db: Session = Depends(get_db),
    # search for what Depends do
    auth_dic = Depends(auth_middleware),
    # working of auth_middleware 
    ):
    song_id = (uuid.uuid4())
    song_res = cloudinary.uploader.upload(song.file, resource_type='auto', folder=f'songs/{song_id}')
    thumbnail_res = cloudinary.uploader.upload(thumbnail.file, resource_type='image', folder=f'songs/{song_id}')

    new_song = Song(
        id = song_id,
        song_url = song_res['url'],
        thumbnail_url = thumbnail_res['url'],
        song_name = song_name,
        artist = artist,
        hex_code = hex_code,
    )

    db.add(new_song)
    db.commit()
    db.refresh(new_song)
    return new_song

@router.get('/list')
def list_song(db: Session=Depends(get_db), auth_details=Depends(auth_middleware)):
    songs = db.query(Song).all()
    return songs

# @router.post('/favorite')
# def favorite_song(favorite_song: dict, db: Session= Depends(get_db), auth_details=Depends(auth_middleware)):
#     # song is already favorited by the user
#     user_id = auth_details['uid']
#     fav_song = db.query(Favorite).filter(Favorite.song_id == favorite_song.song_id, Favorite.user_id == user_id).first()

#     # if the song is favorited, then unfavorite the song
#     if fav_song:
#         db.delete(fav_song)
#         db.commit()
#         return {'message': False}
#     else:
#         new_fav = Favorite(id= str(uuid.uuid4()), song_id= favorite_song.song_id, user_id= user_id)
#         db.add(new_fav)
#         db.commit()
#         return {'message': True} 
#     # if the song is not favorited the favorite the song

# @router.get('/list/favorite')
# def list_fav_song(db: Session=Depends(get_db), auth_details=Depends(auth_middleware)):
#     user_id = auth_details['uid']
#     fav_song = db.query(Favorite).filter(Favorite.user_id == user_id).options(joinedload(Favorite.song)).all()
#     return fav_song



@router.put('/list/{id}', response_model=SongResponse)
def update_song(
    id: str,
    # payload: UpdateSong = File(None),
    song: Optional[UploadFile] = File(None),
    thumbnail: Optional[UploadFile] = File(None), 
    artist: Optional[str] = Form(None), 
    song_name: Optional[str] = Form(None), 
    hex_code: Optional[str] = Form(None),
    db: Session = Depends(get_db), 
    auth_details = Depends(auth_middleware)
    ):
    
    db_songs = db.query(Song).filter(Song.id == id).first()
    song_id = (id)

    if not db_songs:
        return 'No songs found'
    
    if song is not None:
        song_res = cloudinary.uploader.upload(song.file, resource_type='auto', folder=f'songs/{song_id}')
        db_songs.song_url = song_res['url']

    if thumbnail is not None:
        thumbnail_res = cloudinary.uploader.upload(thumbnail.file, resource_type='image', folder=f'songs/{song_id}')
        db_songs.thumbnail_url = thumbnail_res['url']

    if song_name is not None:
        db_songs.song_name = song_name
    if artist is not None:
        db_songs.artist = artist
    if hex_code is not None:
        db_songs.hex_code = hex_code

    print('updated')
    db.commit()
    db.refresh(db_songs)
    print(db_songs)
    return db_songs

@router.get('/list/{id}',response_model=SongResponse)
def save_to_downloads(
    id: str,
    db: Session = Depends(get_db),
    auth_details = Depends(auth_middleware),
    ):

    db_song = db.query(Song).filter(Song.id == id).first()
    return db_song


@router.delete('/list/{id}', response_model=SongResponse)
def delete_song(
    id: str,
    db: Session = Depends(get_db), 
    auth_details = Depends(auth_middleware),
   ):
    
    db_song = db.query(Song).filter(Song.id == id).first()

    if not db_song:
        raise HTTPException(
            status_code= 404,
            detail= f"Song with song_id = {id} not found",
        )
    
    db.delete(db_song)
    db.commit()
    db.refresh(db_song)
    # print('See the db_song value',db_song.id)
    return {"message": f"Song with id {id} deleted successfully"}
