"""Regression checks for project rendering and build failure handling.

Run with ``python -m unittest discover -s tests -v``. Tests use temporary output
directories and a stub uv executable; no packages or external services are needed.
"""

from __future__ import annotations

import ast
import os
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.generate import ProjectSpec, project_generate

REPO_DIR: Path = Path(__file__).resolve().parent.parent


class GeneratorTests(unittest.TestCase):
    """Check generation in isolation, including unsafe inputs and build failures.

    Attributes:
        temporary: Automatically cleaned test workspace.
        workspace: Directory used for callers, stubs, and generated projects.
    """

    def setUp(self) -> None:
        """Allocate a temporary workspace for each test."""
        self.temporary = tempfile.TemporaryDirectory(prefix="fapp-test-")
        self.addCleanup(self.temporary.cleanup)
        self.workspace: Path = Path(self.temporary.name)

    def test_metadata_and_minimal_output(self) -> None:
        """Render valid package metadata and Python for unusual descriptions."""
        description = 'A "quoted" API\\path 🧪\x7f\nwith @@PROJECT_NAME@@ and $(touch unexpected)'
        destination: Path = project_generate(
            ProjectSpec(self.workspace / "project with spaces", "example-api", description)
        )
        metadata = tomllib.loads((destination / "pyproject.toml").read_text())
        self.assertEqual(metadata["project"]["name"], "example-api")
        self.assertEqual(metadata["project"]["description"], description)
        source = ast.parse((destination / "app/_metadata.py").read_text())
        values: dict[str, str] = {
            node.target.id: ast.literal_eval(node.value)
            for node in source.body
            if isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name)
        }
        self.assertEqual(values["DESCRIPTION"], description)
        self.assertEqual(values["NAME"], "example-api")
        self.assertIn(description, (destination / "README.md").read_text())
        for source_path in destination.rglob("*.py"):
            ast.parse(source_path.read_text(), filename=str(source_path))
        self.assertTrue((destination / ".github/workflows/ci.yml").is_file())
        self.assertTrue((destination / ".dockerignore").is_file())
        self.assertTrue((destination / "tests/test_app.py").is_file())
        self.assertTrue((destination / "PYTHON-STYLE-GUIDE.md").is_file())
        self.assertFalse((destination / "app/db").exists())
        self.assertFalse((destination / "app/models/credentialModel.py").exists())
        self.assertNotIn("mongo", (destination / "compose.yaml").read_text())
        self.assertFalse((self.workspace / "unexpected").exists())

    def test_existing_project_is_preserved(self) -> None:
        """Reject nonempty destinations without touching their existing files."""
        destination = self.workspace / "existing"
        destination.mkdir()
        original = destination / "main.py"
        original.write_text("user changes\n")
        with self.assertRaisesRegex(ValueError, "new or empty"):
            project_generate(ProjectSpec(destination))
        self.assertEqual(original.read_text(), "user changes\n")
        self.assertEqual(list(destination.iterdir()), [original])

    def test_empty_destination(self) -> None:
        """Allow an explicitly created empty destination."""
        destination = self.workspace / "empty"
        destination.mkdir()
        project_generate(ProjectSpec(destination))
        self.assertTrue((destination / "app/main.py").is_file())

    def test_invalid_inputs(self) -> None:
        """Reject invalid names, regular-file destinations, and template recursion."""
        with self.assertRaisesRegex(ValueError, "distribution name"):
            project_generate(ProjectSpec(self.workspace / "bad-name", "../bad"))
        blocker = self.workspace / "file"
        blocker.touch()
        with self.assertRaisesRegex(ValueError, "new or empty"):
            project_generate(ProjectSpec(blocker))
        with self.assertRaisesRegex(ValueError, "outside the template"):
            project_generate(ProjectSpec(REPO_DIR / "templates/generated"))
        link = self.workspace / "link"
        link.symlink_to(self.workspace / "target")
        with self.assertRaisesRegex(ValueError, "symbolic link"):
            project_generate(ProjectSpec(link))

    def test_missing_templates(self) -> None:
        """Report missing source templates before creating the destination."""
        destination = self.workspace / "missing"
        with patch("scripts.generate.TEMPLATE_DIR", self.workspace / "absent"):
            with self.assertRaises(FileNotFoundError):
                project_generate(ProjectSpec(destination))
        self.assertFalse(destination.exists())

    def test_failed_render_is_not_published(self) -> None:
        """Keep the output absent when rendering fails after copying templates."""
        destination = self.workspace / "render failure"
        with patch("scripts.generate.re.sub", side_effect=OSError("render failed")):
            with self.assertRaises(OSError):
                project_generate(ProjectSpec(destination))
        self.assertFalse(destination.exists())
        self.assertEqual(list(self.workspace.iterdir()), [])

    def test_wrapper_without_install(self) -> None:
        """Generate from an unrelated working directory into a relative path."""
        result = subprocess.run(
            ["bash", str(REPO_DIR / "build.sh"), "--no-install", "output with spaces"],
            cwd=self.workspace,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.workspace / "output with spaces/app/main.py").is_file())
        self.assertFalse((self.workspace / "output with spaces/.venv").exists())

    def test_wrapper_install_failure(self) -> None:
        """Propagate a dependency-install failure without announcing success."""
        executable = self.workspace / "uv"
        executable.write_text('#!/bin/sh\nif [ "$1" = "pip" ]; then exit 42; fi\nexit 0\n')
        executable.chmod(0o755)
        environment: dict[str, str] = dict(os.environ)
        environment["PATH"] = f"{self.workspace}:{environment['PATH']}"
        result = subprocess.run(
            ["bash", str(REPO_DIR / "build.sh"), "project"],
            cwd=self.workspace,
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 42)
        self.assertNotIn("environment ready", result.stdout)


if __name__ == "__main__":
    unittest.main()
