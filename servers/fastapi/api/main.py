import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.sessions import SessionMiddleware
from starlette.middleware.sessions import SessionMiddleware
import ollama
from sqlmodel import SQLModel
from contextlib import asynccontextmanager

from api.routers.presentation.router import presentation_router
from api.auth.router import router as auth_router
from api.services.database import sql_engine
from api.utils.supported_ollama_models import SUPPORTED_OLLAMA_MODELS
from api.utils.utils import is_ollama_selected, update_env_with_user_config

can_change_keys = os.getenv("CAN_CHANGE_KEYS") != "false"

# Ollama model download
if not can_change_keys and is_ollama_selected():
    ollama_model = os.getenv("OLLAMA_MODEL")
    pexels_api_key = os.getenv("PEXELS_API_KEY")
    if not (ollama_model or pexels_api_key):
        raise Exception("OLLAMA_MODEL and PEXELS_API_KEY must be provided")

    if ollama_model not in SUPPORTED_OLLAMA_MODELS:
        raise Exception(f"Model {ollama_model} is not supported")

    print("-" * 50)
    print("Pulling model: ", ollama_model)
    for event in ollama.pull(ollama_model, stream=True):
        print(event)
    print("Pulled model: ", ollama_model)
    print("-" * 50)


@asynccontextmanager
async def lifespan(_: FastAPI):
    os.makedirs(os.getenv("APP_DATA_DIRECTORY"), exist_ok=True)
    SQLModel.metadata.create_all(sql_engine)
    yield


app = FastAPI(lifespan=lifespan)

# Add session middleware for authentication
app.add_middleware(
    SessionMiddleware,
    secret_key=os.getenv("SESSION_SECRET_KEY", "your-secret-key-change-in-production")
)

# Configure CORS
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def update_env_middleware(request: Request, call_next):
    if can_change_keys:
        update_env_with_user_config()
    return await call_next(request)


app.include_router(auth_router)
app.include_router(presentation_router)
