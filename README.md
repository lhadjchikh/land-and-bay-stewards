# Land and Bay Stewards (landandbay.org)

[![Backend Tests](https://github.com/lhadjchikh/landandbay/actions/workflows/test_backend.yml/badge.svg)](https://github.com/lhadjchikh/landandbay/actions/workflows/test_backend.yml)
[![Frontend Tests](https://github.com/lhadjchikh/landandbay/actions/workflows/test_frontend.yml/badge.svg)](https://github.com/lhadjchikh/landandbay/actions/workflows/test_frontend.yml)
[![Full Stack Tests](https://github.com/lhadjchikh/landandbay/actions/workflows/test_fullstack.yml/badge.svg)](https://github.com/lhadjchikh/landandbay/actions/workflows/test_fullstack.yml)
[![Python Lint](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_python.yml/badge.svg)](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_python.yml)
[![Prettier Lint](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_prettier.yml/badge.svg)](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_prettier.yml)
[![TypeScript Type Check](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_typescript.yml/badge.svg)](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_typescript.yml)
[![Terraform Lint](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_terraform.yml/badge.svg)](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_terraform.yml)
[![ShellCheck Lint](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_shellcheck.yml/badge.svg)](https://github.com/lhadjchikh/landandbay/actions/workflows/lint_shellcheck.yml)

The Land and Bay Stewards (landandbay.org) project is a web application for managing and promoting policy campaigns,
tracking legislative support, and organizing endorsers. The application consists of a Django backend with GeoDjango
support and a React frontend with TypeScript.

## Project Overview

This project is a full-stack web application with:

- **Backend**: Django REST API with PostGIS for spatial data
- **Frontend**: React with TypeScript
- **Database**: PostgreSQL with PostGIS extension
- **Deployment**: Docker containerization

## Repository Structure

The repository is organized into two main directories:

- **[/backend](/backend)**: Django backend code
- **[/frontend](/frontend)**: React frontend code

## Getting Started

### Prerequisites

- Docker and Docker Compose (recommended)
- Alternatively:
  - Python 3.13+ with Poetry
  - Node.js 18+ with npm
  - PostgreSQL with PostGIS
  - GDAL 3.10.3

### Quick Start with Docker

The easiest way to run the application is using Docker Compose:

```bash
# Clone the repository
git clone https://github.com/lhadjchikh/landandbay.git
cd landandbay

# Start the application
docker-compose up
```

This will start:

- A PostgreSQL database with PostGIS at port 5432
- The Django backend at http://localhost:8000
- The React frontend at http://localhost:3000

### Manual Setup

#### Backend

```bash
cd backend
poetry install
poetry run python manage.py migrate
poetry run python manage.py runserver
```

#### Frontend

```bash
cd frontend
npm install
npm start
```

## Development Workflow

### Environment Variables

A `.env.example` file is provided in the project root as a template. Copy it to create your own `.env` file:

```bash
cp .env.example .env
```

For local development, the following variables are required:

```
# Django settings
DEBUG=True
SECRET_KEY=your-secret-key
DATABASE_URL=postgis://landandbay_app:app_password@localhost:5432/landandbay
ALLOWED_HOSTS=localhost,127.0.0.1
```

Note that the database uses two separate users for enhanced security:

- An administrative user (`landandbay_admin`) with privileges to create databases and users
- An application user (`landandbay_app`) with restricted privileges for security

For production deployments, database credentials are securely managed through AWS Secrets Manager to meet SOC 2 compliance requirements, with secure password management. Future enhancements may include automated password rotation.

For deployment to AWS, additional variables are required. See [DEPLOY_TO_ECS.md](DEPLOY_TO_ECS.md) for details.

### Testing

The project includes comprehensive test suites for both backend and frontend:

```bash
# Backend tests
cd backend
poetry run python manage.py test

# Frontend tests
cd frontend
npm test
```

### Code Quality

The project enforces code quality standards:

#### Backend

- Black for code formatting
- Ruff for linting
- Type annotations

#### Frontend

- ESLint for linting
- TypeScript for type checking

## Continuous Integration

GitHub Actions workflows run tests and linting on pull requests and pushes to the main branch:

- Backend tests
- Frontend tests
- Integration tests
- Code quality checks (Black, Ruff, ESLint, TypeScript)

## Deployment

This project is set up for deployment to AWS ECS (Elastic Container Service) with Terraform infrastructure as code, following SOC 2 compliance best practices.

### Deploying to Amazon ECS

This project includes a comprehensive setup for deploying to AWS ECS with:

1. **Terraform** for infrastructure provisioning
2. **GitHub Actions** for CI/CD
3. **Amazon ECS** for container orchestration
4. **Amazon RDS** for PostgreSQL with PostGIS
5. **AWS Secrets Manager** for secure credential management

To deploy:

1. Set up your AWS account and create IAM credentials
2. Configure GitHub repository secrets for AWS access
3. Trigger the GitHub Actions workflow
4. Follow the detailed steps in [DEPLOY_TO_ECS.md](DEPLOY_TO_ECS.md)

The deployment includes:

- Containerized application running on ECS Fargate
- RDS PostgreSQL database with PostGIS extension
- Application Load Balancer for routing traffic
- ECR for container registry
- Automated CI/CD pipeline via GitHub Actions
- Infrastructure as code with Terraform

## Cleanup

To remove all AWS resources created by this project:

1. Navigate to the "Actions" tab in your GitHub repository
2. Select the "Terraform Destroy" workflow
3. Click "Run workflow"
4. Confirm the action

This will clean up all AWS resources created for this project.

## License

This project is licensed under the terms of the license included in the repository.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
