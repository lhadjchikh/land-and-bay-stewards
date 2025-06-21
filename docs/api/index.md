# Coalition Builder API Documentation

This document provides comprehensive API documentation for the Coalition Builder backend, specifically designed for frontend developers and API consumers.

## Base URL

- **Development**: `http://localhost:8000/api`
- **Production**: `https://your-domain.com/api`

## Authentication

Currently, the API does not require authentication for read operations. Write operations are handled through the Django admin interface.

## Response Format

All API responses follow a consistent JSON format:

- **Success**: Returns the requested data directly or as an array
- **Error**: Returns an object with a `detail` field containing the error message

```json
// Success example
{
  "id": 1,
  "name": "Example Campaign",
  "slug": "example-campaign"
}

// Error example
{
  "detail": "Not Found"
}
```

## Endpoints

### Homepage Content

#### `GET /api/homepage/`

Returns the active homepage configuration with all content.

**Response Example:**

```json
{
  "id": 1,
  "organization_name": "Land and Bay Stewards",
  "tagline": "Protecting our coastal resources for future generations",
  "hero_title": "Building Coalitions for Environmental Policy",
  "hero_subtitle": "Join our efforts to protect the Chesapeake Bay watershed through collaborative advocacy",
  "hero_background_image": "https://example.com/hero-bg.jpg",
  "about_section_title": "About Our Mission",
  "about_section_content": "We work to build strong coalitions between farmers, watermen, businesses, and environmental organizations to advocate for policies that protect our shared natural resources while supporting sustainable economic development.",
  "cta_title": "Get Involved",
  "cta_content": "Join our coalition and help make a difference in environmental policy advocacy",
  "cta_button_text": "View Current Campaigns",
  "cta_button_url": "/campaigns/",
  "contact_email": "info@landandbay.org",
  "contact_phone": "(555) 123-4567",
  "facebook_url": "https://facebook.com/landandbay",
  "twitter_url": "https://twitter.com/landandbay",
  "instagram_url": "https://instagram.com/landandbay",
  "linkedin_url": "https://linkedin.com/company/landandbay",
  "campaigns_section_title": "Current Policy Campaigns",
  "campaigns_section_subtitle": "Active initiatives driving policy change",
  "show_campaigns_section": true,
  "content_blocks": [
    {
      "id": 1,
      "title": "Why Coalition Building Matters",
      "block_type": "text",
      "content": "<p>Effective policy change requires more than individual voices—it requires coordinated action from diverse stakeholders. Our platform facilitates collaboration between organizations, advocates, and community leaders.</p>",
      "image_url": "",
      "image_alt_text": "",
      "css_classes": "bg-gray-50",
      "background_color": "",
      "order": 1,
      "is_visible": true,
      "created_at": "2024-01-01T10:00:00Z",
      "updated_at": "2024-01-01T10:00:00Z"
    },
    {
      "id": 2,
      "title": "Our Impact",
      "block_type": "stats",
      "content": "<div class=\"grid grid-cols-3 gap-4 text-center\"><div><div class=\"text-4xl font-bold text-blue-600 mb-2\">150+</div><div class=\"text-gray-600\">Organizations</div></div><div><div class=\"text-4xl font-bold text-blue-600 mb-2\">25</div><div class=\"text-gray-600\">Active Campaigns</div></div><div><div class=\"text-4xl font-bold text-blue-600 mb-2\">500+</div><div class=\"text-gray-600\">Stakeholder Endorsements</div></div></div>",
      "image_url": "",
      "image_alt_text": "",
      "css_classes": "",
      "background_color": "",
      "order": 2,
      "is_visible": true,
      "created_at": "2024-01-01T10:00:00Z",
      "updated_at": "2024-01-01T10:00:00Z"
    }
  ],
  "is_active": true,
  "created_at": "2024-01-01T10:00:00Z",
  "updated_at": "2024-01-01T10:00:00Z"
}
```

**Status Codes:**

- `200 OK`: Homepage found and returned
- `404 Not Found`: No active homepage configuration exists

#### Content Block Types

Content blocks support different types for flexible page layouts:

- **`text`**: Rich text content with HTML support
- **`image`**: Image block with optional caption
- **`text_image`**: Combined text and image layout
- **`quote`**: Highlighted quote or testimonial
- **`stats`**: Statistics or metrics display
- **`custom_html`**: Custom HTML content for advanced layouts

