# Backend Development

This guide covers Django backend development for Coalition Builder, including models, API endpoints, testing, and database management.

## Architecture

The backend is built with:

- **Django 5.2** - Web framework
- **Django REST Framework** - API framework
- **Django Ninja** - Fast, type-safe API endpoints
- **PostgreSQL 16** - Database
- **PostGIS** - Spatial database extension

## Project Structure

```
backend/
├── coalition/
│   ├── core/           # Core app (homepage, base models)
│   ├── campaigns/      # Campaign management
│   ├── stakeholders/   # Stakeholder management
│   ├── legislators/    # Legislator tracking
│   ├── endorsements/   # Endorsement tracking
│   └── api/           # API endpoints
├── scripts/           # Management scripts
└── manage.py         # Django management
```

## Development Setup

1. **Install Dependencies**:

   ```bash
   cd backend
   poetry install
   ```

2. **Database Setup**:

   ```bash
   # Start PostgreSQL with PostGIS
   docker-compose up -d db

   # Run migrations
   python manage.py migrate

   # Create superuser
   python manage.py createsuperuser
   ```

3. **Run Development Server**:
   ```bash
   python manage.py runserver
   ```

## Models

### Core Models

#### HomePage

Manages dynamic homepage content:

```python
from coalition.core.models import HomePage

# Get active homepage
homepage = HomePage.get_active()

# Create homepage
homepage = HomePage.objects.create(
    organization_name="My Coalition",
    tagline="Building change together",
    hero_title="Welcome to Our Coalition",
    about_section_content="We advocate for...",
    contact_email="info@mycoalition.org"
)
```

#### ContentBlock

Flexible content blocks for homepage:

```python
from coalition.core.models import ContentBlock

# Add content block
block = ContentBlock.objects.create(
    homepage=homepage,
    title="Our Mission",
    block_type="text",
    content="<p>We believe in...</p>",
    order=1,
    is_visible=True
)
```

### Campaign Models

#### PolicyCampaign

Represents advocacy campaigns:

```python
from coalition.campaigns.models import PolicyCampaign

campaign = PolicyCampaign.objects.create(
    title="Clean Water Act",
    slug="clean-water-act",
    summary="Protecting our waterways",
    description="Comprehensive legislation..."
)
```

### Stakeholder Models

#### Stakeholder

Organizations and individuals:

```python
from coalition.stakeholders.models import Stakeholder

stakeholder = Stakeholder.objects.create(
    name="Bay Conservation Society",
    organization="Environmental Nonprofits",
    type="nonprofit",
    state="MD",
    email="contact@bayconservation.org"
)
```

## API Development

### Creating Endpoints

API endpoints use Django Ninja for type safety:

```python
# coalition/api/campaigns.py
from ninja import Router
from coalition.campaigns.models import PolicyCampaign
from .schemas import CampaignSchema

router = Router()

@router.get("/", response=List[CampaignSchema])
def list_campaigns(request):
    return PolicyCampaign.objects.all()

@router.get("/{campaign_id}/", response=CampaignSchema)
def get_campaign(request, campaign_id: int):
    return get_object_or_404(PolicyCampaign, id=campaign_id)
```

### Schemas

Define API schemas for type safety:

```python
# coalition/api/schemas.py
from ninja import Schema
from datetime import datetime

class CampaignSchema(Schema):
    id: int
    title: str
    slug: str
    summary: str
    description: str = None
    created_at: datetime
    updated_at: datetime
```

### Adding to Main API

```python
# coalition/api/api.py
from ninja import NinjaAPI
from .campaigns import router as campaigns_router

api = NinjaAPI()
api.add_router("/campaigns/", campaigns_router)
```

## Database Operations

### Migrations

```bash
# Create migration after model changes
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Check migration status
python manage.py showmigrations
```

### Custom Management Commands

```python
# coalition/core/management/commands/import_legislators.py
from django.core.management.base import BaseCommand
from coalition.legislators.models import Legislator

class Command(BaseCommand):
    def handle(self, *args, **options):
        # Import logic here
        pass
```

Run with:

```bash
python manage.py import_legislators
```

## Testing

### Model Tests

```python
# coalition/core/tests.py
from django.test import TestCase
from coalition.core.models import HomePage

class HomePageModelTest(TestCase):
    def test_create_homepage(self):
        homepage = HomePage.objects.create(
            organization_name="Test Org",
            tagline="Test tagline",
            hero_title="Test title",
            about_section_content="Test content",
            contact_email="test@example.com"
        )
        self.assertEqual(homepage.organization_name, "Test Org")
```

### API Tests

```python
# coalition/api/tests.py
from django.test import TestCase, Client
from coalition.core.models import HomePage

class HomepageAPITest(TestCase):
    def setUp(self):
        self.client = Client()
        self.homepage = HomePage.objects.create(
            organization_name="Test Organization",
            # ... other fields
        )

    def test_get_homepage(self):
        response = self.client.get("/api/homepage/")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["organization_name"], "Test Organization")
```

### Run Tests

```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test coalition.core

# Run with coverage
coverage run --source='.' manage.py test
coverage report
```

## Admin Interface

### Custom Admin

```python
# coalition/core/admin.py
from django.contrib import admin
from .models import HomePage, ContentBlock

class ContentBlockInline(admin.TabularInline):
    model = ContentBlock
    extra = 0

@admin.register(HomePage)
class HomePageAdmin(admin.ModelAdmin):
    inlines = [ContentBlockInline]
    list_display = ('organization_name', 'is_active', 'updated_at')
    list_filter = ('is_active', 'created_at')
```

## Performance

### Database Optimization

```python
# Use select_related for foreign keys
campaigns = PolicyCampaign.objects.select_related('category')

# Use prefetch_related for many-to-many or reverse foreign keys
homepage = HomePage.objects.prefetch_related('content_blocks').first()

# Add database indexes
class Meta:
    indexes = [
        models.Index(fields=['slug']),
        models.Index(fields=['created_at']),
    ]
```

### Caching

```python
from django.core.cache import cache

def get_homepage():
    homepage = cache.get('active_homepage')
    if not homepage:
        homepage = HomePage.get_active()
        cache.set('active_homepage', homepage, 300)  # 5 minutes
    return homepage
```

## Debugging

### Django Debug Toolbar

```python
# settings.py (development only)
if DEBUG:
    INSTALLED_APPS += ['debug_toolbar']
    MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']
```

### Logging

```python
import logging
logger = logging.getLogger(__name__)

def my_view(request):
    logger.info(f"Processing request for {request.user}")
    # ... view logic
```

## Best Practices

1. **Model Design**:

   - Use descriptive field names
   - Add help_text for admin interface
   - Implement proper **str** methods
   - Use model validation

2. **API Design**:

   - Use consistent naming conventions
   - Implement proper error handling
   - Add comprehensive schemas
   - Document endpoints

3. **Testing**:

   - Write tests for all models and views
   - Use factories for test data
   - Test both success and error cases
   - Maintain good test coverage

4. **Security**:
   - Validate all input data
   - Use proper authentication
   - Sanitize user-generated content
   - Follow Django security best practices

## Related Documentation

- [API Reference](../api/index.md)
- [Database Schema](../architecture/database.md)
- [Testing Guide](testing.md)
- [Development Setup](setup.md)
