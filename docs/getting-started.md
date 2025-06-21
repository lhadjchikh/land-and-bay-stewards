# Getting Started

Coalition Builder is a comprehensive web application for managing policy campaigns, tracking legislative support, and organizing endorsers. This guide will help you get up and running quickly.

## Overview

Coalition Builder consists of three main components:

- **Backend**: Django REST API with PostgreSQL database
- **Frontend**: React TypeScript application
- **SSR (Optional)**: Next.js server-side rendering for improved SEO

## Quick Setup

### Prerequisites

- Docker and Docker Compose
- Node.js 18+ (for local development)
- Python 3.10+ (for local development)
- PostgreSQL 16+ with PostGIS (for local development)

### Option 1: Docker (Recommended)

1. Clone the repository:

   ```bash
   git clone https://github.com/your-org/coalition-builder.git
   cd coalition-builder
   ```

2. Start the services:

   ```bash
   docker-compose up -d
   ```

3. Create test data:

   ```bash
   docker-compose exec backend python scripts/create_test_data.py
   ```

4. Access the application:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - Django Admin: http://localhost:8000/admin
   - SSR (if enabled): http://localhost:3001

### Option 2: Local Development

For detailed local development setup, see [Development Setup](development/setup.md).

## First Steps

### 1. Access Django Admin

1. Create a superuser:

   ```bash
   docker-compose exec backend python manage.py createsuperuser
   ```

2. Login to Django admin at http://localhost:8000/admin

### 2. Configure Your Homepage

1. In Django admin, go to "Homepage Configurations"
2. Edit the existing homepage or create a new one
3. Add your organization's information and content blocks

For detailed instructions, see [Content Management Guide](user-guides/content-management.md).

### 3. Add Your Data

1. **Campaigns**: Create policy campaigns you're advocating for
2. **Stakeholders**: Add organizations and individuals who might endorse
3. **Legislators**: Import or add representatives and senators
4. **Endorsements**: Track support for your campaigns

## Environment Configuration

Key environment variables to configure:

```bash
# Basic Configuration
ORGANIZATION_NAME="Your Organization"
ORG_TAGLINE="Your mission statement"
CONTACT_EMAIL="info@yourorg.org"

# Database
DATABASE_URL="postgresql://user:pass@localhost:5432/coalition"

# Security (set in production)
SECRET_KEY="your-secret-key"
DEBUG=False
ALLOWED_HOSTS="yourdomain.com,www.yourdomain.com"
```

For a complete list, see [Environment Variables Reference](reference/environment.md).

## Next Steps

- [Content Management](user-guides/content-management.md) - Customize your homepage
- [API Usage](user-guides/api-usage.md) - Integrate with the API
- [Development Setup](development/setup.md) - Set up local development
- [Deployment Guide](deployment/aws.md) - Deploy to production

## Need Help?

- Check the [Troubleshooting Guide](admin/troubleshooting.md)
- Review the [Architecture Overview](architecture/overview.md)
- Browse the [API Reference](api/index.md)
