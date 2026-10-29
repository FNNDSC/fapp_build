"""HTTP and configuration checks for a generated application.

The tests exercise real FastAPI requests and lifespan handling with TestClient.
Run ``python -m pytest`` after installing the project's dev dependencies.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app import _metadata
from app.main import application_create
from app.settings import AppSettings


def test_health_and_readiness() -> None:
    """Serve probes during lifespan and clear readiness after shutdown."""
    application = application_create()
    assert application.state.ready is False
    with TestClient(application) as client:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}
        response = client.get("/ready")
        assert response.status_code == 200
        assert response.json() == {"status": "ready"}
    assert application.state.ready is False


def test_readiness_before_startup() -> None:
    """Return an unavailable response when lifespan has not started."""
    client: TestClient = TestClient(application_create())
    try:
        response = client.get("/ready")
        assert response.status_code == 503
        assert response.json() == {"status": "not_ready"}
    finally:
        client.close()


def test_openapi_metadata() -> None:
    """Expose the configured identity and only the starter's probe routes."""
    settings: AppSettings = AppSettings(name="Example service", description="Example API")
    with TestClient(application_create(settings)) as client:
        schema = client.get("/openapi.json").json()
        assert schema["info"]["title"] == "Example service"
        assert schema["info"]["description"] == "Example API"
        assert schema["info"]["version"] == _metadata.VERSION
        assert set(schema["paths"]) == {"/health", "/ready"}


def test_environment_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    """Read explicit environment overrides when constructing an application.

    Args:
        monkeypatch: Fixture restoring environment values after the test.
    """
    monkeypatch.setenv("APP_NAME", "Configured service")
    monkeypatch.setenv("APP_DEBUG", "false")
    application = application_create()
    assert application.title == "Configured service"
    assert application.debug is False


def test_invalid_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    """Reject invalid settings before the application starts serving.

    Args:
        monkeypatch: Fixture restoring environment values after the test.
    """
    monkeypatch.setenv("APP_DEBUG", "invalid")
    with pytest.raises(ValidationError):
        application_create()
