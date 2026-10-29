"""Generate a minimal FastAPI project from the repository's template tree.

ProjectSpec describes the output; project_generate validates the destination,
copies the templates, and renders project metadata without executing user input.
Run this module directly to generate files without installing dependencies.
Only the Python standard library is required.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path

TEMPLATE_DIR: Path = Path(__file__).resolve().parent.parent / "templates"


@dataclass(frozen=True)
class ProjectSpec:
    """Inputs for a generated project.

    Attributes:
        destination: New or empty directory to receive the generated files.
        name: Python distribution name used in package and API metadata.
        description: Human-readable description of the service.
        version: Initial project version.
    """

    destination: Path
    name: str = "default_project"
    description: str = "A FastAPI service"
    version: str = "0.1.0"


def project_generate(spec: ProjectSpec) -> Path:
    """Render a project into a new or empty destination.

    Args:
        spec: Project identity and output location.

    Returns:
        Absolute path to the generated project.

    Raises:
        ValueError: If the name or destination is invalid.
        FileNotFoundError: If the template entry point is missing.
        OSError: If project files cannot be read or written.
    """
    if not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?", spec.name):
        raise ValueError("Project name must be a valid Python distribution name.")
    if spec.destination.is_symlink():
        raise ValueError("Destination must not be a symbolic link.")
    destination: Path = spec.destination.resolve()
    if destination.is_relative_to(TEMPLATE_DIR):
        raise ValueError("Destination must be outside the template directory.")
    if destination.exists() and (not destination.is_dir() or any(destination.iterdir())):
        raise ValueError("Destination must be a new or empty directory.")
    if not (TEMPLATE_DIR / "app/main.py").is_file():
        raise FileNotFoundError(f"Application templates missing from {TEMPLATE_DIR}")

    replacements: dict[str, str] = {
        "PROJECT_NAME_JSON": json.dumps(spec.name),
        "PROJECT_DESCRIPTION_JSON": json.dumps(spec.description, ensure_ascii=False).replace(
            "\x7f", "\\u007f"
        ),
        "PROJECT_VERSION_JSON": json.dumps(spec.version),
        "PROJECT_NAME_PYTHON": repr(spec.name),
        "PROJECT_DESCRIPTION_PYTHON": repr(spec.description),
        "PROJECT_VERSION_PYTHON": repr(spec.version),
        "PROJECT_NAME": spec.name,
        "PROJECT_DESCRIPTION": spec.description,
    }
    rendered_files: dict[str, str] = {
        "pyproject.toml.tmpl": "pyproject.toml",
        "app/_metadata.py.tmpl": "app/_metadata.py",
        "README.md": "README.md",
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Stage beside the destination so failed generation never publishes a partial tree.
    with tempfile.TemporaryDirectory(prefix=".fapp-build-", dir=destination.parent) as tmp:
        staging: Path = Path(tmp) / "project"
        shutil.copytree(
            TEMPLATE_DIR,
            staging,
            ignore=shutil.ignore_patterns(
                "__pycache__", "*.pyc", ".pytest_cache", ".ruff_cache", ".venv"
            ),
        )
        for source_path, target_path in rendered_files.items():
            template: Path = staging / source_path
            target: Path = staging / target_path
            source: str = template.read_text(encoding="utf-8")
            # A single substitution pass preserves token-like text in user descriptions.
            rendered: str = re.sub(
                r"@@([A-Z_]+)@@",
                lambda match: replacements[match.group(1)],
                source,
            )
            target.write_text(rendered, encoding="utf-8")
            if template != target:
                template.unlink()
        shutil.copyfile(
            TEMPLATE_DIR.parent / "PYTHON-STYLE-GUIDE.md", staging / "PYTHON-STYLE-GUIDE.md"
        )
        staging.replace(destination)
    return destination


def command_run() -> None:
    """Parse CLI inputs and generate a project, reporting actionable errors.

    Raises:
        SystemExit: If arguments or generation fail.
    """
    parser: argparse.ArgumentParser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    parser.add_argument("name", nargs="?", default="default_project")
    parser.add_argument("description", nargs="?", default="A FastAPI service")
    options: argparse.Namespace = parser.parse_args()
    spec: ProjectSpec = ProjectSpec(options.destination, options.name, options.description)
    try:
        destination: Path = project_generate(spec)
    except (ValueError, OSError) as error:
        parser.exit(1, f"Error: {error}\n")
    print(f"Project generated in {destination}")


if __name__ == "__main__":
    command_run()
