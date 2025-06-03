import asyncio
from fastapi import FastAPI, WebSocket, HTTPException, Depends, Query
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel
from datetime import datetime
import sqlite3
from pydynamic_modules.chat_body import ChatBody
from pydynamic_modules.user import UserProfile
from pydynamic_modules.chat import ChatMessage
from services.llm_service import LLMService
from services.search_service import SearchService
from services.sort_source import SortSourceService
from config import Settings

app = FastAPI()
settings = Settings()

# Initialize services
search_service = SearchService()
sort_source_service = SortSourceService()
llm_service = LLMService()

# Initialize database
def init_db():
    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users
                 (user_id TEXT PRIMARY KEY, username TEXT, email TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS chats
                 (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, query TEXT, response TEXT, timestamp TEXT)''')
    conn.commit()
    conn.close()

init_db()

# Authentication setup
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserCredentials(BaseModel):
    username: str
    password: str

async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub") # type: ignore
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/token")
async def login(credentials: UserCredentials):
    # TODO: Validate credentials against database (e.g., check username and hashed password)
    # For simplicity, assuming valid credentials return a user_id
    user_id = "user123"  # Replace with actual user lookup logic
    token = jwt.encode({"sub": user_id}, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return {"access_token": token, "token_type": "bearer"}

# Profile endpoints
@app.get("/profile/{user_id}")
async def get_profile(user_id: str, current_user: str = Depends(get_current_user)):
    if user_id != current_user:
        raise HTTPException(status_code=403, detail="Not authorized")
    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute("SELECT username, email FROM users WHERE user_id = ?", (user_id,))
    result = c.fetchone()
    conn.close()
    if result:
        return {"user_id": user_id, "username": result[0], "email": result[1]}
    raise HTTPException(status_code=404, detail="User not found")

@app.post("/profile")
async def update_profile(profile: UserProfile, current_user: str = Depends(get_current_user)):
    if profile.user_id != current_user:
        raise HTTPException(status_code=403, detail="Not authorized")
    try:
        conn = sqlite3.connect('users.db')
        c = conn.cursor()
        c.execute("INSERT OR REPLACE INTO users (user_id, username, email) VALUES (?, ?, ?)",
                  (profile.user_id, profile.username, profile.email))
        conn.commit()
        conn.close()
        return {"message": "Profile updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating profile: {str(e)}")

# Chat history endpoints
@app.post("/chat/history")
async def save_chat(chat: ChatMessage, current_user: str = Depends(get_current_user)):
    if chat.user_id != current_user:
        raise HTTPException(status_code=403, detail="Not authorized")
    try:
        conn = sqlite3.connect('users.db')
        c = conn.cursor()
        c.execute("INSERT INTO chats (user_id, query, response, timestamp) VALUES (?, ?, ?, ?)",
                  (chat.user_id, chat.query, chat.response, chat.timestamp.isoformat()))
        conn.commit()
        conn.close()
        return {"message": "Chat saved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saving chat: {str(e)}")

@app.get("/chat/history/{user_id}")
async def get_chat_history(user_id: str, current_user: str = Depends(get_current_user)):
    if user_id != current_user:
        raise HTTPException(status_code=403, detail="Not authorized")
    try:
        conn = sqlite3.connect('users.db')
        c = conn.cursor()
        c.execute("SELECT query, response, timestamp FROM chats WHERE user_id = ? ORDER BY timestamp DESC", (user_id,))
        results = c.fetchall()
        conn.close()
        return [{"query": r[0], "response": r[1], "timestamp": r[2]} for r in results]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving chat history: {str(e)}")

# Chat WebSocket
@app.websocket("/ws/chat")
async def websocket_chat_endpoint(websocket: WebSocket, token: str = Query(...)):
    await websocket.accept()
    try:
        user_id = await get_current_user(token)
        await asyncio.sleep(0.1)
        data = await websocket.receive_json()
        query = data.get("query")
        if not query:
            await websocket.send_json({"type": "error", "data": "Query is required"})
            return
        search_results = search_service.web_search(query)
        if not search_results:
            await websocket.send_json({"type": "error", "data": "No search results found"})
            return
        sorted_results = sort_source_service.sort_sources(query, search_results) or []
        await websocket.send_json({"type": "search_result", "data": sorted_results})
        response_text = ""
        for chunk in llm_service.generate_response(query, sorted_results):
            response_text += chunk
            await websocket.send_json({"type": "content", "data": chunk})
        # Save chat history
        chat = ChatMessage(
            user_id=user_id,
            query=query,
            response=response_text,
            timestamp=datetime.now()
        )
        await save_chat(chat, user_id)
    except Exception as e:
        await websocket.send_json({"type": "error", "data": f"Unexpected error: {str(e)}"})
    finally:
        await websocket.close()

# Chat REST endpoint
@app.post("/chat")
async def chat_endpoint(body: ChatBody, current_user: str = Depends(get_current_user)):
    try:
        search_results = search_service.web_search(body.query)
        if not search_results:
            raise HTTPException(status_code=404, detail="No search results found")
        sorted_result = sort_source_service.sort_sources(body.query, search_results) or []
        response_text = ""
        for chunk in llm_service.generate_response(body.query, sorted_result):
            response_text += chunk
        # Save chat history
        chat = ChatMessage(
            user_id=current_user,
            query=body.query,
            response=response_text,
            timestamp=datetime.now()
        )
        await save_chat(chat, current_user)
        return {"response": response_text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing chat: {str(e)}")