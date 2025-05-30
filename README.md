# Land and Bay Stewards

[![Backend Tests](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/backend-tests.yml)
[![Frontend Tests](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/frontend-tests.yml/badge.svg)](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/frontend-tests.yml)
[![Full Stack Tests](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/full-stack-tests.yml/badge.svg)](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/full-stack-tests.yml)
[![Black Code Style](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/black.yml/badge.svg)](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/black.yml)
[![Ruff Linting](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/ruff.yml/badge.svg)](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/ruff.yml)
[![TypeScript Type Check](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/ts-typecheck.yml/badge.svg)](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/ts-typecheck.yml)
[![JavaScript & TypeScript Linting](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/js-lint.yml/badge.svg)](https://github.com/lhadjchikh/land-and-bay-stewards/actions/workflows/js-lint.yml)

The Land and Bay Stewards project is a web application for managing and promoting policy campaigns, tracking legislative support, and organizing endorsers. The application consists of a Django backend with GeoDjango support and a React frontend with TypeScript.

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
  - Python 3.12+ with Poetry
  - Node.js 18+ with npm
  - PostgreSQL with PostGIS
  - GDAL 3.10.3

### Quick Start with Docker

The easiest way to run the application is using Docker Compose:

```bash
# Clone the repository
git clone https://github.com/lhadjchikh/land-and-bay-stewards.git
cd land-and-bay-stewards

# Start the application
docker-compose up
```

This will start:

- A PostgreSQL database with PostGIS at port 5433
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

Create a `.env` file in the project root with the following variables:

```
DEBUG=True
SECRET_KEY=your-secret-key
DATABASE_URL=postgis://postgres:postgres@localhost:5433/labs
ALLOWED_HOSTS=localhost,127.0.0.1
```

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

The application can be deployed using the provided Dockerfile, which creates a multi-stage build optimized for production.
