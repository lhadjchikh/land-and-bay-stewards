# Coalition Builder Tests

This directory contains tests for the Coalition Builder frontend application.

## Test Structure

- `integration/` - Tests that verify frontend components with mocked API responses
- `e2e/` - End-to-end tests that verify the integration between frontend and backend

## Running Tests

### Unit and Integration Tests

Run all tests with mock API responses:

```bash
npm test
```

or

```bash
npm test -- --watchAll=false
```

### End-to-End Integration Tests

These tests verify the actual connection between the frontend and backend. They require the backend server to be
running.

1. Start the backend server:

```bash
cd ../backend
python manage.py runserver
```

2. In another terminal, run only the e2e tests:

```bash
cd frontend
npm test -- src/tests/e2e/BackendIntegration.test.js
```

## Skipping E2E Tests in CI/CD

The E2E tests are set up to be skipped in CI/CD environments by checking for the `CI=true` environment variable. If you
want to manually skip these tests, you can run:

```bash
SKIP_E2E=true npm test
```

## Adding New Tests

- For component tests, add them to the appropriate component file or create a new one in `src/`
- For frontend integration tests with mock API, add them to `integration/`
- For full stack tests that require the backend, add them to `e2e/`
