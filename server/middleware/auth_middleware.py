from google.oauth2 import id_token
from dotenv import load_dotenv
from fastapi import HTTPException, Header
from google.auth.transport import requests
import os
import jwt


load_dotenv()

GOOGLE_CLIENT_ID = os.getenv("CLIENT_ID")
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHUM = os.getenv("ALGORITHUM")


def auth_middleware(x_auth_token: str = Header(default=None)):
    try:
        # get user token from the headers
        if not x_auth_token:
            raise HTTPException(401, "No auth token, access denied!")
    
        try:
            verified_token = jwt.decode(x_auth_token, SECRET_KEY, ALGORITHUM)
            uid = verified_token.get('id')
            return {'uid' : uid, 'token': x_auth_token, "auth_type": "local"}
        except jwt.PyJWTError:
            pass

        try:
            idinfo = id_token.verify_oauth2_token(
                x_auth_token,
                requests.Request(),
                GOOGLE_CLIENT_ID,
            )

            uid = idinfo.get("sub")
            email = idinfo.get("email")

            return {'uid' : uid, 'token': x_auth_token, "auth_type": "google"}
        except ValueError:
            raise HTTPException(401, "Invalid Google Id token")
    
        # postgres database get the user info
    except Exception as e:
        raise HTTPException(401, detail=str(e))