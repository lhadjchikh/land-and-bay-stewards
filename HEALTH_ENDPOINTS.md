# Health Check Endpoints Documentation

This document clarifies the usage of different health check endpoints in the application.

## Health Check Endpoints

### `/health/` (Django Backend)

- **Purpose**: Load balancer health checks, container health checks, internal monitoring
- **Implementation**: Django view in `backend/coalition/core/views.py`
- **URL Pattern**: `backend/coalition/core/urls.py` → `path("health/", health_check)`
- **Used By**:
  - AWS Load Balancer API target group health checks
  - ECS container health checks
  - Docker container health checks (`healthcheck.py`)
  - Internal infrastructure monitoring

### `/api/health/` (Django API)

- **Purpose**: API-specific health checks, external monitoring tools, API consumers
- **Implementation**: Django Ninja API endpoint in `backend/coalition/api/api.py`
- **URL Pattern**: `@api.get("/health/", tags=["Health"])`
- **Used By**:
  - External monitoring services
  - API consumers wanting to check API health
  - Development/debugging tools
  - SSR server when checking backend health

### `/health` (SSR/Next.js)

- **Purpose**: SSR application health checks
- **Implementation**: Next.js route in `ssr/app/health/route.ts`
- **Used By**:
  - AWS Load Balancer SSR target group health checks
  - ECS container health checks for SSR service
  - SSR-specific monitoring

## Configuration Files

### Terraform

- **Root variable**: `terraform/variables.tf` → `health_check_path = "/health/"` (backend container and load balancer health checks)
- **Load balancer API health**: Uses `var.health_check_path` → `/health/` (Django backend health)
- **Load balancer SSR health**: Hardcoded `/health` (SSR health, no trailing slash)
- **Container health**: Uses `var.health_check_path` → `/health/` (Django containers)

### Variable Descriptions

- **`health_check_path`**: Used for infrastructure health checks (containers, load balancers) pointing to Django `/health/`
- **Not used for**: API-specific monitoring (that uses `/api/health/` directly)

### Docker

- **Django container**: `healthcheck.py` → calls `/health/`
- **SSR container**: `healthcheck.js` → calls `/health`

## Intended Usage

1. **For Infrastructure Monitoring**: Use `/health/` (Django) and `/health` (SSR)
2. **For API Monitoring**: Use `/api/health/` (Django API)
3. **For Load Balancers**: Automatically configured to use appropriate endpoints
4. **For External Tools**: Choose based on what you want to monitor:
   - Whole Django app → `/health/`
   - API specifically → `/api/health/`
   - SSR app → `/health`

## Response Format

All health endpoints return similar JSON structure:

```json
{
  "status": "healthy" | "unhealthy",
  "timestamp": "ISO-8601-timestamp",
  "service": "django-api" | "ssr",
  "version": "app-version",
  "database": "ok" | "error",
  "memory_usage": "memory-info"
}
```

## Troubleshooting

- **504 Gateway Timeout**: Check load balancer health check paths match endpoint implementations
- **Health check failures**: Verify database connectivity and service dependencies
- **Path confusion**: Refer to this document for correct endpoint usage
