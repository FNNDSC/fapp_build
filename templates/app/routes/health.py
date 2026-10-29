"""Liveness and readiness endpoints for the generated service.

HealthResponse defines the probe schema. health_get checks that HTTP requests
can be served; readiness_get checks completion of application startup.
These public probes require no database or external service.
"""

from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Request, Response
from pydantic import BaseModel

router: APIRouter = APIRouter(tags=["Health"])


class HealthResponse(BaseModel):
    """Status returned by the service probes.

    Attributes:
        status: Liveness or readiness state of this application instance.
    """

    status: Literal["ok", "ready", "not_ready"]


@router.get("/health", response_model=HealthResponse)
def health_get() -> HealthResponse:
    """Report that the service can respond to requests.

    Returns:
        A successful liveness response.
    """
    return HealthResponse(status="ok")


@router.get("/ready", response_model=HealthResponse, responses={503: {"model": HealthResponse}})
def readiness_get(request: Request, response: Response) -> HealthResponse:
    """Report whether startup has completed for this application instance.

    Args:
        request: Request carrying the application lifecycle state.
        response: Response whose status becomes 503 when unavailable.

    Returns:
        The readiness state, with HTTP 503 until startup completes.
    """
    if not request.app.state.ready:
        response.status_code = 503
        return HealthResponse(status="not_ready")
    return HealthResponse(status="ready")
