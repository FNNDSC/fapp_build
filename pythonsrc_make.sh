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

# Python files for the app
echo "Creating Python files for the app..."
create_file "$BASE_DIR/app/__init__.py"

# MongoDB Client with pfmongo
create_directory "$BASE_DIR/app/db"
cat > "$BASE_DIR/app/db/mongo_client.py" << 'EOF'
import os
# from pfmongo import MongoClient

mongo_uri = os.getenv("MONGO_URI", "mongodb://admin:admin@localhost:27017")
# client = MongoClient(mongo_uri)
# db = client.get_database("$PROJECT_NAME")
EOF

# Main entry point
cat > "$BASE_DIR/app/main.py" << 'EOF'
from fastapi import FastAPI
from app.api.v1.routes import users

app = FastAPI()

@app.get("/")
async def read_root():
    return {"message": "Welcome to $PROJECT_NAME!"}

app.include_router(users.router, prefix="/users", tags=["users"])
EOF

# API Route Example
create_directory "$BASE_DIR/app/api/v1/routes"
cat > "$BASE_DIR/app/api/v1/routes/users.py" << 'EOF'
from fastapi import APIRouter
# from app.db.mongo_client import db

router = APIRouter()

@router.get("/")
async def get_users():
    # users = db.users.find()
    users = {"name": "Some One", "email": "someone@somewhere.fun"}
    return [{"name": user["name"], "email": user["email"]} for user in users]
EOF

echo "Python files created with pfmongo integration in $BASE_DIR."
echo "Total errors encountered: $error_count"
# Check if a base directory is provided as an argument
