# Coalition Builder Backend

[![Black Code Style](https://github.com/lhadjchikh/coalition-builder/actions/workflows/black.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/black.yml)
[![Ruff Linting](https://github.com/lhadjchikh/coalition-builder/actions/workflows/ruff.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/ruff.yml)
[![Backend Tests](https://github.com/lhadjchikh/coalition-builder/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/backend-tests.yml)

This is the Django backend for Coalition Builder. It provides a REST API for managing
policy campaigns, stakeholders, endorsements, and legislators.

## Technology Stack

- **Python 3.13**: Core programming language
- **Django 5.2**: Web framework
- **Django Ninja**: API framework (FastAPI-inspired)
- **GeoDjango**: For geographic data handling
- **PostGIS**: Spatial database extension for PostgreSQL
- **Poetry**: Dependency management
- **GDAL**: Geospatial Data Abstraction Library

## Project Structure

The backend is organized into several Django apps:

- **campaigns**: Policy campaigns and related bills
- **stakeholders**: Organizations and individuals who can endorse campaigns
- **endorsements**: Relationships between stakeholders and campaigns
- **legislators**: Representatives and senators
- **regions**: Geographic regions (states, counties, etc.)
- **api**: Django Ninja API endpoints and schemas

The project is structured following standard Python package practices:

```
backend/
├── coalition/                 # Main package
│   ├── api/                    # API endpoints
│   ├── campaigns/              # Campaign models and views
│   ├── core/                   # Core project settings and configuration
│   ├── legislators/            # Legislator models and views
│   └── regions/                # Region models and views
├── stakeholders/               # Stakeholder models and admin (separate app)
├── endorsements/               # Endorsement models and admin (separate app)
├── manage.py                   # Django management script
├── pyproject.toml              # Poetry dependencies and tool configuration
└── poetry.lock                 # Locked dependencies
```

## Development Environment

### Prerequisites

- Python 3.13
- Poetry
- GDAL 3.10.3
- PostgreSQL 16 with PostGIS

### Local Setup

1. **Install dependencies**:

   ```bash
   cd backend
   poetry install
   ```

2. **Run migrations**:

   ```bash
   poetry run python manage.py migrate
   ```

3. **Start the development server**:

   ```bash
   poetry run python manage.py runserver
   ```

### Using Docker (Recommended)

The recommended way to run the application is using Docker Compose:

```bash
# From the project root
docker-compose up
```

This will start both the backend and frontend applications, along with a PostGIS database.

## API Endpoints

The API is available at `/api/` with the following routers:

- `/api/campaigns/`: Policy campaign endpoints
- `/api/stakeholders/`: Stakeholder management endpoints
- `/api/endorsements/`: Campaign endorsement endpoints
- `/api/legislators/`: Legislator endpoints

## Code Quality

### Type Checking

This project uses type annotations and encourages static type checking.

### Linting

We use several tools to ensure code quality:

- **Black**: Code formatting

  ```bash
  poetry run black .
  ```

- **Ruff**: Fast linting

  ```bash
  poetry run ruff check .
  ```

## Testing

Run the tests with:

```bash
poetry run python manage.py test
```

For debugging test issues, use the verbose flag:

```bash
poetry run python manage.py test -v 2
```

## Environment Variables

The following environment variables can be configured:

### Development Environment

- `DEBUG`: Set to `True` for development
- `SECRET_KEY`: Django secret key
- `DATABASE_URL`: Database connection URL (supports PostGIS)
- `ALLOWED_HOSTS`: Comma-separated list of allowed hosts

### Production Environment

In production, sensitive credentials are managed through AWS Secrets Manager for enhanced security and SOC 2 compliance:

- **Database Credentials**: Stored securely in AWS Secrets Manager
- **Master Database User**: Administrative user with full database privileges
- **Application Database User**: Restricted user for application access with secure password management

For production deployment configuration, see [DEPLOY_TO_ECS.md](../DEPLOY_TO_ECS.md) in the project root.
