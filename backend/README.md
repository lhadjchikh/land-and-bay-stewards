# Coalition Builder Backend

[![Black Code Style](https://github.com/lhadjchikh/coalition-builder/actions/workflows/black.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/black.yml)
[![Ruff Linting](https://github.com/lhadjchikh/coalition-builder/actions/workflows/ruff.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/ruff.yml)
[![Backend Tests](https://github.com/lhadjchikh/coalition-builder/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/backend-tests.yml)

This is the Django backend for Coalition Builder. It provides a REST API for managing
policy campaigns, stakeholders, endorsements, legislators, and dynamic homepage content.

## 📚 Documentation

**For complete documentation, visit: [your-org.github.io/coalition-builder](https://your-org.github.io/coalition-builder/)**

Quick links:

- [Backend Development Guide](../docs/development/backend.md)
- [API Reference](../docs/api/index.md)
- [Development Setup](../docs/development/setup.md)

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

- **core**: Homepage content management and project configuration
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
│   ├── api/                    # API endpoints and schemas
│   ├── campaigns/              # Campaign models and views
│   ├── core/                   # Homepage models, settings, and configuration
│   ├── legislators/            # Legislator models and views
│   └── regions/                # Region models and views
├── stakeholders/               # Stakeholder models and admin (separate app)
├── endorsements/               # Endorsement models and admin (separate app)
├── scripts/                    # Utility scripts for development
├── sample_data/                # Sample fixtures for testing
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

- `/api/homepage/`: Homepage content management endpoints
- `/api/campaigns/`: Policy campaign endpoints
- `/api/stakeholders/`: Stakeholder management endpoints
- `/api/endorsements/`: Campaign endorsement endpoints
- `/api/legislators/`: Legislator endpoints

### Homepage API

#### `GET /api/homepage/`

Returns the active homepage configuration with all visible content blocks:

```json
{
  "id": 1,
  "organization_name": "Land and Bay Stewards",
  "tagline": "Protecting our coastal resources",
  "hero_title": "Building Coalitions for Environmental Policy",
  "hero_subtitle": "Join our efforts to protect the Chesapeake Bay",
  "about_section_title": "About Our Mission",
  "about_section_content": "We work to build strong coalitions...",
  "cta_title": "Get Involved",
  "cta_content": "Join our coalition today",
  "cta_button_text": "Learn More",
  "cta_button_url": "/campaigns/",
  "contact_email": "info@landandbay.org",
  "contact_phone": "(555) 123-4567",
  "facebook_url": "https://facebook.com/landandbay",
  "campaigns_section_title": "Current Campaigns",
  "campaigns_section_subtitle": "Active policy initiatives",
  "show_campaigns_section": true,
  "content_blocks": [
    {
      "id": 1,
      "title": "Why Coalition Building Matters",
      "block_type": "text",
      "content": "<p>Effective policy change requires...</p>",
      "order": 1,
      "is_visible": true
    }
  ],
  "is_active": true,
  "created_at": "2024-01-01T10:00:00Z",
  "updated_at": "2024-01-01T10:00:00Z"
}
```

#### `GET /api/homepage/{id}/`

Returns a specific homepage configuration by ID.

#### `GET /api/homepage/{id}/content-blocks/`

Returns all visible content blocks for a specific homepage, ordered by the `order` field.

#### `GET /api/homepage/content-blocks/{block_id}/`

Returns a specific content block by ID.

## Content Management

### Django Admin Interface

Coalition Builder provides a comprehensive Django admin interface for managing homepage content, campaigns, stakeholders, and other data.

#### Accessing the Admin

1. **Create a superuser account**:

   ```bash
   poetry run python manage.py createsuperuser
   ```

2. **Access the admin interface**:
   Navigate to `http://localhost:8000/admin/` and log in with your superuser credentials.

#### Homepage Management

The admin interface provides dedicated sections for managing homepage content:

**Homepage Configuration**:

- Organization information (name, tagline, contact details)
- Hero section (title, subtitle, background image)
- About section content
- Call-to-action configuration
- Social media links
- Campaign section settings

**Content Blocks**:

- Flexible content sections that can be added to the homepage
- Support for different block types: text, image, text+image, quote, statistics, custom HTML
- Drag-and-drop ordering via the `order` field
- Visibility controls for each block
- Rich content editing with HTML support

**Key Features**:

- **Single Active Homepage**: Only one homepage configuration can be active at a time
- **Content Block Management**: Add, edit, and reorder content blocks inline
- **Validation**: Built-in validation ensures data integrity
- **Preview**: Changes are immediately reflected on the frontend

#### Campaign Management

- Create and manage policy campaigns
- Associate bills with campaigns
- Track campaign status and activity

#### Stakeholder Management

- Manage organizations and individuals
- Track contact information and roles
- Categorize by stakeholder type (farmer, waterman, business, nonprofit, etc.)

#### Endorsement Management

- Link stakeholders to campaigns
- Manage endorsement statements
- Control public visibility of endorsements

### Environment-Based Configuration

The application supports environment-based configuration for different organizations:

```bash
# Set organization-specific environment variables
export ORGANIZATION_NAME="Your Organization Name"
export ORG_TAGLINE="Your organization tagline"
export CONTACT_EMAIL="contact@yourorg.org"
```

These variables serve as fallbacks when no homepage configuration exists in the database.

### Sample Data

Load sample data for development and testing:

```bash
poetry run python scripts/create_test_data.py
```

This creates sample campaigns, stakeholders, endorsements, legislators, and homepage content.

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

### Organization Configuration

- `ORGANIZATION_NAME`: Name of the organization (fallback when no homepage exists)
- `ORG_TAGLINE`: Organization tagline or slogan (fallback)
- `CONTACT_EMAIL`: Primary contact email address (fallback)

### Production Environment

In production, sensitive credentials are managed through AWS Secrets Manager for enhanced security and SOC 2 compliance:

- **Database Credentials**: Stored securely in AWS Secrets Manager
- **Master Database User**: Administrative user with full database privileges
- **Application Database User**: Restricted user for application access with secure password management

For production deployment configuration, see [DEPLOY_TO_ECS.md](../DEPLOY_TO_ECS.md) in the project root.
