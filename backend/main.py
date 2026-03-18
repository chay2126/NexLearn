from __future__ import annotations

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import init_db
from routes.chemistry import router as chemistry_router
from routes.english import router as english_router
from routes.topics import router as topics_router


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="NexLearn API",
    version="1.0.0",
    summary="Interactive learning API for chemistry simulations and English analysis",
    lifespan=lifespan,
)

origins = os.getenv("CORS_ALLOWED_ORIGINS", "*")
if origins == "*":
    allow_origins = ["*"]
else:
    allow_origins = [origin.strip() for origin in origins.split(",") if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(topics_router)
app.include_router(chemistry_router)
app.include_router(english_router)


@app.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}
