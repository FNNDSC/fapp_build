# FastAPI project builder

Generate a small, runnable FastAPI service with validated configuration,
health/readiness endpoints, lifecycle logging, tests, Docker, and CI.

The starter has no database, authentication, credential vault, or AI-service
integration. Add those to an application when needed. Reusable authentication
and downstream-service access belong in a separate dependency such as a future
authCore package, rather than copied security implementations.

## Generate a project

Use Python 3.12+ and `uv` for the full build:

```bash
./build.sh ~/src/my_service my_service "My FastAPI service"
```

The destination must be new or empty. The builder creates a Python 3.12 virtual
environment and installs the application plus development dependencies.
Project names must be valid Python distribution names (letters, digits, dots,
hyphens, and underscores, starting and ending with a letter or digit).
The optional name defaults to `default_project`.

To generate files without installing anything:

```bash
./build.sh --no-install ~/src/my_service my_service "My FastAPI service"
```

The script works from any working directory and supports paths containing spaces.
Relative destinations are resolved from the caller's directory. Existing projects
are never overwritten: generate a fresh project and review changes when upgrading.

## Run the generated service

```bash
cd ~/src/my_service
source .venv/bin/activate
uvicorn app.main:app --reload
```

Visit `/health`, `/ready`, or `/docs` at `http://127.0.0.1:8000`.
The generated README covers settings, development, and `docker compose up --build`.

## Repository layout

```text
build.sh                   # Generate files and optionally install dependencies
scripts/generate.py        # Standard-library template renderer
PYTHON-STYLE-GUIDE.md      # Shared Python conventions; copied into generated projects
templates/
    app/
        main.py            # Application factory and lifespan
        settings.py        # APP_ environment configuration
        _metadata.py.tmpl  # Project identity placeholders rendered at generation
        routes/health.py   # Health/readiness response model and routes
    tests/test_app.py      # HTTP, lifecycle, and configuration tests
    pyproject.toml.tmpl    # Runtime dependencies and dev extras
    Dockerfile
    compose.yaml           # API service only
    .github/workflows/ci.yml
    README.md
tests/test_generator.py    # Generator and build-wrapper regression checks
docs/authcore-research.md  # Design assessment and proposed authCore boundary
```

Edit `templates/` to change generated projects. The renderer copies the tree,
including dotfiles, and renders `pyproject.toml.tmpl`, `app/_metadata.py.tmpl`,
and `README.md`. Rendered files lose the `.tmpl` suffix. Metadata is escaped for its target format;
cache files are excluded. Python templates become runnable inside a generated
project. Generation stages files before publishing the output directory.

## Verify changes

Generator checks require only Python's standard library:

```bash
python3 -m unittest discover -s tests -v
```

Exercise the generated application separately:

```bash
./build.sh /tmp/fapp-example fapp_example "Generator verification"
cd /tmp/fapp-example
.venv/bin/python -m pytest
.venv/bin/ruff check .
.venv/bin/ruff format --check .
docker build -t fapp-example .
```

Use a fresh output directory for each run. Repository CI generates a project,
installs it, runs its checks, and builds its container. Generated-project CI does
the same application checks. Neither workflow publishes images.

The earlier scaffold mixed credential-vault, LLM, and MongoDB code from other
applications. Those fragments and placeholder policies/citations have been removed.
See the [architecture assessment](docs/authcore-research.md) for the proposed
separation between this builder and authCore.
