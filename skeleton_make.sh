#!/bin/bash

# Initialize error count
error_count=0


if [ $# -eq 1 ]; then
  BASE_DIR="$1"
  PROJECT_NAME="default_project"
  DESCRIPTION="A FastAPI project"
elif [ $# -ge 2 ]; then
  BASE_DIR="$1"
  PROJECT_NAME="$2"
  DESCRIPTION="${3:-A FastAPI project}"
else
  echo "Invalid arguments."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <base_directory>"
  exit 1
fi

# Set the base project directory
BASE_DIR="$1"

# Function to create directories with error checking
create_directory() {
  local dir_path="$1"
  if mkdir -p "$dir_path"; then
    echo "Created directory: $dir_path"
  else
    echo "Failed to create directory: $dir_path" >&2
    ((error_count++))
  fi
}

# Function to create files with error checking
create_file() {
  local file_path="$1"
  if touch "$file_path"; then
    echo "Created file: $file_path"
  else
    echo "Failed to create file: $file_path" >&2
    ((error_count++))
  fi
}

# Ensure base directory exists
echo "Checking if base directory exists..."
create_directory "$BASE_DIR"

# Directory structure
echo "Creating full directory structure for $BASE_DIR..."
create_directory "$BASE_DIR/app"
create_directory "$BASE_DIR/app/core"
create_directory "$BASE_DIR/app/api/v1/routes"
create_directory "$BASE_DIR/app/models"
create_directory "$BASE_DIR/app/services"
create_directory "$BASE_DIR/app/db/collections"
create_directory "$BASE_DIR/app/utils"
create_directory "$BASE_DIR/tests"
create_directory "$BASE_DIR/tests/test_routes"
create_directory "$BASE_DIR/tests/test_services"
create_directory "$BASE_DIR/tests/test_db"
create_directory "$BASE_DIR/docs"
create_directory "$BASE_DIR/.github/workflows"
create_directory "$BASE_DIR/.github/ISSUE_TEMPLATE"

# Create configuration files
echo "Adding configuration files..."
cat > "$BASE_DIR/.gitignore" << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Virtual environment
.venv/
.env/
env/

# Build artifacts
*.egg-info/
dist/
build/

# Python environment files
.python-version

# Docker artifacts
*.dockerignore

# Editor configurations
.vscode/
.idea/

# Operating system files
.DS_Store
Thumbs.db
EOF

cat > "$BASE_DIR/.editorconfig" << EOF
# EditorConfig helps maintain consistent coding styles for multiple developers
# working on the same project across various editors and IDEs.
root = true

[*]
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 4
charset = utf-8
EOF

# GitHub Actions workflows
echo "Adding GitHub Actions workflows..."
cat > "$BASE_DIR/.github/workflows/docker-publish.yml" << 'EOF'
name: Build and Publish Docker Image

on:
  push:
    branches:
      - main

jobs:
  build-and-push:
    name: Build and Push to GHCR
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract repository name in lowercase
        id: repo_name
        run: echo "repo_lower=$(echo '${{ github.repository }}' | tr '[:upper:]' '[:lower:]')" >> $GITHUB_ENV

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ env.repo_lower }}:latest
            ghcr.io/${{ env.repo_lower }}:${{ github.sha }}
EOF

cat > "$BASE_DIR/.github/workflows/ci.yml" << EOF
name: Continuous Integration

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: "3.12"
    - name: Install dependencies
      run: pip install -r requirements.txt
    - name: Run tests
      run: pytest tests/
EOF

# Add pyproject.toml
echo "Adding pyproject.toml..."
cat > "$BASE_DIR/pyproject.toml" << EOF
[build-system]
requires = ["setuptools>=42", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "$DESCRIPTION"
authors = [
    {name = "Rudolph Pienaar", email = "rudolph.pienaar@childrens.harvard.edu"}
]
license = {text = "MIT"}
readme = {file = "README.adoc", content-type = "text/x-asciidoc"}
dynamic = ["dependencies"]

[tool.setuptools.dynamic]
dependencies = {file = "requirements.txt"}

[project.urls]
homepage = "https://github.com/FNNDSC/$PROJECT_NAME"
repository = "https://github.com/FNNDSC/$PROJECT_NAME"
EOF

# Add requirements.txt
echo "Adding requirements.txt..."
cat > "$BASE_DIR/requirements.txt" << EOF
fastapi
uvicorn
pymongo
pfmongo
EOF

echo "All directories and files created for $BASE_DIR skeleton."
echo "Total errors encountered: $error_count"
# Check if a base directory is provided as an argument
