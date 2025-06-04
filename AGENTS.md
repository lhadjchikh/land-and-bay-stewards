# Land and Bay Codex Instructions

This repository contains multiple components:

- `backend/` – Django REST API using Poetry
- `frontend/` – React + TypeScript client
- `ssr/` – optional Next.js app for server side rendering
- `terraform/` – IaC definitions

## Testing

Run tests for each part when relevant:

```bash
# Backend tests
cd backend && poetry run python manage.py test

# Frontend unit/integration tests
cd frontend && npm run test:ci

# SSR integration tests (requires backend running)
cd ssr && npm run test:ci
```

The SSR tests expect the backend API running at `http://localhost:8000`. Use `docker-compose up -d` or run the Django server manually if you need to execute them locally.

## Code Quality

- **Python**: format with Black and lint with Ruff – `poetry run black .` and `poetry run ruff check .`
- **JavaScript/TypeScript**: run ESLint and Prettier – `npm run lint` and `npm run format`
- **Terraform**: run `terraform fmt -write=true -recursive` and `tflint` if available
- **Shell scripts**: use `shellcheck` if installed

A convenience command is available:

```bash
cd backend && poetry run lint
```

This script runs formatting and linting across Python, frontend files, Terraform, and shell scripts.

## Contributing Guidelines

- Follow existing project structure when adding new modules or components.
- Update or add tests along with code changes.
- Ensure linters and tests pass before opening a pull request.
- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.
