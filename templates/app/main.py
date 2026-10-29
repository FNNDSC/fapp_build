"""FastAPI application factory and ASGI entry point.

application_create builds an isolated service instance; application_lifespan
owns startup/shutdown state. Run with ``uvicorn app.main:app``. The service uses
validated settings, public health probes, and standard-library lifecycle logging.
"""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app import _metadata
from app.routes.health import router
from app.settings import AppSettings

logger: logging.Logger = logging.getLogger("uvicorn.error")


@asynccontextmanager
async def application_lifespan(application: FastAPI) -> AsyncIterator[None]:
    """Manage startup and shutdown for an application instance.

    Args:
        application: Service whose readiness is being managed.

    Yields:
        Control to FastAPI after startup completes.
    """
    application.state.ready = True
    logger.info("Service started: %s", application.title)
    try:
        yield
    finally:
        application.state.ready = False
        logger.info("Service stopped: %s", application.title)


def application_create(settings: AppSettings | None = None) -> FastAPI:
    """Create an application using supplied or environment-derived settings.

    Args:
        settings: Optional validated settings, useful for isolated tests.

    Returns:
        Configured FastAPI application with health and readiness routes.

    Raises:
        pydantic.ValidationError: If environment-derived settings are invalid.
    """
    configuration: AppSettings = settings if settings is not None else AppSettings()
    application: FastAPI = FastAPI(
        title=configuration.name,
        description=configuration.description,
        version=_metadata.VERSION,
        debug=configuration.debug,
        lifespan=application_lifespan,
    )
    application.state.ready = False
    application.include_router(router)
    return application


app: FastAPI = application_create()
