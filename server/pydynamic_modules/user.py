# server/pydynamic_modules/user.py
from pydantic import BaseModel

class UserProfile(BaseModel):
    user_id: str
    username: str
    email: str