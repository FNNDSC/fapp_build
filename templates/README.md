# @@PROJECT_NAME@@

@@PROJECT_DESCRIPTION@@

A Python 3.12+ FastAPI starter with environment-based configuration, lifecycle
logging, health probes, tests, and a container build.

## Run locally

If generated using the full builder, dependencies are already installed in `.venv`.
Otherwise, create the environment and install the application:

```bash
uv venv --python 3.12
uv pip install --python .venv/bin/python -e '.[dev]'
```

Then start the development server:

```bash
source .venv/bin/activate
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

| URL | Purpose |
|-----|---------|
| `/health` | Liveness: the server can answer requests |
| `/ready` | Readiness: startup completed; returns 503 when unavailable |
| `/docs` | Interactive API documentation |
| `/openapi.json` | OpenAPI schema |

Readiness currently tracks only application startup; extend the lifespan and probe
when adding required resources. There is no database or authentication dependency.
These endpoints are public. Add identity and authorization explicitly when adding
protected application routes.

## Configuration

Settings are validated when the app is created:

| Environment variable | Default | Purpose |
|----------------------|---------|---------|
| `APP_NAME` | Generated project name | API title |
| `APP_DESCRIPTION` | Generated description | API description |
| `APP_DEBUG` | `false` | Debug responses for local development |

Environment files are not loaded automatically. Lifecycle events use Python's
standard logging through Uvicorn's configured logger; adjust verbosity with
Uvicorn's `--log-level` option.

## Development

```bash
python -m pytest
ruff check .
ruff format --check .
```

The code lives in `app/main.py`, `app/settings.py`, and `app/routes/health.py`.
`app/_metadata.py` contains generated identity/version defaults and is included in
installed packages. Keep its version aligned with `pyproject.toml` when releasing.
Put new route modules in `app/routes/` and register them in `application_create`.
Follow [PYTHON-STYLE-GUIDE.md](PYTHON-STYLE-GUIDE.md).

CI runs linting, formatting checks, tests, and a Docker build. It does not publish images.

## Container

```bash
docker compose up --build
```

The API is available on port 8000. The container runs as a non-root user, installs
only runtime dependencies, and needs no companion services.
