# GitHub Workflows

This directory contains the GitHub Actions workflows for the Land and Bay Stewards project. These workflows automate
testing and other CI/CD processes.

## Available Workflows

### Frontend Tests (`frontend-tests.yml`)

- Triggered by changes to files in the `frontend/` directory
- Runs on multiple Node.js versions (18.x and 20.x)
- Installs dependencies with `npm ci`
- Runs unit and integration tests (excluding E2E tests)
- Builds the frontend application
- Checks for TypeScript errors (if applicable)

### Backend Tests (`backend-tests.yml`)

- Triggered by changes to files in the `backend/` directory, `docker-compose.yml`, or `Dockerfile`
- Sets up Docker and PostgreSQL
- Runs the Django tests inside a Docker container

### Code Style Checks

- `black.yml`: Runs the Black Python code formatter
- `ruff.yml`: Runs the Ruff Python linter
- `js-lint.yml`: Runs ESLint on JavaScript/JSX/TypeScript files

### Full Stack Integration Tests (`full-stack-tests.yml`)

- Runs on pushes to main branch, pull requests that affect both frontend and backend, or manual triggers
- Focuses specifically on end-to-end tests that verify frontend and backend integration
- Starts the complete application stack in Docker
- Runs the E2E tests from the frontend against the live backend

## Running Tests Locally

### Frontend Tests

```bash
cd frontend
npm run test:ci          # Run all tests except E2E tests
npm run test:e2e         # Run only E2E tests (requires backend running)
```

### Backend Tests

```bash
cd backend
python manage.py test    # Run Django tests
```

## Adding New Workflows

When adding new workflows, please follow these conventions:

1. Name your workflow file descriptively (e.g., `component-name-action.yml`)
2. Include clear step names
3. Group related jobs logically
4. Add the workflow to this README
