import uuid
import bcrypt
from models.user import User
from fastapi import Depends, HTTPException, APIRouter
from pydantic_schemas.user_create import UserCreate
from database import get_db
from sqlalchemy.orm import Session

from pydantic_schemas.user_login import UserLogin


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
    
    return user_db