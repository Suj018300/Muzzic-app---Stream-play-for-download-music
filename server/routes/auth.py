import uuid
import bcrypt
import jwt
from models.favorite import Favorite
from models.user import User
from middleware.auth_middleware import auth_middleware
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests
from fastapi import Depends, HTTPException, APIRouter, Header
from pydantic_schemas.google_user import GoogleLoginSchema
from pydantic_schemas.user_create import UserCreate
from database import get_db
from sqlalchemy.orm import Session
from pydantic_schemas.user_login import UserLogin
from sqlalchemy.orm import joinedload
from dotenv import load_dotenv
import os

load_dotenv()

GOOGLE_CLIENT_ID = os.getenv("CLIENT_ID")
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHUM = os.getenv("ALGORITHUM")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")

router = APIRouter()

@router.post("/signup", status_code=201)
def signup_user(user: UserCreate, db: Session=Depends(get_db)):

    # extract the data that are coming from the req
    user_db = db.query(User).filter(User.email == user.email).first()

    # check if user is already exits
    if user_db:
        raise HTTPException(400, "User with same email already exits.")
    
    hashed_pw = bcrypt.hashpw(user.password.encode(), bcrypt.gensalt(16))
    user_db = User(id=str(uuid.uuid4()), email=user.email, password=hashed_pw, name=user.name)

    # add user to the database
    db.add(user_db)
    db.commit()
    db.refresh(user_db)

    return user_db


@router.post("/login")
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    # check if the user already exits or not 
    user_db = db.query(User).filter(User.email == user.email).first()

    if not user_db:
        raise HTTPException(400, "Email does not exits.")
    
    is_match = bcrypt.checkpw(user.password.encode(), user_db.password)
    
    # password is correct or not
    if not is_match:
        raise HTTPException(401, "Incorrect Password")
    
    token = jwt.encode({'id': str(user_db.id)}, SECRET_KEY, algorithm=ALGORITHUM)
    
    return {'token': token, 'user': user_db}


@router.get("/")
def current_user_data(db: Session = Depends(get_db), user_dic = Depends(auth_middleware)):
    user = db.query(User).filter(User.id == user_dic['uid']).options(
        joinedload(User.favorites)
    ).first()
    
    if not user:
        raise HTTPException(404, 'User not found')
    
    return user

@router.post("/google_sign")
def google_sign_in(user: GoogleLoginSchema, db: Session = Depends(get_db)):
    
    try:
        id_token_value = user.id_token 

        # Verify google id token
        idinfo = google_id_token.verify_oauth2_token(
            id_token_value,
            requests.Request(),
            GOOGLE_CLIENT_ID,
        )
        print("Verified token info:", idinfo),

        email = idinfo.get('email')
        name = idinfo.get('name', '')
        google_id = idinfo.get('sub')

        if not email:
            raise HTTPException(401, 'Google account has no email')
        
        # Check id user already exits in db
        user_db = db.query(User).filter(User.email == email).first()

        if not user_db:
            # Add user to the db
            new_user = User(
                name = name,
                email = email,
                password = None,
                google_id = google_id
            )
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            user_db = new_user

        token_data = {'id': str(user_db.id), 'email':user_db.email}
        app_token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHUM)

        return {
            'token': app_token,
            'user': {
                'id': user_db.id,
                'name': user_db.name,
                'email': user_db.email,
            },
            'message': 'Google Sign in successful'
        }
    except ValueError:
        raise HTTPException(401, 'Invalid google id token')
    
    except Exception as e:
        print("Exception occurred:", e)
        # traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
