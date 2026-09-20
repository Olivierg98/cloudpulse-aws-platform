from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_instance_metadata(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "test")
    response = client.get("/api/instance")
    assert response.status_code == 200
    assert response.json()["environment"] == "test"


def test_home():
    response = client.get("/")
    assert response.status_code == 200
    assert "CloudPulse" in response.text


def test_database_reports_not_configured_without_secret(monkeypatch):
    monkeypatch.delenv("DATABASE_SECRET_ARN", raising=False)
    response = client.get("/api/database")
    assert response.status_code == 200
    assert response.json() == {"configured": False, "reachable": False}
