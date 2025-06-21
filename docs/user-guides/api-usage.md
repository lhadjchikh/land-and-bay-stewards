# API Usage Guide

This guide covers how to use the Coalition Builder API to integrate with external systems, build custom applications, or automate campaign management tasks.

## Authentication

Currently, the API uses Django's session-based authentication. For production use, consider implementing token-based authentication.

```python
import requests

# Login to get session
session = requests.Session()
login_response = session.post('http://localhost:8000/admin/login/', {
    'username': 'your_username',
    'password': 'your_password'
})
```

## Base URL

```
Local Development: http://localhost:8000/api/
Production: https://your-domain.com/api/
```

## Common Endpoints

### Homepage Configuration

Get the active homepage configuration:

```bash
curl http://localhost:8000/api/homepage/
```

Response:

```json
{
  "id": 1,
  "organization_name": "Coalition Builder",
  "tagline": "Building strong advocacy partnerships",
  "hero_title": "Welcome to Coalition Builder",
  "content_blocks": [
    {
      "id": 1,
      "title": "Our Mission",
      "block_type": "text",
      "content": "<p>We build strong coalitions...</p>",
      "order": 1,
      "is_visible": true
    }
  ]
}
```

### Policy Campaigns

List all campaigns:

```bash
curl http://localhost:8000/api/campaigns/
```

Get a specific campaign:

```bash
curl http://localhost:8000/api/campaigns/1/
```

### Stakeholders

List stakeholders:

```bash
curl http://localhost:8000/api/stakeholders/
```

Filter by state:

```bash
curl "http://localhost:8000/api/stakeholders/?state=MD"
```

### Legislators

List legislators:

```bash
curl http://localhost:8000/api/legislators/
```

Filter by chamber:

```bash
curl "http://localhost:8000/api/legislators/?chamber=House"
```

### Endorsements

List endorsements:

```bash
curl http://localhost:8000/api/endorsements/
```

## API Schema

The API provides an interactive schema at:

- OpenAPI Schema: http://localhost:8000/api/openapi.json
- Interactive Docs: http://localhost:8000/api/docs

## Error Handling

The API uses standard HTTP status codes:

- `200` - Success
- `400` - Bad Request (validation errors)
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

Error responses include details:

```json
{
  "detail": "Validation error",
  "errors": {
    "field_name": ["This field is required."]
  }
}
```

## Rate Limiting

Currently, no rate limiting is implemented. For production deployment, consider implementing rate limiting based on your needs.

## Examples

### Creating a New Campaign

```python
import requests

data = {
    "title": "Clean Water Act",
    "slug": "clean-water-act",
    "summary": "Legislation to protect water quality",
    "description": "Comprehensive water protection measures..."
}

response = requests.post(
    'http://localhost:8000/api/campaigns/',
    json=data,
    headers={'Content-Type': 'application/json'}
)
```

### Adding an Endorsement

```python
endorsement_data = {
    "stakeholder": 1,
    "campaign": 1,
    "statement": "We strongly support this legislation",
    "public_display": True
}

response = requests.post(
    'http://localhost:8000/api/endorsements/',
    json=endorsement_data
)
```

## SDKs and Libraries

### Python Client

```python
from coalition_builder import CoalitionClient

client = CoalitionClient(
    base_url="http://localhost:8000/api/",
    username="admin",
    password="password"
)

# Get campaigns
campaigns = client.campaigns.list()

# Get homepage
homepage = client.homepage.get()
```

### JavaScript/TypeScript

```typescript
import { CoalitionAPI } from "@/lib/api";

const api = new CoalitionAPI("http://localhost:8000/api/");

// Get campaigns
const campaigns = await api.getCampaigns();

// Get homepage
const homepage = await api.getHomepage();
```

## Best Practices

1. **Caching**: Cache API responses where appropriate to reduce server load
2. **Pagination**: Use pagination for large result sets
3. **Error Handling**: Always handle API errors gracefully
4. **Authentication**: Store credentials securely
5. **Rate Limiting**: Respect rate limits in production environments

## Next Steps

- [API Reference](../api/index.md) - Complete API documentation
- [Development Setup](../development/setup.md) - Set up local development
- [Backend Development](../development/backend.md) - Extend the API
