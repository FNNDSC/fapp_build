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

# Add Dockerfile
echo "Adding Dockerfile..."
cat > "$BASE_DIR/Dockerfile" << 'EOF'
# Use the official Python image as a parent image
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port the app runs on
EXPOSE 8000

# Define environment variables
ENV PYTHONUNBUFFERED=1

# Run the FastAPI app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Add docker-compose.yml
echo "Adding docker-compose.yml..."
cat > "$BASE_DIR/docker-compose.yml" << 'EOF'
version: "3.8"

services:
  pfapp-maybe-change-name:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - MONGO_URI=mongodb://admin:admin@mongo:27017
    depends_on:
      - mongo

  mongo:
    image: mongo:latest
    container_name: pfmongo-db
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: admin
    security_opt:
      - seccomp:unconfined
    ports:
      - "27017:27017"
    volumes:
      - type: volume
        source: MONGO_DATA
        target: /data/db
      - type: volume
        source: MONGO_CONFIG
        target: /data/configdb

  mongo-express:
    image: mongo-express:latest
    container_name: pfmongo-db-ui
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: admin
      ME_CONFIG_MONGODB_SERVER: mongo
      ME_CONFIG_MONGODB_PORT: "27017"
    ports:
      - "8081:8081"
    depends_on:
      - mongo
    restart: unless-stopped

volumes:
  MONGO_DATA:
  MONGO_CONFIG:
EOF

echo "Dockerfile and docker-compose.yml created in $BASE_DIR."
echo "Total errors encountered: $error_count"
# Check if a base directory is provided as an argument
