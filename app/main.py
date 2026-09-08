import os
import socket
from datetime import datetime, timezone

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from starlette.requests import Request

app = FastAPI(title="CloudPulse", version="1.0.0")
templates = Jinja2Templates(directory="app/templates")


@app.get("/health")
def health() -> dict:
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}


@app.get("/api/instance")
def instance() -> dict:
    return {
        "hostname": socket.gethostname(),
        "environment": os.getenv("ENVIRONMENT", "local"),
        "region": os.getenv("AWS_REGION", "local"),
        "version": os.getenv("APP_VERSION", "dev"),
    }


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={"environment": os.getenv("ENVIRONMENT", "local")},
    )
