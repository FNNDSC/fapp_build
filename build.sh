#!/bin/bash


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
  echo "Usage: $0 <base_directory> <project_name> [<\"project description quoted\">]"
  exit 1
fi

# Set the base project directory
BASE_DIR="$1"
echo "$PROJECT_NAME"
echo "$DESCRIPTION"

# Ensure all required scripts exist
required_scripts=("skeleton_make.sh" "pythonsrc_make.sh" "doc_make.sh" "docker_make.sh")
for script in "${required_scripts[@]}"; do
  if [ ! -f "$script" ]; then
    echo "Error: $script not found in the current directory. Please ensure all scripts are present."
    exit 1
  fi
done

# Run the skeleton_make.sh script
echo "Running skeleton_make.sh..."
chmod +x skeleton_make.sh
./skeleton_make.sh "$BASE_DIR" "$PROJECT_NAME" "$DESCRIPTION"
if [ $? -ne 0 ]; then
  echo "Error: skeleton_make.sh failed."
  exit 1
fi

# Run the pythonsrc_make.sh script
echo "Running pythonsrc_make.sh..."
chmod +x pythonsrc_make.sh
./pythonsrc_make.sh "$BASE_DIR" "$PROJECT_NAME" "$DESCRIPTION"
if [ $? -ne 0 ]; then
  echo "Error: pythonsrc_make.sh failed."
  exit 1
fi

# Run the doc_make.sh script
echo "Running doc_make.sh..."
chmod +x doc_make.sh 
./doc_make.sh "$BASE_DIR" "$PROJECT_NAME" "$DESCRIPTION"
if [ $? -ne 0 ]; then
  echo "Error: doc_make.sh failed."
  exit 1
fi

# Run the docker_make.sh script
echo "Running docker_make.sh..."
chmod +x docker_make.sh
./docker_make.sh "$BASE_DIR" "$PROJECT_NAME" "$DESCRIPTION"
if [ $? -ne 0 ]; then
  echo "Error: docker_make.sh failed."
  exit 1
fi

# Completion message
echo "Project successfully built in $BASE_DIR."
# Check if a base directory is provided as an argument
