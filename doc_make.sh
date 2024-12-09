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

# Documentation files
echo "Adding documentation files..."

# README.adoc
cat > "$BASE_DIR/README.adoc" << EOF
= $PROJECT_NAME: Web-based Holistic AI Manager

$PROJECT_NAME is a FastAPI-based web application for managing AI models, tasks, and users. This project includes a MongoDB backend, RESTful APIs, and service layers for scalable deployments.

== Features
- User Management
- Task and AI Model Management
- RESTful APIs with versioning
- MongoDB integration using pfmongo
- Dockerized deployment

== Installation and Usage
Refer to the link below for detailed setup and usage instructions:
link:HOWTORUN.adoc[How to Run the $PROJECT_NAME Server Locally]

== Contributing
We welcome contributions! Please see link:CONTRIBUTING.adoc[CONTRIBUTING.adoc] for guidelines.

== License
This project is licensed under the MIT License.

== Acknowledgements
This project is developed and maintained by Rudolph Pienaar and contributors.
EOF

# Function to generate HOWTORUN.adoc content and write it to a file
generate_howtorun_adoc() {
    local project_name="$1"
    local output_file="$2"

    # Dynamically generate the content as a string
    local content
    content="
= How to Run the $project_name Server Locally

This document provides step-by-step instructions for setting up and running the $project_name server locally.

== Prerequisites
1. Install Python 3.12 or later.
2. Install MongoDB.

== Steps to Run the Server

=== 1. One-time local setup

To run the server locally, the overall approach is to clone the repo, create a python virtual environment, and install the dependencies and application. This is typically a one-time activity.

==== 1.1. Clone the Repository
Clone the repository to your local machine:
----
git clone https://github.com/FNNDSC/$project_name.git
cd $project_name
----

==== 1.2. Create and activate a python virtual environment
Create a +venv+ in the repo directory:

----
python -m venv venv
----

and "activate" it:

----
source venv/bin/activate
----

==== 1.3. Install Dependencies
Install the required dependencies using \`pip\`:
----
pip install -r requirements.txt
----

==== 1.4. Install the Application in Editable Mode
To ensure the application is available for \`uvicorn\`, install it in the current environment:
----
pip install -e .
----

=== 2. Start MongoDB
Now, assuming the application an dependencies are setup in a local python virtual environment, start MongoDB locally or using Docker Compose:
----
docker-compose up
----

=== 3. Run the WHAM Server
Run the FastAPI server using \`uvicorn\`:
----
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
----

=== 4. Access the Application
Open your browser and navigate to:

- API Root: http://127.0.0.1:8000
- Interactive API Docs: http://127.0.0.1:8000/docs

"

    # Write the generated content to the file
    echo "$content" > "$output_file"
}
generate_howtorun_adoc "$PROJECT_NAME" "$BASE_DIR/HOWTORUN.adoc"

# CODE_OF_CONDUCT.adoc
cat > "$BASE_DIR/CODE_OF_CONDUCT.adoc" << EOF
= Code of Conduct

As contributors and maintainers of this project, we pledge to respect all participants and foster a welcoming and inclusive community.

== Our Standards
- Be respectful of differing viewpoints.
- Provide constructive feedback.
- Avoid offensive language or behavior.

== Enforcement
Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by contacting the project team at support@example.com. All complaints will be reviewed and addressed promptly.

EOF

# CONTRIBUTING.adoc
cat > "$BASE_DIR/CONTRIBUTING.adoc" << EOF
= Contributing to $PROJECT_NAME

We welcome contributions to $PROJECT_NAME! Please follow these guidelines to contribute effectively.

== Ways to Contribute
- Report bugs or issues.
- Suggest features or improvements.
- Submit pull requests with bug fixes or new features.

== Development Workflow
1. Fork the repository.
2. Create a feature branch: \`git checkout -b feature-branch-name\`.
3. Commit your changes: \`git commit -m "Add feature X"\`.
4. Push to your branch: \`git push origin feature-branch-name\`.
5. Open a pull request.

== Code of Conduct
Please adhere to the link:CODE_OF_CONDUCT.adoc[Code of Conduct] while contributing.

== License
By contributing to this project, you agree that your contributions will be licensed under the MIT License.
EOF

# SECURITY.adoc
cat > "$BASE_DIR/SECURITY.adoc" << EOF
= Security Policy

We take security issues seriously. If you discover a vulnerability, please report it responsibly.

== Reporting a Vulnerability
To report a vulnerability:
1. Email our security team at security@example.com.
2. Include a detailed description of the issue and steps to reproduce it.

== Supported Versions
We currently support the following versions:
- Version 0.1.x: Fully supported
- Version 0.0.x: No longer supported

== Response
We will review your report promptly and work to address the issue. You will receive an acknowledgment within 48 hours.

EOF


# architecture.adoc
cat > "$BASE_DIR/docs/architecture.adoc" << EOF
= $PROJECT_NAME Architecture Overview

$PROJECT_NAME is designed as a modular, scalable, and maintainable application for AI model management.

== Components
- **FastAPI**: Framework for building RESTful APIs.
- **MongoDB**: Database for storing user, task, and AI model data.
- **Docker**: Used for containerized deployment.

== Layers
- **API Layer**: Exposes RESTful endpoints.
- **Service Layer**: Contains business logic.
- **Database Layer**: Interfaces with MongoDB using pfmongo.

== Scalability
- Stateless services allow horizontal scaling.
- Database design supports sharding and replication.

== Deployment
- Local development uses Docker Compose.
- Production deployments use Kubernetes or similar platforms.

For a detailed architecture diagram, see future revisions of this document.
EOF

# CITATION.cff
cat > "$BASE_DIR/CITATION.cff" << EOF
cff-version: 1.2.0
message: "If you use $PROJECT_NAME, please cite it as below."
authors:
  - family-names: "Pienaar"
    given-names: "Rudolph"
title: "$PROJECT_NAME: Web-based Holistic AI Manager"
version: "0.1.0"
date-released: "2024-12-05"
EOF

echo "All documentation and citation files created for $BASE_DIR."
echo "Total errors encountered: $error_count"
# Check if a base directory is provided as an argument
