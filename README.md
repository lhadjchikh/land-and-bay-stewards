# Coalition Builder

[![Backend Tests](https://github.com/lhadjchikh/coalition-builder/actions/workflows/test_backend.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/test_backend.yml)
[![Frontend Tests](https://github.com/lhadjchikh/coalition-builder/actions/workflows/test_frontend.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/test_frontend.yml)
[![Full Stack Tests](https://github.com/lhadjchikh/coalition-builder/actions/workflows/test_fullstack.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/test_fullstack.yml)
[![Python Lint](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_python.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_python.yml)
[![Prettier Lint](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_prettier.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_prettier.yml)
[![TypeScript Type Check](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_typescript.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_typescript.yml)
[![Terraform Lint](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_terraform.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_terraform.yml)
[![ShellCheck Lint](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_shellcheck.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/lint_shellcheck.yml)

A comprehensive web application for managing policy campaigns, tracking legislative support, and organizing endorsers. Built with Django REST API backend, React TypeScript frontend, and optional Next.js Server-Side Rendering.

## 🌟 Features

- **Policy Campaign Management**: Create and manage advocacy campaigns with legislative tracking
- **Stakeholder Management**: Manage organizations and individuals (farmers, watermen, businesses, nonprofits)
- **Endorsement Tracking**: Collect and display campaign endorsements from stakeholders
- **Legislator Tracking**: Monitor representatives and senators with bill sponsorship data
- **Geographic Data**: PostGIS integration for location-based features
- **Server-Side Rendering**: Optional Next.js SSR for improved SEO and performance
- **Production-Ready**: Secure AWS deployment with Terraform infrastructure as code

## 🏗️ Architecture

This project uses a modern, scalable architecture:

### Backend (Django + PostGIS)

- **Framework**: Django 5.2 with Django REST Framework
- **API**: Django Ninja for fast, type-safe API endpoints
- **Database**: PostgreSQL 16 with PostGIS extension for spatial data
- **Authentication**: Django's built-in auth system
- **Testing**: Comprehensive test suite with coverage

### Frontend (React + TypeScript)

- **Framework**: React 19 with TypeScript for type safety
- **State Management**: React hooks and context
- **HTTP Client**: Axios for API communication
- **Testing**: Jest and React Testing Library
- **Build Tool**: Create React App with TypeScript template

### Optional SSR (Next.js)

- **Framework**: Next.js 14 with App Router
- **Rendering**: Server-side rendering for improved SEO
- **API Integration**: Seamless connection to Django backend
- **Health Monitoring**: Built-in health checks and metrics

### Infrastructure (AWS + Terraform)

- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Amazon ECS Fargate
- **Load Balancing**: Application Load Balancer with intelligent routing
- **Database**: Amazon RDS PostgreSQL with PostGIS
- **Security**: AWS Secrets Manager, KMS encryption, WAF protection
- **Monitoring**: CloudWatch logs, budget alerts, VPC flow logs

## 📁 Project Structure

```
├── backend/                 # Django API server
│   ├── coalition/         # Main Django project
│   │   ├── campaigns/      # Policy campaigns app
│   │   ├── legislators/    # Legislators tracking app
│   │   ├── regions/        # Geographic regions app
│   │   ├── api/           # API endpoints and schemas
│   │   └── core/          # Core settings and configuration
│   ├── stakeholders/       # Stakeholder management app
│   ├── endorsements/       # Campaign endorsements app
│   ├── scripts/           # Backend-specific utilities
│   ├── manage.py          # Django management script
│   └── pyproject.toml     # Python dependencies (Poetry)
├── frontend/               # React TypeScript application
│   ├── src/
│   │   ├── components/    # React components
│   │   ├── services/      # API service layer
│   │   ├── types/         # TypeScript type definitions
│   │   └── tests/         # Test files
│   ├── package.json       # Node.js dependencies
│   └── tsconfig.json      # TypeScript configuration
├── ssr/                   # Next.js Server-Side Rendering (optional)
│   ├── app/              # Next.js App Router pages
│   ├── lib/              # Utility libraries
│   ├── types/            # TypeScript types
│   └── tests/            # Integration tests
├── terraform/            # Infrastructure as Code
│   ├── modules/          # Reusable Terraform modules
│   │   ├── compute/      # ECS, ECR, and container services
│   │   ├── database/     # RDS PostgreSQL with PostGIS
│   │   ├── dns/          # Route53 records and domain management
│   │   ├── loadbalancer/ # Application Load Balancer with SSL
│   │   ├── monitoring/   # CloudWatch, budgets, and alerts
│   │   ├── networking/   # VPC, subnets, and security groups
│   │   ├── secrets/      # AWS Secrets Manager integration
│   │   └── security/     # WAF, security policies, and KMS
│   ├── scripts/          # Database setup and utility scripts
│   ├── tests/            # Terraform unit and integration tests
│   ├── main.tf          # Main infrastructure configuration
│   ├── variables.tf     # Configuration variables
│   └── outputs.tf       # Infrastructure outputs
├── scripts/              # Project-wide automation scripts
│   └── lint.py          # Cross-language linting and formatting
├── .github/workflows/    # CI/CD pipelines
└── docker-compose.yml   # Local development environment
```

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** (recommended for quickest setup)
- **Python 3.13+** with Poetry (for backend development)
- **Node.js 18+** with npm (for frontend development)
- **PostgreSQL 16** with PostGIS (if running locally)
- **GDAL 3.10+** system libraries (for GeoDjango)

### Option 1: Docker Development (Recommended)

Get the entire stack running in minutes:

```bash
# Clone the repository
git clone https://github.com/lhadjchikh/coalition.git
cd coalition

# Start all services (database, backend, frontend, SSR)
docker-compose up

# In another terminal, create test data
docker-compose exec api python backend/scripts/create_test_data.py
```

**Services will be available at:**

- Frontend (React): http://localhost:3000
- Backend API: http://localhost:8000
- Load Balancer: http://localhost:80
- Database: localhost:5432

### Option 2: Local Development

#### Backend Setup

```bash
cd backend

# Install GDAL system packages first (if not using Docker)
# Ubuntu/Debian:
#   sudo apt-get install gdal-bin libgdal-dev
# macOS (Homebrew):
#   brew install gdal

# Install dependencies
poetry install

# Set up environment variables
cp ../.env.example .env
# Edit .env with your database settings

# Run migrations
poetry run python manage.py migrate

# Create a superuser (optional)
poetry run python manage.py createsuperuser

# Start development server
poetry run python manage.py runserver
```

#### Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm start
```

#### SSR Setup (Optional)

```bash
cd ssr

# Install dependencies
npm install

# Start development server
npm run dev
```

## 🧪 Testing

The project includes comprehensive testing at multiple levels:

### Backend Tests

```bash
cd backend
poetry run python manage.py test
```

### Frontend Tests

```bash
cd frontend

# Unit and integration tests
npm test

# Type checking
npm run typecheck

# Linting
npm run lint
```

### End-to-End Tests

```bash
# Start all services first
docker-compose up -d

# Run integration tests
cd frontend
npm run test:e2e
```

### SSR Integration Tests

```bash
cd ssr
npm test
```

### Infrastructure Tests

The Terraform infrastructure includes comprehensive testing using Go and Terratest with AWS SDK v2:

#### Quick Validation (No AWS Resources)

```bash
cd terraform/tests
go test -short ./...    # ✅ Free, 30 seconds, validates all test logic
```

#### Local Development Testing

```bash
# Test individual modules (creates real AWS resources)
make test-networking    # VPC, subnets (~$1, 15m)
make test-compute      # ECS, ECR (~$1, 20m)
make test-security     # Security groups (~$1, 10m)
make test-database     # RDS instance (~$1, 20m)

# Test all modules
make test-unit         # All modules (~$4, 30-45m)

# Full integration testing (complete infrastructure)
make test-integration  # Full stack (~$3-5, 45m)
```

#### Advanced Testing

```bash
# Test specific functions
go test -v -run TestNetworkingModuleCreatesVPC ./modules/

# Debug with verbose Terraform logging
export TF_LOG=DEBUG
go test -v -run TestSpecificTest ./modules/

# Manual testing (comment out cleanup for inspection)
# defer common.CleanupResources(t, terraformOptions)
```

**Features:**

- **Modern AWS SDK v2**: Context-based API calls with proper timeout handling
- **Module Tests**: Unit tests for networking, compute, security, database modules
- **Integration Tests**: End-to-end infrastructure deployment validation
- **Auto Cleanup**: Automatic resource destruction after tests (max 30min)
- **Cost Optimized**: Uses minimal instance sizes and storage for testing
- **Isolated**: Unique resource naming prevents conflicts

📖 **[See terraform/tests/README.md](terraform/tests/README.md) for complete testing documentation**

## 🔧 Development Tools

### Code Quality

The project enforces high code quality standards:

- **Python**: Black formatting, Ruff linting, type hints
- **Go**: gofmt, go vet, staticcheck, golangci-lint (for Terraform tests)
- **TypeScript/JavaScript**: ESLint, Prettier formatting
- **Shell Scripts**: ShellCheck validation and shfmt formatting
- **Terraform**: TFLint validation and formatting

### Quick Setup

**First-time setup** (installs all tools and configures environment):

```bash
# Auto-detect your OS and set up everything
python scripts/setup_dev_env.py

# Or specify your OS
python scripts/setup_dev_env.py --os macos    # macOS
python scripts/setup_dev_env.py --os linux    # Linux
python scripts/setup_dev_env.py --os windows  # Windows
```

**Daily linting** (after setup):

```bash
# Run all linters across the entire project
python scripts/lint.py
```

### Manual Setup

If you prefer manual setup, see [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) for detailed instructions.

### Individual Component Linting

```bash
# Individual component linting (if needed)
cd backend && poetry run black . && poetry run ruff check .
cd frontend && npm run lint:fix && npm run format
cd terraform/tests && make lint
```

### Environment Configuration

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Key environment variables:

```bash
# Django settings
DEBUG=True
SECRET_KEY=your-secret-key-here
DATABASE_URL=postgis://user:password@localhost:5432/coalition
ALLOWED_HOSTS=localhost,127.0.0.1

# For production deployment (see DEPLOY_TO_ECS.md)
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
# ... additional AWS and domain settings
```

## 🚀 Production Deployment

This project includes a complete production deployment setup for AWS:

### Features

- **Secure Infrastructure**: VPC, security groups, encrypted storage
- **Auto-Scaling**: ECS Fargate with health checks and rolling deployments
- **Load Balancing**: Application Load Balancer with SSL termination
- **Database**: RDS PostgreSQL with automated backups
- **Secrets Management**: AWS Secrets Manager for secure credential storage
- **Monitoring**: CloudWatch logs, budget alerts, performance metrics
- **CI/CD**: GitHub Actions with automated testing and deployment

### Quick Deploy

1. **Configure GitHub Secrets** (see [DEPLOY_TO_ECS.md](DEPLOY_TO_ECS.md) for details):

   ```
   AWS_ACCESS_KEY_ID
   AWS_SECRET_ACCESS_KEY
   TF_VAR_db_password
   TF_VAR_route53_zone_id
   TF_VAR_domain_name
   TF_VAR_acm_certificate_arn
   ```

2. **Push to main branch** - GitHub Actions will automatically:

   - Run all tests
   - Build and push Docker images
   - Deploy infrastructure with Terraform
   - Deploy application to ECS

3. **Manual Setup** (alternative):
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

### Configuration Options

The deployment is highly configurable:

- **SSR Toggle**: Enable/disable Next.js SSR with `enable_ssr` variable
- **VPC Options**: Use existing VPC/subnets or create new ones
- **Security**: Configure bastion host access and security groups
- **Scaling**: Adjust task counts and instance sizes
- **Database**: Configure backup retention and instance types

See [terraform/README.md](terraform/README.md) for comprehensive deployment documentation.

## 📚 API Documentation

The Django backend provides a comprehensive REST API:

### Endpoints

- **Campaigns**: `/api/campaigns/` - Policy campaign management
- **Stakeholders**: `/api/stakeholders/` - Stakeholder information and management
- **Endorsements**: `/api/endorsements/` - Campaign endorsement relationships
- **Legislators**: `/api/legislators/` - Representative and senator data
- **Health**: `/health/` - Application health status

### API Features

- **Django Ninja**: Fast, type-safe API with automatic OpenAPI documentation
- **Authentication**: Session-based authentication
- **Pagination**: Efficient data pagination for large datasets
- **Filtering**: Advanced filtering and search capabilities
- **Validation**: Comprehensive input validation and error handling

Access API documentation at: http://localhost:8000/api/docs (when running locally)

## 🌍 Geographic Features

This application includes sophisticated geographic data handling:

- **PostGIS Integration**: Full spatial database capabilities
- **Region Management**: States, congressional districts, counties
- **Spatial Queries**: Location-based filtering and analysis
- **GDAL Support**: Advanced geospatial data processing

## 🔒 Security Features

- **Input Validation**: Comprehensive validation on all inputs
- **SQL Injection Protection**: Parameterized queries and ORM protection
- **XSS Prevention**: React's built-in XSS protection
- **CSRF Protection**: Django CSRF middleware
- **Secure Headers**: Security headers and HTTPS enforcement
- **Database Security**: Encrypted connections and credential management
- **AWS Security**: WAF, security groups, and encrypted storage

## 📖 Additional Documentation

- **[Backend Documentation](backend/README.md)** - Django API details
- **[Frontend Documentation](frontend/README.md)** - React TypeScript guide
- **[SSR Documentation](ssr/README.md)** - Next.js server-side rendering
- **[Deployment Guide](DEPLOY_TO_ECS.md)** - AWS deployment instructions
- **[Infrastructure Docs](terraform/README.md)** - Terraform configuration
- **[GitHub Workflows](.github/workflows/README.md)** - CI/CD pipeline details

## 🐛 Troubleshooting

### Common Issues

**Docker services won't start:**

```bash
# Check for port conflicts
docker-compose down
docker-compose up --build
```

**Database connection errors:**

```bash
# Reset database
docker-compose down -v
docker-compose up
```

**TypeScript errors:**

```bash
cd frontend
npm run typecheck
```

**Test failures:**

```bash
# Run specific test suites
npm test -- --testPathPattern=integration
poetry run python manage.py test campaigns
```

### Getting Help

- Check existing [GitHub Issues](https://github.com/lhadjchikh/coalition-builder/issues)
- Review documentation in the `docs/` directory
- Check the application logs: `docker-compose logs [service-name]`

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

This project demonstrates the power of human-AI collaboration in modern software development. The codebase, infrastructure, and documentation were developed through a collaborative process utilizing:

- [Claude](https://claude.ai/) by Anthropic and [Codex](https://openai.com/codex/) by OpenAI - for code generation, documentation, and troubleshooting
- [GitHub Copilot](https://github.com/features/copilot) - for code snippets and automated code reviews
- Human expertise in system design, testing, and deployment strategies

We believe in transparency about our development process and the tools that help us build better software.

## 🤝 Contributing

This project was built through human-AI collaboration, and like all software, it's not perfect. Whether you spot bugs, have ideas for improvements, or want to add features, please don't hesitate to:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** and add tests
4. **Run the test suite** (see [Testing](#-testing) section)
5. **Submit a pull request**

### Development Guidelines

- Follow existing code style (enforced by linters)
- Add tests for new features
- Update documentation as needed
- Ensure all CI checks pass