### Policy Campaigns

#### `GET /api/campaigns/`

Returns all active policy campaigns.

**Response Example:**

```json
[
  {
    "id": 1,
    "title": "Clean Water Protection Act",
    "slug": "clean-water-protection-act",
    "summary": "Legislation to strengthen water quality standards and protect the Chesapeake Bay watershed",
    "active": true,
    "created_at": "2024-01-15T10:00:00Z"
  }
]
```

#### `GET /api/campaigns/{slug}/`

Returns a specific campaign by slug.

### Stakeholders

#### `GET /api/stakeholders/`

Returns all stakeholders.

**Response Example:**

```json
[
  {
    "id": 1,
    "name": "Jamie Smith",
    "organization": "Bay Area Farmers Coalition",
    "role": "Executive Director",
    "email": "jamie@bayareafarmers.org",
    "state": "MD",
    "county": "Anne Arundel",
    "type": "nonprofit",
    "created_at": "2024-01-10T10:00:00Z"
  }
]
```

**Stakeholder Types:**

- `farmer`: Agricultural stakeholders
- `waterman`: Commercial fishing/maritime stakeholders
- `business`: Private sector organizations
- `nonprofit`: Non-profit organizations
- `other`: Other stakeholder types

### Endorsements

#### `GET /api/endorsements/`

Returns all public endorsements with stakeholder and campaign details.

**Response Example:**

```json
[
  {
    "id": 1,
    "stakeholder": {
      "id": 1,
      "name": "Jamie Smith",
      "organization": "Bay Area Farmers Coalition"
    },
    "campaign": {
      "id": 1,
      "title": "Clean Water Protection Act",
      "slug": "clean-water-protection-act"
    },
    "statement": "This legislation is crucial for protecting our agricultural lands while ensuring clean water for future generations.",
    "public_display": true,
    "created_at": "2024-01-20T10:00:00Z"
  }
]
```

### Legislators

#### `GET /api/legislators/`

Returns all legislators.

**Response Example:**

```json
[
  {
    "id": 1,
    "bioguide_id": "B000944",
    "first_name": "Sherrod",
    "last_name": "Brown",
    "chamber": "Senate",
    "state": "OH",
    "district": null,
    "is_senior": true,
    "party": "D",
    "in_office": true,
    "url": "https://www.brown.senate.gov"
  }
]
```

## Error Handling

The API uses standard HTTP status codes:

- `200 OK`: Request successful
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

Error responses include a `detail` field with a human-readable error message:

```json
{
  "detail": "No active homepage configuration found"
}
```

## Rate Limiting

Currently, no rate limiting is implemented on the API endpoints.

## CORS

Cross-Origin Resource Sharing (CORS) is configured to allow requests from the frontend application domains.

## Frontend Integration

### Next.js Integration

The API is designed to work seamlessly with Next.js Server-Side Rendering (SSR):

```typescript
// Example usage in Next.js
export async function generateMetadata(): Promise<Metadata> {
  try {
    const homepage = await apiClient.getHomepage();
    return {
      title: homepage.organization_name,
      description: homepage.tagline,
    };
  } catch {
    return {
      title: "Coalition Builder",
      description: "Building strong advocacy partnerships",
    };
  }
}
```

### Error Handling Best Practices

Always implement fallback content for when API calls fail:

```typescript
// Recommended error handling
let homepage: HomePage | null = null;
try {
  homepage = await apiClient.getHomepage();
} catch (error) {
  console.error("Failed to fetch homepage:", error);
  // Use fallback content
  homepage = {
    organization_name: process.env.ORGANIZATION_NAME || "Coalition Builder",
    tagline: process.env.TAGLINE || "Building strong advocacy partnerships",
    // ... other fallback fields
  };
}
```

### Content Block Rendering

Content blocks should be filtered by visibility and ordered:

```typescript
const visibleBlocks = homepage.content_blocks
  .filter((block) => block.is_visible)
  .sort((a, b) => a.order - b.order);
```

## Development Notes

- All datetime fields are returned in ISO 8601 format with UTC timezone
- HTML content in content blocks should be sanitized before rendering
- Image URLs should be validated before display
- The API automatically filters content blocks to only return visible ones
- Only one homepage configuration can be active at a time
