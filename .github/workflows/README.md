# GitHub Workflows

This directory contains the GitHub Actions workflows for the Land and Bay Stewards project. These workflows automate
testing and other CI/CD processes.

## CI/CD Architecture

This project uses a structured CI/CD pipeline with the following key workflows:

### Test Workflows

#### Frontend Tests (`test_frontend.yml`)

- Triggered by changes to files in the `frontend/` directory
- Runs on multiple Node.js versions (18.x and 20.x)
- Installs dependencies with `npm ci`
- Runs unit and integration tests (excluding E2E tests)
- Builds the frontend application
- Checks for TypeScript errors (if applicable)
- Can be manually triggered with `workflow_dispatch`

#### Backend Tests (`test_backend.yml`)

- Triggered by changes to files in the `backend/` directory, `docker-compose.yml`, or `Dockerfile`
- Sets up Docker and PostgreSQL
- Runs the Django tests inside a Docker container
- Can be manually triggered with `workflow_dispatch`

#### Full Stack Integration Tests (`test_fullstack.yml`)

- Runs on pushes to main branch, pull requests that affect both frontend and backend, or manual triggers
- Focuses specifically on end-to-end tests that verify frontend and backend integration
- Starts the complete application stack in Docker
- Runs the E2E tests from the frontend against the live backend

#### Terraform Tests (`test_terraform.yml`)

- Triggered by changes to files in the `terraform/` directory
- Validates Terraform configurations and formatting
- Runs comprehensive unit tests for individual modules (networking, compute, security, database)
- Runs integration tests that validate module interactions
- **Cost-aware testing**: Creates AWS resources only on main branch pushes or manual triggers
- Includes automatic resource cleanup and cost monitoring
- Supports manual testing scenarios with configurable options

**Test Types:**

- **Unit Tests**: Fast tests without AWS resources (networking, compute, security, database modules)
- **Integration Tests (Short)**: Module interaction tests without AWS resources
- **Integration Tests (Full)**: Complete infrastructure deployment with real AWS resources
- **Cost Monitoring**: Checks for leftover resources and creates alerts

### Deployment Workflow (`deploy-to-ecs.yml`)

- Deploys the application to Amazon ECS
- Triggered automatically after all test workflows complete successfully
- Can be manually triggered with an option to skip tests
- No longer runs redundant tests (as of May 2025)

### Infrastructure Workflow (`infrastructure.yml`)

- Manages AWS infrastructure changes using Terraform
- Runs independently of application code changes

### Code Style Checks

- `python-lint.yml`: Runs Python linters
- `prettier-lint.yml`: Runs prettier for formatting
- `ts-typecheck.yml`: Checks TypeScript types
- `terraform-lint.yml`: Validates Terraform files

## Workflow Dependencies

```
Frontend Tests ─┐
Backend Tests ──┼─► Deploy to ECS ─► Amazon ECS
Full Stack Tests┘

Terraform Tests ─► Infrastructure Changes ─► AWS Resources
```

## Manual Triggers

All workflows can be manually triggered from the GitHub Actions UI. When manually triggering the deployment workflow, you have the option to skip the test requirement (use with caution).

## AWS Credentials

The deployment and infrastructure workflows require AWS credentials to be configured as GitHub environment secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

These credentials should be configured in the GitHub "prod" environment and have the necessary permissions for ECR, ECS, and any other AWS services used in the application.

All production-related jobs have been configured to use the "prod" environment to access these secrets.

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
