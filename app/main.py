import os
import socket
import json
from datetime import datetime, timezone

import boto3
import psycopg
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


@app.get("/api/database")
def database() -> dict:
    """Validate private RDS connectivity without returning secret material."""
    secret_arn = os.getenv("DATABASE_SECRET_ARN")
    if not secret_arn:
        return {"configured": False, "reachable": False}

    client = boto3.client("secretsmanager", region_name=os.getenv("AWS_REGION"))
    secret = json.loads(client.get_secret_value(SecretId=secret_arn)["SecretString"])
    with psycopg.connect(
        host=secret["host"],
        port=secret["port"],
        dbname=secret["dbname"],
        user=secret["username"],
        password=secret["password"],
        connect_timeout=3,
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()

    return {"configured": True, "reachable": result == (1,)}


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={"environment": os.getenv("ENVIRONMENT", "local")},
    )
