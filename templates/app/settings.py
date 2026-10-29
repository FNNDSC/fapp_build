"""Validated service configuration with APP_ environment overrides.

AppSettings supplies API metadata and an explicit debug flag. Construct it at
application creation so invalid configuration fails before serving requests.
For example, APP_NAME overrides the generated project name. Uses Pydantic Settings.
"""

from __future__ import annotations

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

from app import _metadata


class AppSettings(BaseSettings):
    """Service settings loaded from defaults and environment variables.

    Attributes:
        name: Display name used by the API and lifecycle logs.
        description: Description shown in the OpenAPI documentation.
        debug: Enable debug responses; disabled by default.
    """

    model_config = SettingsConfigDict(env_prefix="APP_", extra="ignore")

    name: str = Field(default=_metadata.NAME, min_length=1)
    description: str = _metadata.DESCRIPTION
    debug: bool = False
